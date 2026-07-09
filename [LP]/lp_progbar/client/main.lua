--[[
    lp_progbar — concurrent progress bars for VORPCore/RedM

    Multiple bars can run at once. Each call returns a unique id; pass it back
    to cancel that one bar specifically, or cancel everything at once.

    Animation ownership: first-wins. The earliest still-active action that
    asked for an animation owns the ped's animation slot. When it ends, the
    next active anim-requesting action (if any) takes over.

    Control disables: OR'd across every active action — a control stays
    disabled for as long as at least one active action asked for it.

    ------------------------------------------------------------------
    USAGE
    ------------------------------------------------------------------

    -- Export, id returned directly:
    local id = exports.lp_progbar:Progress({
        duration = 5000,
        label = "Mining...",
        controlDisables = { disableMovement = true, disableCombat = true },
        animation = { animDict = "amb_work@world_human_hammering@male_a@idle_a", anim = "idle_a" },
    }, function(cancelled)
        print(cancelled and "stopped" or "done")
    end)

    -- Event (same client only), onStart receives the generated id:
    TriggerEvent("lp_progbar:client:progress",
        { duration = 5000, label = "Mining..." },
        function(cancelled) end,
        function(id) end
    )

    -- Caller-supplied id (works from a server-triggered event too):
    TriggerEvent("lp_progbar:client:progress", { id = "mining_" .. key, duration = 5000, label = "Mining..." })
    -- if that id is already live, a fresh one is generated instead

    -- Cancel one bar (others keep running):
    exports.lp_progbar:CancelProgress(id)             -- returns true/false
    TriggerEvent("lp_progbar:client:cancel", id)       -- unknown id = no-op

    -- Cancel everything:
    exports.lp_progbar:CancelAllProgress()             -- returns count
    TriggerEvent("lp_progbar:client:cancel")           -- nil/no arg = cancel all

    ------------------------------------------------------------------
    EXPORTS
      Progress(action, finish)                             -> id|nil
      ProgressWithStartEvent(action, start, finish)         -> id|nil
      ProgressWithTickEvent(action, tick, finish)           -> id|nil
      ProgressWithStartAndTick(action, start, tick, finish) -> id|nil
      CancelProgress(id)                                    -> bool
      CancelAllProgress()                                   -> count
      GetActiveProgress()                                   -> { {id,label,startTime,endTime}, ... }

    EVENTS (in)
      lp_progbar:client:progress(action, finish, onStart)
      lp_progbar:client:ProgressWithStartEvent(action, start, finish, onStart)
      lp_progbar:client:ProgressWithTickEvent(action, tick, finish, onStart)
      lp_progbar:client:ProgressWithStartAndTick(action, start, tick, finish, onStart)
      lp_progbar:client:cancel(id|nil)   -- nil cancels all; unknown id = no-op

    EVENTS (out)
      lp_progbar:client:progressStarted(id, tag, label)
      lp_progbar:client:actionCleanup(id)
    ------------------------------------------------------------------

    action fields:
      duration          ms (number)
      label             string shown on the bar
      id / tag          optional caller-supplied id / correlation tag
      canCancel         bool, default true — cancelKey aborts the bar
      useWhileDead      bool, default false — skip starting if the ped is dead
      position          optional string forwarded to the NUI (e.g. "carhud")
      controlDisables   { disableMovement, disableCarMovement, disableMouse, disableCombat }
      animation         { animDict, anim, flags } or { task = "SCENARIO_NAME" }
      prop              { model, bone, coords = {x,y,z}, rotation = {x,y,z} }
]]

local CANCEL_KEY = 0x8CC9CD42 -- X

local actions    = {}
local nextSeq    = 0
local animOwner  = nil
local wasDead    = false

-- ── id / defaults ──────────────────────────────────────────────────────────

local function generateId()
    nextSeq = nextSeq + 1
    return ("lpb_%d_%d"):format(nextSeq, GetGameTimer())
end

local function applyDefaults(a)
    a = a or {}
    if a.useWhileDead == nil then a.useWhileDead = false end
    if a.canCancel == nil then a.canCancel = true end
    a.controlDisables = a.controlDisables or {}
    a.animation = a.animation or {}
    a.prop = a.prop or {}
    a.duration = tonumber(a.duration) or 0
    a.label = a.label or ""
    return a
end

-- ── animation ────────────────────────────────────────────────────────────

local function requestsAnimation(a)
    if a.animation.task then return true end
    if a.animation.sequence then return true end
    return a.animation.animDict ~= nil and a.animation.anim ~= nil
end

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    local guard = 0
    while not HasAnimDictLoaded(dict) and guard < 200 do
        Citizen.Wait(5)
        guard = guard + 1
    end
end

-- ── sequence: สลับเล่นหลายคลิปต่อกันเป็นลูปเดียว ──
-- สำหรับ animset ที่ไม่มีคลิปลูปเดี่ยวๆ แต่แยกเป็นคู่ทรานซิชัน เช่น
-- ท่าเหวี่ยงลง (state A -> B) กับท่าเงื้อกลับ (state B -> A) เล่นสลับกันไปเรื่อยๆ
-- จะได้ภาพลูปต่อเนื่อง: { { animDict, anim, flags? }, { animDict, anim, flags? }, ... }
local seqGen           = 0
local seqActive         = false
local seqCurrentDict, seqCurrentAnim

local function stopSequence()
    seqActive = false
    seqGen    = seqGen + 1
    if seqCurrentDict and seqCurrentAnim then
        StopAnimTask(PlayerPedId(), seqCurrentDict, seqCurrentAnim, 1.0)
    end
    seqCurrentDict, seqCurrentAnim = nil, nil
end

local function playSequence(steps)
    seqActive = true
    seqGen    = seqGen + 1
    local gen = seqGen

    Citizen.CreateThread(function()
        local i = 0
        while seqActive and gen == seqGen do
            i = (i % #steps) + 1
            local step = steps[i]

            loadAnimDict(step.animDict)
            if not (seqActive and gen == seqGen) then break end

            local ped = PlayerPedId()
            seqCurrentDict, seqCurrentAnim = step.animDict, step.anim
            -- flag 2 = AF_HOLD_LAST_FRAME กันไม่ให้หลุดกลับ default pose ระหว่างสลับคลิป
            TaskPlayAnim(ped, step.animDict, step.anim, 3.0, 1.0, -1, step.flags or 2, 0, false, 0, false, "", true)

            local dur     = GetAnimDuration(step.animDict, step.anim)
            local waitMs  = math.max(50, math.floor((dur or 0) * 1000))
            local elapsed = 0
            while seqActive and gen == seqGen and elapsed < waitMs do
                Citizen.Wait(50)
                elapsed = elapsed + 50
            end
        end
    end)
end

local function playAnimation(a)
    local ped = PlayerPedId()
    if a.animation.task then
        TaskStartScenarioInPlace(ped, a.animation.task, 0, true)
        return
    end
    if a.animation.sequence then
        playSequence(a.animation.sequence)
        return
    end
    loadAnimDict(a.animation.animDict)
    -- TASK_PLAY_ANIM (RDR3) มี 13 พารามิเตอร์ต่อจาก ped ไม่ใช่ 11 แบบ GTA5:
    -- ..., playbackRate, p8(BOOL), ikFlags(int), p10(BOOL), taskFilter(charPtr), p12(BOOL)
    -- ของเดิมเรียกแบบ GTA5 (ขาด taskFilter/p12 และ ikFlags ผิด type เป็น bool)
    -- ทำให้ anim บางตัวเล่นแล้วรีเฟรม/ลูปไม่สมูท จึงเติมให้ครบตาม native จริง
    TaskPlayAnim(ped, a.animation.animDict, a.animation.anim, 3.0, 1.0, -1, a.animation.flags or 1, 0, false, 0, false, "", true)
end

local function stopAnimation(a)
    local ped = PlayerPedId()
    if a.animation.task then
        ClearPedTasks(ped)
        return
    end
    if a.animation.sequence then
        stopSequence()
        return
    end
    if a.animation.animDict and a.animation.anim then
        StopAnimTask(ped, a.animation.animDict, a.animation.anim, 1.0)
    end
end

local function pickNextAnimOwner()
    local pickId, pickStart = nil, nil
    for id, data in pairs(actions) do
        if requestsAnimation(data.action) and (pickStart == nil or data.startTime < pickStart) then
            pickId, pickStart = id, data.startTime
        end
    end
    return pickId
end

-- ── prop ─────────────────────────────────────────────────────────────────

local function spawnProp(a)
    local hash = GetHashKey(a.prop.model)
    RequestModel(hash)
    local guard = 0
    while not HasModelLoaded(hash) and guard < 200 do
        Citizen.Wait(0)
        guard = guard + 1
    end
    if not HasModelLoaded(hash) then return nil end

    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local obj    = CreateObject(hash, coords.x, coords.y, coords.z, true, true, true)
    SetModelAsNoLongerNeeded(hash)

    local bone = a.prop.bone or GetPedBoneIndex(ped, 60309)
    local c    = a.prop.coords or { x = 0.0, y = 0.0, z = 0.0 }
    local r    = a.prop.rotation or { x = 0.0, y = 0.0, z = 0.0 }
    AttachEntityToEntity(obj, ped, bone, c.x, c.y, c.z, r.x, r.y, r.z, true, true, false, true, 2, true, false, false)

    return ObjToNet(obj)
end

-- ── cleanup ──────────────────────────────────────────────────────────────

local function cleanupAction(id)
    local data = actions[id]
    if not data then return end

    if data.propNet then
        local obj = NetToObj(data.propNet)
        if obj ~= 0 then
            DetachEntity(obj, true, true)
            DeleteEntity(obj)
        end
    end

    if animOwner == id then
        stopAnimation(data.action)
        animOwner = nil
    end

    actions[id] = nil
end

-- ── core driver ──────────────────────────────────────────────────────────

local function runProgress(action, onStart, onTick, onFinish)
    local a = applyDefaults(action)

    if IsEntityDead(PlayerPedId()) and not a.useWhileDead then
        return nil
    end

    local id = a.id
    if id == nil or id == "" or actions[id] ~= nil then
        id = generateId()
    end

    local now = GetGameTimer()
    actions[id] = {
        action    = a,
        startTime = now,
        endTime   = now + a.duration,
        cancelled = false,
        propNet   = nil,
    }

    SendNUIMessage({
        action   = "lp_progbar:show",
        id       = id,
        duration = a.duration,
        label    = a.label,
        position = a.position,
    })

    -- function ข้าม resource ผ่าน exports มาเป็น callable table ไม่ใช่ raw `function` เช็คด้วยความจริง (truthy) แทน type()
    if onStart then onStart(id) end
    TriggerEvent("lp_progbar:client:progressStarted", id, a.tag, a.label)

    Citizen.CreateThread(function()
        while actions[id] and not actions[id].cancelled and GetGameTimer() < actions[id].endTime do
            if onTick then onTick() end
            if a.canCancel and IsControlJustPressed(0, CANCEL_KEY) then
                TriggerEvent("lp_progbar:client:cancel", id)
            end
            Citizen.Wait(0)
        end

        local data      = actions[id]
        local cancelled = data ~= nil and data.cancelled

        SendNUIMessage({ action = "lp_progbar:hide", id = id, cancelled = cancelled })
        cleanupAction(id)
        TriggerEvent("lp_progbar:client:actionCleanup", id)

        if onFinish then
            local ok, err = pcall(onFinish, cancelled)
            if not ok then
                print(('[lp_progbar] id=%s onFinish threw an error: %s'):format(tostring(id), tostring(err)))
            end
        end
    end)

    return id
end

-- ── exports ──────────────────────────────────────────────────────────────

function Progress(action, finish)
    return runProgress(action, nil, nil, finish)
end

function ProgressWithStartEvent(action, start, finish)
    return runProgress(action, start, nil, finish)
end

function ProgressWithTickEvent(action, tick, finish)
    return runProgress(action, nil, tick, finish)
end

function ProgressWithStartAndTick(action, start, tick, finish)
    return runProgress(action, start, tick, finish)
end

function CancelProgress(id)
    if id ~= nil and actions[id] then
        actions[id].cancelled = true
        return true
    end
    return false
end

function CancelAllProgress()
    local n = 0
    for _, data in pairs(actions) do
        data.cancelled = true
        n = n + 1
    end
    return n
end

function GetActiveProgress()
    local list = {}
    for id, data in pairs(actions) do
        list[#list + 1] = {
            id = id, label = data.action.label,
            startTime = data.startTime, endTime = data.endTime,
        }
    end
    return list
end

exports('Progress', Progress)
exports('ProgressWithStartEvent', ProgressWithStartEvent)
exports('ProgressWithTickEvent', ProgressWithTickEvent)
exports('ProgressWithStartAndTick', ProgressWithStartAndTick)
exports('CancelProgress', CancelProgress)
exports('CancelAllProgress', CancelAllProgress)
exports('GetActiveProgress', GetActiveProgress)

-- ── events ───────────────────────────────────────────────────────────────

RegisterNetEvent('lp_progbar:client:progress', function(action, finish, onStart)
    runProgress(action, onStart, nil, finish)
end)

RegisterNetEvent('lp_progbar:client:ProgressWithStartEvent', function(action, start, finish, onStart)
    runProgress(action, start, nil, finish)
    if type(onStart) == 'function' then end -- id already emitted via progressStarted
end)

RegisterNetEvent('lp_progbar:client:ProgressWithTickEvent', function(action, tick, finish, onStart)
    runProgress(action, nil, tick, finish)
end)

RegisterNetEvent('lp_progbar:client:ProgressWithStartAndTick', function(action, start, tick, finish, onStart)
    runProgress(action, start, tick, finish)
end)

RegisterNetEvent('lp_progbar:client:cancel', function(id)
    if id ~= nil then
        CancelProgress(id)
        return
    end
    CancelAllProgress()
end)

-- ── maintenance loop: anim ownership hand-off + OR'd control disables ─────

local function applyControlDisables()
    local mouse, move, carMove, combat = false, false, false, false
    for _, data in pairs(actions) do
        local d = data.action.controlDisables
        if d.disableMouse then mouse = true end
        if d.disableMovement then move = true end
        if d.disableCarMovement then carMove = true end
        if d.disableCombat then combat = true end
    end

    if mouse then
        DisableControlAction(0, 1, true)
        DisableControlAction(0, 2, true)
        DisableControlAction(0, 106, true)
    end
    if move then
        DisableControlAction(0, 30, true)
        DisableControlAction(0, 31, true)
        DisableControlAction(0, 36, true)
        DisableControlAction(0, 21, true)
    end
    if carMove then
        DisableControlAction(0, 63, true)
        DisableControlAction(0, 64, true)
        DisableControlAction(0, 71, true)
        DisableControlAction(0, 72, true)
        DisableControlAction(0, 75, true)
    end
    if combat then
        DisablePlayerFiring(PlayerPedId(), true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 47, true)
        DisableControlAction(0, 58, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(0, 143, true)
        DisableControlAction(0, 263, true)
        DisableControlAction(0, 264, true)
        DisableControlAction(0, 257, true)
    end
end

Citizen.CreateThread(function()
    while true do
        local hasActions = next(actions) ~= nil

        if hasActions then
            local dead = IsEntityDead(PlayerPedId())
            if dead and not wasDead then
                CancelAllProgress()
            end
            wasDead = dead

            if animOwner and not actions[animOwner] then
                animOwner = nil
            end
            if animOwner == nil then
                local pick = pickNextAnimOwner()
                if pick then
                    animOwner = pick
                    playAnimation(actions[pick].action)
                end
            end

            for id, data in pairs(actions) do
                if data.propNet == nil and data.action.prop and data.action.prop.model then
                    data.propNet = spawnProp(data.action)
                end
            end

            applyControlDisables()
            Citizen.Wait(0)
        else
            wasDead = IsEntityDead(PlayerPedId())
            Citizen.Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(name)
    if GetCurrentResourceName() ~= name then return end
    CancelAllProgress()
    for id in pairs(actions) do
        cleanupAction(id)
    end
end)

-- ── Test commands (F8 console) ──────────────────────────────────────────
-- /progbar_test        1 bar, 5s, movement+combat disabled
-- /progbar_test_multi  3 concurrent bars with staggered durations
-- /progbar_test_anim   1 bar, 6s, plays a scenario animation while it runs
-- /progbar_cancel      cancel every active bar

RegisterCommand('progbar_test', function()
    Progress({
        duration = 5000,
        label = 'Testing lp_progbar...',
        controlDisables = { disableMovement = true, disableCombat = true },
    }, function(cancelled)
        print(('[lp_progbar] progbar_test finished (cancelled=%s)'):format(tostring(cancelled)))
    end)
end, false)

RegisterCommand('progbar_test_multi', function()
    Progress({ duration = 4000, label = 'Bar A (4s)' }, function(c) print('[lp_progbar] A done, cancelled=' .. tostring(c)) end)
    Progress({ duration = 6000, label = 'Bar B (6s)' }, function(c) print('[lp_progbar] B done, cancelled=' .. tostring(c)) end)
    Progress({ duration = 8000, label = 'Bar C (8s)' }, function(c) print('[lp_progbar] C done, cancelled=' .. tostring(c)) end)
end, false)

RegisterCommand('progbar_test_anim', function()
    Progress({
        duration = 6000,
        label = 'Chopping (anim test)...',
        controlDisables = { disableMovement = true },
        animation = { task = 'WORLD_HUMAN_STAND_IMPATIENT' },
    }, function(cancelled)
        print(('[lp_progbar] progbar_test_anim finished (cancelled=%s)'):format(tostring(cancelled)))
    end)
end, false)

RegisterCommand('progbar_cancel', function()
    local n = CancelAllProgress()
    print(('[lp_progbar] cancelled %d bar(s)'):format(n))
end, false)
