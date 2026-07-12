NX_GR = NX_GR or {}
NX_GR.VORP = {}

local Core = exports.vorp_core:GetCore()
local Inventory = exports.vorp_inventory

function NX_GR.VORP.GetCharacter(source)
    local user = Core.getUser(source)
    if not user then return nil end

    local char = user.getUsedCharacter
    if not char then return nil end

    return {
        raw = char,
        user = user,
        identifier = char.identifier,
        charIdentifier = tostring(char.charIdentifier),
        job = char.job,
        group = char.group,
        isDead = char.isdead == true or char.isdead == 1,
    }
end

function NX_GR.VORP.Notify(source, message, duration)
    Core.NotifyRightTip(source, message, duration or 4000)
end

function NX_GR.VORP.HasItem(source, itemName, amount)
    local count = Inventory:getItemCount(source, itemName)
    return (tonumber(count) or 0) >= (amount or 1)
end

function NX_GR.VORP.RemoveItem(source, itemName, amount)
    local result = Inventory:subItem(source, itemName, amount or 1)
    return result ~= false and result ~= nil
end

function NX_GR.VORP.CanCarryItem(source, itemName, amount)
    local ok = Inventory:canCarryItem(source, itemName, amount or 1)
    return ok == true
end

function NX_GR.VORP.AddItem(source, itemName, amount, metadata)
    local result = Inventory:addItem(source, itemName, amount or 1, metadata or {})
    return result ~= false and result ~= nil
end

function NX_GR.VORP.AddCurrency(character, currency, amount)
    if not amount or amount <= 0 then return true end
    character.raw.addCurrency(currency or 0, amount)
    return true
end

function NX_GR.VORP.IsAdmin(source)
    if source == 0 then return true end
    if Config.Security.adminAce and IsPlayerAceAllowed(source, Config.Security.adminAce) then
        return true
    end

    local user = Core.getUser(source)
    if not user then return false end
    return NX_GR.TableContains(Config.Security.adminGroups, user.getGroup)
end

function NX_GR.VORP.GetIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, identifier in ipairs(identifiers) do
        if identifier:find('license:', 1, true) then return identifier end
    end
    return identifiers[1]
end
