-- local VorpCore = exports.vorp_core:GetCore()

-- State
local isInZone     = false
local isChopping   = false
local currentDur   = 99
local maxDur       = 99
local rod          = nil
local nearby_tree  = nil
local ChoppedTrees = {}
local currentProgId = nil

local HINT_CHOP = '[E] เพื่อเริ่มตัดไม้'

-- ── Utility ──────────────────────────────────────
local function createBlips()
    for _, zone in pairs(Config.lumberZone) do
        local blip = BlipAddForCoords(zone.Blips.Style, zone.Coords.x, zone.Coords.y, zone.Coords.z)
        SetBlipSprite(blip, zone.Blips.Sprite, false)
        BlipAddModifier(blip, zone.Blips.Color)
        SetBlipName(blip, zone.Name)
        zone.BlipHandle = blip
    end
end

local function isPlayerInLumberZone(coords)
    for _, zone in pairs(Config.lumberZone) do
        if #(coords - zone.Coords) <= zone.Radius then return true end
    end
    return false
end

local function GetTreeNearby(coords, radius, hash_filter)
    local itemSet = CreateItemset(true)
    local size = Citizen.InvokeNative(0x59B57C4B06531E1E, coords, radius, itemSet, 3, Citizen.ResultAsInteger())
    local found
    local bestDist
    if size > 0 then
        for i = 0, size - 1 do
            local entity = GetIndexedItemInItemset(i, itemSet)
            local hash   = GetEntityModel(entity)
            if hash_filter[hash] then
                local tc = GetEntityCoords(entity)
                local d  = #(coords - tc)
                -- เลือกต้นที่ใกล้ที่สุด (ไม่ใช่ต้นแรกที่เจอ) กัน cachedTree กระโดดไปต้นอื่นที่ไกลกว่าตอนลำดับ itemset สลับ
                if not bestDist or d < bestDist then
                    bestDist = d
                    found = { entity = entity, model_hash = hash, vector_coords = tc }
                end
            end
        end
    end
    if IsItemsetValid(itemSet) then DestroyItemset(itemSet) end
    return found
end

local function isPlayerReadyToChopTrees(ped)
    return not IsPedOnMount(ped)
        and not IsPedInAnyVehicle(ped, false)
        and not IsPedDeadOrDying(ped, false)
        and not IsEntityInWater(ped)
        and not IsPedClimbing(ped)
        and IsPedOnFoot(ped)
end

local function coordsToString(c)
    local function r(n) return math.floor(n * 10 + 0.5) / 10 end
    return r(c.x) .. '-' .. r(c.y) .. '-' .. r(c.z)
end
local function isTreeAlreadyChopped(c)  return ChoppedTrees[coordsToString(c)] == true end
local function rememberTreeAsChopped(c) ChoppedTrees[coordsToString(c)] = true end
local function forgetTreeAsChopped(c)   ChoppedTrees[coordsToString(c)] = nil end

local function convertConfigTreesToHashRegister()
    local t = {}
    for _, name in pairs(Config.Trees) do t[GetHashKey(name)] = name end
    return t
end

local function convertConfigTownRestrictionsToHashRegister()
    local t = {}
    for _, r in pairs(Config.TownRestrictions) do
        if not r.chop_allowed then t[GetHashKey(r.name)] = r.name end
    end
    return t
end

local function GetTown(x, y, z)
    return Citizen.InvokeNative(0x43AD8FC02B429D33, x, y, z, 1)
end

local function isInRestrictedTown(restricted, coords)
    local x, y, z = coords.x, coords.y, coords.z
    local hash = GetTown(x, y, z)
    if hash == false then return false end
    return restricted[hash] ~= nil
end

-- คำนวณครั้งเดียว ใช้ร่วมกันทั้ง tree-scan thread กับ callback ของ TextUIHold (จุดที่เริ่มตัดไม้จริงตอนนี้)
local ALLOWED_TREES    = convertConfigTreesToHashRegister()
local RESTRICTED_TOWNS = convertConfigTownRestrictionsToHashRegister()

-- ── Axe prop ─────────────────────────────────────
local function equipAxe()
    local ped     = PlayerPedId()
    local axeHash = GetHashKey('p_axe02x')
    RequestModel(axeHash)
    while not HasModelLoaded(axeHash) do Citizen.Wait(5) end
    local c = GetEntityCoords(ped)
    rod = CreateObject(axeHash, c.x, c.y, c.z, true, false, false, false)
    AttachEntityToEntity(rod, ped, GetPedBoneIndex(ped, 7966),
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true, false, false)
    Citizen.InvokeNative(0x923583741DC87BCE, ped, 'arthur_healthy')
    Citizen.InvokeNative(0x89F5E7ADECCCB49C, ped, "carry_pitchfork")
    Citizen.InvokeNative(0x2208438012482A1A, ped, true, true)
    Citizen.InvokeNative(0x3A50753042B6891B, ped, "PITCH_FORKS")
end

local function removeAxe()
    if not rod then return end
    local ped = PlayerPedId()
    Citizen.InvokeNative(0xED00D72F81CF7278, rod, 1, 1)
    DeleteObject(rod)
    Citizen.InvokeNative(0x58F7DB5BD8FA2288, ped)
    ClearPedDesiredLocoForModel(ped)
    ClearPedDesiredLocoMotionType(ped)
    rod = nil
end

local suppressCancelNotify = false

local function resetChopState()
    isChopping = false
    FreezeEntityPosition(PlayerPedId(), false)
    removeAxe()
end

-- ── lp_progbar onFinish: จุดที่ "กด X ระหว่างเล่นจริง" มาลง (lp_progbar เช็ค cancel-key ของมันเอง)
--    รวมถึงจบรอบสำเร็จ — ที่นี่ต้อง reset state เองเสมอ ห้ามพึ่ง stopChopping() เพราะฝั่งนั้นไม่รู้ว่ากด X ไปแล้ว ──
local function onChopFinished(cancelled)
    currentProgId = nil
    resetChopState()

    if cancelled then
        if not suppressCancelNotify then
            exports.pNotify:SendNotification({ type = 'info', text = 'หยุดตัดไม้แล้ว', timeout = 3000 })
        end
        suppressCancelNotify = false
        return
    end

    -- ส่งพิกัดต้นไม้ไปให้ server ทำ per-position cooldown เอง (server ยึดเป็นหลัก ไม่เชื่อ client)
    local coords = nearby_tree and nearby_tree.vector_coords
    TriggerServerEvent('!MJ-Lumberjack:addItem', coords and { x = coords.x, y = coords.y, z = coords.z } or nil)
    currentDur = currentDur - 1

    if coords then
        rememberTreeAsChopped(coords)
        Citizen.CreateThread(function()
            Citizen.Wait(900000)
            forgetTreeAsChopped(coords)
        end)
    end
end

-- ── ใช้ตอนยังไม่มี progbar วิ่งอยู่ (รอ server ตอบ axecheck) หรือบังคับตัด (exitZone/resourceStop) ──
-- reset แบบ sync ทันที ไม่รอ onChopFinished async กันเคสรีซอร์สหยุดก่อนมันทันทำงาน + กันแจ้งเตือนซ้ำด้วย suppress flag
local function stopChopping(silent)
    if currentProgId then
        suppressCancelNotify = true
        exports.lp_progbar:CancelProgress(currentProgId)
        currentProgId = nil
    end
    resetChopState()
    if not silent then
        exports.pNotify:SendNotification({ type = 'info', text = 'หยุดตัดไม้แล้ว', timeout = 3000 })
    end
end

-- ── Server responses ──────────────────────────────
RegisterNetEvent("!MJ-Lumberjack:axechecked", function(tree, durability)
    currentDur = durability or 99
    maxDur     = 99

    equipAxe()
    FreezeEntityPosition(PlayerPedId(), true)
    exports.lp_textui:HideUI()

    currentProgId = exports.lp_progbar:Progress({
        duration = Config.ChopDuration * 1000,
        label = ('กำลังตัดไม้...'),
        controlDisables = { disableMovement = true },
        animation = {
            -- animset นี้ไม่มีคลิปลูปเดี่ยว เป็นคู่ทรานซิชันสลับทิศ (pre<->after)
            -- เล่นสลับกันไปเรื่อยๆ แทน เพื่อให้ได้ท่าเหวี่ยง-เงื้อกลับต่อเนื่อง
            sequence = {
                { animDict = "amb_work@world_human_tree_chop_new@working@pre_swing@male_a@trans", anim = "pre_swing_trans_after_swing" },
                { animDict = "amb_work@world_human_tree_chop_new@working@after_swing@male_a@trans", anim = "after_swing_trans_pre_swing" },
            },
        },
    }, onChopFinished)
end)

RegisterNetEvent("!MJ-Lumberjack:noaxe", function()
    stopChopping(true)
    exports.pNotify:SendNotification({ type = 'error', text = 'ขวานหักแล้ว!', timeout = 4000 })
end)

RegisterNetEvent("!MJ-Lumberjack:itemAwarded", function(itemName)
    exports.lp_rewardpanel:Highlight(itemName)
end)

-- ── Tree scan (ทุก 500ms) ────────────────────────
local cachedTree = nil  -- shared ระหว่าง loop กับ marker

Citizen.CreateThread(function()
    repeat Citizen.Wait(5000) until LocalPlayer.state.IsInSession
    while true do
        Citizen.Wait(500)
        if not isChopping then
            local pos = GetEntityCoords(PlayerPedId())
            if isPlayerInLumberZone(pos) then
                cachedTree = GetTreeNearby(pos, Config.TreeScanRange or 25.0, ALLOWED_TREES)
            else
                cachedTree = nil
            end
        end
    end
end)

-- ── ต้นไม้เป้าหมายตอนนี้ตัดได้ไหม (มี, ยังไม่ถูกตัด, ไม่ได้กำลังตัดอยู่) ──
local function hasChoppableTree()
    return cachedTree ~= nil
        and not isTreeAlreadyChopped(cachedTree.vector_coords)
        and not isChopping
end

-- ── กดค้าง E ครบแล้ว: เริ่มตัดไม้จริง (callback ของ TextUIHold) ──
local function startChoppingFromHold()
    if isChopping then return end
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    if not (isPlayerReadyToChopTrees(ped) and not isInRestrictedTown(RESTRICTED_TOWNS, pos)) then return end

    local target = cachedTree
    if target and #(pos - target.vector_coords) > Config.ChopRange then
        target = GetTreeNearby(pos, Config.ChopRange, ALLOWED_TREES)
    end
    if not target or isTreeAlreadyChopped(target.vector_coords) then
        exports.pNotify:SendNotification({ type = 'info', text = 'ไม่มีต้นไม้ใกล้ๆ', timeout = 2000 })
        return
    end

    nearby_tree = target
    isChopping  = true

    -- freeze ก่อนหันหน้า กัน input เดินเดิม (ปุ่มเดินที่ยังกดค้าง) แย่ง task หันหน้าจน turn ไม่ติดบางครั้ง
    ClearPedTasksImmediately(ped)
    TaskTurnPedToFaceEntity(ped, target.entity, 5000)
    Citizen.Wait(1000)

    TriggerServerEvent("!MJ-Lumberjack:axecheck", nearby_tree.vector_coords)
end

-- ── Marker draw (ทุก frame) — วาด marker อย่างเดียว ไม่ยุ่งกับ hint ──
Citizen.CreateThread(function()
    repeat Citizen.Wait(5000) until LocalPlayer.state.IsInSession
    while true do
        if hasChoppableTree() then
            local tc = cachedTree.vector_coords
            Citizen.InvokeNative(0x2A32FAA57B937173,
                0x94FDAE17,
                tc.x, tc.y, tc.z,
                0, 0, 0, 0, 0, 0,
                0.3, 0.3, 1.0,
                230, 230, 0, 155,
                0, 0, 0, 2, 0, 0, 0, 0)
            Citizen.Wait(0)
        else
            Citizen.Wait(300)
        end
    end
end)

-- ── Hold hint (state machine แยกจากลูปวาด marker) ──
-- เข้าระยะ Config.ChopRange -> TextUIHold โชว์ hint + คุม poll ปุ่ม/วงแหวนเอง, กดค้าง E ครบ HOLD_MS -> callback เริ่มตัด
-- เรียก TextUIHold ครั้งเดียวตอนเข้าระยะ (เรียกซ้ำจะรีเซ็ตวงแหวน) และ CancelHold ครั้งเดียวตอนออก
-- hysteresis กันสั่นตรงขอบระยะ (เข้า <= ChopRange, ออก > ChopRange + 0.3)
local HOLD_MS = 900  -- กดค้าง E กี่ ms ถึงเริ่มตัด (ปรับได้)

Citizen.CreateThread(function()
    repeat Citizen.Wait(5000) until LocalPlayer.state.IsInSession
    local shown = false
    while true do
        Citizen.Wait(150)

        local inRange = false
        if hasChoppableTree() then
            local dist = #(GetEntityCoords(PlayerPedId()) - cachedTree.vector_coords)
            inRange = dist <= (shown and (Config.ChopRange + 0.3) or Config.ChopRange)
        end

        if inRange and not shown then
            shown = true
            exports.lp_textui:TextUIHold(HINT_CHOP, HOLD_MS, function()
                shown = false
                startChoppingFromHold()
            end, Config.KEY_E)
        elseif (not inRange) and shown then
            shown = false
            exports.lp_textui:CancelHold() -- ต้องใช้ CancelHold (ไม่ใช่ HideUI) ไม่งั้นเธรด poll ปุ่มของ TextUIHold ค้างวิ่งต่อ
        end
    end
end)

-- ── Main loop ─────────────────────────────────────
Citizen.CreateThread(function()
    repeat Citizen.Wait(5000) until LocalPlayer.state.IsInSession

    createBlips()

    while true do
        Citizen.Wait(5)
        local ped  = PlayerPedId()
        local pos  = GetEntityCoords(ped)
        local inZone = isPlayerInLumberZone(pos)

        if inZone then
            if not isInZone then
                isInZone = true
                local items = {}
                for _, r in ipairs(Config.Items) do
                    table.insert(items, {
                        img    = 'nui://vorp_inventory/html/img/items/' .. r.name .. '.png',
                        chance = r.chance,
                        item   = r.name,
                    })
                end
                exports.lp_rewardpanel:Show(items, 'โอกาสดร็อปไอเทมในโซน', 'Item Drop Info')
            end

            -- เริ่มตัดไม้ (กดค้าง E) จัดการใน hold hint thread แล้ว — ดูลูป Hold hint ด้านบน

            -- X: ยกเลิกระหว่างรอ server ตอบ axecheck (ระหว่างเล่นจริง lp_progbar คุม cancel-key เองแล้ว)
            if isChopping and not currentProgId and IsControlJustPressed(0, Config.KEY_X) then
                stopChopping()
            end
        else
            if isInZone then
                isInZone = false
                if isChopping then
                    stopChopping(true)
                end
                exports.lp_rewardpanel:Hide()
                exports.lp_textui:CancelHold()
                exports.lp_textui:HideUI()
            end
            Citizen.Wait(1000)
        end
    end
end)

AddEventHandler('onResourceStop', function(name)
    if GetCurrentResourceName() ~= name then return end
    if isChopping then
        stopChopping(true)
    end
    exports.lp_rewardpanel:Hide()
    exports.lp_textui:CancelHold()
    exports.lp_textui:HideUI()
    for _, zone in pairs(Config.lumberZone) do
        if zone.BlipHandle then RemoveBlip(zone.BlipHandle) end
    end
end)

-- ── DEV: /chopanim_test [dict] [anim] [flag] — เล่น/หยุดอนิเมชั่นเดี่ยวๆ
--    แยกออกจาก zone/hold/progbar ทั้งหมด รับ dict/anim ทาง argument ได้
--    เพื่อลองชื่อคลิปอื่นในเกมจริงได้เลยโดยไม่ต้องแก้โค้ด/restart ทุกรอบ
--    ใช้: /chopanim_test                                  -> ค่า default (คลิปที่รู้แล้วว่าพัง)
--        /chopanim_test <dict> <anim>                    -> ลองคู่ dict/anim อื่น
--        /chopanim_test <dict> <anim> <flag>             -> กำหนด flag ด้วย (default 1 = AF_LOOPING)
--        /chopanim_test                                  -> (กดซ้ำ ไม่ใส่ arg) หยุด
--
--    คู่ที่น่าลอง (เดาจากชื่อ dict/scenario ยังไม่ยืนยัน 100%):
--    /chopanim_test amb_work@world_human_tree_chop_new@working@pre_swing@male_a pre_swing
--    /chopanim_test amb_work@world_human_tree_chop_new@working@pre_swing@male_a idle_a
--    /chopanim_test amb_work@world_human_tree_chop_new@working@pre_swing@male_a base
local DEFAULT_TEST_DICT = "amb_work@world_human_tree_chop_new@working@pre_swing@male_a@trans"
local DEFAULT_TEST_ANIM = "pre_swing_trans_after_swing"
local testAnimActive     = false
local activeDict, activeAnim

RegisterCommand('chopanim_test', function(_, args)
    local ped = PlayerPedId()

    if testAnimActive then
        StopAnimTask(ped, activeDict, activeAnim, 1.0)
        print(('[chopanim_test] stopped: %s / %s'):format(activeDict, activeAnim))
        testAnimActive = false
        return
    end

    local dict = args[1] or DEFAULT_TEST_DICT
    local anim = args[2] or DEFAULT_TEST_ANIM
    local flag = tonumber(args[3]) or 1

    RequestAnimDict(dict)
    local guard = 0
    while not HasAnimDictLoaded(dict) and guard < 200 do
        Citizen.Wait(5)
        guard = guard + 1
    end

    if not HasAnimDictLoaded(dict) then
        print('[chopanim_test] โหลด anim dict ไม่สำเร็จ (ชื่อ dict อาจผิด): ' .. dict)
        return
    end

    -- ความยาวคลิปจริง: 0.0 มักแปลว่าชื่อ anim ไม่มีจริงใน dict นี้ (พิมพ์ผิด/เดาผิด)
    local dur = GetAnimDuration(dict, anim)
    if dur <= 0.0 then
        print(('[chopanim_test] WARNING length=%.3fs -> anim "%s" น่าจะไม่มีอยู่จริงใน dict นี้'):format(dur, anim))
    end
    print(('[chopanim_test] dict=%s anim=%s length=%.3fs flag=%d'):format(dict, anim, dur, flag))

    TaskPlayAnim(ped, dict, anim, 3.0, 1.0, -1, flag, 0, false, 0, false, "", true)
    activeDict, activeAnim = dict, anim
    testAnimActive = true
end, false)

-- ── DEV: /chopscenario_test — ทดสอบ native scenario "WORLD_HUMAN_TREE_CHOP_RAYFIRE"
--    แทนการเล่น anim clip ดิบ เพราะคลิป pre_swing_trans_after_swing มีแค่ช่วงเหวี่ยงไป
--    ไม่มีช่วงดึงกลับ (ยืนยันจาก /chopanim_test) — scenario ให้ engine คุมลูป/ทรานซิชันเอง
--    ใช้: /chopscenario_test -> เริ่ม, กดซ้ำ -> หยุด (ClearPedTasks)
local testScenarioActive = false

RegisterCommand('chopscenario_test', function()
    local ped = PlayerPedId()

    if testScenarioActive then
        ClearPedTasks(ped)
        testScenarioActive = false
        print('[chopscenario_test] stopped')
        return
    end

    local heading = GetEntityHeading(ped)
    -- signature จริง: ped, scenarioHash, duration, playEnterAnim, conditionalHash, heading, p6
    Citizen.InvokeNative(0x524B54361229154F, ped,
        GetHashKey('WORLD_HUMAN_TREE_CHOP_RAYFIRE'), 0, true, 0, heading, false)

    print('[chopscenario_test] started WORLD_HUMAN_TREE_CHOP_RAYFIRE')
    testScenarioActive = true
end, false)
