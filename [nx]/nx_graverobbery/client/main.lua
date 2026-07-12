NX_GR = NX_GR or {}

RegisterNetEvent('nx_graverobbery:client:startSession', function(payload)
    NX_GR.PlayDigSession(payload)
end)

RegisterNetEvent('nx_graverobbery:client:cancelSession', function(messageKey)
    NX_GR.CleanupAnimation()
    if messageKey then
        NX_GR.Notify(NX_GR.Locale(messageKey), 'error')
    end
end)

RegisterNetEvent('nx_graverobbery:client:receiveAlert', function(payload)
    NX_GR.ReceiveAlert(payload)
end)

RegisterNetEvent('nx_graverobbery:client:syncGraveState', function(payload)
    NX_GR.ApplyGraveState(payload)
end)

RegisterNetEvent('nx_graverobbery:client:startPray', function(payload)
    NX_GR.PlayPray(payload)
end)

CreateThread(function()
    Wait(1000)
    NX_GR.RegisterTargets()
    TriggerServerEvent('nx_graverobbery:server:requestState')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    NX_GR.CleanupAnimation()
    NX_GR.CleanupBlips()
    NX_GR.RemoveTargets()
end)
