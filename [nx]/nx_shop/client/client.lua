local Core = exports.vorp_core:GetCore()
local PromptGroup = GetRandomIntInRange(0, 0xffffff)
local OpenPrompt = nil
local NuiOpen = false
local CurrentStore = nil

local function notify(text, duration)
    if Core and Core.NotifyRightTip then
        Core.NotifyRightTip(text, duration or 3000)
    elseif Core and Core.NotifyObjective then
        Core.NotifyObjective(text, duration or 3000)
    end
end

local function setNui(state)
    NuiOpen = state
    SetNuiFocus(state, state)
    DisplayRadar(not state)
    SendNUIMessage({ action = state and 'show' or 'hide' })
end

local function createPrompt()
    OpenPrompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(OpenPrompt, Config.OpenKey)
    UiPromptSetText(OpenPrompt, VarString(10, 'LITERAL_STRING', Config.Text.Prompt))
    UiPromptSetEnabled(OpenPrompt, true)
    UiPromptSetVisible(OpenPrompt, true)
    UiPromptSetStandardMode(OpenPrompt, true)
    UiPromptSetGroup(OpenPrompt, PromptGroup, 0)
    UiPromptRegisterEnd(OpenPrompt)
end

local function showPrompt(label)
    UiPromptSetActiveGroupThisFrame(PromptGroup, VarString(10, 'LITERAL_STRING', label), 0, 0, 0, 0)
    return UiPromptHasStandardModeCompleted(OpenPrompt, 0)
end

local function distanceFrom(pos)
    return #(GetEntityCoords(PlayerPedId()) - pos)
end

local function isJobAllowed(store)
    if not store.jobs or next(store.jobs) == nil then
        return true
    end

    local character = LocalPlayer.state and LocalPlayer.state.Character
    local job = character and character.Job
    local grade = tonumber(character and character.Grade) or 0
    local minGrade = job and store.jobs[job]

    return minGrade ~= nil and grade >= tonumber(minGrade)
end

local function isStoreClosed(store)
    if not store.hours or not store.hours.enabled then
        return false
    end

    local hour = GetClockHours()
    if store.hours.close < store.hours.open then
        return not (hour >= store.hours.open or hour < store.hours.close)
    end

    return not (hour >= store.hours.open and hour < store.hours.close)
end

local function addBlip(store)
    if not store.blip or not store.blip.enabled or store._blip then
        return
    end

    local blip = BlipAddForCoords(1664425300, store.position.x, store.position.y, store.position.z)
    SetBlipSprite(blip, store.blip.sprite or 1475879922, false)
    SetBlipName(blip, store.blip.name or store.promptName or 'Shop')
    store._blip = blip
end

local function requestModel(model)
    local hash = joaat(model)
    if not IsModelValid(hash) then
        print(('[nx_shop] invalid npc model: %s'):format(model))
        return nil
    end

    RequestModel(hash, false)
    while not HasModelLoaded(hash) do
        Wait(50)
    end

    return hash
end

local function spawnNpc(store)
    if not store.npc or not store.npc.enabled or store._npc then
        return
    end

    local npcPos = store.npc.position
    local hash = requestModel(store.npc.model)
    if not hash then
        return
    end

    local ped = CreatePed(hash, npcPos.x, npcPos.y, npcPos.z, npcPos.w or store.heading or 0.0, false, false, false, false)
    while not DoesEntityExist(ped) do
        Wait(50)
    end

    SetRandomOutfitVariation(ped, true)
    PlaceEntityOnGroundProperly(ped)
    SetEntityCanBeDamaged(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    store._npc = ped
end

local function removeNpc(store)
    if store._npc then
        DeleteEntity(store._npc)
        store._npc = nil
    end
end

local function openShop(storeId)
    if NuiOpen then
        return
    end

    local response = Core.Callback.TriggerAwait('nx_shop:server:getShop', storeId)
    if not response or not response.ok then
        notify(response and response.message or Config.Text.NotAllowed)
        return
    end

    CurrentStore = storeId
    SetNuiFocus(true, true)
    NuiOpen = true
    DisplayRadar(false)
    SendNUIMessage({
        action = 'open',
        store = response.store,
        imagePath = Config.ItemImagePath
    })
end

RegisterNUICallback('close', function(_, cb)
    CurrentStore = nil
    setNui(false)
    cb({ ok = true })
end)

RegisterNUICallback('pay', function(data, cb)
    if not CurrentStore then
        cb({ ok = false })
        return
    end

    TriggerServerEvent('nx_shop:server:buy', CurrentStore, data and data.cart or {}, data and data.useBank == true)
    cb({ ok = true, pending = true })
end)

RegisterNetEvent('nx_shop:client:purchaseResult', function(result)
    SendNUIMessage({
        action = 'purchaseResult',
        result = result
    })

    notify(result and result.message or Config.Text.InvalidCart)

    if result and result.ok then
        CurrentStore = nil
        setNui(false)
    end
end)

CreateThread(function()
    repeat Wait(500) until LocalPlayer.state and LocalPlayer.state.IsInSession
    createPrompt()

    for _, store in pairs(Config.Stores) do
        if store.enabled ~= false then
            addBlip(store)
        end
    end

    while true do
        local sleep = 1000

        if not NuiOpen then
            local playerPed = PlayerPedId()
            if not IsEntityDead(playerPed) then
                for storeId, store in pairs(Config.Stores) do
                    if store.enabled ~= false then
                        local dist = distanceFrom(store.position)
                        local npcDistance = (store.npc and store.npc.spawnDistance) or 35.0

                        if dist <= npcDistance then
                            spawnNpc(store)
                        else
                            removeNpc(store)
                        end

                        if dist <= store.openDistance then
                            sleep = 0
                            if isStoreClosed(store) then
                                UiPromptSetEnabled(OpenPrompt, false)
                            elseif isJobAllowed(store) then
                                UiPromptSetEnabled(OpenPrompt, true)
                                if showPrompt(store.promptName or Config.Text.Prompt) then
                                    Wait(150)
                                    openShop(storeId)
                                end
                            else
                                UiPromptSetEnabled(OpenPrompt, false)
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    SetNuiFocus(false, false)
    DisplayRadar(true)

    for _, store in pairs(Config.Stores) do
        removeNpc(store)
        if store._blip then
            RemoveBlip(store._blip)
            store._blip = nil
        end
    end
end)
