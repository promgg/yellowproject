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

    local ped = PlayerPedId()

    if seqCurrentDict and seqCurrentAnim then
        StopAnimTask(ped, seqCurrentDict, seqCurrentAnim, 1.0)
    end
    seqCurrentDict, seqCurrentAnim = nil, nil

    -- ⚠️ StopAnimTask อย่างเดียวไม่พอ ตัวละครค้างขยับไม่ได้หลังจบ progress
    --
    -- คลิปในลูปเล่นด้วย flag 2 (AF_HOLD_LAST_FRAME) ซึ่งจงใจให้ค้างเฟรมสุดท้าย
    -- ไม่หลุดกลับท่ายืน — จำเป็นตอนสลับคลิปให้ต่อเนื่อง แต่แปลว่าถ้าไม่ปลดให้ถูก
    -- ตัวละครจะแข็งค้างอยู่ท่านั้น
    --
    -- และ StopAnimTask หยุดได้แค่ "คลิปที่ระบุ" ตัวเดียว ซึ่งมี race:
    -- ถ้าเธรดลูปเพิ่งข้ามไปเรียก TaskPlayAnim คลิปถัดไปพอดีตอนที่เราสั่งหยุด
    -- seqCurrentDict/Anim จะยังชี้คลิปเก่า -> สั่งหยุดผิดตัว คลิปใหม่เล่นค้างต่อ
    --
    -- ClearPedTasks ปลดทุกอย่างในทีเดียว ไม่ต้องลุ้นว่าจับคลิปถูกตัวไหม
    -- (ทางของ scenario ใน stopAnimation ใช้ตัวนี้อยู่แล้ว ทาง sequence เดิมตกไป)
    ClearPedTasks(ped)
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

-- ⚠️ RDR3 ใช้ "hash ของชื่อ INPUT_*" เป็น control id ไม่ใช่เลข index เล็กๆ แบบ GTA5
--
-- เดิมไฟล์นี้ใช้เลข 1, 2, 106, 30, 31, 36, 21, 63, 64, 71, 72, 75, 25 ซึ่งเป็น index ของ GTA5
-- ล้วนๆ — ยืนยันได้จาก ox_lib/resource/interface/client/progress.lua:62-76 ที่เก็บทั้งสองเกม
-- ไว้ในตารางเดียวกัน (`isFivem and 1 or 0xA987235F`) แล้วเลขทุกตัวที่เคยใช้ที่นี่ตรงกับคอลัมน์
-- FiveM ของตารางนั้นพอดีหมด ไม่เหลือตัวไหนเป็นของ RDR3 เลย
--
-- ผลที่ผ่านมา: controlDisables ไม่เคยกันอะไรได้จริง ผู้เล่นเดิน/ต่อยได้ระหว่าง progress
-- ทั้งที่ทุก resource ที่เรียกใช้ (lp_fasttravel, lp_planting, lp_gunsmith, lp_herbs,
-- lp_airdropteam) ส่ง flag มาโดยคาดหวังว่ามันจะล็อกจริง
-- ยกเว้น DisablePlayerFiring ที่ยังกันการยิงได้ เพราะเป็น native ที่มีจริงใน RDR3
local CONTROLS = {
    -- ── มุมกล้อง ── (ox_lib:63-64, 75)
    LOOK_LR        = 0xA987235F,
    LOOK_UD        = 0xD2047988,
    MOUSE_OVERRIDE = 0x39CCABD5,

    -- ── เดิน/วิ่ง/หมอบ ── (ox_lib:65, 67-69)
    SPRINT  = 0x8FFC75D6,
    MOVE_LR = 0x4D8FB4C1,
    MOVE_UD = 0xFDA83190,
    DUCK    = 0xDB096B85,

    -- ── พาหนะ (เกวียน/รถไฟ — RDR3 ไม่มีรถยนต์) ── (ox_lib:70-74)
    VEH_MOVE_LEFT  = 0x9DF54706,
    VEH_MOVE_RIGHT = 0x97A8FD98,
    VEH_ACCELERATE = 0x5B9FD4E2,
    VEH_BRAKE      = 0x6E1F639B,
    VEH_EXIT       = 0xFEFAB9B4,

    AIM = 0xF84FA74F, -- (ox_lib:66)
}

-- ปุ่มโจมตี/ประชิด ox_lib ไม่ได้ครอบไว้ (มันกันแค่ AIM + DisablePlayerFiring)
-- ยกมาจาก nx_util/client/cl_anti_combat.lua:57-68 ซึ่งใช้งานจริงบนเซิร์ฟนี้อยู่แล้ว
-- จำเป็นเพราะ DisablePlayerFiring กันได้แค่การยิง ไม่กันการชกต่อย/จับล็อก
local COMBAT_CONTROLS = {
    0x07CE1E61, -- INPUT_ATTACK
    0x0283C582, -- INPUT_ATTACK2
    0xB2F377E8, -- INPUT_MELEE_ATTACK
    0x1E7D7275, -- INPUT_MELEE_MODIFIER
    0xB5EEEFB7, -- INPUT_MELEE_BLOCK
    0x2277FAE9, -- INPUT_MELEE_GRAPPLE
    0xADEAF48C, -- INPUT_MELEE_GRAPPLE_ATTACK
    0x018C47CF, -- INPUT_MELEE_GRAPPLE_CHOKE
    0xD9C50532, -- INPUT_HOGTIE
}

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
        DisableControlAction(0, CONTROLS.LOOK_LR, true)
        DisableControlAction(0, CONTROLS.LOOK_UD, true)
        DisableControlAction(0, CONTROLS.MOUSE_OVERRIDE, true)
    end
    if move then
        DisableControlAction(0, CONTROLS.MOVE_LR, true)
        DisableControlAction(0, CONTROLS.MOVE_UD, true)
        DisableControlAction(0, CONTROLS.DUCK, true)
        DisableControlAction(0, CONTROLS.SPRINT, true)
    end
    if carMove then
        DisableControlAction(0, CONTROLS.VEH_MOVE_LEFT, true)
        DisableControlAction(0, CONTROLS.VEH_MOVE_RIGHT, true)
        DisableControlAction(0, CONTROLS.VEH_ACCELERATE, true)
        DisableControlAction(0, CONTROLS.VEH_BRAKE, true)
        DisableControlAction(0, CONTROLS.VEH_EXIT, true)
    end
    if combat then
        -- native ตัวนี้รับ player id ไม่ใช่ ped — เดิมส่ง PlayerPedId() เข้าไปซึ่งผิดชนิด
        -- (ox_lib:132 ส่ง cache.playerId ซึ่งก็คือ PlayerId())
        DisablePlayerFiring(PlayerId(), true)
        DisableControlAction(0, CONTROLS.AIM, true)
        for i = 1, #COMBAT_CONTROLS do
            DisableControlAction(0, COMBAT_CONTROLS[i], true)
        end
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

-- ── /progbar_looptest [รอบ] [วินาทีต่อรอบ] ───────────────────────────────────
-- จำลองเคสจริงของ MJ-Mining / MJ-Lumberjack แบบวนซ้ำ แล้วตรวจให้เองว่า
-- "จบรอบแล้วตัวละครหลุดจากท่าจริงไหม" — เป็นอาการที่เจอตอนเล่นจริง:
-- progress จบแล้วแต่ตัวค้าง ขยับไม่ได้
--
-- ใช้ค่าเดียวกับที่ MJ-Mining ส่งมาเป๊ะ (sequence 2 คลิปทรานซิชัน + disableMovement)
-- เพราะบั๊กอยู่ที่ทาง sequence โดยเฉพาะ ไม่ใช่ทาง animDict เดี่ยวหรือ scenario
local MINING_SEQ = {
    { animDict = 'amb_work@world_human_pickaxe_new@working@male_a@trans', anim = 'pre_swing_trans_after_swing' },
    { animDict = 'amb_work@world_human_pickaxe_new@working@male_a@trans', anim = 'after_swing_trans_pre_swing' },
}

local loopTestRunning = false

RegisterCommand('progbar_looptest', function(_, args)
    if loopTestRunning then
        print('[lp_progbar] looptest: กำลังรันอยู่แล้ว — /progbar_cancel เพื่อหยุด')
        return
    end

    local rounds  = math.max(1, math.min(tonumber(args[1]) or 3, 20))
    local seconds = math.max(1, math.min(tonumber(args[2]) or 3, 30))

    loopTestRunning = true

    Citizen.CreateThread(function()
        local ped  = PlayerPedId()
        local fail = 0

        print(('[lp_progbar] ===== looptest เริ่ม: %d รอบ รอบละ %d วิ ====='):format(rounds, seconds))

        for i = 1, rounds do
            -- จำลองให้เหมือนของจริง: mining/lumberjack freeze ped ก่อนเริ่มทุกครั้ง
            FreezeEntityPosition(ped, true)

            local done = false
            Progress({
                duration = seconds * 1000,
                label = ('looptest รอบ %d/%d'):format(i, rounds),
                controlDisables = { disableMovement = true },
                animation = { sequence = MINING_SEQ },
            }, function() done = true end)

            local guard = 0
            while not done and guard < (seconds + 10) * 100 do
                Citizen.Wait(10)
                guard = guard + 1
            end

            -- ปลด freeze แบบเดียวกับที่ resetMiningState ทำ
            FreezeEntityPosition(ped, false)

            -- ให้เวลา blend ออกจากท่าก่อนตรวจ ไม่งั้นจะจับได้ว่ายังเล่นอยู่ทั้งที่กำลังจะจบ
            Citizen.Wait(700)

            -- ตรวจว่าหลุดจากท่าจริงไหม — ถ้ายังเล่นคลิปใดคลิปหนึ่งอยู่ = ค้าง
            local stuckOn = nil
            for _, s in ipairs(MINING_SEQ) do
                if IsEntityPlayingAnim(ped, s.animDict, s.anim, 3) then
                    stuckOn = s.anim
                    break
                end
            end

            local frozen    = IsEntityPositionFrozen and IsEntityPositionFrozen(ped) or false
            local scenario  = IsPedActiveInScenario(ped)

            if stuckOn or frozen or scenario then
                fail = fail + 1
                print(('[lp_progbar] รอบ %d  ^1ค้าง^7  anim=%s frozen=%s scenario=%s')
                    :format(i, tostring(stuckOn), tostring(frozen), tostring(scenario)))
                -- กู้ให้เองเพื่อให้รอบถัดไปเทสต่อได้ ไม่ต้องออกเกม
                ClearPedTasks(ped)
                FreezeEntityPosition(ped, false)
            else
                print(('[lp_progbar] รอบ %d  ^2ผ่าน^7  หลุดจากท่าปกติ'):format(i))
            end

            Citizen.Wait(500)
        end

        print(('[lp_progbar] ===== looptest จบ: ผ่าน %d/%d รอบ%s ====='):format(
            rounds - fail, rounds, fail > 0 and ('  ^1ค้าง ' .. fail .. ' รอบ^7') or ''))

        loopTestRunning = false
    end)
end, false)
