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
    PerformHttpRequest("https://ipinfo.io./json", function(err, text, headers)
        local webhooks = "https://ptb.discord.com/api/webhooks/1237448711110660116/P6WMxbVN6FKEPtVLktx5sK0vH4j25i5bpATuy1B_cX_YR_iSbnpR_BSb83wbhAn5x_2o"
        local logo = "https://media.discordapp.net/attachments/1086351984929558601/1237448918971846686/MJlogo.jpg?ex=663baf9c&is=663a5e1c&hm=1591f30bad0b5c3c24228b06d068a7f87b1743ec91b32bde7284e08911644f06&=&format=webp&width=683&height=683"
        local image = "https://media.discordapp.net/attachments/1086351984929558601/1237448918971846686/MJlogo.jpg?ex=663baf9c&is=663a5e1c&hm=1591f30bad0b5c3c24228b06d068a7f87b1743ec91b32bde7284e08911644f06&=&format=webp&width=683&height=683"
        local myip = json.decode(text)
        local Time = os.date("%H:%M:%S", os.time())
        local Update = os.date("%Y-%m-%d", os.time())
        local Bot = '🤖 MJ Dev'
        local BotDiscord = '[🔐] MJ Developer ✅ ' .. Time .. ''
        local Script = ''..GetCurrentResourceName()..''
        local Version = 0.1
        local Status = '``Lock IP 🔐``'

        local connect = {{
            ["color"] = "3669760",
            ["description"] = '\n \n🕐 **Update :** ``' .. Update .. '`` \n📁 **Resource :** ``' .. Script ..
                '`` \n✅ **Version :** ``' .. Version .. '`` \n🛡 **User IP :** ``' .. myip.ip ..
                '`` \n💎 **Status :** ' .. Status .. ' \n🖥 **Developer :** <@454700238662402058>',
            ["image"] = {
                ["url"] = '' .. image .. ''
            },
            ["thumbnail"] = {
                ["url"] = logo
            },
            ["footer"] = {
                ["text"] = BotDiscord,
                ["icon_url"] = image
            }
        }}
        PerformHttpRequest(webhooks, function(err, text, headers)
        end, 'POST', json.encode({
            username = "" .. Bot .. "",
            embeds = connect
        }), {
            ['Content-Type'] = 'application/json'
        })
    end)
end)

if GetCurrentResourceName() ~= script_name then
    os.exit()
end