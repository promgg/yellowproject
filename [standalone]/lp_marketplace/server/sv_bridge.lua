-- sv_bridge.lua — VORPCore / vorp_inventory helpers
-- vorp_inventory is callback-based (async); the rest of this resource is written
-- in a synchronous/await style (like the MySQL.xxx.await calls already used here).
-- These wrappers use promise + Citizen.Await so callers can read top-to-bottom.

VORPcore = exports.vorp_core:GetCore()

-- ── Character lookup ──────────────────────────────────────────────────────────
function GetCharacter(source)
    local ok, user = pcall(VORPcore.getUser, source)
    if not ok or not user then return nil end
    return user.getUsedCharacter
end

-- ── Inventory: item count ─────────────────────────────────────────────────────
function InvGetCount(source, itemName)
    local p = promise.new()
    local ok = pcall(function()
        exports.vorp_inventory:getItem(source, itemName, function(item)
            local count = 0
            if item then
                if type(item.getCount) == 'function' then
                    count = item:getCount()
                else
                    count = item.count or item.amount or 0
                end
            end
            p:resolve(count)
        end)
    end)
    if not ok then p:resolve(0) end
    return Citizen.Await(p)
end

-- ── Inventory: remove item ────────────────────────────────────────────────────
function InvSubItem(source, itemName, amount)
    local p = promise.new()
    local ok = pcall(function()
        exports.vorp_inventory:subItem(source, itemName, amount, nil, function(success)
            p:resolve(success == true)
        end)
    end)
    if not ok then p:resolve(false) end
    return Citizen.Await(p)
end

-- ── Inventory: add item ───────────────────────────────────────────────────────
function InvAddItem(source, itemName, amount)
    local p = promise.new()
    local ok = pcall(function()
        exports.vorp_inventory:addItem(source, itemName, amount, nil, function(success)
            p:resolve(success == true)
        end)
    end)
    if not ok then p:resolve(false) end
    return Citizen.Await(p)
end

-- ── Inventory: full item list (สำหรับ inventory picker ใน SELL tab) ──────────
function InvGetAll(source)
    local p = promise.new()
    local ok = pcall(function()
        exports.vorp_inventory:getUserInventoryItems(source, function(items)
            p:resolve(items or {})
        end)
    end)
    if not ok then p:resolve({}) end
    return Citizen.Await(p)
end

-- ── Inventory: static item label lookup (ไม่ผูกกับผู้เล่นคนใดคนหนึ่ง) ────────
function InvGetItemLabel(itemName)
    local p = promise.new()
    local ok = pcall(function()
        exports.vorp_inventory:getItemDB(itemName, function(svItem)
            p:resolve(svItem and svItem.label or itemName)
        end)
    end)
    if not ok then p:resolve(itemName) end
    return Citizen.Await(p)
end

-- ── หา source ของผู้เล่น online จาก charIdentifier (สำหรับจ่ายเงินผู้ขายทันที) ──
function FindSourceByCharIdentifier(charIdentifier)
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        local char = GetCharacter(src)
        if char and char.charIdentifier == charIdentifier then
            return src
        end
    end
    return nil
end

-- ── RPC: เช็คไอเทม (ใช้เฉพาะตอน Config.CommandItem/zone.item.enabled = true) ──
VORPcore.addRpcCallback('lp_marketplace:hasItem', function(source, cb, itemName)
    cb(InvGetCount(source, itemName) > 0)
end)
