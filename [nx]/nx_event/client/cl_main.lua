-- client/cl_main.lua
-- nx_event — Zone detection | Event participation | Death handling | NUI bridge

local VORPcore      = nil
local isInZone      = false
local isParticipant = false
local eventActive   = false
local eventZone     = nil  -- { x, y, z, r }
local localBlip     = nil

-- ─── Init VORP core ──────────────────────────────────────────────────────────
CreateThread(function()
    while VORPcore == nil do
        VORPcore = exports.vorp_core:GetCore()
        Wait(200)
    end
end)

-- ─── On resource start: sync with server if event already running ────────────
AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(1500)
    if VORPcore == nil then VORPcore = exports.vorp_core:GetCore() end
    VORPcore.Callback.TriggerAsync('nx_event:GetState', function(state)
        if state.active then
            TriggerEvent('nx_event:Client:EventStart', {
                duration = state.remaining,
                boxes    = state.boxes,
                total    = state.total,
                zone     = state.zone,
                snapshot = state.snapshot,
            })
        end
    end)
end)

-- ─── Zone detection thread ───────────────────────────────────────────────────
CreateThread(function()
    while true do
        if eventActive and eventZone then
            local pos  = GetEntityCoords(PlayerPedId())
            local dist = #(pos - vector3(eventZone.x, eventZone.y, eventZone.z))

            if dist <= eventZone.r and not isInZone then
                isInZone = true
                TryJoinEvent()
            elseif dist > (eventZone.r + 5.0) and isInZone then
                isInZone = false
            end
        end
        Wait(1000)
    end
end)

function TryJoinEvent()
    if isParticipant then return end
    VORPcore.Callback.TriggerAsync('nx_event:JoinEvent', function(result)
        if result.ok then
            isParticipant = true
            if result.snapshot then
                SendNUIMessage({ action = 'UPDATE_HUD', data = result.snapshot })
            end
        end
    end)
end

-- ─── Death detection ─────────────────────────────────────────────────────────
-- เมื่อผู้เล่นตายในกิจกรรม:
--   1. แจ้งเซิฟว่าตาย (ใช้ตรวจสอบ death timer)
--   2. ส่ง NUI แสดง "สลบ" overlay
--   3. Fire local event เพื่อให้ MJ-Medic hook เข้ามาได้
--
-- MJ-Medic integration: ใส่ใน medic script ก่อน start death timer:
--   if exports['nx_event']:IsPlayerInEvent(source) then return end
CreateThread(function()
    local wasDead = false
    while true do
        if isParticipant and eventActive then
            local ped  = PlayerPedId()
            local dead = IsPedDeadOrDying(ped, true)

            if dead and not wasDead then
                wasDead = true
                VORPcore.Callback.TriggerAsync('nx_event:PlayerDied', function() end)
                SendNUIMessage({ action = 'PLAYER_DOWNED' })
                -- Hook point สำหรับ medic scripts
                TriggerEvent('nx_event:LocalPlayerDowned')
            elseif not dead and wasDead then
                wasDead = false
                SendNUIMessage({ action = 'PLAYER_ALIVE' })
                VORPcore.Callback.TriggerAsync('nx_event:PlayerRevived', function() end)
                TriggerEvent('nx_event:LocalPlayerRevived')
            end
        end
        Wait(800)
    end
end)

-- ─── NET: Event Start ────────────────────────────────────────────────────────
RegisterNetEvent('nx_event:Client:EventStart')
AddEventHandler('nx_event:Client:EventStart', function(data)
    eventActive = true
    eventZone   = data.zone

    -- Show HUD
    SendNUIMessage({
        action   = 'SHOW',
        duration = data.duration,
        snapshot = data.snapshot or {},
        total    = data.total or Config.TotalBoxes,
    })

    -- Blip on minimap
    if localBlip then RemoveBlip(localBlip) end
    localBlip = AddBlipForCoord(data.zone.x, data.zone.y, data.zone.z)
    SetBlipSprite(localBlip, -1294772431)
    SetBlipScale(localBlip, Config.EventBlip.scale)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(Config.EventBlip.label)
    EndTextCommandSetBlipName(localBlip)

    -- Spawn box objects
    TriggerEvent('nx_event:Local:SpawnBoxes', data.boxes)

    -- Immediate zone check (already inside zone when event starts)
    local pos  = GetEntityCoords(PlayerPedId())
    local dist = #(pos - vector3(data.zone.x, data.zone.y, data.zone.z))
    if dist <= data.zone.r then
        isInZone = true
        TryJoinEvent()
    end
end)

-- ─── NET: Event End ──────────────────────────────────────────────────────────
RegisterNetEvent('nx_event:Client:EventEnd')
AddEventHandler('nx_event:Client:EventEnd', function(result)
    local wasPart = isParticipant

    eventActive   = false
    isInZone      = false
    isParticipant = false
    eventZone     = nil

    if localBlip then RemoveBlip(localBlip) localBlip = nil end

    TriggerEvent('nx_event:Local:ClearBoxes')
    SendNUIMessage({ action = 'SHOW_RESULT', data = result })

    -- ถ้าผู้เล่นยังสลบอยู่เมื่อกิจกรรมจบ → ฟื้นที่เดิม
    -- (MJ-Medic จะ resume death timer หลังจาก IsPlayerInEvent คืน false)
    if wasPart then
        Wait(1000)
        local ped = PlayerPedId()
        if IsPedDeadOrDying(ped, true) then
            local pos = GetEntityCoords(ped)
            local hdg = GetEntityHeading(ped)
            -- Resurrect via VORP character respawn event
            TriggerEvent('vorp:revivePlayer')
        end
    end
end)

-- ─── NET: HUD Update ─────────────────────────────────────────────────────────
RegisterNetEvent('nx_event:Client:UpdateHUD')
AddEventHandler('nx_event:Client:UpdateHUD', function(snapshot)
    SendNUIMessage({ action = 'UPDATE_HUD', data = snapshot })
end)

-- ─── NET: Box Collected ──────────────────────────────────────────────────────
RegisterNetEvent('nx_event:Client:BoxCollected')
AddEventHandler('nx_event:Client:BoxCollected', function(data)
    TriggerEvent('nx_event:Local:RemoveBox', data.boxIdx)
    SendNUIMessage({ action = 'UPDATE_HUD', data = data.snapshot })
end)

-- ─── Client Exports ──────────────────────────────────────────────────────────
exports('IsLocalPlayerInEvent', function()
    return isParticipant and eventActive
end)

exports('IsLocalPlayerInZone', function()
    return isInZone and eventActive
end)
