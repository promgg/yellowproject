Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) -- เช็คทุก 1 วินาที
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearbyPlayers = 0
        
        for _, player in ipairs(GetActivePlayers()) do
            local targetPed = GetPlayerPed(player)
            if targetPed ~= playerPed then
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(playerCoords - targetCoords)
                
                if distance <= Config.DistanceThreshold then
                    nearbyPlayers = nearbyPlayers + 1
                end
            end
        end
        
        if nearbyPlayers >= Config.PlayerThreshold then
            SendNUIMessage({display = true, color = Config.UIColorRed})
        else
            SendNUIMessage({display = true, color = Config.UIColorGreen})
        end
    end
end)
