-- client/cl_main.lua
-- Spawn detection, UI trigger, and teleport after selection

local VORPcore    = exports.vorp_core:GetCore()
local playerState = { cityId = nil, hasCity = false, heritageId = nil, hasHeritage = false, uiOpen = false }
local pendingSpawn = nil -- { spawn, cityName } — teleport deferred until heritage selection also completes

-- ─────────────────────────────────────────────────────────────
--  INTERNAL: Same as VORPcore.Callback.TriggerAsync, but guarantees
--  onResult(nil) fires once even if the server never responds —
--  otherwise a dropped callback leaves the player frozen forever.
-- ─────────────────────────────────────────────────────────────
local function TriggerAsyncSafe(name, timeoutMs, onResult, ...)
    local done = false
    VORPcore.Callback.TriggerAsync(name, function(result)
        if done then return end
        done = true
        onResult(result)
    end, ...)
    Citizen.SetTimeout(timeoutMs, function()
        if done then return end
        done = true
        onResult(nil)
    end)
end

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
--  INTERNAL: Complete onboarding — teleport (if a city pick is
--  still pending) then unfreeze. Shared exit point for every
--  path through the heritage step.
-- ─────────────────────────────────────────────────────────────
local function FinishHeritageFlow()
    if pendingSpawn then
        local spawn    = pendingSpawn
        pendingSpawn   = nil

        TeleportToSpawn(spawn.spawn)
        Wait(800)

        exports.pNotify:SendNotification({
            type    = 'success',
            text    = Lang.notify_city_selected:format(spawn.cityName),
            timeout = 6000,
        })
    end

    SetPlayerFrozen(false)
end

-- ─────────────────────────────────────────────────────────────
--  INTERNAL: Request heritage data from server and open UI
-- ─────────────────────────────────────────────────────────────
local function OpenHeritageSelectionUI()
    playerState.uiOpen = true
    SetPlayerFrozen(true)

    TriggerAsyncSafe("nx_cityselect:GetHeritageData", 8000, function(heritages)
        if not heritages then
            FinishHeritageFlow()
            playerState.uiOpen = false
            return
        end
        SendNUIMessage({
            action    = "OPEN",
            mode      = "heritage",
            heritages = heritages,
            lang      = {
                title         = Lang.ui_heritage_title,
                subtitle      = Lang.ui_heritage_subtitle,
                selectBtn     = Lang.ui_select_btn,
                confirmTitle  = Lang.ui_heritage_confirm_title,
                confirmMsg    = Lang.ui_heritage_confirm_msg,
                confirmYes    = Lang.ui_confirm_yes,
                confirmNo     = Lang.ui_confirm_no,
            },
        })
        SetNuiFocus(true, true)
    end)
end

-- ─────────────────────────────────────────────────────────────
--  INTERNAL: Handle confirmed heritage selection returned from UI
-- ─────────────────────────────────────────────────────────────
local function HandleHeritageSelection(heritageId)
    SetNuiFocus(false, false)

    TriggerAsyncSafe("nx_cityselect:SelectHeritage", 8000, function(result)
        playerState.uiOpen = false

        if not result or not result.success then
            local reason = result and result.reason or "unknown"
            if reason == "already_selected" then
                exports.pNotify:SendNotification({ type = 'error', text = Lang.notify_already_selected, timeout = 4000 })
            else
                exports.pNotify:SendNotification({ type = 'error', text = Lang.notify_invalid_heritage, timeout = 4000 })
            end

            Wait(1500)
            if not playerState.hasHeritage then
                OpenHeritageSelectionUI()
            else
                FinishHeritageFlow()
            end
            return
        end

        -- Success
        playerState.hasHeritage = true
        playerState.heritageId  = result.heritageId

        SendNUIMessage({ action = "CLOSE" })
        SetNuiFocus(false, false)

        TriggerEvent("nx_cityselect:Client:HeritageAssigned", result.heritageId)

        exports.pNotify:SendNotification({
            type    = 'success',
            text    = Lang.notify_heritage_selected:format(result.name),
            timeout = 6000,
        })

        FinishHeritageFlow()
    end, heritageId)
end

-- ─────────────────────────────────────────────────────────────
--  INTERNAL: Check heritage status; prompt if missing, else finish
-- ─────────────────────────────────────────────────────────────
local function CheckHeritageThenUnfreeze()
    TriggerAsyncSafe("nx_cityselect:CheckPlayerHeritage", 8000, function(result)
        if not result then
            FinishHeritageFlow()
            return
        end

        if result.hasHeritage then
            playerState.hasHeritage = true
            playerState.heritageId  = result.heritageId
            TriggerEvent("nx_cityselect:Client:HeritageAssigned", result.heritageId)
            FinishHeritageFlow()
        else
            OpenHeritageSelectionUI()
        end
    end)
end

-- ─────────────────────────────────────────────────────────────
--  INTERNAL: Request city data from server and open UI
-- ─────────────────────────────────────────────────────────────
local function OpenCitySelectionUI()
    playerState.uiOpen = true
    SetPlayerFrozen(true)

    TriggerAsyncSafe("nx_cityselect:GetCityData", 8000, function(cities)
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

    TriggerAsyncSafe("nx_cityselect:SelectCity", 8000, function(result)
        playerState.uiOpen = false

        if not result or not result.success then
            local reason = result and result.reason or "unknown"
            if reason == "full" then
                exports.pNotify:SendNotification({ type = 'error', text = Lang.notify_city_full, timeout = 4000 })
            elseif reason == "already_selected" then
                exports.pNotify:SendNotification({ type = 'error', text = Lang.notify_already_selected, timeout = 4000 })
            else
                exports.pNotify:SendNotification({ type = 'error', text = Lang.notify_invalid_city, timeout = 4000 })
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

        -- Defer teleport + welcome notification until heritage is also chosen
        pendingSpawn = { spawn = result.spawn, cityName = result.cityName }

        -- Continue straight into heritage selection (still frozen, still at old position)
        CheckHeritageThenUnfreeze()
    end, cityId)
end

-- ─────────────────────────────────────────────────────────────
--  EVENT: Character selected — check if city is needed
-- ─────────────────────────────────────────────────────────────
RegisterNetEvent("vorp:SelectedCharacter")
AddEventHandler("vorp:SelectedCharacter", function(charId)
    -- Wait for world and ped to fully load
    Wait(Config.SpawnFreezeTime)

    TriggerAsyncSafe("nx_cityselect:CheckPlayerCity", 8000, function(result)
        if not result then return end

        if result.hasCity then
            playerState.hasCity = true
            playerState.cityId  = result.cityId
            TriggerEvent("nx_cityselect:Client:CityAssigned", result.cityId)
            CheckHeritageThenUnfreeze()
        else
            -- First time — show city selection
            OpenCitySelectionUI()
        end
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  EVENT: แอดมินย้ายเมือง/เปลี่ยนเชื้อสายให้ (สั่งจาก MJ-Admin -> nx_cityselect export)
--
--  ต้องอัปเดต state ที่ cache ไว้ในเครื่องด้วย ไม่ใช่แค่ DB — ไม่งั้น export
--  GetCurrentCityId()/GetCurrentHeritageId() ที่ resource อื่นเรียก (nx_graverobbery,
--  lp_airdropteam, MJ-Airdrop ฯลฯ) จะยังคืนเมืองเก่าจนกว่าผู้เล่นจะรีล็อกอิน
--
--  cl_outfit.lua ฟัง CityChanged ตัวเดียวกันนี้เพื่อถอดโค้ทเมืองเก่าที่ใส่ค้างอยู่
-- ─────────────────────────────────────────────────────────────
RegisterNetEvent("nx_cityselect:Client:CityChanged")
AddEventHandler("nx_cityselect:Client:CityChanged", function(cityId)
    if type(cityId) ~= "string" or cityId == "" then return end
    playerState.hasCity = true
    playerState.cityId  = cityId
    TriggerEvent("nx_cityselect:Client:CityAssigned", cityId)
end)

RegisterNetEvent("nx_cityselect:Client:HeritageChanged")
AddEventHandler("nx_cityselect:Client:HeritageChanged", function(heritageId)
    if type(heritageId) ~= "string" or heritageId == "" then return end
    playerState.hasHeritage = true
    playerState.heritageId  = heritageId
    TriggerEvent("nx_cityselect:Client:HeritageAssigned", heritageId)
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
--  NUI CALLBACK: Player confirms heritage selection
-- ─────────────────────────────────────────────────────────────
RegisterNUICallback("selectHeritage", function(data, cb)
    cb("ok")
    if not playerState.uiOpen then return end
    local heritageId = SanitizeId(data.heritageId or "")
    if heritageId == "" then return end
    HandleHeritageSelection(heritageId)
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
--  NUI CALLBACK: UI requests refresh of heritage data
-- ─────────────────────────────────────────────────────────────
RegisterNUICallback("refreshHeritages", function(_, cb)
    VORPcore.Callback.TriggerAsync("nx_cityselect:GetHeritageData", function(heritages)
        cb(heritages or {})
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  NUI CALLBACK: UI closed via escape (blocked — must select)
-- ─────────────────────────────────────────────────────────────
RegisterNUICallback("closeUI", function(_, cb)
    cb("ok")
    -- Do not allow closing without selecting if first time
    if playerState.uiOpen and (not playerState.hasCity or not playerState.hasHeritage) then
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

exports("GetCurrentHeritageId", function()
    return playerState.heritageId
end)

exports("HasHeritageSelected", function()
    return playerState.hasHeritage
end)

-- ─────────────────────────────────────────────────────────────
--  Release NUI focus / unfreeze if the resource stops mid-selection
-- ─────────────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "CLOSE" })
    if playerState.uiOpen then
        SetPlayerFrozen(false)
    end
end)
