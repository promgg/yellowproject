
temperature = 0
temp = 0
tempadd = 0
clean = 0
voiceMode = 0
isLoggedIn = false

Citizen.CreateThread(function()

    if Config.HidePlayerHealthNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 4, 2) -- ICON_HEALTH / HIDE
        Citizen.InvokeNative(0xC116E6DF68DCE667, 5, 2) -- ICON_HEALTH_CORE / HIDE
    end

    if Config.HidePlayerStaminaNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 0, 2) -- ICON_STAMINA / HIDE
        Citizen.InvokeNative(0xC116E6DF68DCE667, 1, 2) -- ICON_STAMINA_CORE / HIDE
    end

    if Config.HidePlayerDeadEyeNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 2, 2) -- ICON_DEADEYE / HIDE
        Citizen.InvokeNative(0xC116E6DF68DCE667, 3, 2) -- ICON_DEADEYE_CORE / HIDE
    end

    if Config.HideHorseHealthNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 6, 2) -- ICON_HORSE_HEALTH / HIDE
        Citizen.InvokeNative(0xC116E6DF68DCE667, 7, 2) -- ICON_HORSE_HEALTH_CORE / HIDE
    end

    if Config.HideHorseStaminaNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 8, 2) -- ICON_HORSE_STAMINA / HIDE
        Citizen.InvokeNative(0xC116E6DF68DCE667, 9, 2) -- ICON_HORSE_STAMINA_CORE / HIDE
    end

    if Config.HideHorseCourageNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 10, 2) -- ICON_HORSE_COURAGE / HIDE
        Citizen.InvokeNative(0xC116E6DF68DCE667, 11, 2) -- ICON_HORSE_COURAGE_CORE / HIDE
    end

end)

------------------------------------------------
-- functions
------------------------------------------------
local function GetShakeIntensity(stresslevel)
    local retval = 0.05
    for _, v in pairs(Config.Intensity['shake']) do
        if stresslevel >= v.min and stresslevel <= v.max then
            retval = v.intensity
            break
        end
    end
    return retval
end

local function GetEffectInterval(stresslevel)
    local retval = 60000
    for _, v in pairs(Config.EffectInterval) do
        if stresslevel >= v.min and stresslevel <= v.max then
            retval = v.timeout
            break
        end
    end
    return retval
end


AddEventHandler('pma-voice:setTalkingMode', function(newTalkingRange)
    voiceMode = newTalkingRange
end)

------------------------------------------------
-- player hud
------------------------------------------------
CreateThread(function()
    while true do
        Wait(1000)
        if isLoggedIn and PlayerStatus and next(PlayerStatus) then
            local show = true
            local player = PlayerPedId()
            local playerid = PlayerId()
            local coords = GetEntityCoords(player)
            local stamina = tonumber(string.format("%.2f", Citizen.InvokeNative(0x0FF421E467373FCF, playerid, Citizen.ResultAsFloat())))
            local armor = Citizen.InvokeNative(0x2CE311A7, player)
            local mounted = IsPedOnMount(player)
            local thirst = exports['MJ-STATUS']:setThirst() / 1000
            local hunger = exports['MJ-STATUS']:setHunger() / 1000
            local stress = exports['MJ-STATUS']:setStress() / 1000  
            local talking = Citizen.InvokeNative(0x33EEF97F, playerid)

            if IsPauseMenuActive() then
                show = false
            end

            -- horse health, stamina & cleanliness
            local horsehealth = 0
            local horsestamina = 0
            local horseclean = 0

            if mounted then
                local horse = GetMount(player)
                local maxHealth = Citizen.InvokeNative(0x4700A416E8324EF3, horse, Citizen.ResultAsInteger())
                local maxStamina = Citizen.InvokeNative(0xCB42AFE2B613EE55, horse, Citizen.ResultAsFloat())
                local horseCleanliness = Citizen.InvokeNative(0x147149F2E909323C, horse, 16, Citizen.ResultAsInteger())
                if horseCleanliness == 0 then
                    horseclean = 100
                else
                    horseclean = 100 - horseCleanliness
                end
                horsehealth = tonumber(string.format("%.2f", Citizen.InvokeNative(0x82368787EA73C0F7, horse) / maxHealth * 100))
                horsestamina = tonumber(string.format("%.2f", Citizen.InvokeNative(0x775A1CA7893AA8B5, horse, Citizen.ResultAsFloat()) / maxStamina * 100))
            end  
            if Config.ShowUI then
                SendNUIMessage({
                    action = 'hudtick',
                    show = show,
                    health = GetEntityHealth(player) / 6, -- health in red dead max health is 600 so dividing by 6 makes it 100 here
                    stamina = stamina,
                    armor = armor,
                    thirst = thirst,
                    hunger = hunger,
                    stress = stress,
                    talking = talking,
                    temp = temperature,
                    onHorse = mounted,
                    horsehealth = horsehealth,
                    horsestamina = horsestamina,
                    horseclean = horseclean,
                    voice = voiceMode,
                })
            else
                SendNUIMessage({
                    action = 'hudtick',
                    onHorse = mounted,
                    horsehealth = horsehealth,
                    horsestamina = horsestamina,
                    horseclean = horseclean,
                    voice = voiceMode,
                })
            end
        else
            SendNUIMessage({
                action = 'hudtick',
                show = false
            })
        end
    end
end)


CreateThread(function()
    while true do
        Wait(1000)

        local player = PlayerPedId()
        local coords = GetEntityCoords(player)

        -- wearing
        local hat = Citizen.InvokeNative(0xFB4891BD7578CDC1, player, 0x9925C067) -- hat
        local shirt = Citizen.InvokeNative(0xFB4891BD7578CDC1, player, 0x2026C46D) -- shirt
        local pants = Citizen.InvokeNative(0xFB4891BD7578CDC1, player, 0x1D4C528A) -- pants
        local boots = Citizen.InvokeNative(0xFB4891BD7578CDC1, player, 0x777EC6EF) -- boots
        local coat = Citizen.InvokeNative(0xFB4891BD7578CDC1, player, 0xE06D30CE) -- coat
        local opencoat = Citizen.InvokeNative(0xFB4891BD7578CDC1, player, 0x662AC34) -- open-coat
        local gloves = Citizen.InvokeNative(0xFB4891BD7578CDC1, player, 0xEABE0032) -- gloves
        local vest = Citizen.InvokeNative(0xFB4891BD7578CDC1, player, 0x485EE834) -- vest
        local poncho = Citizen.InvokeNative(0xFB4891BD7578CDC1, player, 0xAF14310B) -- poncho
        local skirts = Citizen.InvokeNative(0xFB4891BD7578CDC1, player, 0xA0E3AB7F) -- skirts
        local chaps = Citizen.InvokeNative(0xFB4891BD7578CDC1, player, 0x3107499B) -- chaps

        -- get temp add
        if hat == 1 then
            what = Config.WearingHat
        else
            what = 0
        end
        if shirt == 1 then
            wshirt = Config.WearingShirt
        else
            wshirt = 0
        end
        if pants == 1 then
            wpants = Config.WearingPants
        else
            wpants = 0
        end
        if boots == 1 then
            wboots = Config.WearingBoots
        else
            wboots = 0
        end
        if coat == 1 then
            wcoat = Config.WearingCoat
        else
            wcoat = 0
        end
        if opencoat == 1 then
            wopencoat = Config.WearingOpenCoat
        else
            wopencoat = 0
        end
        if gloves == 1 then
            wgloves = Config.WearingGloves
        else
            wgloves = 0
        end
        if vest == 1 then
            wvest = Config.WearingVest
        else
            wvest = 0
        end
        if poncho == 1 then
            wponcho = Config.WearingPoncho
        else
            wponcho = 0
        end
        if skirts == 1 then
            wskirts = Config.WearingSkirt
        else
            wskirts = 0
        end
        if chaps == 1 then
            wchaps = Config.WearingChaps
        else
            wchaps = 0
        end

        local tempadd = (what + wshirt + wpants + wboots + wcoat + wopencoat + wgloves + wvest + wponcho + wskirts +  wchaps)

        if Config.TempFormat == 'celsius' then
            temperature = math.floor(GetTemperatureAtCoords(coords)) + tempadd .. "°C" -- Uncomment for celcius
            temp = math.floor(GetTemperatureAtCoords(coords)) + tempadd
        elseif Config.TempFormat == 'fahrenheit' then
            temperature = math.floor(GetTemperatureAtCoords(coords) * 9 / 5 + 32) + tempadd .. "°F" -- Comment out for celcius
            temp = math.floor(GetTemperatureAtCoords(coords) * 9 / 5 + 32) + tempadd 
        end
    end
end)

------------------------------------------------
-- ระบบ Health / Cleanliness / Stress
------------------------------------------------

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        if isLoggedIn and Config.DoHealthDamage and temp ~= nil and temp > 0 then
            local player = PlayerPedId()
            local health = GetEntityHealth(player)

            -- ดึงค่าความสะอาดของตัวละคร
            local cleanliness = Citizen.InvokeNative(0xCAAF2BCC, player) or 100 

            -- ฟังก์ชันใช้ลดพลังชีวิต
            local function ApplyHealthDamage()
                if Config.DoHealthDamageFx then
                    Citizen.InvokeNative(0x4102732DF6B4005F, "MP_Downed", 0, true)
                end
                if Config.DoHealthPainSound then
                    PlayPain(player, 9, 1, true, true)
                end
                SetEntityHealth(player, math.max(0, health - Config.RemoveHealth))
            end

            -- ตรวจสอบเงื่อนไขที่ต้องลดพลังชีวิต
            if temp < Config.MinTemp or temp > Config.MaxTemp or cleanliness < Config.MinCleanliness then
                ApplyHealthDamage()
            elseif Citizen.InvokeNative(0x4A123E85D7C4CA0B, "MP_Downed") and Config.DoHealthDamageFx then
                Citizen.InvokeNative(0xB4FD7446BAB2F394, "MP_Downed")
            end
            -- print(temp, Config.MinTemp)
            if temp < Config.MinTemp then
                ScreenEffectfxPlay()
            elseif temp > Config.MaxTemp then
                ScreenEffectfxPlay2()
            end

            -- ลดค่าความเหนื่อยล้าลงเรื่อย ๆ เมื่อเวลาผ่านไป
            -- if PlayerStatus.Stress > 0 then
            --     PlayerStatus.Stress = math.max(0, PlayerStatus.Stress + Config.StressReductionRate)
            -- end
        end
    end
end)

ScreenEffectfxPlay = function()
    AnimpostfxStop("MP_MoonshinerDisorient")
    AnimpostfxPlay("PlayerHealthPoor", 0, true) -- เอฟเฟกต์เบลอ
    AnimpostfxPlay("MissionChoice", 0, true)
    SetPedMoveRateOverride(PlayerPedId(), 0.5) -- เดินช้าลง
    Citizen.Wait(10000) -- 10 วินาที
    AnimpostfxStop("PlayerHealthPoor")
    AnimpostfxStop("MissionChoice")
    SetPedMoveRateOverride(PlayerPedId(), 1.0) -- กลับมาเร็วปกติ
end

ScreenEffectfxPlay2 = function()
    AnimpostfxStop("MissionChoice")
    AnimpostfxPlay("PlayerHealthPoor", 0, true) -- เอฟเฟกต์เบลอ
    AnimpostfxPlay("MP_MoonshinerDisorient", 0, true)
    SetPedMoveRateOverride(PlayerPedId(), 0.5) -- เดินช้าลง
    Citizen.Wait(10000) -- 10 วินาที
    AnimpostfxStop("PlayerHealthPoor")
    AnimpostfxStop("MP_MoonshinerDisorient")
    SetPedMoveRateOverride(PlayerPedId(), 1.0) -- กลับมาเร็วปกติ
end

------------------------------------------------
-- stress screen effects
------------------------------------------------
-- flag ที่เธรดวาดจอแดงอ่าน — เปิดเมื่อความเครียดถึง Config.StressEffectThreshold (90)
local stressRedActive = false

-- เธรดวาด "จอแดง" — DrawRect ต้องเรียกทุกเฟรม (วาด overlay สีแดงเต็มจอ อัลฟาเต้นเป็นจังหวะ)
-- ใช้ DrawRect แทน AnimpostfxPlay เพราะไม่มี postfx สีแดงชัวร์ๆ ใน RDR3 (มีแต่เบลอ/จอดำ)
CreateThread(function()
    while true do
        if stressRedActive then
            -- อัลฟาเต้น ~50..110 (จาก 255) ให้รู้สึกเหมือนเลือดสูบ ไม่ใช่แดงตายตัว
            local pulse = 80 + math.floor(30 * math.sin(GetGameTimer() / 220.0))
            DrawRect(0.5, 0.5, 1.0, 1.0, 170, 20, 20, pulse)
            Wait(0)
        else
            Wait(200)
        end
    end
end)

-- เธรดตรวจความเครียด: ถึง threshold (90) -> เปิดจอแดง + สั่นจอเป็นระยะ, ต่ำกว่านั้น -> ดับ
CreateThread(function()
    while true do
        local sleep = 1000
        if isLoggedIn and Config.DoHealthEffects then
            local stress = exports['MJ-STATUS']:MJ_stress()

            if stress >= (Config.StressEffectThreshold or 90) then
                stressRedActive = true
                ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', GetShakeIntensity(stress))
                sleep = 2000   -- สั่นซ้ำทุก 2 วิระหว่างที่ยังเครียดหนัก (จอแดงติดต่อเนื่องอยู่แล้ว)
            else
                stressRedActive = false
                sleep = 1000
            end
        else
            stressRedActive = false
        end

        Wait(sleep)
    end
end)
