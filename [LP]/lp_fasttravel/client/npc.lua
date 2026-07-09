-- client/npc.lua
-- lp_fasttravel — Standalone NPC + Blip ต่อสถานี (แยกจาก NPC/blip ของ bcc-train เอง)
-- pattern เดียวกับ bcc-train/client/blips_npc.lua (AddNPC/RemoveNPC/ManageBlip)

local spawnedPeds = {} -- [stationId] = ped
local blips        = {} -- [stationId] = blip

local function AddStationBlip(station)
    if blips[station.id] then return end

    local blip = Citizen.InvokeNative(0x554d9d53f696d002, 1664425300, station.coords.x, station.coords.y, station.coords.z) -- BlipAddForCoords
    SetBlipSprite(blip, Config.Blip.sprite, true)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, station.name) -- SetBlipName

    if Config.BlipColors[Config.Blip.color] then
        Citizen.InvokeNative(0x662D364ABF16DE2F, blip, joaat(Config.BlipColors[Config.Blip.color])) -- BlipAddModifier
    end

    blips[station.id] = blip
end

local function AddStationNPC(station)
    if spawnedPeds[station.id] then return end

    local hash = joaat(Config.NPC.model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 3000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(0) end
    if not HasModelLoaded(hash) then return end

    local ped = CreatePed(hash, station.coords.x, station.coords.y, station.coords.z - 1.0, station.heading or 0.0, false, false, false, false)
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true) -- SetRandomOutfitVariation
    SetEntityCanBeDamaged(ped, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(hash)

    spawnedPeds[station.id] = ped
end

local function RemoveStationNPC(station)
    local ped = spawnedPeds[station.id]
    if ped then
        if DoesEntityExist(ped) then DeleteEntity(ped) end
        spawnedPeds[station.id] = nil
    end
end

-- ─── Blip ทุกสถานีสร้างครั้งเดียวตอน resource start (ถาวร ไม่ผูกกับระยะ) ──────
CreateThread(function()
    for _, station in ipairs(Config.Stations) do
        AddStationBlip(station)
    end
end)

-- ─── NPC spawn/despawn ตามระยะ (perf: ไม่ spawn ทุกจุดพร้อมกันทั้งแมพ) ────────
CreateThread(function()
    while true do
        Wait(1000)
        local pos = GetEntityCoords(PlayerPedId())
        for _, station in ipairs(Config.Stations) do
            local dist = #(pos - station.coords)
            if dist <= Config.NPC.spawnDistance then
                AddStationNPC(station)
            else
                RemoveStationNPC(station)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for id in pairs(spawnedPeds) do
        RemoveStationNPC({ id = id })
    end
    for _, blip in pairs(blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
end)
