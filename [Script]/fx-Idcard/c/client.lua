local nuiOpen = false
local nuiEffects = false
local activeCity = nil -- เมืองที่กำลังโชว์ lp_textui hold prompt อยู่ (nil = ไม่มี)

local function closeNui(clearSession)
    if not nuiOpen then return end

    nuiOpen = false
    SetNuiFocus(false, false)
    if nuiEffects then
        AnimpostfxStop("OJDominoBlur")
        Config.ShowHud()
        nuiEffects = false
    end
    SendNUIMessage({ action = "closeAll" })

    if clearSession then
        TriggerServerEvent("fx-idcard:server:closeSession")
    end
end

local function openNui(useEffects)
    nuiOpen = true
    SetNuiFocus(true, true)

    if useEffects and not nuiEffects then
        nuiEffects = true
        Config.HideHud()
        AnimpostfxPlay("OJDominoBlur")
        AnimpostfxSetStrength("OJDominoBlur", 0.5)
    end
end

RegisterNUICallback("close", function(_, cb)
    closeNui(true)
    cb({ ok = true })
end)

RegisterNUICallback("selectService", function(data, cb)
    TriggerServerEvent("fx-idcard:server:selectService", data.token, data.service)
    cb({ ok = true })
end)

RegisterNUICallback("submitCard", function(data, cb)
    TriggerServerEvent("fx-idcard:server:submitCard", data.token, data.imageUrl)
    cb({ ok = true })
end)

RegisterNetEvent("fx-idcard:client:openServiceMenu", function(payload)
    openNui(true)
    SendNUIMessage({ action = "openServiceMenu", payload = payload })
end)

RegisterNetEvent("fx-idcard:client:openCardForm", function(payload)
    openNui(true)
    SendNUIMessage({ action = "openCardForm", payload = payload })
end)

RegisterNetEvent("fx-idcard:client:closeService", function()
    closeNui(false)
end)

RegisterNetEvent("fx-idcard:client:previewCard", function(cardData)
    openNui(false)
    cardData.numberPrefix = Config.CardNumberPrefix
    SendNUIMessage({ action = "previewCard", payload = cardData })
end)

local function isOpen(settings)
    if not settings then return true end

    local hour = GetClockHours()
    return hour >= settings.open and hour <= settings.close
end

local function spawnPed(settings)
    local modelHash = GetHashKey(settings.models)
    RequestModel(modelHash)

    while not HasModelLoaded(modelHash) do
        Wait(10)
    end

    local coords = settings.coords
    local npc = CreatePed(modelHash, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)
    FreezeEntityPosition(npc, true)
    Citizen.InvokeNative(0x283978A15512B2FE, npc, true)
    SetEntityInvincible(npc, true)
    SetEntityCanBeDamaged(npc, false)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetEntityAsMissionEntity(npc, true, true)
    SetModelAsNoLongerNeeded(modelHash)

    if settings.anims and settings.anims.name then
        RequestAnimDict(settings.anims.dict)
        while not HasAnimDictLoaded(settings.anims.dict) do Wait(50) end
        TaskPlayAnim(npc, settings.anims.dict, settings.anims.name, 1.0, -1.0, -1, 1, 0, true, 0, false, 0, false)
    elseif settings.anims and settings.anims.dict then
        TaskStartScenarioInPlace(npc, GetHashKey(settings.anims.dict), 0, true, false, false, false)
    end

    return npc
end

local function createBlip(settings)
    local coords = settings.coords
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, coords.x, coords.y, coords.z)
    Citizen.InvokeNative(0x0DF2B55F717DDB10, blip, false)
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip, joaat(settings.blips.modifier))
    SetBlipSprite(blip, settings.blips.sprite, true)
    SetBlipScale(blip, settings.blips.scale)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, settings.blips.name)
    return blip
end

local function updateNpcs()
    local playerCoords = GetEntityCoords(PlayerPedId())

    for _, settings in pairs(Config.IDCardNPC) do
        local distance = #(playerCoords - vector3(settings.coords.x, settings.coords.y, settings.coords.z))
        local officeOpen = isOpen(settings.timeSettings)

        if distance < Config.PedSpawnDistance and not settings.npc and officeOpen then
            settings.npc = spawnPed(settings)
            settings.canInteract = true
        elseif settings.npc and (distance >= Config.PedSpawnDistance or not officeOpen) then
            DeletePed(settings.npc)
            settings.npc = nil
            settings.canInteract = nil
        end

        if settings.blips and not settings.blip then
            settings.blip = createBlip(settings)
        end

        if settings.blip and settings.timeSettings then
            local modifier = officeOpen and settings.blips.modifier or settings.timeSettings.blipmodifier
            Citizen.InvokeNative(0x662D364ABF16DE2F, settings.blip, joaat(modifier))
        end
    end
end

CreateThread(function()
    while true do
        updateNpcs()
        Wait(2000)
    end
end)

-- หาสำนักงานที่ใกล้ที่สุดที่เข้าระยะโต้ตอบได้ (NPC spawn อยู่จริง + สำนักงานเปิด)
local function findNearestOffice()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearestCity, nearestDist

    for city, settings in pairs(Config.IDCardNPC) do
        if settings.canInteract then
            local officeCoords = vector3(settings.coords.x, settings.coords.y, settings.coords.z)
            local dist = #(playerCoords - officeCoords)
            if dist <= settings.distance and (not nearestDist or dist < nearestDist) then
                nearestCity, nearestDist = city, dist
            end
        end
    end

    return nearestCity
end

CreateThread(function()
    while true do
        -- 100ms ระหว่างถือ hold ก็ไวพอจะจับ "เดินออกนอกระยะ/NUI เปิด" ได้ทัน ไม่ต้องรันทุกเฟรม (Wait(0))
        Wait(activeCity and 100 or 250)

        local city = nil
        if not nuiOpen then
            city = findNearestOffice()
        end

        if activeCity and city ~= activeCity then
            exports.lp_textui:CancelHold()
            activeCity = nil
        end

        if city and not activeCity then
            activeCity = city
            local settings = Config.IDCardNPC[city]
            local officeCoords = vector3(settings.coords.x, settings.coords.y, settings.coords.z)

            exports.lp_textui:TextUIHold(('[E] %s'):format(Locale("interact")), Config.InteractHoldMs or 900, function()
                activeCity = nil
                TriggerServerEvent("fx-idcard:server:openService", city)
            end, nil, { coords = officeCoords, offset = vector3(0.0, 0.0, 0.3) })
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    closeNui(true) -- แจ้ง server ปิด session ทันที ไม่ต้องรอ Config.SessionTimeout หมดอายุเอง
    if activeCity then
        exports.lp_textui:CancelHold()
        activeCity = nil
    end

    for _, settings in pairs(Config.IDCardNPC) do
        if settings.npc then DeletePed(settings.npc) end
        if settings.blip then RemoveBlip(settings.blip) end
    end
end)
