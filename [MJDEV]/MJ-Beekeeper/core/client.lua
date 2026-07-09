local bees_cloud_group = "core"  -- ชื่อกลุ่มที่ใช้ในการแสดงผลฝูงผึ้ง
local bees_cloud_name = "ent_amb_insect_bee_swarm"
local placed_hives = {}  -- เก็บรังที่วางไว้สำหรับแต่ละผู้เล่น
local CreatedSwarms = {}  -- เก็บฝูงผึ้งที่สร้างขึ้น
local active_timers = {}  -- เก็บเวลาในการคูลดาวน์สำหรับรัง
local blips = {} -- Clear the table
local max_hives_per_player = Config.ApiBeeHives.MaxHives  -- จำนวนรังที่ผู้เล่นสามารถวางได้

-- ตรวจสอบว่าผู้เล่นอยู่ในพื้นที่ที่กำหนดหรือไม่
function IsWithinAllowedZone(coords)
    for _, v in pairs(Config.BeekeeperPoint) do
        local distance = Vdist(coords.x, coords.y, coords.z, v.coords.x, v.coords.y, v.coords.z)
        if distance <= v.radius then
            return true
        end
    end
    return false
end

-- วางรังผึ้ง
RegisterNetEvent('MJ-Beekeeper:PlaceHive')
AddEventHandler('MJ-Beekeeper:PlaceHive', function(item)
    local playerPed = PlayerPedId()
    local playerId = GetPlayerServerId(PlayerId())

    if not placed_hives[playerId] then
        placed_hives[playerId] = {}
    end

    if #placed_hives[playerId] >= max_hives_per_player then
        TriggerEvent("vorp:TipBottom", "You have placed the full number of beehives.", 4000)
        return
    end
    
    local coords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)  -- หามุมที่ผู้เล่นหันหน้า

    -- คำนวณทิศทางที่ผู้เล่นหัน
    local forwardVector = GetEntityForwardVector(playerPed)
    
    -- คำนวณตำแหน่งด้านหน้าของผู้เล่น
    local newCoords = vector3(coords.x + forwardVector.x * 2, coords.y + forwardVector.y * 2, coords.z)
    
    if not IsWithinAllowedZone(coords) then
        TriggerEvent("vorp:TipBottom", "You cannot place beehives in this area.", 4000)
        return
    end

    -- โหลด Animation
    FreezeEntityPosition(playerPed, true)
    RequestAnimDict("amb_work@world_human_farmer_weeding@male_a@idle_a")
    while not HasAnimDictLoaded("amb_work@world_human_farmer_weeding@male_a@idle_a") do
        Wait(100)
    end
    TaskPlayAnim(playerPed, "amb_work@world_human_farmer_weeding@male_a@idle_a", "idle_a", 8.0, -8.0, 8000, 1, 0, true, 0, false, 0, false)
    exports.redemrp_progressbars:DisplayProgressBar(4000, "Placing Beehive...")
    FreezeEntityPosition(playerPed, false)
    ClearPedTasksImmediately(playerPed) 

    -- โหลด Model
    local hiveModel = GetHashKey(item.model)
    RequestModel(hiveModel)
    while not HasModelLoaded(hiveModel) do
        Wait(100)
    end
    local hive = CreateObject(hiveModel, newCoords.x, newCoords.y, newCoords.z, true, true, false)
    SetEntityHeading(hive, playerHeading)  -- ตั้งทิศทางให้รังผึ้งหันตามผู้เล่น
    SetEntityAsMissionEntity(hive, true)
    PlaceObjectOnGroundProperly(hive)
    FreezeEntityPosition(hive, true)
    TriggerServerEvent('MJ-Beekeeper:subItem', item.name)
    -- สร้าง Particle Effect (ฝูงผึ้งบินรอบรัง)
    if not CreatedSwarms[hive] then
        Citizen.InvokeNative(0xA10DB07FC234DD12, bees_cloud_group)
        CreatedSwarms[hive] = Citizen.InvokeNative(0xBA32867E86125D3A, bees_cloud_name, newCoords.x, newCoords.y, newCoords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
    end
    
    table.insert(placed_hives[playerId], hive)
    active_timers[hive] = Config.ApiBeeHives.CooldownTime

    Citizen.CreateThread(function()
        if active_timers[hive] > 0 then
            while true do
                if active_timers[hive] then
                    active_timers[hive] = active_timers[hive] - 1
                end
                Citizen.Wait(1000)
            end
        end
    end)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(5)
            local playerPed = PlayerPedId()  -- ได้ ID ของผู้เล่น
            local playerCoords = GetEntityCoords(playerPed)  -- หาพิกัดของผู้เล่น
            
            for _, hive in pairs(placed_hives[playerId]) do
                if active_timers[hive] > 0 then
                    -- หาค่าพิกัดของรังผึ้ง
                    local hiveCoords = GetEntityCoords(hive)
    
                    -- คำนวณระยะห่างระหว่างผู้เล่นกับรังผึ้ง
                    local distance = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, hiveCoords.x, hiveCoords.y, hiveCoords.z)
    
                    -- ตรวจสอบว่าผู้เล่นอยู่ในระยะ 10 เมตร
                    if distance <= 10.0 then
                        -- คำนวณคูลดาวน์ที่เหลือ
                        local remainingCooldown = active_timers[hive]
                        -- แสดงข้อความ 3D
                        DrawText3D(hiveCoords.x, hiveCoords.y, hiveCoords.z, "Cooldown: " .. tostring(remainingCooldown) .. " Second - To Harvesting.", 2)
                    else
                        Citizen.Wait(500)
                    end
                end
            end
        end
    end)

    --- bee-sting effect
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.CheckTime)
            if IsEntityAtCoord(PlayerPedId(), newCoords, 3.0, 3.0, 3.0, 0, 1, 0) then
                local ped = PlayerPedId()
                local health = GetEntityHealth(ped)
                if health > 0 then 
                    SetEntityHealth(ped, health - Config.BeeSting)
                    PlayPain(ped, 9, 1, true, true)
                end
            end
        end
    end)
end)

-- เก็บน้ำผึ้งจากรัง
RegisterNetEvent('MJ-Beekeeper:CollectHive')
AddEventHandler('MJ-Beekeeper:CollectHive', function()
    local playerPed = PlayerPedId()
    local playerId = GetPlayerServerId(PlayerId())
    local coords = GetEntityCoords(playerPed)

    for hive, timer in pairs(active_timers) do
        if timer <= 0 and #(coords - GetEntityCoords(hive)) < 3.0 then
            FreezeEntityPosition(playerPed, true)
            CrouchAnim()
            FreezeEntityPosition(playerPed, false)
            ClearPedTasksImmediately(playerPed) 
            TriggerServerEvent("MJ-Beekeeper:GiveHoney")
            -- ลบรังผึ้งจากโลก
            if placed_hives[playerId] then
                for i, beehive in ipairs(placed_hives[playerId]) do
                    if beehive == hive then
                        -- ลบรังผึ้ง
                        DeleteObject(beehive)
                        -- ลบ particle effect (ฝูงผึ้ง)
                        if CreatedSwarms[beehive] then
                            StopParticleFxLooped(CreatedSwarms[beehive], true)
                            CreatedSwarms[beehive] = nil
                        end
                        -- ลบรังผึ้งออกจากรายการที่ผู้เล่นวาง
                        table.remove(placed_hives[playerId], i)
                        break
                    end
                end
            end

            -- รีเซ็ตเวลาและการทำงานที่เกี่ยวข้อง
            active_timers[hive] = nil
            return
        end
    end
    TriggerEvent("vorp:TipBottom", "There are no nearby beehives that can be harvested.!", 4000)
end)

Citizen.CreateThread(function()
    local wasInZone = false  -- ติดตามสถานะของผู้เล่นก่อนหน้านี้
    while true do
        Wait(1000) -- ตรวจสอบทุก 1 วินาที

        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        if IsWithinAllowedZone(coords) then
            if not wasInZone then
                TriggerEvent("vorp:TipBottom", "You have entered the beekeeping area.", 4000)
                wasInZone = true
            end
        else
            if wasInZone then
                TriggerEvent("vorp:TipBottom", "You have left the beekeeping area.", 4000)
                wasInZone = false
            end
        end
    end
end)

Citizen.CreateThread(function()
    local wasInZone = false  
    local timeOutsideZone = 0  -- ตัวแปรเก็บเวลาที่อยู่นอกโซน
    local allowedTime = Config.AllowedTimeOutside or 30  -- กำหนดค่าเริ่มต้น 30 วินาที หากไม่มีใน Config

    while true do
        Wait(1000) -- ตรวจสอบทุก 1 วินาที

        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local playerId = GetPlayerServerId(PlayerId())

        if placed_hives[playerId] then
            if IsWithinAllowedZone(coords) then
                if not wasInZone then
                    TriggerEvent("vorp:TipBottom", "You have entered the beekeeping area.", 4000)
                    wasInZone = true
                    timeOutsideZone = 0  -- รีเซ็ตเวลาเมื่อกลับเข้าโซน
                end
            else
                if wasInZone then
                    TriggerEvent("vorp:TipBottom", "You have left the beekeeping area.", 4000)
                    wasInZone = false
                end
                
                -- เพิ่มเวลาที่อยู่นอกโซน
                timeOutsideZone = timeOutsideZone + 1

                -- ถ้าอยู่นอกโซนนานเกินกำหนด ให้รีเซ็ตค่าทั้งหมด
                if timeOutsideZone >= allowedTime then
                    TriggerEvent("vorp:TipBottom", "You have been outside the beekeeping area for too long! Your beehives have been reset.", 5000)
                    ResetPlayerBeehives()
                    TriggerServerEvent('MJ-Beekeeper:Delete')
                    timeOutsideZone = 0 -- รีเซ็ตตัวจับเวลา
                end
            end
        end
    end
end)

function ResetPlayerBeehives()
    local playerId = GetPlayerServerId(PlayerId())
    if placed_hives[playerId] then
        for _, beehive in ipairs(placed_hives[playerId]) do
            DeleteObject(beehive)

            -- ลบ particle effect ของผึ้งที่อยู่รอบรัง
            if CreatedSwarms[beehive] then
                StopParticleFxLooped(CreatedSwarms[beehive], true)
                CreatedSwarms[beehive] = nil
            end
            active_timers[beehive] = nil
        end
        -- รีเซ็ตค่าตัวแปรทั้งหมดของผู้เล่น
        placed_hives[playerId] = {}
    end
end

-- จับ SPACE เพื่อเก็บน้ำผึ้ง
Citizen.CreateThread(function()
    while true do
        Wait(5)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        for hive, timer in pairs(active_timers) do
            if timer <= 0 and #(coords - GetEntityCoords(hive)) < 3.0 then
                -- หาค่าพิกัดของรังผึ้ง
                local hiveCoords = GetEntityCoords(hive)
                
                -- แสดงข้อความ 3D
                DrawText3D(hiveCoords.x, hiveCoords.y, hiveCoords.z + 1.0, "Press SPACE to collect honey", 1)
                
                -- ตรวจสอบการกด SPACE เพื่อเก็บน้ำผึ้ง
                if IsControlJustPressed(0, Config.Controls.EnterKey) then  --  คือรหัสของปุ่ม SPACE
                    -- เก็บน้ำผึ้ง (ลบรังผึ้ง)
                    TriggerEvent('MJ-Beekeeper:CollectHive', hive)
                end
            end
        end
    end
end)

-- แสดง Blips (ถ้าจำเป็น)
Citizen.CreateThread(function()
    for i = 1, #Config.BeekeeperPoint do
        local point = Config.BeekeeperPoint[i]
        
        if point.blips.enabled then
            local coord = point.coords  -- Coordinates for the blip
            local blip_modifier_hash = GetHashKey(point.blips.color)  -- Get the hash of the color for the blip

            -- Create the Blip at the defined coordinates
            local B = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, coord.x, coord.y, coord.z)

            -- Create the radius for the blip
            local R = Citizen.InvokeNative(0x45F13B7E0A15C880, 693035517, coord.x, coord.y, coord.z, point.radius or 100.0)

            -- Set Blip Sprite (Icon)
            SetBlipSprite(B, point.blips.sprite)

            -- Set Blip Scale (Size)
            SetBlipScale(B, point.blips.scale)

            -- Apply color if it's valid
            if blip_modifier_hash ~= 0 then
                Citizen.InvokeNative(0x662D364ABF16DE2F, B, blip_modifier_hash)
            end

            -- Set the blip's text label
            Citizen.InvokeNative(0x9CB1A1623062F402, B, point.blips.text)

            -- Store the created blip and its radius in a table (Optional)
            table.insert(blips, {
                blip = B,
                radius = R
            })
        end
    end
end)


-- Optional function to remove all blips when they are no longer needed
function RemoveAllBlips()
    for _, data in ipairs(blips) do
        RemoveBlip(data.blip) -- Remove the blip
        RemoveBlip(data.radius) -- Remove the radius blip
    end
    blips = {} -- Clear the table
end

------ Animation
function CrouchAnim()
    local PlayAnimStatus = true
    local prop_name = "mp005_s_posse_col_net01x"
    local MyPed = PlayerPedId()
    local MyCoords = GetEntityCoords(MyPed)
    -- Create the prop
    local BugNet = CreateObject(GetHashKey(prop_name), MyCoords.x, MyCoords.y, MyCoords.z, true, true, true)
    SetEntityAsMissionEntity(BugNet, true, true)
    AttachEntityToEntity(BugNet, MyPed, GetEntityBoneIndexByName(MyPed, "PH_L_Hand"),0.0, 0.0, -0.45, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    -- Request and play animation
    RequestAnimDict("mini_games@fishing@shore")
    while not HasAnimDictLoaded("mini_games@fishing@shore") do
        Citizen.Wait(100)
    end
    TaskPlayAnim(MyPed, "mini_games@fishing@shore", "cast",1.0, 8.0, -1, 31, 0, false, false, false)
    -- Wait the Catch Time
    exports.redemrp_progressbars:DisplayProgressBar(5000, "Collecting Honey...")
    ClearPedTasks(MyPed)
    -- Cleanup BugNet when animation stops
    while PlayAnimStatus do
        Citizen.Wait(100)
        if not IsEntityPlayingAnim(MyPed, "mini_games@fishing@shore", "cast", 3) then
            DeleteEntity(BugNet) -- Clean up the prop
            PlayAnimStatus = false
        end
    end
end

-- ลบรังเก่าจากโลก
RegisterNetEvent('MJ-Beekeeper:RemoveOldBox')
AddEventHandler('MJ-Beekeeper:RemoveOldBox', function()
    -- ลบรังผึ้งทั้งหมดจากผู้เล่น
    for playerId, hives in pairs(placed_hives) do
        for _, beehive in ipairs(hives) do
            DeleteObject(beehive)
        end
    end
    
    -- หยุด particle effect ของฝูงผึ้ง
    for _, BeesFX in pairs(CreatedSwarms) do
        StopParticleFxLooped(BeesFX, true)
    end
end)

-- ฟังก์ชันการวาดข้อความ 3D ที่สามารถเลือกฟอนต์ได้
function DrawText3D(x, y, z, text, type)
    local _type = type
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoord())
    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    
    if onScreen then
        -- เลือกสีของข้อความตามประเภท
        if _type == 0 then
            SetTextColor(163, 138, 184, 215)
        elseif _type == 1 then
            SetTextColor(117, 14, 14, 215)
        elseif _type == 2 then
            SetTextColor(255, 255, 255, 215)
        end

        -- ตั้งขนาดข้อความ
        SetTextScale(0.30, 0.30)
        SetTextFontForCurrentCommand(1)  -- ใช้ฟอนต์ที่โหลด
        SetTextCentre(1)
        DisplayText(str, _x, _y - 0.13)

        -- สร้างพื้นหลังเพื่อให้ข้อความโดดเด่น
        local factor = (string.len(text)) / 225
        DrawSprite("feeds", "hud_menu_4a", _x, _y - 0.12, 0.015 + factor, 0.03, 0.1, 0, 0, 0, 200, 0)
    end
end


RegisterNetEvent('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        -- ลบรังผึ้งทั้งหมดจากผู้เล่น
        for playerId, hives in pairs(placed_hives) do
            for _, beehive in ipairs(hives) do
                DeleteObject(beehive)
            end
        end
        
        -- หยุด particle effect ของฝูงผึ้ง
        for _, BeesFX in pairs(CreatedSwarms) do
            StopParticleFxLooped(BeesFX, true)
        end
        RemoveAllBlips()
    end
end)
