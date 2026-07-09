local voiceMode = 2
local talk = false
local isLoggedIn = false
local hudEnabled = true -- เริ่มต้นเปิด HUD

-- ตัวแปรเก็บค่าสถานะล่าสุด
local thirst, hunger, stress, temp = 0, 0, 0, 0
local lastStatusUpdate = 0

Citizen.CreateThread(function()
    Citizen.Wait(20000)
    isLoggedIn = true
    print("##################################################")
    print("##                                              ##")
    print("##           MJ DEV | Verify Success            ##")
    print("##           Thank You For Purchase             ##")
    print("##           Version : 1.0 (Latest)             ##")
    print("##                                              ##")
    print("##################################################")
    print("###### Discord: https://discord.gg/gHRNMDQKzb ####")
end)

RegisterNetEvent('vorp:SelectedCharacter', function(charId)
    Wait(20000)
    isLoggedIn = true
end)

AddEventHandler('pma-voice:setTalkingMode', function(mode)
    voiceMode = mode
end)

Citizen.CreateThread(function()
    if Config.HidePlayerHealthNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 4, 2)
        Citizen.InvokeNative(0xC116E6DF68DCE667, 5, 2)
    end
    if Config.HidePlayerStaminaNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 0, 2)
        Citizen.InvokeNative(0xC116E6DF68DCE667, 1, 2)
    end
    if Config.HidePlayerDeadEyeNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 2, 2)
        Citizen.InvokeNative(0xC116E6DF68DCE667, 3, 2)
    end
    if Config.HideHorseHealthNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 6, 2)
        Citizen.InvokeNative(0xC116E6DF68DCE667, 7, 2)
    end
    if Config.HideHorseStaminaNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 8, 2)
        Citizen.InvokeNative(0xC116E6DF68DCE667, 9, 2)
    end
    if Config.HideHorseCourageNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 10, 2)
        Citizen.InvokeNative(0xC116E6DF68DCE667, 11, 2)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300)
        if isLoggedIn and hudEnabled then
            local PlayerPed = PlayerPedId()
            local playerid = PlayerId()
            local playerStamina = tonumber(string.format("%.2f", Citizen.InvokeNative(0x0FF421E467373FCF, playerid, Citizen.ResultAsFloat()))-12)
            local talking = Citizen.InvokeNative(0x33EEF97F, playerid)
            local mounted = IsPedOnMount(PlayerPed)
     
            -- กั้นเวลาอัปเดตค่า status จาก exports
            local currentTime = GetGameTimer()
            if currentTime - lastStatusUpdate >= 2000 then
               -- ด้านใน while true loop ก่อน SendNUIMessage()
                thirst = math.floor(exports['MJ-STATUS']:setThirst() / 10) or 0
                hunger = math.floor(exports['MJ-STATUS']:setHunger() / 10) or 0
                stress = math.floor(exports['MJ-STATUS']:setStress()) or 0
                temp = exports['MJ-STATUS']:setTemp() or 0
                lastStatusUpdate = currentTime
            end

            local horsehealth = 0
            local horsestamina = 0
            local horseclean = 0

            if mounted then
                local horse = GetMount(PlayerPed)
                local maxHealth = Citizen.InvokeNative(0x4700A416E8324EF3, horse, Citizen.ResultAsInteger())
                local maxStamina = Citizen.InvokeNative(0xCB42AFE2B613EE55, horse, Citizen.ResultAsFloat())
                local horseCleanliness = Citizen.InvokeNative(0x147149F2E909323C, horse, 16, Citizen.ResultAsInteger())
                horseclean = (horseCleanliness == 0) and 100 or (100 - horseCleanliness)
                horsehealth = tonumber(string.format("%.2f", Citizen.InvokeNative(0x82368787EA73C0F7, horse) / maxHealth * 100))
                horsestamina = tonumber(string.format("%.2f", Citizen.InvokeNative(0x775A1CA7893AA8B5, horse, Citizen.ResultAsFloat()) / maxStamina * 100))
            end  
            
            SendNUIMessage({
                action = "toggleHud",
                state = true,
                isMounted = mounted,
                id = GetPlayerServerId(playerid),
                isPause = IsPauseMenuActive(),
                health = GetEntityHealth(PlayerPed),
                armor = Citizen.InvokeNative(0x2CE311A7, PlayerPed),
                stamina = playerStamina,
                thirst = thirst,
                hunger = hunger,
                stress = stress,
                temp = temp,
                voiceMode = voiceMode,
                talkActive = talking,
                modeTalk = voiceMode,
                onHorse = mounted,
                horsehealth = horsehealth,
                horsestamina = horsestamina,
                horseclean = horseclean,
            })            
        else
            SendNUIMessage({
                action = "toggleHud",
                state = false,
                isMounted = false,
            })
        end
    end
end)

RegisterCommand("togglehud", function()
    hudEnabled = not hudEnabled
    SendNUIMessage({
        action = "toggleHud",
        state = hudEnabled
    })
    TriggerEvent("vorp:TipBottom", "HUD: " .. (hudEnabled and "open" or "close"), 3000)
end)
