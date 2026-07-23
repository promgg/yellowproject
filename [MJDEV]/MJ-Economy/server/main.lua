
DATA = {}
Core = exports.vorp_core:GetCore()
VorpInv = exports.vorp_inventory:vorp_inventoryApi()

function InitEconomy()
    DATA = {}
    math.randomseed(os.time())

    -- เติม DATA จาก Config.Items เสมอ (synchronous) — ไม่ผูกกับ DB
    -- เดิมโค้ดเติม DATA ทั้งก้อน "ภายใน callback ของ MySQL.query" ทำให้ถ้า query ล้มเหลว
    -- (ตาราง mjdev_economy ไม่มี / DB error) callback ไม่ถูกเรียก → DATA ว่างทั้งหมด →
    -- ทุกไอเทมขึ้น "ไม่พบข้อมูลสินค้า" (แม้ทุกไอเทมจะ RandomWhenStart คือไม่ได้ใช้ราคาจาก DB เลย)
    local isRandom = {} -- [itemName] = true ถ้าสุ่มราคา (DB overlay ด้านล่างจะไม่ทับ)
    for _, items in pairs(Config.Items) do
        for itemName, itemData in pairs(items) do
            local newData = {
                Price = 0,
                Min = itemData.Min,
                Max = itemData.Max,
                RangeChange = itemData.RangeChange,
                AmountToChange = itemData.AmountToChange,
                CurrentAmount = 0,
                Label = itemData.Label,
                Status = 'equal'
            }
            isRandom[itemName] = itemData.RandomWhenStart == true
            if isRandom[itemName] then
                newData.Price = math.random(itemData.Min, itemData.Max)
            else
                newData.Price = itemData.Min
            end
            local center = math.floor((newData.Min + newData.Max) / 2)
            newData.Status = (newData.Price > center) and 'up' or (newData.Price < center and 'down' or 'equal')
            DATA[itemName] = newData
        end
    end

    -- overlay ราคาจาก DB แบบ best-effort (เฉพาะไอเทมที่ไม่ RandomWhenStart) — ถ้า DB/ตารางมีปัญหา
    -- ก็แค่ใช้ราคาจาก Config ต่อไป DATA ไม่ว่าง (query อยู่นอก path การเติม DATA แล้ว)
    --
    -- ตาราง mjdev_economy เป็น overlay ราคาเริ่มต้นที่แอดมินตั้งเองได้ (optional) — resource นี้ "อ่าน
    -- อย่างเดียว" ไม่เคยเขียนกลับ (ราคาผันผวนทุก 15 นาทีอัปเดตแค่ใน DATA ไม่ลง DB) เดิมถ้าตารางไม่มี
    -- oxmysql จะพ่น error "Table doesn't exist" รกทุกครั้งที่ start — สร้างตารางเองด้วย IF NOT EXISTS
    -- ก่อน SELECT ให้ self-healing (ตารางว่าง = SELECT คืน 0 แถว = ใช้ราคาจาก Config ตามปกติ ไม่ error)
    MySQL.ready(function()
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `mjdev_economy` (
                `item` VARCHAR(50) NOT NULL,
                `price` INT NOT NULL,
                PRIMARY KEY (`item`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ]], {}, function()
            MySQL.query('SELECT item, price FROM mjdev_economy', {}, function(rows)
                for _, row in ipairs(rows or {}) do
                    local d = DATA[row.item]
                    if d and not isRandom[row.item] then
                        d.Price = tonumber(row.price) or d.Price
                        local center = math.floor((d.Min + d.Max) / 2)
                        d.Status = (d.Price > center) and 'up' or (d.Price < center and 'down' or 'equal')
                    end
                end
            end)
        end)
    end)

    -- Callbacks for jobs and inventory
    Core.Callback.Register("MJ-Economy:GetJob", function(source, cb)
        local xPlayer = Core.getUser(source).getUsedCharacter
        cb(xPlayer.job)
    end)

    Core.Callback.Register("MJ-Economy:getInventory", function(source, cb)
        local xPlayer = Core.getUser(source).getUsedCharacter
        if xPlayer then
            cb(VorpInv.getUserInventory(source))
        end
    end)

    -- **Economy Update Thread**
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(15 * 60000)  -- Every 15 minutes

            math.randomseed(os.time())  -- Set random seed ONCE before the loop
            
            for item, data in pairs(DATA) do
                Citizen.Wait(100)

                -- Check if the item has exceeded its AmountToChange
                if data.CurrentAmount >= data.AmountToChange then
                    local decreaseAmount = math.floor((data.CurrentAmount / data.AmountToChange) * (data.Price - data.Min))
                    data.Price = math.max(data.Price - decreaseAmount, data.Min)  -- Ensure price doesn't go below Min
                    data.CurrentAmount = 0  -- Reset sold amount tracking
                else
                    -- Random price fluctuation (small changes)
                    local priceChange = math.random(data.RangeChange[1], data.RangeChange[2])
                    data.Price = (math.random(1, 2) == 1) and (data.Price + priceChange) or (data.Price - priceChange)
                end

                -- Ensure price stays within range
                data.Price = math.max(data.Min, math.min(data.Max, data.Price))

                -- Update item status
                local center = math.floor((data.Min + data.Max) / 2)
                data.Status = (data.Price > center) and 'up' or (data.Price < center and 'down' or 'equal')
            end

            -- Send updates to all players
            TriggerClientEvent('MJ-Economy:setPrices', -1, DATA)
        end
    end)

    print('Setup World Economics')
end

RegisterServerEvent('MJ-Economy:cfx:action')
AddEventHandler('MJ-Economy:cfx:action', function(item, amount)
    local playerId = source
    local xPlayer = Core.getUser(playerId).getUsedCharacter
    local count = exports.vorp_inventory:getItemCount(playerId, nil, item)
    local itemEco = DATA[item]

    -- Ensure the item exists in the data
    if itemEco then
        -- If the player has enough items and the amount is valid
        if count >= amount and amount > 0 then
            exports.vorp_inventory:subItem(playerId, item, amount)
            xPlayer.addCurrency(0, math.abs(itemEco.Price * amount))

            -- Update current amount sold
            itemEco.CurrentAmount = itemEco.CurrentAmount + amount
            
            -- Check if total amount sold exceeds the threshold
            if itemEco.CurrentAmount > itemEco.AmountToChange then
                -- Reset current amount and calculate price adjustment
                itemEco.CurrentAmount = 0

                -- Calculate new price based on total amount sold
                local newPrice = itemEco.Price
                Wait(100)
                math.randomseed(os.time())
                Wait(100)
                local randomChanger = math.random(1, 2)
                Wait(100)
                local priceChanger = math.random(itemEco.RangeChange[1], itemEco.RangeChange[2])

                -- Adjust the price randomly up or down
                if randomChanger == 1 then
                    newPrice = newPrice + priceChanger
                else
                    newPrice = newPrice - priceChanger
                end

                -- Determine price direction
                local center = math.floor((itemEco.Min + itemEco.Max) / 2)
                if itemEco.Price > center then
                    itemEco.Status = 'up'
                elseif itemEco.Price < center then
                    itemEco.Status = 'down'
                else
                    itemEco.Status = 'equal'
                end

                -- Update item data
                DATA[item] = itemEco

                -- Send updated value to all players
                TriggerClientEvent('MJ-Economy:update', -1, item, itemEco)

                -- Apply the price decrease over time based on the total sold amount
                if itemEco.CurrentAmount >= itemEco.AmountToChange then
                    -- If the item has been sold up to the maximum, reduce the price further
                    local priceDecrease = math.floor((itemEco.CurrentAmount / itemEco.AmountToChange) * (itemEco.Price - itemEco.Min))
                    itemEco.Price = itemEco.Price - priceDecrease

                    -- Ensure the price doesn't go below the minimum value
                    if itemEco.Price < itemEco.Min then
                        itemEco.Price = itemEco.Min
                    end
                end
            end
        else
            TriggerClientEvent("pNotify:SendNotification", playerId, {
                text = 'ไม่สามารถขายได้',
                type = "success",
                timeout = 5000,
                layout = "topRight",
                queue = "left"
            })
        end
    else
        TriggerClientEvent("pNotify:SendNotification", playerId, {
            text = 'ไม่พบข้อมูลสินค้า',
            type = "error",
            timeout = 5000,
            layout = "topRight",
            queue = "left"
        })
    end
end)


RegisterServerEvent('MJ-Economy:cfx:getPrices')
AddEventHandler('MJ-Economy:cfx:getPrices', function()
    local playerId = source
    TriggerClientEvent('MJ-Economy:setPrices', playerId, DATA)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == 'MJ-Economy' then
        local playerId = source
        TriggerClientEvent('MJ-Economy:setPrices', playerId, DATA)
    end
end)

Citizen.CreateThread(function()
    Citizen.Wait(5000) 
    InitEconomy()
    print("##################################################")
    print("##                                              ##")
    print("##           \27[37mMJ DEV | Verify \27[32mSuccess\27[0m            ##")
    print("##           \27[36mThank You For Purchase\27[0m             ##")
    print("##           \27[34mVersion : 1.0 (Latest)\27[0m             ##")
    print("##                                              ##")
    print("##################################################")
    print("###### \27[36mDiscord: https://discord.gg/gHRNMDQKzb\27[0m ####")
end)