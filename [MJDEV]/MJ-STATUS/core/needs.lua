PlayerStatus = {}
isdead = false 
starve = false
notifstarve = false
notifthirst = false
notifstress = false  
foodtime = Config.HungerTickInterval -- Hunger tick every 90 seconds
thirsttime = Config.ThirstTickInterval -- Thirst tick every 75 seconds
stresstime = Config.StressTickInterval 

RegisterNetEvent('vorp:PlayerForceRespawn', function(status)
    PlayerStatus["Thirst"] = Config.MaxHunger;
    PlayerStatus["Hunger"] = Config.MaxThirst;
    PlayerStatus["Stress"] = Config.MinStress;
end)

RegisterNetEvent('vorp:SelectedCharacter', function(charId)
    isLoggedIn = true
end)

RegisterNetEvent("MJ-STATUS:setStatus")
AddEventHandler("MJ-STATUS:setStatus", function(status)
    if (#status < 2) then
        return
    end
    isLoggedIn = true
    PlayerStatus = json.decode(status)
    print("Hunger: " .. PlayerStatus.Hunger .. ", Thirst: " .. PlayerStatus.Thirst .. ", Stress: " .. PlayerStatus.Stress)
end)

RegisterNetEvent("MJ-STATUS:getStatus")
AddEventHandler("MJ-STATUS:getStatus", function()
    TriggerServerEvent("MJ-STATUS:saveStatus", PlayerStatus)
end)

RegisterNetEvent("vorpmetabolism:changeValue")
AddEventHandler("vorpmetabolism:changeValue", function(a,b)
    if PlayerStatus and next(PlayerStatus) and isLoggedIn then
        if PlayerStatus.Hunger == a and PlayerStatus.Hunger > b then
            PlayerStatus.Hunger = b
        elseif PlayerStatus.Thirst == a and PlayerStatus.Thirst > b then
            PlayerStatus.Thirst = b
        elseif PlayerStatus.Stress == a and PlayerStatus.Stress < b then
            PlayerStatus.Stress = b
        end
    end
end)


CreateThread(function()
    while true do
        Wait(3000)

        if PlayerStatus and next(PlayerStatus) and isLoggedIn then
            local ped = PlayerPedId()

            --  ลดเลือดหากหิว ≤ 10%
            if PlayerStatus.Hunger <= (Config.MaxHunger * 0.01) then
                local newHealth = GetEntityHealth(ped) - 2  -- ลดเลือดทีละ 5
                if newHealth < 1 then
                    ApplyDamageToPed(ped, 500000, false, true, true)
                    SetEntityHealth(ped, 0)
                else
                    SetEntityHealth(ped, newHealth)
                end
            end

            --  ลดเลือดหากกระหาย ≤ 10%
            if PlayerStatus.Thirst <= (Config.MaxThirst * 0.01) then
                local newHealth = GetEntityHealth(ped) - 3  -- ลดเลือดทีละ 5
                if newHealth < 1 then
                    ApplyDamageToPed(ped, 500000, false, true, true)
                    SetEntityHealth(ped, 0)
                else
                    SetEntityHealth(ped, newHealth)
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(10000)
        if PlayerStatus and next(PlayerStatus) and isLoggedIn then
            local playerPed = PlayerPedId()
            local currentHealth = GetEntityHealth(playerPed)

            --  เช็ค & แจ้งเตือนความหิว
            -- print((Config.MaxHunger * 0.02))
            if PlayerStatus.Hunger <= (Config.MaxHunger * 0.02) and not notifstarve then
                -- ย้ายจาก MJ-Showitem (ปิดไปแล้ว) มาใช้ pNotify ระบบแจ้งเตือน text มาตรฐานของโปรเจกต์
                exports.pNotify:SendNotification({ type = 'error', text = '⚠ คุณกำลังหิวมาก! รีบหาอะไรกินด่วน!', timeout = 5000 })
                notifstarve = true
            else
                notifstarve = false
            end

            --  เช็ค & แจ้งเตือนความกระหายน้ำ
            if PlayerStatus.Thirst <= (Config.MaxThirst * 0.02) and not notifthirst then
                exports.pNotify:SendNotification({ type = 'error', text = '⚠ คุณกระหายน้ำมาก! รีบดื่มน้ำด่วน!', timeout = 5000 })
                notifthirst = true
            else
                notifthirst = false
            end

            --  จำกัดค่าหิว/กระหายน้ำไม่ให้เกิน Max
            PlayerStatus.Hunger = math.max(math.min(PlayerStatus.Hunger - 10, Config.MaxHunger), 0)
            PlayerStatus.Thirst = math.max(math.min(PlayerStatus.Thirst - 10, Config.MaxThirst), 0)

            -- จำกัดค่า Hunger/Thirst ไม่ให้เกิน Max
            if PlayerStatus.Hunger > Config.MaxHunger then
                PlayerStatus.Hunger = Config.MaxHunger
            end

            if PlayerStatus.Thirst > Config.MaxThirst then
                PlayerStatus.Thirst = Config.MaxThirst
            end
        end
    end
end)


CreateThread(function()
    while true do
        Wait(1000)  -- ตรวจสอบทุก 1 วินาที
        if PlayerStatus and next(PlayerStatus)and isLoggedIn then
            -- ตรวจสอบสถานะการเคลื่อนไหว
            Wait(Config.StressTickInterval)
            local playerPed = PlayerPedId()
            local isRunning = IsPedRunning(playerPed)
            local isWalking = IsPedWalking(playerPed)

            -- เพิ่มความเครียดตามสถานะการเคลื่อนไหว
            if isRunning then
                -- ถ้าวิ่งเพิ่มความเครียด 20%
                PlayerStatus.Stress = PlayerStatus.Stress + 2
            elseif isWalking then
                -- ถ้าเดินเพิ่มความเครียด 10%
                PlayerStatus.Stress = PlayerStatus.Stress + 1
            end

            -- ตรวจสอบว่าเครียดเกิน 90 หรือไม่
            if PlayerStatus.Stress >= (Config.MaxStress * 0.02) and not isdead then
                exports.pNotify:SendNotification({ type = 'error', text = 'คุณรู้สึกเครียดมากเกินไป!!', timeout = 5000 })
                isdead = true  -- ตั้งค่า dead เป็น true เมื่อเครียดมากเกินไป
            end

            -- ตรวจสอบว่าเครียดถึง 100 หรือไม่
            if PlayerStatus.Stress >= (Config.MaxStress * 0.02) then
                if not notifstress then
                    exports.pNotify:SendNotification({ type = 'error', text = 'คุณเสียชีวิตจากความเครียด!!!', timeout = 5000 })
                    notifstress = true
                    local newHealth = GetEntityHealth(playerPed) - 20
                    if newHealth < 1 then
                        ApplyDamageToPed(playerPed, 500000, false, true, true)
                        SetEntityHealth(playerPed, 0)
                    end
                    SetEntityHealth(playerPed, newHealth)
                    isdead = true  -- ผู้เล่นตายแล้วตั้งค่า dead เป็น true
                end
            else
                -- ถ้าความเครียดลดลงไป, รีเซ็ตสถานะการแจ้งเตือนและการตาย
                PlayerStatus.Stress = PlayerStatus.Stress + 0.1
                notifstress = false
                if isdead then
                    -- รีเซ็ตสถานะการตายเมื่อความเครียดไม่ถึง 100
                    isdead = false
                end
            end
        end
    end
end)

-- Prevent hunger and thirst from exceeding limits
CreateThread(function()
    while true do
        Wait(5000)  -- Wait 5 seconds before checking again
        if PlayerStatus and next(PlayerStatus) and isLoggedIn then
            PlayerStatus.Hunger = math.min(PlayerStatus.Hunger, 100000)
            PlayerStatus.Thirst = math.min(PlayerStatus.Thirst, 100000)
            PlayerStatus.Stress = math.min(PlayerStatus.Stress, 100000)
        end
    end
end)

RegisterNetEvent("MJ-STATUS:useItem")
AddEventHandler("MJ-STATUS:useItem", function(index, hunger, thirst, stress, stamina, eatAnimDict, eatAnimName)
    local playerPed = PlayerPedId()
    local PlayerId = PlayerId()
    -- Retrieve the prop name from the Config based on itemType (bread, apple, etc.)
    local itemConfig = Config.FoodItems[index]
    if not itemConfig then
        print("Invalid item type!")
        return
    end
    
    local prop_name = itemConfig.prop_name  -- Get the prop name Config.FoodItems
    if (Config["FoodItems"][index]["Animation"] == "eat") then
        PlayAnimEat(prop_name)
    else
        PlayAnimDrink(prop_name)
    end

    if (Config["FoodItems"][index]["Effect"] ~= "") then
        ScreenEffect(Config["FoodItems"][index]["Effect"], Config["FoodItems"][index]["EffectDuration"])
    end

    local currentHunger = PlayerStatus.Hunger
    local currentThirst = PlayerStatus.Thirst
    local currentStress = PlayerStatus.Stress
    local currentStamina = GetPlayerStamina(playerPed)

    -- Calculate new values after using the item
    local newHunger = math.min(Config.MaxHunger, currentHunger + hunger)
    local newThirst = math.min(Config.MaxThirst, currentThirst + thirst)
    local newStress = math.max(Config.MinStress, currentStress + stress)
    local newStamina = math.min(Config.MaxStamina, currentStamina + stamina)

    local status = {
        ['Hunger'] = newHunger,
        ['Thirst'] = newThirst,
        ['Stress'] = newStress
    }
    Citizen.InvokeNative(0xFECA17CF3343694B, PlayerId, newStamina)
    TriggerServerEvent("MJ-STATUS:saveStatus", status)
end)

function ScreenEffect(effect, durationMinutes)
    local durationMilliseconds = durationMinutes * 60*1000 -- Convert minutes to milliseconds
    AnimpostfxPlay(effect)
    Citizen.Wait(durationMilliseconds)
    AnimpostfxStop(effect)
end

-- prop ต้องสร้าง "แล้วแปะเข้ามือทันทีในเฟรมเดียวกัน" ไม่งั้นมันจะลอยอยู่กลางอากาศที่พิกัดผู้เล่น
-- ระหว่าง Wait ก่อนแปะ (บั๊กเดิม: CreateObject ที่ z+0.2 → Wait(1000) → ค่อย Attach = prop ลอย 1 วิ)
-- แก้เป็น: เล่นท่าก่อน → รอให้มือยกขึ้น → ค่อยสร้าง+แปะ prop พร้อมกัน + โหลด/ลบโมเดลให้ครบ
local function spawnHeldProp(propName)
    local ped = PlayerPedId()
    local hashItem = GetHashKey(propName)
    if not IsModelValid(hashItem) then return nil end

    RequestModel(hashItem)
    local t0 = GetGameTimer()
    while not HasModelLoaded(hashItem) and GetGameTimer() - t0 < 2000 do Wait(10) end
    if not HasModelLoaded(hashItem) then return nil end

    local coords = GetEntityCoords(ped)
    local prop = CreateObject(hashItem, coords.x, coords.y, coords.z, true, true, false, false, true)
    SetEntityAsMissionEntity(prop, true, true)
    local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_R_Finger12")
    AttachEntityToEntity(prop, ped, boneIndex, 0.02, 0.028, 0.001, 15.0, 175.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(hashItem)
    return prop
end

local function removeHeldProp(prop)
    if prop and DoesEntityExist(prop) then
        DeleteEntity(prop)
    end
end

function PlayAnimDrink(propName)
    local ped = PlayerPedId()
    local dict = "amb_rest_drunk@world_human_drinking@male_a@idle_a"
    local anim = "idle_a"

    RequestAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        Wait(50)
    end

    TaskPlayAnim(ped, dict, anim, 1.0, 8.0, 5000, 31, 0.0, false, false, false)
    Wait(800) -- ให้มือยกขึ้นก่อน ค่อยโผล่ prop (ไม่สร้างค้างไว้ให้ลอย)

    local prop = spawnHeldProp(propName)
    Wait(5200)

    removeHeldProp(prop)
    ClearPedSecondaryTask(ped)
end

function PlayAnimEat(propName)
    local ped = PlayerPedId()
    local dict = "mech_inventory@eating@multi_bite@wedge_a4-2_b0-75_w8_h9-4_eat_cheese"
    local anim = "quick_right_hand"

    RequestAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        Wait(50)
    end

    TaskPlayAnim(ped, dict, anim, 1.0, 8.0, 5000, 31, 0.0, false, false, false)
    Wait(800) -- ให้มือยกขึ้นก่อน ค่อยโผล่ prop (ไม่สร้างค้างไว้ให้ลอย)

    local prop = spawnHeldProp(propName)
    Wait(5200)

    removeHeldProp(prop)
    ClearPedSecondaryTask(ped)
end

-- Play an animation
function TaskAnim(animDict, animName, flags, duration)
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(0)
        end
    end

    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, 3.0, duration, flags, 0, 0, 0, 0)
    RemoveAnimDict(animDict)
end

exports('setThirst', function() return PlayerStatus.Thirst end)
exports('setHunger', function() return PlayerStatus.Hunger end)
exports('setStress', function() return PlayerStatus.Stress end) 
exports('setTemp', function() return temperature end)

------------------------------------------------
-- Export เพิ่มความเหนื่อยล้า
------------------------------------------------
exports("AddStress", function(amount)
    PlayerStatus.Stress = math.min(Config.MaxStress, PlayerStatus.Stress + amount)
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        AnimpostfxStop("PlayerHealthPoor")
        AnimpostfxStop("MissionChoice")
        AnimpostfxStop("MP_MoonshinerDisorient")
        if PlayerStatus and not next(PlayerStatus) then
            Wait(2000)
            TriggerServerEvent("MJ-STATUS:loadStatus")
        end
    end
end)
