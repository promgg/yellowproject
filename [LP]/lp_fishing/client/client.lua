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

function isFishInterested(fishModel)
    local baitedFish = BaitsPerFish[currentLure]
    if baitedFish ~= nil then
        for _, fish in pairs(baitedFish) do
            if fishs[fishModel] == fish then
                return true
            end
        end
    end
    return false
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

-- ── โหมดเล็งเหวี่ยงเบ็ด ─────────────────────────────────────────────────────
-- คลิกขวา 1 ครั้ง = เข้า/ออกโหมดเล็ง | เมาส์ = ทิศ | สกรอลล์ = ระยะ | E = เหวี่ยง
--
-- ไม่ได้เทเลพอร์ตเบ็ดและไม่ได้ปลอม input — native เป็นคนเหวี่ยงเองตอนผู้เล่นคลิก
-- (prompt "Cast Fishing Rod" ของเกม) เราแค่เซ็ต f_1 (ระยะเหวี่ยงสูงสุด) = ระยะถึง
-- marker ก่อน แล้วยึดค่านั้นไว้ระหว่างที่เบ็ดลอยออกไป physics ยังเป็นของเกมทั้งหมด

-- แปลงมุมกล้องเป็นเวกเตอร์ทิศทาง
local function camForwardVec()
    local rot = GetGameplayCamRot(2)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local cosRx = math.cos(rx)
    return vector3(-math.sin(rz) * cosRx, math.cos(rz) * cosRx, math.sin(rx))
end

-- หาความสูงผิวน้ำที่พิกัด x,y — คืน nil ถ้าตรงนั้นไม่ใช่น้ำ
local function waterZAt(x, y, fromZ)
    local ok, res = pcall(function()
        return exports['lp_fishing']:VERTICAL_PROBE(x, y, fromZ + 10.0, 1)
    end)
    if ok and type(res) == 'table' and res[1] then return res[2] end
    return nil
end

local function drawText3D(x, y, z, text)
    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(x, y, z)
    if not onScreen then return end
    local str = CreateVarString(10, 'LITERAL_STRING', tostring(text))
    SetTextScale(0.35, 0.35)
    SetTextColor(255, 235, 190, 235)
    SetTextCentre(true)
    SetTextDropshadow(1, 0, 0, 0, 255)
    -- RedM บางบิลด์ไม่มี SetTextOutline — กันไว้ไม่ให้สคริปต์พัง
    if SetTextOutline then SetTextOutline() end
    DisplayText(str, sx, sy)
end

-- เส้นโค้งพาราโบลาจากปลายคันเบ็ดถึง marker
local function drawCastArc(fx, fy, fz, tx, ty, tz, A)
    local segs = A.ArcSegments or 14
    local col  = A.ArcColor or { r = 235, g = 200, b = 120, a = 200 }
    local dx, dy = tx - fx, ty - fy
    local flat = math.sqrt(dx * dx + dy * dy)
    local peak = flat * (A.ArcHeight or 0.25)

    local px, py, pz = fx, fy, fz
    for i = 1, segs do
        local t = i / segs
        local nx = fx + dx * t
        local ny = fy + dy * t
        -- ยกโค้ง: สูงสุดกลางทาง (4t(1-t) = 1 ที่ t=0.5)
        local nz = fz + (tz - fz) * t + peak * 4.0 * t * (1.0 - t)
        DrawLine(px, py, pz, nx, ny, nz, col.r, col.g, col.b, col.a)
        px, py, pz = nx, ny, nz
    end
end

local aimActive  = false
local aimCasting = false

CreateThread(function()
    local A = Config.AimMode
    local M = Config.CastMarker
    if not A or not A.Enabled then return end
    if not M or not M.Enabled then return end

    local hToggle = GetHashKey(A.ToggleControl or 'INPUT_AIM')
    local hCast   = GetHashKey(A.CastControl or 'INPUT_CONTEXT')
    local hCancel = GetHashKey(A.CancelControl or 'INPUT_FRONTEND_CANCEL')
    local hUp     = GetHashKey(A.ScrollUpControl or 'INPUT_CURSOR_SCROLL_UP')
    local hDown   = GetHashKey(A.ScrollDownControl or 'INPUT_CURSOR_SCROLL_DOWN')

    local aimDist, aimMax = 0.0, 0.0
    local lastProbeAt, lastProbeZ = 0, nil

    -- ปุ่มที่ต้องปิดตลอดช่วงตกปลา (สกรอลล์ = ปุ่มสลับอาวุธ → เปิด weapon wheel → เกมเก็บเบ็ด)
    local blockHashes = {}
    for _, name in ipairs(A.BlockControls or {}) do
        blockHashes[#blockHashes + 1] = GetHashKey(name)
    end
    local blockStates = {}
    for _, st in ipairs(A.BlockDuringStates or { 1, 2, 6, 7, 12 }) do
        blockStates[st] = true
    end

    -- เกมเหวี่ยงเองอยู่แล้วเมื่อผู้เล่นคลิก (prompt "Cast Fishing Rod" ของ native)
    -- เราจึงไม่ปลอม input แค่ตั้ง f_1 = ระยะถึง marker แล้วยึดค่านั้นไว้ตลอด
    -- ช่วงที่เบ็ดกำลังลอยออกไป ให้เกมใช้ค่าของเราเป็นระยะจริง
    local function holdCastDistance(dist)
        if aimCasting then return end
        aimCasting = true
        aimActive  = false

        CreateThread(function()
            FISHING_SET_F_(1, dist + 0.0)

            -- state ที่ถือว่า "เบ็ดกำลังออก" — จาก /fishwatch พบว่าเกมใช้ 13 ไม่ใช่ 2
            -- เขียน f_1 ซ้ำทุกเฟรมตลอดช่วงนี้ กันเกมคำนวณทับ
            local holdStates = {}
            for _, st in ipairs(A.HoldDuringStates or { 2, 13 }) do holdStates[st] = true end

            local holdUntil = GetGameTimer() + (A.HoldMaxDistMs or 1500)
            while GetGameTimer() < holdUntil do
                local st = FISHING_GET_MINIGAME_STATE()
                if holdStates[st] then
                    FISHING_SET_F_(1, dist + 0.0)
                elseif st == 6 or st == 7 or st == 12 then
                    break -- เบ็ดลงน้ำแล้ว ไม่ต้องยึดต่อ
                end
                Wait(0)
            end

            Wait(300)
            aimCasting = false
        end)
    end

    while true do
        local sleep = 200
        local state = FISHING_GET_MINIGAME_STATE()

        -- ปิด weapon wheel / สลับอาวุธ ตลอดช่วงตกปลา ไม่ใช่แค่ตอนเล็ง
        -- เพราะสกรอลล์ผิดจังหวะทีเดียวเกมจะเก็บเบ็ดเองแล้วเหยื่อหายฟรี
        if blockStates[state] then
            sleep = 0
            for i = 1, #blockHashes do
                DisableControlAction(0, blockHashes[i], true)
            end
        end

        -- เล็งได้เฉพาะตอนพร้อมตก (state 1) และไม่ได้กำลังเหวี่ยงอยู่
        if state == 1 and not aimCasting then
            sleep = 0

            if not aimActive then
                if IsControlJustPressed(0, hToggle) then
                    aimActive = true
                    -- อ่านระยะสูงสุดครั้งเดียวตอนเข้าโหมด — ห้ามอ่านซ้ำทุกเฟรม
                    -- เพราะเราเขียนทับ f_1 เองตอนเหวี่ยง ถ้าอ่านซ้ำระยะจะ drift ลงเรื่อยๆ
                    aimMax = M.MaxDistance or 0.0
                    if aimMax <= 0.0 then
                        local fromGame = FISHING_GET_MAX_THROWING_DISTANCE()
                        aimMax = (type(fromGame) == 'number' and fromGame > 0.0)
                            and fromGame or (M.FallbackMax or 30.0)
                    end
                    aimDist = math.min(aimMax, (M.MinDistance or 4.0) + (aimMax - (M.MinDistance or 4.0)) * 0.5)
                    lastProbeAt, lastProbeZ = 0, nil
                end
            else
                -- ห้ามปิด hToggle (คลิกขวา) เด็ดขาด — native ต้องมีการง้างค้างอยู่
                -- คลิกซ้ายถึงจะเหวี่ยงได้ ถ้าปิดไปคือปิดการง้างของเกมด้วย แล้วเหวี่ยงไม่ออก
                -- แทนที่จะปิด เราป้อนค่าค้างให้แทน เกมจะคิดว่ากำลังง้างอยู่ตลอด
                -- ผู้เล่นเลยไม่ต้องกดค้างเอง
                if A.KeepChargeHeld ~= false then
                    SetControlValueNextFrame(0, hToggle, 1.0)
                end

                -- ออกจากโหมดได้ทาง ESC เท่านั้น — คลิกขวาใช้ไม่ได้เพราะเราป้อนค่ามันอยู่
                -- เกมจึงเห็นเป็น "กดค้าง" ตลอด ไม่มีจังหวะ just-pressed ให้จับ
                if IsControlJustPressed(0, hCancel) then
                    aimActive = false
                    goto continue
                end

                -- สกรอลล์ปรับระยะ — ต้องอ่านผ่าน IsDisabledControl* เพราะปุ่มพวกนี้
                -- ถูกปิดไปแล้วข้างบน (ไม่งั้นมันจะไปเปิด weapon wheel)
                local step = A.ScrollStep or 1.5
                if IsDisabledControlJustPressed(0, hUp) then
                    aimDist = math.min(aimMax, aimDist + step)
                elseif IsDisabledControlJustPressed(0, hDown) then
                    aimDist = math.max(M.MinDistance or 4.0, aimDist - step)
                end

                -- ตรึง f_1 ทุกเฟรม — /fishwatch พบว่าเกมล้างค่ากลับเป็น 0 ภายใน ~20-135ms
                -- เขียนครั้งเดียวตอนกดเหวี่ยงจึงไม่ทัน ต้องเขียนค้างไว้ตลอดที่เล็ง
                FISHING_SET_F_(1, aimDist + 0.0)

                local ped = PlayerPedId()
                local c   = GetEntityCoords(ped)
                local dir = camForwardVec()
                local tx, ty = c.x + dir.x * aimDist, c.y + dir.y * aimDist

                -- probe น้ำแบบ throttle (VERTICAL_PROBE วิ่งผ่าน JS export)
                local now = GetGameTimer()
                if now - lastProbeAt >= 60 then
                    lastProbeAt = now
                    lastProbeZ = waterZAt(tx, ty, c.z)
                end

                local wz  = lastProbeZ
                local col = wz and M.OverWater or M.NoWater
                local mz  = wz or c.z

                if wz or M.ShowNoWater then
                    local s = M.Scale or { x = 1.2, y = 1.2, z = 0.6 }
                    DrawMarker(
                        M.Type or 0x07DCE236,
                        tx, ty, mz + 0.05,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        s.x, s.y, s.z,
                        col.r, col.g, col.b, col.a,
                        false, false, 2, false, nil, nil, false
                    )

                    if A.ShowArc then
                        -- ออกจากปลายคันเบ็ดโดยประมาณ (สูงจากเท้าราวหนึ่งช่วงตัว)
                        drawCastArc(c.x, c.y, c.z + 1.0, tx, ty, mz, A)
                    end

                    if A.ShowDistanceText then
                        drawText3D(tx, ty, mz + 1.2, string.format('%.0f ม.', aimDist))
                    end
                end

                -- เหวี่ยง — native ทำเองเมื่อผู้เล่นคลิก เราแค่ตั้งระยะให้ก่อน
                -- เล็งโดนพื้น = ปิดปุ่มไว้เลย เกมจะเหวี่ยงไม่ออกเอง ไม่ต้องไปยกเลิกทีหลัง
                if wz then
                    if IsControlJustPressed(0, hCast) then
                        holdCastDistance(aimDist)
                    end
                else
                    DisableControlAction(0, hCast, true)
                    if IsDisabledControlJustPressed(0, hCast) then
                        exports.pNotify:SendNotification({
                            text = A.BlockedMsg or 'ต้องเล็งลงน้ำก่อนถึงจะเหวี่ยงได้',
                            type = 'error',
                            timeout = 3000,
                        })
                    end
                end
            end
        elseif aimActive then
            aimActive = false
        end

        ::continue::
        Wait(sleep)
    end
end)

-- ── debug ไว้ไล่หาค่าตอนทดสอบในเกม ──────────────────────────────────────────
CreateThread(function()
    if not Config.AimMode or not Config.AimMode.DebugCommands then return end

    -- ดูค่าทั้ง struct — ใช้ตอบว่า "เซ็ต f_1 แล้วเกมเคารพไหม" ได้ทันที
    RegisterCommand('fishdump', function()
        print('[lp_fishing] state=' .. tostring(FISHING_GET_MINIGAME_STATE()) ..
              ' maxThrow(f_1)=' .. tostring(FISHING_GET_MAX_THROWING_DISTANCE()) ..
              ' lineDist(f_2)=' .. tostring(FISHING_GET_LINE_DISTANCE()))
        for i = 0, 27 do
            print(('  f_%d = %s'):format(i, tostring(FISHING_GET_F_(i))))
        end
    end, false)

    -- ตามดู state + f_1 ทุกเฟรม พิมพ์เฉพาะตอนค่าเปลี่ยน
    -- เหวี่ยง 1 ครั้งแล้วดู log จะตอบได้เลยว่า: เข้า state 2 ไหม / f_1 ที่เราเขียนอยู่รอดไหม
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

    -- ยิง transition flag ทีละค่าเพื่อหาว่าเลขไหน = "เหวี่ยง"
    -- ที่รู้แล้ว: 4=ปลาติดเบ็ด 8=ออกจากโหมด 11=เอ็นขาด 12=ได้ปลา 32=เก็บ 64=ปล่อย 128=(state 6)
    RegisterCommand('fishflag', function(_, args)
        local n = tonumber(args[1])
        if not n then
            print('[lp_fishing] ใช้: /fishflag <เลข>')
            return
        end
        print(('[lp_fishing] ก่อนยิง flag %d -> state=%s'):format(n, tostring(FISHING_GET_MINIGAME_STATE())))
        FISHING_SET_TRANSITION_FLAG(n)
        CreateThread(function()
            Wait(400)
            print(('[lp_fishing] หลังยิง flag %d -> state=%s'):format(n, tostring(FISHING_GET_MINIGAME_STATE())))
        end)
    end, false)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    hideStartPrompt()
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

-- ตามสถานะเหยื่อ: ติดเหยื่อ -> โชว์ panel, เลิกตก/ปลดเหยื่อ -> ซ่อน
CreateThread(function()
    local lastLure = nil
    while true do
        Wait(300)
        if currentLure ~= lastLure then
            lastLure = currentLure
            if currentLure then showBaitPanel(currentLure) else hideBaitPanel() end
        end
    end
end)

-- flash ช่องปลาที่เพิ่งได้ (server ยืนยันแล้วว่าเข้ากระเป๋าจริง)
RegisterNetEvent('lp_fishing:fishAwarded', function(itemName)
    pcall(function() exports.lp_rewardpanel:Highlight(itemName) end)
end)
