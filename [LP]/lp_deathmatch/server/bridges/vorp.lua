LP_DM = LP_DM or {}
LP_DM.VORP = {}

local Core = exports.vorp_core:GetCore()
local Inventory = exports.vorp_inventory

function LP_DM.VORP.GetCharacter(source)
    local user = Core.getUser(source)
    if not user then return nil end

    local char = user.getUsedCharacter
    if not char then return nil end

    return {
        raw = char,
        user = user,
        identifier = char.identifier,
        charIdentifier = tostring(char.charIdentifier),
        isDead = char.isdead == true or char.isdead == 1,
    }
end

function LP_DM.VORP.Notify(source, message, duration, notifyType)
    TriggerClientEvent('pNotify:SendNotification', source, { type = notifyType or 'success', text = message, timeout = duration or 4000 })
end

function LP_DM.VORP.CanCarryItem(source, itemName, amount)
    local ok = Inventory:canCarryItem(source, itemName, amount or 1)
    return ok == true
end

function LP_DM.VORP.AddItem(source, itemName, amount, metadata)
    local result = Inventory:addItem(source, itemName, amount or 1, metadata or {})
    return result ~= false and result ~= nil
end

function LP_DM.VORP.AddCurrency(character, currency, amount)
    if not amount or amount <= 0 then return true end
    character.raw.addCurrency(currency or 0, amount)
    return true
end

function LP_DM.VORP.IsAdmin(source)
    if source == 0 then return true end
    if Config.Security.adminAce and IsPlayerAceAllowed(source, Config.Security.adminAce) then
        return true
    end

    local user = Core.getUser(source)
    if not user then return false end
    return LP_DM.TableContains(Config.Security.adminGroups, user.getGroup)
end

function LP_DM.VORP.GetIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, identifier in ipairs(identifiers) do
        if identifier:find('license:', 1, true) then return identifier end
    end
    return identifiers[1]
end
