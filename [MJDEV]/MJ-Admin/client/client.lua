VORPcore = {}
admin = {}
nearBlips = {}
longBlips = {}
bloked = {}
display, frozen, isSpectating, speed = false, false, false, 1
local noclipAllow = false
local temppos = nil
local playerID = 0
local Updateblip = false
local Ghost = false
local BlockMIC = 0
local Block = false
local god = false
local goldenCores = false
local infiniteammo = false
local isPlayerIDActive = false
local Keys = {
    -- Mouse buttons
    ["MOUSE1"] = 0x07CE1E61,
    ["MOUSE2"] = 0xF84FA74F,
    ["MOUSE3"] = 0xCEE12B50,
    ["MWUP"] = 0x3076E97C,
    -- keyboard
    ["A"] = 0x7065027D,
    ["B"] = 0x4CC0E2FE,
    ["C"] = 0x9959A6F0,
    ["D"] = 0xB4E465B4,
    ["E"] = 0xCEFD9220,
    ["F"] = 0xB2F377E8,
    ["G"] = 0x760A9C6F,
    ["H"] = 0x24978A28,
    ["I"] = 0xC1989F95,
    ["J"] = 0xF3830D8E,
    ["L"] = 0x80F28E95,
    ["M"] = 0xE31C6A41,
    ["N"] = 0x4BC9DABB,
    ["O"] = 0xF1301666,
    ["P"] = 0xD82E0BD2,
    ["Q"] = 0xDE794E3E,
    ["R"] = 0xE30CD707,
    ["S"] = 0xD27782E3,
    ["U"] = 0xD8F73058,
    ["V"] = 0x7F8D09B8,
    ["W"] = 0x8FD015D8,
    ["X"] = 0x8CC9CD42,
    ["Z"] = 0x26E9DC00,
    ["RIGHTBRACKET"] = 0xA5BDCD3C,
    ["LEFTBRACKET"] = 0x430593AA,
    ["CTRL"] = 0xDB096B85,
    ["TAB"] = 0xB238FE0B,
    ["SHIFT"] = 0x8FFC75D6,
    ["SPACEBAR"] = 0xD9D0E1C0,
    ["ENTER"] = 0xC7B5340A,
    ["BACKSPACE"] = 0x156F7119,
    ["LALT"] = 0x8AAA0AD4,
    ["DEL"] = 0x4AF4D473,
    ["PGUP"] = 0x446258B6,
    ["PGDN"] = 0x3C3DD371,
    ["F1"] = 0xA8E3F467,
    ["F4"] = 0x1F6D95E5,
    ["F6"] = 0x3C0A40F2,
    ["1"] = 0xE6F612E4,
    ["2"] = 0x1CE6D9EB,
    ["3"] = 0x4F49CC4C,
    ["4"] = 0x8F9F9E58,
    ["5"] = 0xAB62E997,
    ["6"] = 0xA1FDE2A6,
    ["7"] = 0xB03A913B,
    ["8"] = 0x42385422,
    ["DOWN"] = 0x05CA7C52,
    ["UP"] = 0x6319DB71,
    ["LEFT"] = 0xA65EBAB4,
    ["RIGHT"] = 0xDEB34313
}

TriggerEvent("getCore", function(core)
    VORPcore = core
end)


Citizen.CreateThread(function()
    while true do
        Wait(5)  -- ตรวจสอบการกดปุ่มทุกเฟรม (ลดการใช้ CPU)
        if IsControlJustPressed(0, 0x446258B6) then  
            ExecuteCommand('adminmenu')  -- เรียกคำสั่ง adminmenu
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(5)
        if IsControlJustPressed(0, 0xB03A913B) then
            if noclipAllow then
                if not isPlayerIDActive then
                    TriggerEvent('MJ-DEV:showPlayerIDs', not isPlayerIDActive)
                    isPlayerIDActive = true
                else
                    TriggerEvent('MJ-DEV:showPlayerIDs', not isPlayerIDActive)
                    isPlayerIDActive = false
                end

            end
        end
    end
end)

Citizen.CreateThread(function()
    local handsUp = false
    while true do
        Citizen.Wait(5)
        if (IsControlJustPressed(0, 0x8CC9CD42)) and IsInputDisabled(0) then
            local ped = PlayerPedId()
            if (DoesEntityExist(ped) and not IsEntityDead(ped)) then
                RequestAnimDict("script_proc@robberies@shop@rhodes@gunsmith@inside_upstairs")
                while (not HasAnimDictLoaded("script_proc@robberies@shop@rhodes@gunsmith@inside_upstairs")) do
                    Citizen.Wait(100)
                end

                if handsUp then
                    -- ยกมือลง
                    ClearPedSecondaryTask(ped)
                    handsUp = false
                else
                    -- ยกมือขึ้น
                    SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
                    DisablePlayerFiring(ped, true)
                    TaskPlayAnim(ped, "script_proc@robberies@shop@rhodes@gunsmith@inside_upstairs","handsup_register_owner", 2.0, -1.0, 120000, 31, 0, true, 0, false, 0, false)
                    handsUp = true
                end
            end
        end
    end
end)


local pointing = false
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)
        if IsControlPressed(0, 0x4CC0E2FE) then -- B
            if pointing then
                pointing = false
                ClearPedSecondaryTask(PlayerPedId())
                RemoveAnimDict("script_common@other@unapproved")
            else
                pointing = true
                RequestAnimDict('script_common@other@unapproved')
                while not HasAnimDictLoaded('script_common@other@unapproved') do
                    Citizen.Wait(100)
                end
                TaskPlayAnim(PlayerPedId(), 'script_common@other@unapproved', 'loop_0', 1.0, -1.0, 9999999999, 30, 0,true, 0, false, 0, false)
            end
            Wait(500) -- ป้องกัน spam
        end
    end
end)


RegisterNUICallback("giveitemall", function(data)
    local amount = tonumber(data.amount)
    TriggerServerEvent("admin:AddItemAll", data.name, amount)
end)

RegisterNUICallback("reviveall", function(data)
    if data.inputData == '1' then
        TriggerServerEvent("admin:reviveall")
    end
end)

RegisterNUICallback("delcarall", function(data)
    if data.inputData == '1' then
        TriggerServerEvent("admin:delcarall")
    end
end)

RegisterNUICallback("exit", function(data)
    SetDisplay(false)
end)

RegisterNUICallback("ban", function(data)
    TriggerServerEvent("admin:Ban", data.playerid, tonumber(data.inputData), "แบนชั่วคราว")
end)

RegisterNUICallback("permaban", function(data)
    TriggerServerEvent("admin:Ban", data.playerid, 0, data.inputData)
end)

RegisterNUICallback("godmode", function(data)
    TriggerServerEvent("admin:godmode", data.playerid)
end)
RegisterNUICallback("admino", function(data)
    SetDisplay(false)
    TriggerEvent('vorp_admin:OpenAdmin')
end)

RegisterNUICallback("godmodeall", function(data)
    TriggerServerEvent("admin:godmodeall")
end)

RegisterNUICallback("Golden", function(data)
    TriggerServerEvent("admin:Golden", data.playerid)
end)

RegisterNUICallback("GoldenAll", function(data)
    TriggerServerEvent("admin:Golden", 'all')
end)

RegisterNUICallback("scoreb", function(data)
    SetDisplay(false)
    Wait(300)
    TriggerEvent("K1-Scoreboard:client:open")
end)
RegisterNUICallback("InfiAmmo", function(data)
    TriggerServerEvent("admin:InfiAmmo", data.playerid)
end)

RegisterNUICallback("unban", function(data)
    TriggerServerEvent("admin:Unban", data.confirmoutput)
    admin.GetPlayers()
end)

RegisterNUICallback("addCash", function(data)
    local amnt = tonumber(data.inputData)
    TriggerServerEvent("admin:AddCash", data.playerid, amnt)

end)

RegisterNUICallback("addBank", function(data)
    local amnt = tonumber(data.inputData)
    TriggerServerEvent("admin:AddBank", data.playerid, amnt)

end)

-- จำไว้ว่ากระเป๋าที่เปิดอยู่เป็นของผู้เล่นคนอื่นที่แอดมินสั่งเปิด ไม่ใช่กระเป๋าตัวเอง
-- (syn:closeinv ยิงตอนปิดกระเป๋าอะไรก็ได้ ถ้าไม่แยกจะไปล้าง DataSteal ผิดจังหวะ)
local viewingPlayerInv = false

RegisterNUICallback("inventory", function(data)
    SetDisplay(false)
    -- เดิมเรียก vorp_inventory:OpenstealInventory ตรงนี้เลย ซึ่งเปิดได้แค่หน้าต่างเปล่า
    -- (ไม่มีใครส่งรายการของเข้าไป และไม่ได้ตั้ง DataSteal ที่ระบบหยิบของต้องใช้)
    -- ให้ server เป็นคนจัดการทั้งชุด — ดู admin:OpenPlayerInventory ใน server/server.lua
    viewingPlayerInv = true
    TriggerServerEvent("admin:OpenPlayerInventory", data.playerid)
end)

-- vorp_inventory ยิง syn:closeinv ทุกครั้งที่ปิดกระเป๋า (NUIService.CloseInv)
-- ใช้จังหวะนี้ล้าง DataSteal ฝั่ง server ไม่งั้นค่าค้างไว้ แล้วแอดมินไปเปิดตู้อื่นทีหลัง
-- ของที่ลากอาจไปโผล่ที่ผู้เล่นคนเดิมโดยไม่ตั้งใจ
AddEventHandler("syn:closeinv", function()
    if not viewingPlayerInv then return end
    viewingPlayerInv = false
    TriggerServerEvent("admin:ClosePlayerInventory")
end)

RegisterNUICallback("giveitem", function(data)
    local amnt = tonumber(data.amount)

    TriggerServerEvent("admin:AddItem", data.playerid, data.name, amnt)
end)


RegisterNUICallback("error", function(data)
    chat(data.error, {255, 0, 0})

end)

RegisterNUICallback("tp-wp", function(data)
    admin.TeleportToWaypoint()
end)

RegisterNUICallback("bring", function(data)
    TriggerServerEvent("admin:Teleport", data.playerid, "bring")

end)

RegisterNUICallback("bringall", function(data)
    if data.inputData == '1' then
        local coords = GetEntityCoords(PlayerPedId())
        TriggerServerEvent("admin:TeleportAll", coords)
    end
end)

RegisterNUICallback("goto", function(data)
    TriggerServerEvent("admin:Teleport", data.playerid, "goto")

end)

RegisterNUICallback("kick", function(data)
    TriggerServerEvent("admin:Kick", data.playerid, data.inputData)
    print(data.playerid, data.inputData)

end)

RegisterNUICallback("anmid", function(data)
    TriggerServerEvent("admin:anmid", data.playerid, data.inputData)

end)

RegisterNUICallback("anmall", function(data)
    TriggerServerEvent("admin:anmall", data.inputData)
end)

RegisterNUICallback("spawnHorse", function(data)
    TriggerServerEvent("admin:SetHorse", data.playerid, data.inputData)
    SetDisplay(false)
end)

RegisterNUICallback("setmodel", function(data)
    TriggerServerEvent("admin:SetMonModel", data.playerid, data.inputData)
    SetDisplay(false)
end)

RegisterNUICallback("kickall", function(data)
    TriggerServerEvent("admin:KickAll", data.inputData)

end)
RegisterNUICallback("Coords", function(data)
    SetDisplay(false)
    TriggerEvent("MJDEV-CoordsUI:OPEN")

end)

RegisterNUICallback("spectate", function(data)
    playerID = data.playerid
    admin.Spectate(playerID, true)
    isSpectating = true
end)

RegisterNUICallback("resetcol", function(data)
    TriggerServerEvent("admin:resetcol", data.playerid)

end)

RegisterNUICallback("freeze", function(data)
    TriggerServerEvent("admin:Freeze", data.playerid)

end)

RegisterNUICallback("freezeall", function()
    TriggerServerEvent("admin:FreezeAll")

end)

RegisterNUICallback("targetskinmenu", function(data)
    TriggerServerEvent("admin:targetskinmenu", data.playerid)

end)

RegisterNUICallback("kill", function(data)
    TriggerServerEvent("admin:Slay", data.playerid)

end)

RegisterNUICallback('stopfood', function(data)
    TriggerServerEvent('admin:stopfood', data.playerid)

end)

-- หมายเหตุ: เดิมบรรทัดพวกนี้ยิง TriggerEvent("vorpmetabolism:changeValue", ...) แบบ local
-- ด้วย ซึ่งลงที่ "เครื่องแอดมินเอง" ไม่ใช่เป้าหมาย (กดเติมให้คนอื่น แต่ตัวเองอิ่มแทน) —
-- ที่ผ่านมาไม่มีใครเห็นผลเพราะ handler ฝั่ง MJ-STATUS เป็น no-op มาตลอด
-- ตอนนี้ตัดทิ้ง ให้ server เป็นคนสั่งเป้าหมายผ่าน exports ของ MJ-STATUS ทางเดียว
RegisterNUICallback('foodall', function(data)
    if data.inputData == '1' then
        TriggerServerEvent('admin:foodall')
    end

end)

RegisterNUICallback('food', function(data)
    TriggerServerEvent('admin:foodall', data.playerid)
end)

RegisterNUICallback('stressall', function(data)
    TriggerServerEvent('admin:stressall')
end)

RegisterNUICallback('stress', function(data)
    TriggerServerEvent('admin:stressall', data.playerid)

end)

RegisterNUICallback('cleanall', function(data)
    TriggerServerEvent('admin:cleanall')

end)

RegisterNUICallback('clean', function(data)
    TriggerServerEvent('admin:cleanall', data.playerid)

end)

RegisterNUICallback('healall', function(data)
    if data.inputData == '1' then
        TriggerServerEvent('admin:healall')
    end

end)

RegisterNUICallback('petskin', function(data)
    ExecuteCommand('pedmenu')
    SetDisplay(false)
end)

RegisterNUICallback('weathers', function(data)

    TriggerEvent("weathersync:openAdminUi")
    SetDisplay(false)
end)

RegisterNUICallback('reoil', function(data)
    TriggerServerEvent("MJDEV-StealOiljob:resetNoCandomission:iscmd:Sv")
end)

RegisterNUICallback('Maxoil', function(data)
    TriggerServerEvent("MJDEV-StealOiljob:Candomission:Sv")
end)

RegisterNUICallback('reskin', function(data)
    TriggerServerEvent('admin:loadskin', data.playerid)

end)

RegisterNUICallback('heal', function(data)
    TriggerServerEvent('admin:healall', data.playerid)

end)

RegisterNUICallback("killall", function(data)
    if data.inputData == '1' then
        TriggerServerEvent("admin:SlayAll")
    end

end)

RegisterNUICallback("promote", function(data)
    TriggerServerEvent("admin:Promote", data.playerid, data.level)
end)

RegisterNUICallback("weapon", function(data)
    local amnt = tonumber(data.amount)
    TriggerServerEvent("admin:GiveWeapon", data.playerid, data.weapon, amnt)

end)

RegisterNUICallback("noclip", function(data)
    admin.Noclip()
end)

RegisterNUICallback("enablemic", function(data)
    TriggerServerEvent('admin:enableMic', data.playerid)
end)

RegisterNUICallback("setvehicle", function(data)
    local playerPed = GetPlayerPed(-1)
    if IsPedInAnyVehicle(playerPed, false) then
        TriggerEvent("admin:setvehicle")
    else
        notification("คุณต้องอยู่บนยานพาหนะ", "e")
    end
end)

RegisterNUICallback("god", function(data)
    TriggerServerEvent("admin:God", data.playerid)
end)

RegisterNUICallback("godall", function()
    TriggerServerEvent("admin:GodAll")
end)

RegisterNUICallback("spawnvehicle", function(data)
    if data.model == 'deletehorse' then
        admin.DeleteVehicle(data.model) 
    else
        admin.SpawnVehicle(data.model) 
    end
end)

RegisterNUICallback("jail", function(data)
    local amnt = tonumber(data.inputData)
    TriggerServerEvent("admin:jail", data.playerid, amnt)
end)

RegisterNUICallback("cjail", function(data)
    local amnt = tonumber(data.inputData)
    TriggerServerEvent("admin:cjail", data.playerid, amnt)
end)

RegisterNUICallback("announce", function(data)
    TriggerServerEvent("admin:Announcement", data.inputData)
end)

-- ป้ายประกาศเต็มจอของ MJ-Announcement (คนละอันกับ "announce" ด้านบนที่ยิงลงแชทธรรมดา)
RegisterNUICallback("mjannounce", function(data)
    TriggerServerEvent("admin:MJAnnounce", data.inputData)
end)

RegisterNUICallback("setJob", function(data)
    -- print(DumpTable(data))
    TriggerServerEvent("admin:setJob", data.playerid, data.job, data.rank, data.label)
end)

RegisterNUICallback("revive", function(data)
    -- เดิมยิง vorpmetabolism:changeValue แบบ local ด้วย = ลงที่เครื่องแอดมินเอง ไม่ใช่คนที่ถูกชุบ
    -- (และเป็น no-op อยู่แล้ว) — ตัดทิ้ง ถ้าจะเติมค่าให้คนที่ถูกชุบ ทำฝั่ง server ของ admin:revive
    TriggerServerEvent("admin:revive", data.playerid)
end)

RegisterNUICallback("revivenocooldown", function(data)
    TriggerServerEvent("admin:revivenocooldown", data.playerid)
end)

RegisterNUICallback("setTime", function(data)
    TriggerServerEvent("admin:Time", data.inputData)
end)

RegisterNUICallback("freezeTime", function(data)
    TriggerServerEvent("admin:freezeTime")
end)

RegisterNUICallback("changeWeather", function(data)
    TriggerServerEvent("admin:Weather", data.weather)
end)

RegisterNUICallback("freezeWeather", function(data)
    TriggerServerEvent("admin:freezeWeather")
end)

RegisterNUICallback("blackout", function(data)
    TriggerServerEvent("admin:Blackout")
end)

-- คืนค่าเวลา+อากาศเป็นอัตโนมัติ (weathersync คุมเองตามพยากรณ์)
RegisterNUICallback("resetWeatherTime", function(data)
    TriggerServerEvent("admin:ResetWeatherTime")
end)

-- รีเซ็ตบัญชีผู้เล่น — inputData คือชื่อตัวละครที่แอดมินพิมพ์ยืนยัน (server เทียบให้ตรงเป๊ะอีกชั้น)
RegisterNUICallback("resetAccount", function(data)
    TriggerServerEvent("admin:ResetPlayerAccount", data.playerid, data.inputData)
end)

admin.TeleportToWaypoint = function()
    if Config["Perms"][playerRank] and Config["Perms"][playerRank].CanTpWp then
        local playerPed = PlayerPedId()
        local coords = GetWaypointCoords()
        local x, y, groundZ, startingpoint = coords.x, coords.y, 650.0, 750.0
        local found = false
        local vehicle = GetVehiclePedIsIn(playerPed, false)

        DoScreenFadeOut(500)
        Wait(1000)
        FreezeEntityPosition(playerPed, true)
        for i = startingpoint, 0, -25.0 do
            local z = i
            if (i % 2) ~= 0 then
                z = startingpoint + i
            end
            SetEntityCoords(playerPed, x, y, z - 1000, false, false, false, false)
            Wait(1000)
            found, groundZ = GetGroundZAndNormalFor_3dCoord(x, y, z)
            if found then
                RequestCollisionAtCoord(x, y, groundZ)
                Wait(200)
                SetEntityCoords(playerPed, x, y, groundZ, false, false, false, false)
                repeat Wait(0) until HasCollisionLoadedAroundEntity(playerPed)
                FreezeEntityPosition(playerPed, false)
                Wait(1000)
                DoScreenFadeIn(650)
                break
            end
        end
    end
end

admin.DeleteVehicle = function(data)
    local ped = PlayerPedId()
    -- ตรวจสอบว่าผู้เล่นอยู่ในยานพาหนะ (รถม้า, wagon, รถทั่วไป)
    local currentVehicle = GetVehiclePedIsIn(ped, false)
    if currentVehicle and currentVehicle ~= 0 then
        print('Deleting Vehicle: ' .. currentVehicle)
        SetEntityAsMissionEntity(currentVehicle, true, true)
        TaskLeaveVehicle(ped, currentVehicle, 0) -- สั่งให้ผู้เล่นออกจากยานพาหนะก่อนลบ
        Wait(1000) -- รอให้ผู้เล่นลงก่อน
        DeleteVehicle(currentVehicle)
    end

    -- ตรวจสอบว่าผู้เล่นขี่ม้าอยู่หรือไม่
    local playerHorse = GetMount(ped)
    if playerHorse and DoesEntityExist(playerHorse) then
        print('Deleting Horse: ' .. playerHorse)
        SetEntityAsMissionEntity(playerHorse, true, true)
        Wait(500) -- ให้เวลาระบบประมวลผลก่อนลบ
        DeletePed(playerHorse)
    end
end


RegisterNUICallback("spy", function(data)
    if not Ghost then
        Ghost = true
        SetEntityVisible(PlayerPedId(), false)
        TriggerServerEvent("admin:Spy", data.playerid)
    else
        SetEntityVisible(PlayerPedId(), true)
        Ghost = false
    end
end)

-- ตรวจสอบว่าเป็นเขตเมืองหรือไม่ (วางไว้ก่อนฟังก์ชันอื่นๆ)
local function IsTownZone(hTownZone)
    local TownZones = {
        [459833523] = true,    -- Valentine
        [2046780049] = true,   -- Rhodes
        [-765540529] = true,   -- Saint Denis
        [427683330] = true,    -- Strawberry
        [1053078005] = true,   -- Blackwater
        [-744494798] = true,   -- Armadillo
        [-1524959147] = true,  -- Tumbleweed
        [7359335] = true,      -- Annesburg
        [2126321341] = true,   -- Van Horn
        [201158410] = true,    -- Manicato
        [1463094051] = true    -- Manzanita Post
    }

    return TownZones[hTownZone] or false
end

-- ตรวจสอบว่าม้าอยู่ในเมืองหรือไม่
local function LocationUiCheckTowns(vPlayerCoords)
    local hTownZone = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, 1)
    return IsTownZone(hTownZone)
end

local function DeleteHorseAuto()
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)

    for _, entity in pairs(GetGamePool("CPed")) do
        if DoesEntityExist(entity) and not IsPedAPlayer(entity) then
            local model = GetEntityModel(entity)

            if IsThisModelAHorse(model) then
                local horseCoords = GetEntityCoords(entity)
                if LocationUiCheckTowns(horseCoords) then
                    if not IsHorseMountedByPlayer(entity) and IsImportantNPC(entity) then
                        print('Removed Horse: '..entity)
                        DeleteEntity(entity)
                    end
                end
            end
        end
    end
end

RegisterNetEvent("admin_:delcarall")
AddEventHandler("admin_:delcarall", function()
    -- ตรวจสอบเกวียน (หากต้องการ)
    local playerPed = PlayerPedId()
    local playerHorse = GetMount(playerPed) -- รับม้าที่ติดอยู่กับผู้เล่น
    local playerWagon = GetVehiclePedIsIn(playerPed, false)  -- เกวียนที่ผู้เล่นอยู่ ถ้าไม่มีจะได้ 0 หรือ nil
    for _, entity in pairs(GetGamePool("CVehicle")) do
        if DoesEntityExist(entity) and not IsPedAPlayer(entity) then
            local model = GetEntityModel(entity)
            -- เช็คว่าเป็นเกวียน (แทนที่ชื่อโมเดลด้วยโมเดลของเกวียนที่ต้องการ)
            if IsThisModelADraftVehicle(model) then
                if not IsHorseMountedByPlayer(entity) and entity ~= playerWagon then
                    DeleteEntity(entity)
                end
            end
        end
    end 
    DeleteHorseAuto() 
end)

-- ตรวจสอบว่าม้านี้มีผู้เล่นขี่อยู่หรือไม่
function IsHorseMountedByPlayer(horseEntity)
    if DoesEntityExist(horseEntity) then
        local rider = GetPedInVehicleSeat(horseEntity, -1)
        return DoesEntityExist(rider) and IsPedAPlayer(rider)
    end
    return false
end

-- ยกเว้น NPC พิเศษ (สามารถเพิ่มเงื่อนไขหรือตัว NPC ได้ตามต้องการ)
function IsImportantNPC(entity)
    local pedType = GetPedType(entity)
    return pedType == 28 -- PedType 28 มักจะเป็น NPC สำคัญ
end

function IsImportantMount(entity)
    local pedType = GetEntityType(entity)
    return pedType == 1 -- PedType 28 มักจะเป็น NPC สำคัญ
end


RegisterNetEvent("admin:setCoords")
AddEventHandler("admin:setCoords", function(coords)
    SetEntityCoords(PlayerId(), coords)
end)

RegisterNetEvent("admin:loadskin")
AddEventHandler("admin:loadskin", function()
    ExecuteCommand('rc')
end)

RegisterNetEvent("admin:removeUser")
AddEventHandler("admin:removeUser", function(plyId)
    print("OUT:" .. plyId)
    if nearBlips[plyId] then
        RemoveBlip(nearBlips[plyId].blip)
        nearBlips[plyId] = nil
    end
    if longBlips[plyId] then
        RemoveBlip(longBlips[plyId].blip)
        longBlips[plyId] = nil
    end
end)

RegisterNetEvent("admin:showblip")
AddEventHandler("admin:showblip", function(myId, data)
    for k, v in pairs(data) do
        local cId = GetPlayerFromServerId(v.playerId)
        if true then
            if myId ~= v.playerId then
                if cId ~= -1 then
                    if nearBlips[v.playerId] == nil then
                        if longBlips[v.playerId] then
                            RemoveBlip(longBlips[v.playerId].blip)
                            longBlips[v.playerId] = nil
                        end
                        nearBlips[v.playerId] = {}
                        nearBlips[v.playerId].blip = AddBlipForEntity(GetPlayerPed(cId))
                        setupBlip(nearBlips[v.playerId].blip, v)
                    end
                else
                    if longBlips[v.playerId] == nil then
                        if nearBlips[v.playerId] then
                            RemoveBlip(nearBlips[v.playerId].blip)
                            nearBlips[v.playerId] = nil
                        end
                        longBlips[v.playerId] = {}
                        longBlips[v.playerId].blip = N_0x554d9d53f696d002(1664425300, v.coords)
                        setupBlip(longBlips[v.playerId].blip, v)
                    else
                        if longBlips[v.playerId] then
                            RemoveBlip(longBlips[v.playerId].blip)
                        end
                        longBlips[v.playerId].blip = N_0x554d9d53f696d002(1664425300, v.coords)
                        setupBlip(longBlips[v.playerId].blip, v)
                    end
                end
            end
        end
    end
end)

function setupBlip(blip, data)
    local blip_modifier_hash = GetHashKey('BLIP_MODIFIER_MP_COLOR_20')
    SetBlipSprite(blip, -185399168, 1)
    SetBlipScale(blip, 0.8)
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip, blip_modifier_hash)

    Citizen.InvokeNative(0x9CB1A1623062F402, blip, data.rpname)
end

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    removeAllBlips()
end)

function removeAllBlips()
    for k, v in pairs(nearBlips) do
        RemoveBlip(v.blip)
    end
    for k, v in pairs(longBlips) do
        RemoveBlip(v.blip)
    end
    nearBlips = {}
    longBlips = {}
end

function restoreBlip(blip)
    SetBlipSprite(blip, 6)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, 0)
    SetBlipShowCone(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(GetPlayerName(PlayerId()))
    EndTextCommandSetBlipName(blip)
    SetBlipCategory(blip, 1)
end

RegisterNetEvent("admin:Freeze")
AddEventHandler("admin:Freeze", function(targetPed)
    local player = PlayerId()
    local ped = PlayerPedId()
    frozen = not frozen
    if not frozen then
        if not IsEntityVisible(ped) then
            SetEntityVisible(ped, true)
        end
        if not IsPedInAnyVehicle(ped) then
            SetEntityCollision(ped, true)
        end
        FreezeEntityPosition(ped, false)
        SetPlayerInvincible(player, false)
    else
        SetEntityCollision(ped, false)
        FreezeEntityPosition(ped, true)
        SetPlayerInvincible(player, true)
        if not IsPedFatallyInjured(ped) then
            ClearPedTasksImmediately(ped)
        end
    end
end)

RegisterNetEvent("admin_:SetMonModel")
AddEventHandler("admin_:SetMonModel", function(model)
    SetMonModel(model)
end)

RegisterNetEvent("admin_:SetHorse")
AddEventHandler("admin_:SetHorse", function(model)
    admin.SpawnVehicle(model)
end)

RegisterNetEvent("admin_:teleport")
AddEventHandler("admin_:teleport", function(temppos)
    DoScreenFadeOut(2000)
    Wait(2000)
    SetEntityCoords(PlayerPedId(), temppos.x, temppos.y, temppos.z)
    DoScreenFadeIn(3000)

end)

RegisterNetEvent("admin:Slay")
AddEventHandler("admin:Slay", function(targetPed)
    SetEntityHealth(PlayerPedId(), 0)
end)

RegisterNetEvent("admin:God")
AddEventHandler("admin:God", function(targetPed)
    GODmode()
end)

RegisterNetEvent("admin:GodAll")
AddEventHandler("admin:GodAll", function()
    GODmode()
end)

admin.SpawnVehicle = function(model)
    if Config["Perms"][playerRank] and Config["Perms"][playerRank].CanSpawnVehicle then
        CreateThread(function() 
            local hash = GetHashKey(model)

            if IsModelValid(hash) then
                local ped = PlayerPedId()
                
                -- Delete any vehicle or horse the player is currently in
                if IsPedSittingInAnyVehicle(ped) then 
                    local currentvehicle = GetVehiclePedIsIn(ped, false)
                    SetEntityAsMissionEntity(currentvehicle, true, true)
                    DeleteVehicle(currentvehicle)
                end

                -- Check if the player is riding a horse, and delete the horse
                local playerHorse = GetMount(ped) -- รับม้าที่ติดอยู่กับผู้เล่น
                if playerHorse then
                    SetEntityAsMissionEntity(playerHorse, true, true)
                    DeletePed(playerHorse)  -- ลบม้า
                end

                -- Request and load the model
                RequestModel(hash, 0)
                while not HasModelLoaded(hash) do
                    Wait(0)
                end

                -- Handle collision if it's not a boat
                if not IsThisModelABoat(hash) and not IsThisModelAHorse(hash) then
                    RequestCollisionForModel(hash)
                    while not HasCollisionForModelLoaded(hash) do
                        Wait(0)
                    end
                end

                if HasModelLoaded(hash) then
                    local x, y, z = table.unpack(GetEntityCoords(ped))
                    local pedheading = GetEntityHeading(ped)
                    if IsThisModelADraftVehicle(hash) == 0 then
                        local horse = CreatePed(hash, x, y, z, pedheading, true, false)
                        repeat Wait(0) until DoesEntityExist(horse)
                        Citizen.InvokeNative(0x77FF8D35EEC6BBC4, horse, 1, 0) -- Equip horse (if needed)
                        Citizen.InvokeNative(0x028F76B6E78246EB, ped, horse, -1, true) -- Make the player mount the horse
                        notification("เสกม้า <strong class='blue-text'>" .. model .. "</strong>", "s")
                    else
                        local vehcreated
                        if not IsThisModelABoat(hash) then
                            vehcreated = CreateVehicle(hash, x, y, z, pedheading, true, true, false, false)
                        else
                            vehcreated = CreateVehicle_2(hash, x, y, z, pedheading, true, true, false, false)
                        end
                        SetEntityAsMissionEntity(vehcreated,true,true)
                        while not DoesEntityExist(vehcreated) do
                            Wait(0)
                        end
                        SetVehicleOnGroundProperly(vehcreated)
                        SetVehicleAsNoLongerNeeded(vehcreated)
                        TaskWarpPedIntoVehicle(ped,vehcreated,-1)
                        SetEntityVisible(vehcreated, true)
                        notification("เสกรถ <strong class='blue-text'>" .. model .. "</strong>", "s")
                    end
                    SetModelAsNoLongerNeeded(hash)
                end
            end
        end)
    else
        -- If the player doesn't have permission
        notification("คุณไม่มีสิทธิ์ในการเสกยานพาหนะ", "e")
    end
end


admin.Spectate = function(target, bool)
    local playerRank = playerRank
    if Config["Perms"][playerRank] and Config["Perms"][playerRank].CanSpectate then
        if bool then
            temppos = GetEntityCoords(PlayerPedId(), false)
            SetEntityInvincible(PlayerPedId(), true)
            SetEntityVisible(PlayerPedId(), false, false)
            FreezeEntityPosition(PlayerPedId(), true)
            Citizen.Wait(1000)
            local targetPed = GetPlayerPed(GetPlayerFromServerId(target))
            local name = GetPlayerName(GetPlayerFromServerId(target))
            if targetPed ~= PlayerPedId() then
                if (not IsScreenFadedOut() and not IsScreenFadingOut()) then
                    DoScreenFadeOut(1000)
                    while (not IsScreenFadedOut()) do
                        Citizen.Wait(0)
                    end
                    local targetx, targety, targetz = table.unpack(GetEntityCoords(targetPed, false))
                    RequestCollisionAtCoord(targetx, targety, targetz)
                    NetworkSetInSpectatorMode(true, targetPed)
                    notification("สังเกตุการณ์ <strong class='green-text'>" .. name, "h")
                    if (IsScreenFadedOut()) then
                        DoScreenFadeIn(1000)
                    end
                end

            else
                notification(
                    "คุณไม่สามารถสังเกตุการณ์ตัวเองได้",
                    "h")
            end
            Citizen.CreateThread(function()
                while isSpectating do
                    Citizen.Wait(5)
                    if IsControlJustPressed(0, 0x156F7119) then
                        admin.Spectate(playerID, false)
                        isSpectating = false
                        playerID = nil
                    end
                end
            end)
        else
            local targetPed = GetPlayerPed(GetPlayerFromServerId(target))
            local name = GetPlayerName(GetPlayerFromServerId(target))
            if (not IsScreenFadedOut() and not IsScreenFadingOut()) then
                DoScreenFadeOut(1000)
                while (not IsScreenFadedOut()) do
                    Citizen.Wait(0)
                end
                local targetx, targety, targetz = table.unpack(GetEntityCoords(targetPed, false))
                RequestCollisionAtCoord(targetx, targety, targetz)
                NetworkSetInSpectatorMode(false, targetPed)
                notification("หยุดสังเกตุการณ์ <strong class='green-text'>" .. name, "h")
                if (IsScreenFadedOut()) then
                    DoScreenFadeIn(1000)
                end
            end
            if temppos ~= nil then
                SetEntityCoords(PlayerPedId(), temppos)
                SetEntityInvincible(PlayerPedId(), false)
                SetEntityVisible(PlayerPedId(), true, true)
                FreezeEntityPosition(PlayerPedId(), false)
            end
        end
    else
        -- TriggerEvent("chat:addMessage", {args = {"^1ระบบ", " : คุณไม่มีสิทเข้าถึงเเผงควบคุมผู้ดูเเลระบบ"}})
    end
end

-- Round each component of a vector
function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

RegisterNUICallback("Updateblip", function()
    Updateblip = not Updateblip
    TriggerServerEvent("admin:addUpdateblip", Updateblip)
    if not Updateblip then
        removeAllBlips()
    end
end)

RegisterNUICallback("name_on", function()
    if not isPlayerIDActive then
        TriggerEvent('MJ-DEV:showPlayerIDs', not isPlayerIDActive)
        isPlayerIDActive = true
    else
        TriggerEvent('MJ-DEV:showPlayerIDs', not isPlayerIDActive)
        isPlayerIDActive = false
    end
end)

RegisterNUICallback("stamina", function()
    stamina_ = not stamina_
    if stamina_ then
        Citizen.CreateThread(function()
            stamina()
        end)
    end

end)

RegisterNUICallback("staminaall", function()
    TriggerServerEvent("admin:staminaall")
end)

RegisterNetEvent("admin:staminaall")
AddEventHandler("admin:staminaall", function()
    stamina_ = not stamina_
    if stamina_ then
        Citizen.CreateThread(function()
            stamina()
        end)
    end
end)

function stamina()
    while stamina_ do
        RestorePlayerStamina(PlayerId(), 1.0)
        Citizen.Wait(10000)
    end
end

function DrawText3D(x, y, z, text, mul)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov * mul
    if onScreen then
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFontForCurrentCommand(4)
        SetTextProportional(1)
        -- SetTextScale(0.0, 0.55)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function getCamDirection()
    local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(GetPlayerPed(-1))
    return heading
end

function notification(i, x)
    TriggerEvent("pNotify:SendNotification", {
        text = i,
        type = "success",
        timeout = 5000,
        layout = "topRight",
        queue = "left"
    })
end

RegisterNetEvent('admin:GetTimerBlock')
AddEventHandler('admin:GetTimerBlock', function()
    TriggerServerEvent('admin:GetTimerBlockSV')
end)

Citizen.CreateThread(function()
    TriggerEvent('admin:GetTimerBlock')
    while true do
        Wait(0)
        if Block then
            DisableControlAction(0, 249, true)
            DisableControlAction(1, 249, true)
            DisableControlAction(2, 249, true)
        end
    end
end)

RegisterNetEvent('admin:ShowTextBlockMic')
AddEventHandler('admin:ShowTextBlockMic', function(time, playerid)
    if time > 0 then
        bloked[playerid] = true
    else
        bloked[playerid] = false
    end
    while bloked[playerid] do
        Wait(5)
        local p = GetPlayerPed(-1)
        local x1, y1, z1 = table.unpack(GetEntityCoords(p, true))
        for k, v in pairs(GetActivePlayers()) do
            if GetPlayerServerId(v) == playerid then
                local ped = GetPlayerPed(v)
                local x2, y2, z2 = table.unpack(GetEntityCoords(ped, true))
                local distance = math.floor(GetDistanceBetweenCoords(x1, y1, z1, x2, y2, z2, true))
                if distance < 20.0 then
                    local localFPS = 1 / GetFrameTime()(GetEntityVelocity(ped) / localFPS)
                    local text = "~r~•<font face='sarabun'> ถูกบล๊อคไมค์ </font>•"
                    DrawText3D(playerHead.x, playerHead.y, playerHead.z, text, 0.8)
                end
            end
        end
    end
end)

RegisterNetEvent('admin:SetTimeBlockMic')
AddEventHandler('admin:SetTimeBlockMic', function(blockTime)
    BlockMIC = blockTime
    if BlockMIC > 0 then
        Block = true
        if Block then
            repeat
                Wait(1000)

                if BlockMIC > 0 then
                    BlockMIC = BlockMIC - 1
                end

            until BlockMIC == 0
            Block = false
            TriggerServerEvent('admin:enableMic', GetPlayerServerId(PlayerId()))
        end
    end
end)

RegisterNetEvent('admin:healFromAdmin')
AddEventHandler('admin:healFromAdmin', function()
    local p = PlayerPedId()
    local PlayerPed = GetPlayerPed(-1)
    if IsEntityDead(PlayerPedId()) then
        return
    end
    ClearPedBloodDamage(p)
    SetEntityHealth(p, 600)
    local minihearth = Citizen.InvokeNative(0x36731AC041289BB1, PlayerPedId(), 0)
    local energy = Citizen.InvokeNative(0x36731AC041289BB1, PlayerPedId(), 1)
    Citizen.InvokeNative(0xC6258F41D86676E0, playerPed, 1, 100) -- SetAttributeCoreValue
    Citizen.InvokeNative(0xC6258F41D86676E0, playerPed, 2, 100) -- SetAttributeCoreValue
    Citizen.InvokeNative(0xC6258F41D86676E0, PlayerPedId(), 0, 100)
    EnableAttributeOverpower(playerPed, 0, 0.0)
    EnableAttributeOverpower(playerPed, 1, 0.0)
    EnableAttributeOverpower(playerPed, 2, 0.0)
    Citizen.InvokeNative(0xF6A7C08DF2E28B28, playerPed, 0, 0.0)
    Citizen.InvokeNative(0xF6A7C08DF2E28B28, playerPed, 1, 0.0)
    Citizen.InvokeNative(0xF6A7C08DF2E28B28, playerPed, 2, 0.0)

    Citizen.InvokeNative(0xC6258F41D86676E0, playerPed, 1, 100) -- SetAttributeCoreValue
    Citizen.InvokeNative(0xC6258F41D86676E0, playerPed, 2, 100) -- SetAttributeCoreValue
    EnableAttributeOverpower(playerPed, 0, 0.0)
    EnableAttributeOverpower(playerPed, 1, 0.0)
    EnableAttributeOverpower(playerPed, 2, 0.0)
    Citizen.InvokeNative(0xF6A7C08DF2E28B28, playerPed, 0, 0.0)
    Citizen.InvokeNative(0xF6A7C08DF2E28B28, playerPed, 1, 0.0)
    Citizen.InvokeNative(0xF6A7C08DF2E28B28, playerPed, 2, 0.0)
    --[[     if minihearth <= 100 then
        Citizen.InvokeNative(0xC6258F41D86676E0, PlayerPedId(), 0, 100)
        Citizen.InvokeNative(0xC6258F41D86676E0, PlayerPedId(), 1, 100)
		
    end ]]
end)

exports('CheckBanMIC', function()
    return Block
end)

RegisterNetEvent('admin_:InfiAmmo')
AddEventHandler('admin_:InfiAmmo', function()
    InfiAmmo()
end)

function InfiAmmo()
    local player = PlayerPedId()
    local _, weaponHash = GetCurrentPedWeapon(player, false, 0, false)
    if not infiniteammo then
        local unarmed = -1569615261
        if weaponHash == unarmed then
            TriggerEvent("pNotify:SendNotification", {
                text = 'โปรดถืออาวุธ!',
                type = "success",
                timeout = 5000,
                layout = "topRight",
                queue = "left"
            })
        else
            SetPedInfiniteAmmo(player, true, weaponHash)
            infiniteammo = true
            TriggerEvent("pNotify:SendNotification", {
                text = 'เริ่มทำงานกระสุนไม่จำกัด!',
                type = "success",
                timeout = 5000,
                layout = "topRight",
                queue = "left"
            })
        end
    else
        infiniteammo = false
        SetPedInfiniteAmmo(player, false, weaponHash)
        TriggerEvent("pNotify:SendNotification", {
            text = 'ยกกระสุนไม่จำกัดแล้ว!',
            type = "success",
            timeout = 5000,
            layout = "topRight",
            queue = "left"
        })
    end
end

function GODmode()
    local player = PlayerPedId()
    if not god then
        SetEntityCanBeDamaged(player, false)
        SetEntityInvincible(player, true)
        SetPedConfigFlag(player, 2, true) -- no critical hits
        SetPedCanRagdoll(player, false)
        SetPedCanBeTargetted(player, false)
        Citizen.InvokeNative(0x5240864E847C691C, player, false) -- set ped can be incapacitaded
        SetPlayerInvincible(player, true)
        Citizen.InvokeNative(0xFD6943B6DF77E449, player, false) -- set ped can be lassoed
        TriggerEvent("pNotify:SendNotification", {
            text = 'เป็นอมตะแล้ว!',
            type = "success",
            timeout = 5000,
            layout = "topRight",
            queue = "left"
        })
        god = true
    else
        SetEntityCanBeDamaged(player, true)
        SetEntityInvincible(player, false)
        SetPedConfigFlag(player, 2, false)
        SetPedCanRagdoll(player, true)
        SetPedCanBeTargetted(player, true)
        Citizen.InvokeNative(0x5240864E847C691C, player, true)
        SetPlayerInvincible(player, false)
        Citizen.InvokeNative(0xFD6943B6DF77E449, player, true)
        god = false
        TriggerEvent("pNotify:SendNotification", {
            text = 'ยกเลิกเป็นอมตะแล้ว!',
            type = "success",
            timeout = 5000,
            layout = "topRight",
            queue = "left"
        })
    end
end

RegisterNetEvent('admin_:Golden')
AddEventHandler('admin_:Golden', function()
    GoldenCores()
end)

function GoldenCores()
    local playerPed = PlayerPedId()
    if not goldenCores then
        Citizen.InvokeNative(0xC6258F41D86676E0, playerPed, 1, 100) -- SetAttributeCoreValue
        Citizen.InvokeNative(0xC6258F41D86676E0, playerPed, 2, 100) -- SetAttributeCoreValue
        EnableAttributeOverpower(playerPed, 0, 5000.0)
        EnableAttributeOverpower(playerPed, 1, 5000.0)
        EnableAttributeOverpower(playerPed, 2, 5000.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, playerPed, 0, 5000.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, playerPed, 1, 5000.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, playerPed, 2, 5000.0)
        TriggerEvent("pNotify:SendNotification", {
            text = 'เช็ตเลือดเหลืองแล้ว!',
            type = "success",
            timeout = 5000,
            layout = "topRight",
            queue = "left"
        })
        goldenCores = true
    else
        Citizen.InvokeNative(0xC6258F41D86676E0, playerPed, 1, 100) -- SetAttributeCoreValue
        Citizen.InvokeNative(0xC6258F41D86676E0, playerPed, 2, 100) -- SetAttributeCoreValue
        EnableAttributeOverpower(playerPed, 0, 0.0)
        EnableAttributeOverpower(playerPed, 1, 0.0)
        EnableAttributeOverpower(playerPed, 2, 0.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, playerPed, 0, 0.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, playerPed, 1, 0.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, playerPed, 2, 0.0)
        TriggerEvent("pNotify:SendNotification", {
            text = 'ยกเลิกเช็ตเลือดเหลืองแล้ว!',
            type = "success",
            timeout = 5000,
            layout = "topRight",
            queue = "left"
        })
        goldenCores = false
    end
end

function PerformRequest(hash)
    RequestModel(hash, 0)
    local bacon = 1
    while not Citizen.InvokeNative(0x1283B8B89DD5D1B6, hash) do
        Citizen.InvokeNative(0xFA28FE3A6246FC30, hash, 0)
        bacon = bacon + 1
        Citizen.Wait(0)
        if bacon >= 100 then
            break
        end
    end
end

function SetMonModel(name)
    local model = GetHashKey(name)
    local player = PlayerId()

    if not IsModelValid(model) then
        return
    end
    PerformRequest(model)

    if HasModelLoaded(model) then
        Citizen.InvokeNative(0xED40380076A31506, player, model, false)
        Citizen.InvokeNative(0x283978A15512B2FE, PlayerPedId(), true)
        SetModelAsNoLongerNeeded(model)
    end
end

local IsAnimal = false
local IsAttacking = false

RegisterNetEvent("MJ-attack:attack")

function SetControlContext(pad, context)
    Citizen.InvokeNative(0x2804658EB7D8A50B, pad, context)
end

function GetPedCrouchMovement(ped)
    return Citizen.InvokeNative(0xD5FE956C70FF370B, ped)
end

function SetPedCrouchMovement(ped, state, immediately)
    Citizen.InvokeNative(0x7DE9692C6F64CFE8, ped, state, immediately)
end

function PlayAnimation(anim)
    if not DoesAnimDictExist(anim.dict) then
        print("Invalid animation dictionary: " .. anim.dict)
        return
    end

    RequestAnimDict(anim.dict)

    while not HasAnimDictLoaded(anim.dict) do
        Citizen.Wait(0)
    end

    TaskPlayAnim(PlayerPedId(), anim.dict, anim.name, 4.0, 4.0, -1, 0, 0.0, false, false, false, "", false)

    RemoveAnimDict(anim.dict)
end

function IsPvpEnabled()
    return GetRelationshipBetweenGroups(PLAYER, PLAYER) == 5
end

function IsValidTarget(ped)
    return not IsPedDeadOrDying(ped) and not (IsPedAPlayer(ped) and not IsPvpEnabled())
end

function GetClosestPed(playerPed, radius)
    local playerCoords = GetEntityCoords(playerPed)

    local itemset = CreateItemset(true)
    local size = Citizen.InvokeNative(0x59B57C4B06531E1E, playerCoords, radius, itemset, 1, Citizen.ResultAsInteger())

    local closestPed
    local minDist = radius

    if size > 0 then
        for i = 0, size - 1 do
            local ped = GetIndexedItemInItemset(i, itemset)

            if playerPed ~= ped and IsValidTarget(ped) then
                local pedCoords = GetEntityCoords(ped)
                local distance = #(playerCoords - pedCoords)

                if distance < minDist then
                    closestPed = ped
                    minDist = distance
                end
            end
        end
    end

    if IsItemsetValid(itemset) then
        DestroyItemset(itemset)
    end

    return closestPed
end

function MakeEntityFaceEntity(entity1, entity2)
    local p1 = GetEntityCoords(entity1)
    local p2 = GetEntityCoords(entity2)

    local dx = p2.x - p1.x
    local dy = p2.y - p1.y

    local heading = GetHeadingFromVector_2d(dx, dy)

    SetEntityHeading(entity1, heading)
end

function GetAttackType(playerPed)
    local playerModel = GetEntityModel(playerPed)

    for _, attackType in ipairs(Config.AttackTypes) do
        for _, model in ipairs(attackType.models) do
            if playerModel == model then
                return attackType
            end
        end
    end
end

function ApplyAttackToTarget(attacker, target, attackType)
    if attackType.force > 0 then
        SetPedToRagdoll(target, 1000, 1000, 0, 0, 0, 0)
        SetEntityVelocity(target, GetEntityForwardVector(attacker) * attackType.force)
    end

    if attackType.damage > 0 then
        ApplyDamageToPed(target, attackType.damage, 1, -1, 0)
    end
end

function GetPlayerServerIdFromPed(ped)
    for _, player in ipairs(GetActivePlayers()) do
        if GetPlayerPed(player) == ped then
            return GetPlayerServerId(player)
        end
    end
end

function Attack()
    if IsAttacking then
        return
    end

    local playerPed = PlayerPedId()

    if IsPedDeadOrDying(playerPed) or IsPedRagdoll(playerPed) then
        return
    end

    local attackType = GetAttackType(playerPed)

    if attackType then
        local target = GetClosestPed(playerPed, attackType.radius)

        if target then
            IsAttacking = true

            MakeEntityFaceEntity(playerPed, target)

            PlayAnimation(attackType.animation)

            if IsPedAPlayer(target) then
                TriggerServerEvent("MJ-attack:attack", GetPlayerServerIdFromPed(target), -1)
            elseif NetworkGetEntityIsNetworked(target) and not NetworkHasControlOfEntity(target) then
                TriggerServerEvent("MJ-attack:attack", -1, PedToNet(target))
            else
                ApplyAttackToTarget(playerPed, target, attackType)
            end

            Citizen.SetTimeout(Config.AttackCooldown, function()
                IsAttacking = false
            end)
        end
    end
end

function ToggleCrouch()
    local playerPed = PlayerPedId()

    SetPedCrouchMovement(playerPed, not GetPedCrouchMovement(playerPed), true)
end

AddEventHandler("MJ-attack:attack", function(attacker, entity)
    local attackerPed = GetPlayerPed(GetPlayerFromServerId(attacker))
    local attackType = GetAttackType(attackerPed)

    if entity == -1 then
        if IsPvpEnabled() then
            ApplyAttackToTarget(attackerPed, PlayerPedId(), attackType)
        end
    else
        ApplyAttackToTarget(attackerPed, NetToPed(entity), attackType)
    end
end)

Citizen.CreateThread(function()
    local lastPed = 0

    while true do
        local ped = PlayerPedId()

        if ped ~= lastPed then
            if IsPedHuman(ped) then
                SetControlContext(2, 0)
                IsAnimal = false
            else

                SetPedConfigFlag(ped, 43, true)
                IsAnimal = true
            end

            lastPed = ped
        end

        Citizen.Wait(1000)
    end
end)

Citizen.CreateThread(function()
    while true do
        if IsAnimal then

            SetControlContext(2, OnMount)

            DisableFirstPersonCamThisFrame()

            if IsControlJustPressed(0, INPUT_ATTACK) then
                Attack()
            end

            if IsControlJustPressed(0, INPUT_HORSE_MELEE) then
                ToggleCrouch()
            end
        end

        Citizen.Wait(0)
    end
end)

-- Variables
local isPlayerIdsEnabled = false
local playerGamerTags = {}
local distanceToCheck = GetConvarInt('txAdmin-menuPlayerIdDistance', 150)

-- Game consts
local fivemGamerTagCompsEnum = {
    GamerName = 0,
    CrewTag = 1,
    HealthArmour = 2,
    BigText = 3,
    AudioIcon = 4,
    UsingMenu = 5,
    PassiveMode = 6,
    WantedStars = 7,
    Driver = 8,
    CoDriver = 9,
    Tagged = 12,
    GamerNameNearby = 13,
    Arrow = 14,
    Packages = 15,
    InvIfPedIsFollowing = 16,
    RankText = 17,
    Typing = 18
}

local redmGamerTagCompsEnum = {
    none = 0,
    icon = 1,
    simple = 2,
    complex = 3
}
local redmSpeakerIconHash = GetHashKey('SPEAKER')
local redmColorYellowHash = GetHashKey('COLOR_YELLOWSTRONG')

--- Removes all cached tags
local function cleanAllGamerTags()
    debugPrint('Cleaning up gamer tags table')
    for _, v in pairs(playerGamerTags) do
        if IsMpGamerTagActive(v.gamerTag) then
            Citizen.InvokeNative(0x839BFD7D7E49FE09, Citizen.PointerValueIntInitialized(v.gamerTag));
        end
    end
    playerGamerTags = {}
end

--- Draws a single gamer tag (redm)
local function setGamerTagRedm(targetTag, pid)
    Citizen.InvokeNative(0x93171DDDAB274EB8, targetTag, redmGamerTagCompsEnum.complex) -- SetMpGamerTagVisibility
    if MumbleIsPlayerTalking(pid) then
        Citizen.InvokeNative(0x95384C6CE1526EFF, targetTag, redmSpeakerIconHash) -- SetMpGamerTagSecondaryIcon
        Citizen.InvokeNative(0x84BD27DDF9575816, targetTag, redmColorYellowHash) -- SetMpGamerTagColour
    else
        Citizen.InvokeNative(0x95384C6CE1526EFF, targetTag, nil) -- SetMpGamerTagSecondaryIcon
        Citizen.InvokeNative(0x84BD27DDF9575816, targetTag, 0) -- SetMpGamerTagColour
    end
end

--- Clears a single gamer tag (redm)
local function clearGamerTagRedm(targetTag)
    Citizen.InvokeNative(0x93171DDDAB274EB8, targetTag, redmGamerTagCompsEnum.none) -- SetMpGamerTagVisibility
end

--- Setting game-specific functions
local setGamerTagFunc = setGamerTagRedm
local clearGamerTagFunc = clearGamerTagRedm

--- Loops through every player, checks distance and draws or hides the tag
local function showGamerTags()
    local curCoords = GetEntityCoords(PlayerPedId())
    -- Per infinity this will only return players within 300m
    local allActivePlayers = GetActivePlayers()

    for _, pid in ipairs(allActivePlayers) do
        -- Resolving player
        local targetPed = GetPlayerPed(pid)

        -- If we have not yet indexed this player or their tag has somehow dissapeared (pause, etc)
        if not playerGamerTags[pid] or not IsMpGamerTagActive(playerGamerTags[pid].gamerTag) then
            local playerName = string.sub(GetPlayerName(pid) or "unknown", 1, 75)
            local playerStr = '[' .. GetPlayerServerId(pid) .. ']' .. ' ' .. playerName
            playerGamerTags[pid] = {
                gamerTag = CreateFakeMpGamerTag(targetPed, playerStr, false, false, 0),
                ped = targetPed
            }
        end
        local targetTag = playerGamerTags[pid].gamerTag

        -- Distance Check
        local targetPedCoords = GetEntityCoords(targetPed)
        if #(targetPedCoords - curCoords) <= distanceToCheck then
            setGamerTagFunc(targetTag, pid)
        else
            clearGamerTagFunc(targetTag)
        end
    end
end

--- Starts the gamer tag thread
--- Increasing/decreasing the delay realistically only reflects on the 
--- delay for the VOIP indicator icon, 250 is fine
local function createGamerTagThread()
    debugPrint('Starting gamer tag thread')
    CreateThread(function()
        while isPlayerIdsEnabled do
            showGamerTags()
            Wait(250)
        end

        -- Remove all gamer tags and clear out active table
        cleanAllGamerTags()
    end)
end

--- Function to enable or disable the player ids
function toggleShowPlayerIDs(enabled, showNotification)
    isPlayerIdsEnabled = enabled
    local snackMessage
    if isPlayerIdsEnabled then
        snackMessage = 'เปิด - แสดงชื่อ'
        createGamerTagThread()
    else
        snackMessage = 'ปิด - แสดงชื่อ'
    end

    if showNotification then
        notification(snackMessage, "e")
        --[[      sendSnackbarMessage('info', snackMessage, true) ]]
    end
    debugPrint('Show Player IDs Status: ' .. tostring(isPlayerIdsEnabled))
end

--- Receives the return from the server and toggles player ids on/off
RegisterNetEvent('MJ-DEV:showPlayerIDs', function(enabled)
    toggleShowPlayerIDs(enabled, true)
end)

function debugPrint(a)
    print(a)
end
