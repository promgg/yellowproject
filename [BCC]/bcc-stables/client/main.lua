local Core = exports.vorp_core:GetCore()
FeatherMenu =  exports['feather-menu'].initiate()

-- แจ้งเตือนผ่าน pNotify (แทน Core.NotifyRightTip เดิม) — ข้อความไทยอ่านชัด + สไตล์เดียวกับ resource อื่นในเซิร์ฟ
-- kind: 'info'(ค่าเริ่มต้น) / 'success' / 'error' / 'warning'
local function NotifyTip(text, duration, kind)
    exports.pNotify:SendNotification({ text = tostring(text or ''), type = kind or 'info', timeout = tonumber(duration) or 4000 })
end

-- Prompts
local OpenShops, OpenCall, OpenReturn
local ShopGroup = GetRandomIntInRange(0, 0xffffff)

local KeepTame, SellTame
local TameGroup = GetRandomIntInRange(0, 0xffffff)

local TradeHorse
local TradeGroup = GetRandomIntInRange(0, 0xffffff)

local LootHorse
local LootGroup = GetRandomIntInRange(0, 0xffffff)

local invHoldStart = nil -- เวลาเริ่มกดค้างเปิดกระเป๋าม้า (Config.inventoryHoldMs)

-- Target Prompts
local HorseDrink, HorseRest, HorseSleep, HorseWallow = 0, 0, 0, 0

-- Horse Tack
local BedrollsUsing, MasksUsing, MustachesUsing, HolstersUsing = nil, nil, nil, nil
local SaddlesUsing, SaddleclothsUsing, StirrupsUsing, HorseshoesUsing = nil, nil, nil, nil
local BagsUsing, ManesUsing, TailsUsing, SaddleHornsUsing, BridlesUsing = nil, nil, nil, nil, nil

-- Horse Training
local LastLoc, TamedModel, TameToken = nil, nil, nil
local HorseGeneration = 0
local PreviewGeneration = 0
local IsTrainer, IsNaming, MaxBonding, HorseBreed = false, false, false, false
-- โหมดแอดมิน "ดูม้าทุกตัว" (/stablecatalog) — เมื่อ true ร้านจะข้าม saleWhitelist + ข้อจำกัด job โชว์ม้าทั้งหมด
local AdminViewAll = false

-- Misc.
MyHorse = 0
MyModel, MyHorseBreed, MyHorseColor = nil, nil, nil
local ShopEntity, MyEntity = 0, 0
local StableName, Site
local MyEntityID, MyHorseId
local InMenu, HasJob, UsingLantern, PromptsStarted, IsFleeing = false, false, false, false, false
local StableCargoOpen = false
local Drinking, Spawning, Sending, Cam, InWrithe, Activated = false, false, false, false, false, false
local DevModeActive = Config.devMode

function DebugPrint(message)
    if DevModeActive then
        print('^1[DEV MODE] ^4' .. message)
    end
end

local function isShopClosed(shopCfg)
    local hour = GetClockHours()
    local hoursActive = shopCfg.shop.hours.active

    if not hoursActive then
        return false
    end

    local openHour = shopCfg.shop.hours.open
    local closeHour = shopCfg.shop.hours.close

    if openHour < closeHour then
        -- Normal: shop opens and closes on the same day
        return hour < openHour or hour >= closeHour
    else
        -- Overnight: shop closes on the next day
        return hour < openHour and hour >= closeHour
    end
end

local function ManageStableBlip(site, closed)
    local siteCfg = Stables[site]

    if (closed and not siteCfg.blip.showClosed) or (not siteCfg.blip.show) then
        if siteCfg.Blip then
            RemoveBlip(siteCfg.Blip)
            siteCfg.Blip = nil
        end
        return
    end

    if not siteCfg.Blip then
        siteCfg.Blip = Citizen.InvokeNative(0x554d9d53f696d002, 1664425300, siteCfg.npc.coords) -- BlipAddForCoords
        SetBlipSprite(siteCfg.Blip, siteCfg.blip.sprite, true)
        Citizen.InvokeNative(0x9CB1A1623062F402, siteCfg.Blip, siteCfg.blip.name) -- SetBlipName
    end

    local color = siteCfg.blip.color.open
    if siteCfg.shop.jobsEnabled then color = siteCfg.blip.color.job end
    if closed then color = siteCfg.blip.color.closed end

    if Config.BlipColors[color] then
        Citizen.InvokeNative(0x662D364ABF16DE2F, siteCfg.Blip, joaat(Config.BlipColors[color])) -- BlipAddModifier
    else
        DebugPrint('Blip color not defined for color: ' .. tostring(color))
    end
end

local function AddStableNPC(site)
    local siteCfg = Stables[site]

    if not siteCfg.NPC then
        local modelName = siteCfg.npc.model
        local model = joaat(modelName)
        LoadModel(model, modelName)

        siteCfg.NPC = CreatePed(model, siteCfg.npc.coords.x, siteCfg.npc.coords.y, siteCfg.npc.coords.z - 1.0, siteCfg.npc.heading, false, true, true, true)
        Citizen.InvokeNative(0x283978A15512B2FE, siteCfg.NPC, true) -- SetRandomOutfitVariation

        TaskStartScenarioInPlace(siteCfg.NPC, `WORLD_HUMAN_WRITE_NOTEBOOK`, -1, true)
        SetEntityCanBeDamaged(siteCfg.NPC, false)
        SetEntityInvincible(siteCfg.NPC, true)
        Wait(500)
        FreezeEntityPosition(siteCfg.NPC, true)
        SetBlockingOfNonTemporaryEvents(siteCfg.NPC, true)
    end
end

local function RemoveStableNPC(site)
    local siteCfg = Stables[site]

    if siteCfg.NPC then
        DeleteEntity(siteCfg.NPC)
        siteCfg.NPC = nil
    end
end

local function RemoveHorsePrompts()
    local player = PlayerId()
    Citizen.InvokeNative(0xA3DB37EDF9A74635, player, MyHorse, 35, 1, true) -- Hide TARGET_INFO
    Citizen.InvokeNative(0xA3DB37EDF9A74635, player, MyHorse, 33, 1, true) -- Hide HORSE_FLEE
    UiPromptDelete(HorseDrink)
    UiPromptDelete(HorseRest)
    UiPromptDelete(HorseSleep)
    UiPromptDelete(HorseWallow)
    PromptsStarted = false
    invHoldStart = nil -- เดินออกจากระยะ = ล้างการกดค้างที่ค้างอยู่ กันเปิดเองตอนกลับเข้าระยะ
end

CreateThread(function()
    StartPrompts()

    local closedCall = Config.closedCall
    local closedReturn = Config.closedReturn

    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local sleep = 1000

        if InMenu or IsEntityDead(playerPed) then goto END end

        for site, siteCfg in pairs(Stables) do
            local distance = #(playerCoords - siteCfg.npc.coords)
            local isClosed = isShopClosed(siteCfg)

            if siteCfg.blip.show then
                ManageStableBlip(site, isClosed)
            end

            if distance > siteCfg.npc.distance or isClosed then
                RemoveStableNPC(site)
            elseif siteCfg.npc.active then
                AddStableNPC(site)
            end

            if distance <= siteCfg.shop.distance then
                sleep = 0
                if isClosed then
                    local promptText = string.format("%s%s%s%s%s%s", siteCfg.shop.name, _U('hours'), siteCfg.shop.hours.open, _U('to'), siteCfg.shop.hours.close, _U('hundred'))
                    UiPromptSetActiveGroupThisFrame(ShopGroup, CreateVarString(10, 'LITERAL_STRING', promptText), 2, 0, 0, 0)
                    UiPromptSetEnabled(OpenShops, false)
                    UiPromptSetEnabled(OpenCall, closedCall)
                    UiPromptSetEnabled(OpenReturn, closedReturn)
                else
                    UiPromptSetActiveGroupThisFrame(ShopGroup, CreateVarString(10, 'LITERAL_STRING', siteCfg.shop.prompt), 2, 0, 0, 0)
                    UiPromptSetEnabled(OpenShops, true)
                    UiPromptSetEnabled(OpenCall, true)
                    UiPromptSetEnabled(OpenReturn, true)
                end

                local function handlePrompt(prompt)
                    if UiPromptHasStandardModeCompleted(prompt, 0) then
                        if siteCfg.shop.jobsEnabled then
                            CheckPlayerJob(false, site)
                            if not HasJob then return end
                        end

                        if prompt == OpenShops then
                            OpenStable(site)
                        elseif prompt == OpenCall then
                            GetSelectedHorse()
                        elseif prompt == OpenReturn then
                            ReturnHorse()
                        end
                    end
                end

                if isClosed then
                    handlePrompt(OpenCall)
                    handlePrompt(OpenReturn)
                else
                    handlePrompt(OpenShops)
                    handlePrompt(OpenCall)
                    handlePrompt(OpenReturn)
                end
            end
        end
        ::END::
        Wait(sleep)
    end
end)

-- แปลงค่าสถานะเป็นสเกล 0-10 สำหรับโชว์แถบใน UI:
-- ใช้ c.stats (0-10) ถ้ากำหนดไว้ตรง ๆ / ไม่งั้น derive จาก c.attrs (0-100 %) โดยหาร 10 ปัดใกล้สุด
-- (config ส่วนใหญ่กำหนดแค่ attrs → เดิม UI อ่าน stats ไม่เจอเลยโชว์ 4/10 ทุกค่า)
function DeriveStats(c)
    if type(c) ~= 'table' then return nil end
    if type(c.stats) == 'table' then return c.stats end
    if type(c.attrs) == 'table' then
        local a = c.attrs
        local function to10(v) local n = tonumber(v); if not n then return nil end return math.floor(n / 10 + 0.5) end
        return {
            health = to10(a.health), stamina = to10(a.stamina),
            speed = to10(a.speed), acceleration = to10(a.acceleration),
            agility = to10(a.agility), courage = to10(a.courage),
        }
    end
    return nil
end

-- หา meta ของม้าจากชื่อโมเดล ใน config/horses.lua (breed/color/invLimit/stats) — ใช้แนบไปกับ
-- myHorsesData ให้ NUI ใหม่โชว์สถิติ 6 ตัว + สายพันธุ์ + จำนวนช่องกระเป๋า โดยไม่ต้องอ่าน native
function ResolveHorseMeta(model)
    if not model or not Horses then return nil end
    for _, breedEntry in ipairs(Horses) do
        local colors = breedEntry.colors or {}
        local c = colors[model]
        if c then
            return {
                breed = breedEntry.breed,
                color = c.color,
                slots = tonumber(c.invLimit) or 0,
                stats = DeriveStats(c), -- 0-10 (จาก c.stats หรือ derive จาก attrs) — โชว์แถบใน UI เท่านั้น
                attrs = c.attrs, -- { health, speed, acceleration, agility, courage, stamina } เป็น % (0-100) — ค่าสถานะจริงที่มีผลในเกม
            }
        end
    end
    return nil
end

-- ระดับความผูกพันจาก xp — สูตรง่ายๆ ปรับได้ผ่าน Config.stableUI.bondXpPerLevel (ค่าเริ่ม 100)
-- xp เป็นค่าจริงจาก DB (player_horses.xp) ส่วน level ใช้โชว์บนหัวเรื่อง NUI เท่านั้น
function BondLevelFromXp(xp)
    local per = (Config.stableUI and Config.stableUI.bondXpPerLevel) or 100
    return math.floor((tonumber(xp) or 0) / per) + 1
end

local function EnrichHorseData(horseData)
    for _, h in ipairs(horseData or {}) do
        local meta = ResolveHorseMeta(h.model)
        if meta then
            h.breedLabel = meta.breed
            h.colorLabel = meta.color
            h.slots = meta.slots
            h.stats = meta.stats
        else
            -- Keep legacy/custom horses usable when their model is no longer in the shop catalogue.
            h.slots = tonumber(Config.defaultHorseInventoryLimit) or 60
        end
        h.bondLevel = BondLevelFromXp(h.xp)
    end
    return horseData
end

-- Keep the runtime active-horse pointer consistent with the authoritative
-- stable rows before exposing it to NUI. A dead/deleted horse entity must not
-- block summoning another owned horse from the stable.
local function ReconcileActiveHorseForStable(horseData)
    if not MyHorseId then return end

    local activeRow
    for _, horse in ipairs(horseData or {}) do
        if tonumber(horse.id) == tonumber(MyHorseId) then
            activeRow = horse
            break
        end
    end

    local entityExists = MyHorse ~= 0 and DoesEntityExist(MyHorse)
    if activeRow and tonumber(activeRow.dead) ~= 1 and tonumber(activeRow.writhe) ~= 1 and entityExists then return end

    if entityExists then
        SetEntityAsMissionEntity(MyHorse, true, true)
        DeleteEntity(MyHorse)
    end
    Sending = false
    HorseGeneration = HorseGeneration + 1
    MyHorse = 0
    MyHorseId = nil
    InWrithe = false
end

local function SendStableData(horseData, stableMeta)
    ReconcileActiveHorseForStable(horseData)
    EnrichHorseData(horseData)
    SendNUIMessage({
        action = 'show',
        shopData = JobMatchedHorses,
        compData = HorseComp,
        translations = Translations,
        location = StableName,
        currencyType = Config.currencyType,
        myHorsesData = horseData,
        healPrice = (Config.healPrice or 500),
        healCurrencyLabel = ((Config.healCurrency or Config.currencyType) == 1) and '' or '$',
        stableMeta = stableMeta or {},
        activeHorseId = MyHorseId,
        tackColorGroups = Config.TackColorGroups or {}, -- กลุ่ม "สี" (variations) ของอุปกรณ์แต่ละรุ่น สำหรับ color picker
    })
end

function OpenStable(site)
    CheckPlayerJob(false, site)
    DisplayRadar(false)
    InMenu = true
    Site = site
    StableName = Stables[Site].shop.name
    CreateCamera()
    SendNUIMessage({ action = 'loading' })
    SetNuiFocus(true, true)

    local horseData = Core.Callback.TriggerAwait('bcc-stables:GetMyHorses')
    local stableMeta = Core.Callback.TriggerAwait('bcc-stables:GetPlayerStableMeta') or {}
    if horseData then
        SendStableData(horseData, stableMeta)
        SetNuiFocus(true, true)
    else
        SendNUIMessage({ action = 'error', message = 'ไม่สามารถดึงข้อมูลม้าจากเซิร์ฟเวอร์ได้' })
    end
end

local function ClearShopHorse()
    if ShopEntity ~= 0 then
        DeleteEntity(ShopEntity)
        ShopEntity = 0
    end

    if MyEntity ~=0 then
        DeleteEntity(MyEntity)
        MyEntity = 0
    end
end

local function CheckEntityExists(entity)
    local timeout = 10000
    local startTime = GetGameTimer()

    while not DoesEntityExist(entity) do
        if GetGameTimer() - startTime > timeout then
            DebugPrint('Failed to create entity: ' .. tostring(entity))
            return false
        end
        Wait(10)
    end
    return true
end

-- View Horses for Purchase
RegisterNUICallback('loadHorse', function(data, cb)
    PreviewGeneration = PreviewGeneration + 1
    local requestGeneration = PreviewGeneration
    ClearShopHorse()

    local modelName = data.horseModel
    local model = joaat(modelName)
    if not LoadModel(model, modelName) then
        return cb({ ok = false, reason = 'model' })
    end
    if requestGeneration ~= PreviewGeneration then
        SetModelAsNoLongerNeeded(model)
        return cb({ ok = false, reason = 'stale' })
    end

    local siteCfg = Stables[Site]
    local coords = siteCfg.horse.coords
    ShopEntity = CreatePed(model, coords.x, coords.y, coords.z - 1.0, siteCfg.horse.heading, false, false, false, false)

    local entityExists = CheckEntityExists(ShopEntity)
    if not entityExists or requestGeneration ~= PreviewGeneration then
        if ShopEntity ~= 0 then DeleteEntity(ShopEntity) end
        ShopEntity = 0
        return cb({ ok = false, reason = entityExists and 'stale' or 'entity' })
    end
    SetModelAsNoLongerNeeded(model)

    Citizen.InvokeNative(0x283978A15512B2FE, ShopEntity, true) -- SetRandomOutfitVariation
    Citizen.InvokeNative(0x58A850EAEE20FAA3, ShopEntity) -- PlaceObjectOnGroundProperly
    Citizen.InvokeNative(0x7D9EFB7AD6B19754, ShopEntity, true) -- FreezeEntityPosition

    if not Cam then
        Cam = true
        CameraLighting()
    end

    SetBlockingOfNonTemporaryEvents(ShopEntity, true)
    SetPedConfigFlag(ShopEntity, 113, true) -- DisableShockingEvents
    Wait(300)
    Citizen.InvokeNative(0x6585D955A68452A5, ShopEntity) -- ClearPedEnvDirt
    cb({ ok = true })
end)

RegisterNUICallback('BuyHorse', function(data, cb)
    CheckPlayerJob(true, nil)

    if Stables[Site].trainerBuy and not IsTrainer then
        NotifyTip(_U('trainerBuyHorse'), 4000)
        cb({ ok = false, reason = 'trainer_only' })
        StableMenu()
        return
    end

    data.isTrainer = IsTrainer
    data.origin = 'buyHorse'
    data.site = Site

    local canBuy = Core.Callback.TriggerAwait('bcc-stables:BuyHorse', data)
    if canBuy then
        cb({ ok = true })
        SetHorseName(data)
    else
        cb({ ok = false, reason = 'unavailable' })
        StableMenu()
    end
end)

function SetHorseName(data)
    IsNaming = true

    if data.origin ~= 'tameHorse' then
        SendNUIMessage({ action = 'hide' })
        SetNuiFocus(false, false)
        Wait(200)
    end

    AddTextEntry('FMMC_MPM_NA', _U('nameHorse'))
    DisplayOnscreenKeyboard(1, 'FMMC_MPM_NA', '', '', '', '', '', 30)

    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
    end

    if GetOnscreenKeyboardResult() then
        local horseName = GetOnscreenKeyboardResult()
        if string.len(horseName) > 0 then
            data.name = horseName
            if data.origin == 'updateHorse' then
                local nameSaved = Core.Callback.TriggerAwait('bcc-stables:UpdateHorseName', data)
                if nameSaved then
                    StableMenu()
                end
                IsNaming = false
                return
            elseif data.origin == 'buyHorse' then
                data.captured = 0
                data.site = Site
                local horseSaved = Core.Callback.TriggerAwait('bcc-stables:SaveNewHorse', data)
                if horseSaved then
                    StableMenu()
                end
                IsNaming = false
                return
            elseif data.origin == 'tameHorse' then
                data.captured = 1
                local playerPed = PlayerPedId()
                Citizen.InvokeNative(0x48E92D3DDE23C23A, playerPed, 0, 0, 0, 0, data.mount) -- TaskDismountAnimal
                local dismountDeadline = GetGameTimer() + 5000
                while not Citizen.InvokeNative(0x01FEE67DB37F59B2, playerPed) and GetGameTimer() < dismountDeadline do -- IsPedOnFoot
                    Wait(10)
                end
                local horseSaved = Core.Callback.TriggerAwait('bcc-stables:SaveTamedHorse', data)
                if horseSaved then
                    DeleteEntity(data.mount)
                    HorseBreed = false
                    TameToken = nil
                end
                IsNaming = false
                return
            end
        else
            SetHorseName(data)
            return
        end
    end

    if data.origin ~= 'tameHorse' then
        local horseData = Core.Callback.TriggerAwait('bcc-stables:GetMyHorses')
        local stableMeta = Core.Callback.TriggerAwait('bcc-stables:GetPlayerStableMeta') or {}
        if horseData then
            SendStableData(horseData, stableMeta)
            SetNuiFocus(true, true)
        end
    end
    IsNaming = false
end

RegisterNUICallback('RenameHorse', function(data, cb)
    cb('ok')
    data.origin = 'updateHorse'
    SetHorseName(data)
end)

-- View Owned Horse in Stable Menu
RegisterNUICallback('loadMyHorse', function(data, cb)
    PreviewGeneration = PreviewGeneration + 1
    local requestGeneration = PreviewGeneration
    ClearShopHorse()
    MyEntityID = data.HorseId
    local ok, components = pcall(json.decode, data.HorseComp or '{}')
    if not ok or type(components) ~= 'table' then components = {} end

    local modelName = data.HorseModel
    local model = joaat(modelName)
    if not LoadModel(model, modelName) then
        MyEntityID = nil
        return cb({ ok = false, reason = 'model' })
    end
    if requestGeneration ~= PreviewGeneration then
        SetModelAsNoLongerNeeded(model)
        return cb({ ok = false, reason = 'stale' })
    end

    local siteCfg = Stables[Site]
    local coords = siteCfg.horse.coords
    MyEntity = CreatePed(model, coords.x, coords.y, coords.z - 1.0, siteCfg.horse.heading, false, false, false, false)

    local entityExists = CheckEntityExists(MyEntity)
    if not entityExists or requestGeneration ~= PreviewGeneration then
        if MyEntity ~= 0 then DeleteEntity(MyEntity) end
        MyEntity = 0
        MyEntityID = nil
        return cb({ ok = false, reason = entityExists and 'stale' or 'entity' })
    end
    SetModelAsNoLongerNeeded(model)

    Citizen.InvokeNative(0x283978A15512B2FE, MyEntity, true) -- SetRandomOutfitVariation
    Citizen.InvokeNative(0x58A850EAEE20FAA3, MyEntity) -- PlaceObjectOnGroundProperly
    Citizen.InvokeNative(0x7D9EFB7AD6B19754, MyEntity, true) -- FreezeEntityPosition

    if data.HorseGender == 'female' then
        Citizen.InvokeNative(0x5653AB26C82938CF, MyEntity, 41611, 1.0) -- SetCharExpression
        Citizen.InvokeNative(0xCC8CA3E88256E58F, MyEntity, false, true, true, true, false) -- UpdatePedVariation
    end

    if not Cam then
        Cam = true
        CameraLighting()
    end

    SetBlockingOfNonTemporaryEvents(MyEntity, true)
    SetPedConfigFlag(MyEntity, 113, true) -- PCF_DisableShockingEvents
    Wait(300)
    Citizen.InvokeNative(0x6585D955A68452A5, MyEntity) -- ClearPedEnvDirt

    if components and components ~= '[]' then
        for _, component in pairs(components) do
            SetComponent(MyEntity, component)
        end
    end
    cb({ ok = true, horseId = MyEntityID })
end)

RegisterNUICallback('selectHorse', function(data, cb)
    local selected = Core.Callback.TriggerAwait('bcc-stables:SetSelectedHorse', data and data.horseId)
    if not selected then NotifyTip('ไม่สามารถตั้งม้าตัวนี้เป็นม้าหลักได้', 4000) end
    cb({ ok = selected == true })
end)

function GetSelectedHorse()
    local data = Core.Callback.TriggerAwait('bcc-stables:GetHorseData')

    if data == false then
        return DebugPrint('No selected-horse data returned')
    end

    SpawnHorse(data)
end

-- ปิดโรงม้า: ซ่อน NUI, คืน focus/กล้อง/เรดาร์, ลบ preview ped — แยกออกมาให้ callback ใหม่
-- (summonHorse/returnHorse) เรียกใช้ร่วมได้ ไม่ต้องก็อปโค้ด teardown ซ้ำ
function TeardownStable()
    SendNUIMessage({ action = 'hide' })
    SetNuiFocus(false, false)

    Citizen.InvokeNative(0x67C540AA08E4A6F5, 'Leaderboard_Hide', 'MP_Leaderboard_Sounds', true, 0) -- PlaySoundFrontend

    ClearShopHorse()

    Cam = false
    DestroyAllCams(true)
    DisplayRadar(true)
    InMenu = false
    AdminViewAll = false -- ออกจากร้าน = จบโหมดแอดมิน กลับไปโชว์เฉพาะ whitelist ตามปกติ
    ClearPedTasksImmediately(PlayerPedId())
end

RegisterNUICallback('CloseStable', function(data, cb)
    if data.MenuAction == 'save' then
        data.horseId = MyEntityID
        data.components = SaveComps()
        data.site = Site
        local result = Core.Callback.TriggerAwait('bcc-stables:BuyTack', data)
        if not result or result.ok ~= true then
            NotifyTip('ไม่สามารถบันทึกอุปกรณ์ม้าได้', 4000)
            return cb(result or { ok = false, reason = 'failed' })
        end
        cb(result)
        TeardownStable()
        return
    end
    cb({ ok = true })
    TeardownStable()
end)

-- ===== callback ใหม่สำหรับ action bar ของ NUI ใหม่ (ต่อกับฟังก์ชัน/อีเวนต์เดิม ไม่แตะ logic server) =====
-- เรียกม้า: ปิดเมนูก่อน (คืนกล้อง/โฟกัส) แล้ว spawn ม้าตัวหลักออกมาในโลก
RegisterNUICallback('summonHorse', function(data, cb)
    local horseId = data and tonumber(data.horseId)
    if not horseId then return cb({ ok = false, reason = 'invalid_horse' }) end
    if MyHorse ~= 0 and DoesEntityExist(MyHorse) then
        return cb({ ok = false, reason = MyHorseId == horseId and 'already_active' or 'another_active' })
    end
    local horse = Core.Callback.TriggerAwait('bcc-stables:SummonHorse', horseId)
    if not horse then return cb({ ok = false, reason = 'unavailable' }) end
    local spawned = SpawnHorse(horse)
    if spawned ~= true then
        return cb({ ok = false, reason = 'unsafe_spawn' })
    end
    local selected = Core.Callback.TriggerAwait('bcc-stables:SetSelectedHorse', horseId)
    if selected ~= true then
        Sending = false
        HorseGeneration = HorseGeneration + 1
        if MyHorse ~= 0 and DoesEntityExist(MyHorse) then DeleteEntity(MyHorse) end
        MyHorse, MyHorseId = 0, nil
        return cb({ ok = false, reason = 'state_changed' })
    end
    cb({ ok = true })
    TeardownStable()
end)

-- ส่งม้ากลับโรงม้า: ปิดเมนูก่อน แล้วเก็บม้าที่อยู่ในโลก (ReturnHorse จัดการ save + ลบ ped)
RegisterNUICallback('returnHorse', function(data, cb)
    local horseId = data and tonumber(data.horseId)
    if MyHorse == 0 or not DoesEntityExist(MyHorse) then
        return cb({ ok = false, reason = 'not_active' })
    end
    if horseId and tonumber(MyHorseId) ~= horseId then
        return cb({ ok = false, reason = 'different_active' })
    end
    -- Returning an active horse is an in-menu state change. Keep the stable
    -- camera, NUI focus and menu open; the UI refreshes the roster afterward.
    cb({ ok = ReturnHorse() == true })
end)

-- เปิดกระเป๋าอานม้าของม้าที่กำลังพรีวิว — ยิง API เปิดกระเป๋าม้าตรงๆ (ข้ามเช็ค saddlebag component
-- ของ OpenInventory) เพราะกระเป๋าผูกกับ id ม้าตัวนั้นเสมอ (vorp_inventory: 'horse_<id>')
RegisterNUICallback('openCargo', function(data, cb)
    local horseId = (data and data.horseId) or MyEntityID
    if horseId then
        StableCargoOpen = true
        SendNUIMessage({ action = 'pause' })
        SetNuiFocus(false, false)
        local result = Core.Callback.TriggerAwait('bcc-stables:OpenInventoryChecked', horseId, {
            stable = true,
            site = Site
        })
        if not result or result.ok ~= true then
            StableCargoOpen = false
            SendNUIMessage({ action = 'resume' })
            SetNuiFocus(true, true)
        end
        return cb(result or { ok = false, reason = 'failed' })
    end
    cb({ ok = false, reason = 'invalid_horse' })
end)

-- vorp_inventory releases the global NUI focus when it closes. Restore the stable menu
-- that was paused underneath the horse cargo instead of leaving a visible, unclickable UI.
local function restoreStableAfterCargo()
    if not StableCargoOpen then return end
    StableCargoOpen = false
    if InMenu then
        SendNUIMessage({ action = 'resume' })
        DisplayRadar(false)
        SetNuiFocus(true, true)
    end
end

AddEventHandler('syn:closeinv', restoreStableAfterCargo)

AddEventHandler('vorp_inventory:Client:OnInvStateChange', function(isOpen)
    if not isOpen then restoreStableAfterCargo() end
end)

-- รักษาม้าแบบจ่ายเงิน (server ตัดสินราคา/หักเงิน/เติมเลือด ดู server/main.lua bcc-stables:PaidHeal)
RegisterNUICallback('healHorse', function(data, cb)
    local horseId = data and data.horseId
    if horseId then
        local result = Core.Callback.TriggerAwait('bcc-stables:PaidHealRequest', horseId, Site)
        if result and result.ok then
            SendNUIMessage({ action = 'healed', horseId = horseId })
        else
            NotifyTip('ไม่สามารถรักษาม้าตัวนี้ได้', 4000)
        end
        return cb(result or { ok = false, reason = 'failed' })
    end
    cb({ ok = false, reason = 'invalid_horse' })
end)

-- server รักษาม้าสำเร็จ → บอก NUI ให้อัปเดตแถบ HP/สเตมิน่าของม้าตัวนั้นเป็นเต็ม
RegisterNetEvent('bcc-stables:cl:healResult', function(horseId)
    SendNUIMessage({ action = 'healed', horseId = horseId })
end)

-- แจ้งเตือนจาก NUI ใหม่ (ปุ่มไอคอนล้วน — ชื่อ/ผลลัพธ์เด้งเป็น pNotify ฝั่งเกมแทน toast ใน NUI)
RegisterNUICallback('stableNotify', function(data, cb)
    cb('ok')
    exports.pNotify:SendNotification({
        type = (data and data.kind) or 'info',
        text = (data and data.text) or '',
        timeout = (data and data.timeout) or 2500,
    })
end)

RegisterNUICallback('retryStable', function(_, cb)
    local horseData = Core.Callback.TriggerAwait('bcc-stables:GetMyHorses')
    local stableMeta = Core.Callback.TriggerAwait('bcc-stables:GetPlayerStableMeta') or {}
    if not horseData then
        SendNUIMessage({ action = 'error', message = 'เซิร์ฟเวอร์ไม่ตอบกลับ กรุณาลองใหม่' })
        return cb({ ok = false })
    end
    SendStableData(horseData, stableMeta)
    cb({ ok = true })
end)

-- Refresh the owned-horse roster in place after an action. Unlike retryStable,
-- this callback does not reopen/reset the NUI route or rebuild the camera.
RegisterNUICallback('refreshHorseData', function(_, cb)
    local horseData = Core.Callback.TriggerAwait('bcc-stables:GetMyHorses')
    local stableMeta = Core.Callback.TriggerAwait('bcc-stables:GetPlayerStableMeta') or {}
    if not horseData then
        return cb({ ok = false, reason = 'callback_failed' })
    end

    ReconcileActiveHorseForStable(horseData)
    EnrichHorseData(horseData)
    cb({
        ok = true,
        myHorsesData = horseData,
        stableMeta = stableMeta,
        activeHorseId = MyHorseId,
    })
end)

-- Save Horse Tack to Database
function SaveComps()
    return {
        Saddles = SaddlesUsing,
        Saddlecloths = SaddleclothsUsing,
        Stirrups = StirrupsUsing,
        SaddleBags = BagsUsing,
        Manes = ManesUsing,
        Tails = TailsUsing,
        SaddleHorns = SaddleHornsUsing,
        Bedrolls = BedrollsUsing,
        Masks = MasksUsing,
        Mustaches = MustachesUsing,
        Holsters = HolstersUsing,
        Bridles = BridlesUsing,
        Horseshoes = HorseshoesUsing
    }
end

-- Reopen Menu After Sell or Failed Purchase
function StableMenu()
    ClearShopHorse()

    local horseData = Core.Callback.TriggerAwait('bcc-stables:GetMyHorses')
    local stableMeta = Core.Callback.TriggerAwait('bcc-stables:GetPlayerStableMeta') or {}
    if horseData then
        SendStableData(horseData, stableMeta)
        SetNuiFocus(true, true)
    end
end

function SpawnHorse(data)
    if Spawning then
        return
    end
    Spawning = true

    if MyHorse ~= 0 then
        Sending = false
        HorseGeneration = HorseGeneration + 1
        DeleteEntity(MyHorse)
        MyHorse = 0
        MyHorseId = nil
    end

    local pendingHorseId = tonumber(data.id)
    if not pendingHorseId then Spawning = false return false end
    HorseName = data.name
    local xp = data.xp
    local decoded, components = pcall(json.decode, data.components or '{}')
    if not decoded or type(components) ~= 'table' then components = {} end

    local horseModel = data.model
    MyModel = joaat(horseModel)
    if not LoadModel(MyModel, horseModel) then
        Spawning = false
        NotifyTip('โหลดโมเดลม้าไม่สำเร็จ กรุณาลองใหม่', 4000)
        return false
    end

    for _, horseCfg in pairs(Horses) do
        for model, modelCfg in pairs(horseCfg.colors) do
            local horseHash = joaat(model)
            if horseHash == MyModel then
                MyHorseBreed = horseCfg.breed
                MyHorseColor = modelCfg.color
                break
            end
        end
    end

    local player = PlayerId()
    local playerPed = PlayerPedId()
    local x, y, z = table.unpack(GetOffsetFromEntityInWorldCoords(playerPed, 0.0, -10.0, 0.0))
    local spawnPosition = nil
    for height = 1, 1000 do
        local groundCheck, ground = GetGroundZAndNormalFor_3dCoord(x, y, height + 0.0)
        if groundCheck then
            spawnPosition = vector3(x, y, ground)
            break
        end
    end

    local index = 0
    while index < 25 do
        local nodeCheck, node = GetNthClosestVehicleNode(x, y, z, index, 1, 1077936128, 0)
        if nodeCheck then
            spawnPosition = node
            break
        else
            index = index + 3
        end
    end

    if not spawnPosition then
        Spawning = false
        NotifyTip('ไม่พบจุดเรียกม้าที่ปลอดภัย กรุณาขยับตำแหน่งแล้วลองใหม่', 4000)
        return false
    end

    MyHorse = CreatePed(MyModel, spawnPosition.x, spawnPosition.y, spawnPosition.z, GetEntityHeading(playerPed), true, false, false, false)
    local entityExists = CheckEntityExists(MyHorse)
    if not entityExists then
        Spawning = false
        MyHorse = 0
        NotifyTip('ไม่สามารถสร้างม้าได้ กรุณาลองใหม่', 4000)
        return false
    end

    SetModelAsNoLongerNeeded(MyModel)
    HorseGeneration = HorseGeneration + 1
    MyHorseId = pendingHorseId

    LocalPlayer.state.HorseData = {
        MyHorse = NetworkGetNetworkIdFromEntity(MyHorse)
    }

    Citizen.InvokeNative(0x9587913B9E772D29, MyHorse, 0) -- PlaceEntityOnGroundProperly
    Citizen.InvokeNative(0x283978A15512B2FE, MyHorse, true) -- SetRandomOutfitVariation
    if data.gender == 'female' then
        Citizen.InvokeNative(0x5653AB26C82938CF, MyHorse, 41611, 1.0) -- SetCharExpression
        Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse, false, true, true, true, false) -- UpdatePedVariation
    end
    Citizen.InvokeNative(0xD2CB0FB0FDCB473D, playerPed, MyHorse) -- SetPedAsSaddleHorseForPlayer
    Citizen.InvokeNative(0x931B241409216C1F, playerPed, MyHorse, false) -- SetPedOwnsAnimal
    Citizen.InvokeNative(0xB8B6430EAD2D2437, MyHorse, `PLAYER_HORSE`) -- SetPedPersonality
    Citizen.InvokeNative(0xE6D4E435B56D5BD0, player, MyHorse) -- SetPlayerOwnsMount

    -- ModifyPlayerUiPromptForPed / Horse Prompts / (Block = 0, Hide = 1, Grey Out = 2)
    Citizen.InvokeNative(0xA3DB37EDF9A74635, player, MyHorse, 49, 1, true) -- HORSE_BRUSH
    Citizen.InvokeNative(0xA3DB37EDF9A74635, player, MyHorse, 50, 1, true) -- HORSE_FEED
    if not Config.fleeEnabled then
        Citizen.InvokeNative(0xA3DB37EDF9A74635, player, MyHorse, 33, 1, true) -- HORSE_FLEE
    end

    -- Set Horse Health and Stamina
    local health = data.health == nil and 100 or data.health
    Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 0, health)  -- SetAttributeCoreValue

    local stamina = data.stamina == nil and 100 or data.stamina
    Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 1, stamina) -- SetAttributeCoreValue

    -- ── ค่าสถานะจริงต่อม้า (config.attrs) — มีผลต่อการวิ่ง/เลือด/สตามินาในเกมจริง ──────────────
    -- attrs เก็บเป็น % (0-100) ต่อม้า แปลงเป็น attribute points โดยคูณกับเพดานจริงของม้าตัวนั้น
    -- (GetMaxAttributePoints) → "40%" = 40% ของค่าสูงสุดที่ม้าตัวนั้นทำได้ auto-calibrate ตามเกม
    -- index อ้างอิง rsg-horses (RedM ใช้งานจริง): 0=health 1=stamina 4=agility 5=speed 6=accel
    -- courage=3 ยังไม่ยืนยัน 100% — ถ้า index ไม่ตรง SetAttributePoints จะ no-op เฉยๆ ไม่ทำม้าพัง
    local horseMeta = ResolveHorseMeta(horseModel)
    if horseMeta and type(horseMeta.attrs) == 'table' then
        local ATTR_INDEX = { health = 0, stamina = 1, agility = 4, speed = 5, acceleration = 6, courage = 3 }
        for statName, index in pairs(ATTR_INDEX) do
            local pct = tonumber(horseMeta.attrs[statName])
            if pct and pct > 0 then
                local maxPts = Citizen.InvokeNative(0x223BF310F854871C, MyHorse, index) -- GetMaxAttributePoints
                if maxPts and maxPts > 0 then
                    local points = math.floor(maxPts * math.min(pct, 100) / 100)
                    Citizen.InvokeNative(0x09A59688C26D88DF, MyHorse, index, points) -- SetAttributePoints
                end
            end
        end
    end

    -- Bonding
    Citizen.InvokeNative(0x09A59688C26D88DF, MyHorse, 7, xp) -- SetAttributePoints
    local maxXp = Citizen.InvokeNative(0x223BF310F854871C, MyHorse, 7) -- GetMaxAttributePoints
    MaxBonding = false
    if xp >= maxXp then
        MaxBonding = true
    end

    if Config.trainerOnly then
        CheckPlayerJob(true, nil)
        if IsTrainer then
            TriggerEvent('bcc-stables:HorseBonding')
        end
    else
        TriggerEvent('bcc-stables:HorseBonding')
    end

    local currentLevel = Citizen.InvokeNative(0x147149F2E909323C, MyHorse, 7, Citizen.ResultAsInteger()) -- GetAttributeBaseRank

    -- SetPedConfigFlag
    if currentLevel >= 2 then
        Citizen.InvokeNative(0x1913FE4CBF41C463, MyHorse, 113, true) -- DisableShockingEvents
    end
    if currentLevel >= 3 then
        Citizen.InvokeNative(0x1913FE4CBF41C463, MyHorse, 312, true) -- DisableHorseGunshotFleeResponse
    end
    Citizen.InvokeNative(0x1913FE4CBF41C463, MyHorse, 297, true) -- ForceInteractionLockonOnTargetPed / Allow to Lead Horse
    Citizen.InvokeNative(0x1913FE4CBF41C463, MyHorse, 471, Config.disableKick) -- DisableHorseKick

    Citizen.InvokeNative(0xE2487779957FE897, MyHorse, 528) -- SetTransportUsageFlags

    local horseBlip = Citizen.InvokeNative(0x23f74c2fda6e7c61, -1230993421, MyHorse) -- BlipAddForEntity
    Citizen.InvokeNative(0x9CB1A1623062F402, horseBlip, HorseName) -- SetBlipName
    SetPedPromptName(MyHorse, HorseName)

    TriggerServerEvent('bcc-stables:RegisterInventory', MyHorseId, horseModel)

    Entity(MyHorse).state:set('myHorseId', MyHorseId, true)

    if Config.horseTag then
        TriggerEvent('bcc-stables:HorseTag')
    end

    TriggerEvent('bcc-stables:TradeHorse')

    PromptsStarted = false
    TriggerEvent('bcc-stables:HorsePrompts')

    if Config.saveInterval > 0 then
        TriggerEvent('bcc-stables:HorseMonitor')
    end

    if components and components ~= '[]' then
        for _, component in pairs(components) do
            SetComponent(MyHorse, component)
        end
    end

    InWrithe = false
    Activated = false
    LastLoc = nil
    UsingLantern = false
    Spawning = false

    if data.writhe == 1 then
        TriggerEvent('bcc-stables:ManageHorseDeath')
        return false
    end

    Sending = true
    CreateThread(SendHorse)
    return true
end

-- Loot Players Horse Inventory
CreateThread(function()
    if Config.shareInventory then
        while true do
            local horse, horseId, isLeading, owner = nil, nil, nil, nil
            local playerPed = PlayerPedId()
            local sleep = 1000

            if (IsEntityDead(playerPed)) or (not IsPedOnFoot(playerPed)) then goto END end

            horse = Citizen.InvokeNative(0x0501D52D24EA8934, 1, Citizen.ResultAsInteger()) -- Get HorsePedId in Range
            if (horse == 0) or (horse == MyHorse) then goto END end

            owner = Citizen.InvokeNative(0xAD03B03737CE6810, horse) -- GetPlayerOwnerOfMount
            isLeading = Citizen.InvokeNative(0xEFC4303DDC6E60D3, playerPed) -- IsPedLeadingHorse
            if (owner == 255) or isLeading then goto END end

            sleep = 0
            UiPromptSetActiveGroupThisFrame(LootGroup, CreateVarString(10, 'LITERAL_STRING', _U('lootInventory')), 1, 0, 0, 0)
            if UiPromptHasStandardModeCompleted(LootHorse, 0) then
                horseId = Entity(horse).state.myHorseId
                OpenInventory(horse, horseId, true)
            end
            ::END::
            Wait(sleep)
        end
    end
end)

-- Set Horse Name and Health Bar Above Horse
AddEventHandler('bcc-stables:HorseTag', function()
    local generation, horse, horseId = HorseGeneration, MyHorse, MyHorseId
    local tagDistance = Config.tagDistance
    local gamerTagId = Citizen.InvokeNative(0xE961BF23EAB76B12, MyHorse, HorseName) -- CreateMpGamerTagOnEntity
    Citizen.InvokeNative(0x5F57522BC1EB9D9D, gamerTagId, `PLAYER_HORSE`) -- SetMpGamerTagTopIcon

    while MyHorse == horse and MyHorseId == horseId and generation == HorseGeneration and DoesEntityExist(horse) do
        Wait(1000)

        local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(MyHorse))
        if dist < tagDistance and Citizen.InvokeNative(0xAAB0FE202E9FC9F0, MyHorse, -1) then -- IsMountSeatFree
            Citizen.InvokeNative(0x93171DDDAB274EB8, gamerTagId, 3) -- SetMpGamerTagVisibility
        else
            if Citizen.InvokeNative(0x502E1591A504F843, gamerTagId, MyHorse) then -- IsMpGamerTagActiveOnEntity
                Citizen.InvokeNative(0x93171DDDAB274EB8, gamerTagId, 0) -- SetMpGamerTagVisibility
            end
        end
    end

    Citizen.InvokeNative(0x839BFD7D7E49FE09, Citizen.PointerValueIntInitialized(gamerTagId)) -- RemoveMpGamerTag
end)

-- Manage Horse Lockon Prompts
local function HandleHorseAction(key, action)
    if Citizen.InvokeNative(0x580417101DDB492F, 0, key) and not Drinking then
        action()
    end
end

AddEventHandler('bcc-stables:HorsePrompts', function()
    local generation, horse, horseId = HorseGeneration, MyHorse, MyHorseId
    local player = PlayerId()
    local fleeEnabled = Config.fleeEnabled
    local distanceCheckEnabled = Config.horseDistance.enabled
    local horseRadius = Config.horseDistance.radius
    local drinkKey = Config.keys.drink
    local restKey = Config.keys.rest
    local sleepKey = Config.keys.sleep
    local wallowKey = Config.keys.wallow

    while MyHorse == horse and MyHorseId == horseId and generation == HorseGeneration and DoesEntityExist(horse) do
        local playerPed = PlayerPedId()
        local sleep = 1000
        local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(MyHorse))

        if distanceCheckEnabled and distance > horseRadius then
            SaveHorseStats(InWrithe)
            Sending = false
            HorseGeneration = HorseGeneration + 1
            DeleteEntity(MyHorse)
            MyHorse = 0
            MyHorseId = nil
            goto END
        end

        if (IsPlayerFreeAiming(player)) or (distance > 2.8) or (IsEntityDead(playerPed)) then
            RemoveHorsePrompts()
            goto END
        end

        sleep = 0

        -- ซ่อน prompt "Horse Cargo [B]" ของตัวเกม: ปิด control ปุ่ม B ทุกเฟรมตอนอยู่ในระยะ
        -- prompt native ผูกกับ control ตัวนี้ พอถูก disable ทั้ง prompt หายและกด B เปิดเมนู
        -- default ไม่ได้ เหลือแต่ทางของ resource (ปุ่ม inventory ด้านล่าง)
        if Config.hideGameCargoPrompt then
            DisableControlAction(0, `INPUT_OPEN_SATCHEL_HORSE_MENU`, true)
        end

        -- เปิดกระเป๋าม้า — รองรับทั้ง "กดทีเดียว" และ "กดค้าง" ตาม Config.inventoryHoldMs
        -- ใช้ IsDisabledControl* (ไม่ใช่ตัวปกติ) เพราะเกมปิดอินพุตบางตัวตอนขี่ม้าอยู่
        -- ห่อ do...end กัน 'goto END' ด้านล่างกระโดดข้าม local เข้ามาในขอบเขต (Lua ห้าม)
        do
            local holdMs = Config.inventoryHoldMs or 0
            local openNow = false

            if holdMs > 0 then
                -- กดค้าง: นับเวลาตั้งแต่เริ่มกด ครบ holdMs = เปิด ปล่อยก่อน = รีเซ็ต
                if Citizen.InvokeNative(0xE2587F8CBBD87B1D, 0, Config.keys.inventory) then -- IsDisabledControlPressed
                    if not invHoldStart then invHoldStart = GetGameTimer() end
                    if (GetGameTimer() - invHoldStart) >= holdMs then
                        openNow = true
                        invHoldStart = nil
                    end
                else
                    invHoldStart = nil
                end
            else
                openNow = Citizen.InvokeNative(0x91AEF906BCA88877, 0, Config.keys.inventory) -- IsDisabledControlJustPressed
            end

            if openNow then
                if LocalPlayer.state.IsInvActive then
                    exports.vorp_inventory:closeInventory()
                else
                    OpenInventory(MyHorse, MyHorseId, false)
                end
            end
        end

        if InWrithe and Citizen.InvokeNative(0x91AEF906BCA88877, 0, `INPUT_REVIVE`) then  -- IsDisabledControlJustPressed
            TriggerEvent('bcc-stables:ReviveHorse')
            goto END
        end

        Citizen.InvokeNative(0xA3DB37EDF9A74635, player, MyHorse, 35, 1, false) -- Show TARGET_INFO
        Citizen.InvokeNative(0xA3DB37EDF9A74635, player, MyHorse, 33, 1, false) -- Show HORSE_FLEE

        if Citizen.InvokeNative(0x27F89FDC16688A7A, player, MyHorse, false) then -- IsPlayerTargettingEntity
            sleep = 0
            local menuGroup = Citizen.InvokeNative(0xB796970BD125FCE8, MyHorse) -- PromptGetGroupIdForTargetEntity
            HorseTargetPrompts(menuGroup)

            HandleHorseAction(drinkKey, HorseDrinking)
            HandleHorseAction(restKey, HorseResting)
            HandleHorseAction(sleepKey, HorseSleeping)
            HandleHorseAction(wallowKey, HorseWallowing)

            if fleeEnabled and Citizen.InvokeNative(0x580417101DDB492F, 0, `INPUT_HORSE_COMMAND_FLEE`) then -- IsControlJustPressed
                FleeHorse()
            end
        end
        ::END::
        Wait(sleep)
    end
end)

function HorseDrinking()
    if not IsEntityInWater(MyHorse) then
        NotifyTip(HorseName .. _U('needWater'), 4000)
        return
    end

    Drinking = true
    local drinkTime = Config.drinkLength * 1000
    local dict = 'amb_creature_mammal@world_horse_drink_ground@idle'

    if LoadAnim(dict) then
        TaskPlayAnim(MyHorse, dict, 'idle_a', 1.0, 1.0, drinkTime, 3, 1.0, false, false, false)
    end

    Wait(drinkTime)

    local health = Citizen.InvokeNative(0x36731AC041289BB1, MyHorse, 0, Citizen.ResultAsInteger()) -- GetAttributeCoreValue
    local stamina = Citizen.InvokeNative(0x36731AC041289BB1, MyHorse, 1, Citizen.ResultAsInteger()) -- GetAttributeCoreValue

    if health < 100 or stamina < 100 then
        local authorized = Core.Callback.TriggerAwait('bcc-stables:AuthorizeCoreGain', MyHorseId, 'drink')
        if authorized ~= true then
            Drinking = false
            return
        end
        local healthBoost = Config.boost.drinkHealth
        local staminaBoost = Config.boost.drinkStamina

        if healthBoost > 0 then
            local newHealth = math.min(health + healthBoost, 100)
            Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 0, newHealth) -- SetAttributeCoreValue
        end

        if staminaBoost > 0 then
            local newStamina = math.min(stamina + staminaBoost, 100)
            Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 1, newStamina) -- SetAttributeCoreValue
        end
        SaveHorseStats(false, true)

        if Config.horseXpPerDrink > 0 and not MaxBonding then
            if not Config.trainerOnly or (Config.trainerOnly and IsTrainer) then
                SaveXp('drink')
            end
        end

        Citizen.InvokeNative(0x67C540AA08E4A6F5, 'Core_Fill_Up', 'Consumption_Sounds', true, 0) -- PlaySoundFrontend
    end

    Drinking = false
end

function HorseResting()
    if not Citizen.InvokeNative(0xAAB0FE202E9FC9F0, MyHorse, -1) then -- IsMountSeatFree
        return
    end

    local dict = 'amb_creature_mammal@world_horse_resting@idle'

    if LoadAnim(dict) then
        TaskPlayAnim(MyHorse, dict, 'idle_a', 1.0, 1.0, -1, 3, 1.0, false, false, false)
    end
end

function HorseSleeping()
    if not Citizen.InvokeNative(0xAAB0FE202E9FC9F0, MyHorse, -1) then -- IsMountSeatFree
        return
    end

    local dict = 'amb_creature_mammal@world_horse_sleeping@base'

    if LoadAnim(dict) then
        TaskPlayAnim(MyHorse, dict, 'base', 1.0, 1.0, -1, 3, 1.0, false, false, false)
    end
end

function HorseWallowing()
    if not Citizen.InvokeNative(0xAAB0FE202E9FC9F0, MyHorse, -1) then -- IsMountSeatFree
        return
    end

    local dict = 'amb_creature_mammal@world_horse_wallow_shake@idle'

    if LoadAnim(dict) then
        TaskPlayAnim(MyHorse, dict, 'idle_a', 1.0, 1.0, -1, 3, 1.0, false, false, false)
    end
end

function LoadAnim(dict)
    RequestAnimDict(dict)
    local startTime = GetGameTimer()
    local timeout = 5000

    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() - startTime > timeout then
            DebugPrint('Failed to load animation dictionary ' .. dict)
            return false
        end
        Wait(10)
    end
    return true
end

-- Event Listener
CreateThread(function()
    local writheEnabled = Config.death.writheEnabled
    while true do
        Wait(0)

        local size = GetNumberOfEvents(0)
        if size > 0 then
            for i = 0, size - 1 do
                local event = Citizen.InvokeNative(0xA85E614430EFF816, 0, i) -- GetEventAtIndex

                if event == 1327216456 then -- EVENT_PED_WHISTLE
                    local eventDataSize = 2
                    local eventDataStruct = DataView.ArrayBuffer(128)
                    eventDataStruct:SetInt32(0, 0) -- whistler ped id
                    eventDataStruct:SetInt32(8, 0) -- whistle type

                    local data = Citizen.InvokeNative(0x57EC5FA4D4D6AFCA, 0, i, eventDataStruct:Buffer(), eventDataSize) -- GetEventData
                    if data then
                        if eventDataStruct:GetInt32(0) == PlayerPedId() then
                            if eventDataStruct:GetInt32(8) ~= 869278708 then -- WHISTLEHORSELONG
                                TriggerEvent('bcc-stables:WhistleHorse')
                            else
                                TriggerEvent('bcc-stables:LongWhistleHorse')
                            end
                        end
                    end

                elseif event == 218595333 then -- EVENT_HORSE_BROKEN
                    local eventDataSize = 3
                    local eventDataStruct = DataView.ArrayBuffer(128)
                    eventDataStruct:SetInt32(0, 0)  -- Rider Ped Id
                    eventDataStruct:SetInt32(8, 0)  -- Horse Ped Id
                    eventDataStruct:SetInt32(16, 0) -- Broken Type Id

                    local data = Citizen.InvokeNative(0x57EC5FA4D4D6AFCA, 0, i, eventDataStruct:Buffer(), eventDataSize) -- GetEventData
                    if data then
                        if eventDataStruct:GetInt32(16) == 2 then -- Horse Taming Successful
                            local tamedPedId = eventDataStruct:GetInt32(8)
                            local tamedNetId = NetworkGetNetworkIdFromEntity(tamedPedId)
                            Entity(tamedPedId).state:set('netId', tamedNetId, true)
                            local modelHash = GetEntityModel(tamedPedId)
                            local modelName
                            for _, horseCfg in pairs(Horses) do
                                for candidate in pairs(horseCfg.colors) do
                                    if joaat(candidate) == modelHash then modelName = candidate break end
                                end
                                if modelName then break end
                            end
                            if modelName then
                                local authorization = Core.Callback.TriggerAwait('bcc-stables:AuthorizeTamedHorse', modelName, tamedNetId)
                                if authorization and authorization.ok then TameToken = authorization.token end
                            end
                        end
                    end

                elseif event == 2145012826 then -- EVENT_ENTITY_DESTROYED 
                    local eventDataSize = 9
                    local eventDataStruct = DataView.ArrayBuffer(128)
                    eventDataStruct:SetInt32(0, 0)  -- Destroyed Entity Id
                    eventDataStruct:SetInt32(8, 0)  -- Object/Ped Id that Damaged Entity
                    eventDataStruct:SetInt32(16, 0) -- Weapon Hash that Damaged Entity
                    eventDataStruct:SetInt32(24, 0) -- Ammo Hash that Damaged Entity
                    eventDataStruct:SetInt32(32, 0) -- (float) Damage Amount
                    eventDataStruct:SetInt32(40, 0) -- Unknown
                    eventDataStruct:SetInt32(48, 0) -- (float) Entity Coord x
                    eventDataStruct:SetInt32(56, 0) -- (float) Entity Coord y
                    eventDataStruct:SetInt32(64, 0) -- (float) Entity Coord z

                    local data = Citizen.InvokeNative(0x57EC5FA4D4D6AFCA, 0, i, eventDataStruct:Buffer(), eventDataSize) -- GetEventData
                    local entity = eventDataStruct:GetInt32(0)
                    if data then
                        if entity == MyHorse then
                            if writheEnabled then
                                TriggerEvent('bcc-stables:ManageHorseDeath')
                            else
                                TriggerServerEvent('bcc-stables:UpdateHorseStatus', MyHorseId, 'dead')
                                Wait(5000)
                                SaveHorseStats(true)
                                DeleteEntity(MyHorse)
                                Sending = false
                                HorseGeneration = HorseGeneration + 1
                                MyHorse = 0
                                MyHorseId = nil
                            end
                        end
                    end
                end
            end
        end
    end
end)

AddEventHandler('bcc-stables:ManageHorseDeath', function()
    if not InWrithe then
        InWrithe = true
        Citizen.InvokeNative(0x71BC8E838B9C6035, MyHorse) -- ResurrectPed
        Citizen.InvokeNative(0x1913FE4CBF41C463, MyHorse, 136, false)-- SetPedConfigFlag / CannotBeMounted
        Citizen.InvokeNative(0x8C038A39C4A4B6D6, MyHorse, 0, 0) -- TaskAnimalWrithe
        Wait(100)
        Citizen.InvokeNative(0x925A160133003AC6, MyHorse, true) -- SetPausePedWritheBleedout
        RemoveHorsePrompts()

        NotifyTip(_U('horseWrithe'), 4000)

        TriggerServerEvent('bcc-stables:SetHorseWrithe', MyHorseId)

        SaveHorseStats(true)
    else
        NotifyTip(_U('horseDied'), 4000)
        TriggerServerEvent('bcc-stables:UpdateHorseStatus', MyHorseId, 'dead')

        Wait(5000)
        SaveHorseStats(true)
        DeleteEntity(MyHorse)
        Sending = false
        HorseGeneration = HorseGeneration + 1
        MyHorse = 0
        MyHorseId = nil
        InWrithe = false
    end
end)

-- Call Horse to Player
AddEventHandler('bcc-stables:WhistleHorse', function()
    if MyHorse == 0 then
        WhistleSpawn()
        return
    end

    if Citizen.InvokeNative(0x77F1BEB8863288D5, MyHorse, 0x4924437D, false) ~= 0 then -- GetScriptTaskStatus / SCRIPT_TASK_GO_TO_ENTITY
        local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(MyHorse))

        if dist >= 100 then
            Sending = false
            HorseGeneration = HorseGeneration + 1
            DeleteEntity(MyHorse)
            MyHorse = 0
            MyHorseId = nil
            GetSelectedHorse()
        else
            Sending = true
            CreateThread(SendHorse)
        end
    end
end)

-- Call Horse or have Horse Follow Player
AddEventHandler('bcc-stables:LongWhistleHorse', function()
    local playerPed = PlayerPedId()

    if MyHorse == 0 then
        WhistleSpawn()
        return
    end

    if Citizen.InvokeNative(0x77F1BEB8863288D5, MyHorse, 0x4924437D, 0) ~= 0 then -- GetScriptTaskStatus
        local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(MyHorse))

        if dist <= 45 then
            if Citizen.InvokeNative(0x77F1BEB8863288D5, MyHorse, 0x3EF867F4, 0) ~= 1 then -- GetScriptTaskStatus
                Citizen.InvokeNative(0x304AE42E357B8C7E, MyHorse, playerPed, math.random(1.0, 4.0), math.random(5.0, 8.0), 0.0, 0.7, -1, 3.0, true) -- TaskFollowToOffsetOfEntity
            else
                ClearPedTasks(MyHorse)
            end
        end
    end
end)

function WhistleSpawn()
    if Config.whistleSpawn then
        GetSelectedHorse()
    else
        NotifyTip(_U('stableSpawn'), 4000)
    end
end

-- Move horse to Player
function SendHorse()
    local playerPed = PlayerPedId()
    local horse, horseId, generation = MyHorse, MyHorseId, HorseGeneration
    local deadline = GetGameTimer() + 30000

    if horse == 0 or not DoesEntityExist(horse) then Sending = false return end
    TaskGoToEntity(horse, playerPed, -1, 10.2, 2.0, 0.0, 0)

    while Sending and MyHorse == horse and MyHorseId == horseId and generation == HorseGeneration
        and DoesEntityExist(horse) and GetGameTimer() < deadline do
        Wait(100)
        local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(horse))
        if dist <= 10.0 then
            ClearPedTasks(horse)
            Sending = false
        end
    end
    if MyHorse == horse and generation == HorseGeneration then Sending = false end
end

-- Wild Horse Taming
CreateThread(function()
    local horseModel

    while true do
        local mount = Citizen.InvokeNative(0xE7E11B8DCBED1058, PlayerPedId()) -- GetMount
        if not mount or mount == MyHorse then
            goto END
        end

        horseModel = GetEntityModel(mount)

        for _, horseCfg in pairs(Horses) do
            for model, modelCfg in pairs(horseCfg.colors) do
                local horseHash = joaat(model)
                if horseHash == horseModel then
                    TamedModel = model
                    if Config.displayHorseBreed and not HorseBreed then
                        if horseCfg.breed == 'Other' then
                            Core.NotifyBottomRight(modelCfg.color, 1000)
                        else
                            Core.NotifyBottomRight(horseCfg.breed, 1000)
                        end
                        HorseBreed = true
                    end
                end
            end
        end
        ::END::
        Wait(1000)
    end
end)

CreateThread(function()
    local mount = 0
    local mountNetId, tamedNetId
    local allowSale = Config.allowSale
    local allowKeep = Config.allowKeep
    local trainerOnly = Config.trainerOnly

    while true do
        local playerPed = PlayerPedId()
        local sleep = 1000

        if IsEntityDead(playerPed) then goto END end

        mount = Citizen.InvokeNative(0xE7E11B8DCBED1058, playerPed) -- GetMount
        if mount and mount ~= 0 then
            mountNetId = NetworkGetNetworkIdFromEntity(mount)
            tamedNetId = Entity(mount).state.netId
        end

        for site, siteCfg in pairs(Trainers) do
            local distance = #(GetEntityCoords(playerPed) - siteCfg.npc.coords)

            if siteCfg.blip.show and not siteCfg.TrainerBlip then
                AddTrainerBlip(site)
                Citizen.InvokeNative(0x662D364ABF16DE2F, siteCfg.TrainerBlip, joaat(Config.BlipColors[siteCfg.blip.color])) -- BlipAddModifier
            end

            if siteCfg.npc.active then
                if distance <= siteCfg.npc.distance then
                    if not siteCfg.TrainerNPC then
                        AddTrainerNPC(site)
                    end
                elseif siteCfg.TrainerNPC then
                    DeleteEntity(siteCfg.TrainerNPC)
                    siteCfg.TrainerNPC = nil
                end
            end

            if (distance <= siteCfg.shop.distance) and (IsPedOnMount(playerPed)) and (mountNetId == tamedNetId) and (not IsNaming) then
                sleep = 0
                UiPromptSetActiveGroupThisFrame(TameGroup, CreateVarString(10, 'LITERAL_STRING', siteCfg.shop.prompt), 1, 0, 0, 0)

                UiPromptSetVisible(SellTame, allowSale)
                UiPromptSetEnabled(SellTame, allowSale)

                UiPromptSetVisible(KeepTame, allowKeep)
                UiPromptSetEnabled(KeepTame, allowKeep)

                if Citizen.InvokeNative(0xE0F65F0640EF0617, SellTame) then  -- PromptHasHoldModeCompleted
                    local onCooldown = Core.Callback.TriggerAwait('bcc-stables:CheckPlayerCooldown', 'sellTame')
                    if onCooldown then
                        NotifyTip(_U('sellCooldown'), 4000)
                        HorseBreed = false
                        goto END
                    end

                    if trainerOnly then
                        CheckPlayerJob(true, nil)
                        if not IsTrainer then
                            NotifyTip(_U('trainerSellHorse'), 4000)
                            HorseBreed = false
                            goto END
                        end
                    end

                    local sold = Core.Callback.TriggerAwait('bcc-stables:SellTamedHorseChecked', TamedModel, NetworkGetNetworkIdFromEntity(mount), TameToken)

                    if sold and sold.ok and mount ~= 0 then
                        Citizen.InvokeNative(0x48E92D3DDE23C23A, playerPed, 0, 0, 0, 0, mount) -- TaskDismountAnimal

                        local dismountDeadline = GetGameTimer() + 5000
                        while not Citizen.InvokeNative(0x01FEE67DB37F59B2, playerPed) and GetGameTimer() < dismountDeadline do -- IsPedOnFoot
                            Wait(10)
                        end

                        NotifyTip(_U('tamedCooldown') .. Config.cooldown.sellTame .. _U('minutes'), 4000)
                        DeleteEntity(mount)
                        mount = 0
                        Wait(200)
                        HorseBreed = false
                        TameToken = nil
                    elseif not sold or not sold.ok then
                        NotifyTip('ไม่สามารถขายม้าตัวนี้ได้', 4000)
                    end
                end

                if Citizen.InvokeNative(0xE0F65F0640EF0617, KeepTame) then  -- PromptHasHoldModeCompleted
                    CheckPlayerJob(true, nil)
                    if trainerOnly then
                        if not IsTrainer then
                            NotifyTip(_U('trainerRegHorse'), 4000)
                            HorseBreed = false
                            goto END
                        end
                    end

                    local tameData = {
                        isTrainer = IsTrainer,
                        ModelH = TamedModel,
                        origin = 'tameHorse',
                        IsCash = true,
                        gender = IsPedMale(mount) and 'male' or 'female',
                        mount = mount,
                        mountNetId = NetworkGetNetworkIdFromEntity(mount),
                        tameToken = TameToken
                    }

                    local canKeep = Core.Callback.TriggerAwait('bcc-stables:RegisterHorse', tameData)
                    if canKeep and canKeep.ok then
                        SetHorseName(tameData)
                    else
                        HorseBreed = false
                    end
                end
            end
        end
        ::END::
        Wait(sleep)
    end
end)

AddEventHandler('bcc-stables:HorseMonitor', function()
    local generation, horse, horseId = HorseGeneration, MyHorse, MyHorseId
    local intervalValue = Config.saveInterval * 1000
    local interval = intervalValue
    local checkInterval = 1000

    while MyHorse == horse and MyHorseId == horseId and generation == HorseGeneration and DoesEntityExist(horse) do
        Wait(checkInterval)

        interval = interval - checkInterval

        if interval <= 0 and not IsFleeing then
            SaveHorseStats(InWrithe)
            interval = intervalValue
        end
    end
end)


AddEventHandler('bcc-stables:ReviveHorse', function()
    local hasItem = Core.Callback.TriggerAwait('bcc-stables:HorseReviveItem', MyHorseId)

    if not hasItem then
        NotifyTip(_U('noReviver'), 4000)
        return
    end

    if not IsEntityDead(MyHorse) then
        Citizen.InvokeNative(0x356088527D9EBAAD, PlayerPedId(), MyHorse, `s_inv_horsereviver01x`) -- TaskReviveTarget
        TriggerServerEvent('bcc-stables:UpdateHorseStatus', MyHorseId, 'revive')
        SetEntityHealth(MyHorse, GetEntityMaxHealth(MyHorse), 0)
        SaveHorseStats(true)
        InWrithe = false
    end
end)

function OpenInventory(horsePedId, horseId, isLooting)
    local hasSaddlebags = Citizen.InvokeNative(0xFB4891BD7578CDC1, horsePedId, -2142954459) -- IsMetaPedUsingComponent

    if not isLooting and Config.useSaddlebags and not hasSaddlebags then
        NotifyTip(_U('noSaddlebags'), 4000)
        return
    end

    if hasSaddlebags then
        Citizen.InvokeNative(0xCD181A959CFDD7F4, PlayerPedId(), horsePedId, `Interaction_LootSaddleBags`, 0, true) -- TaskAnimalInteraction
    end

    TriggerServerEvent('bcc-stables:OpenInventory', horseId)
end

function FleeHorse()
    IsFleeing = true
    SaveHorseStats(false, true)

    GetControlOfHorse()

    Citizen.InvokeNative(0x22B0D0E37CCB840D, MyHorse, PlayerPedId(), 150.0, 10000, 6, 3.0) -- TaskSmartFleePed
    Wait(10000)
    DeleteEntity(MyHorse)
    Sending = false
    HorseGeneration = HorseGeneration + 1
    MyHorse = 0
    MyHorseId = nil
    IsFleeing = false
end

function ReturnHorse()
    local playerPed = PlayerPedId()

    if not MyHorse or MyHorse == 0 then
        NotifyTip(_U('noHorse'), 4000)
        return false
    end

    if Citizen.InvokeNative(0x460BC76A0E10655E, playerPed) then -- IsPedOnMount
        Citizen.InvokeNative(0x48E92D3DDE23C23A, playerPed, 0, 0, 0, 0, MyHorse) -- TaskDismountAnimal
        local dismountDeadline = GetGameTimer() + 5000
        while not Citizen.InvokeNative(0x01FEE67DB37F59B2, playerPed) and GetGameTimer() < dismountDeadline do -- IsPedOnFoot
            Wait(10)
        end
    end

    if not SaveHorseStats(InWrithe, true) then
        NotifyTip('บันทึกสถานะม้าไม่สำเร็จ กรุณาลองใหม่', 4000)
        return false
    end
    GetControlOfHorse()
    Sending = false
    HorseGeneration = HorseGeneration + 1
    DeleteEntity(MyHorse)
    MyHorse = 0
    MyHorseId = nil
    NotifyTip(_U('horseReturned'), 4000, 'success')
    return true
end

function GetControlOfHorse()
    local entity = MyHorse
    local deadline = GetGameTimer() + 3000
    while DoesEntityExist(entity) and not NetworkHasControlOfEntity(entity) and GetGameTimer() < deadline do
        NetworkRequestControlOfEntity(entity)
        Wait(100)
    end
    return DoesEntityExist(entity) and NetworkHasControlOfEntity(entity)
end

AddEventHandler('bcc-stables:HorseBonding', function()
    local trainingDistance = Config.trainingDistance
    local generation = HorseGeneration
    local horseId = MyHorseId

    while not MaxBonding and MyHorse ~= 0 and DoesEntityExist(MyHorse) and generation == HorseGeneration and horseId == MyHorseId do
        Wait(5000)

        local playerPed = PlayerPedId()
        local lastLed = Citizen.InvokeNative(0x693126B5D0457D0D, playerPed)   -- GetLastLedMount
        local isLeading = Citizen.InvokeNative(0xEFC4303DDC6E60D3, playerPed) -- IsPedLeadingHorse
        local currentMount = Citizen.InvokeNative(0x4C8B59171957BCF7, playerPed) -- GetLastMount
        local isMounted = Citizen.InvokeNative(0x460BC76A0E10655E, playerPed) -- IsPedOnMount

        if ((lastLed == MyHorse and isLeading) or (MyHorse == currentMount and isMounted)) then
            local currentCoords = GetEntityCoords(MyHorse)

            if LastLoc == nil then
                LastLoc = currentCoords
            else
                local dist = #(LastLoc - currentCoords)
                if dist >= trainingDistance then
                    LastLoc = currentCoords
                    SaveXp('travel')
                end
            end
        end
    end
end)

function SaveXp(xpSource)
    local horseXp = nil
    local updateXp = {
        ['travel'] = Config.horseXpPerCheck,
        ['brush'] = Config.horseXpPerBrush,
        ['feed'] = Config.horseXpPerFeed,
        ['drink'] = Config.horseXpPerDrink
    }

    horseXp = updateXp[xpSource]
    if not horseXp then
        return DebugPrint('No xpSource data: ' .. tostring(xpSource))
    end

    local applied = Core.Callback.TriggerAwait('bcc-stables:ApplyHorseXp', MyHorseId, xpSource)
    if type(applied) ~= 'table' or applied.ok ~= true then return end

    Citizen.InvokeNative(0x75415EE0CB583760, MyHorse, 7, horseXp) -- AddAttributePoints

    if Config.showXpMessage then
        NotifyTip('+ ' .. horseXp .. ' XP', 2000, 'success')
    end

    local maxXp = Citizen.InvokeNative(0x223BF310F854871C, MyHorse, 7) -- GetMaxAttributePoints
    local newXp = Citizen.InvokeNative(0x219DA04BAA9CB065, MyHorse, 7, Citizen.ResultAsInteger()) -- GetAttributePoints

    MaxBonding = newXp >= maxXp

end

RegisterNetEvent('bcc-stables:BrushHorse', function(simpleBrushItem)
    if not MyHorse or MyHorse == 0 then
        return NotifyTip(_U('noHorse'), 4000)
    end

    local playerPed = PlayerPedId()
    local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(MyHorse))

    if distance > 3.5 then
        return NotifyTip(_U('tooFar'), 4000)
    end

    local skipDurability = type(simpleBrushItem) == 'string'
    if skipDurability then
        local consumed = Core.Callback.TriggerAwait('bcc-stables:UseSimpleBrush', MyHorseId, simpleBrushItem)
        if consumed ~= true then
            return NotifyTip('ไม่สามารถใช้แปรงกับม้าตัวนี้ได้', 4000)
        end
    else
        local authorized = Core.Callback.TriggerAwait('bcc-stables:AuthorizeHorseCare', MyHorseId, 'brush')
        if authorized ~= true then
            return NotifyTip('ไม่สามารถใช้แปรงกับม้าตัวนี้ได้', 4000)
        end
    end

    ClearPedTasks(playerPed)

    -- skipDurability = true มาจากแปรงแบบใช้ครั้งเดียว (hr_brush) ที่ถูกหักไปแล้วฝั่ง server — ไม่ต้องไป
    -- ลด durability ของ Config.horsebrush.item (แปรงหลักคนละตัว) ไม่งั้นจะไปกินความทนของแปรงหลักผิดตัว
    Citizen.InvokeNative(0xCD181A959CFDD7F4, playerPed, MyHorse, `Interaction_Brush`, `p_brushHorse02x`, true) -- TaskAnimalInteraction
    Wait(5000)
    Citizen.InvokeNative(0x6585D955A68452A5, MyHorse) -- ClearPedEnvDirt
    Citizen.InvokeNative(0x523C79AEEFCC4A2A, MyHorse, 10, 'ALL') -- ClearPedDamageDecalByZone
    Citizen.InvokeNative(0x8FE22675A5A45817, MyHorse) -- ClearPedBloodDamage

    local health = Citizen.InvokeNative(0x36731AC041289BB1, MyHorse, 0, Citizen.ResultAsInteger()) -- GetAttributeCoreValue
    local stamina = Citizen.InvokeNative(0x36731AC041289BB1, MyHorse, 1, Citizen.ResultAsInteger()) -- GetAttributeCoreValue

    local healthBoost = Config.boost.brushHealth
    local staminaBoost = Config.boost.brushStamina

    if healthBoost > 0 then
        local newHealth = math.min(health + healthBoost, 100)
        Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 0, newHealth) -- SetAttributeCoreValue
    end

    if staminaBoost > 0 then
        local newStamina = math.min(stamina + staminaBoost, 100)
        Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 1, newStamina) -- SetAttributeCoreValue
    end
    SaveHorseStats(false, true)

    if (Config.horseXpPerBrush > 0) and (not MaxBonding) then
        if not Config.trainerOnly or IsTrainer then
            SaveXp('brush')
        end
    end

    Citizen.InvokeNative(0x67C540AA08E4A6F5, 'Core_Fill_Up', 'Consumption_Sounds', true, 0) -- PlaySoundFrontend
end)

RegisterNetEvent('bcc-stables:FeedHorse', function(item)
    if not MyHorse or MyHorse == 0 then
        return NotifyTip(_U('noHorse'), 4000)
    end

    local playerPed = PlayerPedId()
    local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(MyHorse))

    if distance > 3.5 then
        NotifyTip(_U('tooFar'), 4000)
        return
    end

    local consumed = Core.Callback.TriggerAwait('bcc-stables:UseHorseFood', MyHorseId, item)
    if consumed ~= true then
        return NotifyTip('ไม่สามารถให้อาหารม้าตัวนี้ได้', 4000)
    end

    ClearPedTasks(playerPed)
    Citizen.InvokeNative(0xCD181A959CFDD7F4, playerPed, MyHorse, `Interaction_Food`, `s_horsnack_haycube01x`, true) -- TaskAnimalInteraction
    Wait(5000)

    local health = Citizen.InvokeNative(0x36731AC041289BB1, MyHorse, 0, Citizen.ResultAsInteger()) -- GetAttributeCoreValue
    local stamina = Citizen.InvokeNative(0x36731AC041289BB1, MyHorse, 1, Citizen.ResultAsInteger()) -- GetAttributeCoreValue

    local healthBoost = Config.boost.feedHealth
    local staminaBoost = Config.boost.feedStamina

    if healthBoost > 0 then
        local newHealth = math.min(health + healthBoost, 100)
        Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 0, newHealth) -- SetAttributeCoreValue
    end

    if staminaBoost > 0 then
        local newStamina = math.min(stamina + staminaBoost, 100)
        Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 1, newStamina) -- SetAttributeCoreValue
    end
    SaveHorseStats(false)

    if (Config.horseXpPerFeed > 0) and (not MaxBonding) then
        if not Config.trainerOnly or IsTrainer then
            SaveXp('feed')
        end
    end

    Citizen.InvokeNative(0x67C540AA08E4A6F5, 'Core_Fill_Up', 'Consumption_Sounds', true, 0) -- PlaySoundFrontend
end)

RegisterNetEvent('bcc-stables:FlamingHooves', function()
    if not MyHorse or MyHorse == 0 then
        return NotifyTip(_U('noHorse'), 4000)
    end

    if Activated then return end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local horseCoords = GetEntityCoords(MyHorse)

    if #(playerCoords - horseCoords) > 3.5 then
        return NotifyTip(_U('tooFar'), 4000)
    end

    ClearPedTasks(playerPed)

    Citizen.InvokeNative(0x1913FE4CBF41C463, MyHorse, 207, true) -- SetPedConfigFlag / PCF_FlamingHoovesActive
    NotifyTip(_U('flameHoovesActivated'), 4000, 'success')
    Activated = true

    -- Check if durability system is enabled before adjusting durability
    if Config.flamingHooves.durability then
        TriggerServerEvent('bcc-stables:FlamingHoovesDurability')
    end

    -- Set a timer to deactivate the flaming hooves effect after the specified duration
    local duration = Config.flamingHooves.duration * 60000 -- Convert minutes to milliseconds
    Citizen.SetTimeout(duration, function()
        if DoesEntityExist(MyHorse) then
            Citizen.InvokeNative(0x1913FE4CBF41C463, MyHorse, 207, false)
            NotifyTip(_U('flameHoovesDeactivated'), 4000)
            Activated = false
        end
    end)
end)

RegisterNetEvent('bcc-stables:UseLantern', function()
    if not MyHorse or MyHorse == 0 then
        return NotifyTip(_U('noHorse'), 4000)
    end

    local playerPed = PlayerPedId()
    local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(MyHorse))

    if distance > 3.5 then
        return NotifyTip(_U('tooFar'), 4000)
    end

    ClearPedTasks(playerPed)

    if not UsingLantern then
        SetComponent(MyHorse, 0x635E387C)
        UsingLantern = true

        if Config.lantern.durability then
            TriggerServerEvent('bcc-stables:LanternDurability')
        end
    else
        Citizen.InvokeNative(0x0D7FFA1B2F69ED82, MyHorse, 0x635E387C, 0, 0) -- RemoveShopItemFromPed
        Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse, false, true, true, true, false)    -- UpdatePedVariation
        UsingLantern = false
    end
end)

AddEventHandler('bcc-stables:TradeHorse', function()
    local generation, horse, horseId = HorseGeneration, MyHorse, MyHorseId
    while MyHorse == horse and MyHorseId == horseId and generation == HorseGeneration and DoesEntityExist(horse) do
        local playerPed = PlayerPedId()
        local sleep = 1000
        local lastLed = Citizen.InvokeNative(0x693126B5D0457D0D, playerPed) -- GetLastLedMount
        local isLeading = Citizen.InvokeNative(0xEFC4303DDC6E60D3, playerPed) -- IsPedLeadingHorse

        if not IsEntityDead(playerPed) and lastLed == MyHorse and isLeading then
            local closestPlayer, closestDistance = GetClosestPlayer()
            if closestPlayer and closestDistance <= 2.0 then
                sleep = 0
                UiPromptSetActiveGroupThisFrame(TradeGroup, CreateVarString(10, 'LITERAL_STRING', HorseName), 1, 0, 0, 0)
                if Citizen.InvokeNative(0xE0F65F0640EF0617, TradeHorse) then  -- PromptHasHoldModeCompleted
                    local serverId = GetPlayerServerId(closestPlayer)
                    TriggerServerEvent('bcc-stables:SaveHorseTrade', serverId, MyHorseId)
                    break
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('bcc-stables:TradeOffer', function(offerId, ownerName, horseName)
    NotifyTip(('%s ต้องการมอบม้า %s ให้คุณ พิมพ์ ACCEPT เพื่อยืนยัน'):format(ownerName or 'ผู้เล่น', horseName or ''), 8000)
    local prompt = {
        type = 'enableinput', inputType = 'input', button = 'ยืนยัน', placeholder = 'ACCEPT', style = 'block',
        attributes = { inputHeader = 'รับม้า', type = 'text', pattern = '^(ACCEPT|accept)$', title = 'พิมพ์ ACCEPT เพื่อรับม้า' }
    }
    TriggerEvent('vorpinputs:advancedInput', json.encode(prompt), function(result)
        TriggerServerEvent('bcc-stables:ResolveTradeOffer', offerId, type(result) == 'string' and result:upper() == 'ACCEPT')
    end)
end)

RegisterNetEvent('bcc-stables:TradeCompleted', function(horseId)
    if tonumber(MyHorseId) ~= tonumber(horseId) then return end
    FleeHorse()
    MyHorseId = nil
end)

function GetClosestPlayer()
    local players = GetActivePlayers()
    local player = PlayerId()
    local coords = GetEntityCoords(PlayerPedId())
    local closestDistance = math.huge
    local closestPlayer = -1

    for _, playerId in ipairs(players) do
        if playerId ~= player then
            local targetCoords = GetEntityCoords(GetPlayerPed(playerId))
            local distance = #(coords - targetCoords)
            if distance < closestDistance then
                closestPlayer = playerId
                closestDistance = distance
            end
        end
    end

    return closestPlayer, closestDistance
end

-- Select Horse Tack from Menu
RegisterNUICallback('Saddles', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        SaddlesUsing = 0
        RemoveComponent(0xBAA7E618)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        SaddlesUsing = hash
    end
end)

RegisterNUICallback('Saddlecloths', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        SaddleclothsUsing = 0
        RemoveComponent(0x17CEB41A)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        SaddleclothsUsing = hash
    end
end)

RegisterNUICallback('Stirrups', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        StirrupsUsing = 0
        RemoveComponent(0xDA6DADCA)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        StirrupsUsing = hash
    end
end)

RegisterNUICallback('SaddleBags', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        BagsUsing = 0
        RemoveComponent(0x80451C25)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        BagsUsing = hash
    end
end)

RegisterNUICallback('Manes', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        ManesUsing = 0
        RemoveComponent(0xAA0217AB)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        ManesUsing = hash
    end
end)

RegisterNUICallback('Tails', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        TailsUsing = 0
        RemoveComponent(0xA63CAE10)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        TailsUsing = hash
    end
end)

RegisterNUICallback('SaddleHorns', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        SaddleHornsUsing = 0
        RemoveComponent(0x5447332)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        SaddleHornsUsing = hash
    end
end)

RegisterNUICallback('Bedrolls', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        BedrollsUsing = 0
        RemoveComponent(0xEFB31921)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        BedrollsUsing = hash
    end
end)

RegisterNUICallback('Masks', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        MasksUsing = 0
        RemoveComponent(0xD3500E5D)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        MasksUsing = hash
    end
end)

RegisterNUICallback('Mustaches', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        MustachesUsing = 0
        RemoveComponent(0x30DEFDDF)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        MustachesUsing = hash
    end
end)

RegisterNUICallback('Holsters', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        HolstersUsing = 0
        RemoveComponent(0xAC106B30)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        HolstersUsing = hash
    end
end)

RegisterNUICallback('Bridles', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        BridlesUsing = 0
        RemoveComponent(0x94B2E3AF)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        BridlesUsing = hash
    end
end)

RegisterNUICallback('Horseshoes', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        HorseshoesUsing = 0
        RemoveComponent(0xFACFC3C0)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        HorseshoesUsing = hash
    end
end)

---@param entity number
---@param hash string
function SetComponent(entity, hash)
    if not DoesEntityExist(entity) then return end

    local comp = tonumber(hash)
    if not comp or comp == 0 then return end -- กันค่าที่ไม่ใช่ hash (เช่น _tint เดิมที่อาจค้างใน DB ม้าเก่า)

    Citizen.InvokeNative(0xD3A7B003ED343FD9, entity, comp, true, true, true) -- ApplyShopItemToPed
    Wait(50)
    Citizen.InvokeNative(0xCC8CA3E88256E58F, entity, false, true, true, true, false) -- UpdatePedVariation
end

function RemoveComponent(category)
    Citizen.InvokeNative(0xD710A5007C2AC539, MyEntity, category, 0) -- RemoveTagFromMetaPed
    Citizen.InvokeNative(0xCC8CA3E88256E58F, MyEntity, false, true, true, true, false) -- UpdatePedVariation
end

RegisterNUICallback('sellHorse', function(data, cb)
    data = type(data) == 'table' and data or {}
    data.site = Site
    local result = Core.Callback.TriggerAwait('bcc-stables:SellMyHorse', data)
    if result == true then result = { ok = true } end -- legacy callback compatibility
    if type(result) ~= 'table' then result = { ok = false, reason = 'callback_failed' } end
    if result.ok == true then
        ClearShopHorse()
        MyEntityID = nil
    end
    cb(result)
end)

function SaveHorseStats(dead, awaitResult)
    local healthCore, staminaCore

    if not dead then
        healthCore = Citizen.InvokeNative(0x36731AC041289BB1, MyHorse, 0, Citizen.ResultAsInteger())  -- GetAttributeCoreValue
        staminaCore = Citizen.InvokeNative(0x36731AC041289BB1, MyHorse, 1, Citizen.ResultAsInteger()) -- GetAttributeCoreValue
    else
        healthCore = Config.death.health
        staminaCore = Config.death.stamina
        Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 0, healthCore)  -- SetAttributeCoreValue
        Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 1, staminaCore) -- SetAttributeCoreValue
    end

    Wait(100) -- Wait for the values to be set before saving

    if awaitResult then
        return Core.Callback.TriggerAwait('bcc-stables:SaveHorseStatsChecked', healthCore, staminaCore, MyHorseId) == true
    end
    TriggerServerEvent('bcc-stables:SaveHorseStatsToDb', healthCore, staminaCore, MyHorseId)
    return true
end

-- View Horses While in Menu
function CreateCamera()
    local siteCfg = Stables[Site]
    local horseCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

    SetCamCoord(horseCam, siteCfg.horse.camera.x, siteCfg.horse.camera.y, siteCfg.horse.camera.z + 1.2)
    SetCamActive(horseCam, true)
    PointCamAtCoord(horseCam, siteCfg.horse.coords.x - 0.5, siteCfg.horse.coords.y, siteCfg.horse.coords.z)

    DoScreenFadeOut(500)
    Wait(500)
    DoScreenFadeIn(500)

    RenderScriptCams(true, false, 0, false, false, 0)
    Citizen.InvokeNative(0x67C540AA08E4A6F5, 'Leaderboard_Show', 'MP_Leaderboard_Sounds', true, 0) -- PlaySoundFrontend
end

function CameraLighting()
    CreateThread(function()
        local siteCfg = Stables[Site]
        local coords = siteCfg.horse.coords

        while Cam do
            Wait(0)
            Citizen.InvokeNative(0xD2D9E04C0DF927F4, coords.x, coords.y, coords.z + 3, 130, 130, 85, 4.0, 15.0) -- DrawLightWithRange
        end
    end)
end

-- -- Rotate Horses while Viewing
local function Rotation(dir)
    local entity = MyEntity ~= 0 and MyEntity or ShopEntity

    if entity ~= 0 then
        local currentHeading = GetEntityHeading(entity)
        SetEntityHeading(entity, (currentHeading + dir) % 360)
    end
end

RegisterNUICallback('rotate', function(data, cb)
    cb('ok')
    local direction = data.RotateHorse
    -- 6° ต่อครั้ง (เดิม 1° แทบไม่ขยับ) — NUI ใหม่กดค้างยิงซ้ำทุก 90ms → หมุนต่อเนื่องลื่น
    local dir = direction == 'left' and 6 or -6

    Rotation(dir)
end)

RegisterCommand(Config.commands.horseRespawn, function(source, args, rawCommand)
    Spawning = false
    WhistleSpawn()
end, false)

-- คำสั่งแอดมิน: เปิดหน้าร้านโชว์ม้า "ทุกตัว" (ข้าม saleWhitelist) ไว้เช็คชื่อ+สี — เช็คสิทธิ์ ACE ที่ server
RegisterCommand(Config.adminCatalogCommand or 'stablecatalog', function()
    if InMenu then return end

    local isAdmin = Core.Callback.TriggerAwait('bcc-stables:CheckAdmin')
    if not isAdmin then
        NotifyTip('คุณไม่มีสิทธิ์ใช้คำสั่งนี้', 4000)
        return
    end

    -- หาโรงม้าที่ใกล้สุด (ต้องอยู่ใกล้พอ กล้อง/preview จะได้อยู่ที่โรงม้าจริง)
    local pcoords = GetEntityCoords(PlayerPedId())
    local nearestKey, nearestDist = nil, math.huge
    for key, st in pairs(Stables) do
        if st.npc and st.npc.coords then
            local d = #(pcoords - st.npc.coords)
            if d < nearestDist then nearestKey, nearestDist = key, d end
        end
    end

    if not nearestKey or nearestDist > 60.0 then
        NotifyTip('ไปยืนใกล้โรงม้าก่อนใช้คำสั่งนี้', 4000)
        return
    end

    AdminViewAll = true -- TeardownStable จะรีเซ็ตกลับเป็น false ตอนปิดร้าน
    OpenStable(nearestKey)
end, false)

RegisterCommand(Config.commands.horseSetWild, function(source, args, rawCommand)
    if Config.devMode then
        local mount = Citizen.InvokeNative(0xE7E11B8DCBED1058, PlayerPedId()) -- GetMount

        Citizen.InvokeNative(0xAEB97D84CDF3C00B, mount, true) -- SetAnimalIsWild
        Citizen.InvokeNative(0xBCC76708E5677E1D, mount, true) -- ClearActiveAnimalOwner
        Citizen.InvokeNative(0x9FF1E042FA597187, mount, 97, false) -- SetAnimalTuningBoolParam
    else
        print('Command used in Developer Mode Only!') -- Not for use on live server
    end
end, false)

RegisterCommand(Config.commands.horseWrithe, function(source, args, rawCommand)
    if Config.devMode then
        Citizen.InvokeNative(0x8C038A39C4A4B6D6, MyHorse, 0, 0) -- TaskAnimalWrithe
    else
        print('Command used in Developer Mode Only!') -- Not for use on live server
    end
end, false)

RegisterCommand(Config.commands.horseInfo, function(source, args, rawCommand)
    if not MyHorse or MyHorse == 0 then
        NotifyTip(_U('noHorse'), 4000)
        return
    end

    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(MyHorse)) <= 3.0 then
        HorseInfoMenu()
    else
        NotifyTip(_U('tooFar'), 4000)
    end
end, false)

function StartPrompts()
    OpenShops = UiPromptRegisterBegin()
    UiPromptSetControlAction(OpenShops, Config.keys.shop)
    UiPromptSetText(OpenShops, CreateVarString(10, 'LITERAL_STRING', _U('shopPrompt')))
    UiPromptSetVisible(OpenShops, true)
    UiPromptSetStandardMode(OpenShops, true)
    UiPromptSetGroup(OpenShops, ShopGroup, 0)
    UiPromptRegisterEnd(OpenShops)

    OpenCall = UiPromptRegisterBegin()
    UiPromptSetControlAction(OpenCall, Config.keys.call)
    UiPromptSetText(OpenCall, CreateVarString(10, 'LITERAL_STRING', _U('callPrompt')))
    UiPromptSetVisible(OpenCall, true)
    UiPromptSetStandardMode(OpenCall, true)
    UiPromptSetGroup(OpenCall, ShopGroup, 1)
    UiPromptRegisterEnd(OpenCall)

    OpenReturn = UiPromptRegisterBegin()
    UiPromptSetControlAction(OpenReturn, Config.keys.ret)
    UiPromptSetText(OpenReturn, CreateVarString(10, 'LITERAL_STRING', _U('returnPrompt')))
    UiPromptSetVisible(OpenReturn, true)
    UiPromptSetStandardMode(OpenReturn, true)
    UiPromptSetGroup(OpenReturn, ShopGroup, 1)
    UiPromptRegisterEnd(OpenReturn)

    SellTame = UiPromptRegisterBegin()
    UiPromptSetControlAction(SellTame, Config.keys.sell)
    UiPromptSetText(SellTame, CreateVarString(10, 'LITERAL_STRING', _U('sellPrompt')))
    UiPromptSetHoldMode(SellTame, 2000)
    UiPromptSetGroup(SellTame, TameGroup, 0)
    UiPromptRegisterEnd(SellTame)

    KeepTame = UiPromptRegisterBegin()
    UiPromptSetControlAction(KeepTame, Config.keys.keep)
    UiPromptSetText(KeepTame, CreateVarString(10, 'LITERAL_STRING', _U('keepPrompt') .. tostring(Config.regCost)))
    UiPromptSetHoldMode(KeepTame, 2000)
    UiPromptSetGroup(KeepTame, TameGroup, 0)
    UiPromptRegisterEnd(KeepTame)

    TradeHorse = UiPromptRegisterBegin()
    UiPromptSetControlAction(TradeHorse, Config.keys.trade)
    UiPromptSetText(TradeHorse, CreateVarString(10, 'LITERAL_STRING', _U('tradePrompt')))
    UiPromptSetVisible(TradeHorse, true)
    UiPromptSetEnabled(TradeHorse, true)
    UiPromptSetHoldMode(TradeHorse, 2000)
    UiPromptSetGroup(TradeHorse, TradeGroup, 0)
    UiPromptRegisterEnd(TradeHorse)

    LootHorse = UiPromptRegisterBegin()
    UiPromptSetControlAction(LootHorse, Config.keys.loot)
    UiPromptSetText(LootHorse, CreateVarString(10, 'LITERAL_STRING', _U('lootHorsePrompt')))
    UiPromptSetVisible(LootHorse, true)
    UiPromptSetEnabled(LootHorse, true)
    UiPromptSetStandardMode(LootHorse, true)
    UiPromptSetGroup(LootHorse, LootGroup, 0)
    UiPromptRegisterEnd(LootHorse)
end

function HorseTargetPrompts(menuGroup)
    local currentLevel = Citizen.InvokeNative(0x147149F2E909323C, MyHorse, 7, Citizen.ResultAsInteger()) -- GetAttributeBaseRank

    if not PromptsStarted then
        HorseDrink = UiPromptRegisterBegin()
        UiPromptSetControlAction(HorseDrink, Config.keys.drink)
        UiPromptSetText(HorseDrink, CreateVarString(10, 'LITERAL_STRING', _U('drinkPrompt')))
        UiPromptSetVisible(HorseDrink, true)
        UiPromptSetStandardMode(HorseDrink, true)
        UiPromptSetGroup(HorseDrink, menuGroup, 0)
        UiPromptRegisterEnd(HorseDrink)

        HorseRest = UiPromptRegisterBegin()
        UiPromptSetControlAction(HorseRest, Config.keys.rest)
        UiPromptSetText(HorseRest, CreateVarString(10, 'LITERAL_STRING', _U('restPrompt')))
        UiPromptSetVisible(HorseRest, true)
        UiPromptSetStandardMode(HorseRest, true)
        UiPromptSetGroup(HorseRest, menuGroup, 0)
        UiPromptRegisterEnd(HorseRest)

        HorseSleep = UiPromptRegisterBegin()
        UiPromptSetControlAction(HorseSleep, Config.keys.sleep)
        UiPromptSetText(HorseSleep, CreateVarString(10, 'LITERAL_STRING', _U('sleepPrompt')))
        UiPromptSetVisible(HorseSleep, true)
        UiPromptSetStandardMode(HorseSleep, true)
        UiPromptSetGroup(HorseSleep, menuGroup, 0)
        UiPromptRegisterEnd(HorseSleep)

        HorseWallow = UiPromptRegisterBegin()
        UiPromptSetControlAction(HorseWallow, Config.keys.wallow)
        UiPromptSetText(HorseWallow, CreateVarString(10, 'LITERAL_STRING', _U('wallowPrompt')))
        UiPromptSetVisible(HorseWallow, true)
        UiPromptSetStandardMode(HorseWallow, true)
        UiPromptSetGroup(HorseWallow, menuGroup, 0)
        UiPromptRegisterEnd(HorseWallow)

        PromptsStarted = true
    end

    local prompts = {
        {level = 1, prompt = HorseDrink},
        {level = 2, prompt = HorseRest},
        {level = 3, prompt = HorseSleep},
        {level = 4, prompt = HorseWallow}
    }

    for _, item in ipairs(prompts) do
        UiPromptSetEnabled(item.prompt, currentLevel >= item.level)
    end
end

function CheckPlayerJob(trainer, site)
    local result = Core.Callback.TriggerAwait('bcc-stables:CheckJob', trainer, site)

    IsTrainer = false
    HasJob = false

    if result then
        if trainer and result[1] then
            IsTrainer = true
        elseif result[1] then
            HasJob = true
        end

        -- โหมดแอดมินให้ดึงรายการเสมอ (แม้ไม่มี job) เพราะ FindHorsesByJob จะข้าม job ให้อยู่แล้ว
        if AdminViewAll or (not trainer and result[2]) then
            JobMatchedHorses = FindHorsesByJob(result[2] or 'admin')
        end

        if not trainer and not result[1] and Stables[site].shop.jobsEnabled then
            NotifyTip(_U('needJob'), 4000)
        end
    end
end

function AddTrainerBlip(site)
    local siteCfg = Trainers[site]

    siteCfg.TrainerBlip = Citizen.InvokeNative(0x554d9d53f696d002, 1664425300, siteCfg.npc.coords) -- BlipAddForCoords
    SetBlipSprite(siteCfg.TrainerBlip, siteCfg.blip.sprite, true)
    Citizen.InvokeNative(0x9CB1A1623062F402, siteCfg.TrainerBlip,  siteCfg.blip.name) -- SetBlipName
end

function AddTrainerNPC(site)
    local siteCfg = Trainers[site]
    local coords = siteCfg.npc.coords

    local modelName = siteCfg.npc.model
    local model = joaat(modelName)
    LoadModel(model, modelName)

    siteCfg.TrainerNPC = CreatePed(model, coords.x, coords.y, coords.z - 1.0, siteCfg.npc.heading, false, false, false, false)
    Citizen.InvokeNative(0x283978A15512B2FE, siteCfg.TrainerNPC, true) -- SetRandomOutfitVariation
    SetEntityCanBeDamaged(siteCfg.TrainerNPC, false)
    SetEntityInvincible(siteCfg.TrainerNPC, true)
    Wait(500)
    FreezeEntityPosition(siteCfg.TrainerNPC, true)
    SetBlockingOfNonTemporaryEvents(siteCfg.TrainerNPC, true)
end

function LoadModel(model, modelName)
    if not IsModelValid(model) then
        DebugPrint('Invalid model: ' .. tostring(modelName))
        return false
    end

    if not HasModelLoaded(model) then
        RequestModel(model, false)

        local timeout = 10000
        local startTime = GetGameTimer()

        while not HasModelLoaded(model) do
            if GetGameTimer() - startTime > timeout then
                DebugPrint('Failed to load model: ' .. tostring(modelName))
                return false
            end
            Wait(10)
        end
    end
    return true
end

 -- Update Global Horse Entity after session change
RegisterNetEvent('bcc-stables:UpdateMyHorseEntity', function()
    if MyHorse ~= 0 then
        MyHorse = NetworkGetEntityFromNetworkId(LocalPlayer.state.HorseData.MyHorse)
    end
end)

-- to count length of maps
local function len(t)
    local counter = 0
    for _ in pairs(t) do
        counter = counter + 1
    end
    return counter
end

local function orderedPairs(t)
    local keys = {}
    for key in pairs(t) do keys[#keys + 1] = key end
    table.sort(keys)
    local index = 0
    return function()
        index = index + 1
        local key = keys[index]
        if key ~= nil then return key, t[key] end
    end
end

function FindHorsesByJob(job)
    local matchingHorses = {}
    for _, horseType in ipairs(Horses) do
        local matchingColors = {}

        for horseColor, horseColorData in orderedPairs(horseType.colors) do
            -- whitelist: ถ้า Config.saleWhitelist ไม่ว่าง → โชว์ขายเฉพาะ model ที่อยู่ใน list
            -- ว่าง = โชว์ทุกตัวตามปกติ (next(wl) == nil) | โหมดแอดมิน (AdminViewAll) ข้ามทั้งหมด
            local wl = Config.saleWhitelist
            local onSale = AdminViewAll or (wl == nil) or (next(wl) == nil) or (wl[horseColor] == true)

            if onSale then
                local horseJobs = {}
                for _, horseJob in pairs(horseColorData.job) do
                    horseJobs[horseJob] = true
                end

                -- แอดมิน: โชว์ทุกสีไม่ว่า job อะไร | ปกติ: โชว์ถ้า job ตรง หรือไม่มี job ล็อก
                if AdminViewAll or horseJobs[job] or len(horseJobs) == 0 then
                    matchingColors[horseColor] = {
                        color = horseColorData.color,
                        cashPrice = horseColorData.cashPrice,
                        goldPrice = horseColorData.goldPrice,
                        invLimit = horseColorData.invLimit,
                        stats = DeriveStats(horseColorData), -- 0-10 (จาก stats/attrs) ให้ NUI ร้านม้าโชว์ค่าจริง ไม่ใช่ 4/10
                        job = (len(horseJobs) == 0) and nil or horseColorData.job
                    }
                end
            end
        end

        if len(matchingColors) > 0 then
            table.insert(matchingHorses, {
                breed = horseType.breed,
                colors = matchingColors
            })
        end
    end
    return matchingHorses
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    if InMenu then
        SendNUIMessage({ action = 'hide' })
        SetNuiFocus(false, false)
    end

    ClearPedTasksImmediately(PlayerPedId())
    DestroyAllCams(true)
    DisplayRadar(true)

    if ShopEntity ~= 0 then
        DeleteEntity(ShopEntity)
        ShopEntity = 0
    end

    if MyEntity ~= 0 then
        DeleteEntity(MyEntity)
        MyEntity = 0
    end

    if MyHorse ~= 0 then
        SaveHorseStats(InWrithe)
        Sending = false
        HorseGeneration = HorseGeneration + 1
        DeleteEntity(MyHorse)
        MyHorse = 0
    end

    for _, siteCfg in pairs(Stables) do
        if siteCfg.Blip then
            RemoveBlip(siteCfg.Blip)
            siteCfg.Blip = nil
        end
        if siteCfg.NPC then
            DeleteEntity(siteCfg.NPC)
            siteCfg.NPC = nil
        end
    end

    for _, siteCfg in pairs(Trainers) do
        if siteCfg.TrainerBlip then
            RemoveBlip(siteCfg.TrainerBlip)
            siteCfg.TrainerBlip = nil
        end
        if siteCfg.TrainerNPC then
            DeleteEntity(siteCfg.TrainerNPC)
            siteCfg.TrainerNPC = nil
        end
    end

    CleanupAnimalInfoHud()
end)
