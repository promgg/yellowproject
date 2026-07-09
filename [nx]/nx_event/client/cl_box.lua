-- client/cl_box.lua
-- nx_event — Box spawning | G-hold collection | Animation | Cancel logic

local VORPcore      = nil
local boxes         = {}     -- [idx] = { entity, pos = vector3 }
local isCollecting  = false
local collectTarget = nil    -- idx ของกล่องที่กำลังเก็บ
local collectStart  = 0
local collectKey    = false  -- true = ปุ่มถูกกดค้างอยู่
local lastHealth    = 200    -- used for damage detection

-- ─── Init VORP ───────────────────────────────────────────────────────────────
CreateThread(function()
    while VORPcore == nil do
        VORPcore = exports.vorp_core:GetCore()
        Wait(200)
    end
end)

-- ─── Key binding ─────────────────────────────────────────────────────────────
-- ผู้เล่นสามารถเปลี่ยนปุ่มได้ใน Settings > Key Bindings
RegisterKeyMapping('+' .. Config.CollectKeyName, 'เก็บกล่องกิจกรรม', 'keyboard', Config.CollectKeyDefault)
RegisterCommand('+' .. Config.CollectKeyName, function() collectKey = true  end, false)
RegisterCommand('-' .. Config.CollectKeyName, function() collectKey = false end, false)

-- ─── Spawn box objects ───────────────────────────────────────────────────────
AddEventHandler('nx_event:Local:SpawnBoxes', function(boxData)
    if not boxData or #boxData == 0 then return end

    local hash = GetHashKey(Config.BoxProp)
    RequestModel(hash)

    local timeout = GetGameTimer() + 6000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(100) end

    if not HasModelLoaded(hash) then
        print("[nx_event] WARNING: Box prop '" .. Config.BoxProp .. "' failed to load. Check Config.BoxProp.")
        return
    end

    for _, b in ipairs(boxData) do
        local obj = CreateObjectNoOffset(hash, b.x, b.y, b.z, false, false, false)
        if DoesEntityExist(obj) then
            FreezeEntityPosition(obj, true)
            SetEntityInvincible(obj, true)
            PlaceObjectOnGroundProperly(obj)
            boxes[b.idx] = { entity = obj, pos = vector3(b.x, b.y, b.z) }
        end
    end

    SetModelAsNoLongerNeeded(hash)
end)

-- ─── Remove single box (collected / server confirmed) ────────────────────────
AddEventHandler('nx_event:Local:RemoveBox', function(boxIdx)
    local b = boxes[boxIdx]
    if b then
        if DoesEntityExist(b.entity) then DeleteObject(b.entity) end
        boxes[boxIdx] = nil
    end
    -- Cancel active collection if it was on this box
    if collectTarget == boxIdx then
        CancelCollection("box_removed")
    end
end)

-- ─── Clear all boxes (event ended) ───────────────────────────────────────────
AddEventHandler('nx_event:Local:ClearBoxes', function()
    CancelCollection("event_ended")
    for _, b in pairs(boxes) do
        if DoesEntityExist(b.entity) then DeleteObject(b.entity) end
    end
    boxes = {}
end)

-- ─── Cancel collection ───────────────────────────────────────────────────────
function CancelCollection(reason)
    if not isCollecting then return end
    isCollecting   = false
    collectTarget  = nil
    ClearPedTasks(PlayerPedId())
    SendNUIMessage({ action = 'COLLECT_CANCEL' })
    if reason then
        -- print(string.format("[nx_event] Collection cancelled: %s", reason))
    end
end

-- ─── Finish collection (progress complete) ───────────────────────────────────
local function FinishCollection(boxIdx)
    isCollecting  = false
    collectTarget = nil
    ClearPedTasks(PlayerPedId())

    VORPcore.Callback.TriggerAsync('nx_event:CollectBox', function(ok)
        if ok then
            SendNUIMessage({ action = 'COLLECT_DONE' })
        else
            -- Box already taken by someone else
            SendNUIMessage({ action = 'COLLECT_CANCEL' })
        end
    end, boxIdx)
end

-- ─── Start collection ────────────────────────────────────────────────────────
local function StartCollection(boxIdx, ped)
    isCollecting   = true
    collectTarget  = boxIdx
    collectStart   = GetGameTimer()
    lastHealth     = GetEntityHealth(ped)

    -- Load and play animation
    local dict = Config.CollectAnim.dict
    local anim = Config.CollectAnim.anim
    RequestAnimDict(dict)
    local t = GetGameTimer() + 3000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < t do Wait(50) end
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, anim, 3.0, -3.0, -1, 1, 0, false, false, false)
    end

    SendNUIMessage({ action = 'COLLECT_START' })
end

-- ─── Main collection thread ───────────────────────────────────────────────────
CreateThread(function()
    local lastHintVisible = false

    while true do
        -- Only run when player is an active participant
        if not exports['nx_event']:IsLocalPlayerInEvent() then
            if isCollecting then CancelCollection("left_event") end
            -- Hide hint if it was showing
            if lastHintVisible then
                SendNUIMessage({ action = 'SHOW_HINT', visible = false })
                lastHintVisible = false
            end
            collectKey = false
            Wait(2000)
            goto continue
        end

        local ped  = PlayerPedId()
        local pos  = GetEntityCoords(ped)
        local dead = IsPedDeadOrDying(ped, true)

        -- Cancel if player died
        if dead then
            if isCollecting then CancelCollection("player_dead") end
            if lastHintVisible then
                SendNUIMessage({ action = 'SHOW_HINT', visible = false })
                lastHintVisible = false
            end
            Wait(1000)
            goto continue
        end

        -- ─── Find nearest uncollected box ───────────────────────────────
        local nearIdx  = nil
        local nearDist = Config.CollectRadius + 1.0
        for idx, b in pairs(boxes) do
            local d = #(pos - b.pos)
            if d < nearDist then
                nearDist = d
                nearIdx  = idx
            end
        end

        -- ─── Show/hide hint ─────────────────────────────────────────────
        local hintVisible = nearIdx ~= nil and nearDist <= Config.CollectRadius
        if hintVisible ~= lastHintVisible then
            SendNUIMessage({ action = 'SHOW_HINT', visible = hintVisible })
            lastHintVisible = hintVisible
        end

        -- ─── Start collection when key held near box ─────────────────────
        if hintVisible and collectKey and not isCollecting then
            StartCollection(nearIdx, ped)
        end

        -- ─── Update active collection ────────────────────────────────────
        if isCollecting then
            local currentHealth = GetEntityHealth(ped)
            local elapsed       = GetGameTimer() - collectStart
            local progress      = math.min(elapsed / Config.CollectHoldTime, 1.0)

            -- Verify still near the target box
            local target     = boxes[collectTarget]
            local stillNear  = target and #(pos - target.pos) <= (Config.CollectRadius * 1.5)

            -- Damage detection (health dropped)
            local tookDamage = currentHealth < (lastHealth - 2)
            lastHealth       = currentHealth

            -- ─── Cancel conditions ───────────────────────────────────
            if not collectKey then
                CancelCollection("key_released")
            elseif not stillNear then
                CancelCollection("moved_away")
            elseif tookDamage then
                CancelCollection("took_damage")
            elseif IsPedDeadOrDying(ped, true) then
                CancelCollection("player_dead")
            elseif progress >= 1.0 then
                -- ─── SUCCESS ──────────────────────────────────────────
                FinishCollection(collectTarget)
            else
                -- Send progress to UI (throttle: every frame)
                SendNUIMessage({ action = 'COLLECT_PROGRESS', progress = progress })
            end
        end

        Wait(0)
        ::continue::
    end
end)
