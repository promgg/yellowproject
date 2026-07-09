-- client/cl_box.lua
-- nx_event — Box spawning | 2-phase collection: lp_textui:TextUIHold (grip, world-anchored on the box)
-- -> lp_progbar (opening animation) | Cancel logic

local VORPcore     = nil
local boxes        = {}     -- [idx] = { entity, pos = vector3 }
local activeIdx    = nil    -- box กำลังโต้ตอบอยู่ (ทั้ง phase hold และ open)
local activePhase  = nil    -- 'hold' | 'open' | nil
local collectId    = nil    -- lp_progbar action id (มีค่าเฉพาะ phase == 'open')
local lastHealth   = 200    -- used for damage detection

-- ─── Init VORP ───────────────────────────────────────────────────────────────
CreateThread(function()
    while VORPcore == nil do
        VORPcore = exports.vorp_core:GetCore()
        Wait(200)
    end
end)

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
        -- กัน spawn ซ้อน: ถ้า idx นี้มี entity ของเดิมอยู่แล้ว (เช่น resync ตอน
        -- onClientResourceStart ขณะ event ยังไม่จบ) ข้ามไปเลย ไม่งั้นจะได้ prop
        -- ซ้อนกัน 2 อัน โดยอันเก่าไม่ถูก track ใน boxes[] อีกต่อไป เก็บไม่ได้
        local existing = boxes[b.idx]
        if not (existing and DoesEntityExist(existing.entity)) then
            local obj = CreateObjectNoOffset(hash, b.x, b.y, b.z, false, false, false)
            if DoesEntityExist(obj) then
                FreezeEntityPosition(obj, true)
                SetEntityInvincible(obj, true)
                PlaceObjectOnGroundProperly(obj)
                boxes[b.idx] = { entity = obj, pos = vector3(b.x, b.y, b.z) }
            end
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
    if activeIdx == boxIdx then
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

-- ─── บล็อคการขยับระหว่างเก็บกล่องทั้ง 2 phase ─────────────────────────────
-- phase 'open' ถูกบล็อคผ่าน controlDisables ของ lp_progbar อยู่แล้ว แต่ phase
-- 'hold' (lp_textui:TextUIHold) ไม่มี option นี้ จึงต้องบล็อคเองตรงนี้
local MOVEMENT_CONTROLS = { 30, 31, 36, 21 }
local function blockMovement()
    for _, c in ipairs(MOVEMENT_CONTROLS) do
        DisableControlAction(0, c, true)
    end
end

-- ─── Reset local state (called once whichever phase actually stops) ─────────
local function ResetActive()
    activeIdx   = nil
    activePhase = nil
    collectId   = nil
end

-- ─── Cancel collection (either phase) ────────────────────────────────────────
function CancelCollection(reason)
    if activePhase == 'hold' then
        exports.lp_textui:CancelHold()
        ResetActive()
    elseif activePhase == 'open' and collectId then
        -- ResetActive เกิดใน callback ของ Progress เอง (cancelled = true)
        exports.lp_progbar:CancelProgress(collectId)
    end
end

-- ─── Phase 2: opening animation via lp_progbar ────────────────────────────────
local function OpenBox(boxIdx)
    activePhase = 'open'

    collectId = exports.lp_progbar:Progress({
        duration        = Config.CollectOpenTime,
        label           = "กำลังเปิดกล่อง...",
        canCancel       = true,
        controlDisables = { disableMovement = true, disableCombat = true },
        animation       = { animDict = Config.CollectAnim.dict, anim = Config.CollectAnim.anim },
    }, function(cancelled)
        if not cancelled then
            VORPcore.Callback.TriggerAsync('nx_event:CollectBox', function() end, boxIdx)
        end
        ResetActive()
    end)
end

-- ─── Phase 1: grip hold via lp_textui, floating on the box itself ────────────
local function BeginHold(boxIdx)
    local b = boxes[boxIdx]
    if not b then return end

    activeIdx   = boxIdx
    activePhase = 'hold'
    lastHealth  = GetEntityHealth(PlayerPedId())

    exports.lp_textui:TextUIHold(
        "[E] ค้างเพื่อเก็บกล่อง",
        Config.CollectHoldTime,
        function() OpenBox(boxIdx) end,
        Config.CollectKey,
        { coords = b.pos, offset = vector3(0.0, 0.0, 0.3) }
    )
end

-- ─── Main thread ──────────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        if not exports['nx_event']:IsLocalPlayerInEvent() then
            if activePhase then CancelCollection("left_event") end
            Wait(2000)
            goto continue
        end

        local ped  = PlayerPedId()
        local pos  = GetEntityCoords(ped)
        local dead = IsPedDeadOrDying(ped, true)

        if dead then
            if activePhase then CancelCollection("player_dead") end
            Wait(1000)
            goto continue
        end

        if activePhase then
            blockMovement()

            -- lp_textui/lp_progbar ไม่เช็คระยะห่างจากกล่องหรือดาเมจให้ ต้องคุมเอง
            local target     = boxes[activeIdx]
            local stillNear  = target and #(pos - target.pos) <= (Config.CollectRadius * 1.5)
            local currentHp  = GetEntityHealth(ped)
            local tookDamage = currentHp < (lastHealth - 2)
            lastHealth       = currentHp

            if not stillNear then
                CancelCollection("moved_away")
            elseif tookDamage then
                CancelCollection("took_damage")
            end
        else
            -- ─── Find nearest uncollected box ───────────────────────────
            local nearIdx  = nil
            local nearDist = Config.CollectRadius + 1.0
            for idx, b in pairs(boxes) do
                local d = #(pos - b.pos)
                if d < nearDist then
                    nearDist = d
                    nearIdx  = idx
                end
            end

            if nearIdx ~= nil and nearDist <= Config.CollectRadius then
                BeginHold(nearIdx)
            end
        end

        Wait(0)
        ::continue::
    end
end)
