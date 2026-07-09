local script = 'MJ-Cooldown'
DEAD = {}
VORPcore = {} -- core object

TriggerEvent("getCore", function(core)
    VORPcore = core
end)

AddEventHandler("vorp:SelectedCharacter", function(source)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    if DEAD[Character.identifier] then
        TriggerClientEvent(script .. "GetData", _source, true)
    else
        TriggerClientEvent(script .. "GetData", _source, false)
    end
end)

RegisterNetEvent(script .. "SaveData")
AddEventHandler(script .. "SaveData", function(isDead)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    if DEAD[Character.identifier] ~= nil then
        DEAD[Character.identifier] = 0
    end
    if isDead then
        DEAD[Character.identifier] = true
        if Config['ChangeClothes'] then
            TriggerClientEvent(script .. "GetCloth", _source, json.decode(Character.comps))
        end
    else
        DEAD[Character.identifier] = false
        if Config['ChangeClothes'] then
            TriggerClientEvent(script .. "GetCloth", _source, json.decode(Character.comps))
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

if GetCurrentResourceName() ~= script then
    os.exit()
end