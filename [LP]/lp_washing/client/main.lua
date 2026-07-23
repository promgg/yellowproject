-- ═══════════════════════════════════════════════════════════════════════════
--  lp_washing — client
-- ═══════════════════════════════════════════════════════════════════════════

local Core = exports.vorp_core:GetCore()

local busy       = false  -- กำลังล้าง/อาบอยู่ ห้ามซ้อน
local promptOwner = nil   -- 'river' | 'bath' | nil — ใครเป็นเจ้าของ prompt ที่โชว์อยู่
local lastWashAt = 0

local function dbg(msg, ...)
    if Config.Debug then print(('[lp_washing] ' .. msg):format(...)) end
end

local function notify(text)
    -- pNotify ใช้ทั้งเซิร์ฟอยู่แล้ว แต่ pcall ไว้กัน resource ยังไม่ขึ้นตอน boot
    pcall(function()
        exports.pNotify:SendNotification({ type = 'info', text = text, timeout = 3000 })
    end)
end

-- ── หัวใจของทั้งสคริปต์: ล้างคราบออกจาก ped ────────────────────────────────
-- hash ชุดนี้ยกมาจาก bcc-stables ที่ใช้ล้างม้าอยู่แล้ว ใช้กับ ped ตัวไหนก็ได้
local function cleanPed(ped)
    if Config.Clean.envDirt then
        Citizen.InvokeNative(0x6585D955A68452A5, ped)            -- ClearPedEnvDirt
    end
    if Config.Clean.blood then
        Citizen.InvokeNative(0x8FE22675A5A45817, ped)            -- ClearPedBloodDamage
    end
    if Config.Clean.damageDecals then
        Citizen.InvokeNative(0x523C79AEEFCC4A2A, ped, 10, 'ALL') -- ClearPedDamageDecalByZone
    end
    if Config.Clean.wetness then
        ClearPedWetness(ped)  -- มีเป็น native ชื่อตรง ๆ (vorp_stables/Client/interactions.lua:186)
    end
end

-- lp_textui โหมดกดค้างไม่รับพารามิเตอร์ปุ่ม — มันเรียก TextUI(message, nil, ...)
-- ตายตัวอยู่ข้างใน (lp_textui/client/main.lua:248) เลยต้องบอกปุ่มในข้อความเอง
local function withKey(label)
    return ('[E] %s'):format(label)
end

local function clearPrompt()
    if promptOwner then
        exports.lp_textui:HideUI()
        promptOwner = nil
    end
end

-- ── เงื่อนไขล้างตัวในแม่น้ำ ─────────────────────────────────────────────────
-- "อยู่ในน้ำ แต่ไม่ได้ว่ายน้ำ" = ยืนแช่น้ำตื้นแถวตลิ่ง
-- ว่ายอยู่กลางแม่น้ำจะไม่เข้าเงื่อนไข เพราะท่าล้างตัวเป็นท่านั่งยองบนพื้น
local function canWashInRiver(ped)
    if not Config.River.enabled then return false end
    -- เช็คคูลดาวน์ตรงนี้ ไม่ใช่ตอนกด — ไม่งั้น prompt จะโชว์ค้างให้กดค้างจนครบ
    -- แล้วไม่มีอะไรเกิดขึ้น ผู้เล่นงงว่าพังหรือเปล่า
    if (GetGameTimer() - lastWashAt) < Config.River.cooldownMs then return false end
    if IsPedSwimming(ped) then return false end
    if IsPedDeadOrDying(ped, true) then return false end
    if IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false) then return false end
    if not IsEntityInWater(ped) then return false end

    -- นั่งย่อก่อน — GetPedCrouchMovement (hash เดียวกับ MJ-Admin/client/client.lua:1359)
    if Config.River.requireCrouch and not Citizen.InvokeNative(0xD5FE956C70FF370B, ped) then
        return false
    end
    return true
end

-- ── หาจุดอาบน้ำที่ใกล้ที่สุดในระยะ ──────────────────────────────────────────
local function getNearbyBath(coords)
    if not Config.BathHouse.enabled then return nil end
    local best, bestDist = nil, Config.BathHouse.range
    for _, loc in ipairs(Config.BathHouse.locations) do
        local d = #(coords - loc.stand)
        if d < bestDist then best, bestDist = loc, d end
    end
    return best
end

-- ── หลอด + ท่าทาง ────────────────────────────────────────────────────────────
-- ใช้ท่าเดียวกันทั้งริมน้ำและในอ่าง (Config.River.scenario) ต่างกันแค่ความยาวหลอด
-- ถ้าวันหลังหาท่าอาบอ่างที่ดีกว่าได้ ค่อยแยก scenario ของ BathHouse ออกมา
local function runWashProgress(durationMs, label)
    local done, cancelled = false, false
    exports.lp_progbar:Progress({
        duration = durationMs,
        label = label,
        controlDisables = { disableMovement = true },
        animation = { task = Config.River.scenario },
    }, function(c) cancelled = c; done = true end)
    while not done do Wait(0) end
    return cancelled
end

-- ── ฉากอ่างอาบน้ำของเกม ─────────────────────────────────────────────────────
-- แกะจาก rsg-bathing/client/client.lua:74-89 (intro) และ 212-231 (outro)
-- ที่เดาไม่ได้เองคือ 2 อย่าง: slot ของผู้เล่นชื่อ "ARTHUR" และต้องผูกประตู
-- เข้าไปในชื่อ "Door" ด้วย ไม่งั้นฉากขาดตัวแสดง
local ANIM = {
    create   = 0x1FCA98E33C1437B3, -- CreateAnimScene
    isLoaded = 0x477122B8D05E7968, -- IsAnimSceneLoaded (รับ 3 อาร์กิวเมนต์)
    isDone   = 0xD8254CB2C586412B, -- ฉากเล่นจบหรือยัง
    exists   = 0x25557E324489393C, -- DoesAnimSceneExist
    dispose  = 0x84EEDB2C6E650000, -- DisposeAnimScene
    doorEnt  = 0xF7424890E4A094C0, -- GetEntityByDoorhash
}

-- คืน true ถ้าฉากเล่นจบ, false ถ้าโหลดไม่ขึ้น (ผู้เรียกไป fallback ต่อ)
local function runAnimScene(loc, sceneName)
    local ped = PlayerPedId()
    local scene = Citizen.InvokeNative(ANIM.create, loc.dict, 0, sceneName, false, true)
    if not scene or scene == 0 then
        dbg('สร้างฉากไม่สำเร็จ: %s / %s', tostring(loc.dict), sceneName)
        return false
    end

    SetAnimSceneEntity(scene, 'ARTHUR', ped, 0)
    if loc.door then
        local door = Citizen.InvokeNative(ANIM.doorEnt, loc.door, 0)
        if door and door ~= 0 then SetAnimSceneEntity(scene, 'Door', door, 0) end
    end

    LoadAnimScene(scene)

    -- ต้นทางรอแบบไม่มี timeout — ถ้า dict ผิดหรือยังไม่สตรีมจะค้างจอถาวร
    -- ของเราตัดที่ 3 วิ แล้วกลับไปใช้ท่าล้างตัวธรรมดาแทน
    local waited = 0
    while not Citizen.InvokeNative(ANIM.isLoaded, scene, 1, 0) do
        Wait(10)
        waited = waited + 1
        if waited > 300 then
            dbg('ฉากโหลดไม่ขึ้นใน 3 วิ: %s / %s', tostring(loc.dict), sceneName)
            Citizen.InvokeNative(ANIM.dispose, scene)
            return false
        end
    end

    StartAnimScene(scene)

    local guard = 0
    while not Citizen.InvokeNative(ANIM.isDone, scene, true) do
        Wait(10)
        guard = guard + 1
        if guard > 3000 then break end -- 30 วิ กันฉากค้างไม่จบ
    end

    if Citizen.InvokeNative(ANIM.exists, scene) then
        Citizen.InvokeNative(ANIM.dispose, scene)
    end
    return true
end

-- ── ท่าค้างระหว่างอาบ ────────────────────────────────────────────────────────
-- ฉาก intro จบแล้ว "ไม่มีอะไรค้างท่าไว้" ตัวละครจะเด้งกลับท่ายืนทันที
-- ตัวที่ค้างท่าคือ move network ซึ่งต้องส่ง struct เข้า native — ทำใน Lua ไม่ได้
-- เลยต้องผ่าน client/structs.js (ยกวิธีมาจาก rsg-bathing/client/structs.js)
local BATH_MOVE_NET = 'Script_Mini_Game_Bathing_Regular'

local function loadBathStreaming()
    RequestAnimDict('MINI_GAMES@BATHING@REGULAR@ARTHUR')
    RequestAnimDict('MINI_GAMES@BATHING@REGULAR@RAG')
    RequestClipSet('CLIPSET@MINI_GAMES@BATHING@REGULAR@ARTHUR')
    RequestClipSet('CLIPSET@MINI_GAMES@BATHING@REGULAR@RAG')
    Citizen.InvokeNative(0x2B6529C54D29037A, BATH_MOVE_NET) -- RequestMoveNetworkDef
    -- โหลดแค่ชุด regular ไม่เอา deluxe เพราะเราไม่ได้ทำโหมดอาบหรู
    Wait(500)
end

local function unloadBathStreaming()
    RemoveAnimDict('MINI_GAMES@BATHING@REGULAR@ARTHUR')
    RemoveAnimDict('MINI_GAMES@BATHING@REGULAR@RAG')
    RemoveClipSet('CLIPSET@MINI_GAMES@BATHING@REGULAR@ARTHUR')
    RemoveClipSet('CLIPSET@MINI_GAMES@BATHING@REGULAR@RAG')
    Citizen.InvokeNative(0x57A197AD83F66BBF, BATH_MOVE_NET)
end

local function taskBathing(entity, clipset)
    TriggerEvent('lp_washing:TaskMoveNetworkWithInitParams',
        { entity, BATH_MOVE_NET, clipset, `DEFAULT`, 'BATHING' })
end

-- intro -> ค้างท่าอาบ -> outro
-- ไม่ได้ทำส่วนถอดเสื้อผ้า/มินิเกมถูตัวของต้นทาง เพราะผูกกับ
-- rsg-appearance + rsg-wardrobe ที่เราไม่มี (ของเราอาบทั้งชุด)
local function playBathScene(loc)
    if not Config.BathHouse.useAnimScene then return false end
    if not loc.dict then return false end

    local ped = PlayerPedId()
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true, 0, true, true)
    HolsterPedWeapons(ped, false, false, false, true)
    loadBathStreaming()

    SetPedCanLegIk(ped, false)
    SetPedLegIkMode(ped, 0)
    ClearPedTasksImmediately(ped, true, true)

    if not runAnimScene(loc, 's_regular_intro') then
        SetPedCanLegIk(ped, true)
        unloadBathStreaming()
        return false
    end

    -- ผ้าถูตัว — move network ของ ARTHUR อ้างถึงผ้าผืนนี้ ถ้าไม่มีท่าจะไม่ครบ
    local rag = nil
    if IsModelValid(`P_CS_RAG02X`) then
        RequestModel(`P_CS_RAG02X`)
        local tries = 0
        while not HasModelLoaded(`P_CS_RAG02X`) and tries < 100 do Wait(10); tries = tries + 1 end
        if HasModelLoaded(`P_CS_RAG02X`) then
            rag = CreateObject(`P_CS_RAG02X`, GetEntityCoords(ped), false, false, false, false, true)
            SetModelAsNoLongerNeeded(`P_CS_RAG02X`)
        end
    end

    ped = PlayerPedId()
    taskBathing(ped, `CLIPSET@MINI_GAMES@BATHING@REGULAR@ARTHUR`)
    if rag then
        taskBathing(rag, `CLIPSET@MINI_GAMES@BATHING@REGULAR@RAG`)
        ForceEntityAiAndAnimationUpdate(rag, true)
    end
    Citizen.InvokeNative(0x55546004A244302A, ped)

    -- Wait(Config.BathHouse.soakMs or 5000)
    cleanPed(PlayerPedId())

    -- ผ้าต้องเก็บก่อนเล่น outro ไม่งั้นค้างลอยอยู่ข้างอ่างเป็นซาก
    if rag and DoesEntityExist(rag) then DeleteEntity(rag) end

    -- intro ผ่านแล้วต้องพยายามเล่น outro ให้ได้ ไม่งั้นตัวละครค้างอยู่ในอ่าง
    runAnimScene(loc, 's_regular_outro')

    local finalPed = PlayerPedId()
    SetPedCanLegIk(finalPed, true)
    ClearPedTasks(finalPed)
    unloadBathStreaming()
    return true
end

-- ── การกระทำ ─────────────────────────────────────────────────────────────────
local function doRiverWash()
    if busy then return end
    if (GetGameTimer() - lastWashAt) < Config.River.cooldownMs then return end

    busy = true
    clearPrompt()

    local ped = PlayerPedId()
    local cancelled = runWashProgress(Config.River.durationMs, Config.River.busyLabel)

    -- ยกเลิกกลางคัน = ไม่ล้าง (ไม่งั้นกดแล้วเดินหนีทันทีก็สะอาดฟรี)
    if not cancelled then
        cleanPed(PlayerPedId())
        notify('ล้างตัวสะอาดแล้ว')
        lastWashAt = GetGameTimer()
    end

    busy = false
end

local function doBath(loc)
    if busy then return end
    busy = true
    clearPrompt()

    -- จ่ายเงินก่อน แล้วค่อยเล่นฉาก — server เป็นคนตัดสินราคาและระยะ
    --
    -- ต้องรับเป็น "ตารางเดียว" ไม่ใช่ ok, reason สองตัว —
    -- TriggerAwait ของ VORP จบที่ Citizen.Await(promise) ซึ่งคืนค่าเดียว
    -- (vorp_core/client/callbacks.lua:60) ค่าที่สองจะหายเงียบ ๆ
    local res = Core.Callback.TriggerAwait('lp_washing:PayBath', loc.id)
    if type(res) ~= 'table' or not res.ok then
        notify((type(res) == 'table' and res.reason) or 'อาบน้ำไม่สำเร็จ')
        busy = false
        return
    end

    -- ถ้าฉากอ่างเล่นได้ ไม่ต้องเฟดจอ — ตัวฉากคือของที่อยากให้ดู
    -- เฟดเฉพาะตอน fallback เพื่อกลบการวาร์ปท่าทาง
    if not playBathScene(loc) then
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
        Wait(300)
        DoScreenFadeIn(500)
        runWashProgress(Config.BathHouse.durationMs, Config.BathHouse.busyLabel)
    end

    -- จ่ายเงินไปแล้ว จึงล้างให้เสมอ ไม่สนว่ากด cancel หลอดหรือเปล่า
    cleanPed(PlayerPedId())
    notify('อาบน้ำเสร็จแล้ว รู้สึกสดชื่น')
    lastWashAt = GetGameTimer()
    busy = false
end

-- ── ลูปหลัก ──────────────────────────────────────────────────────────────────
-- ไม่มีอะไรวาดทุกเฟรม เลยเดินช้าได้ ประหยัดกว่าลูป 0ms ของต้นทางมาก
CreateThread(function()
    while true do
        local sleep = 500

        if busy then
            sleep = 1000
        else
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local bath = getNearbyBath(coords)

            if bath then
                sleep = 200
                if promptOwner ~= 'bath' then
                    clearPrompt()
                    local label = withKey(('%s ($%s)'):format(Config.BathHouse.label, Config.BathHouse.price))
                    if exports.lp_textui:TextUIHold(label, Config.BathHouse.holdMs, function()
                            doBath(bath)
                        end) then
                        promptOwner = 'bath'
                    end
                end

            elseif canWashInRiver(ped) then
                sleep = 200
                if promptOwner ~= 'river' then
                    clearPrompt()
                    if exports.lp_textui:TextUIHold(withKey(Config.River.label), Config.River.holdMs, function()
                            doRiverWash()
                        end) then
                        promptOwner = 'river'
                    end
                end

            else
                clearPrompt()
            end
        end

        Wait(sleep)
    end
end)

-- ── blip จุดอาบน้ำ ───────────────────────────────────────────────────────────
CreateThread(function()
    if not Config.BathHouse.enabled then return end
    for _, loc in ipairs(Config.BathHouse.locations) do
        if loc.blip and loc.blip.enabled then
            local b = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, loc.stand.x, loc.stand.y, loc.stand.z)
            SetBlipSprite(b, loc.blip.sprite, true)
            Citizen.InvokeNative(0x9CB1A1623062F402, b, loc.blip.name or loc.label)
            loc._blip = b
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    clearPrompt()
    for _, loc in ipairs(Config.BathHouse.locations) do
        if loc._blip and DoesBlipExist(loc._blip) then RemoveBlip(loc._blip) end
    end
end)

-- ── เก็บพิกัดจุดอาบน้ำ (เปิดด้วย Config.Debug) ──────────────────────────────
-- เดินไปยืนหน้าอ่างในโรงแรมแล้วพิมพ์ /washpos จะได้บรรทัดพร้อมแปะลง config
CreateThread(function()
    if not Config.Debug then return end
    RegisterCommand('washpos', function()
        local c = GetEntityCoords(PlayerPedId())
        local line = ('stand = vector3(%.4f, %.4f, %.4f),'):format(c.x, c.y, c.z)
        print('[lp_washing] ' .. line)
        notify(line)
    end, false)

    RegisterCommand('washdebug', function()
        local ped = PlayerPedId()
        print(('[lp_washing] inWater=%s swimming=%s canWash=%s busy=%s prompt=%s'):format(
            tostring(IsEntityInWater(ped)), tostring(IsPedSwimming(ped)),
            tostring(canWashInRiver(ped)), tostring(busy), tostring(promptOwner)))
    end, false)
end)
