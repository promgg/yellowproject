-- ═══════════════════════════════════════════════════════════════════════════
--  lp_planting — client (แสดงผลอย่างเดียว)
--
--  ไม่มีการตัดสินใจอะไรที่นี่เลย: ทุกการหักของ/แจกของ/เลื่อนขั้น ขอไป server
--  แล้วรอผลกลับมา สิ่งที่เก็บไว้ฝั่งนี้มีแค่ prop กับตัวเลขไว้โชว์ความคืบหน้า
-- ═══════════════════════════════════════════════════════════════════════════

local VORPcore = {}
TriggerEvent('getCore', function(core) VORPcore = core end)

local function dbg(fmt, ...)
    if Config.Debug then print(('[lp_planting] ' .. fmt):format(...)) end
end

-- [plantId] = { id, seed, stage, coords, heading, obj, grownAtStart, baseTimer, swapped }
local Plants = {}
local blips = {}
local busy = false          -- กำลังเล่นท่าอยู่ กันกดซ้อน
local placing = false       -- กำลังปลูก กัน race

-- ── helper ───────────────────────────────────────────────────────────────────

local function notifyErr(text)
    exports.pNotify:SendNotification({ type = 'error', text = text, timeout = 4000 })
end

local function notifyOk(text)
    exports.pNotify:SendNotification({ type = 'success', text = text, timeout = 3500 })
end

-- เรียก RPC แบบรอผล (เขียนลำดับขั้นตอนได้ ไม่ต้อง nest callback)
local function rpc(name, ...)
    local done, result = false, nil
    VORPcore.RpcCall(name, function(r) result = r; done = true end, ...)
    local start = GetGameTimer()
    while not done do
        Wait(0)
        if GetGameTimer() - start > 10000 then return nil end -- กันค้างถาวรถ้า server ไม่ตอบ
    end
    return result
end

local function loadModel(model)
    local hash = type(model) == 'string' and GetHashKey(model) or model
    RequestModel(hash)
    local start = GetGameTimer()
    while not HasModelLoaded(hash) do
        Wait(50)
        if GetGameTimer() - start > 5000 then
            print(('^1[lp_planting]^7 โหลดโมเดลไม่สำเร็จ: %s'):format(tostring(model)))
            return false
        end
    end
    return true
end

-- ── progress bar + ท่าทาง (ยกจาก MJ-Planting ที่ยืนยันแล้วว่าเล่นได้จริง) ────

local function runProgress(action)
    local done, cancelled = false, false
    exports.lp_progbar:Progress(action, function(c) cancelled = c; done = true end)
    while not done do Wait(0) end
    return cancelled
end

-- ท่าปลูกเมล็ด (WORLD_HUMAN_FARMER_WEEDING)
local function animPlant()
    local anim = IsPedMale(PlayerPedId())
        and { task = 'WORLD_HUMAN_FARMER_WEEDING' }
        or  { animDict = 'amb_work@world_human_farmer_weeding@male_a@idle_a', anim = 'idle_a' }
    return runProgress({
        duration = 5000, label = 'กำลังปลูกเมล็ด...',
        controlDisables = { disableMovement = true }, animation = anim,
    })
end

-- ท่าใส่ปุ๋ย — ใช้ animDict ตรงๆ ไม่ใช่ task scenario
-- (WORLD_HUMAN_FEED_CHICKEN ผูกกับ scenario-point ของเกม เรียกลอยๆ แล้วไม่เล่นท่าให้เห็น)
-- prop ถุงปุ๋ยต้องใส่เอง เพราะท่านี้ไม่มี prop มากับ scenario
local function animFertilize()
    local male = IsPedMale(PlayerPedId())
    return runProgress({
        duration = 6000, label = 'กำลังใส่ปุ๋ย...',
        controlDisables = { disableMovement = true },
        animation = male
            and { animDict = 'amb_work@world_human_feed_chickens@male_a@idle_a', anim = 'idle_a' }
            or  { animDict = 'amb_work@world_human_feed_chickens@female_a@idle_a', anim = 'idle_a' },
        prop = { model = 'p_feedbag01x', bone = GetEntityBoneIndexByName(PlayerPedId(), 'SKEL_L_Hand') },
    })
end

local function animWater()
    return runProgress({
        duration = 8000, label = 'กำลังรดน้ำ...',
        controlDisables = { disableMovement = true },
        animation = { task = 'WORLD_HUMAN_BUCKET_POUR_LOW' },
    })
end

local function animHarvest()
    return runProgress({
        duration = 8000, label = 'กำลังเก็บเกี่ยว...',
        controlDisables = { disableMovement = true },
        animation = { animDict = 'mech_pickup@plant@berries', anim = 'base' },
    })
end

-- ── prop ─────────────────────────────────────────────────────────────────────

-- เวลาโตที่ผ่านไปแล้วของต้นนี้ (วินาที)
-- grownAtStart = ค่าที่ server บอกตอนส่งมา, baseTimer = นาฬิกา client ตอนรับ
-- บวกกันได้เวลาปัจจุบันโดยไม่ต้องเทียบนาฬิกาข้ามฝั่ง
local function grownSeconds(p)
    if not p.grownAtStart then return 0 end
    return p.grownAtStart + math.floor((GetGameTimer() - p.baseTimer) / 1000)
end

local function spawnProp(p)
    local info = Config.SeedLookup[p.seed]
    if not info then return end

    -- ต้นที่โตเกินครึ่งทางแล้วให้ขึ้นโมเดลโตเลย ไม่ต้องรอ swap
    local useGrown = p.stage == 'grow' and grownSeconds(p) >= info.swapSeconds
    local model = useGrown and info.modelGrown or info.model
    if not loadModel(model) then return end

    local obj = CreateObject(GetHashKey(model), p.coords.x, p.coords.y, p.coords.z, false, false, false)
    SetEntityAsMissionEntity(obj)
    PlaceObjectOnGroundProperly(obj)
    SetEntityHeading(obj, p.heading or 0.0)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(GetHashKey(model))

    p.obj = obj
    p.swapped = useGrown
end

local function despawnProp(p)
    if p.obj and DoesEntityExist(p.obj) then
        SetEntityAsMissionEntity(p.obj, false, true)
        DeleteEntity(p.obj)
        DeleteObject(p.obj)
    end
    p.obj = nil
end

local function addPlant(data)
    if Plants[data.id] then return end
    local p = {
        id = data.id, seed = data.seed, stage = data.stage,
        coords = data.coords, heading = data.heading,
        grownAtStart = data.grownSeconds,
        baseTimer = GetGameTimer(),
        swapped = false,
    }
    Plants[data.id] = p
    spawnProp(p)
end

local function removePlant(id)
    local p = Plants[id]
    if not p then return end
    despawnProp(p)
    Plants[id] = nil
end

-- ── โหลดต้นของตัวเองตอนเข้าเกม / restart resource ───────────────────────────

local function refreshMyPlants()
    local list = rpc('lp_planting:getMyPlants')
    if not list then return end
    for _, data in ipairs(list) do addPlant(data) end
    dbg('โหลดต้นของตัวเอง %d ต้น', #list)
end

AddEventHandler('vorp:SelectedCharacter', function()
    -- เปลี่ยนตัวละคร: เก็บของตัวเก่าทิ้งก่อน ไม่งั้น prop ของอีกตัวละครค้างอยู่
    for id in pairs(Plants) do removePlant(id) end
    SetTimeout(3000, refreshMyPlants)
end)

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetTimeout(2000, refreshMyPlants)
end)

RegisterNetEvent('lp_planting:removePlant', function(id) removePlant(id) end)

-- ── สลับโมเดลตอนต้นโตครึ่งทาง ───────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(5000)
        for _, p in pairs(Plants) do
            if p.stage == 'grow' and not p.swapped and p.obj and DoesEntityExist(p.obj) then
                local info = Config.SeedLookup[p.seed]
                if info and grownSeconds(p) >= info.swapSeconds then
                    despawnProp(p)
                    spawnProp(p) -- spawnProp เลือกโมเดลจากเวลาที่ผ่านไปเองแล้ว
                    PlaySoundFrontend('CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', true, 1)
                end
            end
        end
    end
end)

-- ── ปลูก: ใช้เมล็ด -> ลงตรงหน้าเลย (ไม่มี ghost ให้เล็งแบบเดิม) ─────────────

-- จุดปลูกอยู่ตรงหน้าผู้เล่นระยะคงที่
-- z เป็นค่าประมาณจากพื้น — spawnProp เรียก PlaceObjectOnGroundProperly ต่ออยู่แล้ว
local function spotInFront(dist)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local fwd = GetEntityForwardVector(ped)
    local x, y = pos.x + fwd.x * dist, pos.y + fwd.y * dist
    local found, groundZ = GetGroundZFor_3dCoord(x, y, pos.z + 1.0, false)
    return vector3(x, y, (found and groundZ) or pos.z), GetEntityHeading(ped)
end

RegisterNetEvent('lp_planting:useSeed', function(seed)
    if busy or placing then return end

    local info = Config.SeedLookup[seed]
    if not info then return end

    -- เช็คโซนฝั่ง client ก่อนเพื่อไม่ให้เสียเวลาเล่นท่าเปล่า (server ตรวจซ้ำอยู่ดี)
    if #(GetEntityCoords(PlayerPedId()) - info.zone.coords) > info.zone.range then
        notifyErr(('ต้องอยู่ในเขต %s ถึงจะปลูกได้'):format(info.zone.label))
        return
    end

    placing = true
    local coords, heading = spotInFront(1.5)

    -- เช็คระยะห่างจากต้นของตัวเองก่อน (server เช็คของทุกคนอีกชั้น)
    for _, p in pairs(Plants) do
        if #(p.coords - coords) < (info.zone.minDistance or 3.0) then
            notifyErr('ใกล้ต้นอื่นเกินไป ขยับออกไปหน่อย')
            placing = false
            return
        end
    end

    if animPlant() then placing = false; return end -- ยกเลิกกลางคัน = ยังไม่หักเมล็ด

    local res = rpc('lp_planting:place', seed, coords, heading)
    placing = false

    if not (res and res.ok) then
        local reason = res and res.reason
        if reason == 'quota' then
            notifyErr(('ปลูกได้สูงสุด %d ต้นต่อไร่ เก็บของเก่าก่อน'):format(Config.MaxPlantsPerZone))
        elseif reason == 'tooclose' then notifyErr('ใกล้ต้นอื่นเกินไป')
        elseif reason == 'notinzone' then notifyErr('ออกนอกเขตไร่แล้ว')
        elseif reason == 'noseed' then notifyErr('ไม่มีเมล็ดในกระเป๋า')
        else notifyErr('ปลูกไม่สำเร็จ') end
        return
    end

    addPlant({
        id = res.plantId, seed = seed, stage = 'fertilize',
        coords = coords, heading = heading, grownSeconds = nil,
    })
    notifyOk('ปลูกเมล็ดแล้ว — กดค้าง E ที่ต้นเพื่อใส่ปุ๋ย')
end)

-- ── การกระทำต่อต้น ──────────────────────────────────────────────────────────

local function doAction(p, action)
    busy = true

    if action == 'fertilize' then
        if not rpc('lp_planting:hasItem', Config.FertilizerItem) then
            notifyErr('ไม่มีปุ๋ย (compost)'); busy = false; return
        end
        if animFertilize() then busy = false; return end

        local res = rpc('lp_planting:fertilize', p.id)
        if not (res and res.ok) then
            notifyErr(res and res.reason == 'noitem' and 'ไม่มีปุ๋ย' or 'ใส่ปุ๋ยไม่สำเร็จ')
            busy = false; return
        end
        p.stage = 'water'
        notifyOk('ใส่ปุ๋ยแล้ว — กดค้าง E เพื่อรดน้ำต่อ')

    elseif action == 'water' then
        local tank = rpc('lp_planting:checkBucket')
        if not (tank and tank.hasBucket) then notifyErr('ไม่มีถังน้ำ'); busy = false; return end
        if (tank.uses or 0) <= 0 then notifyErr('ถังน้ำหมด ไปเติมที่จุดเติมน้ำก่อน'); busy = false; return end

        if animWater() then busy = false; return end

        local res = rpc('lp_planting:water', p.id)
        if not (res and res.ok) then notifyErr('รดน้ำไม่สำเร็จ'); busy = false; return end

        p.stage = 'grow'
        p.grownAtStart = 0
        p.baseTimer = GetGameTimer()

        local left = res.remaining or 0
        notifyOk(left > 0
            and ('รดน้ำแล้ว ต้นเริ่มโต (เหลือน้ำ %d ครั้ง)'):format(left)
            or  'รดน้ำแล้ว ต้นเริ่มโต (ถังน้ำหมด ไปเติมก่อนต้นถัดไป)')

        -- โจร: แยก thread ไม่งั้นลูป spawn ของมันจะบล็อก busy ไว้ 10-15 วิ
        if (Config.BanditChance or 0) > 0 and math.random(1, 100) <= Config.BanditChance then
            CreateThread(function() TriggerEvent('lp_planting:banditsStart') end)
        end

    elseif action == 'harvest' then
        if animHarvest() then busy = false; return end

        local res = rpc('lp_planting:harvest', p.id)
        if not (res and res.ok) then
            local reason = res and res.reason
            if reason == 'fullinv' then notifyErr('กระเป๋าเต็ม เคลียร์ที่ว่างก่อน')
            elseif reason == 'notready' then notifyErr('ต้นยังโตไม่พอ')
            else notifyErr('เก็บเกี่ยวไม่สำเร็จ') end
            busy = false; return
        end
        PlaySoundFrontend('CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', true, 1)
        removePlant(p.id)
    end

    busy = false
end

-- ── prompt ลอยเหนือต้น ──────────────────────────────────────────────────────

local function findTarget()
    local pos = GetEntityCoords(PlayerPedId())
    for _, p in pairs(Plants) do
        if p.obj and DoesEntityExist(p.obj) then
            local objPos = GetEntityCoords(p.obj)
            if #(pos - objPos) < Config.InteractRange then
                if p.stage == 'fertilize' then
                    return p, 'fertilize', '[E] ใส่ปุ๋ย', objPos
                elseif p.stage == 'water' then
                    return p, 'water', '[E] รดน้ำ', objPos
                elseif p.stage == 'grow' then
                    local info = Config.SeedLookup[p.seed]
                    local left = info and (info.growSeconds - grownSeconds(p)) or 0
                    if left <= 0 then
                        return p, 'harvest', '[E] เก็บเกี่ยว', objPos
                    end
                    -- ยังไม่โต: โชว์เวลาที่เหลือ ไม่ให้กด
                    return p, nil, ('อีก %d:%02d นาที'):format(math.floor(left / 60), left % 60), objPos
                end
            end
        end
    end
    return nil
end

CreateThread(function()
    local active, activeLabel = nil, nil

    -- ต้องใช้ HideUI ไม่ใช่ CancelHold: CancelHold มี early return ถ้าไม่มี hold ทำงานอยู่
    -- ป้ายนับถอยหลังสร้างด้วย TextUI ธรรมดา (ไม่ใช่ hold) เรียก CancelHold จึงไม่ปิดให้
    -- แล้วป้ายค้างบนจอตลอด — HideUI ปิดได้ทั้งสองแบบ
    local function clearPrompt()
        exports.lp_textui:HideUI()
        active, activeLabel = nil, nil
    end

    while true do
        -- ตอนมี prompt อยู่เช็คถี่หน่อยให้ป้ายหายทันทีที่เดินออก แต่ไม่ต้องทุกเฟรม
        Wait(active and 100 or 250)

        if busy then
            if active then clearPrompt() end
            goto continue
        end

        local target, action, label, pos = findTarget()

        -- เดินออกนอกระยะ หรือเปลี่ยนไปต้นอื่น -> เก็บป้ายเดิมก่อน
        if active and target ~= active then clearPrompt() end

        if target and not active then
            active, activeLabel = target, label
            if action then
                local thisP, thisAction = target, action
                exports.lp_textui:TextUIHold(label, Config.InteractHoldMs, function()
                    active, activeLabel = nil, nil
                    doAction(thisP, thisAction)
                end, nil, { coords = pos, offset = vector3(0.0, 0.0, 0.3) })
            else
                -- ยังโตไม่เสร็จ: โชว์ข้อความเฉยๆ กดไม่ได้
                -- signature คือ TextUI(message, key, worldAnchor) — ตัวที่ 2 เป็นปุ่มที่จะโชว์
                -- ไม่ใช่ตัวเลือก ถ้ายัด world-anchor ไปตรงนั้นจะได้ [object Object] บนจอ
                exports.lp_textui:TextUI(label, nil, { coords = pos, offset = vector3(0.0, 0.0, 0.3) })
            end

        elseif target and active == target and label ~= activeLabel then
            -- ต้นเดิมแต่ข้อความเปลี่ยน (นับถอยหลังเดิน หรือโตครบพร้อมเก็บแล้ว)
            activeLabel = label
            if action then
                -- เพิ่งพร้อมเก็บ: ต้องเปลี่ยนจากป้ายเฉยๆ เป็นแบบกดค้างได้
                local thisP, thisAction = target, action
                exports.lp_textui:HideUI()
                exports.lp_textui:TextUIHold(label, Config.InteractHoldMs, function()
                    active, activeLabel = nil, nil
                    doAction(thisP, thisAction)
                end, nil, { coords = pos, offset = vector3(0.0, 0.0, 0.3) })
            else
                -- แค่อัปเดตตัวเลข ส่ง TextUI ทับได้เลย ไม่ต้อง Hide ก่อน (ไม่งั้นกะพริบทุกวินาที)
                exports.lp_textui:TextUI(label, nil, { coords = pos, offset = vector3(0.0, 0.0, 0.3) })
            end
        end

        ::continue::
    end
end)

-- ── แผงโชว์ผลผลิตตอนอยู่ในไร่ (lp_rewardpanel) ──────────────────────────────
-- โผล่ตอนเดินเข้าเขตไร่ หายตอนออก — โชว์ว่าไร่นี้ปลูกอะไรได้บ้าง

local function buildRewardItems(zone)
    local items = {}
    for _, crop in pairs(zone.crops) do
        items[#items + 1] = {
            img    = 'nui://vorp_inventory/html/img/items/' .. crop.reward.item .. '.png',
            chance = 100, -- ได้แน่นอนเมื่อเก็บเกี่ยวสำเร็จ ไม่ใช่ % สุ่ม
            item   = crop.reward.item,
        }
    end
    return items
end

CreateThread(function()
    Wait(4000) -- รอ config/โซนพร้อมก่อน
    local inZone = nil

    while true do
        Wait(500)
        local pos = GetEntityCoords(PlayerPedId())

        local found = nil
        for zoneId, zone in pairs(Config.Zones) do
            if #(pos - zone.coords) <= zone.range then found = zoneId break end
        end

        if found ~= inZone then
            if found then
                local zone = Config.Zones[found]
                exports.lp_rewardpanel:Show(buildRewardItems(zone), zone.label, 'ผลผลิตในไร่นี้')
            else
                exports.lp_rewardpanel:Hide()
            end
            inZone = found
        end
    end
end)

-- ── blip ────────────────────────────────────────────────────────────────────
CreateThread(function()
    for _, zone in pairs(Config.Zones) do
        if zone.blip and zone.blip.enabled then
            local b = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, zone.coords.x, zone.coords.y, zone.coords.z)
            SetBlipSprite(b, zone.blip.sprite)
            SetBlipScale(b, zone.blip.scale)
            local colorHash = GetHashKey(zone.blip.color)
            if colorHash ~= 0 then Citizen.InvokeNative(0x662D364ABF16DE2F, b, colorHash) end
            Citizen.InvokeNative(0x9CB1A1623062F402, b, zone.blip.label)
            blips[#blips + 1] = b

            local r = Citizen.InvokeNative(0x45F13B7E0A15C880, 693035517, zone.coords.x, zone.coords.y, zone.coords.z, zone.range)
            blips[#blips + 1] = r
        end
    end
end)

-- ── เก็บกวาดตอนปิด resource ─────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, p in pairs(Plants) do despawnProp(p) end
    for _, b in ipairs(blips) do RemoveBlip(b) end
    exports.lp_textui:HideUI() -- HideUI ไม่ใช่ CancelHold — ดูเหตุผลที่ clearPrompt
    exports.lp_rewardpanel:Hide() -- ไม่ปิดจะค้างบนจอหลัง restart resource
end)
