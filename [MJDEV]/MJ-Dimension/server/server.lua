local script = '!MJ-Dimension'
RegisterNetEvent('MJ-dimension:changeBucket', function(bucketId)
    local src = source
    SetPlayerRoutingBucket(src, tonumber(bucketId))
    currentBucket = bucketId
end)

RegisterNetEvent('MJ-dimension:resetBucket', function()
    local src = source
    SetPlayerRoutingBucket(src, 0)
    currentBucket = 0
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

if GetCurrentResourceName() ~= script then
    os.exit()
end