local Core = exports.vorp_core:GetCore()
local Purchasing = {}

local function roundMoney(value)
    return math.floor((tonumber(value) or 0) * 100 + 0.5) / 100
end

local function sanitizeQuantity(value)
    local amount = math.floor(tonumber(value) or 0)
    if amount < 1 then
        return 0
    end

    if amount > Config.MaxCartQuantityPerItem then
        amount = Config.MaxCartQuantityPerItem
    end

    return amount
end

local function isStoreClosed(store)
    if not store.hours or not store.hours.enabled then
        return false
    end

    local hour = tonumber(os.date('%H')) or 0
    if store.hours.close < store.hours.open then
        return not (hour >= store.hours.open or hour < store.hours.close)
    end

    return not (hour >= store.hours.open and hour < store.hours.close)
end

local function isJobAllowed(source, store)
    if not store.jobs or next(store.jobs) == nil then
        return true
    end

    local user = Core.getUser(source)
    local character = user and user.getUsedCharacter
    if not character then
        return false
    end

    local minGrade = store.jobs[character.job]
    return minGrade ~= nil and tonumber(character.jobGrade or 0) >= tonumber(minGrade)
end

local function isNearStore(source, store)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then
        return false
    end

    local coords = GetEntityCoords(ped)
    return #(coords - store.position) <= (store.openDistance + Config.ServerDistancePadding)
end

local function validateAccess(source, storeId)
    local store = Config.Stores[storeId]
    if not store or store.enabled == false then
        return false, Config.Text.NotAllowed
    end

    if isStoreClosed(store) then
        return false, Config.Text.Closed
    end

    if not isJobAllowed(source, store) then
        return false, Config.Text.NotAllowed
    end

    if not isNearStore(source, store) then
        return false, Config.Text.TooFar
    end

    return true, nil, store
end

local function itemMap(store)
    local map = {}
    for _, item in ipairs(store.items or {}) do
        if item.id and item.item and item.price then
            map[item.id] = item
        end
    end
    return map
end

local function buildClientStore(storeId, store)
    local categories = {}
    for _, category in ipairs(store.categories or {}) do
        categories[#categories + 1] = {
            id = category.id,
            label = category.label
        }
    end

    local items = {}
    for _, item in ipairs(store.items or {}) do
        items[#items + 1] = {
            id = item.id,
            item = item.item,
            label = item.label or item.item,
            category = item.category or 'all',
            price = tonumber(item.price) or 0,
            currency = item.currency or 'cash',
            image = item.image or (item.item .. '.png'),
            max = tonumber(item.max) or Config.MaxCartQuantityPerItem
        }
    end

    return {
        id = storeId,
        title = store.title or 'ร้านค้า',
        subtitle = store.subtitle or store.promptName or storeId,
        categories = categories,
        items = items,
        payment = {
            allowCash = store.payment and store.payment.allowCash ~= false,
            allowBank = store.payment and store.payment.allowBank == true,
            vatPercent = tonumber(store.payment and store.payment.vatPercent) or 0
        }
    }
end

local function buildOrder(store, cart)
    if type(cart) ~= 'table' then
        return nil
    end

    local byId = itemMap(store)
    local order = {
        lines = {},
        cashTotal = 0,
        blackTotal = 0
    }

    for _, row in ipairs(cart) do
        local id = type(row) == 'table' and tostring(row.id or '') or ''
        local qty = type(row) == 'table' and sanitizeQuantity(row.qty) or 0
        local cfg = byId[id]

        if cfg and qty > 0 then
            local max = tonumber(cfg.max) or Config.MaxCartQuantityPerItem
            if qty > max then
                qty = max
            end

            local price = tonumber(cfg.price) or 0
            local currency = cfg.currency or 'cash'
            local lineTotal = roundMoney(price * qty)

            order.lines[#order.lines + 1] = {
                cfg = cfg,
                qty = qty,
                total = lineTotal,
                currency = currency
            }

            if currency == 'black' then
                order.blackTotal = order.blackTotal + lineTotal
            else
                order.cashTotal = order.cashTotal + lineTotal
            end
        end
    end

    order.cashTotal = roundMoney(order.cashTotal)
    order.blackTotal = math.floor(order.blackTotal)

    if #order.lines == 0 then
        return nil
    end

    return order
end

local function canCarryOrder(source, order)
    for _, line in ipairs(order.lines) do
        local cfg = line.cfg
        if cfg.weapon then
            local canCarryWeapon = exports.vorp_inventory:canCarryWeapons(source, line.qty, nil, cfg.item)
            if not canCarryWeapon then
                return false
            end
        else
            local canCarryItem = exports.vorp_inventory:canCarryItem(source, cfg.item, line.qty)
            if not canCarryItem then
                return false
            end
        end
    end

    return true
end

local function getBankBalance(character, bankName)
    local result = MySQL.single.await(
        'SELECT money FROM bank_users WHERE charidentifier = @charidentifier AND name = @name LIMIT 1',
        {
            charidentifier = character.charIdentifier,
            name = bankName
        }
    )

    return result and tonumber(result.money) or nil
end

local function removeBankMoney(character, bankName, amount)
    local affected = MySQL.update.await(
        'UPDATE bank_users SET money = money - @amount WHERE charidentifier = @charidentifier AND name = @name AND money >= @amount',
        {
            amount = amount,
            charidentifier = character.charIdentifier,
            name = bankName
        }
    )

    return affected and affected > 0
end

local function removeBlackMoney(source, amount)
    if amount <= 0 then
        return true
    end

    local count = exports.vorp_inventory:getItemCount(source, nil, Config.BlackMoneyItem)
    if (tonumber(count) or 0) < amount then
        return false
    end

    return exports.vorp_inventory:subItem(source, Config.BlackMoneyItem, amount) ~= false
end

local function hasBlackMoney(source, amount)
    if amount <= 0 then
        return true
    end

    local count = exports.vorp_inventory:getItemCount(source, nil, Config.BlackMoneyItem)
    return (tonumber(count) or 0) >= amount
end

local function giveOrder(source, order)
    for _, line in ipairs(order.lines) do
        local cfg = line.cfg
        if cfg.weapon then
            for _ = 1, line.qty do
                exports.vorp_inventory:createWeapon(source, cfg.item)
            end
        else
            exports.vorp_inventory:addItem(source, cfg.item, line.qty, cfg.metadata or {})
        end
    end
end

Core.Callback.Register('nx_shop:server:getShop', function(source, cb, storeId)
    local ok, message, store = validateAccess(source, storeId)
    if not ok then
        cb({ ok = false, message = message })
        return
    end

    cb({ ok = true, store = buildClientStore(storeId, store) })
end)

RegisterServerEvent('nx_shop:server:buy', function(storeId, cart, useBank)
    local source = source
    if Purchasing[source] then
        TriggerClientEvent('nx_shop:client:purchaseResult', source, { ok = false, message = Config.Text.Busy })
        return
    end

    Purchasing[source] = true

    local function finish(ok, message)
        Purchasing[source] = nil
        TriggerClientEvent('nx_shop:client:purchaseResult', source, {
            ok = ok,
            message = message
        })
    end

    local ok, message, store = validateAccess(source, storeId)
    if not ok then
        finish(false, message)
        return
    end

    local user = Core.getUser(source)
    local character = user and user.getUsedCharacter
    if not character then
        finish(false, Config.Text.NotAllowed)
        return
    end

    local order = buildOrder(store, cart)
    if not order then
        finish(false, Config.Text.InvalidCart)
        return
    end

    if not canCarryOrder(source, order) then
        finish(false, Config.Text.CannotCarry)
        return
    end

    local vatPercent = tonumber(store.payment and store.payment.vatPercent) or 0
    local vat = useBank and roundMoney(order.cashTotal * (vatPercent / 100)) or 0
    local chargeCash = roundMoney(order.cashTotal + vat)

    if order.blackTotal > 0 and not hasBlackMoney(source, order.blackTotal) then
        finish(false, Config.Text.NoBlackMoney)
        return
    end

    if chargeCash > 0 then
        if useBank then
            if not (store.payment and store.payment.allowBank) then
                finish(false, Config.Text.BankUnavailable)
                return
            end

            local bankName = store.payment.bankName or storeId
            local balance = getBankBalance(character, bankName)
            if not balance then
                finish(false, Config.Text.BankUnavailable)
                return
            end

            if balance < chargeCash or not removeBankMoney(character, bankName, chargeCash) then
                finish(false, Config.Text.NoMoney)
                return
            end
        else
            if store.payment and store.payment.allowCash == false then
                finish(false, Config.Text.NoMoney)
                return
            end

            if character.money < chargeCash then
                finish(false, Config.Text.NoMoney)
                return
            end

            character.removeCurrency(0, chargeCash)
            character.money = character.money - chargeCash
        end
    end

    if order.blackTotal > 0 and not removeBlackMoney(source, order.blackTotal) then
        if chargeCash > 0 then
            if useBank then
                MySQL.update.await(
                    'UPDATE bank_users SET money = money + @amount WHERE charidentifier = @charidentifier AND name = @name',
                    {
                        amount = chargeCash,
                        charidentifier = character.charIdentifier,
                        name = store.payment.bankName or storeId
                    }
                )
            else
                character.addCurrency(0, chargeCash)
                character.money = character.money + chargeCash
            end
        end

        finish(false, Config.Text.NoBlackMoney)
        return
    end

    giveOrder(source, order)
    finish(true, Config.Text.Purchased)
end)

AddEventHandler('playerDropped', function()
    Purchasing[source] = nil
end)
