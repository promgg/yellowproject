-- local VorpCore = exports.vorp_core:GetCore()

local function notify(source, kind, text, duration)
    TriggerClientEvent("pNotify:SendNotification", source, { type = kind, text = text, timeout = duration or 3000 })
end

RegisterServerEvent("!MJ-Lumberjack:axecheck", function(tree)
    local _source = source
    local axe     = exports.vorp_inventory:getItem(_source, Config.Axe)

    if not axe then
        TriggerClientEvent("!MJ-Lumberjack:noaxe", _source)
        notify(_source, 'error', 'คุณไม่มีขวาน', 5000)
        return
    end

    -- Config.AxeDurability = false: ซื้อขวานครั้งเดียวใช้ได้ตลอด ไม่มีวันหัก/พัง แค่เช็คว่ามีขวานพอ
    if not Config.AxeDurability then
        TriggerClientEvent("!MJ-Lumberjack:axechecked", _source, tree, 99)
        return
    end

    local meta       = axe.metadata
    local durability = 99

    if not next(meta) then
        -- ขวานใหม่ ตั้ง durability
        local metadata = { description = "Durability 99", durability = 99 }
        exports.vorp_inventory:setItemMetadata(_source, axe.id, metadata, 1)
        durability = 99
        TriggerClientEvent("!MJ-Lumberjack:axechecked", _source, tree, durability)
    else
        durability = (meta.durability or 99) - 1
        local metadata = { description = "Durability " .. durability, durability = durability }

        if durability < 20 then
            local roll = math.random(1, 3)
            if roll == 1 then
                notify(_source, 'error', 'ขวานของคุณหักแล้ว!', 5000)
                exports.vorp_inventory:subItem(_source, Config.Axe, 1, meta)
                TriggerClientEvent("!MJ-Lumberjack:noaxe", _source)
                return
            end
        end

        exports.vorp_inventory:setItemMetadata(_source, axe.id, metadata, 1)
        TriggerClientEvent("!MJ-Lumberjack:axechecked", _source, tree, durability)
    end
end)

RegisterServerEvent('!MJ-Lumberjack:addItem', function()
    local _source = source
    -- roll 1-100 แบบ cumulative: ไล่บวก chance ทีละตัวตามลำดับใน Config.Items
    -- met_log=10, met_stick=50, met_bark=30, met_resin=10 -> รวม 100% ไม่มีโอกาส "ไม่ได้ของ"
    local roll       = math.random(100)
    local cumulative = 0
    local pick       = nil

    for _, v in ipairs(Config.Items) do
        cumulative = cumulative + v.chance
        if roll <= cumulative then
            pick = v
            break
        end
    end

    if not pick then
        notify(_source, 'warning', 'ไม่ได้ไอเทมรอบนี้', 3000)
        return
    end

    local count    = pick.amount
    local canCarry = exports.vorp_inventory:canCarryItem(_source, pick.name, count)

    if not canCarry then
        notify(_source, 'warning', 'กระเป๋าเต็ม — ' .. pick.label, 5000)
        return
    end

    exports.vorp_inventory:addItem(_source, pick.name, count)
    -- notify(_source, 'success', 'ได้รับ ' .. pick.label .. ' x' .. count, 3000)
    TriggerClientEvent('!MJ-Lumberjack:itemAwarded', _source, pick.name)
end)
