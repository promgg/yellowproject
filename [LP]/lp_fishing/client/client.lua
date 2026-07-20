local fishing_minigame_struct = {}
local fishing_lure_cooldown = 0
local ready = false
local fishing = false
local fishStatus = 0
local fishForce = 0.6
local nextAttTime = 0
local horizontalMove = 0
local status = nil
local currentLure = nil
local Core = exports.vorp_core:GetCore()

local T = Translation.Langs[Config.Lang]

local fishing_data = {
    fish                   = { weight = 0 },
    prompt_prepare_fishing = {},
    prompt_waiting_hook    = {},
    prompt_hook            = {},
    prompt_finish          = {}
}

local fishs = {
    [`A_C_FISHBLUEGIL_01_MS`]        = FishData.A_C_FISHBLUEGIL_01_MS[1],
    [`A_C_FISHBLUEGIL_01_SM`]        = FishData.A_C_FISHBLUEGIL_01_SM[1],
    [`A_C_FISHBULLHEADCAT_01_MS`]    = FishData.A_C_FISHBULLHEADCAT_01_MS[1],
    [`A_C_FISHBULLHEADCAT_01_SM`]    = FishData.A_C_FISHBULLHEADCAT_01_SM[1],
    [`A_C_FISHCHAINPICKEREL_01_MS`]  = FishData.A_C_FISHCHAINPICKEREL_01_MS[1],
    [`A_C_FISHCHAINPICKEREL_01_SM`]  = FishData.A_C_FISHCHAINPICKEREL_01_SM[1],
    [`A_C_FISHCHANNELCATFISH_01_LG`] = FishData.A_C_FISHCHANNELCATFISH_01_LG[1],
    [`A_C_FISHCHANNELCATFISH_01_XL`] = FishData.A_C_FISHCHANNELCATFISH_01_XL[1],
    [`A_C_FISHLAKESTURGEON_01_LG`]   = FishData.A_C_FISHLAKESTURGEON_01_LG[1],
    [`A_C_FISHLARGEMOUTHBASS_01_LG`] = FishData.A_C_FISHLARGEMOUTHBASS_01_LG[1],
    [`A_C_FISHLARGEMOUTHBASS_01_MS`] = FishData.A_C_FISHLARGEMOUTHBASS_01_MS[1],
    [`A_C_FISHLONGNOSEGAR_01_LG`]    = FishData.A_C_FISHLONGNOSEGAR_01_LG[1],
    [`A_C_FISHMUSKIE_01_LG`]         = FishData.A_C_FISHMUSKIE_01_LG[1],
    [`A_C_FISHNORTHERNPIKE_01_LG`]   = FishData.A_C_FISHNORTHERNPIKE_01_LG[1],
    [`A_C_FISHPERCH_01_MS`]          = FishData.A_C_FISHPERCH_01_MS[1],
    [`A_C_FISHPERCH_01_SM`]          = FishData.A_C_FISHPERCH_01_SM[1],
    [`A_C_FISHRAINBOWTROUT_01_LG`]   = FishData.A_C_FISHRAINBOWTROUT_01_LG[1],
    [`A_C_FISHRAINBOWTROUT_01_MS`]   = FishData.A_C_FISHRAINBOWTROUT_01_MS[1],
    [`A_C_FISHREDFINPICKEREL_01_MS`] = FishData.A_C_FISHREDFINPICKEREL_01_MS[1],
    [`A_C_FISHREDFINPICKEREL_01_SM`] = FishData.A_C_FISHREDFINPICKEREL_01_SM[1],
    [`A_C_FISHROCKBASS_01_MS`]       = FishData.A_C_FISHROCKBASS_01_MS[1],
    [`A_C_FISHROCKBASS_01_SM`]       = FishData.A_C_FISHROCKBASS_01_SM[1],
    [`A_C_FISHSALMONSOCKEYE_01_LG`]  = FishData.A_C_FISHSALMONSOCKEYE_01_LG[1],
    [`A_C_FISHSALMONSOCKEYE_01_ML`]  = FishData.A_C_FISHSALMONSOCKEYE_01_ML[1],
    [`A_C_FISHSALMONSOCKEYE_01_MS`]  = FishData.A_C_FISHSALMONSOCKEYE_01_MS[1],
    [`A_C_FISHSMALLMOUTHBASS_01_LG`] = FishData.A_C_FISHSMALLMOUTHBASS_01_LG[1],
    [`A_C_FISHSMALLMOUTHBASS_01_MS`] = FishData.A_C_FISHSMALLMOUTHBASS_01_MS[1],
}

AddEventHandler("lp_fishing:resetFishing", function()
    fishing = false
    fishStatus = 0
    fishForce = 0.6
    nextAttTime = 0
    horizontalMove = 0
    status = nil
    currentLure = nil
end)

Core.Callback.Register("lp_fishing:checkRodAndBait", function(CB, UsableBait)
    local ped = PlayerPedId()
    local _, weaponHash = GetCurrentPedWeapon(ped, true, 0, false)

    if weaponHash ~= GetHashKey("WEAPON_FISHINGROD") then
        Core.NotifyRightTip(T.NoFishingRodEquipped, 4000)
        return CB({false})
    end

    if currentLure ~= nil then
        if currentLure == UsableBait then
            Core.NotifyRightTip(T.AlreadyHaveBait, 4000)
            return CB({false})
        else
            fishing = false
            Core.NotifyRightTip(T.ChangeBait, 4000)
        end
    end

    currentLure = UsableBait
    CB({true, currentLure})
end)

RegisterNetEvent("lp_fishing:UseBait", function(UsableBait)
    if fishing then return end

    -- โหมดง่ายไม่ใช้มินิเกมของเกมเลย — currentLure ถูกตั้งไว้แล้วตอน checkRodAndBait
    -- ปล่อยให้ thread ของโหมดง่ายรับช่วงต่อ (รอผู้เล่นกดปุ่มเหวี่ยง)
    if Config.SimpleMode and Config.SimpleMode.Enabled then return end

    local playerPed = PlayerPedId()
    if Citizen.InvokeNative(0xDC88D06719070C39,playerPed) and not IsPedSwimming(playerPed) then
        Core.NotifyRightTip(T.StandNearSide, 4000)
    end
  
    Citizen.InvokeNative(0x1096603B519C905F, "MMFSH")
    prepareMyPrompt()
    fishing = true
    local sleep = 1500
    ready = false

    while fishing do
        Citizen.Wait(0)
        GET_TASK_FISHING_DATA()
        if FISHING_GET_MINIGAME_STATE() == 1 and ready == false then
            ready = true
            if Config.Debug then
                print("Current bait: " .. currentLure)
            end
            TaskSwapFishingBait(PlayerPedId(), currentLure, false)
            Citizen.InvokeNative(0x9B0C7FA063E67629, PlayerPedId(), currentLure, 0, 1)
        end

        if hasMinigameOn then
            sleep = 4
            local playerPed = PlayerPedId()

            if FISHING_GET_MINIGAME_STATE() == 2 then
                FISHING_GET_MAX_THROWING_DISTANCE()
            end

            if FISHING_GET_MINIGAME_STATE() == 6 then
                if IsControlJustPressed(0, 0x8FFC75D6) then
                    FISHING_SET_F_(6, 128)
                end

                local bobberPosition = FISHING_GET_BOBBER_HANDLE()

                local hookHandle = FISHING_GET_HOOK_HANDLE()
                local hookPosition = GetEntityCoords(hookHandle)
                local lured = false

                if IsControlPressed(0, GetHashKey("INPUT_DUCK")) then
                    local actualReelSpeed = Config.ReelSpeed
                    local playerCoords = GetEntityCoords(PlayerPedId(), true, true)
                    local distance = playerCoords - hookPosition

                    distance = hookPosition + distance * actualReelSpeed
                    SetEntityCoords(hookHandle, distance.x, distance.y, distance.z, false, false, false, false)
                end

                if FISHING_GET_LINE_DISTANCE() < 4.0 then
                    FISHING_SET_F_(14, 1.0)
                else
                    FISHING_SET_F_(14, 0.4)
                end

                local fishHandle
                for _, f in pairs(GetNearbyFishs(hookPosition, 50.0)) do
                    local fishModel = GetEntityModel(f)

                    if fishs[fishModel] ~= nil then
                        local fishPosition = GetEntityCoords(f)
                        if Config.Debug then
                            Citizen.InvokeNative(GetHashKey("DRAW_LINE") & 0xFFFFFFFF, fishPosition, fishPosition + vec3(0, 0, 2.0), 255, 255, 0, 255)
                        end

                        if fishing_lure_cooldown <= GetGameTimer() then
                            local dist = #(hookPosition - fishPosition)
                            if dist <= 1.6 then
                                fishHandle = f
                            else
                                if isFishInterested(GetEntityModel(f)) then
                                    TaskGoToEntity(f, bobberPosition, 100, 1, 1.0, 2.0, 0)
                                end
                            end

                            if lured == false then
                                lured = true
                            end
                        end
                    else
                        if Config.Debug then
                            print("Ignoring non-mapped fish model:", fishModel)
                        end
                    end
                end


                if lured then
                    fishing_lure_cooldown = GetGameTimer() + (1 * 1000)
                end

                if fishHandle then
                    local probabilidadePuxar = math.random()
                    if probabilidadePuxar > 0.9 or probabilidadePuxar < 0.2 then -- soltar linha
                       -- if FISHING_GET_F_(5) == 1 then
                            Citizen.InvokeNative(0xF0FBF193F1F5C0EA, fishHandle)

                            SetPedConfigFlag(fishHandle, 17, true)

                            Citizen.InvokeNative(0x1F298C7BD30D1240, playerPed)

                            ClearPedTasksImmediately(fishHandle, false, true)
                            TaskSetBlockingOfNonTemporaryEvents(fishHandle, true)

                            Citizen.InvokeNative(0x1A52076D26E09004, playerPed, fishHandle)

                            FISHING_SET_FISH_HANDLE(fishHandle)
                            fishForce = 0.6

                            FISHING_SET_TRANSITION_FLAG(4)
                      --  end
                    end
                end
            end

            if FISHING_GET_MINIGAME_STATE() == 7 then
                fishing_data.fish.weight = FISHING_GET_F_(8)

                if IsControlJustPressed(0, 0x8FFC75D6) then
                    FISHING_SET_F_(6, 11)
                end
                local fishHandle = FISHING_GET_FISH_HANDLE()

                if GetControlNormal(0, 0x390948DC) > 0 then
                    horizontalMove = horizontalMove - (0.05 * GetControlNormal(0, 0x390948DC))
                end
                if GetControlNormal(0, 0x390948DC) < 0 then
                    horizontalMove = horizontalMove + (0.05 * -GetControlNormal(0, 0x390948DC))
                end
                if horizontalMove < 0 then
                    horizontalMove = 0
                end
                if horizontalMove > 1 then
                    horizontalMove = 1
                end
                FISHING_SET_F_(22, horizontalMove)


                if FISHING_GET_LINE_DISTANCE() < 4.0 then
                    FISHING_SET_F_(6, 12)
                    FISHING_SET_F_(14, 1.0)
                else
                    FISHING_SET_F_(14, 1.0)
                end

                if GetGameTimer() >= nextAttTime then
                    local probabilidadePuxar = math.random()
                    if probabilidadePuxar > 0.8 or probabilidadePuxar < 0.2 then -- soltar linha
                        fishForce = 0.8
                        tempoPuxando = math.random(3, 5) * 1000
                        fishStatus = 1 -- agitado
                        nextAttTime = GetGameTimer() + tempoPuxando

                        local fishHandle = FISHING_GET_FISH_HANDLE()
                        local x, y, z = table.unpack(GetEntityCoords(fishHandle))

                        local r = exports["lp_fishing"]:VERTICAL_PROBE(x, y, z, 1)

                        -- import from ptfx on vorp_fishing c# version
                        local particlecoords = GetEntityCoords(fishHandle)
                        RequestNamedPtfxAsset(GetHashKey('scr_mg_fishing'))
                        while not HasNamedPtfxAssetLoaded(GetHashKey('scr_mg_fishing')) do
                            Wait(5)
                        end
                        UseParticleFxAsset("scr_mg_fishing")
                        local Fisheffect = "" -- missing effect name
                        StartParticleFxNonLoopedAtCoord("scr_mg_fish_struggle", particlecoords.x, particlecoords.y, particlecoords.z,
                            0.0, 0.0, math.random(0, 360) + 0.0001, 1.5, false, false, false)
                        --SetParticleFxLoopedAlpha(Fisheffect, 1.0)

                        --  animDict = "mini_games@fishing@shore@hooked_med@struggle"

                        --  if not HasAnimDictLoaded(animDict) then
                        --      RequestAnimDict(animDict)
                        --      while not HasAnimDictLoaded(animDict) do
                        --          Citizen.Wait(0)
                        --      end
                        --  end
                    else
                        fishForce = 0
                        tempoPuxando = math.random(6, 10) * 1000
                        fishStatus = 0 --calmo
                        nextAttTime = GetGameTimer() + tempoPuxando
                    end
                end

                if fishStatus == 1 then
                    if IsControlPressed(0, GetHashKey("INPUT_GAME_MENU_OPTION")) then
                        FISHING_SET_ROD_WEIGHT(4)
                        fishForce = fishForce + 0.005
                    else
                        fishForce = fishForce - 0.005
                    end

                    if IsControlJustReleased(0, GetHashKey("INPUT_GAME_MENU_OPTION")) then
                        FISHING_SET_ROD_WEIGHT(2)
                    end

                    -- เอ็นขาด = แรงสาวเกินเพดาน → f_6 = 11 (ปลาหลุด)
                    -- Config.GuaranteedCatch = true จะไม่ยิง flag นี้เลย แค่ตรึงแรงไว้ที่เพดาน
                    local maxForce = Config.MaxFishForce or 1.4
                    if fishForce >= maxForce then
                        if Config.GuaranteedCatch then
                            fishForce = maxForce - 0.01
                        else
                            FISHING_SET_F_(6, 11)
                        end
                    else
                        if fishForce < 0.8 then
                            fishForce = 0.8
                        end
                    end
                    TaskSmartFleeCoord(fishHandle, GetEntityCoords(playerPed), 40.0, 50, 8, 1077936128)

                    -- import from ptfx on vorp_fishing c# version
                    local particlecoords = GetEntityCoords(fishHandle)
                    RequestNamedPtfxAsset(GetHashKey('scr_mg_fishing'))
                    while not HasNamedPtfxAssetLoaded(GetHashKey('scr_mg_fishing')) do
                        Wait(5)
                    end
                    UseParticleFxAsset("scr_mg_fishing")
                    local Fisheffect = "" -- its missing effect from here?
                    StartParticleFxNonLoopedAtCoord("scr_mg_fish_struggle", particlecoords.x, particlecoords.y, particlecoords.z, 0.0, 0.0, math.random(0, 360) + 0.0001, 1.5, false, false, false)
                    --SetParticleFxLoopedAlpha(Fisheffect, 1.0)
                else
                    if IsControlJustPressed(0, GetHashKey("INPUT_GAME_MENU_OPTION")) or (IsControlPressed(0, GetHashKey("INPUT_GAME_MENU_OPTION")) and GetGameTimer() % 25 == 0) then
                        FISHING_SET_ROD_WEIGHT(4)
                        TaskGoToEntity(fishHandle, playerPed, Config.Difficulty, 1.0, 1.5, 0.0, 0)
                        -- #######################################################
                        -- SetBlockingOfNonTemporaryEvents(fishHandle, true)
                        -- TaskGoToEntity(fishHandle, playerPed, 500, 5, 2.0, 2.0, 0)
                        -- ApplyForceToEntity(fishHandle, 0, GetEntityCoords(playerPed))
                        -- SetEntityVelocity(fishHandle, GetEntityCoords(playerPed))
                        -- TaskGoToEntity(fishHandle, playerPed, 1000, 20, 1.0, 0.0, 1) !!
                        -- Citizen.InvokeNative(0x53187E563F938E76,1)
                    end

                    if IsControlJustReleased(0, GetHashKey("INPUT_GAME_MENU_OPTION")) then
                        FISHING_SET_ROD_WEIGHT(2)
                    end
                end

                if FISHING_GET_F_(6) ~= 11 and FISHING_GET_F_(6) ~= 12 then
                    FISHING_SET_F_(13, fishForce)
                    FISHING_SET_F_(21, fishForce)
                end

                if IsControlJustPressed(0, GetHashKey("INPUT_ATTACK")) then
                    FISHING_SET_ROD_POSITION_UD(0.6)
                end

                if IsControlJustReleased(0, GetHashKey("INPUT_ATTACK")) then
                    FISHING_SET_ROD_POSITION_UD(0.0)
                end
            end

            if FISHING_GET_MINIGAME_STATE() == 12 then
                if IsControlJustPressed(0, GetHashKey("INPUT_ATTACK")) then
                    if fishing then
                        FISHING_SET_TRANSITION_FLAG(32)
                        fishing = false
                        currentLure = nil
                        status = "keep"
                        local entity = FISHING_GET_FISH_HANDLE()
                        -- check if its networked
                        local isNetworked = NetworkGetEntityIsNetworked(entity)
                        if isNetworked then
                            local netid = NetworkGetNetworkIdFromEntity(entity)
                            local model = GetEntityModel(entity)
                            TriggerServerEvent("lp_fishing:FishToInventory", netid, model, fishing_data.fish.weight, status)

                            SetEntityAsMissionEntity(entity, true, true)
                            Citizen.Wait(3000)
                            DeleteEntity(entity)
                            Citizen.InvokeNative(0x9B0C7FA063E67629, PlayerPedId(), "", 0, 1)
                        else
                            print("Fish Entity is not networked")
                        end
                    end
                end

                if IsControlJustPressed(0, GetHashKey("INPUT_AIM")) then
                    if fishing then
                        fishing = false
                        currentLure = nil
                        status = "throw"
                        local entity = FISHING_GET_FISH_HANDLE()
                        local fishModel = GetEntityModel(entity)
                        Citizen.InvokeNative(0x9B0C7FA063E67629, PlayerPedId(), "", 0, 1)
                        FISHING_SET_TRANSITION_FLAG(64)
                        if Config.DiscordIntegration == true then
                            TriggerServerEvent("lp_fishing:discord", fishModel, fishing_data.fish.weight, status, GetPlayerServerId(PlayerId()))
                        end
                        SetEntityAsMissionEntity(entity, true, true)
                        Citizen.Wait(3000)
                        DeleteEntity(entity)
                    end
                end

                if FISHING_GET_F_(5) == 96 and FISHING_GET_F_(6) == 0 then
                    fishing = false
                    Citizen.InvokeNative(0x9B0C7FA063E67629, PlayerPedId(), "", 0, 1)
                    local entity = FISHING_GET_FISH_HANDLE()
                    SetEntityAsMissionEntity(entity, true, true)
                    Citizen.Wait(3000)
                    DeleteEntity(entity)
                end
            end

            if IsControlJustPressed(0, GetHashKey("INPUT_TOGGLE_HOLSTER")) then
                fishing = false
                -- เก็บเบ็ด = เหยื่อไม่ได้ติดอยู่แล้ว ต้องเคลียร์ด้วย ไม่งั้นค่าค้าง
                -- แล้วรอบหน้าที่หยิบเบ็ดขึ้นมาเปล่าๆ ระบบจะคิดว่ายังมีเหยื่อติดอยู่
                currentLure = nil
                FISHING_SET_TRANSITION_FLAG(8)
                Citizen.InvokeNative(0x9B0C7FA063E67629, PlayerPedId(), "", 0, 1)
            end
        end
        -- lastState = FISHING_GET_MINIGAME_STATE()
        Wait(sleep)
    end
    TriggerServerEvent("lp_fishing:stopFishing")
end)

CreateThread(function()
    prepareMyPrompt()
    while true do
        Wait(0)
        if FISHING_GET_MINIGAME_STATE() == 1 then
            UiPromptSetActiveGroupThisFrame(fishing_data.prompt_prepare_fishing.group, VarString(10, "LITERAL_STRING", T.ReadyToFish), 0, 0, 0, 0)
        end

        if FISHING_GET_MINIGAME_STATE() == 6 then
            UiPromptSetActiveGroupThisFrame(fishing_data.prompt_waiting_hook.group, VarString(10, "LITERAL_STRING", T.Fishing), 0, 0, 0, 0)
        end

        if FISHING_GET_MINIGAME_STATE() == 7 then
            fishing_data.fish.weight = FISHING_GET_F_(8)
            UiPromptSetActiveGroupThisFrame(fishing_data.prompt_hook.group, VarString(10, "LITERAL_STRING", T.MiniGame), 0, 0, 0, 0)
        end

        if FISHING_GET_MINIGAME_STATE() == 12 then
            if fishs[GetEntityModel(FISHING_GET_FISH_HANDLE())] ~= nil then
                UiPromptSetActiveGroupThisFrame(fishing_data.prompt_finish.group, VarString(10, "LITERAL_STRING",
                    T.FishName ..
                    " : " ..
                    fishs[GetEntityModel(FISHING_GET_FISH_HANDLE())] ..
                    " // " ..
                    T.FishWeight ..
                    " : " .. string.format("%.2f%%", (fishing_data.fish.weight * 54.25)):gsub("%%", "") .. "Kg"), 0, 0, 0, 0)
            end
        end
    end
end)

function GET_TASK_FISHING_DATA()
    local r = exports["lp_fishing"]:GET_TASK_FISHING_DATA_EXTRA()
    hasMinigameOn = r[1]
    local outAsInt = r[2]
    local outAsFloat = r[3]

    fishing_minigame_struct = {}

    fishing_minigame_struct = {
        f_0 = outAsInt["0"],
        f_1 = outAsFloat["2"],
        f_2 = outAsFloat["4"],
        f_3 = outAsFloat["6"],
        f_4 = outAsFloat["8"],
        f_5 = outAsInt["10"],
        f_6 = outAsInt["12"],
        f_7 = outAsInt["14"],
        f_8 = outAsFloat["16"],
        f_9 = outAsFloat["18"],
        f_10 = outAsInt["20"],
        f_11 = outAsInt["22"],
        f_12 = outAsInt["24"],
        f_13 = outAsFloat["26"],
        f_14 = outAsFloat["28"],
        f_15 = outAsFloat["30"],
        f_16 = outAsInt["32"],
        f_17 = outAsFloat["34"],
        f_18 = outAsInt["36"],
        f_19 = outAsInt["38"],
        f_20 = outAsFloat["40"],
        f_21 = outAsFloat["42"],
        f_22 = outAsFloat["44"],
        f_23 = outAsFloat["46"],
        f_24 = outAsFloat["48"],
        f_25 = outAsFloat["50"],
        f_26 = outAsFloat["52"],
        f_27 = outAsFloat["54"]
    }
end

-- BaitsPerFish เก็บ "ชื่อโมเดล" เป็น string ("A_C_FISHBLUEGIL_01_MS") แต่ตาราง fishs
-- ใช้ hash เป็น key และเก็บ "ชื่อที่โชว์" เป็น value ("Blue Gil (Medium)")
-- โค้ดเดิมเทียบ fishs[hash] == "A_C_FISH..." ซึ่งเป็นคนละอย่าง ไม่มีทางตรงกันได้เลย
-- ผลคือ isFishInterested คืน false ตลอด ปลาไม่เคยถูกล่อเข้าหาทุ่น (TaskGoToEntity ไม่เคยทำงาน)
-- แปลงเป็นตาราง hash ไว้ล่วงหน้าแล้วเทียบ hash ตรงๆ แทน
local baitFishHashes = {}
function baitAttracts(bait, fishModelHash)
    if not bait then return false end
    local set = baitFishHashes[bait]
    if not set then
        local list = BaitsPerFish[bait]
        if not list then return false end
        set = {}
        for _, name in ipairs(list) do set[GetHashKey(name)] = true end
        baitFishHashes[bait] = set
    end
    return set[fishModelHash] == true
end

function isFishInterested(fishModel)
    return baitAttracts(currentLure, fishModel)
end

function SET_TASK_FISHING_DATA()
    if fishing_minigame_struct.f_0 ~= nil then
        exports["lp_fishing"]:SET_TASK_FISHING_DATA_EXTRA(fishing_minigame_struct)
    end
end

function FISHING_HAS_MINIGAME_ON()
    return hasMinigameOn
end

function FISHING_GET_F_(f)
    return fishing_minigame_struct["f_" .. f]
end

function FISHING_GET_MINIGAME_STATE()
    return FISHING_GET_F_(0)
end

function FISHING_GET_MAX_THROWING_DISTANCE()
    return FISHING_GET_F_(1)
end

function FISHING_GET_LINE_DISTANCE()
    return FISHING_GET_F_(2)
end

function FISHING_GET_TRANSITION_FLAG()
    return FISHING_GET_F_(6)
end

function FISHING_GET_FISH_HANDLE()
    return FISHING_GET_F_(7)
end

function FISHING_GET_CALCULATED_FISH_WEIGHT()
    return FISHING_GET_F_(8)
end

function FISHING_GET_F_9()
    return FISHING_GET_F_(9)
end

function FISHING_GET_SCRIPT_TIMER()
    return FISHING_GET_F_(10)
end

function FISHING_GET_BOBBER_HANDLE()
    return FISHING_GET_F_(11)
end

function FISHING_GET_HOOK_HANDLE()
    return FISHING_GET_F_(12)
end

function FISHING_SET_F_(f, v)
    fishing_minigame_struct["f_" .. f] = v
    SET_TASK_FISHING_DATA()
end

function FISHING_SET_LINE_DISTANCE(v)
    FISHING_SET_F_(2, v)
end

function FISHING_SET_TRANSITION_FLAG(v)
    FISHING_SET_F_(6, v)
end

function FISHING_SET_FISH_HANDLE(v)
    FISHING_SET_F_(7, v)
    local weight_index = FishModelToSomeSortOfWeightIndex(GetEntityModel(v))

    FISHING_SET_CALCULATED_FISH_WEIGHT(GetRandomFishWeightForWeightIndex(weight_index) / 54.25)

    fishing_data.fish.rodweight = 2
    FISHING_SET_ROD_WEIGHT(fishing_data.fish.rodweight)
end

function FISHING_SET_CALCULATED_FISH_WEIGHT(v)
    fishing_data.fish.weight = v * 54.25

    FISHING_SET_F_(8, v)
end

function FISHING_SET_ROD_WEIGHT(v)
    FISHING_SET_F_(18, v)
end

function FISHING_SET_ROD_POSITION_LR(v)
    FISHING_SET_F_(22, v)
end

function FISHING_SET_ROD_POSITION_UD(v)
    FISHING_SET_F_(23, v)
end

function GetNearbyFishs(coords, radius)
    local r = {}

    local itemSet = CreateItemset(true)
    local size = Citizen.InvokeNative(0x59B57C4B06531E1E, coords, radius, itemSet, 1, Citizen.ResultAsInteger())

    if size > 0 then
        for index = 0, size - 1 do
            local entity = GetIndexedItemInItemset(index, itemSet)
            local populationType = GetEntityPopulationType(entity)
            if (populationType == 6 or populationType == 8) and not IsPedDeadOrDying(entity, false) then
                table.insert(r, entity)
            end
        end
    end

    if IsItemsetValid(itemSet) then
        DestroyItemset(itemSet)
    end

    return r
end

function FishModelToSomeSortOfWeightIndex(fishModel)
    if fishModel == GetHashKey("A_C_FISHBLUEGIL_01_SM") then ------Small size fish
        return 0
    elseif fishModel == GetHashKey("A_C_FISHBULLHEADCAT_01_SM") then
        return 1
    elseif fishModel == GetHashKey("A_C_FISHREDFINPICKEREL_01_SM") then
        return 2
    elseif fishModel == GetHashKey("A_C_FISHPERCH_01_SM") then
        return 3
    elseif fishModel == GetHashKey("A_C_FISHCHAINPICKEREL_01_SM") then
        return 4
    elseif fishModel == GetHashKey("A_C_FISHROCKBASS_01_SM") then
        return 5
    elseif fishModel == GetHashKey("A_C_FISHBLUEGIL_01_MS") then ------ Medium Size fish
        return 6
    elseif fishModel == GetHashKey("A_C_FISHBULLHEADCAT_01_MS") then
        return 7
    elseif fishModel == GetHashKey("A_C_FISHCHAINPICKEREL_01_MS") then
        return 8
    elseif fishModel == GetHashKey("A_C_FISHPERCH_01_MS") then
        return 9
    elseif fishModel == GetHashKey("A_C_FISHLARGEMOUTHBASS_01_MS") then
        return 10
    elseif fishModel == GetHashKey("A_C_FISHREDFINPICKEREL_01_MS") then
        return 11
    elseif fishModel == GetHashKey("A_C_FISHRAINBOWTROUT_01_MS") then
        return 12
    elseif fishModel == GetHashKey("A_C_FISHROCKBASS_01_MS") then
        return 13
    elseif fishModel == GetHashKey("A_C_FISHSALMONSOCKEYE_01_MS") then
        return 14
    elseif fishModel == GetHashKey("A_C_FISHSMALLMOUTHBASS_01_MS") then
        return 15
    elseif fishModel == GetHashKey("A_C_FISHSALMONSOCKEYE_01_ML") then  ----- Medium Large fish
        return 16
    elseif fishModel == GetHashKey("A_C_FISHCHANNELCATFISH_01_LG") then ---- Large Fish
        return 17
    elseif fishModel == GetHashKey("A_C_FISHLAKESTURGEON_01_LG") then
        return 18
    elseif fishModel == GetHashKey("A_C_FISHLARGEMOUTHBASS_01_LG") then
        return 19
    elseif fishModel == GetHashKey("A_C_FISHLONGNOSEGAR_01_LG") then
        return 20
    elseif fishModel == GetHashKey("A_C_FISHMUSKIE_01_LG") then
        return 21
    elseif fishModel == GetHashKey("A_C_FISHNORTHERNPIKE_01_LG") then
        return 22
    elseif fishModel == GetHashKey("A_C_FISHRAINBOWTROUT_01_LG") then
        return 23
    elseif fishModel == GetHashKey("A_C_FISHSALMONSOCKEYE_01_LG") then
        return 24
    elseif fishModel == GetHashKey("A_C_FISHSMALLMOUTHBASS_01_LG") then
        return 25
    end
end

function GetMinMaxWeightForWeightIndex(index)
    local min = 0.0
    local max = 0.0

    if index == 0 or index == 1 or index == 2 or index == 3 or index == 4 or index == 5 then -----small fish
        min = 0.5
        max = 5.0
    elseif index == 17 or index == 18 or index == 20 or index == 21 or index == 22 or index == 16 then ----Large
        min = 14.0
        max = 20.0
    elseif index == 19 or index == 23 or index == 24 or index == 25 then ----Legendary large
        min = 20.0
        max = 25.0
    elseif index == 6 or index == 7 or index == 8 or index == 9 or index == 10 or index == 11 or index == 12 or index == 13 or index == 14 or index == 15 then ---- Med and Legend med
        min = 6.0
        max = 10.0
    end

    min = min
    max = max

    return min, max
end

function GetRandomFishWeightForWeightIndex(index)
    local min, max = GetMinMaxWeightForWeightIndex(index)
    local weight = math.random() * (max - min) + min

    return weight
end

function prepareMyPrompt()
    fishing_data.prompt_prepare_fishing.group = GetRandomIntInRange(0, 0xffffff)
    local prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, GetHashKey("INPUT_AIM")) -- MOUSE LEFT CLICK
    UiPromptSetText(prompt, VarString(10, "LITERAL_STRING", T.PrepRod))
    UiPromptSetEnabled(prompt, true)
    UiPromptSetVisible(prompt, true)
    UiPromptSetHoldMode(prompt, 0)
    UiPromptSetGroup(prompt, fishing_data.prompt_prepare_fishing.group, 0)
    UiPromptRegisterEnd(prompt)
    fishing_data.prompt_prepare_fishing.change_bait = prompt

    prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, 0x07CE1E61) -- LEFT CONTROL
    UiPromptSetText(prompt, VarString(10, "LITERAL_STRING", T.ThrowHook))
    UiPromptSetEnabled(prompt, true)
    UiPromptSetVisible(prompt, true)
    UiPromptSetHoldMode(prompt, 0)
    UiPromptSetGroup(prompt, fishing_data.prompt_prepare_fishing.group, 0)
    UiPromptRegisterEnd(prompt)
    fishing_data.prompt_prepare_fishing.throw_hook = prompt


    fishing_data.prompt_waiting_hook.group = GetRandomIntInRange(0, 0xffffff)
    prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, GetHashKey("INPUT_ATTACK")) -- MOUSE LEFT CLICK
    UiPromptSetText(prompt, VarString(10, "LITERAL_STRING", T.HookFish))
    UiPromptSetEnabled(prompt, true)
    UiPromptSetVisible(prompt, true)
    UiPromptSetHoldMode(prompt, 0)
    UiPromptSetGroup(prompt, fishing_data.prompt_waiting_hook.group, 0)
    UiPromptRegisterEnd(prompt)
    fishing_data.prompt_waiting_hook.hook_fish = prompt

    prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, 0x8FFC75D6) -- LEFT SHIFT
    UiPromptSetText(prompt, VarString(10, "LITERAL_STRING", T.Cancel))
    UiPromptSetEnabled(prompt, true)
    UiPromptSetVisible(prompt, true)
    UiPromptSetHoldMode(prompt, 0)
    UiPromptSetGroup(prompt, fishing_data.prompt_waiting_hook.group, 0)
    UiPromptRegisterEnd(prompt)
    fishing_data.prompt_waiting_hook.cancel = prompt

    prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, 0xDB096B85) -- LEFT CONTROL
    UiPromptSetText(prompt, VarString(10, "LITERAL_STRING", T.ReelLure))
    UiPromptSetEnabled(prompt, true)
    UiPromptSetVisible(prompt, true)
    UiPromptSetHoldMode(prompt, 0)
    UiPromptSetGroup(prompt, fishing_data.prompt_waiting_hook.group, 0)
    UiPromptRegisterEnd(prompt)
    fishing_data.prompt_waiting_hook.reel_lure = prompt

    -- Puxando Peixe
    fishing_data.prompt_hook.group = GetRandomIntInRange(0, 0xffffff)
    prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, 0xFBD7B3E6) -- SPACE
    UiPromptSetText(prompt, VarString(10, "LITERAL_STRING", T.ReelIn))
    UiPromptSetEnabled(prompt, true)
    UiPromptSetVisible(prompt, true)
    UiPromptSetHoldMode(prompt, 0)
    UiPromptSetGroup(prompt, fishing_data.prompt_hook.group, 0)
    UiPromptRegisterEnd(prompt)
    fishing_data.prompt_hook.reel = prompt

    prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, 0x8FFC75D6) -- LEFT SHIFT
    UiPromptSetText(prompt, VarString(10, "LITERAL_STRING", T.Cancel))
    UiPromptSetEnabled(prompt, true)
    UiPromptSetVisible(prompt, true)
    UiPromptSetHoldMode(prompt, 0)
    UiPromptSetGroup(prompt, fishing_data.prompt_hook.group, 0)
    UiPromptRegisterEnd(prompt)
    fishing_data.prompt_hook.cancel = prompt

    -- Peixe Pego
    fishing_data.prompt_finish.group = GetRandomIntInRange(0, 0xffffff)
    prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, GetHashKey("INPUT_ATTACK")) -- MOUSE LEFT CLICK
    UiPromptSetText(prompt, VarString(10, "LITERAL_STRING", T.KeepFish))
    UiPromptSetEnabled(prompt, true)
    UiPromptSetVisible(prompt, true)
    UiPromptSetHoldMode(prompt, 0)
    UiPromptSetGroup(prompt, fishing_data.prompt_finish.group, 0)
    UiPromptRegisterEnd(prompt)
    fishing_data.prompt_finish.keep_fish = prompt

    prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, GetHashKey("INPUT_AIM")) -- MOUSE RIGHT CLICK
    UiPromptSetText(prompt, VarString(10, "LITERAL_STRING", T.ThrowFish))
    UiPromptSetEnabled(prompt, true)
    UiPromptSetVisible(prompt, true)
    UiPromptSetHoldMode(prompt, 0)
    UiPromptSetGroup(prompt, fishing_data.prompt_finish.group, 0)
    UiPromptRegisterEnd(prompt)
    fishing_data.prompt_finish.throw_fish = prompt
end

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        UiPromptDelete(fishing_data.prompt_prepare_fishing.throw_hook)
        UiPromptDelete(fishing_data.prompt_waiting_hook.hook_fish)
        UiPromptDelete(fishing_data.prompt_waiting_hook.cancel)
        UiPromptDelete(fishing_data.prompt_hook.reel)
        UiPromptDelete(fishing_data.prompt_hook.cancel)
        UiPromptDelete(fishing_data.prompt_finish.keep_fish)
        UiPromptDelete(fishing_data.prompt_finish.throw_fish)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  lp_fishing — ส่วนที่เพิ่มจาก vorp_fishing เดิม
--  (1) prompt เริ่มตกปลาด้วย lp_textui แทน native prompt ตอนยังไม่ได้หยิบเบ็ด
--  (2) lp_progbar ตอนดึงปลาขึ้นมา
--  แยกไว้ท้ายไฟล์ ไม่แตะ state machine เดิมของเกม เพื่อให้ merge ของต้นทางง่ายถ้ามีอัปเดต
-- ═══════════════════════════════════════════════════════════════════════════

local startPromptShown = false

-- ยิง probe ลงในแนวดิ่งรอบตัวเพื่อหาว่ามีน้ำใกล้ๆ ไหม — ใช้ helper เดียวกับที่ตัวเกมใช้หาผิวน้ำ
-- (TEST_VERTICAL_PROBE_AGAINST_ALL_WATER ผ่าน export VERTICAL_PROBE ใน client_js.js)
local function isNearWater()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local range = Config.StartPrompt.WaterRange or 12.0

    -- ยิง 5 จุด: ตรงตัว + 4 ทิศรอบตัว กันเคสยืนบนฝั่งแล้วน้ำอยู่ข้างหน้า
    local offsets = {
        { 0.0, 0.0 }, { range, 0.0 }, { -range, 0.0 }, { 0.0, range }, { 0.0, -range },
    }
    for _, o in ipairs(offsets) do
        local ok, res = pcall(function()
            return exports['lp_fishing']:VERTICAL_PROBE(c.x + o[1], c.y + o[2], c.z + 10.0, 1)
        end)
        if ok and type(res) == 'table' and res[1] then return true end
    end
    return false
end

local function isHoldingRod()
    local _, weapon = GetCurrentPedWeapon(PlayerPedId(), true, 0, true)
    return weapon == GetHashKey(Config.RodWeapon or 'WEAPON_FISHINGROD')
end

local function hideStartPrompt()
    if not startPromptShown then return end
    startPromptShown = false
    exports.lp_textui:CancelHold()
end

CreateThread(function()
    if not Config.StartPrompt.Enabled then return end
    Wait(2000)

    while true do
        local sleep = Config.StartPrompt.ScanMs or 500

        -- โชว์เฉพาะตอน "ยังไม่ได้เข้าโหมดตกปลา" (state 0) และยังไม่ได้ถือเบ็ด
        -- ถ้าถือเบ็ดแล้วเกมจะเข้า state 1 เอง native prompt ของเกมรับช่วงต่อ
        local idle = FISHING_GET_MINIGAME_STATE() == 0
        if idle and not isHoldingRod() and isNearWater() then
            if not startPromptShown then
                startPromptShown = true
                exports.lp_textui:TextUIHold(
                    Config.StartPrompt.Text or '[E] เริ่มตกปลา',
                    Config.StartPrompt.HoldMs or 500,
                    function()
                        startPromptShown = false
                        -- ให้ server เป็นคนตรวจว่ามีเบ็ดจริงแล้วสั่งหยิบ (ไม่เชื่อ client)
                        TriggerServerEvent('lp_fishing:equipRod')
                    end
                )
            end
            sleep = 300
        else
            hideStartPrompt()
        end

        Wait(sleep)
    end
end)

-- server ยืนยันว่ามีเบ็ดแล้ว -> หยิบขึ้นมือจริง
RegisterNetEvent('lp_fishing:doEquipRod', function()
    local ped = PlayerPedId()
    local hash = GetHashKey(Config.RodWeapon or 'WEAPON_FISHINGROD')
    RequestWeaponAsset(hash, 31, 0)
    local t = GetGameTimer()
    while not HasWeaponAssetLoaded(hash) and (GetGameTimer() - t) < 2000 do Wait(0) end
    GiveWeaponToPed_2(ped, hash, 0, true, true, 0, false, 0.5, 1.0, 0, false, 0.0, 0)
    SetCurrentPedWeapon(ped, hash, true, 0, false, false)
end)

-- lp_progbar ตอนปลาติดเบ็ดแล้วกำลังเก็บขึ้นมา (state 12) — ยิงครั้งเดียวต่อการตก 1 ตัว
CreateThread(function()
    if not Config.LandingBar.Enabled then return end
    local barShownFor = nil

    while true do
        Wait(100)
        local state = FISHING_GET_MINIGAME_STATE()

        if state == 12 then
            local handle = FISHING_GET_FISH_HANDLE()
            if handle and handle ~= 0 and barShownFor ~= handle then
                barShownFor = handle
                pcall(function()
                    exports.lp_progbar:Progress({
                        duration = Config.LandingBar.Duration or 1500,
                        label    = Config.LandingBar.Label or 'กำลังเก็บปลา...',
                    })
                end)
            end
        elseif state == 0 then
            barShownFor = nil
        end
    end
end)

-- ── กันเหยื่อหายฟรีระหว่างตกปลา ──────────────────────────────────────────────
-- สกรอลล์เมาส์ใน RedM คือปุ่มสลับอาวุธ (INPUT_SELECT_PREV/NEXT_WEAPON) ไม่ใช่
-- ปุ่มเคอร์เซอร์ — เผลอสกรอลล์ทีเดียวระหว่างตกปลาจะเปิด weapon wheel แล้วเกม
-- เก็บเบ็ดให้เอง จบการตกปลาโดยที่เหยื่อถูกหักไปแล้ว (server หัก subItem ตอนใช้
-- ไอเทม ไม่ใช่ตอนได้ปลา) เลยปิดปุ่มพวกนี้ไว้ตลอดช่วงตกปลา
-- ไม่ปิด INPUT_TOGGLE_HOLSTER เพราะเป็นปุ่มเลิกตกปลาโดยตั้งใจ
CreateThread(function()
    local G = Config.FishingGuard
    if not G or not G.Enabled then return end

    local blockHashes = {}
    for _, name in ipairs(G.BlockControls or {}) do
        blockHashes[#blockHashes + 1] = GetHashKey(name)
    end
    local blockStates = {}
    for _, st in ipairs(G.BlockDuringStates or {}) do
        blockStates[st] = true
    end

    while true do
        local sleep = 200
        if blockStates[FISHING_GET_MINIGAME_STATE()] then
            sleep = 0
            for i = 1, #blockHashes do
                DisableControlAction(0, blockHashes[i], true)
            end
        end
        Wait(sleep)
    end
end)

-- ── debug ไว้ไล่หาค่าตอนทดสอบในเกม ──────────────────────────────────────────
CreateThread(function()
    if not Config.DebugCommands then return end

    -- ดูค่าทั้ง struct ของมินิเกมตกปลา
    RegisterCommand('fishdump', function()
        print('[lp_fishing] state=' .. tostring(FISHING_GET_MINIGAME_STATE()) ..
              ' maxThrow(f_1)=' .. tostring(FISHING_GET_MAX_THROWING_DISTANCE()) ..
              ' lineDist(f_2)=' .. tostring(FISHING_GET_LINE_DISTANCE()))
        for i = 0, 27 do
            print(('  f_%d = %s'):format(i, tostring(FISHING_GET_F_(i))))
        end
    end, false)

    -- ตามดู state + f_1 ทุกเฟรม พิมพ์เฉพาะตอนค่าเปลี่ยน
    -- ใช้ไล่ดูว่าการตกปลา 1 รอบวิ่งผ่าน state ไหนบ้าง
    local watching = false
    RegisterCommand('fishwatch', function()
        watching = not watching
        print('[lp_fishing] fishwatch = ' .. tostring(watching))
        if not watching then return end

        CreateThread(function()
            local lastState, lastF1 = nil, nil
            local t0 = GetGameTimer()
            while watching do
                local st = FISHING_GET_MINIGAME_STATE()
                local f1 = FISHING_GET_MAX_THROWING_DISTANCE()
                if st ~= lastState or f1 ~= lastF1 then
                    print(('[lp_fishing] +%dms state=%s f_1=%s')
                        :format(GetGameTimer() - t0, tostring(st), tostring(f1)))
                    lastState, lastF1 = st, f1
                end
                Wait(0)
            end
        end)
    end, false)

end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    hideStartPrompt()
    -- panel เป็นของ resource อื่น ถ้าไม่สั่งซ่อนมันจะค้างบนจอหลัง lp_fishing หยุด
    pcall(function() exports.lp_rewardpanel:Hide() end)
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  lp_rewardpanel — โชว์ว่า "เหยื่อที่ติดอยู่ตอนนี้ล่อปลาอะไรได้บ้าง"
--
--  เดิม MJ-AfkFishing โชว์ pool ปลาพร้อม % ตามโซน แต่ระบบใหม่ไม่มี % แล้ว (ปลาที่ได้คือปลาตัวจริง
--  ที่ว่ายอยู่ในน้ำ) สิ่งที่ยังมีประโยชน์ให้ผู้เล่นเห็นคือ "เหยื่อนี้ปลาชนิดไหนสนใจ" ซึ่งมาจาก
--  BaitsPerFish ตรงๆ — ไม่ส่ง chance ไป panel จะไม่โชว์ป้าย % (ดู html/js/app.js: if (items[i].chance))
-- ═══════════════════════════════════════════════════════════════════════════

-- โมเดลปลาของเกม -> ชื่อไอเทมของเรา (ต้องตรงกับตาราง fishEntity ใน server/server.lua)
-- ใช้เฉพาะหาไอคอนมาโชว์ใน panel เท่านั้น การแจกของจริง server ตัดสินเองทั้งหมด
local FISH_ITEM_BY_SPECIES = {
    bluegil = 'fish_bluegill_small', bullheadcat = 'fish_bullheadcat_small',
    chainpickerel = 'fish_chainpickerel_small', channelcatfish = 'fish_channelcatfish_large',
    lakesturgeon = 'fish_lakesturgeon_large', largemouthbass = 'fish_largemouthbass_medium',
    longnosegar = 'fish_longnosegar_large', muskie = 'fish_muskie_large',
    northernpike = 'fish_northernpike_large', perch = 'fish_perch_small',
    rainbowtrout = 'fish_rainbowtrout_medium', redfinpickerel = 'fish_redfinpickerel_small',
    rockbass = 'fish_rockbass_small', salmonsockeye = 'fish_salmonsockeye_medium',
    smallmouthbass = 'fish_smallmouthbass_medium',
}

local function fishModelToItem(modelName)
    local species = tostring(modelName):lower():match('^a_c_fish([a-z]+)_01_')
    return species and FISH_ITEM_BY_SPECIES[species] or nil
end

local function showBaitPanel(bait)
    local list = BaitsPerFish[bait]
    if not list then return end

    -- ปลาหลายขนาดของชนิดเดียวกัน map เป็นไอเทมเดียว ต้องกันซ้ำไม่งั้นช่องเต็มด้วยปลาชนิดเดิม
    local seen, items = {}, {}
    for _, model in ipairs(list) do
        local item = fishModelToItem(model)
        if item and not seen[item] then
            seen[item] = true
            items[#items + 1] = {
                item = item,
                img  = 'nui://vorp_inventory/html/img/items/' .. item .. '.png',
                -- ไม่ส่ง chance — ระบบนี้ไม่มี % แล้ว panel จะซ่อนป้ายให้เอง
            }
        end
    end

    pcall(function()
        exports.lp_rewardpanel:Show(items, 'เหยื่อนี้ล่อปลาได้', 'Bait Info')
    end)
end

local function hideBaitPanel()
    pcall(function() exports.lp_rewardpanel:Hide() end)
end

-- ตามสถานะเหยื่อ: เบ็ดอยู่ในมือ + มีเหยื่อติดอยู่จริง -> โชว์ panel, นอกนั้นซ่อน
--
-- เชื่อ currentLure อย่างเดียวไม่ได้ เพราะไม่มีจุดไหนเคลียร์มันตอนผู้เล่นเก็บเบ็ด
-- (INPUT_TOGGLE_HOLSTER ตั้งแค่ fishing = false) panel เลยค้างทั้งที่เบ็ดเก็บไปแล้ว
-- จึงเช็คสถานะจริงของเกมด้วย: ถือเบ็ดอยู่ไหม + มินิเกมยังทำงานอยู่ไหม
CreateThread(function()
    local shownFor = nil
    while true do
        Wait(300)

        local ok = false
        local lure = currentLure
        if lure then
            -- refresh struct เอง — ตัวที่อัปเดตให้อยู่ในลูป UseBait ซึ่งหยุดไปแล้ว
            -- ตอนเลิกตกปลา ถ้าไม่ refresh state จะค้างค่าเก่า
            pcall(GET_TASK_FISHING_DATA)
            local holding = isHoldingRod()

            -- โหมดง่ายไม่ได้สตาร์ท native task เลย state จึงเชื่อไม่ได้ (อาจเป็น 0 ตลอด)
            -- ใช้แค่ "ถือเบ็ดอยู่ไหม" เป็นตัวตัดสิน ไม่งั้นจะไปล้าง currentLure ทิ้ง
            -- ตั้งแต่ยังไม่ได้เหวี่ยง แล้วโหมดง่ายจะใช้ไม่ได้เลย
            local simple = Config.SimpleMode and Config.SimpleMode.Enabled
            local active = simple or (FISHING_GET_MINIGAME_STATE() or 0) ~= 0

            if not holding or not active then
                -- มินิเกมจบไปแล้วไม่ว่าด้วยเหตุใด (ตาย เดินหนี เก็บเบ็ดทางอื่น)
                -- เหยื่อไม่ได้ติดอยู่แล้ว เคลียร์ทิ้งกันค่าค้างไปโผล่รอบหน้า
                currentLure = nil
                lure = nil
            else
                ok = true
            end
        end

        if ok then
            if shownFor ~= lure then
                shownFor = lure
                showBaitPanel(lure)
            end
        elseif shownFor then
            shownFor = nil
            hideBaitPanel()
        end
    end
end)

-- flash ช่องปลาที่เพิ่งได้ (server ยืนยันแล้วว่าเข้ากระเป๋าจริง)
RegisterNetEvent('lp_fishing:fishAwarded', function(itemName)
    pcall(function() exports.lp_rewardpanel:Highlight(itemName) end)
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  โหมดง่าย — แยกจากมินิเกมของเกมทั้งหมด (Config.SimpleMode.Enabled)
--
--  ถือเบ็ด -> ใส่เหยื่อ -> กด E -> เล็งไปที่ปลาที่เหยื่อล่อได้ตัวใกล้สุด
--  -> รอปลากิน -> เล่น lp_minigame -> ผ่าน = ได้ปลา / ไม่ผ่าน = ปลาหลุด + เสียเหยื่อ
--
--  ปลาที่จับเป็น entity จริงในน้ำ ไม่ได้สุ่มจากตาราง จึงส่งเข้า server event เดิมได้
--  และได้ด่านตรวจเดิมครบ (playersFishing + DoesEntityExist + canCarryItem)
-- ═══════════════════════════════════════════════════════════════════════════

local function notify(text, kind)
    pcall(function()
        exports.pNotify:SendNotification({ text = text, type = kind or 'error', timeout = 4000 })
    end)
end

-- ปลาที่เหยื่อชิ้นนี้ล่อได้ ตัวที่ใกล้ที่สุด
local function findBaitedFish(radius)
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local best, bestDist

    for _, f in pairs(GetNearbyFishs(coords, radius)) do
        if DoesEntityExist(f) then
            local model = GetEntityModel(f)
            -- ต้องอยู่ในตาราง fishs ด้วย ไม่งั้น server จะหา fishEntity ไม่เจอแล้วทิ้งทั้งรอบ
            if fishs[model] and baitAttracts(currentLure, model) then
                local d = #(coords - GetEntityCoords(f))
                if not bestDist or d < bestDist then best, bestDist = f, d end
            end
        end
    end
    return best
end

local simpleBusy = false

local function simpleCast()
    local S = Config.SimpleMode
    if not currentLure then return end

    local fish = findBaitedFish(S.SearchRadius or 60.0)
    if not fish then
        notify(S.NoFishMsg or 'แถวนี้ไม่มีปลาที่เหยื่อนี้ล่อได้')
        return
    end

    -- หันหน้าไปทางปลาให้ดูเหมือนเหวี่ยงไปหามัน
    local ped = PlayerPedId()
    local pc, fc = GetEntityCoords(ped), GetEntityCoords(fish)
    SetEntityHeading(ped, GetHeadingFromVector_2d(fc.x - pc.x, fc.y - pc.y))

    -- รอปลากินเหยื่อ — lp_progbar:Progress ไม่ block (spawn thread แล้ว return id)
    -- ต้องรอเองผ่าน callback ถึงจะรู้ว่าผู้เล่นกดยกเลิกกลางคันหรือเปล่า
    local waitMs = math.random(S.BiteDelayMin or 3000, S.BiteDelayMax or 8000)
    local done, cancelled = false, false
    local started = pcall(function()
        exports.lp_progbar:Progress(
            { duration = waitMs, label = S.WaitLabel or 'รอปลากินเหยื่อ...', canCancel = true },
            function(wasCancelled) cancelled = wasCancelled; done = true end
        )
    end)
    if started then
        while not done do Wait(50) end
    else
        Wait(waitMs)
    end
    if cancelled then return end

    -- ปลาอาจว่ายหนีไปแล้วระหว่างรอ
    if not DoesEntityExist(fish) then
        notify('ปลาว่ายหนีไปแล้ว')
        return
    end

    -- แยก "แพ้" ออกจาก "เรียก minigame ไม่ได้" — ถ้า lp_minigame พังหรือไม่ได้รัน
    -- ต้องไม่นับเป็นแพ้ ไม่งั้นผู้เล่นเสียเหยื่อฟรีเพราะบั๊กที่ไม่ใช่ความผิดเขา
    local called, passed = pcall(function()
        return exports.lp_minigame:Fishing(S.Minigame or {})
    end)
    if not called then
        print('[lp_fishing] เรียก lp_minigame:Fishing ไม่ได้: ' .. tostring(passed))
        notify('ระบบมินิเกมมีปัญหา ลองใหม่อีกครั้ง')
        return
    end

    if not passed then
        notify(S.FailMsg or 'ปลาหลุด! เหยื่อหายไปด้วย')
        currentLure = nil                                  -- เสียเหยื่อ ต้องใส่ใหม่
        TriggerServerEvent('lp_fishing:stopFishing')
        return
    end

    -- ปลาที่ว่ายในน้ำเป็น entity ของ client ฝั่งเดียว server จะมองไม่เห็นถ้าไม่ register
    -- ก่อน — ไม่มี netid ที่ใช้ได้ = แจกของไม่ได้ ต้องเช็คซ้ำหลัง register แล้วยอมแพ้
    -- แบบไม่แจกของ ดีกว่าส่ง netid มั่วไปให้ server
    if not NetworkGetEntityIsNetworked(fish) then
        NetworkRegisterEntityAsNetworked(fish)
    end
    if not NetworkGetEntityIsNetworked(fish) then
        notify('จับปลาตัวนี้ไม่ได้ ลองตัวอื่น')
        return
    end

    SetEntityAsMissionEntity(fish, true, true)
    TriggerServerEvent('lp_fishing:FishToInventory',
        NetworkGetNetworkIdFromEntity(fish),
        GetEntityModel(fish),
        math.random(30, 90) / 100,
        'keep')

    currentLure = nil
    Wait(500)   -- ให้ FishToInventory ถึง server ก่อนค่อยเคลียร์สถานะกำลังตกปลา
    TriggerServerEvent('lp_fishing:stopFishing')
end

CreateThread(function()
    local S = Config.SimpleMode
    if not S or not S.Enabled then return end

    local promptShown = false

    while true do
        local sleep = 500
        local ready = (not simpleBusy) and currentLure and isHoldingRod() and isNearWater()

        if ready then
            sleep = 300
            if not promptShown then
                promptShown = true
                exports.lp_textui:TextUIHold(S.PromptText or 'เหวี่ยงเบ็ด', S.HoldMs or 200, function()
                    promptShown = false
                    if simpleBusy then return end
                    simpleBusy = true
                    CreateThread(function()
                        local ok, err = pcall(simpleCast)
                        if not ok then print('[lp_fishing] simpleCast error: ' .. tostring(err)) end
                        simpleBusy = false
                    end)
                end)
            end
        elseif promptShown then
            promptShown = false
            pcall(function() exports.lp_textui:CancelHold() end)
        end

        Wait(sleep)
    end
end)
