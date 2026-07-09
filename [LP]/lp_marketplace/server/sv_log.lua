-- sv_log.lua — Discord Webhook + console log

local function SendDiscord(title, description, color, fields)
    if not Config.Log.enabled or Config.Log.webhook == '' or Config.Log.webhook == 'YOUR_DISCORD_WEBHOOK_HERE' then return end
    local embed = {
        title       = title,
        description = description,
        color       = color or Config.Log.color,
        fields      = fields or {},
        timestamp   = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        footer      = { text = 'lp_marketplace v1.0' },
    }
    local payload = json.encode({
        username   = Config.Log.botName,
        avatar_url = Config.Log.botAvatar ~= '' and Config.Log.botAvatar or nil,
        embeds     = { embed },
    })
    PerformHttpRequest(Config.Log.webhook, function() end, 'POST', payload,
        { ['Content-Type'] = 'application/json' })
end

function Log(event, title, description, fields)
    if not Config.Log.events[event] then return end
    print(('[lp_marketplace][%s] %s — %s'):format(event:upper(), title, description))
    SendDiscord(title, description, nil, fields)
end
