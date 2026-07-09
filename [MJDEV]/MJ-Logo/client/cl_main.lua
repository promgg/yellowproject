
local possiblePositions = {
    ['esquerda'] = true,
    ['direita'] = true,
    ['centro'] = true,
    ['off'] = false,
    ['on'] = false
}

RegisterCommand('logo', function(source, args)
    if args[1] and args[1] ~= '' then
        local pos = string.lower(args[1])

        if possiblePositions[pos] then
            changeDisplay(pos)
        end
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        CreateThread(function()
            Wait(300)
            SendNUIMessage({
                type = "ui",
                display = true
            })

        end)

    end

end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CreateThread(function()
            Wait(300)
            SendNUIMessage({
                type = "ui",
                display = false
            })

        end)
    end
end)

function changeDisplay(pos)
    SendNUIMessage({
        type = "pos",
        position = pos
    })

end
