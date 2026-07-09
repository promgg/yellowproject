-- MJ-Itemnotify/server.lua
-- Shim: vorp_inventory calls exports['MJ-Itemnotify']:notification(source, config)
-- We forward it as a vorp:TipRight client event

exports('notification', function(source, config)
    if not source or source == 0 then return end
    local title = config.title or ''
    local desc  = config.description or ''
    local time  = config.time or 4000
    local msg   = title ~= '' and (title .. ' ' .. desc) or desc
    TriggerClientEvent('vorp:TipRight', source, msg, time)
end)
