script_name = "MJ-Animal"

Citizen.CreateThread(function()
    Citizen.Wait(3000) -- 5 minutes
    if GetCurrentResourceName() ~= script_name then
        while true do
            print("###### Discord: https://discord.gg/gHRNMDQKzb ####")
        end
    end
    print("##################################################")
    print("##                                              ##")
    print("##           MJ DEV | Verify Success            ##")
    print("##           Thank You For Purchase             ##")
    print("##           Version : 1.0 (Latest)             ##")
    print("##                                              ##")
    print("##################################################")
    print("###### Discord: https://discord.gg/gHRNMDQKzb ####")
    TriggerServerEvent(script_name .. ":CL:GetEvent_Animal")
end)

RegisterNetEvent(script_name .. ":SV:GetEvent_Animal")
AddEventHandler(script_name .. ":SV:GetEvent_Animal", function()
    if GetCurrentResourceName() == script_name then
        MJDEV_GetEventAnimal()
        print(Config.Messages.ResourceName .. script_name)
    end
end)

function Loots(Drop)
    local Loots = {}

    for Key, value in pairs(Drop) do
        local MaxPercent = math.random(1, 100)
        if MaxPercent <= Drop[Key]["percent"] then
            table.insert(Loots, {
                name = Key,
                number = math.random(Drop[Key]["number"][1], Drop[Key]["number"][2])
            })
        end
    end

    for key, value in pairs(Loots) do
        TriggerServerEvent(script_name .. ":SV:CheckHealth", Loots[key]["name"], Loots[key]["number"])
    end
end

RegisterNUICallback("BuyAnimal", function(data, cb)
    if #DataAnimal < MaxAnimal then
        checkHasMoney(DataZone.Animal.Price, function(money)
            if money and money >= DataZone.Animal.Price then
                BuyAnimal()
            else
                Config.SendNotification((Config.Messages.InsufficientMoney):format(Math.GroupDigits(DataZone.Animal.Price)), "error")
            end
        end)
    end
end)

RegisterNUICallback("RemoveAnimal", function(data, cb)
    for i = 1, #DataAnimal do
        if DataAnimal[i].Number == tonumber(data.AnimalNumber) then
            DeleteEntity(DataAnimal[i]["entity"])
            table.remove(DataAnimal, i)
            DataAnimalNumber[tonumber(data.AnimalNumber)] = false
            SendNUIMessage({
                action = "UpdateGetAnimal",
                AnimalCount = #DataAnimal,
                AnimalNumber = tonumber(data.AnimalNumber)
            })
            break
        end
    end
end)

RegisterNUICallback("FeedAnimal", function(data, cb)
    local animalNumber = tonumber(data.AnimalNumber)
    if not animalNumber then
        Config.SendNotification(Config.Messages.AnimalNotFound, "error")
        return
    end

    -- Check if the animal is dead
    local animal = nil
    for i = 1, #DataAnimal do
        if DataAnimal[i].Number == animalNumber then
            animal = DataAnimal[i]
            break
        end
    end

    if not animal then
        Config.SendNotification(Config.Messages.AnimalNotFound, "error")
        return
    end

    if animal.isDead then
        Config.SendNotification(Config.Messages.AnimalDead, "error")
        return
    end

    -- Proceed if animal is alive and player has food
    checkHasItem(DataZone.Animal.Food, function(hasItem)
        if hasItem then
            -- TriggerServerEvent(script_name .. ":SV:PRO", DataZone.Animal.Food)
            -- Feed the animal and reset food needs
            animal["needFood"] = 0
            animal["maxneedFood"] = math.random(animal["ped"]["NeedFood"][1], animal["ped"]["NeedFood"][2])

            SendNUIMessage({
                action = "UpdateFeedAnimal",
                AnimalNumber = animalNumber
            })
            Config.SendNotification(Config.Messages.FeedSuccess, "success")
        else
            Config.SendNotification(Config.Messages.NotEnoughFood, "error")
        end
    end)
end)


RegisterNUICallback("GetAnimal", function(data, cb)
    for i = 1, #DataAnimal do
        if DataAnimal[i].Number == tonumber(data.AnimalNumber) then
            if DataAnimal[i].isDead then
                Config.SendNotification(Config.Messages.AnimalDead, "error")
                return
            end
            if DataAnimal[i]["age"] == DataAnimal[i]["ped"]["Time"] then
                DeleteEntity(DataAnimal[i]["entity"])
                Loots(DataAnimal[i]["ped"]["Drop"])
                table.remove(DataAnimal, i)
                DataAnimalNumber[tonumber(data.AnimalNumber)] = false
                SendNUIMessage({
                    action = "UpdateGetAnimal",
                    AnimalCount = #DataAnimal,
                    AnimalNumber = tonumber(data.AnimalNumber)
                })
                break
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)
        local speel = true
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for _, animalData in pairs(DataAnimal) do
            local animal = animalData.entity
            if DoesEntityExist(animal) then
                local animalCoords = GetEntityCoords(animal)
                local distance = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, animalCoords.x,
                    animalCoords.y, animalCoords.z)

                -- แสดงมาร์คเกอร์และชื่อสัตว์เฉพาะถ้าระยะห่างน้อยกว่า 10 เมตร
                if distance < 10.0 then
                    -- แสดงชื่อสัตว์
                    -- สมมติว่า animalData.ID คือหมายเลขของสัตว์เลี้ยง
                    speel = false
                    DrawText3D(animalCoords.x, animalCoords.y, animalCoords.z + 1.5, string.format("Name: ~b~%s Number: ~r~%d ~s~", animalData.Name, animalData.Number))
                end
            end
        end
        if speel then
            Citizen.Wait(500)
        end
    end
end)

function DrawText3D(x, y, z, text)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(x, y, z)
    SetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(7)
    SetTextColor(255, 255, 255, 200)
    SetTextCentre(1)
    DisplayText(CreateVarString(10, "LITERAL_STRING", text), screenX, screenY)
end

Citizen.CreateThread(function()
    while true do
        if DataZone == nil then
            if #DataAnimal > 0 then
                print("Auto Delete")
                DeleteAnimal()
            end
        end
        Citizen.Wait(500)
    end
end)

local Time = Config.DeleteAnimalTime or 61 -- ใช้ค่าจาก Config ถ้าไม่มีใช้ค่าเริ่มต้น 61

DeleteAnimal = function()
    Time = Config.DeleteAnimalTime or 61 -- รีเซ็ตเวลาใหม่ทุกครั้งที่เรียกใช้ฟังก์ชัน
    Citizen.CreateThread(function()
        while Time > 0 and DataZone == nil do
            Time = Time - 1
            if Time > 0 then
                Config.SendNotification(Config.Messages.EnterZone .. Time .. Config.Messages.Seconds, "error")
            end
            Citizen.Wait(1000)
        end
    end)

    while Time >= 0 and DataZone == nil do
        if Time == 0 then
            if DataZone == nil then
                for i, ped in pairs(DataAnimal) do
                    SendNUIMessage({
                        action = "UpdateGetAnimal",
                        AnimalCount = 0,
                        AnimalNumber = ped.Number
                    })
                    DeleteEntity(ped.entity)
                    table.remove(DataAnimal, i)
                    DataAnimalNumber[ped.Number] = false
                    DataAnimal[i] = nil
                end
                Config.SendNotification(Config.Messages.AnimalDeleted, "error")
            end
            break
        end
        Citizen.Wait(1000)
    end
end

function OpenMenu()
    SendNUIMessage({
        action = "OpenMenu",
        AnimalCount = #DataAnimal,
        AnimalPrice = tostring(DataZone.Animal.Price):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""),
        AnimalFeed = DataZone.Animal.Food
    })
    SetNuiFocus(true, true)
end

-- เช็คว่าผู้เล่นมีไอเท็มหรือไม่
function checkHasItem(itemName, cb)
    VORPcore.RpcCall("MJ-Animal:checkHasItem", function(hasItem)
        cb(hasItem) -- ส่งค่าผลลัพธ์กลับไปยัง callback
    end, itemName)
end

-- เช็คว่าผู้เล่นมีเงินจำนวนที่ต้องการหรือไม่
function checkHasMoney(amount, cb)
    VORPcore.RpcCall("MJ-Animal:CheckMoney", function(money)
        cb(money) -- ส่งค่าผลลัพธ์กลับไปยัง callback
    end, amount)
end

function GetNumber(Animal)
    -- Loop through the DataAnimalNumber table
    for i = 1, #DataAnimalNumber do
        -- Check if the current index has been deleted (false)
        if not DataAnimalNumber[i] then
            -- If the number was deleted, mark it as used and return the index
            DataAnimalNumber[i] = true
            return i
        end
    end
    
    -- If no deleted (false) entries are found, assign a new number at the end
    table.insert(DataAnimalNumber, true)
    return #DataAnimalNumber
end

function LoadModel(model)
    local attempts = 0
    while attempts < 100 and not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(1)
        attempts = attempts + 1
    end
    return IsModelValid(model)
end

-- ฟังก์ชั่นสำหรับการสุ่มตำแหน่ง
function GetRandomPosition(center, range)
    local offsetX = math.random(-range, range)
    local offsetY = math.random(-range, range)
    local offsetZ = math.random(1, 2) -- กำหนดค่าความสูงของการสุ่มในแนวตั้ง (หากต้องการให้พิกัด Z เปลี่ยนแปลงได้) 

    return vector3(center.x + offsetX, center.y + offsetY, center.z + offsetZ)
end

-- ฟังก์ชัน MarkAnimalFood สำหรับการทำให้สัตว์ตายเมื่อไม่ได้รับอาหารเกินเวลา
function MarkAnimalFood(animalNumber)
    for i = 1, #DataAnimal do
        local animal = DataAnimal[i]

        -- ตรวจสอบว่า animal ไม่เป็น nil และมี animal.Number ก่อนที่จะทำการดำเนินการ  
        if animal and animal.Number == tonumber(animalNumber) then

            -- ตรวจสอบว่าสัตว์ตายจากโมเดลจริง ๆ
            if DoesEntityExist(animal.entity) and not IsEntityDead(animal.entity) then
                -- SendNUIMessage({
                --     action = "UpdateHungry",
                --     AnimalFeed = 0,
                --     AnimalNumber = tonumber(animalNumber)
                -- })
                -- แจ้งเตือนว่ามีสัตว์ที่ตาย
                Config.SendNotification(string.format(Config.Messages.AnimalDied, animalNumber), "error")
                
                -- ลบโมเดลสัตว์ออกจากเกม
                DeleteEntity(animal.entity)

                -- ลบจาก DataAnimal
                table.remove(DataAnimal, i)
                DataAnimalNumber[tonumber(animalNumber)] = false
                -- อัปเดต UI ว่าสัตว์ถูกลบ
                SendNUIMessage({
                    action = "UpdateGetAnimal",
                    AnimalCount = #DataAnimal,
                    AnimalNumber = tonumber(animalNumber)
                })
                -- ออกจากลูป
                break
            end
        end
    end
end

-- ฟังก์ชัน MarkAnimalDead สำหรับการทำให้สัตว์ตายจากโมเดล
function MarkAnimalDead(animalNumber)
    for i = 1, #DataAnimal do
        local animal = DataAnimal[i]

        -- ตรวจสอบว่า animal ไม่เป็น nil และมี animal.Number ก่อนที่จะทำการดำเนินการ
        if animal and animal.Number == tonumber(animalNumber) then

            -- ตรวจสอบว่าสัตว์ตายจากโมเดลจริง ๆ
            if DoesEntityExist(animal.entity) and IsEntityDead(animal.entity) then
                -- SendNUIMessage({
                --     action = "UpdateHungry",
                --     AnimalFeed = 0,
                --     AnimalNumber = tonumber(animalNumber)
                -- })

                -- แจ้งเตือนว่ามีสัตว์ที่ตาย
                Config.SendNotification(string.format(Config.Messages.AnimalDied, animalNumber), "error")

                -- ลบโมเดลสัตว์ออกจากเกม
                DeleteEntity(animal.entity)

                -- ลบจาก DataAnimal
                table.remove(DataAnimal, i)
                DataAnimalNumber[tonumber(animalNumber)] = false
                -- อัปเดต UI ว่าสัตว์ถูกลบ
                SendNUIMessage({
                    action = "UpdateGetAnimal",
                    AnimalCount = #DataAnimal,
                    AnimalNumber = tonumber(animalNumber)
                })
                -- ออกจากลูป
                break
            end
        end
    end
end

-- ตรวจสอบสถานะของสัตว์ในเธรด
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)

        if #DataAnimal > 0 then
            for i = 1, #DataAnimal do
                local animal = DataAnimal[i]
                
                -- ตรวจสอบว่า animal ไม่เป็น nil ก่อนที่จะดำเนินการ
                if animal and DataAnimalNumber[animal.Number] and animal.entity then
                    local currentTime = GetGameTimer()  -- ใช้เวลาในมิลลิวินาที (ไม่แปลงเป็นวินาที)

                    -- ตรวจสอบว่า `lastFedTime` มีค่าหรือยัง และหากไม่มีให้ตั้งค่าใหม่
                    if not animal.lastFedTime then
                        animal.lastFedTime = currentTime  -- ตั้งค่าตอนสร้างสัตว์
                    end
                    -- print(animal.needFood)
                    -- ตรวจสอบว่าเวลาห่างจาก `lastFedTime` มากกว่าเวลาที่กำหนดหรือยัง
                    if currentTime - animal.lastFedTime >= animal.TimeFood * 1000 then  -- คูณด้วย 1000 เพื่อให้ค่าตรงกัน
                        -- ถ้าสัตว์ไม่ได้รับอาหารเกินเวลาที่กำหนด
                        if animal.needFood >= animal.maxneedFood and animal.needFood ~= 0 and DoesEntityExist(animal.entity) and not IsEntityDead(animal.entity) then
                            -- สัตว์ที่ไม่ได้รับอาหารเกินเวลาจะถูกทำให้ตาย
                            MarkAnimalFood(animal.Number) -- ลบตัวที่ตาย
                        end
                    end

                    -- ตรวจสอบว่าโมเดลของสัตว์ตายแล้วหรือไม่
                    if DoesEntityExist(animal.entity) and IsEntityDead(animal.entity) then
                        -- ลบสัตว์จากเกม
                        MarkAnimalDead(animal.Number) -- ลบตัวที่ตาย
                    end

                    -- ตรวจสอบอายุและสถานะของสัตว์
                    if animal.age == animal.ped.Time then
                        SendNUIMessage({
                            action = "UpdateMaxAge",
                            AnimalNumber = animal.Number
                        })
                    elseif animal.needFood >= animal.maxneedFood then
                        -- หากหิวมากเกินไปให้แจ้งผู้เล่น
                        SendNUIMessage({
                            action = "UpdateHungry",
                            AnimalFeed = animal.Food,
                            AnimalNumber = animal.Number
                        })
                        checkHasItem(animal.Food, function(hasItem)
                            if hasItem then
                                -- เมื่อได้รับอาหารให้รีเซ็ตสถานะและไม่ทำให้ตาย
                                animal.needFood = 0
                                animal.maxneedFood = math.random(animal.ped.NeedFood[1], animal.ped.NeedFood[2])
                                animal.lastFedTime = currentTime  -- อัปเดตเวลาหลังให้อาหาร
                                SendNUIMessage({
                                    action = "UpdateFeedAnimal",
                                    AnimalNumber = animal.Number
                                })
                            end
                        end)
                    elseif animal.age <= animal.ped.Time then
                        if animal.needFood <= animal.maxneedFood then
                            animal.age = animal.age + 1
                            animal.needFood = animal.needFood + 1
                            SendNUIMessage({
                                action = "UpdateStatus",
                                AnimalNumber = animal.Number,
                                AnimalAge = animal.age,
                                AnimalMaxAge = animal.ped.Time
                            })
                        end
                    end
                end
            end
        end
    end
end)


AddEventHandler('onResourceStop', function(resource)
    if resource == script_name then
        for k, v in pairs(DataAnimal) do
            DeleteEntity(v.entity)
        end
        for k, v in pairs(Config.Animals) do
            if v.BLIPID and v.BLIPRA then
                RemoveBlip(v.BLIPID)
                RemoveBlip(v.BLIPRA)
            end
        end
    end
end)