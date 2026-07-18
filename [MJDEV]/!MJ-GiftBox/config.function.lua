
MJDEV = {
    DiscordLog = function(message, source)
        if Config["Discord"].Webhook and Config["Discord"].Webhook ~= '' then
            PerformHttpRequest(Config["Discord"].Webhook, function(err, text, headers) end, 'POST', json.encode({
                username = 'Gift Box Log',
                content = message
            }), { ['Content-Type'] = 'application/json' })
        else
            if Config.Debug then
                print('[DEBUG] ไม่พบการตั้งค่า Webhook URL')
            end
        end
    end,    
    HorseSQL = function(source, xPlayer, data)
        local identifier = xPlayer.identifier
        local charid = xPlayer.charIdentifier
        local name = data.NameH
        local model = data.ModelH
        local gender = data.GenderH -- male และ female
        local captured = 0

        MySQL.query.await('INSERT INTO `player_horses` (identifier, charid, name, model, gender, captured) VALUES (?, ?, ?, ?, ?, ?)',
        { identifier, charid, name, model, gender, captured })
        TriggerClientEvent("pNotify:SendNotification", source, {
            text = '<strong class="green-text">คุณได้รับม้า !</strong>',
            type = "success",
            timeout = 3000,
            layout = "topRight",
            queue = "global"
        })
    end
}
