script_name = 'lp_airdropteam'

Citizen.CreateThread(function()
    Wait(1500)
    TriggerServerEvent(script_name .. ":CL:GetEvent_Airdrop")
end)

RegisterNetEvent(script_name .. ":SV:GetEvent_Airdrop")
AddEventHandler(script_name .. ":SV:GetEvent_Airdrop", function()
    if GetCurrentResourceName() == script_name then
        print('^2ResourceName ^0' .. script_name)
        MJDEV_GetEventAirdrop()

        -- Sync ongoing airdrop state (so crash/reconnect will see same state)
        Wait(250)
        TriggerServerEvent(script_name .. ":SV:RequestSync")
    end
end)
