
-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 

VORPcore = exports.vorp_core:GetCore()
cam, isCameraActive = nil, false
MaxAnimal = 5
DataAnimal = {}
DataAnimalNumber = {
    [1] = false,
    [2] = false,
    [3] = false,
    [4] = false,
    [5] = false
}
DataZone = nil
inZone = false
enteredZone = false

MJDEV_GetEventAnimal = function()

    RegisterNUICallback("CloseMenu", function(data, cb)
        SetNuiFocus(false, false)
    end)

    Citizen.CreateThread(function()
        local enteredZones = {} -- เก็บสถานะของแต่ละโซน
        for k, v in ipairs(Config["Animals"]) do
            local blip = N_0x554d9d53f696d002(1664425300, v.Coords.x, v.Coords.y, v.Coords.z)
            local BlipRadius = BlipAddForRadius(693035517, v.Coords.x, v.Coords.y, v.Coords.z, v.Radius) 
            Citizen.InvokeNative(0x0DF2B55F717DDB10, blip, false)
            Citizen.InvokeNative(0x662D364ABF16DE2F, blip, joaat(v.blips.modifier))
            SetBlipSprite(blip, v.blips.sprite, 1)
            SetBlipScale(blip, v.blips.scale)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, v.blips.name)
            v.BLIPID = blip
            v.BLIPRA = BlipRadius
        end

        while true do
            local sleep = 500
            DataZone = nil
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            -- ตรวจสอบระยะห่างจากแต่ละโซนใน Config["Coords"]
            for k, v in ipairs(Config["Animals"]) do
                local dist = Vdist(playerCoords, v.Coords)
                if dist < v.Radius then
                    -- ปรับปรุงการแสดงผลตามระยะห่าง
                    sleep = 5
                    Citizen.InvokeNative(0x2A32FAA57B937173, -1795314153, v.Coords.x, v.Coords.y, v.Coords.z - 1.0, 0, 0, 0, 0, 0, 0, v.Radius * 2, v.Radius * 2, 0.6, 128, 0, 0, 100, 0, 0, 2, 0, 0, 0, 0)
                    DataZone = v
                    if not isCameraActive then
                        inZone = true
                        if IsControlJustPressed(0, 0x760A9C6F) then
                            -- สร้างกล้องเมื่อผู้เล่นกดปุ่ม
                            OpenMenu()
                        end
                    end
                else
                    inZone = false
                end

                if inZone and not enteredZones[k] then
                    exports['MJ-Textui']:ShowTextUI( "กด <span class = 'INPUT_CONTEXT'>G</span> เพื่อเปิดร้านค้าสัตว์เลี้ยง")
                    enteredZones[k] = true -- ตั้งค่าหลังแสดงข้อความแล้ว
                elseif not inZone and enteredZones[k] then
                    exports['MJ-Textui']:HideTextUI()
                    enteredZones[k] = false -- รีเซ็ตเพื่อแสดงข้อความใหม่เมื่อเข้าเขตอีกครั้ง
                end
            end
            Citizen.Wait(sleep)
        end
    end)

   function BuyAnimal()
        local playerPed = PlayerPedId()
        local model = GetHashKey(DataZone.Animal.Model)

        -- โหลดโมเดลก่อนสร้างสัตว์
        LoadModel(model)

        -- สร้างสัตว์
        local playerCoords = GetEntityCoords(playerPed)
        local spawnCoords = GetRandomPosition(playerCoords, 5) -- ระยะสุ่ม 5 เมตร
        -- สร้าง Animal ที่ตำแหน่งสุ่ม
        local Animal = CreatePed(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false, false, false)

        -- ตั้งค่าพฤติกรรมของสัตว์
        Citizen.InvokeNative(0x283978A15512B2FE, Animal, true) -- ทำให้สัตว์สามารถถูกควบคุมได้
        SetEntityInvincible(Animal, true) -- ทำให้สัตว์เป็นอมตะ
        SetBlockingOfNonTemporaryEvents(Animal, true) -- ป้องกัน AI จากการทำ Event ที่ไม่จำเป็น
        SetPedCanBeTargetted(Animal, false) -- ป้องกันสัตว์จากการถูกล็อกเป้า
        SetEntityVisible(Animal, true)
        SetEntityCanBeDamaged(Animal, false)
        SetEntityInvincible(Animal, true)
        Citizen.InvokeNative(0x6A071245EB0D1882, Animal, true) -- SET_ANIMAL_IS_TAME
        Citizen.InvokeNative(0xAAB3200ED59016BC, Animal, true) -- SET_PED_CONFIG_FLAG (ทำให้สัตว์ไม่หนี)

        SetEntityCanBeDamaged(Animal, false)
        SetEntityInvincible(Animal, true)
        FreezeEntityPosition(Animal, true)
        SetBlockingOfNonTemporaryEvents(Animal, true)

        -- ปล่อยโมเดล
        SetModelAsNoLongerNeeded(model)
        SetEntityAsNoLongerNeeded(Animal)

        -- ให้สัตว์เดินไปหาผู้เล่น
        -- TaskGoToEntity(Animal, playerPed, -1, 5.0, 5.0, 0, 0)
        -- SetPedKeepTask(Animal, true)

        -- เพิ่มสัตว์ลงใน DataAnimal
        local Number = GetNumber(Animal)
        table.insert(DataAnimal, {
            ["entity"] = Animal,
            ["age"] = 0,
            ["needFood"] = 0,
            ["ped"] = DataZone.Animal,
            ["TimeFood"] = DataZone.Animal.TimeWithoutFood,
            ["lastFedTime"] = GetGameTimer(),  -- เก็บเวลาปัจจุบัน (ในมิลลิวินาที)
            ["maxneedFood"] = math.random(DataZone.Animal["NeedFood"][1], DataZone.Animal["NeedFood"][2]),
            ["Number"] = Number,
            ["isDead"] = false,
            ["Name"] = DataZone.Animal.Label,
            ["Food"] = DataZone.Animal.Food
        })
        
        -- อัปเดต UI
        SendNUIMessage({
            action = "UpdateAnimal",
            Model = DataZone.Animal.Model,
            AnimalCount = #DataAnimal,
            AnimalNumber = Number
        })

        -- ให้สัตว์ตามผู้เล่นตลอด
        -- Citizen.CreateThread(function()
        --     while true do
        --         Citizen.Wait(1000) -- ตรวจสอบทุก 1 วินาทีเพื่อไม่ให้โหลดมากเกินไป
        --         local playerCoords = GetEntityCoords(playerPed) -- รับตำแหน่งของผู้เล่น
        --         TaskGoToCoordAnyMeans(Animal, playerCoords.x, playerCoords.y, playerCoords.z, 5.0, 0, 0, 0) -- ให้สัตว์เดินตามผู้เล่น
        --     end
        -- end)
    end
end
