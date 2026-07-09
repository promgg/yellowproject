local script_name = "MJ-Animal"
local VORPcore = exports.vorp_core:GetCore()
local VorpInv = exports.vorp_inventory:vorp_inventoryApi()
local PlayersAnimals = {}

RegisterServerEvent(script_name .. ":CL:GetEvent_Animal")
AddEventHandler(script_name .. ":CL:GetEvent_Animal", function(name)
    TriggerClientEvent(script_name .. ":SV:GetEvent_Animal", source)
end)

-- Check if player has item
VORPcore.addRpcCallback('MJ-Animal:checkHasItem', function(source, cb, itemName)
    local src = source
    local xPlayer = VORPcore.getUser(src).getUsedCharacter
    local itemCount = VorpInv.getItemCount(src, itemName)
    if itemCount and itemCount > 0 then 
        exports.vorp_inventory:subItem(src, itemName, 1)
        Config.SendNotification_Sv(src, 'คุณให้อาหารสัตว์สำเร็จ', "success")
        SendDiscordLog("🐾 ให้อาหารสัตว์", ("ผู้เล่น **%s** ได้ให้อาหารสัตว์ (%s)"):format(GetPlayerName(source), itemName), 3066993)
        cb(true)
    else
        cb(false)
    end
end)

-- Check if player has exact amount of money
VORPcore.addRpcCallback('MJ-Animal:CheckMoney', function(source, cb, amount)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local money = xPlayer.money -- Correct way to get money in VORPcore
    if money >= tonumber(amount) then  -- Check if the player has enough money
        xPlayer.removeCurrency(0, tonumber(amount))
        Config.SendNotification_Sv(source, ("คุณจ่ายเงิน %s"):format(tostring(amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")), "success")
        SendDiscordLog("💰 จ่ายเงิน", ("ผู้เล่น **%s** จ่ายเงิน **$%s**"):format(GetPlayerName(source), tostring(amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")), 15158332)
        cb(money)
    else
        Config.SendNotification_Sv(source, 'คุณมีเงินไม่เพียงพอ', "error")
        cb(false)
    end
end)

-- Function to handle animal drop loots
RegisterServerEvent(script_name .. ":SV:CheckHealth")
AddEventHandler(script_name .. ":SV:CheckHealth", function(itemName, amount)
    local src = source
    local xPlayer = VORPcore.getUser(src).getUsedCharacter

    if xPlayer then
        exports.vorp_inventory:addItem(src, itemName, amount)
        Config.SendNotification_Sv(src, ("คุณได้รับ %s จำนวน %d"):format(itemName, amount), "success")
        SendDiscordLog("📦 รับไอเทม", ("ผู้เล่น **%s** ได้รับ **%d**x %s"):format(GetPlayerName(src), amount, itemName), 3447003)
    end
end)


function SendDiscordLog(title, description, color)
    local embedData = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color,
            ["footer"] = {
                ["text"] = "MJ-Animal Logs",
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    PerformHttpRequest(Config['DiscordWebhook'], function(err, text, headers) end, "POST", json.encode({
        username = "MJ-Animal Logs",
        embeds = embedData
    }), { ["Content-Type"] = "application/json" })
end


-- Cleanup animals on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == script_name then
        for playerId, animalData in pairs(PlayersAnimals) do
            for _, animal in pairs(animalData) do
                TriggerClientEvent(script_name .. ":CL:DeleteAnimal", playerId, animal.entity)
            end
        end
    end
end)

if GetCurrentResourceName() ~= script_name then
    os.exit()
end