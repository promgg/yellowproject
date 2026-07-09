-- client/cl_main.lua
-- Spawn detection, UI trigger, and teleport after selection

local VORPcore    = exports.vorp_core:GetCore()
local playerState = { cityId = nil, hasCity = false, uiOpen = false }

-- ─────────────────────────────────────────────────────────────
--  INTERNAL: Freeze/unfreeze local player
-- ─────────────────────────────────────────────────────────────
local function SetPlayerFrozen(frozen)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, frozen)
    SetEntityInvincible(ped, frozen)
end

-- ─────────────────────────────────────────────────────────────
--  INTERNAL: Teleport player to a spawn point
-- ─────────────────────────────────────────────────────────────
local function TeleportToSpawn(spawnPoint)
    local ped = PlayerPedId()
    SetEntityCoords(ped, spawnPoint.x, spawnPoint.y, spawnPoint.z, false, false, false, false)
    SetEntityHeading(ped, spawnPoint.heading)
end

-- ─────────────────────────────────────────────────────────────
--  INTERNAL: Request city data from server and open UI
-- ─────────────────────────────────────────────────────────────
local function OpenCitySelectionUI()
    playerState.uiOpen = true
    SetPlayerFrozen(true)

    VORPcore.Callback.TriggerAsync("nx_cityselect:GetCityData", function(cities)
        if not cities then
            SetPlayerFrozen(false)
            playerState.uiOpen = false
            return
        end
        SendNUIMessage({
            action = "OPEN",
            cities = cities,
            lang   = {
                title         = Lang.ui_title,
                subtitle      = Lang.ui_subtitle,
                selectBtn     = Lang.ui_select_btn,
                fullLabel     = Lang.ui_full_label,
                slotsLabel    = Lang.ui_slots_label,
                confirmTitle  = Lang.ui_confirm_title,
                confirmMsg    = Lang.ui_confirm_msg,
                confirmYes    = Lang.ui_confirm_yes,
                confirmNo     = Lang.ui_confirm_no,
            },
        })
        SetNuiFocus(true, true)
    end)
end

-- ─────────────────────────────────────────────────────────────
--  INTERNAL: Handle confirmed city selection returned from UI
-- ─────────────────────────────────────────────────────────────
local function HandleCitySelection(cityId)
    SetNuiFocus(false, false)

    VORPcore.Callback.TriggerAsync("nx_cityselect:SelectCity", function(result)
        playerState.uiOpen = false

        if not result or not result.success then
            local reason = result and result.reason or "unknown"
            if reason == "full" then
                VORPcore.NotifyTip(source, Lang.notify_city_full, 4000)
            elseif reason == "already_selected" then
                VORPcore.NotifyTip(source, Lang.notify_already_selected, 4000)
            else
                VORPcore.NotifyTip(source, Lang.notify_invalid_city, 4000)
            end

            -- Re-open UI so player can pick another city
            Wait(1500)
            if not playerState.hasCity then
                OpenCitySelectionUI()
            else
                SetPlayerFrozen(false)
            end
            return
        end

        -- Success
        playerState.hasCity = true
        playerState.cityId  = result.cityId

        -- Close UI immediately
        SendNUIMessage({ action = "CLOSE" })
        SetNuiFocus(false, false)

        -- Notify
        TriggerEvent("nx_cityselect:Client:CityAssigned", result.cityId)

        -- Teleport to city spawn
        TeleportToSpawn(result.spawn)

        Wait(800)
        SetPlayerFrozen(false)

        -- Show welcome notification
        VORPcore.NotifyLeft(
            PlayerPedId(),
            result.cityName,
            Lang.notify_city_selected:format(result.cityName),
            "hud_textures", "blip_bounty_poster",
            6000, "COLOR_GOLD"
        )
    end, cityId)
end

-- ─────────────────────────────────────────────────────────────
--  EVENT: Character selected — check if city is needed
-- ─────────────────────────────────────────────────────────────
RegisterNetEvent("vorp:SelectedCharacter")
AddEventHandler("vorp:SelectedCharacter", function(charId)
    -- Wait for world and ped to fully load
    Wait(Config.SpawnFreezeTime)

    VORPcore.Callback.TriggerAsync("nx_cityselect:CheckPlayerCity", function(result)
        if not result then return end

        if result.hasCity then
            playerState.hasCity = true
            playerState.cityId  = result.cityId
            TriggerEvent("nx_cityselect:Client:CityAssigned", result.cityId)
        else
            -- First time — show city selection
            OpenCitySelectionUI()
        end
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  NUI CALLBACK: Player confirms city selection
-- ─────────────────────────────────────────────────────────────
RegisterNUICallback("selectCity", function(data, cb)
    cb("ok")
    if not playerState.uiOpen then return end
    local cityId = SanitizeCityId(data.cityId or "")
    if cityId == "" then return end
    HandleCitySelection(cityId)
end)

-- ─────────────────────────────────────────────────────────────
--  NUI CALLBACK: UI requests refresh of city data
-- ─────────────────────────────────────────────────────────────
RegisterNUICallback("refreshCities", function(_, cb)
    VORPcore.Callback.TriggerAsync("nx_cityselect:GetCityData", function(cities)
        cb(cities or {})
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  NUI CALLBACK: UI closed via escape (blocked — must select)
-- ─────────────────────────────────────────────────────────────
RegisterNUICallback("closeUI", function(_, cb)
    cb("ok")
    -- Do not allow closing without selecting if first time
    if playerState.uiOpen and not playerState.hasCity then
        SetNuiFocus(true, true)  -- keep focus locked
    end
end)

-- ─────────────────────────────────────────────────────────────
--  CLIENT EXPORT: GetCurrentCityId
-- ─────────────────────────────────────────────────────────────
exports("GetCurrentCityId", function()
    return playerState.cityId
end)

exports("HasCitySelected", function()
    return playerState.hasCity
end)
