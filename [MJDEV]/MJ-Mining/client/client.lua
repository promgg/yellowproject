local VorpCore = exports.vorp_core:GetCore()

-- State
local isInZone      = false
local isMining       = false
local currentDur    = 99
local maxDur         = 99
local tool           = nil
local miningObjects  = {}
local usedRocks      = {}
local currentRock    = nil
local currentProgId  = nil

local HINT_MINE = '[E] เพื่อเริ่มขุด'

-- ── Utility ──────────────────────────────────────

-- เช็คว่ายืนอยู่ในโซนขุดไหน (คืน zone ทั้งก้อน ไม่ใช่แค่ true/false)
-- ใช้ Config.RocksZone[].Town ที่ระบุไว้ตรงๆ แทนการเดาจาก native GET_MAP_ZONE_AT_COORDS
-- (ยืนยันแล้วว่าโซนขุดอยู่นอกเขต "TOWN" จริงของเกม native เลยคืน false เสมอ ไม่ว่าจะเรียกถูกวิธีแค่ไหน)
local function getCurrentRocksZone(coords)
    for _, zone in pairs(Config.RocksZone) do
        if #(coords - zone.Coords) <= zone.Radius then return zone end
    end
    return nil
end

local function buildRewardItems(coords)
    local items   = {}
    local zone    = getCurrentRocksZone(coords)
    local rewards = zone and Config.MiningRewards[zone.Town]
    if not rewards then return items end

    for _, r in ipairs(rewards) do
        table.insert(items, {
            img    = 'nui://vorp_inventory/html/img/items/' .. r.name .. '.png',
            chance = r.chance,
            item   = r.name,
        })
    end
    return items
end

local function createBlips()
    for _, zone in pairs(Config.RocksZone) do
        local blip = BlipAddForCoords(zone.Blips.Style, zone.Coords.x, zone.Coords.y, zone.Coords.z)
        SetBlipSprite(blip, zone.Blips.Sprite, true)
        BlipAddModifier(blip, zone.Blips.Color)
        SetBlipName(blip, zone.Name)
        zone.BlipHandle = blip
    end
end

local function getNearbyRock(coords, radius)
    for _, obj in pairs(miningObjects) do
        if DoesEntityExist(obj) and not usedRocks[obj] then
            if #(coords - GetEntityCoords(obj)) <= radius then
                return obj
            end
        end
    end
    return nil
end

-- ── Pickaxe prop ─────────────────────────────────
local function equipPickaxe()
    local ped  = PlayerPedId()
    local hash = GetHashKey('p_pickaxe01x')
    RequestModel(hash)
    while not HasModelLoaded(hash) do Citizen.Wait(5) end
    local c = GetEntityCoords(ped)
    tool = CreateObject(hash, c.x, c.y, c.z, true, false, false, false)
    AttachEntityToEntity(tool, ped, GetPedBoneIndex(ped, 7966),
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true, false, false)
    Citizen.InvokeNative(0x923583741DC87BCE, ped, 'arthur_healthy')
    Citizen.InvokeNative(0x89F5E7ADECCCB49C, ped, "carry_pitchfork")
    Citizen.InvokeNative(0x2208438012482A1A, ped, true, true)
    Citizen.InvokeNative(0x3A50753042B6891B, ped, "PITCH_FORKS")
end

local function removePickaxe()
    if not tool then return end
    local ped = PlayerPedId()
    Citizen.InvokeNative(0xED00D72F81CF7278, tool, 1, 1)
    DeleteObject(tool)
    Citizen.InvokeNative(0x58F7DB5BD8FA2288, ped)
    ClearPedDesiredLocoForModel(ped)
    ClearPedDesiredLocoMotionType(ped)
    tool = nil
end

local suppressCancelNotify = false

local function resetMiningState()
    isMining = false
    FreezeEntityPosition(PlayerPedId(), false)
    removePickaxe()
end

-- ── lp_progbar onFinish: จุดที่ "กด X ระหว่างขุดจริง" มาลง (lp_progbar เช็ค cancel-key ของมันเอง)
--    รวมถึงจบรอบสำเร็จ — ที่นี่ต้อง reset state เองเสมอ ห้ามพึ่ง stopMining() เพราะฝั่งนั้นไม่รู้ว่ากด X ไปแล้ว ──
local function onMineFinished(cancelled)
    currentProgId = nil
    resetMiningState()

    if cancelled then
        if not suppressCancelNotify then
            exports.pNotify:SendNotification({ type = 'info', text = 'Mining cancelled.', timeout = 3000 })
        end
        suppressCancelNotify = false
        return
    end

    -- ระบุเมืองจาก Config.RocksZone[].Town ของโซนที่ยืนอยู่ (คำนวณฝั่ง client แล้วส่งไป
    -- เพราะ zone รอบตัว ped อ่านสะดวกกว่าฝั่ง server)
    local zone = getCurrentRocksZone(GetEntityCoords(PlayerPedId()))
    TriggerServerEvent('mining:addItem', zone and zone.Town or nil)
    currentDur = currentDur - 1

    local rock = currentRock
    if rock then
        usedRocks[rock] = true
        Citizen.CreateThread(function()
            Citizen.Wait(Config.RockCooldown)
            usedRocks[rock] = nil
        end)
    end
end

-- ── ใช้ตอนยังไม่มี progbar วิ่งอยู่ (รอ server ตอบ axecheck) หรือบังคับตัด (exitZone/resourceStop) ──
-- reset แบบ sync ทันที ไม่รอ onMineFinished async กันเคสรีซอร์สหยุดก่อนมันทันทำงาน + กันแจ้งเตือนซ้ำด้วย suppress flag
local function stopMining(silent)
    if currentProgId then
        suppressCancelNotify = true
        exports.lp_progbar:CancelProgress(currentProgId)
        currentProgId = nil
    end
    resetMiningState()
    if not silent then
        exports.pNotify:SendNotification({ type = 'info', text = 'Mining cancelled.', timeout = 3000 })
    end
end

-- ── Server responses ──────────────────────────────
RegisterNetEvent("mining:axechecked")
AddEventHandler("mining:axechecked", function(durability)
    currentDur = durability or 99
    maxDur     = 99

    equipPickaxe()
    FreezeEntityPosition(PlayerPedId(), true)
    exports.lp_textui:HideUI()

    currentProgId = exports.lp_progbar:Progress({
        duration = Config.MiningDuration * 1000,
        label = ('กำลังขุด...'),
        controlDisables = { disableMovement = true },
        animation = {
            -- animset นี้ไม่มีคลิปลูปเดี่ยว เป็นคู่ทรานซิชันสลับทิศ (pre<->after) อยู่ใน dict เดียวกัน
            -- เล่นสลับกันไปเรื่อยๆ แทน เพื่อให้ได้ท่าเหวี่ยงจอบ-เงื้อกลับต่อเนื่อง (แบบเดียวกับ MJ-Lumberjack)
            sequence = {
                { animDict = 'amb_work@world_human_pickaxe_new@working@male_a@trans', anim = 'pre_swing_trans_after_swing' },
                { animDict = 'amb_work@world_human_pickaxe_new@working@male_a@trans', anim = 'after_swing_trans_pre_swing' },
            },
        },
    }, onMineFinished)
end)

RegisterNetEvent("mining:noaxe")
AddEventHandler("mining:noaxe", function()
    stopMining(true)
    exports.pNotify:SendNotification({ type = 'error', text = 'Your pickaxe broke!', timeout = 4000 })
end)

RegisterNetEvent("mining:itemAwarded")
AddEventHandler("mining:itemAwarded", function(itemName)
    exports.lp_rewardpanel:Highlight(itemName)
end)

-- ── Spawn rock objects ────────────────────────────
-- แนวคิด random mode พอร์ตมาจาก rimlay-jobx (model:genratecoords()/createobject()): สุ่มจุดในวงกลม
-- รัศมี radius รอบ center, เว้นระยะห่างขั้นต่ำจากก้อนที่วางไปแล้วกันทับกัน, มี retry cap กันวนไม่รู้จบ
local function spawnRockAt(coords)
    -- collision สตรีมตามระยะใกล้ผู้เล่นเท่านั้น — จุดที่ผู้เล่นไม่ได้ยืนอยู่ใกล้ๆ ตอนสปาวน์ (เช่นอีกโซนที่ไกลออกไป)
    -- จะไม่มี collision โหลดให้เลย ทำให้ PlaceObjectOnGroundProperly หาพื้นไม่เจอและก้อนลอยค้างถาวร
    -- ต้องบังคับ RequestCollisionAtCoord ตรงจุดนั้นก่อน (idiom เดียวกับ vorp_admin/vorp_police/teleport.lua)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)

    local obj = CreateObject(GetHashKey(Config.MiningObject), coords.x, coords.y, coords.z, false, false, false)

    local guard = 0
    while not HasCollisionLoadedAroundEntity(obj) and guard < 100 do
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        Citizen.Wait(50)
        guard = guard + 1
    end

    for _ = 1, 15 do
        if PlaceObjectOnGroundProperly(obj) then break end
        Citizen.Wait(50)
    end

    FreezeEntityPosition(obj, true)
    table.insert(miningObjects, obj)
end

local function isSpacedOut(coords, minSpacing)
    for _, obj in pairs(miningObjects) do
        if DoesEntityExist(obj) and #(coords - GetEntityCoords(obj)) < minSpacing then
            return false
        end
    end
    return true
end

local function pickRandomPointInRadius(center, radius)
    local angle = math.random() * 2 * math.pi
    local dist  = math.sqrt(math.random()) * radius -- sqrt กันจุดกระจุกตัวตรงกลางวงกลม
    return vector3(center.x + math.cos(angle) * dist, center.y + math.sin(angle) * dist, center.z)
end

CreateThread(function()
    math.randomseed(GetGameTimer())

    for _, zone in pairs(Config.MiningZones) do
        if zone.mode == "random" then
            local count      = zone.count or 5
            local minSpacing = zone.minSpacing or 7.0
            local MAX_RETRIES = 40

            for _ = 1, count do
                local point, attempt = nil, 0
                repeat
                    attempt  = attempt + 1
                    local candidate = pickRandomPointInRadius(zone.center, zone.radius)
                    if isSpacedOut(candidate, minSpacing) then point = candidate end
                until point or attempt >= MAX_RETRIES

                spawnRockAt(point or pickRandomPointInRadius(zone.center, zone.radius))
                Citizen.Wait(0)
            end
        else
            spawnRockAt(zone.coords)
        end
    end
end)

-- ── Marker draw (ทุก frame) — วาด marker อย่างเดียว ไม่ยุ่งกับ hint ──
CreateThread(function()
    repeat Citizen.Wait(5000) until LocalPlayer.state.IsInSession
    while true do
        if isInZone and not isMining then
            local pos = GetEntityCoords(PlayerPedId())
            local drewAny = false

            for _, obj in pairs(miningObjects) do
                if DoesEntityExist(obj) and not usedRocks[obj] then
                    local oc = GetEntityCoords(obj)
                    if #(pos - oc) <= 5.0 then
                        drewAny = true
                        Citizen.InvokeNative(0x2A32FAA57B937173,
                            0x94FDAE17,
                            oc.x, oc.y, oc.z,
                            0, 0, 0, 0, 0, 0,
                            1.0, 1.0, 1.0,
                            230, 230, 0, 155,
                            0, 0, 0, 2, 0, 0, 0, 0)
                    end
                end
            end

            Citizen.Wait(drewAny and 0 or 500)
        else
            Citizen.Wait(500)
        end
    end
end)

-- ── กดค้าง E ครบแล้ว: เริ่มขุดจริง (callback ของ TextUIHold) ──
local function startMiningFromHold()
    if isMining then return end
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)

    local rock = getNearbyRock(pos, Config.MineRange)
    if not rock then
        exports.pNotify:SendNotification({ type = 'info', text = 'No rock nearby.', timeout = 2000 })
        return
    end

    currentRock = rock
    isMining    = true

    -- freeze ก่อนหันหน้า กัน input เดินเดิม (ปุ่มเดินที่ยังกดค้าง) แย่ง task หันหน้าจน turn ไม่ติดบางครั้ง
    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, true)
    TaskTurnPedToFaceEntity(ped, rock, 500)
    Citizen.Wait(500)

    TriggerServerEvent("mining:axecheck")
end

-- ── Hold hint (state machine แยกจากลูปวาด marker) ──
-- เข้าระยะ Config.MineRange -> TextUIHold โชว์ hint + คุม poll ปุ่ม/วงแหวนเอง, กดค้าง E ครบ HOLD_MS -> callback เริ่มขุด
-- เรียก TextUIHold ครั้งเดียวตอนเข้าระยะ (เรียกซ้ำจะรีเซ็ตวงแหวน) และ CancelHold ครั้งเดียวตอนออก
-- hysteresis กันสั่นตรงขอบระยะ (เข้า <= MineRange, ออก > MineRange + 0.3)
local HOLD_MS = 900  -- กดค้าง E กี่ ms ถึงเริ่มขุด (เท่ากับ MJ-Lumberjack)

CreateThread(function()
    repeat Citizen.Wait(5000) until LocalPlayer.state.IsInSession
    local shown = false
    while true do
        Citizen.Wait(150)

        local inRange = false
        if isInZone and not isMining then
            local pos  = GetEntityCoords(PlayerPedId())
            local rock = getNearbyRock(pos, shown and (Config.MineRange + 0.3) or Config.MineRange)
            inRange = rock ~= nil
        end

        if inRange and not shown then
            shown = true
            exports.lp_textui:TextUIHold(HINT_MINE, HOLD_MS, function()
                shown = false
                startMiningFromHold()
            end, Config.KEY_E)
        elseif (not inRange) and shown then
            shown = false
            exports.lp_textui:CancelHold()
        end
    end
end)

-- ── Main loop ─────────────────────────────────────
CreateThread(function()
    repeat Citizen.Wait(5000) until LocalPlayer.state.IsInSession

    createBlips()

    while true do
        Citizen.Wait(5)
        local ped    = PlayerPedId()
        local pos    = GetEntityCoords(ped)
        local inZone = getCurrentRocksZone(pos) ~= nil

        if inZone then
            if not isInZone then
                isInZone = true
                exports.lp_rewardpanel:Show(buildRewardItems(pos), 'โอกาสดร็อปแร่ในโซน', 'Mining Drop Info')
            end

            -- เริ่มขุด (กดค้าง E) จัดการใน hold hint thread แล้ว — ดูลูป Hold hint ด้านบน

            -- X: ยกเลิกระหว่างรอ server ตอบ axecheck (ระหว่างเล่นจริง lp_progbar คุม cancel-key เองแล้ว)
            if isMining and not currentProgId and IsControlJustPressed(0, Config.KEY_X) then
                stopMining()
            end
        else
            if isInZone then
                isInZone = false
                if isMining then
                    stopMining(true)
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
    if isMining then
        stopMining(true)
    end
    exports.lp_rewardpanel:Hide()
    exports.lp_textui:CancelHold()
    exports.lp_textui:HideUI()
    for _, obj in pairs(miningObjects) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    for _, zone in pairs(Config.RocksZone) do
        if zone.BlipHandle then RemoveBlip(zone.BlipHandle) end
    end
end)
