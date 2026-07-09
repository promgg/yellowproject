local function notify(source, kind, text, duration)
    TriggerClientEvent("pNotify:SendNotification", source, { type = kind, text = text, timeout = duration or 3000 })
end

RegisterServerEvent("mining:axecheck")
AddEventHandler("mining:axecheck", function()
    local _source = source
    local axe     = exports.vorp_inventory:getItem(_source, Config.Pickaxe)

    if not axe then
        TriggerClientEvent("mining:noaxe", _source)
        notify(_source, 'error', 'You need a pickaxe.', 5000)
        return
    end

    -- Config.PickaxeDurability = false: ซื้อจอบครั้งเดียวใช้ได้ตลอด ไม่มีวันหัก/พัง แค่เช็คว่ามีจอบพอ
    if not Config.PickaxeDurability then
        TriggerClientEvent("mining:axechecked", _source, 99)
        return
    end

    local meta       = axe.metadata
    local durability = 99

    if not next(meta) then
        local metadata = { description = "Durability 99", durability = 99 }
        exports.vorp_inventory:setItemMetadata(_source, axe.id, metadata, 1)
        durability = 99
        TriggerClientEvent("mining:axechecked", _source, durability)
    else
        durability = (meta.durability or 99) - 1
        local metadata = { description = "Durability " .. durability, durability = durability }

        if durability < 20 then
            local roll = math.random(1, 3)
            if roll == 1 then
                notify(_source, 'error', 'Your pickaxe broke!', 5000)
                exports.vorp_inventory:subItem(_source, Config.Pickaxe, 1, meta)
                TriggerClientEvent("mining:noaxe", _source)
                return
            end
        end

        exports.vorp_inventory:setItemMetadata(_source, axe.id, metadata, 1)
        TriggerClientEvent("mining:axechecked", _source, durability)
    end
end)

-- _GET_MAP_ZONE_AT_COORDS (0x43AD8FC02B429D33) เป็น native client-only เรียกฝั่ง server แล้วได้ false เสมอ
-- (ไม่มีแผนที่โลกโหลดฝั่ง server) — ต้องให้ client คำนวณ townName เองแล้วส่งมาแนบกับ event แทน
-- (บั๊กแบบเดียวกับที่เจอใน MJ-AfkFishing เมื่อก่อนหน้านี้ในเซสชันนี้)
RegisterServerEvent("mining:addItem")
AddEventHandler("mining:addItem", function(townName)
    local _source = source
    local rewards = townName and Config.MiningRewards[townName]

    if not rewards then
        notify(_source, 'warning', 'Nothing found this swing.', 3000)
        return
    end

    -- roll 1-100 แบบ cumulative: ไล่บวก chance ทีละตัวตามลำดับใน Config.MiningRewards[townName]
    local roll       = math.random(100)
    local cumulative = 0
    local pick       = nil

    for _, v in ipairs(rewards) do
        cumulative = cumulative + v.chance
        if roll <= cumulative then
            pick = v
            break
        end
    end

    if not pick then
        notify(_source, 'warning', 'Nothing found this swing.', 3000)
        return
    end

    local count    = pick.amount
    local canCarry = exports.vorp_inventory:canCarryItem(_source, pick.name, count)

    if not canCarry then
        notify(_source, 'warning', 'Inventory full — ' .. pick.label, 5000)
        return
    end

    exports.vorp_inventory:addItem(_source, pick.name, count)
    TriggerClientEvent('mining:itemAwarded', _source, pick.name)
end)
