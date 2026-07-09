-- sv_main.lua

-- Auto-expire เป็น recurring 60s timer
CreateThread(function()
    Wait(5000)   -- รอ DB พร้อม
    while true do
        MySQL.update('UPDATE lp_marketplace SET status=? WHERE status=? AND expires_at < NOW()',
            { 'expired', 'active' })
        Wait(60000)
    end
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    print('[lp_marketplace] v1.0.0 started.')
end)
