-- server
local VORPcore = {}

TriggerEvent("getCore", function(core)
    VORPcore = core
end)

local Inventory = exports.vorp_inventory:vorp_inventoryApi()

-- ฟังก์ชันสุ่มรางวัล
local function getRandomReward(useitem)
    for _, boxData in ipairs(Config.Rewards) do
        if boxData.useitem == useitem then
            local randomNumber = math.random(1, 100)
            local accumulatedChance = 0

            for _, reward in ipairs(boxData.rewards) do
                accumulatedChance = accumulatedChance + reward.chance
                if randomNumber <= accumulatedChance then
                    local amount = math.random(reward.amountMin, reward.amountMax)
                    return {
                        name = reward.name,
                        type = reward.type,
                        amount = amount,
                        itemName = reward.itemName or nil
                    }
                end
            end
        end
    end
    return nil -- ไม่มีรางวัล
end

-- ลงทะเบียนไอเท็มที่สามารถใช้ได้
for _, boxData in ipairs(Config.Rewards) do
    if boxData.useitem then
        Inventory.RegisterUsableItem(boxData.useitem, function(data)
            local src = data.source
            local itemName = boxData.useitem

            local useitem = exports.vorp_inventory:getItem(src, itemName)

            if useitem then
                exports.vorp_inventory:subItem(src, itemName, 1)
                exports.vorp_inventory:closeInventory(src)

                local reward = getRandomReward(itemName) -- สุ่มรางวัล
                if reward then
                    TriggerClientEvent("scratchTicket:showUI", src, reward)
                end
            else
                TriggerClientEvent("vorp:showNotification", src, "คุณไม่มี " .. itemName .. " ในตัว!")
            end
        end)
    end
end

RegisterNetEvent("scratchTicket:giveReward")
AddEventHandler("scratchTicket:giveReward", function(rewardData)
    local src = source
    local xPlayer = VORPcore.getUser(src).getUsedCharacter

    if not xPlayer or not rewardData then
        print("[ERROR] scratchTicket:giveReward - ข้อมูลไม่ถูกต้อง")
        return
    end

    if rewardData.type == "money" then
        xPlayer.addCurrency(0, rewardData.amount)
    elseif rewardData.type == "gold" then
        xPlayer.addCurrency(1, rewardData.amount)
    elseif rewardData.type == "item" then
        if rewardData.itemName then
            exports.vorp_inventory:addItem(src, rewardData.itemName, rewardData.amount)
        else
            print("[ERROR] scratchTicket:giveReward - itemName เป็น nil")
        end
    end

    TriggerClientEvent("vorp:showNotification", src, "คุณได้รับ " .. rewardData.name .. " x" .. rewardData.amount .. "!")
end)


Citizen.CreateThread(function()
    Citizen.Wait(5000) 
    print("##################################################")
    print("##                                              ##")
    print("##           \27[37mMJ DEV | Verify \27[32mSuccess\27[0m            ##")
    print("##           \27[36mThank You For Purchase\27[0m             ##")
    print("##           \27[34mVersion : 1.0 (Latest)\27[0m             ##")
    print("##                                              ##")
    print("##################################################")
    print("###### \27[36mDiscord: https://discord.gg/gHRNMDQKzb\27[0m ####")
end)
