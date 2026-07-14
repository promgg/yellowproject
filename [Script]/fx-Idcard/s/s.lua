local CREATE_TABLE_SQL = [[
CREATE TABLE IF NOT EXISTS `fx_idcard` (
    `charid` varchar(64) NOT NULL,
    `data` longtext NOT NULL,
    `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`charid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
]]

local sessions = {}
local processing = {}
local cooldowns = {}
local selectCooldowns = {} -- แยกจาก cooldowns (openService) กัน selectService สแปม getSteamAvatar ระหว่าง session 60 วิ
local resetting = false

local function notify(src, key, substitutions, notificationType)
    Notify({
        source = src,
        text = Locale(key, substitutions),
        type = notificationType or "error",
        time = 5000,
    })
end

local function trim(value)
    if type(value) ~= "string" then return "" end
    return value:match("^%s*(.-)%s*$") or ""
end

local function isPrivateIPv4(host)
    local a, b = host:match("^(%d+)%.(%d+)%.%d+%.%d+$")
    a, b = tonumber(a), tonumber(b)
    if not a then return false end

    return a == 0
        or a == 10
        or a == 127
        or (a == 169 and b == 254)
        or (a == 172 and b >= 16 and b <= 31)
        or (a == 192 and b == 168)
end

local function validateImageUrl(value)
    local url = trim(value)
    if url == "" then return Config.Image.allowEmpty, "" end
    if #url > Config.Image.maxLength then return false end
    if not url:lower():match("^https://") then return false end

    local authority = url:match("^https://([^/%?#]+)")
    if not authority or authority:find("@", 1, true) then return false end
    if authority:sub(1, 1) == "[" then return false end

    local host = authority:match("^([^:]+)")
    host = host and host:lower() or ""
    if host == "" or host == "localhost" then return false end
    if host:match("%.localhost$") or host:match("%.local$") or host:match("%.internal$") then return false end
    if isPrivateIPv4(host) then return false end

    return true, url
end

local function decodeCard(row)
    if not row or type(row.data) ~= "string" then return nil end
    local ok, data = pcall(json.decode, row.data)
    return ok and type(data) == "table" and data or nil
end

local function getCard(charid)
    local ok, row = pcall(
        MySQL.single.await,
        "SELECT `data` FROM `fx_idcard` WHERE `charid` = ? LIMIT 1",
        { tostring(charid) }
    )
    return ok and decodeCard(row) or nil
end

local function setCard(charid, data, insertOnly)
    local query
    if insertOnly then
        query = "INSERT INTO `fx_idcard` (`charid`, `data`) VALUES (?, ?)"
    else
        query = "UPDATE `fx_idcard` SET `data` = ? WHERE `charid` = ?"
    end

    local ok, result
    if insertOnly then
        ok, result = pcall(MySQL.insert.await, query, { tostring(charid), json.encode(data) })
    else
        ok, result = pcall(MySQL.update.await, query, { json.encode(data), tostring(charid) })
    end

    return ok and result ~= nil
end

local function getSteam64(src)
    local identifier = GetPlayerIdentifierByType(src, "steam")
    if not identifier then return nil end

    local steamHex = identifier:gsub("steam:", "")
    local steam64 = tonumber(steamHex, 16)
    return steam64 and tostring(steam64) or nil
end

local function getSteamAvatar(src)
    local apiKey = GetConvar("steam_webApiKey", "")
    local steam64 = getSteam64(src)
    if apiKey == "" or not steam64 then return nil end

    local deferred = promise.new()
    local completed = false
    local endpoint = ("https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=%s&steamids=%s")
        :format(apiKey, steam64)

    PerformHttpRequest(endpoint, function(statusCode, body)
        if completed then return end
        completed = true

        if statusCode ~= 200 or not body then
            deferred:resolve(nil)
            return
        end

        local ok, response = pcall(json.decode, body)
        local players = ok and response and response.response and response.response.players
        local player = players and players[1]
        deferred:resolve(player and (player.avatarfull or player.avatarmedium or player.avatar) or nil)
    end, "GET", "", { ["Content-Type"] = "application/json" })

    SetTimeout(5000, function()
        if completed then return end
        completed = true
        deferred:resolve(nil)
    end)

    return Citizen.Await(deferred)
end

local function getCharacterInformation(src, charid)
    local deferred = promise.new()
    FXGetCharacterInformations(src, charid, function(data)
        deferred:resolve(data or {})
    end)
    return Citizen.Await(deferred)
end

local function formatHeight(scale)
    local value = tonumber(scale) or 1.0
    local heights = {
        { 0.85, "4'8" }, { 0.90, "4'9" }, { 0.95, "4'10" },
        { 1.00, "5'0" }, { 1.05, "5'1" }, { 1.10, "5'2" },
    }
    local closest = heights[1]

    for _, entry in ipairs(heights) do
        if math.abs(value - entry[1]) < math.abs(value - closest[1]) then
            closest = entry
        end
    end

    return closest[2]
end

local function buildOfficialData(src, city, avatarUrl)
    local character = FXGetPlayerData(src)
    if not character or not character.charIdentifier then return nil end

    local info = getCharacterInformation(src, character.charIdentifier)
    local age = math.max(0, math.floor(tonumber(info.age) or 0))
    local birthYear = math.max(1800, math.min(1899, 1899 - age))
    local sex = info.sex == "Female" and "Female" or "Male"

    return {
        name = trim((info.firstname or character.firstname or "") .. " " .. (info.lastname or character.lastname or "")),
        cityname = city,
        country = Config.CountryName,
        age = age,
        date = ("%04d-01-01"):format(birthYear),
        height = formatHeight(info.height),
        weight = ("%dKG"):format(math.floor(tonumber(info.weight) or 0)),
        sex = sex,
        charid = tostring(character.charIdentifier),
        img = avatarUrl or "",
    }
end

local function isNearOffice(src, city)
    local office = Config.IDCardNPC[city]
    if not office then return false end

    local ped = GetPlayerPed(src)
    if not ped or ped <= 0 then return false end

    local playerCoords = GetEntityCoords(ped)
    local officeCoords = vector3(office.coords.x, office.coords.y, office.coords.z)
    return #(playerCoords - officeCoords) <= Config.ServerInteractionDistance
end

local function createToken(src)
    return ("%s:%s:%s"):format(src, os.time(), math.random(100000, 999999))
end

local function validSession(src, token)
    local session = sessions[src]
    if not session or session.token ~= token or session.expiresAt < os.time() then
        sessions[src] = nil
        notify(src, "invalidSession")
        return nil
    end

    local character = FXGetPlayerData(src)
    if not character or tostring(character.charIdentifier) ~= session.charid then
        sessions[src] = nil
        notify(src, "invalidSession")
        return nil
    end

    if not isNearOffice(src, session.city) then
        notify(src, "tooFar")
        return nil
    end

    return session
end

local function takePayment(src, amount)
    if amount <= 0 then return true end
    if not FXHaveMoney(src, "cash", amount) then
        notify(src, "noMoney", { money = amount })
        return false
    end

    FXRemoveMoney(src, "cash", amount)
    return true
end

local function cardItemName(card)
    return card.sex == "Female" and Config.Items.female or Config.Items.male
end

local function addCardItem(src, card)
    local metadata = {
        description = Locale("cardDescription", { name = card.name, charid = card.charid }),
        cardCharId = tostring(card.charid),
        CardData = { charid = tostring(card.charid) },
    }

    return FXAddItem(src, cardItemName(card), 1, metadata)
end

-- "ออกบัตรใหม่" มีไว้สำหรับตอนบัตรเก่าหายจริงเท่านั้น เช็คว่า on-hand inventory ยังมีใบเดิมอยู่ไหม
-- ก่อนอนุญาต (เช็คแค่กระเป๋าที่ถืออยู่ ไม่ได้ไล่ stash/trunk อื่นๆ — ครอบคลุมพอสำหรับเคสนี้)
local function hasPhysicalCard(src, card)
    local count = FXGetItemCount(src, cardItemName(card), { cardCharId = tostring(card.charid) })
    return (tonumber(count) or 0) > 0
end

function FXIDCardLog(action, src, card, price, extra)
    -- print เสมอไม่ว่าจะตั้ง webhook ไว้หรือไม่ — ไม่งั้น action สำคัญของแอดมิน (ลบ/รีเซ็ตทั้งหมด)
    -- จะไม่เหลือร่องรอยอะไรเลยถ้าไม่ได้ตั้งค่า Discord ไว้ (ค่า default คือไม่ตั้ง)
    print(("[fx-idcard] action=%s player=%s(src=%s) charid=%s office=%s fee=$%s%s"):format(
        tostring(action),
        src == 0 and "Console" or (GetPlayerName(src) or "Unknown"),
        tostring(src),
        card and tostring(card.charid or "-") or "-",
        card and tostring(card.cityname or "-") or "-",
        tostring(price or 0),
        extra and (" detail=" .. tostring(extra):sub(1, 200)) or ""
    ))

    local webhook = GetConvar("fx_idcard_webhook", Config.DiscordWebhook or "")
    if webhook == "" then return end

    local fields = {
        { name = "Action", value = tostring(action), inline = true },
        { name = "Player", value = src == 0 and "Console" or (GetPlayerName(src) or "Unknown"), inline = true },
        { name = "Server ID", value = tostring(src), inline = true },
        { name = "Character ID", value = card and tostring(card.charid or "-") or "-", inline = true },
        { name = "Office", value = card and tostring(card.cityname or "-") or "-", inline = true },
        { name = "Fee", value = ("$%s"):format(price or 0), inline = true },
    }

    if extra then
        fields[#fields + 1] = { name = "Details", value = tostring(extra):sub(1, 1000), inline = false }
    end

    local embed = {
        title = "Identity Card Log",
        color = 11176004,
        fields = fields,
        footer = { text = os.date("!%Y-%m-%d %H:%M:%S UTC") },
    }

    if card and card.img and card.img ~= "" then
        embed.thumbnail = { url = card.img }
    end

    PerformHttpRequest(webhook, function() end, "POST", json.encode({
        username = Config.DiscordBotName,
        embeds = { embed },
    }), { ["Content-Type"] = "application/json" })
end

local function finishService(src, messageKey, card, price, logAction)
    sessions[src] = nil
    processing[src] = nil
    TriggerClientEvent("fx-idcard:client:closeService", src)
    notify(src, messageKey, nil, "success")
    FXIDCardLog(logAction, src, card, price)
end

local function issueReplacement(src, session)
    if processing[src] then
        notify(src, "serviceBusy")
        return
    end

    processing[src] = true
    local card = getCard(session.charid)
    if not card then
        processing[src] = nil
        notify(src, "noCard")
        return
    end

    -- เช็คซ้ำฝั่งเซิร์ฟ ไม่พึ่งแค่สถานะตอนเปิดเมนู (client อาจ stale หรือถูกแก้) กันซื้อ replacement ทั้งที่บัตรเดิมยังอยู่
    if hasPhysicalCard(src, card) then
        processing[src] = nil
        notify(src, "stillHaveCard")
        return
    end

    local price = Config.Prices.replacement
    if not takePayment(src, price) then
        processing[src] = nil
        return
    end

    local addOk, added = pcall(addCardItem, src, card)
    if not addOk or added == false then
        FXAddMoney(src, "cash", price)
        processing[src] = nil
        notify(src, "inventoryFull")
        return
    end

    finishService(src, "replacementSuccess", card, price, "replacement")
end

RegisterNetEvent("fx-idcard:server:openService", function(city)
    local src = source
    if resetting then return notify(src, "serviceBusy") end
    if processing[src] then return notify(src, "serviceBusy") end
    local now = GetGameTimer()
    if cooldowns[src] and now - cooldowns[src] < 3000 then return end
    cooldowns[src] = now
    if type(city) ~= "string" or not Config.IDCardNPC[city] or not isNearOffice(src, city) then
        return notify(src, "tooFar")
    end

    local character = FXGetPlayerData(src)
    if not character or not character.charIdentifier then return notify(src, "noCharacter") end
    processing[src] = true

    local charid = tostring(character.charIdentifier)
    local token = createToken(src)
    local card = getCard(charid)

    sessions[src] = {
        token = token,
        city = city,
        charid = charid,
        expiresAt = os.time() + Config.SessionTimeout,
    }

    if card then
        processing[src] = nil
        TriggerClientEvent("fx-idcard:client:openServiceMenu", src, {
            token = token,
            card = card,
            hasPhysicalCard = hasPhysicalCard(src, card),
            prices = {
                changePhoto = Config.Prices.changePhoto,
                replacement = Config.Prices.replacement,
            },
        })
        return
    end

    local avatar = getSteamAvatar(src)
    local officialData = buildOfficialData(src, city, avatar)
    if not officialData then
        sessions[src] = nil
        processing[src] = nil
        return notify(src, "noCharacter")
    end

    sessions[src].action = "create"
    sessions[src].officialData = officialData
    sessions[src].steamAvatar = avatar or ""
    processing[src] = nil

    TriggerClientEvent("fx-idcard:client:openCardForm", src, {
        token = token,
        mode = "create",
        price = Config.Prices.create,
        card = officialData,
        steamAvatar = avatar or "",
    })
end)

RegisterNetEvent("fx-idcard:server:selectService", function(token, service)
    local src = source
    local session = validSession(src, token)
    if not session then return end

    -- session token อยู่ได้ 60 วิ (Config.SessionTimeout) — ไม่มี cooldown ตรงนี้ client ยิงรัวได้ทั้ง session
    -- ทั้งที่ change_photo ยิง PerformHttpRequest ไป Steam API ทุกครั้ง
    local now = GetGameTimer()
    if selectCooldowns[src] and now - selectCooldowns[src] < 2000 then return end
    selectCooldowns[src] = now

    if service == "replacement" then
        issueReplacement(src, session)
        return
    end

    if service ~= "change_photo" then return end

    if processing[src] then return notify(src, "serviceBusy") end
    processing[src] = true

    local card = getCard(session.charid)
    if not card then
        processing[src] = nil
        return notify(src, "noCard")
    end

    local avatar = getSteamAvatar(src)
    session.action = "change_photo"
    session.steamAvatar = avatar or ""
    processing[src] = nil

    TriggerClientEvent("fx-idcard:client:openCardForm", src, {
        token = token,
        mode = "change_photo",
        price = Config.Prices.changePhoto,
        card = card,
        steamAvatar = avatar or "",
    })
end)

RegisterNetEvent("fx-idcard:server:submitCard", function(token, imageUrl)
    local src = source
    if processing[src] then return notify(src, "serviceBusy") end

    local session = validSession(src, token)
    if not session or (session.action ~= "create" and session.action ~= "change_photo") then return end

    local validImage, normalizedImage = validateImageUrl(imageUrl)
    if not validImage then return notify(src, "invalidImage") end

    processing[src] = true

    if session.action == "create" then
        if getCard(session.charid) then
            processing[src] = nil
            return notify(src, "alreadyCard")
        end

        local price = Config.Prices.create
        if not takePayment(src, price) then
            processing[src] = nil
            return
        end

        local card = session.officialData
        card.img = normalizedImage
        card.issuedAt = os.time()
        card.updatedAt = card.issuedAt

        if not setCard(session.charid, card, true) then
            FXAddMoney(src, "cash", price)
            processing[src] = nil
            return notify(src, "databaseError")
        end

        local addOk, added = pcall(addCardItem, src, card)
        if not addOk or added == false then
            MySQL.update.await("DELETE FROM `fx_idcard` WHERE `charid` = ?", { session.charid })
            FXAddMoney(src, "cash", price)
            processing[src] = nil
            return notify(src, "inventoryFull")
        end

        finishService(src, "createSuccess", card, price, "created")
        return
    end

    local card = getCard(session.charid)
    if not card then
        processing[src] = nil
        return notify(src, "noCard")
    end

    if trim(card.img or "") == normalizedImage then
        processing[src] = nil
        return notify(src, "sameImage")
    end

    local price = Config.Prices.changePhoto
    if not takePayment(src, price) then
        processing[src] = nil
        return
    end

    card.img = normalizedImage
    card.updatedAt = os.time()

    if not setCard(session.charid, card, false) then
        FXAddMoney(src, "cash", price)
        processing[src] = nil
        return notify(src, "databaseError")
    end

    finishService(src, "photoSuccess", card, price, "photo_changed")
end)

RegisterNetEvent("fx-idcard:server:closeSession", function()
    sessions[source] = nil
end)

local function showCardToNearby(src, card)
    local sourcePed = GetPlayerPed(src)
    if not sourcePed or sourcePed <= 0 then return end

    local sourceCoords = GetEntityCoords(sourcePed)
    local sourceBucket = GetPlayerRoutingBucket(src)

    for _, playerId in ipairs(GetPlayers()) do
        local target = tonumber(playerId)
        if target and GetPlayerRoutingBucket(target) == sourceBucket then
            local targetPed = GetPlayerPed(target)
            if targetPed and targetPed > 0 then
                local distance = #(sourceCoords - GetEntityCoords(targetPed))
                if target == src or distance <= Config.ShowDistance then
                    TriggerClientEvent("fx-idcard:client:previewCard", target, card)
                end
            end
        end
    end
end

local function useCardItem(itemData)
    local src = itemData.source
    local metadata = itemData.item and itemData.item.metadata or {}
    if type(metadata) == "string" then
        local ok, decoded = pcall(json.decode, metadata)
        metadata = ok and decoded or {}
    end
    if type(metadata) ~= "table" then metadata = {} end

    local legacyData = metadata.CardData or {}
    if type(legacyData) == "string" then
        local ok, decoded = pcall(json.decode, legacyData)
        legacyData = ok and decoded or {}
    end
    if type(legacyData) ~= "table" then legacyData = {} end
    local cardCharId = metadata.cardCharId or legacyData.charid

    FXCloseInventory(src)

    if not cardCharId then return notify(src, "noCard") end
    local card = getCard(cardCharId)
    if not card then return notify(src, "noCard") end

    showCardToNearby(src, card)
end

FXRegisterUsableItem(Config.Items.male, useCardItem)
FXRegisterUsableItem(Config.Items.female, useCardItem)

function FXIDCardResetAll(src)
    if resetting then return false, "busy" end
    resetting = true

    local ok = pcall(function()
        MySQL.query.await("DROP TABLE IF EXISTS `fx_idcard`")
        MySQL.query.await(CREATE_TABLE_SQL)
    end)

    if ok then
        sessions = {}
        processing = {}
        for _, playerId in ipairs(GetPlayers()) do
            TriggerClientEvent("fx-idcard:client:closeService", tonumber(playerId))
        end
        FXIDCardLog("reset_all", src, nil, 0, "All identity records were deleted")
    end

    resetting = false
    return ok
end

function FXIDCardDeleteTarget(src, target)
    local character = FXGetPlayerData(target)
    if not character or not character.charIdentifier then return false end

    local charid = tostring(character.charIdentifier)
    local card = getCard(charid)
    local affected = MySQL.update.await("DELETE FROM `fx_idcard` WHERE `charid` = ?", { charid })
    if affected and affected > 0 then
        FXIDCardLog("deleted", src, card or { charid = charid }, 0, "Target server ID: " .. target)
        return true
    end

    return false
end

AddEventHandler("playerDropped", function()
    sessions[source] = nil
    processing[source] = nil
    cooldowns[source] = nil
    selectCooldowns[source] = nil
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    MySQL.query.await(CREATE_TABLE_SQL)
end)
