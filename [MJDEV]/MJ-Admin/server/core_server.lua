local script = 'MJ-Admin'
local maxPing = 1000  -- ตัวอย่าง: 1000ms หรือ 1 วินาที
itemList = {}
admin = admin or {}
cachedPlayers = cachedPlayers or {}  -- ✅ ใช้ได้ เพราะอาจมีค่ามาก่อน
Updateblip = Updateblip or {}
Updateblip_count = 0
playerRanks = {}

local function normalizeGroup(group)
    if type(group) ~= 'string' then
        return nil
    end

    group = group:lower():gsub('^%s+', ''):gsub('%s+$', '')
    if group == '' then
        return nil
    end

    return group
end

local function getUserGroup(user)
    local group = user and user.getGroup
    if type(group) == 'function' then
        local ok, value = pcall(group)
        group = ok and value or nil
    end

    return normalizeGroup(group)
end

local function getCharacterGroup(character)
    return normalizeGroup(character and character.group)
end

local function groupHasAdminPerms(group)
    return group ~= nil and Config and Config["Perms"] and Config["Perms"][group] ~= nil
end

function admin.GetUsedCharacter(user)
    local character = user and user.getUsedCharacter or nil
    if type(character) == 'function' then
        character = character()
    end

    return character
end

function admin.GetPlayerGroup(source, user, character)
    user = user or VORPcore.getUser(source)
    character = character or admin.GetUsedCharacter(user)

    local userGroup = getUserGroup(user)
    local characterGroup = getCharacterGroup(character)
    local effectiveGroup = characterGroup or userGroup or 'user'

    if groupHasAdminPerms(userGroup) then
        effectiveGroup = userGroup
    elseif groupHasAdminPerms(characterGroup) then
        effectiveGroup = characterGroup
    end

    if groupHasAdminPerms(effectiveGroup)
        and character
        and characterGroup ~= effectiveGroup
        and type(character.setGroup) == 'function'
    then
        pcall(character.setGroup, effectiveGroup, false)
    end

    return effectiveGroup, character, userGroup, characterGroup
end

-- ===== ONLINE HELPERS (ใหม่) =====
local function currentOnline()
    return #GetPlayers()
end

local function pushOnlineAll()
    TriggerClientEvent('MJADMIN:SetOnline', -1, currentOnline())
end

CreateThread(function()
    while true do
        Wait(10000)  -- ตรวจสอบทุกๆ 10 วินาที
        for _, playerId in ipairs(GetPlayers()) do
            local ping = GetPlayerPing(playerId)
            -- ถ้า ping เกินค่าที่กำหนดจะเตะผู้เล่นออก
            if ping > maxPing then
                DropPlayer(playerId, "Your ping is too high. You have been disconnected.")
            end
        end
    end
end)

MySQL.ready(function()
    MySQL.Async.fetchAll('SELECT * FROM items', {}, function(result)
		for _, db_item in pairs(result or {}) do
			if db_item.id then
				itemList[db_item.item] = {
					id = db_item.id,
					item = db_item.item,
					label = db_item.label,
					type = db_item.type,
				}
			end
		end
	end)
end)

VORPcore.addRpcCallback("MJADMIN:TeleportSpectate", function(source, cb, targetId)
    local ped = GetPlayerPed(targetId)
    if ped and ped ~= 0 then
        local coords = GetEntityCoords(ped)
        -- ส่งเป็นตาราง ปลอดภัยกว่า vector3 โดยตรง
        TriggerClientEvent("MJADMIN:setCoords", source, { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 })
        cb(true)
    else
        cb(false)
    end
end)

VORPcore.addRpcCallback("admin:fetchUserRank", function(source, cb)
    local group = admin.GetPlayerGroup(source)
    cb(group)
end)

RegisterNetEvent("MJADMIN:RequestPlayerRank")
AddEventHandler("MJADMIN:RequestPlayerRank", function()
    local _source = source
    local user = VORPcore.getUser(_source)
    if user then
        local effectiveGroup, character = admin.GetPlayerGroup(_source, user)
        if character then
            TriggerClientEvent("MJADMIN:SendPlayerRank", _source, effectiveGroup)
        end
    end
end)

RegisterNetEvent("MJADMIN:RequestItemList")
AddEventHandler("MJADMIN:RequestItemList", function()
    local _source = source
    TriggerClientEvent("MJADMIN:updateItemList", _source, itemList, Config and Config['LsitWeapons'], Config and Config['LsitWagons'], Config and Config['SETJOB'])
end)

-- เมื่อผู้เล่นเชื่อมต่อ ขอรายการผู้เล่น
RegisterNetEvent('MJADMIN:getPlayers')
AddEventHandler('MJADMIN:getPlayers', function()
    local src = source
    local xPlayers = GetPlayers()

    for i = 1, #xPlayers do
        local PlayerID = tonumber(xPlayers[i])
        local user = VORPcore.getUser(PlayerID)

        if not user then
            print("MJADMIN: User data not found for player " .. PlayerID)
        end

        local character = user and user.getUsedCharacter or nil
        if type(character) == 'function' then character = character() end -- เรียกใช้งานเป็นฟังก์ชันถ้าเป็นฟังก์ชัน

        if not character then
            print("MJADMIN: Character data not found for player " .. PlayerID)
        end

        TriggerClientEvent("MJADMIN:UpdatePlayer", src, PlayerID, cachedPlayers[PlayerID] or {})
    end

    -- ✅ ส่งจำนวนออนไลน์สดให้คนที่เรียก
    TriggerClientEvent('MJADMIN:SetOnline', src, currentOnline())
end)

-- เมื่อผู้เล่นเลือกตัวละคร (เข้าจริง)
AddEventHandler("vorp:SelectedCharacter", function(source)
    local src = tonumber(source) -- แปลงเป็นตัวเลขเพื่อป้องกันข้อผิดพลาด
    local user = VORPcore.getUser(src)

    if not user then
        print("MJADMIN: User data not found for player " .. src)
        return
    end

    local effectiveGroup, character = admin.GetPlayerGroup(src, user)
    if not character then
        print("MJADMIN: Character data not found for player " .. src)
        return
    end

    -- Ensure data safety
    local firstname = character.firstname or "/"
    local lastname = character.lastname or "/"
    local cash = character.money or 0
    local bank = character.gold or 0
    local job = character.job and (character.job .. " | " .. (character.jobLabel or character.job)) or "No Job"

    -- Store player data in cache (❌ ไม่เก็บ online)
    cachedPlayers[src] = {
        identifier = character.identifier,
        playerid = tonumber(src),
        group = effectiveGroup,
        rpname = firstname .. " " .. lastname,
        name = firstname .. " | " .. lastname,
        cash = cash,
        bank = bank,
        job = job
    }

    -- Broadcast รายชื่อผู้เล่นคนนี้ให้ทุก client
    TriggerClientEvent("MJADMIN:UpdatePlayer", -1, src, cachedPlayers[src])

    -- ✅ อัปเดตจำนวนออนไลน์สดให้ทุกคน
    pushOnlineAll()

    -- อัปเดต UI เฉพาะคนนี้
    TriggerClientEvent("MJADMIN:updatePlayerRank", src, effectiveGroup)
    TriggerClientEvent("MJADMIN:updateItemList", src, itemList)
    print("MJADMIN: Updated player data for " .. src)
end)

-- เรียกเก็บข้อมูลของผู้เล่นตอน (re)start เพื่อ bootstrap cache
CreateThread(function()
    local xPlayers = GetPlayers()
    for _, player in ipairs(xPlayers) do
        local src = tonumber(player) -- แปลงเป็นตัวเลขเพื่อป้องกันข้อผิดพลาด
        local user = VORPcore.getUser(src)
        if not user then
            print("MJADMIN: User data not found for player " .. src)
        else
            local effectiveGroup, character = admin.GetPlayerGroup(src, user)
            if not character then
                print("MJADMIN: Character data not found for player " .. src)
            else
                local firstname = character.firstname or '/'
                local lastname = character.lastname or '/'
                local cash = character.money or 0
                local bank = character.gold or 0
                local job = character.job and (character.job .. " | " .. (character.jobLabel or character.job)) or "No Job"
                
                -- Store player data in cache (❌ ไม่เก็บ online)
                cachedPlayers[src] = {
                    identifier = character.identifier,
                    playerid = tonumber(src),
                    group = effectiveGroup,
                    rpname = firstname .. " " .. lastname,
                    cash = cash,
                    bank = bank,
                    job = job,
                    name = firstname .. " | " .. lastname
                }

                TriggerClientEvent('MJADMIN:updatePlayerRank', src, effectiveGroup)
                TriggerClientEvent("MJADMIN:updateItemList", src, itemList)
                TriggerClientEvent("MJADMIN:UpdatePlayer", -1, src, cachedPlayers[src] or {})
                print("Character data found for player " .. src)
            end
        end
    end

    -- ✅ อัปเดตตัวเลขออนไลน์สดให้ทุกคนหลังบูต
    pushOnlineAll()
end)

AddEventHandler('playerDropped', function(reason)
    local src = tonumber(source) -- แปลงเป็นตัวเลขเพื่อป้องกันข้อผิดพลาด

    -- ลบข้อมูลผู้เล่นออกจาก cachedPlayers
    if cachedPlayers[src] then
        cachedPlayers[src] = nil
        print("MJADMIN: Removed player " .. src .. " from cachedPlayers.")
    end

    -- ลบข้อมูลผู้เล่นออกจาก Updateblip
    if Updateblip[src] then
        Updateblip[src] = nil
        print("MJADMIN: Removed player " .. src .. " from Updateblip.")
    end

    -- Notify all clients to remove this player from their UI list/cache
    TriggerClientEvent("MJADMIN:RemovePlayer", -1, src)

    -- อัปเดตข้อมูลให้กับทุก Client ที่เหลืออยู่
    for key, _ in pairs(cachedPlayers) do
        TriggerClientEvent("MJADMIN:UpdatePlayer", key, key, cachedPlayers[key])
    end    

    for key, _ in pairs(Updateblip) do
        TriggerClientEvent("admin:removeUser", key, src)
    end

    -- ✅ อัปเดตจำนวนออนไลน์สดหลังคนหลุด
    pushOnlineAll()

    print("MJADMIN: Player " .. src .. " cleanup completed.")
end)

-- ให้ client ขอเลขออนไลน์เองได้ (เวลาหน้า UI รีเฟรช)
RegisterNetEvent('MJADMIN:RequestOnlineCount')
AddEventHandler('MJADMIN:RequestOnlineCount', function()
    TriggerClientEvent('MJADMIN:SetOnline', source, currentOnline())
end)

Citizen.CreateThread(function()
    Citizen.Wait(5000) 
    print("##################################################")
    print("##                                              ##")
    print("##           \27[37mMJ DEV | Verify \27[32mSuccess\27[0m            ##")
    print("##           \27[36mThank You For Purchase\27[0m             ##")
    print("##           \27[34mVersion : 1.0 (Latest)\27[0m             ##")
    print("##                                              ##")
    print("##################################################")
    print("###### \27[36mDiscord: https://discord.gg/gHRNMDQKzb\27[0m ####")
    if GetCurrentResourceName() ~= script then
        os.exit()
    end
end)
