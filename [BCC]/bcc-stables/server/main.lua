local Core = exports.vorp_core:GetCore()
local BccUtils = exports['bcc-utils'].initiate()
local CooldownData = {}
local DevModeActive = Config.devMode
local ActionLocks = {}
local RateLimits = {}
local ReviveAuthorizations = {}
local SoldWildEntities = {}
local PendingTames = {}
local TradeOffers = {}
local CoreGainCredits = {}
local XpActionCredits = {}
local TravelXpState = {}

local COMPONENT_CATEGORIES = {
    'Saddles', 'Saddlecloths', 'Stirrups', 'SaddleBags', 'Manes', 'Tails',
    'SaddleHorns', 'Bedrolls', 'Masks', 'Mustaches', 'Holsters', 'Bridles', 'Horseshoes'
}

local function getCharacter(src)
    local user = Core.getUser(src)
    return user and user.getUsedCharacter or nil
end

local function isTrainer(character)
    if not character then return false end
    for _, job in ipairs(Config.trainerJob or {}) do
        if character.job == job.name and tonumber(character.jobGrade or 0) >= tonumber(job.grade or 0) then
            return true
        end
    end
    return false
end

local function maxHorsesFor(character)
    return isTrainer(character) and tonumber(Config.maxTrainerHorses) or tonumber(Config.maxPlayerHorses)
end

local function horseSlotCount(character)
    if not character then return 0 end
    if Config.death.permanent then
        return MySQL.scalar.await('SELECT COUNT(*) FROM `player_horses` WHERE `charid` = ? AND `identifier` = ? AND `dead` = 0',
            { character.charIdentifier, character.identifier }) or 0
    end
    return MySQL.scalar.await('SELECT COUNT(*) FROM `player_horses` WHERE `charid` = ? AND `identifier` = ?',
        { character.charIdentifier, character.identifier }) or 0
end

local function findHorseConfig(model)
    if type(model) ~= 'string' then return nil end
    for _, horseCfg in ipairs(Horses or {}) do
        if horseCfg.colors and horseCfg.colors[model] then
            return horseCfg.colors[model], horseCfg
        end
    end
    return nil
end

local function cleanHorseName(value)
    if type(value) ~= 'string' then return nil end
    local name = value:gsub('^%s+', ''):gsub('%s+$', ''):gsub('[%c<>]', '')
    local ok, length = pcall(utf8.len, name)
    if not ok or not length or length < 1 or length > 30 then return nil end
    return name
end

local function normalizeHash(value)
    if value == 0 or value == '0' then return 0 end
    local number = tonumber(value)
    if not number or number <= 0 or number > 0xffffffff then return nil end
    return ('0x%08X'):format(number)
end

local function decodeComponents(value)
    local decoded = value
    if type(value) == 'string' then
        local ok, result = pcall(json.decode, value)
        if not ok or type(result) ~= 'table' then return {} end
        decoded = result
    end
    if type(decoded) ~= 'table' then return {} end

    local normalized = {}
    for index, category in ipairs(COMPONENT_CATEGORIES) do
        local raw = decoded[category]
        if raw == nil then raw = decoded[index] end
        local hash = normalizeHash(raw)
        if hash then normalized[category] = hash end
    end
    return normalized
end

local function componentOption(category, requestedHash)
    local hash = normalizeHash(requestedHash)
    if hash == 0 then return { hash = 0, cashPrice = 0, goldPrice = 0 } end
    if not hash or not HorseComp or type(HorseComp[category]) ~= 'table' then return nil end
    for _, option in ipairs(HorseComp[category]) do
        if normalizeHash(option.hash) == hash then
            return { hash = hash, cashPrice = tonumber(option.cashPrice) or 0, goldPrice = tonumber(option.goldPrice) or 0 }
        end
    end
    return nil
end

local function hasSaddlebags(components)
    local hash = components and components.SaddleBags
    return hash ~= nil and hash ~= 0 and componentOption('SaddleBags', hash) ~= nil
end

local function beginLock(key)
    local now = GetGameTimer()
    if ActionLocks[key] and ActionLocks[key] > now then return false end
    ActionLocks[key] = now + 15000
    return true
end

local function endLock(key)
    ActionLocks[key] = nil
end

local function isRateLimited(src, action, milliseconds)
    local key = ('%s:%s'):format(src, action)
    local now = GetGameTimer()
    if RateLimits[key] and now - RateLimits[key] < milliseconds then return true end
    RateLimits[key] = now
    return false
end

local function horseOwnerRow(character, horseId, columns)
    horseId = tonumber(horseId)
    if not character or not horseId then return nil end
    local selectedColumns = columns or '`id`, `model`, `components`, `dead`, `writhe`, `selected`, `captured`, `health`, `stamina`, `name`, `gender`, `xp`'
    return MySQL.single.await(('SELECT %s FROM `player_horses` WHERE `id` = ? AND `charid` = ? AND `identifier` = ? LIMIT 1'):format(selectedColumns),
        { horseId, character.charIdentifier, character.identifier })
end

local function coreCreditKey(character, horseId)
    return ('%s:%s:%s'):format(character.identifier, character.charIdentifier, horseId)
end

local function grantCoreGain(character, horseId, health, stamina)
    local key = coreCreditKey(character, horseId)
    local expires = GetGameTimer() + 15000
    CoreGainCredits[key] = {
        health = math.max(0, tonumber(health) or 0),
        stamina = math.max(0, tonumber(stamina) or 0),
        expires = expires,
    }
    SetTimeout(16000, function()
        if CoreGainCredits[key] and CoreGainCredits[key].expires == expires then CoreGainCredits[key] = nil end
    end)
end

local function grantXpAction(character, horseId, action)
    local key = coreCreditKey(character, horseId)
    local expires = GetGameTimer() + 15000
    XpActionCredits[key] = { action = action, expires = expires }
    SetTimeout(16000, function()
        if XpActionCredits[key] and XpActionCredits[key].expires == expires then XpActionCredits[key] = nil end
    end)
end

local function horseCargoHasContents(horseId)
    local inventoryId = 'horse_' .. tostring(horseId)
    local itemCount = MySQL.scalar.await('SELECT COALESCE(SUM(`amount`), 0) FROM `character_inventories` WHERE `inventory_type` = ?', { inventoryId }) or 0
    local weaponCount = MySQL.scalar.await('SELECT COUNT(*) FROM `loadout` WHERE `curr_inv` = ?', { inventoryId }) or 0
    return tonumber(itemCount) > 0 or tonumber(weaponCount) > 0
end

local function validateNearbyHorse(src, netId, modelName, maxDistance)
    netId = tonumber(netId)
    local modelCfg = findHorseConfig(modelName)
    if not netId or not modelCfg then return nil end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 or not DoesEntityExist(entity) or GetEntityType(entity) ~= 1 then return nil end
    if GetEntityModel(entity) ~= joaat(modelName) then return nil end
    local playerPed = GetPlayerPed(src)
    if playerPed == 0 or #(GetEntityCoords(playerPed) - GetEntityCoords(entity)) > (maxDistance or 6.0) then return nil end
    return entity
end

local function findNearbyOwnedHorseEntity(src, horseId, maxDistance)
    local playerPed = GetPlayerPed(src)
    if playerPed == 0 then return nil end
    local playerCoords = GetEntityCoords(playerPed)
    for _, ped in ipairs(GetAllPeds()) do
        local state = Entity(ped).state
        if tonumber(state and state.myHorseId) == tonumber(horseId)
            and #(playerCoords - GetEntityCoords(ped)) <= (maxDistance or 8.0) then
            return ped
        end
    end
    return nil
end

local function findOwnedHorseEntity(horseId)
    for _, ped in ipairs(GetAllPeds()) do
        local state = Entity(ped).state
        if tonumber(state and state.myHorseId) == tonumber(horseId) then return ped end
    end
    return nil
end

local function isPlayerNearStable(src, site)
    local siteCfg = type(site) == 'string' and Stables[site] or nil
    local stableCoords = siteCfg and siteCfg.npc and siteCfg.npc.coords
    local playerPed = GetPlayerPed(src)
    if not stableCoords or playerPed == 0 or not DoesEntityExist(playerPed) then return false end
    local playerCoords = GetEntityCoords(playerPed)
    local allowedDistance = math.max(tonumber(siteCfg.shop and siteCfg.shop.distance) or 3.0, 10.0)
    return #(playerCoords - stableCoords) <= allowedDistance
end

local function jobListAllows(character, jobs)
    if type(jobs) ~= 'table' or #jobs == 0 then return true end
    for _, entry in ipairs(jobs) do
        if type(entry) == 'string' and character.job == entry then return true end
        if type(entry) == 'table' and character.job == entry.name
            and tonumber(character.jobGrade or 0) >= tonumber(entry.grade or 0) then return true end
    end
    return false
end

local function validateStableAction(src, character, site, model, purchasing)
    local siteCfg = type(site) == 'string' and Stables[site] or nil
    if not siteCfg or not isPlayerNearStable(src, site) then return false, 'stable_distance' end
    local shop = siteCfg.shop or {}
    if shop.jobsEnabled and not jobListAllows(character, shop.jobs) then return false, 'job' end
    local hours = shop.hours or {}
    if hours.active then
        local hasClock, hour = pcall(GetClockHours)
        if hasClock then
            local openHour, closeHour = tonumber(hours.open) or 0, tonumber(hours.close) or 24
            local closed = openHour < closeHour and (hour < openHour or hour >= closeHour)
                or openHour >= closeHour and (hour < openHour and hour >= closeHour)
            if closed then return false, 'closed' end
        end
    end
    if purchasing and siteCfg.trainerBuy and not isTrainer(character) then return false, 'trainer_only' end
    if purchasing and model then
        local colorCfg = findHorseConfig(model)
        if not colorCfg or not jobListAllows(character, colorCfg.job) then return false, 'model_access' end
    end
    return true
end

local function DebugPrint(message)
    if DevModeActive then
        print('^1[DEV MODE] ^4' .. message)
    end
end

if Config.discord.active == true then
    Discord = BccUtils.Discord.setup(Config.discord.webhookURL, Config.discord.title, Config.discord.avatar)
end

local function LogToDiscord(name, description, embeds)
    if Config.discord.active == true then
        Discord:sendMessage(name, description, embeds)
    end
end

local function SetPlayerCooldown(type, charid)
    CooldownData[type .. tostring(charid)] = os.time()
end

-- เช็คสิทธิ์แอดมิน (ACE) สำหรับคำสั่ง /stablecatalog — server เป็นเจ้าของสิทธิ์ ห้ามเชื่อ client
Core.Callback.Register('bcc-stables:CheckAdmin', function(source, cb)
    cb(IsPlayerAceAllowed(source, Config.adminAce or 'bcc-stables.admin') == true)
end)

Core.Callback.Register('bcc-stables:BuyHorse', function(source, cb, data)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local charid = character.charIdentifier
    local maxHorses = maxHorsesFor(character)

    if type(data) ~= 'table' or isRateLimited(src, 'buy_check', 750) then return cb(false) end
    local horseCount = horseSlotCount(character)
    if horseCount >= maxHorses then
        Core.NotifyRightTip(src, _U('horseLimit') .. maxHorses .. _U('horses'), 4000)
        return cb(false)
    end

    local model = data.ModelH
    local colorCfg = nil

    for _, horseCfg in pairs(Horses) do
        if horseCfg.colors[model] then
            colorCfg = horseCfg.colors[model]
            break
        end
    end

    if not colorCfg then
        DebugPrint('Horse model not found in the configuration: ' .. tostring(model))
        return cb(false)
    end
    local allowed = validateStableAction(src, character, data.site, model, true)
    if not allowed or data.IsCash ~= true then return cb(false) end

    if character.money >= colorCfg.cashPrice then
        cb(true)
    else
        Core.NotifyRightTip(src, _U('shortCash'), 4000)
        cb(false)
    end
end)

Core.Callback.Register('bcc-stables:RegisterHorse', function(source, cb, data)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local charid = character.charIdentifier

    local maxHorses = maxHorsesFor(character)

    if type(data) ~= 'table' or isRateLimited(src, 'register_check', 750) then return cb(false) end
    local horseCount = horseSlotCount(character)
    if horseCount >= maxHorses then
        Core.NotifyRightTip(src, _U('horseLimit') .. maxHorses .. _U('horses'), 4000)
        return cb(false)
    end

    local pending = PendingTames[src]
    local validToken = pending and pending.token == data.tameToken and pending.model == data.ModelH
        and pending.netId == tonumber(data.mountNetId) and pending.expires >= GetGameTimer()
    if not validToken or data.IsCash ~= true or data.origin ~= 'tameHorse' or character.money < Config.regCost then
        Core.NotifyRightTip(src, _U('shortCash'), 4000)
        return cb(false)
    end

    local entity = validateNearbyHorse(src, pending.netId, pending.model, 6.0)
    if not entity then return cb(false) end
    cb({ ok = true })
end)

Core.Callback.Register('bcc-stables:AuthorizeTamedHorse', function(source, cb, model, netId)
    local src = source
    if isRateLimited(src, 'authorize_tame', 1500) then return cb(false) end
    local entity = validateNearbyHorse(src, netId, model, 8.0)
    if not entity then return cb(false) end
    local token = ('%s:%s:%s'):format(src, GetGameTimer(), math.random(100000, 999999))
    PendingTames[src] = { token = token, model = model, netId = tonumber(netId), expires = GetGameTimer() + 60000 }
    cb({ ok = true, token = token })
end)

Core.Callback.Register('bcc-stables:BuyTack', function(source, cb, data)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    if type(data) ~= 'table' then return cb({ ok = false, reason = 'invalid' }) end
    if isRateLimited(src, 'tack', 750) then return cb({ ok = false, reason = 'processing' }) end
    local character = user.getUsedCharacter
    local horseId = tonumber(data.horseId)
    local changes = data.components
    if not horseId or type(changes) ~= 'table' then return cb({ ok = false, reason = 'invalid' }) end
    local stableAllowed, stableReason = validateStableAction(src, character, data.site, nil, false)
    if not stableAllowed then return cb({ ok = false, reason = stableReason }) end

    local lockKey = 'tack:' .. horseId
    if not beginLock(lockKey) then return cb({ ok = false, reason = 'processing' }) end

    local horse = horseOwnerRow(character, horseId, '`id`, `components`, `dead`')
    if not horse or tonumber(horse.dead) == 1 then
        endLock(lockKey)
        return cb({ ok = false, reason = 'unavailable' })
    end

    local components = decodeComponents(horse.components)
    local cashPrice, goldPrice = 0, 0
    for category, requested in pairs(changes) do
        local knownCategory = false
        for _, name in ipairs(COMPONENT_CATEGORIES) do
            if category == name then knownCategory = true break end
        end
        local option = knownCategory and componentOption(category, requested) or nil
        if not option then
            endLock(lockKey)
            return cb({ ok = false, reason = 'invalid_component' })
        end
        if components[category] ~= option.hash then
            components[category] = option.hash
            cashPrice = cashPrice + option.cashPrice
            goldPrice = goldPrice + option.goldPrice
        end
    end

    -- สีอุปกรณ์ (tack tint) — เก็บเป็นคีย์สงวน _tint ใน components JSON (ไม่ใช่ category จริง จึงไม่ผ่าน loop validate ด้านบน)
    -- ฟรี ไม่คิดเงิน. ส่ง nil = ไม่แตะสีเดิม / ส่ง table = ตั้งสีใหม่ (clamp 0-255 กันค่าเพี้ยนจาก client)
    if type(data.tackTint) == 'table' and tonumber(data.tackTint.t0) then
        local function clampTint(v) return math.max(0, math.min(255, math.floor(tonumber(v) or 255))) end
        components._tint = { t0 = clampTint(data.tackTint.t0), t1 = clampTint(data.tackTint.t1), t2 = clampTint(data.tackTint.t2) }
    end

    local currencyType = 0
    local price = cashPrice
    local balance = character.money
    if balance < price then
        endLock(lockKey)
        Core.NotifyRightTip(src, currencyType == 1 and _U('shortGold') or _U('shortCash'), 4000)
        return cb({ ok = false, reason = 'funds' })
    end

    local encoded = json.encode(components)
    if price > 0 then character.removeCurrency(currencyType, price) end
    local updated = MySQL.update.await('UPDATE `player_horses` SET `components` = ? WHERE `id` = ? AND `charid` = ? AND `identifier` = ? AND `dead` = 0',
        { encoded, horseId, character.charIdentifier, character.identifier })
    if updated ~= 1 then
        if price > 0 then character.addCurrency(currencyType, price) end
        endLock(lockKey)
        return cb({ ok = false, reason = 'database' })
    end
    endLock(lockKey)
    Core.NotifyRightTip(src, _U('purchaseSuccessful'), 4000)
    cb({ ok = true, components = encoded, price = price, currencyType = currencyType })
end)

Core.Callback.Register('bcc-stables:SaveNewHorse', function(source, cb, data)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    if type(data) ~= 'table' then return cb(false) end
    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier
    local name = cleanHorseName(data.name)
    local model = data.ModelH
    local gender = data.gender
    local captured = 0
    local isCash = data.IsCash == true
    local currencyType = 0
    local priceKey = 'cashPrice'
    local currency = character.money
    local notification = _U('shortCash')

    local colorCfg = findHorseConfig(model)
    local stableAllowed = validateStableAction(src, character, data.site, model, true)
    if not stableAllowed or not isCash or not colorCfg or not name or (gender ~= 'male' and gender ~= 'female') then return cb(false) end
    local lockKey = 'commerce:' .. src
    if not beginLock(lockKey) then return cb(false) end
    local horseCount = horseSlotCount(character)
    if horseCount >= maxHorsesFor(character) or currency < colorCfg[priceKey] then
        endLock(lockKey)
        Core.NotifyRightTip(src, horseCount >= maxHorsesFor(character) and (_U('horseLimit') .. maxHorsesFor(character) .. _U('horses')) or notification, 4000)
        return cb(false)
    end
    character.removeCurrency(currencyType, colorCfg[priceKey])
    local inserted = MySQL.insert.await('INSERT INTO `player_horses` (identifier, charid, name, model, gender, captured) VALUES (?, ?, ?, ?, ?, ?)',
        { identifier, charid, name, model, gender, captured })
    if not inserted then
        character.addCurrency(currencyType, colorCfg[priceKey])
        endLock(lockKey)
        return cb(false)
    end
    endLock(lockKey)
    LogToDiscord(charid, _U('discordHorsePurchased'))
    cb(true)
end)

Core.Callback.Register('bcc-stables:SaveTamedHorse', function(source, cb, data)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier
    local regCost = Config.regCost
    local name = cleanHorseName(data.name)
    local model = data.ModelH
    local gender = data.gender
    local pending = PendingTames[src]
    local validToken = pending and pending.token == data.tameToken and pending.model == model and pending.expires >= GetGameTimer()
    local entity = validToken and validateNearbyHorse(src, pending.netId, model, 6.0) or nil
    if not entity or not name or (gender ~= 'male' and gender ~= 'female') then return cb(false) end

    local lockKey = 'commerce:' .. src
    if not beginLock(lockKey) then return cb(false) end
    local horseCount = horseSlotCount(character)
    if horseCount >= maxHorsesFor(character) or character.money < regCost then
        endLock(lockKey)
        Core.NotifyRightTip(src, horseCount >= maxHorsesFor(character) and (_U('horseLimit') .. maxHorsesFor(character) .. _U('horses')) or _U('shortCash'), 4000)
        return cb(false)
    end
    character.removeCurrency(0, regCost)
    local inserted = MySQL.insert.await('INSERT INTO `player_horses` (identifier, charid, name, model, gender, captured) VALUES (?, ?, ?, ?, ?, ?)',
        { identifier, charid, name, model, gender, 1 })
    if not inserted then
        character.addCurrency(0, regCost)
        endLock(lockKey)
        return cb(false)
    end
    PendingTames[src] = nil
    endLock(lockKey)
    LogToDiscord(charid, _U('discordTamedPurchased'))
    cb(true)
end)

Core.Callback.Register('bcc-stables:UpdateHorseName', function(source, cb, data)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier
    local newName = cleanHorseName(data.name)
    local horseId = tonumber(data.horseId)
    if not newName or not horseId then return cb(false) end

    local updated = MySQL.update.await('UPDATE `player_horses` SET `name` = ? WHERE `id` = ? AND `identifier` = ? AND `charid` = ?',
    { newName, horseId, identifier, charid })

    cb(updated == 1)
end)

RegisterNetEvent('bcc-stables:UpdateHorseXp', function(Xp, horseId)
    DebugPrint(('Rejected deprecated client-authored XP update from %s for horse %s'):format(source, tostring(horseId)))
end)

Core.Callback.Register('bcc-stables:ApplyHorseXp', function(source, cb, horseId, action)
    local src = source
    local character = getCharacter(src)
    horseId = tonumber(horseId)
    local gains = {
        travel = tonumber(Config.horseXpPerCheck) or 0,
        brush = tonumber(Config.horseXpPerBrush) or 0,
        feed = tonumber(Config.horseXpPerFeed) or 0,
        drink = tonumber(Config.horseXpPerDrink) or 0,
    }
    local gain = type(action) == 'string' and gains[action] or nil
    if not character or not horseId or not gain or gain <= 0 or isRateLimited(src, 'apply_xp', 500) then return cb(false) end
    if Config.trainerOnly and not isTrainer(character) then return cb(false) end
    local horse = horseOwnerRow(character, horseId, '`id`, `xp`, `dead`, `writhe`')
    local entity = horse and findNearbyOwnedHorseEntity(src, horseId, 12.0) or nil
    if not horse or not entity or tonumber(horse.dead) == 1 or tonumber(horse.writhe) == 1 then return cb(false) end
    local key = coreCreditKey(character, horseId)
    if action == 'travel' then
        local coords = GetEntityCoords(entity)
        local state = TravelXpState[key]
        if not state or state.expires < GetGameTimer() then
            TravelXpState[key] = { coords = coords, expires = GetGameTimer() + 600000 }
            return cb(false)
        end
        if #(coords - state.coords) < (tonumber(Config.trainingDistance) or 50.0) then return cb(false) end
        TravelXpState[key] = { coords = coords, expires = GetGameTimer() + 600000 }
    else
        local credit = XpActionCredits[key]
        if not credit or credit.action ~= action or credit.expires < GetGameTimer() then return cb(false) end
        XpActionCredits[key] = nil
    end
    local lockKey = 'xp:' .. horseId
    if not beginLock(lockKey) then return cb(false) end
    local maxXp = tonumber(Config.maxHorseXp) or 1000
    local updated = MySQL.update.await('UPDATE `player_horses` SET `xp` = LEAST(`xp` + ?, ?) WHERE `id` = ? AND `identifier` = ? AND `charid` = ? AND `dead` = 0 AND `writhe` = 0',
        { math.floor(gain), maxXp, horseId, character.identifier, character.charIdentifier })
    if updated ~= 1 then endLock(lockKey) return cb(false) end
    local newXp = MySQL.scalar.await('SELECT `xp` FROM `player_horses` WHERE `id` = ? AND `identifier` = ? AND `charid` = ? LIMIT 1',
        { horseId, character.identifier, character.charIdentifier })
    endLock(lockKey)
    LogToDiscord(character.charIdentifier, _U('discordHorseXPGain'))
    cb({ ok = true, xp = tonumber(newXp) or 0 })
end)

local function saveHorseStats(src, health, stamina, id, applyRateLimit)
    local user = Core.getUser(src)
    if not user then return false end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier
    if applyRateLimit and isRateLimited(src, 'stats', 1500) then return false end
    local horseHealth = tonumber(health)
    local horseStamina = tonumber(stamina)
    local horseId = tonumber(id)
    if not horseHealth or not horseStamina or not horseId then return false end
    if not findNearbyOwnedHorseEntity(src, horseId, 250.0) then return false end
    horseHealth = math.max(0, math.min(100, math.floor(horseHealth)))
    horseStamina = math.max(0, math.min(100, math.floor(horseStamina)))
    local current = horseOwnerRow(character, horseId, '`id`, `health`, `stamina`, `dead`')
    local maxGain = tonumber(Config.maxHorseCoreGainPerSave) or 100
    if not current or tonumber(current.dead) == 1 then return false end
    local healthGain = math.max(0, horseHealth - tonumber(current.health or 0))
    local staminaGain = math.max(0, horseStamina - tonumber(current.stamina or 0))
    local creditKey = coreCreditKey(character, horseId)
    local credit = CoreGainCredits[creditKey]
    if healthGain > 0 or staminaGain > 0 then
        if not credit or credit.expires < GetGameTimer()
            or healthGain > math.min(maxGain, credit.health)
            or staminaGain > math.min(maxGain, credit.stamina) then return false end
    end

    local updated = MySQL.update.await('UPDATE `player_horses` SET `health` = ?, `stamina` = ? WHERE id = ? AND `identifier` = ? AND `charid` = ? AND `dead` = 0',
    { horseHealth, horseStamina, horseId, identifier, charid })
    if updated == 1 and credit then CoreGainCredits[creditKey] = nil end
    return updated == 1
end

RegisterNetEvent('bcc-stables:SaveHorseStatsToDb', function(health, stamina, id)
    saveHorseStats(source, health, stamina, id, true)
end)

Core.Callback.Register('bcc-stables:SaveHorseStatsChecked', function(source, cb, health, stamina, id)
    if isRateLimited(source, 'stats_checked', 250) then return cb(false) end
    cb(saveHorseStats(source, health, stamina, id, false))
end)

local function selectHorseForCharacter(character, horseId)
    horseId = tonumber(horseId)
    if not horseId then return false end
    local horse = horseOwnerRow(character, horseId)
    if not horse or tonumber(horse.dead) == 1 or tonumber(horse.writhe) == 1 then return false end
    local lockKey = ('select:%s:%s'):format(character.identifier, character.charIdentifier)
    if not beginLock(lockKey) then return false end
    local previousId = MySQL.scalar.await('SELECT `id` FROM `player_horses` WHERE `charid` = ? AND `identifier` = ? AND `selected` = 1 AND `dead` = 0 LIMIT 1',
        { character.charIdentifier, character.identifier })
    MySQL.update.await('UPDATE `player_horses` SET `selected` = 0 WHERE `charid` = ? AND `identifier` = ?',
        { character.charIdentifier, character.identifier })
    local updated = MySQL.update.await('UPDATE `player_horses` SET `selected` = 1 WHERE `id` = ? AND `charid` = ? AND `identifier` = ? AND `dead` = 0',
        { horseId, character.charIdentifier, character.identifier })
    if updated ~= 1 and previousId then
        MySQL.update.await('UPDATE `player_horses` SET `selected` = 1 WHERE `id` = ? AND `charid` = ? AND `identifier` = ? AND `dead` = 0',
            { previousId, character.charIdentifier, character.identifier })
    end
    endLock(lockKey)
    return updated == 1
end

RegisterNetEvent('bcc-stables:SelectHorse', function(data)
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    local character = user.getUsedCharacter
    if type(data) ~= 'table' or isRateLimited(src, 'select', 500) then return end
    selectHorseForCharacter(character, data.horseId)
end)

Core.Callback.Register('bcc-stables:SetSelectedHorse', function(source, cb, horseId)
    local character = getCharacter(source)
    if not character or isRateLimited(source, 'select_cb', 500) then return cb(false) end
    cb(selectHorseForCharacter(character, horseId))
end)

Core.Callback.Register('bcc-stables:SummonHorse', function(source, cb, horseId)
    local character = getCharacter(source)
    if not character or isRateLimited(source, 'summon', 1000) then return cb(false) end
    local horse = horseOwnerRow(character, horseId)
    if not horse or tonumber(horse.dead) == 1 or tonumber(horse.writhe) == 1 then return cb(false) end
    cb(horse)
end)

RegisterNetEvent('bcc-stables:SetHorseWrithe', function(horseId)
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    local character = user.getUsedCharacter
    horseId = tonumber(horseId)
    if not horseId or isRateLimited(src, 'writhe', 750) then return end
    local horse = horseOwnerRow(character, horseId, '`id`, `model`, `dead`')
    local entity = horse and findNearbyOwnedHorseEntity(src, horseId, 15.0) or nil
    if not horse or tonumber(horse.dead) == 1 or not entity or GetEntityModel(entity) ~= joaat(horse.model) then return end
    local identifier = character.identifier
    local charid = character.charIdentifier

    MySQL.update.await('UPDATE `player_horses` SET `writhe` = 1 WHERE `id` = ? AND `identifier` = ? AND `charid` = ? AND `dead` = 0',
    { tonumber(horseId), identifier, charid })
end)

-- Update Horse Selected and Dead Status After Death Event
RegisterNetEvent('bcc-stables:UpdateHorseStatus', function(horseId, action)
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier

    horseId = tonumber(horseId)
    if not horseId or isRateLimited(src, 'status', 750) then return end
    local horse = horseOwnerRow(character, horseId, '`id`, `dead`, `writhe`')
    if not horse then return end

    if action == 'dead' and tonumber(horse.dead) == 0 and (tonumber(horse.writhe) == 1 or Config.death.writheEnabled == false) then
        local updated = MySQL.update.await('UPDATE `player_horses` SET `selected` = 0, `writhe` = 0, `dead` = 1 WHERE `id` = ? AND `identifier` = ? AND `charid` = ? AND `dead` = 0',
            { horseId, identifier, charid })
        if updated == 1 then
            local replacementId = MySQL.scalar.await('SELECT `id` FROM `player_horses` WHERE `charid` = ? AND `identifier` = ? AND `dead` = 0 AND `writhe` = 0 ORDER BY `selected` DESC, `id` LIMIT 1',
                { charid, identifier })
            if replacementId then
                MySQL.update.await('UPDATE `player_horses` SET `selected` = 1 WHERE `id` = ? AND `charid` = ? AND `identifier` = ?',
                    { replacementId, charid, identifier })
            end
        end
    elseif action == 'revive' then
        local authorization = ReviveAuthorizations[src]
        if authorization and authorization.horseId == horseId and authorization.expires >= GetGameTimer() and tonumber(horse.writhe) == 1 then
            ReviveAuthorizations[src] = nil
            MySQL.update.await('UPDATE `player_horses` SET `selected` = 1, `writhe` = 0, `dead` = 0, `health` = ?, `stamina` = ? WHERE `id` = ? AND `identifier` = ? AND `charid` = ?',
                { Config.death.health, Config.death.stamina, horseId, identifier, charid })
        end
    elseif action == 'deselect' and tonumber(horse.dead) == 0 then
        MySQL.update.await('UPDATE `player_horses` SET `selected` = 0, `writhe` = 0 WHERE `id` = ? AND `identifier` = ? AND `charid` = ?',
            { horseId, identifier, charid })
    end
end)

Core.Callback.Register('bcc-stables:GetHorseData', function(source, cb)
    local src = source
    local user = Core.getUser(src)

    if not user then
        DebugPrint('User not found for source: ' .. tostring(src))
        return cb(false)
    end

    local character = user.getUsedCharacter

    local horses = MySQL.query.await('SELECT `id`, `selected`, `name`, `model`, `components`, `gender`, `xp`, `captured`, `health`, `stamina`, `dead`, `writhe` FROM `player_horses` WHERE `charid` = ? AND `identifier` = ? AND `dead` = ?',
    { character.charIdentifier, character.identifier, 0 })

    if #horses == 0 then
        Core.NotifyRightTip(src, _U('noHorses'), 4000)
        return cb(false)
    end

    local selectedHorse = nil
    for _, horse in ipairs(horses) do
        if horse.selected == 1 then
            selectedHorse = horse
            break
        end
    end

    if not selectedHorse then
        Core.NotifyRightTip(src, _U('noSelectedHorse'), 4000)
        return cb(false)
    end

    cb({
        model = selectedHorse.model,
        name = selectedHorse.name,
        components = selectedHorse.components,
        id = selectedHorse.id,
        gender = selectedHorse.gender,
        xp = selectedHorse.xp,
        captured = selectedHorse.captured,
        health = selectedHorse.health,
        stamina = selectedHorse.stamina,
        writhe = selectedHorse.writhe
    })
end)

Core.Callback.Register('bcc-stables:GetMyHorses', function(source, cb)
    local src = source
    local user = Core.getUser(src)

    -- Check if the user exists
    if not user then
        DebugPrint('User not found for source: ' .. tostring(src))
        return cb(false)
    end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier

    local horses = MySQL.query.await('SELECT `id`, `selected`, `name`, `model`, `components`, `gender`, `xp`, `captured`, `health`, `stamina`, `dead`, `writhe` FROM `player_horses` WHERE `charid` = ? AND `identifier` = ? ORDER BY `dead`, `id`', { charid, identifier })

    cb(horses)
end)

Core.Callback.Register('bcc-stables:GetPlayerStableMeta', function(source, cb)
    local character = getCharacter(source)
    if not character then return cb(false) end
    local aliveCount = horseSlotCount(character)
    cb({ money = character.money, gold = character.gold, maxHorses = maxHorsesFor(character), aliveCount = aliveCount, permanentDeath = Config.death.permanent == true })
end)

Core.Callback.Register('bcc-stables:UpdateComponents', function(source, cb, encodedComponents, horseId)
    DebugPrint(('Rejected deprecated UpdateComponents call from %s for horse %s'):format(source, tostring(horseId)))
    cb(false)
end)

Core.Callback.Register('bcc-stables:SellMyHorse', function(source, cb, data)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb({ ok = false, reason = 'user' }) end

    local character = user.getUsedCharacter
    local horseId = tonumber(data and data.horseId)
    if not horseId then return cb({ ok = false, reason = 'invalid_horse' }) end
    local stableAllowed, stableReason = validateStableAction(src, character, data and data.site, nil, false)
    if not stableAllowed then return cb({ ok = false, reason = stableReason }) end
    if isRateLimited(src, 'sell', 1000) then return cb({ ok = false, reason = 'processing' }) end
    local lockKey = 'sell:' .. horseId
    if not beginLock(lockKey) then return cb({ ok = false, reason = 'processing' }) end
    local horse = horseOwnerRow(character, horseId, '`id`, `model`, `captured`, `dead`, `writhe`, `selected`')
    local colorCfg = horse and findHorseConfig(horse.model) or nil
    if not horse then
        endLock(lockKey)
        return cb({ ok = false, reason = 'ownership' })
    end
    if tonumber(horse.dead) == 1 then
        endLock(lockKey)
        return cb({ ok = false, reason = 'dead' })
    end
    if tonumber(horse.writhe) == 1 then
        endLock(lockKey)
        return cb({ ok = false, reason = 'injured' })
    end
    if findOwnedHorseEntity(horseId) then
        endLock(lockKey)
        return cb({ ok = false, reason = 'active' })
    end
    if horseCargoHasContents(horseId) then
        endLock(lockKey)
        return cb({ ok = false, reason = 'cargo_not_empty' })
    end
    local multiplier = tonumber(horse.captured) == 1 and Config.tamedSellPrice or Config.sellPrice
    local basePrice = colorCfg and tonumber(colorCfg.cashPrice) or tonumber(Config.legacyHorseBasePrice) or 100
    local sellPrice = math.ceil((tonumber(multiplier) or 0) * basePrice)
    local deleted = MySQL.update.await('DELETE FROM `player_horses` WHERE `id` = ? AND `charid` = ? AND `identifier` = ? AND `dead` = 0',
        { horseId, character.charIdentifier, character.identifier })
    if deleted ~= 1 then
        endLock(lockKey)
        return cb({ ok = false, reason = 'delete_failed' })
    end
    if tonumber(horse.selected) == 1 then
        local replacementId = MySQL.scalar.await('SELECT `id` FROM `player_horses` WHERE `charid` = ? AND `identifier` = ? AND `dead` = 0 AND `writhe` = 0 ORDER BY `id` LIMIT 1',
            { character.charIdentifier, character.identifier })
        if replacementId then
            MySQL.update.await('UPDATE `player_horses` SET `selected` = 1 WHERE `id` = ? AND `charid` = ? AND `identifier` = ?',
                { replacementId, character.charIdentifier, character.identifier })
        end
    end
    character.addCurrency(0, sellPrice)
    local inventoryId = 'horse_' .. tostring(horseId)
    if exports.vorp_inventory:isCustomInventoryRegistered(inventoryId) then
        exports.vorp_inventory:deleteCustomInventory(inventoryId)
    end
    endLock(lockKey)
    Core.NotifyRightTip(src, _U('soldHorse') .. sellPrice, 4000)
    LogToDiscord(character.charIdentifier, _U('discordHorseSold'))
    cb({ ok = true, sellPrice = sellPrice })
end)

local function sellTamedHorse(src, model, netId, token)
    local user = Core.getUser(src)
    if not user then return false, 'user' end

    local character = user.getUsedCharacter
    local charid = character.charIdentifier
    if isRateLimited(src, 'sell_tamed', 1500) then return false, 'processing' end
    local lastTime = CooldownData['sellTame' .. tostring(charid)]
    local cooldown = tonumber(Config.cooldown.sellTame) or 15
    if lastTime and os.difftime(os.time(), lastTime) < cooldown * 60 then
        Core.NotifyRightTip(src, _U('sellCooldown'), 4000)
        return false, 'cooldown'
    end
    local pending = PendingTames[src]
    local authorized = pending and pending.token == token and pending.model == model
        and pending.netId == tonumber(netId) and pending.expires >= GetGameTimer()
    if not authorized then return false, 'not_tamed' end
    local colorCfg = findHorseConfig(model)
    local entity = colorCfg and validateNearbyHorse(src, netId, model, 8.0) or nil
    netId = tonumber(netId)
    if not entity or not netId or SoldWildEntities[netId] then return false, 'invalid_horse' end
    SoldWildEntities[netId] = true
    PendingTames[src] = nil
    SetPlayerCooldown('sellTame', charid)
    local sellPrice = math.ceil((tonumber(Config.tamedSellPrice) or 0) * (tonumber(colorCfg.cashPrice) or 0))
    character.addCurrency(0, sellPrice)
    Core.NotifyRightTip(src, _U('soldHorse') .. sellPrice, 4000)
    LogToDiscord(charid, _U('discordTamedSold'))
    return true, nil, sellPrice
end

RegisterNetEvent('bcc-stables:SellTamedHorse', function(model, netId, token)
    sellTamedHorse(source, model, netId, token)
end)

Core.Callback.Register('bcc-stables:SellTamedHorseChecked', function(source, cb, model, netId, token)
    local ok, reason, price = sellTamedHorse(source, model, netId, token)
    cb({ ok = ok, reason = reason, price = price })
end)

RegisterNetEvent('bcc-stables:SaveHorseTrade', function(serverId, horseId)
    -- Current Owner
    local src = source
    serverId, horseId = tonumber(serverId), tonumber(horseId)
    if not serverId or serverId == src or not horseId or isRateLimited(src, 'trade', 1500) then return end
    local curUser = Core.getUser(src)
    if not curUser then return end

    local curOwner = curUser.getUsedCharacter
    local curOwnerName = curOwner.firstname .. " " .. curOwner.lastname
    -- New Owner
    local newUser = Core.getUser(serverId)
    if not newUser then return end

    local newOwner = newUser.getUsedCharacter
    local newOwnerName = newOwner.firstname .. " " .. newOwner.lastname
    local sourcePed, targetPed = GetPlayerPed(src), GetPlayerPed(serverId)
    if sourcePed == 0 or targetPed == 0 or #(GetEntityCoords(sourcePed) - GetEntityCoords(targetPed)) > 3.0 then return end
    local horse = horseOwnerRow(curOwner, horseId, '`id`, `name`, `dead`, `selected`')
    if not horse or tonumber(horse.dead) == 1 then return end
    local targetCount = horseSlotCount(newOwner)
    if targetCount >= maxHorsesFor(newOwner) then
        return Core.NotifyRightTip(src, _U('horseLimit') .. maxHorsesFor(newOwner) .. _U('horses'), 4000)
    end
    local offerId = ('%s:%s:%s'):format(src, horseId, GetGameTimer())
    TradeOffers[offerId] = { source = src, target = serverId, horseId = horseId, expires = GetGameTimer() + 20000,
        sourceName = curOwnerName, targetName = newOwnerName }
    TriggerClientEvent('bcc-stables:TradeOffer', serverId, offerId, curOwnerName, horse.name)
    Core.NotifyRightTip(src, 'ส่งข้อเสนอม้าแล้ว รอผู้รับยืนยัน', 4000)
    SetTimeout(20500, function()
        if TradeOffers[offerId] then
            TradeOffers[offerId] = nil
            Core.NotifyRightTip(src, 'ข้อเสนอส่งม้าหมดเวลา', 4000)
            Core.NotifyRightTip(serverId, 'ข้อเสนอรับม้าหมดเวลา', 4000)
        end
    end)
end)

RegisterNetEvent('bcc-stables:ResolveTradeOffer', function(offerId, accepted)
    local targetSrc = source
    if type(offerId) ~= 'string' or isRateLimited(targetSrc, 'resolve_trade', 750) then return end
    local offer = TradeOffers[offerId]
    if not offer or offer.target ~= targetSrc then return end
    if offer.expires < GetGameTimer() then
        TradeOffers[offerId] = nil
        Core.NotifyRightTip(targetSrc, 'ข้อเสนอรับม้าหมดเวลา', 4000)
        Core.NotifyRightTip(offer.source, 'ข้อเสนอส่งม้าหมดเวลา', 4000)
        return
    end
    TradeOffers[offerId] = nil
    if accepted ~= true then
        Core.NotifyRightTip(offer.source, 'ผู้รับปฏิเสธการรับม้า', 4000)
        return
    end
    local sourceCharacter, targetCharacter = getCharacter(offer.source), getCharacter(targetSrc)
    if not sourceCharacter or not targetCharacter then
        Core.NotifyRightTip(offer.source, 'ผู้เล่นไม่พร้อมทำรายการส่งม้า', 4000)
        return
    end
    local sourcePed, targetPed = GetPlayerPed(offer.source), GetPlayerPed(targetSrc)
    if sourcePed == 0 or targetPed == 0 or #(GetEntityCoords(sourcePed) - GetEntityCoords(targetPed)) > 3.0 then
        Core.NotifyRightTip(offer.source, 'ผู้เล่นอยู่ไกลเกินไป การส่งม้าถูกยกเลิก', 4000)
        Core.NotifyRightTip(targetSrc, 'ผู้เล่นอยู่ไกลเกินไป การรับม้าถูกยกเลิก', 4000)
        return
    end
    local targetCount = horseSlotCount(targetCharacter)
    if targetCount >= maxHorsesFor(targetCharacter) then
        Core.NotifyRightTip(offer.source, 'คอกของผู้รับเต็มแล้ว', 4000)
        Core.NotifyRightTip(targetSrc, _U('horseLimit') .. maxHorsesFor(targetCharacter) .. _U('horses'), 4000)
        return
    end
    local transferredHorse = horseOwnerRow(sourceCharacter, offer.horseId, '`id`, `selected`, `dead`, `writhe`')
    if not transferredHorse or tonumber(transferredHorse.dead) == 1 or tonumber(transferredHorse.writhe) == 1 then
        Core.NotifyRightTip(offer.source, 'ข้อมูลม้าเปลี่ยนแปลง การส่งม้าถูกยกเลิก', 4000)
        return
    end
    local updated = MySQL.update.await('UPDATE `player_horses` SET `identifier` = ?, `charid` = ?, `selected` = 0 WHERE `id` = ? AND `identifier` = ? AND `charid` = ? AND `dead` = 0',
        { targetCharacter.identifier, targetCharacter.charIdentifier, offer.horseId, sourceCharacter.identifier, sourceCharacter.charIdentifier })
    if updated ~= 1 then
        Core.NotifyRightTip(offer.source, 'ข้อมูลม้าเปลี่ยนแปลง การส่งม้าถูกยกเลิก', 4000)
        return
    end
    if tonumber(transferredHorse.selected) == 1 then
        local replacementId = MySQL.scalar.await('SELECT `id` FROM `player_horses` WHERE `charid` = ? AND `identifier` = ? AND `dead` = 0 AND `writhe` = 0 ORDER BY `id` LIMIT 1',
            { sourceCharacter.charIdentifier, sourceCharacter.identifier })
        if replacementId then
            MySQL.update.await('UPDATE `player_horses` SET `selected` = 1 WHERE `id` = ? AND `charid` = ? AND `identifier` = ?',
                { replacementId, sourceCharacter.charIdentifier, sourceCharacter.identifier })
        end
    end
    Core.NotifyRightTip(offer.source, _U('youGave') .. offer.targetName .. _U('aHorse'), 4000)
    Core.NotifyRightTip(targetSrc, offer.sourceName .. _U('gaveHorse'), 4000)
    TriggerClientEvent('bcc-stables:TradeCompleted', offer.source, offer.horseId)
    LogToDiscord(offer.sourceName, _U('discordTraded') .. offer.targetName)
end)

local function registerHorseInventory(character, id, model)
    id = tonumber(id)
    if not character or not id then return false end
    local horse = horseOwnerRow(character, id, '`id`, `model`')
    if not horse or horse.model ~= model then return false end
    local colorCfg = findHorseConfig(horse.model)
    -- Existing horses can outlive shop catalogue changes. Their cargo must remain accessible
    -- even when the model was later removed/commented from config/horses.lua.
    local inventoryLimit = colorCfg and tonumber(colorCfg.invLimit)
        or tonumber(Config.defaultHorseInventoryLimit)
        or 60
    local idStr = 'horse_' .. tostring(id)
    local isRegistered = exports.vorp_inventory:isCustomInventoryRegistered(idStr)
    local data = {
        id = idStr,
        name = _U('horseInv'),
        limit = inventoryLimit,
        acceptWeapons = Config.allowWeapons == true,
        shared = Config.shareInventory == true,
        ignoreItemStackLimit = Config.ignoreItemStackLimit == true,
        whitelistItems = Config.useWhiteList == true,
        UsePermissions = Config.usePermissions == true,
        UseBlackList = Config.useBlackList == true,
        whitelistWeapons = Config.whitelistWeapons == true
    }
    if isRegistered then
        exports.vorp_inventory:updateCustomInventoryData(idStr, data)
    else
        exports.vorp_inventory:registerInventory(data)
    end
    if data.UsePermissions then
        for _, permission in ipairs(Config.permissions.allowedJobsTakeFrom) do
            exports.vorp_inventory:AddPermissionTakeFromCustom(idStr, permission.name, permission.grade)
        end
        for _, permission in ipairs(Config.permissions.allowedJobsMoveTo) do
            exports.vorp_inventory:AddPermissionMoveToCustom(idStr, permission.name, permission.grade)
        end
    end
    if data.whitelistItems then
        for _, item in ipairs(Config.itemsLimitWhiteList) do
            exports.vorp_inventory:setCustomInventoryItemLimit(idStr, item.name, item.limit)
        end
    end
    if data.whitelistWeapons then
        for _, weapon in ipairs(Config.weaponsLimitWhiteList) do
            exports.vorp_inventory:setCustomInventoryWeaponLimit(idStr, weapon.name, weapon.limit)
        end
    end
    if data.UseBlackList then
        for _, item in ipairs(Config.itemsBlackList) do
            exports.vorp_inventory:BlackListCustomAny(idStr, item)
        end
    end
    return true
end

RegisterNetEvent('bcc-stables:RegisterInventory', function(id, model)
    local character = getCharacter(source)
    if not character or isRateLimited(source, 'register_inventory', 1000) then return end
    registerHorseInventory(character, id, model)
end)

local function nearbyHorseEntity(src, horseId)
    return findNearbyOwnedHorseEntity(src, horseId, 4.0)
end

local function openHorseInventory(src, id, context)
    id = tonumber(id)
    local character = getCharacter(src)
    if not character or not id or isRateLimited(src, 'open_inventory', 750) then return false, 'processing' end
    local requestedStableAccess = type(context) == 'table' and context.stable == true
    local stableAccess = requestedStableAccess and isPlayerNearStable(src, context.site)
    if requestedStableAccess and not stableAccess then return false, 'stable_distance' end
    local horse = horseOwnerRow(character, id, '`id`, `model`, `components`, `dead`')
    local isOwner = horse ~= nil
    if not horse and Config.shareInventory then
        horse = MySQL.single.await('SELECT `id`, `model`, `components`, `dead` FROM `player_horses` WHERE `id` = ? LIMIT 1', { id })
    end
    if not horse or tonumber(horse.dead) == 1 then return false, 'unavailable' end
    if stableAccess and not isOwner then return false, 'ownership' end
    if not isOwner and not nearbyHorseEntity(src, id) then return false, 'distance' end
    -- At a stable the owner is managing stored horses directly, so the selected horse does not
    -- need to be spawned, marked primary, or currently wearing saddlebags. In the world the
    -- physical saddlebag requirement remains enforced.
    if Config.useSaddlebags and not stableAccess and not hasSaddlebags(decodeComponents(horse.components)) then
        return false, 'saddlebags'
    end
    if isOwner and not registerHorseInventory(character, id, horse.model) then return false, 'inventory' end
    local idStr = 'horse_' .. id
    if not exports.vorp_inventory:isCustomInventoryRegistered(idStr) then return false, 'inventory' end
    exports.vorp_inventory:openInventory(src, idStr)
    return true
end

RegisterNetEvent('bcc-stables:OpenInventory', function(id)
    openHorseInventory(source, id)
end)

Core.Callback.Register('bcc-stables:OpenInventoryChecked', function(source, cb, id, context)
    local ok, reason = openHorseInventory(source, id, context)
    cb({ ok = ok, reason = reason })
end)

-- Iterate over each item in the Config.horseFood array to register them as usable items
for _, item in ipairs(Config.horseFood) do
    exports.vorp_inventory:registerUsableItem(item, function(data)
        local src = data.source
        exports.vorp_inventory:closeInventory(src)

        TriggerClientEvent('bcc-stables:FeedHorse', src, item)
    end)
end

if Config.flamingHooves.active then
    exports.vorp_inventory:registerUsableItem(Config.flamingHooves.item, function(data)
        local src = data.source
        local user = Core.getUser(src)
        if not user then return end

        local item = exports.vorp_inventory:getItem(src, Config.flamingHooves.item)
        exports.vorp_inventory:closeInventory(src)
        if not item then return end

        if Config.flamingHooves.durability then
            local maxDurability = Config.flamingHooves.maxDurability or 100
            local useDurability = Config.flamingHooves.durabilityPerUse or 1
            local itemMetadata = type(item.metadata) == 'table' and item.metadata or {}
            local currentDurability = itemMetadata.durability

            -- Initialize durability if it doesn't exist
            if not currentDurability then
                currentDurability = maxDurability
                local newData = {
                    description = _U('flameHooveDesc') .. '</br>' .. _U('durability') .. currentDurability .. '%',
                    durability = currentDurability,
                    id = item.id
                }
                exports.vorp_inventory:setItemMetadata(src, item.id, newData, 1)
            end

            -- Check if durability is below the usage threshold
            if currentDurability < useDurability then
                exports.vorp_inventory:subItemID(src, item.id)
                Core.NotifyRightTip(src, _U('itemBroke'), 4000)
                return
            end
        end

        TriggerClientEvent('bcc-stables:FlamingHooves', src)
    end)

    RegisterNetEvent('bcc-stables:FlamingHoovesDurability', function()
        local src = source
        local user = Core.getUser(src)
        if not user or isRateLimited(src, 'flaming_hooves_durability', 750) then return end

        local item = exports.vorp_inventory:getItem(src, Config.flamingHooves.item)
        if not item or type(item.metadata) ~= 'table' then return end
        local useDurability = Config.flamingHooves.durabilityPerUse or 1
        local itemMetadata = item.metadata
        local newDurability = (tonumber(itemMetadata.durability) or tonumber(Config.flamingHooves.maxDurability) or 100) - useDurability

        -- Check if durability is below the usage threshold or update the durability
        if newDurability < useDurability then
            exports.vorp_inventory:subItemID(src, item.id)
            Core.NotifyRightTip(src, _U('itemBroke'), 4000)
        else
            local newData = {
                description = _U('flameHooveDesc') .. '</br>' .. _U('durability') .. newDurability .. '%',
                durability = newDurability,
                id = item.id
            }
            exports.vorp_inventory:setItemMetadata(src, item.id, newData, 1)
        end
    end)
end

RegisterNetEvent('bcc-stables:RemoveItem', function(item)
    DebugPrint(('Rejected deprecated RemoveItem event from %s for %s'):format(source, tostring(item)))
end)

Core.Callback.Register('bcc-stables:UseHorseFood', function(source, cb, horseId, itemName)
    local src = source
    local character = getCharacter(src)
    horseId = tonumber(horseId)
    local allowed = false
    for _, food in ipairs(Config.horseFood or {}) do
        if itemName == food then allowed = true break end
    end
    if not character or not horseId or not allowed or isRateLimited(src, 'horse_food', 1000) then return cb(false) end
    local horse = horseOwnerRow(character, horseId, '`id`, `dead`, `writhe`')
    if not horse or tonumber(horse.dead) == 1 or tonumber(horse.writhe) == 1
        or not findNearbyOwnedHorseEntity(src, horseId, 4.0) then return cb(false) end
    local lockKey = ('horse_food:%s:%s'):format(src, itemName)
    if not beginLock(lockKey) then return cb(false) end
    local item = exports.vorp_inventory:getItem(src, itemName)
    if not item then endLock(lockKey) return cb(false) end
    exports.vorp_inventory:subItem(src, itemName, 1)
    grantCoreGain(character, horseId, Config.boost.feedHealth, Config.boost.feedStamina)
    grantXpAction(character, horseId, 'feed')
    endLock(lockKey)
    cb(true)
end)

Core.Callback.Register('bcc-stables:AuthorizeCoreGain', function(source, cb, horseId, action)
    local src = source
    local character = getCharacter(src)
    horseId = tonumber(horseId)
    if action ~= 'drink' or not character or not horseId
        or isRateLimited(src, 'core_gain_drink', math.max(1000, (tonumber(Config.drinkLength) or 5) * 1000)) then return cb(false) end
    local horse = horseOwnerRow(character, horseId, '`id`, `dead`, `writhe`')
    local entity = horse and findNearbyOwnedHorseEntity(src, horseId, 4.0) or nil
    if not horse or tonumber(horse.dead) == 1 or tonumber(horse.writhe) == 1
        or not entity then return cb(false) end
    local hasWaterNative, inWater = pcall(IsEntityInWater, entity)
    if hasWaterNative and not inWater then return cb(false) end
    grantCoreGain(character, horseId, Config.boost.drinkHealth, Config.boost.drinkStamina)
    grantXpAction(character, horseId, 'drink')
    cb(true)
end)

Core.Callback.Register('bcc-stables:AuthorizeHorseCare', function(source, cb, horseId, action)
    local src = source
    local character = getCharacter(src)
    horseId = tonumber(horseId)
    if action ~= 'brush' or not character or not horseId or isRateLimited(src, 'horse_care', 1000) then return cb(false) end
    local horse = horseOwnerRow(character, horseId, '`id`, `dead`, `writhe`')
    local item = exports.vorp_inventory:getItem(src, Config.horsebrush.item)
    if not horse or not item or tonumber(horse.dead) == 1 or tonumber(horse.writhe) == 1
        or not findNearbyOwnedHorseEntity(src, horseId, 4.0) then return cb(false) end
    if Config.horsebrush.durability then
        local useDurability = tonumber(Config.horsebrush.durabilityPerUse) or 1
        local maxDurability = tonumber(Config.horsebrush.maxDurability) or 100
        local metadata = type(item.metadata) == 'table' and item.metadata or {}
        local current = tonumber(metadata.durability) or maxDurability
        if current < useDurability then
            exports.vorp_inventory:subItemID(src, item.id)
            Core.NotifyRightTip(src, _U('itemBroke'), 4000)
            return cb(false)
        end
        local remaining = current - useDurability
        if remaining < useDurability then
            exports.vorp_inventory:subItemID(src, item.id)
        else
            exports.vorp_inventory:setItemMetadata(src, item.id, {
                description = _U('horsebrushDesc') .. '</br>' .. _U('durability') .. remaining .. '%',
                durability = remaining,
                id = item.id,
            }, 1)
        end
    end
    grantCoreGain(character, horseId, Config.boost.brushHealth, Config.boost.brushStamina)
    grantXpAction(character, horseId, 'brush')
    cb(true)
end)

exports.vorp_inventory:registerUsableItem(Config.horsebrush.item, function(data)
    local src = data.source
    local user = Core.getUser(src)
    if not user then return end

    local item = exports.vorp_inventory:getItem(src, Config.horsebrush.item)
    exports.vorp_inventory:closeInventory(src)
    if not item then return end

    if Config.horsebrush.durability then
        local maxDurability = Config.horsebrush.maxDurability or 100
        local useDurability = Config.horsebrush.durabilityPerUse or 1
        local itemMetadata = type(item.metadata) == 'table' and item.metadata or {}
        local currentDurability = itemMetadata.durability

        -- Initialize durability if it doesn't exist
        if not currentDurability then
            currentDurability = maxDurability
            local newData = {
                description = _U('horsebrushDesc') .. '</br>' .. _U('durability') .. currentDurability .. '%',
                durability = currentDurability,
                id = item.id
            }
            exports.vorp_inventory:setItemMetadata(src, item.id, newData, 1)
        end

        -- Check if durability is below the usage threshold
        if currentDurability < useDurability then
            exports.vorp_inventory:subItemID(src, item.id)
            Core.NotifyRightTip(src, _U('itemBroke'), 4000)
            return
        end
    end

    TriggerClientEvent('bcc-stables:BrushHorse', src)
end)

RegisterNetEvent('bcc-stables:HorseBrushDurability', function()
    DebugPrint(('Rejected deprecated HorseBrushDurability event from %s'):format(source))
end)

exports.vorp_inventory:registerUsableItem(Config.lantern.item, function(data)
    local src = data.source
    local user = Core.getUser(src)
    if not user then return end

    local item = exports.vorp_inventory:getItem(src, Config.lantern.item)
    exports.vorp_inventory:closeInventory(src)
    if not item then return end

    if Config.lantern.durability then
        local maxDurability = Config.lantern.maxDurability or 100
        local useDurability = Config.lantern.durabilityPerUse or 1
        local itemMetadata = type(item.metadata) == 'table' and item.metadata or {}
        local currentDurability = itemMetadata.durability

        -- Initialize durability if it doesn't exist
        if not currentDurability then
            currentDurability = maxDurability
            local newData = {
                description = _U('lanternDesc') .. '</br>' .. _U('durability') .. currentDurability .. '%',
                durability = currentDurability,
                id = item.id
            }
            exports.vorp_inventory:setItemMetadata(src, item.id, newData, 1)
        end

        -- Check if durability is below the usage threshold
        if currentDurability < useDurability then
            exports.vorp_inventory:subItemID(src, item.id)
            Core.NotifyRightTip(src, _U('itemBroke'), 4000)
            return
        end
    end

    TriggerClientEvent('bcc-stables:UseLantern', src)
end)

RegisterNetEvent('bcc-stables:LanternDurability', function()
    local src = source
    local user = Core.getUser(src)
    if not user or isRateLimited(src, 'lantern_durability', 750) then return end

    local item = exports.vorp_inventory:getItem(src, Config.lantern.item)
    if not item or type(item.metadata) ~= 'table' then return end
    local useDurability = Config.lantern.durabilityPerUse or 1
    local itemMetadata = item.metadata
    local newDurability = (tonumber(itemMetadata.durability) or tonumber(Config.lantern.maxDurability) or 100) - useDurability

    -- Check if durability is below the usage threshold or update the durability
    if newDurability < useDurability then
        exports.vorp_inventory:subItemID(src, item.id)
        Core.NotifyRightTip(src, _U('itemBroke'), 4000)
    else
        local newData = {
            description = _U('lanternDesc') .. '</br>' .. _U('durability') .. newDurability .. '%',
            durability = newDurability,
            id = item.id
        }
        exports.vorp_inventory:setItemMetadata(src, item.id, newData, 1)
    end
end)

Core.Callback.Register('bcc-stables:HorseReviveItem', function(source, cb, horseId)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    -- รองรับไอเท็มชุบหลายชื่อ (Config.reviverItems) — หาตัวแรกที่ผู้เล่นมีแล้วหักตัวนั้น
    -- fallback เป็น { Config.reviver } เผื่อ config เก่าที่ยังไม่มี reviverItems
    horseId = tonumber(horseId)
    local character = user.getUsedCharacter
    local horse = horseOwnerRow(character, horseId, '`id`, `writhe`, `dead`')
    if not horse or tonumber(horse.writhe) ~= 1 or tonumber(horse.dead) == 1 then return cb(false) end
    local reviverList = Config.reviverItems or { Config.reviver }
    for _, reviveItem in ipairs(reviverList) do
        local hasItem = exports.vorp_inventory:getItem(src, reviveItem)
        if hasItem then
            exports.vorp_inventory:subItem(src, reviveItem, 1)
            ReviveAuthorizations[src] = { horseId = horseId, expires = GetGameTimer() + 15000 }
            return cb(true)
        end
    end

    return cb(false)
end)

-- แปรงขัดม้าแบบใช้ครั้งเดียว (Config.simpleBrushItems เช่น hr_brush จากร้าน) — หัก 1 ชิ้น แล้วสั่ง
-- แปรงเหมือนแปรงหลัก แต่ข้าม durability (ส่ง skipDurability=true ไป client ดู BrushHorse ฝั่ง client)
for _, brushItem in ipairs(Config.simpleBrushItems or {}) do
    exports.vorp_inventory:registerUsableItem(brushItem, function(data)
        local src = data.source
        local user = Core.getUser(src)
        if not user then return end

        exports.vorp_inventory:closeInventory(src)
        TriggerClientEvent('bcc-stables:BrushHorse', src, brushItem)
    end)
end

Core.Callback.Register('bcc-stables:UseSimpleBrush', function(source, cb, horseId, itemName)
    local src = source
    local character = getCharacter(src)
    horseId = tonumber(horseId)
    local allowedItem = false
    for _, name in ipairs(Config.simpleBrushItems or {}) do
        if itemName == name then allowedItem = true break end
    end
    if not character or not horseId or not allowedItem or isRateLimited(src, 'simple_brush', 1000) then return cb(false) end
    local horse = horseOwnerRow(character, horseId, '`id`, `dead`, `writhe`')
    if not horse or tonumber(horse.dead) == 1 or tonumber(horse.writhe) == 1
        or not findNearbyOwnedHorseEntity(src, horseId, 4.0) then return cb(false) end
    local lockKey = ('simple_brush:%s:%s'):format(src, itemName)
    if not beginLock(lockKey) then return cb(false) end
    local item = exports.vorp_inventory:getItem(src, itemName)
    if not item then endLock(lockKey) return cb(false) end
    exports.vorp_inventory:subItem(src, itemName, 1)
    grantCoreGain(character, horseId, Config.boost.brushHealth, Config.boost.brushStamina)
    grantXpAction(character, horseId, 'brush')
    endLock(lockKey)
    cb(true)
end)

Core.Callback.Register('bcc-stables:PaidHealRequest', function(source, cb, horseId, site)
    local src = source
    local character = getCharacter(src)
    horseId = tonumber(horseId)
    if not character or not horseId or isRateLimited(src, 'paid_heal_request', 1500) then
        return cb({ ok = false, reason = 'processing' })
    end
    local stableAllowed, stableReason = validateStableAction(src, character, site, nil, false)
    if not stableAllowed then return cb({ ok = false, reason = stableReason }) end
    local lockKey = ('heal:%s:%s'):format(character.identifier, character.charIdentifier)
    if not beginLock(lockKey) then return cb({ ok = false, reason = 'processing' }) end
    local horse = horseOwnerRow(character, horseId, '`id`, `health`, `stamina`, `dead`, `writhe`')
    if not horse then endLock(lockKey) return cb({ ok = false, reason = 'not_found' }) end
    if tonumber(horse.dead) == 1 and Config.death.permanent then endLock(lockKey) return cb({ ok = false, reason = 'permanent_dead' }) end
    if tonumber(horse.dead) == 1 then
        local aliveCount = MySQL.scalar.await('SELECT COUNT(*) FROM `player_horses` WHERE `charid` = ? AND `identifier` = ? AND `dead` = 0',
            { character.charIdentifier, character.identifier }) or 0
        if aliveCount >= maxHorsesFor(character) then
            endLock(lockKey)
            return cb({ ok = false, reason = 'stable_full' })
        end
    end
    if tonumber(horse.dead) == 0 and tonumber(horse.writhe) == 0 and tonumber(horse.health) >= 100 and tonumber(horse.stamina) >= 100 then
        endLock(lockKey)
        return cb({ ok = false, reason = 'full' })
    end
    local price = tonumber(Config.healPrice) or 500
    local currency = 0
    local balance = character.money
    if balance < price then endLock(lockKey) return cb({ ok = false, reason = 'funds' }) end
    if price > 0 then character.removeCurrency(currency, price) end
    local updated = MySQL.update.await('UPDATE `player_horses` SET `health` = 100, `stamina` = 100, `dead` = 0, `writhe` = 0 WHERE `id` = ? AND `charid` = ? AND `identifier` = ?',
        { horseId, character.charIdentifier, character.identifier })
    if updated ~= 1 then
        if price > 0 then character.addCurrency(currency, price) end
        endLock(lockKey)
        return cb({ ok = false, reason = 'database' })
    end
    endLock(lockKey)
    TriggerClientEvent('bcc-stables:cl:healResult', src, horseId)
    cb({ ok = true, horseId = horseId, price = price })
end)

AddEventHandler('playerDropped', function()
    local src = source
    PendingTames[src] = nil
    ReviveAuthorizations[src] = nil
    for key in pairs(RateLimits) do
        if key:sub(1, #tostring(src) + 1) == tostring(src) .. ':' then RateLimits[key] = nil end
    end
    for offerId, offer in pairs(TradeOffers) do
        if offer.source == src or offer.target == src then TradeOffers[offerId] = nil end
    end
end)

Core.Callback.Register('bcc-stables:CheckPlayerCooldown', function(source, cb, type)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local cooldown = Config.cooldown[type]
    local typeId = type .. tostring(character.charIdentifier)
    local currentTime = os.time()
    local lastTime = CooldownData[typeId]

    if lastTime then
        if os.difftime(currentTime, lastTime) >= cooldown * 60 then
            cb(false) -- Not on Cooldown
        else
            cb(true) -- On Cooldown
        end
    else
        cb(false) -- Not on Cooldown
    end
end)

Core.Callback.Register('bcc-stables:CheckJob', function(source, cb, trainer, site)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local jobConfig = trainer and Config.trainerJob or Stables[site].shop.jobs

    local hasJob = false
    for _, job in pairs(jobConfig) do
        if (character.job == job.name) and (tonumber(character.jobGrade) >= tonumber(job.grade)) then
            hasJob = true
            break
        end
    end

    cb({hasJob, character.job})
end)

RegisterNetEvent('vorp_core:instanceplayers', function(setRoom)
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    if setRoom == 0 then
        Wait(3000)
        TriggerClientEvent('bcc-stables:UpdateMyHorseEntity', src)
    end
end)

--- Check if properly downloaded
function file_exists(name)
    local f = LoadResourceFile(GetCurrentResourceName(), name)
    return f ~= nil
end

if not file_exists('./ui/index.html') then
    print('^1 INCORRECT DOWNLOAD!  ^0')
    print(
        '^4 Please Download: ^2(bcc-stables.zip) ^4from ^3<https://github.com/BryceCanyonCounty/bcc-stables/releases/latest>^0')
end

BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-stables')
