MenuData = exports.vorp_menu:GetMenuData()

local NATIVE_GET_ATTRIBUTE_BASE_RANK = 0x147149F2E909323C
local NATIVE_SET_ATTRIBUTE_BASE_RANK = 0x5DA12E025D47D4E5
local NATIVE_GET_MAX_ATTRIBUTE_RANK = 0x704674A0535A471D

-- index values match enum ePedAttribute (see SET_ATTRIBUTE_BASE_RANK)
local Attributes = {
    { key = "health", index = 0, label = "Health" },
    { key = "stamina", index = 1, label = "Stamina" },
    { key = "specialability", index = 2, label = "Special Ability" },
    { key = "courage", index = 3, label = "Courage" },
    { key = "agility", index = 4, label = "Agility" },
    { key = "speed", index = 5, label = "Speed" },
    { key = "acceleration", index = 6, label = "Acceleration" },
    { key = "bonding", index = 7, label = "Bonding" },
}

local previewPed = nil
local previewModel = nil
local previewHash = nil

-- model name -> { health = n, stamina = n, ... }, filled in from server on load
local SavedTuning = {}

-- flat, alphabetically sorted list of every horse model
local SortedHorseModels = {}
for _, model in ipairs(HorseModels) do
    table.insert(SortedHorseModels, model)
end
table.sort(SortedHorseModels, function(a, b) return a:lower() < b:lower() end)

local OpenHorseMenu -- forward declaration
local OpenTuneMenu  -- forward declaration

local function DeletePreview()
    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
    end
    previewPed = nil
    previewModel = nil
    previewHash = nil
end

local function DrawText3D(x, y, z, text)
    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(x, y, z)
    if not onScreen then return end
    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    SetTextColor(255, 255, 255, 215)
    SetTextScale(0.30, 0.30)
    SetTextFontForCurrentCommand(1)
    SetTextCentre(1)
    DisplayText(str, sx, sy)
end

CreateThread(function()
    while true do
        Wait(0)
        if previewPed and DoesEntityExist(previewPed) then
            local coords = GetEntityCoords(previewPed)
            DrawText3D(coords.x, coords.y, coords.z + 1.3, previewModel)
        else
            Wait(400)
        end
    end
end)

-- builds the element definition vorp_inputs expects for its "vorpinputs:advancedInput" popup
local function BuildTextInputPrompt(header, placeholder, pattern, errorMsg)
    return {
        type = "enableinput",
        inputType = "input",
        button = "Confirm",
        placeholder = placeholder,
        style = "block",
        attributes = {
            inputHeader = header,
            type = "text",
            pattern = pattern,
            title = errorMsg,
            style = "border-radius: 10px; background-color: ; border:none;",
        }
    }
end

local function ApplySavedTuning(model)
    local saved = SavedTuning[model]
    if not saved then return end

    for _, attr in ipairs(Attributes) do
        local value = saved[attr.key]
        if value then
            Citizen.InvokeNative(NATIVE_SET_ATTRIBUTE_BASE_RANK, previewPed, attr.index, value)
        end
    end
end

local function SpawnPreview(model)
    if model == previewModel and previewPed and DoesEntityExist(previewPed) then
        return -- already showing this one, nothing to do
    end

    DeletePreview()

    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then
        local msg = ("[HorsePreview] Invalid/unstreamed model: %s"):format(model)
        print(msg)
        TriggerEvent("vorp:TipRight", msg, 4000)
        return
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(0)
    end

    if not HasModelLoaded(hash) then
        local msg = ("[HorsePreview] Timed out loading model: %s"):format(model)
        print(msg)
        TriggerEvent("vorp:TipRight", msg, 4000)
        return
    end

    local ped = PlayerPedId()
    local offset = GetOffsetFromEntityInWorldCoords(ped, 0.0, 3.5, 0.0)
    local groundFound, groundZ = GetGroundZFor_3dCoord(offset.x, offset.y, offset.z + 5.0, false)
    local spawnZ = groundFound and groundZ or offset.z

    previewPed = CreatePed(hash, offset.x, offset.y, spawnZ, GetEntityHeading(ped) + 180.0, true, true, false, false)
    repeat Wait(0) until DoesEntityExist(previewPed)

    SetEntityInvincible(previewPed, true)
    FreezeEntityPosition(previewPed, true)
    SetBlockingOfNonTemporaryEvents(previewPed, true)
    Citizen.InvokeNative(0x283978A15512B2FE, previewPed, true) -- RandomOutfit / apply default variation
    Citizen.InvokeNative(0x98EFA132A4117BE1, previewPed, model) -- SetDebugName

    SetModelAsNoLongerNeeded(hash)

    previewModel = model
    previewHash = hash

    ApplySavedTuning(model)

    local msg = ("Model: %s | Hash: %s (0x%X)"):format(model, tostring(hash), hash)
    print("[HorsePreview] " .. msg)
    TriggerEvent("vorp:TipRight", msg, 6000)
end

local function SaveCurrentTuning()
    if not previewPed or not DoesEntityExist(previewPed) or not previewModel then
        return
    end

    local payload = {}
    for _, attr in ipairs(Attributes) do
        payload[attr.key] = Citizen.InvokeNative(NATIVE_GET_ATTRIBUTE_BASE_RANK, previewPed, attr.index)
    end

    SavedTuning[previewModel] = payload
    TriggerServerEvent("vorp_horsepreview:saveTuning", previewModel, payload)
    TriggerEvent("vorp:TipRight", ("[HorsePreview] Saved tuning for %s"):format(previewModel), 4000)
    OpenTuneMenu()
end

local function OpenAttributeInput(attrKey)
    local attr
    for _, a in ipairs(Attributes) do
        if a.key == attrKey then
            attr = a
            break
        end
    end
    if not attr or not previewPed or not DoesEntityExist(previewPed) then
        return
    end

    MenuData.CloseAll(true, true, true)

    local prompt = BuildTextInputPrompt(attr.label, "0 - 2000", "^[0-9]{1,4}$", "Enter a whole number between 0 and 2000")
    TriggerEvent("vorpinputs:advancedInput", json.encode(prompt), function(result)
        local num = tonumber(result)
        if not num then
            TriggerEvent("vorp:TipRight", "[HorsePreview] Invalid number, nothing changed", 3000)
            return OpenTuneMenu()
        end

        num = math.floor(num)
        if num < 0 then num = 0 end
        if num > 2000 then num = 2000 end

        Citizen.InvokeNative(NATIVE_SET_ATTRIBUTE_BASE_RANK, previewPed, attr.index, num)
        OpenTuneMenu()
    end)
end

OpenTuneMenu = function()
    if not previewPed or not DoesEntityExist(previewPed) then
        return OpenHorseMenu()
    end

    MenuData.CloseAll(true, true, true)

    local elements = {}
    for _, attr in ipairs(Attributes) do
        local current = Citizen.InvokeNative(NATIVE_GET_ATTRIBUTE_BASE_RANK, previewPed, attr.index)
        local max = Citizen.InvokeNative(NATIVE_GET_MAX_ATTRIBUTE_RANK, previewPed, attr.index)
        elements[#elements + 1] = {
            label = attr.label,
            value = attr.key,
            desc = ("Current: %s / Max: %s"):format(tostring(current), tostring(max))
        }
    end

    elements[#elements + 1] = { label = "Save to config file", value = "__save", desc = "Persists all values above for this exact model" }
    elements[#elements + 1] = { label = "Back to horse list", value = "__back", desc = "Pick a different horse" }

    MenuData.Open('default', GetCurrentResourceName(), 'HorseTune', {
        title = previewModel,
        subtext = "Tune attributes (0-2000)",
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        if not data.current or not data.current.value then return end

        if data.current.value == "__save" then
            return SaveCurrentTuning()
        end

        if data.current.value == "__back" then
            return OpenHorseMenu()
        end

        OpenAttributeInput(data.current.value)
    end, function(data, menu)
        menu.close(true, true, true)
        DeletePreview()
    end)
end

OpenHorseMenu = function()
    MenuData.CloseAll(true, true, true)

    local elements = {}
    for _, model in ipairs(SortedHorseModels) do
        elements[#elements + 1] = {
            label = model,
            value = model,
            desc = SavedTuning[model] and "Spawn preview (has saved tuning)" or "Spawn preview"
        }
    end

    MenuData.Open('default', GetCurrentResourceName(), 'HorsePreviewList', {
        title = "Horse Preview",
        subtext = ("%d horses"):format(#elements),
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        -- final pick: spawn (if not already showing) then go tune it
        if data.current and data.current.value then
            SpawnPreview(data.current.value)
        end
        OpenTuneMenu()
    end, function(data, menu)
        menu.close(true, true, true)
        DeletePreview()
    end, function(data, menu)
        -- fires on every highlight change while scrolling the list
        if data.current and data.current.value then
            SpawnPreview(data.current.value)
        end
    end)

    -- show a preview immediately when the menu opens, without waiting for a selection
    SpawnPreview(previewModel or SortedHorseModels[1])
end

RegisterNetEvent("vorp_horsepreview:receiveTuning", function(cache)
    SavedTuning = cache or {}
end)

RegisterCommand("horsepreview", function()
    OpenHorseMenu()
end, false)

CreateThread(function()
    Wait(1000) -- give the server-side handler a moment to register
    TriggerServerEvent("vorp_horsepreview:requestTuning")
end)

AddEventHandler("onResourceStop", function(resName)
    if resName == GetCurrentResourceName() then
        DeletePreview()
    end
end)
