
RegisterNetEvent("!!MJ-Alert-Police:sendLocation")
AddEventHandler("!MJ-Alert-Police:sendLocation", function(pos)

    TriggerEvent("pNotify:SendNotification", {
        text = "ตั้งเส้นทางไปยังจุดเกิดเหตุแล้ว",
        type = "success",
        timeout = 2000,
        layout = Config["alert_position"]
    })

    TriggerServerEvent("!MJ-Alert-Police:accept")
    SetNewWaypoint(pos)

end)

local ispressed = function(input, key)
    return IsControlPressed(input, key) or IsDisabledControlPressed(input, key)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)

        local num

        if ispressed(1, 0xE6F612E4) then
            num = 1
        elseif ispressed(1, 0x1CE6D9EB) then
            num = 2
        elseif ispressed(1, 0x4F49CC4C) then
            num = 3
        elseif ispressed(1, 0x8F9F9E58) then
            num = 4
        elseif ispressed(1, 0xAB62E997) then
            num = 5
        elseif ispressed(1, 0xA1FDE2A6) then
            num = 6
        elseif ispressed(1, 0xB03A913B) then
            num = 7
        elseif ispressed(1, 0x42385422) then
            num = 8
        end

        if ispressed(1, Config["base_key"]) and num then
            TriggerServerEvent("!MJ-Alert-Police:getLocation", num)
            Citizen.Wait(1000)
        end
    end
end)

RegisterCommand('testp', function()
    TriggerEvent("!MJ-Alert-Police:alertNet", "blackwork")
end)

SetNewWaypoint = function(pos)
    RemoveBlip(blip)
    StartGpsMultiRoute(GetHashKey("COLOR_RED"), true, true)
    marker = AddPointToGpsMultiRoute(pos.x, pos.y, pos.z)
    SetGpsMultiRouteRender(true)

    Citizen.CreateThread(function()
        local blip_modifier_hash = GetHashKey(Config['สีไอคอน'])
        blip = N_0x554d9d53f696d002(1664425300, pos)
        Citizen.InvokeNative(0x662D364ABF16DE2F, blip, blip_modifier_hash)
        SetBlipSprite(blip, Config['ไอคอนบนแมพ'], 1)
        SetBlipScale(blip, Config['ขนาดไอคอน'])
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, Config['ชื่อจุดบนแมพ'])

        local time = Config["Wait"]
        while time > 0 do
            Wait(1000)
            time = time - 1
            if time <= 1 then
                RemoveBlip(blip)
                SetGpsMultiRouteRender(false)
            end
        end

        while true do
            Wait(5)
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local dist = GetDistanceBetweenCoords(coords, pos, 1)
            if dist < Config['Route'] then
                SetGpsMultiRouteRender(false)
                RemoveBlip(blip)
                break
            end
        end

    end)
end

RegisterNetEvent('!MJ-Alert-Police:alertArea')
AddEventHandler('!MJ-Alert-Police:alertArea', function(pos)
    Citizen.CreateThread(function()
        if Config.playsound then
            SendNUIMessage({
                type = 'playsound'
            })
        end
    end)
end)

RegisterNetEvent("!MJ-Alert-Police:alertNet")
AddEventHandler("!MJ-Alert-Police:alertNet", function(event_type)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    TriggerServerEvent("!MJ-Alert-Police:getida")
    TriggerServerEvent("!MJ-Alert-Police:defaultAlert", event_type, GetCurentTownName(), pos)
end)

RegisterNetEvent("!MJ-Alert-Police:getalertNet")
AddEventHandler("!MJ-Alert-Police:getalertNet", function(event_type)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    TriggerServerEvent("!MJ-Alert-Police:defaultAlert", event_type, GetCurentTownName(), pos)
end)

function GetCurentTownName()
    local pedCoords = GetEntityCoords(PlayerPedId())
    local town_hash = Citizen.InvokeNative(0x43AD8FC02B429D33, pedCoords, 1)
    if town_hash == GetHashKey("Annesburg") then
        return "Annesburg"
    elseif town_hash == GetHashKey("Armadillo") then
        return "Armadillo"
    elseif town_hash == GetHashKey("Blackwater") then
        return "Blackwater"
    elseif town_hash == GetHashKey("BeechersHope") then
        return "BeechersHope"
    elseif town_hash == GetHashKey("Braithwaite") then
        return "Braithwaite"
    elseif town_hash == GetHashKey("Butcher") then
        return "Butcher"
    elseif town_hash == GetHashKey("Caliga") then
        return "Caliga"
    elseif town_hash == GetHashKey("cornwall") then
        return "Cornwall"
    elseif town_hash == GetHashKey("Emerald") then
        return "Emerald"
    elseif town_hash == GetHashKey("lagras") then
        return "lagras"
    elseif town_hash == GetHashKey("Manzanita") then
        return "Manzanita"
    elseif town_hash == GetHashKey("Rhodes") then
        return "Rhodes"
    elseif town_hash == GetHashKey("Siska") then
        return "Siska"
    elseif town_hash == GetHashKey("StDenis") then
        return "Saint Denis"
    elseif town_hash == GetHashKey("Strawberry") then
        return "Strawberry"
    elseif town_hash == GetHashKey("Tumbleweed") then
        return "Tumbleweed"
    elseif town_hash == GetHashKey("valentine") then
        return "Valentine"
    elseif town_hash == GetHashKey("VANHORN") then
        return "Vanhorn"
    elseif town_hash == GetHashKey("Wallace") then
        return "Wallace"
    elseif town_hash == GetHashKey("wapiti") then
        return "Wapiti"
    elseif town_hash == GetHashKey("AguasdulcesFarm") then
        return "Aguasdulces Farm"
    elseif town_hash == GetHashKey("AguasdulcesRuins") then
        return "Aguasdulces Ruins"
    elseif town_hash == GetHashKey("AguasdulcesVilla") then
        return "Aguasdulces Villa"
    elseif town_hash == GetHashKey("Manicato") then
        return "Manicato"
    else
        return "นอกเมือง"
    end
end
