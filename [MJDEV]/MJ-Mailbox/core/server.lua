local VORPcore = exports.vorp_core:GetCore()
local VorpInv = exports.vorp_inventory:vorp_inventoryApi()
local json = require("json")
local mailboxFile = "data/mailboxes.json"
local messagesFile = "data/messages.json"
local contactFile = "data/contacts.json"

local function ensureFileExists(filePath)
    local content = LoadResourceFile(GetCurrentResourceName(), filePath)
    if not content or content == "" then
        SaveResourceFile(GetCurrentResourceName(), filePath, json.encode({}, {
            indent = true
        }), -1)
        print("^2[mailbox]^7 สร้างไฟล์ " .. filePath)
    end
end

local function readMailboxData()
    local content = LoadResourceFile(GetCurrentResourceName(), mailboxFile)
    if not content or content == "" then
        return {}
    end
    local ok, data = pcall(json.decode, content)
    if ok and type(data) == "table" then
        return data
    end
    return {}
end

local function writeMailboxData(data)
    local encoded = json.encode(data, {
        indent = true
    })
    return SaveResourceFile(GetCurrentResourceName(), mailboxFile, encoded, -1)
end

local function readMessages()
    ensureFileExists(messagesFile)
    local content = LoadResourceFile(GetCurrentResourceName(), messagesFile)
    if not content or content == "" then
        return {}
    end
    local ok, data = pcall(json.decode, content)
    if ok and type(data) == "table" then
        return data
    end
    return {}
end

local function writeMessages(data)
    local encoded = json.encode(data, {
        indent = true
    })
    return SaveResourceFile(GetCurrentResourceName(), messagesFile, encoded, -1)
end

-- โหลดข้อมูลจากไฟล์
local function loadContacts()
    local file = LoadResourceFile(GetCurrentResourceName(), contactFile)
    if file then
        return json.decode(file)
    else
        return {}
    end
end

-- บันทึกข้อมูลไปยังไฟล์
local function saveContacts(data)
    SaveResourceFile(GetCurrentResourceName(), contactFile, json.encode(data, {
        indent = true
    }), -1)
end

local function generateUniqueMailID(mailboxes)
    local function isUnique(id)
        for _, v in pairs(mailboxes) do
            if v.mailID == id then
                return false
            end
        end
        return true
    end

    local id
    repeat
        id = math.random(100, 999)
    until isUnique(id)
    return id
end

local function getOrCreateMailboxID(steamID, name)
    local mailboxes = readMailboxData()
    if mailboxes[steamID] then
        return mailboxes[steamID].mailID
    else
        local newID = generateUniqueMailID(mailboxes)
        mailboxes[steamID] = {
            name = name,
            mailID = newID
        }
        writeMailboxData(mailboxes)
        return newID
    end
end

local function getSteamIDByName(name)
    local mailboxes = readMailboxData()
    for steamID, data in pairs(mailboxes) do
        if data.name == name then
            return steamID
        end
    end
    return nil
end

local function getSourceFromSteamID(steamID)
    for _, playerId in ipairs(GetPlayers()) do
        if GetPlayerIdentifiers(playerId)[1] == steamID then
            return tonumber(playerId)
        end
    end
    return nil
end

-- ใช้เพิ่มข้อความใหม่ โดยส่ง newMessage เข้าไปเพิ่มใน allMessages[receiverSteamID]
local function addMessage(receiverSteamID, newMessage)
    local allMessages = readMessages()
    if not allMessages[receiverSteamID] then
        allMessages[receiverSteamID] = {}
    end
    table.insert(allMessages[receiverSteamID], newMessage)
    writeMessages(allMessages)
end

local function getNextMessageId(messages)
    local maxId = 0
    for _, msg in ipairs(messages) do
        local id = tonumber(msg.id) or 0
        if id > maxId then
            maxId = id
        end
    end
    return maxId + 1
end

-- Helper สำหรับดึง identifier
local function getIdentifier(src)
    local identifiers = GetPlayerIdentifiers(src)
    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, 6) == "steam:" then
            return id
        end
    end
    return "unknown"
end

local function getSteamIDByMailID(ID)
    local mailboxes = readMailboxData()
    for steamID, data in pairs(mailboxes) do
        print("ID:", ID, type(ID))
        print("data.mailID:", data.mailID, type(data.mailID))
        if tostring(data.mailID) == tostring(ID) then
            return steamID, data.name
        end
    end
    return nil, nil
end

RegisterServerEvent("mailbox:saveContact")
AddEventHandler("mailbox:saveContact", function(name, mailID)
    local src = source
    local identifier = getIdentifier(src)
    local steamID, playerName = getSteamIDByMailID(mailID)
    if not steamID or steamID == "" then
        TriggerClientEvent("mailbox:notify", src,
            "ไม่พบผู้เล่นที่มี Mail ID นี้")
        return
    end

    local contacts = loadContacts()
    contacts[identifier] = contacts[identifier] or {}

    -- Check duplicates
    for _, contact in ipairs(contacts[identifier]) do
        if contact.steamID == steamID or contact.contactId == mailID then
            TriggerClientEvent("mailbox:notify", src,
                "ผู้ติดต่อมีอยู่แล้วในรายชื่อของคุณ")
            return
        end
    end

    table.insert(contacts[identifier], {
        name = name,
        contactId = mailID,
        steamID = steamID,
        addedBy = identifier,
        timestamp = os.date("%Y-%m-%d %H:%M:%S")
    })

    saveContacts(contacts)
    TriggerClientEvent("mailbox:notify", src,
        "เพิ่มผู้ติดต่อเรียบร้อยแล้ว")
end)

-- ส่งรายชื่อกลับให้ client
RegisterServerEvent("mailbox:getMyContacts")
AddEventHandler("mailbox:getMyContacts", function()
    local src = source
    local identifier = getIdentifier(src)

    local contacts = loadContacts()
    local myContacts = contacts[identifier] or {}

    TriggerClientEvent("mailbox:sendMyContacts", src, myContacts)
end)

-- Server event
RegisterServerEvent("mailbox:getUserInfo")
AddEventHandler("mailbox:getUserInfo", function()
    local src = source
    local user = VORPcore.getUser(src)
    if not user then
        return
    end
    local character = user.getUsedCharacter
    if not character then
        return
    end

    local steamID = GetPlayerIdentifiers(src)[1]
    local name = character.firstname .. " " .. character.lastname
    local mailID = getOrCreateMailboxID(steamID, name)

    TriggerClientEvent("mailbox:receiveUserInfo", src, {
        firstname = name,
        mailCode = mailID
    })
end)

RegisterServerEvent("mailbox:loadMessages")
AddEventHandler("mailbox:loadMessages", function()
    local src = source
    local steamID = GetPlayerIdentifiers(src)[1]

    local allMessages = readMessages()
    local messages = allMessages[steamID] or {}

    TriggerClientEvent("mailbox:loadMessagesResult", src, messages)
end)

RegisterServerEvent("mailbox:sendMessage")
AddEventHandler("mailbox:sendMessage", function(data)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then
        TriggerClientEvent("mailbox:notify", src, "❌ ไม่พบผู้เล่นนี้")
        return
    end

    local character = user.getUsedCharacter
    if not character then
        TriggerClientEvent("mailbox:notify", src, "❌ ไม่พบตัวละคร")
        return
    end

    local senderName = character.firstname .. " " .. character.lastname
    local senderId = user.identifier

    local receiverSteamID = getSteamIDByName(data.receiverName)
    if not receiverSteamID then
        TriggerClientEvent("mailbox:notify", src, "❌ ไม่พบผู้รับ")
        return
    end

    -- if receiverSteamID == GetPlayerIdentifiers(src)[1] then
    --     TriggerClientEvent("mailbox:notify", src, "❌ คุณไม่สามารถส่งข้อความหาตัวเองได้")
    --     return
    -- end

    local allMessages = readMessages()
    allMessages[receiverSteamID] = allMessages[receiverSteamID] or {}

    local newMessage = {
        id = getNextMessageId(allMessages[receiverSteamID]),
        sender = senderName,
        sender_id = senderId,
        subject = data.subject or "",
        mailID = data.mailID or "",
        receiver = receiverSteamID,
        message = data.message or "",
        coords = data.coords or nil,
        item = data.item or nil,
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        isRead = false -- ✅ เพิ่มบรรทัดนี้
    }

    addMessage(receiverSteamID, newMessage) -- Ensure this updates and saves properly

    local targetPlayerSource = getSourceFromSteamID(receiverSteamID)
    if targetPlayerSource and data.item then
        VorpInv.addItem(targetPlayerSource, data.item.name, data.item.count or 1)
    end

    if targetPlayerSource then
       local unreadCount = 0
        for _, msg in ipairs(allMessages[receiverSteamID]) do
            if msg.isRead == false then
                unreadCount = unreadCount + 1
            end
        end

        TriggerClientEvent("mailbox:newMailNotify", targetPlayerSource, unreadCount)
        TriggerClientEvent("mailbox:loadMessagesResult", targetPlayerSource, allMessages[receiverSteamID])
    end

    TriggerClientEvent("mailbox:notify", targetPlayerSource, "📨 คุณมีข้อความใหม่กำลังเข้า")
    TriggerClientEvent("mailbox:notify", src, "📨 ส่งข้อความสำเร็จ")
end)

RegisterServerEvent("mailbox:markAsRead")
AddEventHandler("mailbox:markAsRead", function(messageId)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then 
        print("No user found")
        return 
    end

    local char = user.getUsedCharacter
    if not char then 
        print("No character found")
        return 
    end

    local steamID = char.identifier

    local allMessages = readMessages()
    if not allMessages then
        print("readMessages returned nil")
        return
    end

    local messages = allMessages[steamID] or {}

    local changed = false
    for _, msg in ipairs(messages) do
        if tonumber(msg.id) == tonumber(messageId) and msg.isRead == false then
            msg.isRead = true
            changed = true
            break
        end
    end

    if changed then
        writeMessages(allMessages)
    else
        print("No message matched or already read")
    end

    -- Count unread messages
    local unreadCount = 0
    for _, msg in ipairs(messages) do
        if msg.isRead == false then
            unreadCount = unreadCount + 1
        end
    end
    TriggerClientEvent("mailbox:newMailNotify", src, unreadCount)
end)

RegisterServerEvent("mailbox:deleteMessage")
AddEventHandler("mailbox:deleteMessage", function(id)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then
        return
    end
    local character = user.getUsedCharacter
    if not character then
        return
    end
    local steamID = GetPlayerIdentifiers(src)[1]

    local allMessages = readMessages()
    local messages = allMessages[steamID] or {}

    local idNum = tonumber(id)
    local indexToRemove = nil
    for i, msg in ipairs(messages) do
        if tonumber(msg.id) == idNum and msg.receiver == steamID then
            indexToRemove = i
            break
        end
    end

    if indexToRemove then
        table.remove(messages, indexToRemove)
        allMessages[steamID] = messages
        writeMessages(allMessages)
        TriggerClientEvent("mailbox:loadMessagesResult", src, messages)
        TriggerClientEvent("mailbox:notify", src, "🗑️ ลบข้อความสำเร็จ")
    else
        TriggerClientEvent("mailbox:notify", src,
            "❌ ไม่พบข้อความหรือไม่มีสิทธิ์ลบ")
    end
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        ensureFileExists(mailboxFile)
        ensureFileExists(messagesFile)
        ensureFileExists(contactFile)
        math.randomseed(os.time())
    end
end)

Citizen.CreateThread(function()
    Citizen.Wait(3000)
    print("##################################################")
    print("##                                              ##")
    print("##           \27[37mMJ DEV | Verify \27[32mSuccess\27[0m            ##")
    print("##           \27[36mThank You For Purchase\27[0m             ##")
    print("##           \27[34mVersion : 1.0 (Latest)\27[0m             ##")
    print("##                                              ##")
    print("##################################################")
    print("###### \27[36mDiscord: https://discord.gg/gHRNMDQKzb\27[0m ####")
end)

function DumpTable(tbl, depth)
    depth = depth or 0
    if depth > 5 then
        return "{...}"
    end -- Prevent infinite recursion

    if type(tbl) == "table" then
        local s = "{\n"
        local indent = string.rep("    ", depth + 1)

        for k, v in pairs(tbl) do
            local key = type(k) == "number" and k or '"' .. tostring(k) .. '"'
            s = s .. indent .. "[" .. key .. "] = " .. DumpTable(v, depth + 1) .. ",\n"
        end

        return s .. string.rep("    ", depth) .. "}"
    else
        return tostring(tbl)
    end
end
