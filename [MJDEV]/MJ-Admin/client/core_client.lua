local script = 'MJ-Admin'
playerRank = "user"  -- เก็บค่าเริ่มต้นที่ฝั่ง client

-- ===== CACHES =====
cachedPlayers = cachedPlayers or {}
cachedItemList = cachedItemList or {}
cachedWeaponList = cachedWeaponList or {}
cachedVehicleList = cachedVehicleList or {}
cachedJobList = cachedJobList or {}

-- ===== STATE =====
admin = admin or {}          -- กัน error: attempt to index a nil value (global 'admin')
local display = display or false
local onlineCount = 0        -- เลขออนไลน์แบบสด มาจากเซิร์ฟเวอร์

-- ===== RANK ACCESSOR =====
local function getPlayerRank()
    return playerRank
end

-- ===== LOGIN / SPAWN =====
local function requestAdminBootstrap()
    print("Requesting player rank, item list, players & online count from server...")
    TriggerServerEvent("MJADMIN:RequestPlayerRank")
    TriggerServerEvent("MJADMIN:RequestItemList")
    TriggerServerEvent("MJADMIN:getPlayers")
    TriggerServerEvent("MJADMIN:RequestOnlineCount")
end

RegisterNetEvent("vorp:SelectedCharacter", function()
    Citizen.Wait(2000)
    requestAdminBootstrap()
    TriggerServerEvent("MJADMIN:RequestOnlineCount") -- ขอเลขออนไลน์ทันทีตอนเข้า
end)

-- ===== TELEPORT HANDLER (ต้องมี เพราะเซิร์ฟยิง MJADMIN:setCoords) =====
CreateThread(function()
    Citizen.Wait(5000)
    requestAdminBootstrap()
end)

RegisterNetEvent("MJADMIN:setCoords")
AddEventHandler("MJADMIN:setCoords", function(coords)
    local ped = PlayerPedId()
    if coords and coords.x and coords.y and coords.z then
        SetEntityCoords(ped, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, false, false, false, true)
    end
end)

-- ===== RANK HANDLERS =====
RegisterNetEvent("MJADMIN:SendPlayerRank")
AddEventHandler("MJADMIN:SendPlayerRank", function(rank)
    print("Received player rank from server:", rank)
    playerRank = rank
end)

RegisterNetEvent('MJADMIN:updatePlayerRank')
AddEventHandler('MJADMIN:updatePlayerRank', function(rank)
    print('Updating Rank .....')
    playerRank = rank
end)

-- ===== ONLINE COUNT (ใหม่) =====
RegisterNetEvent('MJADMIN:SetOnline')
AddEventHandler('MJADMIN:SetOnline', function(count)
    onlineCount = tonumber(count) or 0
    -- ส่งให้ NUI (แยกเมสเสจ ไม่ผูกกับรายการผู้เล่น)
    SendNUIMessage({ type = "online", value = onlineCount })
end)

-- คำสั่งทดสอบขอเลขออนไลน์สดเอง
RegisterCommand('mjadmin_online', function()
    TriggerServerEvent('MJADMIN:RequestOnlineCount')
end, false)

-- ===== PLAYERS LIST =====
RegisterNetEvent("MJADMIN:UpdatePlayer")
AddEventHandler("MJADMIN:UpdatePlayer", function(key, data)
    print('Updating Players...')
    cachedPlayers[tonumber(key)] = data
    if display and admin.GetPlayers then
        admin.GetPlayers()
    end
end)

RegisterNetEvent("MJADMIN:RemovePlayer")
AddEventHandler("MJADMIN:RemovePlayer", function(playerId)
    local id = tonumber(playerId)
    if id and cachedPlayers[id] then
        cachedPlayers[id] = nil
        print(("Removed player %s from cachedPlayers"):format(id))
        if display and admin.GetPlayers then
            admin.GetPlayers()
        end
    end
end)

-- ===== ITEMS / LISTS =====
RegisterNetEvent("MJADMIN:updateItemList")
AddEventHandler("MJADMIN:updateItemList", function(itemList, weaponList, vehicleList, jobList)
    print('Updating Item List...')

    -- ใช้ค่าที่ส่งมาจากเซิร์ฟก่อน ถ้าไม่มีค่อย fallback ไปที่ Config
    cachedItemList    = itemList    or cachedItemList    or {}
    cachedWeaponList  = weaponList  or (Config and Config['LsitWeapons']) or cachedWeaponList or {}
    cachedVehicleList = vehicleList or (Config and Config['LsitWagons'])  or cachedVehicleList or {}
    cachedJobList     = jobList     or (Config and Config['SETJOB'])      or cachedJobList or {}

    SendNUIMessage({
        type       = "items",
        itemslist  = cachedItemList,
        weaponlist = cachedWeaponList,
        vehiclelist= cachedVehicleList,
        joblist    = cachedJobList
    })
end)

-- ===== OPEN ADMIN MENU =====
RegisterCommand('adminmenu', function()
    local Rank = getPlayerRank()
    if Rank == "admin" then
        if display then return end -- กันเปิดซ้ำ
        -- ขอข้อมูลล่าสุด
        TriggerServerEvent("MJADMIN:getPlayers")
        TriggerServerEvent("MJADMIN:RequestOnlineCount")

        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local head = GetEntityHeading(playerPed)

        SendNUIMessage({
            type = "coords",
            coordData = coords,
            heading = head
        })

        if admin.GetPlayers then admin.GetPlayers() end
        SetDisplay(true)
        noclipAllow = true
    else
        print("Access Denied: You are not an admin.")
    end
end, false)

-- ===== QUICK RESKIN =====
RegisterCommand('reskin', function()
    TriggerEvent("MJDev:reskin")
end, false)

-- ===== BUILD TABLE FOR NUI (เลิกพึ่ง v.online) =====
admin.GetPlayers = function()
    local Admin_data = {}
    for k, v in pairs(cachedPlayers) do
        if type(v) == "table" then
            table.insert(Admin_data, {
                online = onlineCount,        -- ❌ ไม่ใช้แล้ว
                identifier = v.identifier or "N/A",
                playerid   = tonumber(v.playerid) or tonumber(k) or 0,
                group      = v.group or "Unknown",
                name       = v.name or "Unknown",
                rpname     = v.rpname or "Unknown",
                cash       = tonumber(v.cash) or 0,
                bank       = tonumber(v.bank) or 0,
                job        = v.job or "Unemployed"
            })
        end
    end

    table.sort(Admin_data, function(a, b)
        return (a.playerid or 0) < (b.playerid or 0)
    end)

    -- ส่งเลขออนไลน์เป็นฟิลด์ท็อปเลเวล แยกจากข้อมูลรายแถว
    SendNUIMessage({
        type = "MJ-Data",
        data = Admin_data,
    })
end

-- ===== NUI DISPLAY TOGGLE =====
function SetDisplay(bool)
    if display == bool then return end
    display = bool

    SendNUIMessage({
        type = "MJDEV-ADMIN",
        status = bool
    })

    SetNuiFocus(bool, bool)
end

-- ===== BOOT BANNER (แก้คอมเมนต์ให้ตรงเป็น 5 วินาที) =====
Citizen.CreateThread(function()
    Citizen.Wait(5000) -- 5 seconds
    if GetCurrentResourceName() ~= script then
        return
    end
    print("##################################################")
    print("##                                              ##")
    print("##           MJ DEV | Verify Success            ##")
    print("##           Thank You For Purchase             ##")
    print("##           Version : 1.0 (Latest)             ##")
    print("##                                              ##")
    print("##################################################")
    print("###### Discord: https://discord.gg/gHRNMDQKzb ####")
end)
