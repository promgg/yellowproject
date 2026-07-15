local RESOURCE_NAME = GetCurrentResourceName()
local EVENT_PREFIX = Config.ResourceName or 'nx_hud'
local INTEGRATION = Config.Integration or {}
local RADAR_CONFIG = Config.RadarMap or {}

local hudExplicitVisible = Config.Visibility.MainHud ~= false
local horseExplicitVisible = Config.Visibility.HorseHud ~= false
local playerReady = INTEGRATION.WaitForSelectedCharacter ~= true
local vorpUiVisible = true
local currentVoiceMode = Config.Voice.DefaultMode or 'NORMAL'
local externalStatusValues = {}
local lastHudMessage = nil
local lastHorseMessage = nil
local lastHudVisible = nil
local lastHorseVisible = nil
local lastHudRefreshAt = 0
local lastHorseRefreshAt = 0
local lastStatusPollAt = 0
local horseWasMounted = false
local debugPreviewUntil = 0
local radarMode = tostring(RADAR_CONFIG.Mode or 'horse'):lower()
local lastRadarVisible = nil
local previousRadarType = nil
local radarInitialized = false

local VALID_RADAR_MODES = {
    always = true,
    horse = true,
    off = true,
}

local unpackArgs = table.unpack

local function clamp(value, minValue, maxValue)
    value = tonumber(value)

    if not value then
        return minValue
    end

    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function nativeBool(value)
    return value == true or value == 1
end

local function getNativeRadarType()
    if type(GetMinimapType) ~= 'function' then
        return -1
    end

    local ok, radarType = pcall(GetMinimapType)
    if not ok then return -1 end
    return tonumber(radarType) or -1
end

local function setNativeRadarType(radarType)
    radarType = tonumber(radarType)
    if not radarType or type(SetMinimapType) ~= 'function' then
        return false
    end

    local ok, err = pcall(SetMinimapType, math.floor(clamp(radarType, 0, 3)))
    if not ok then
        print(('[%s] SetMinimapType failed: %s'):format(RESOURCE_NAME, tostring(err)))
        return false
    end

    return true
end

local function round(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

local function normalize(value, minValue, maxValue)
    value = tonumber(value) or 0
    minValue = tonumber(minValue) or 0
    maxValue = tonumber(maxValue) or 100

    if maxValue <= minValue then
        return clamp(value, 0, 100)
    end

    return clamp(((value - minValue) / (maxValue - minValue)) * 100, 0, 100)
end

local function encodePayload(payload)
    if type(json) == 'table' and type(json.encode) == 'function' then
        return json.encode(payload)
    end

    return nil
end

local function shouldSend(lastMessage, payload, force)
    local encoded = encodePayload(payload)

    if force or not encoded or lastMessage ~= encoded then
        return true, encoded
    end

    return false, lastMessage
end

local function safeProviderNumber(provider, ...)
    if type(provider) ~= 'function' then
        return nil
    end

    local ok, value = pcall(provider, ...)

    if not ok then
        return nil
    end

    return tonumber(value)
end

local function safeProviderTable(provider, ...)
    if type(provider) ~= 'function' then
        return nil
    end

    local ok, value = pcall(provider, ...)

    if not ok or type(value) ~= 'table' then
        return nil
    end

    return value
end

local function getResourceStateSafe(resourceName)
    if type(resourceName) ~= 'string' or resourceName == '' then
        return nil
    end

    if type(GetResourceState) ~= 'function' then
        return 'started'
    end

    local ok, state = pcall(GetResourceState, resourceName)

    if not ok then
        return nil
    end

    return state
end

local function isResourceStarted(resourceName)
    local state = getResourceStateSafe(resourceName)
    return state == 'started' or state == 'starting'
end

local function safeResourceExport(resourceName, exportName)
    if not exports or type(resourceName) ~= 'string' or type(exportName) ~= 'string' then
        return nil
    end

    if not isResourceStarted(resourceName) then
        return nil
    end

    local ok, value = pcall(function()
        local resourceExports = exports[resourceName]

        if not resourceExports or type(resourceExports[exportName]) ~= 'function' then
            return nil
        end

        return resourceExports[exportName]()
    end)

    if not ok then
        return nil
    end

    return value
end

local function statusPercent(value, maxValue, invert)
    local number = tonumber(value)

    if not number then
        return nil
    end

    maxValue = tonumber(maxValue) or 100

    local percent

    if maxValue > 100 then
        percent = normalize(number, 0, maxValue)
    else
        percent = clamp(number, 0, 100)
    end

    if invert == true then
        percent = 100 - percent
    end

    return clamp(percent, 0, 100)
end

local function invokeNativeResult(resultFactory, hash, ...)
    if type(Citizen) ~= 'table' or type(Citizen.InvokeNative) ~= 'function' or type(resultFactory) ~= 'function' then
        return nil
    end

    local args = { ... }
    args[#args + 1] = resultFactory()

    local ok, result = pcall(function()
        return Citizen.InvokeNative(hash, unpackArgs(args))
    end)

    if not ok then
        return nil
    end

    return result
end

local function invokeNativeFloat(hash, ...)
    if type(Citizen) ~= 'table' then
        return nil
    end

    return tonumber(invokeNativeResult(Citizen.ResultAsFloat, hash, ...))
end

local function invokeNativeInteger(hash, ...)
    if type(Citizen) ~= 'table' then
        return nil
    end

    return tonumber(invokeNativeResult(Citizen.ResultAsInteger, hash, ...))
end

local function entityExists(entity)
    if not entity or entity <= 0 then
        return false
    end

    if type(DoesEntityExist) ~= 'function' then
        return true
    end

    local ok, exists = pcall(DoesEntityExist, entity)
    return ok and nativeBool(exists)
end

local function isPauseMenuVisible()
    if Config.Visibility.HideOnPause ~= true or type(IsPauseMenuActive) ~= 'function' then
        return false
    end

    local ok, active = pcall(IsPauseMenuActive)
    return ok and nativeBool(active)
end

local function isDebugPreviewActive()
    return Config.Debug == true and debugPreviewUntil > 0 and type(GetGameTimer) == 'function' and GetGameTimer() < debugPreviewUntil
end

local function shouldForceRefresh(lastRefresh)
    local intervals = Config.UpdateIntervals or {}
    local interval = tonumber(intervals.ForceRefresh) or 0

    if interval <= 0 or type(GetGameTimer) ~= 'function' then
        return false, lastRefresh
    end

    local now = GetGameTimer()

    if now - lastRefresh >= interval then
        return true, now
    end

    return false, lastRefresh
end

local function getConfiguredInterval(key, fallback, minValue)
    local intervals = Config.UpdateIntervals or {}
    local value = tonumber(intervals[key]) or fallback
    minValue = tonumber(minValue)

    if minValue and value < minValue then
        return minValue
    end

    return value
end

local function normalizeVoiceMode(mode)
    local label = mode

    if type(mode) == 'number' and type(Config.Voice.ModeLabels) == 'table' then
        label = Config.Voice.ModeLabels[mode] or tostring(mode)
    end

    label = tostring(label or Config.Voice.DefaultMode or 'NORMAL')
    label = string.upper(label)

    local maxLength = tonumber(Config.Voice.MaxModeLength) or 10

    if #label > maxLength then
        label = string.sub(label, 1, maxLength)
    end

    return label
end

local function getTalkingState()
    if Config.Voice.PollTalking ~= true then
        return false
    end

    local playerId = PlayerId()

    if type(NetworkIsPlayerTalking) == 'function' then
        local ok, talking = pcall(NetworkIsPlayerTalking, playerId)

        if ok then
            return talking == true
        end
    end

    local nativeTalking = invokeNativeInteger(0x33EEF97F, playerId)
    return nativeTalking == 1
end

local function getEntityHealthPercent(entity, minHealth, maxHealth)
    if not entityExists(entity) or type(GetEntityHealth) ~= 'function' then
        return 0
    end

    local health = tonumber(GetEntityHealth(entity)) or 0
    local dynamicMax = nil

    if type(GetEntityMaxHealth) == 'function' then
        local ok, value = pcall(GetEntityMaxHealth, entity)

        if ok and tonumber(value) and tonumber(value) > 0 then
            dynamicMax = tonumber(value)
        end
    end

    return normalize(health, minHealth or 0, dynamicMax or maxHealth or 100)
end

local function getPlayerStaminaPercent(ped)
    local provided = safeProviderNumber(Config.Providers.PlayerStamina, ped)

    if provided then
        return clamp(provided, 0, 100)
    end

    local nativeValue = invokeNativeFloat(0x0FF421E467373FCF, PlayerId())

    if nativeValue then
        return clamp(nativeValue + (tonumber(Config.Player.StaminaOffset) or 0), 0, 100)
    end

    if type(GetAttributeCoreValue) == 'function' then
        local ok, coreValue = pcall(GetAttributeCoreValue, ped, 1)

        if ok and tonumber(coreValue) then
            return clamp(coreValue, 0, 100)
        end
    end

    return clamp(Config.Player.StaminaFallback, 0, 100)
end

local function normalizeStatusKey(key)
    key = tostring(key or '')

    if key == '' then
        return nil
    end

    local aliases = Config.StatusAliases or {}
    local lowerKey = string.lower(key)

    return tostring(aliases[lowerKey] or aliases[key] or key)
end

local function setExternalStatusValue(key, value)
    local normalizedKey = normalizeStatusKey(key)

    if not normalizedKey then
        return
    end

    if tonumber(value) then
        externalStatusValues[normalizedKey] = clamp(value, 0, 100)
    end
end

local function refreshMJStatusValues(force)
    local integration = Config.Integration or {}
    local statusConfig = integration.MJStatus or {}

    if statusConfig.Enabled ~= true then
        return
    end

    local now = type(GetGameTimer) == 'function' and GetGameTimer() or 0
    local interval = tonumber(statusConfig.PollInterval) or 2000

    if not force and now > 0 and lastStatusPollAt > 0 and now - lastStatusPollAt < interval then
        return
    end

    lastStatusPollAt = now

    local resourceName = statusConfig.Resource or 'MJ-STATUS'
    local exportNames = statusConfig.Exports or {}
    local statusMap = statusConfig.Map or {}
    local hunger = safeResourceExport(resourceName, exportNames.Hunger or 'setHunger')
    local thirst = safeResourceExport(resourceName, exportNames.Thirst or 'setThirst')
    local stress = safeResourceExport(resourceName, exportNames.Stress or 'setStress')

    local hungerPercent = statusPercent(hunger, statusConfig.MaxHunger or 100000, false)
    local thirstPercent = statusPercent(thirst, statusConfig.MaxThirst or 100000, false)
    local stressPercent = statusPercent(stress, statusConfig.MaxStress or 100000, statusConfig.InvertStress == true)

    if hungerPercent then
        setExternalStatusValue(statusMap.Hunger or 'food', hungerPercent)
    end

    if thirstPercent then
        setExternalStatusValue(statusMap.Thirst or 'water', thirstPercent)
    end

    if stressPercent then
        setExternalStatusValue(statusMap.Stress or 'core', stressPercent)
    end
end

local function getStatusIcons(ped)
    local providerValues = safeProviderTable(Config.Providers.StatusIcons, ped)
    local icons = {}

    for _, item in ipairs(Config.StatusIcons or {}) do
        if item.enabled ~= false and item.key then
            local key = tostring(item.key)
            local value = nil

            if providerValues then
                value = providerValues[key]
            end

            if value == nil then
                value = externalStatusValues[key]
            end

            if value == nil then
                value = item.default
            end

            icons[#icons + 1] = {
                key = key,
                icon = tostring(item.icon or key),
                value = round(clamp(value, 0, 100)),
            }
        end
    end

    return icons
end

local function getMountEntity(ped)
    if not entityExists(ped) then
        return nil
    end

    if type(IsPedOnMount) == 'function' then
        local ok, mounted = pcall(IsPedOnMount, ped)
        if not ok or not nativeBool(mounted) then
            return nil
        end
    end

    if type(GetMount) ~= 'function' then
        return nil
    end

    local mount = GetMount(ped)

    if entityExists(mount) then
        return mount
    end

    return nil
end

local function getHorseHealthPercent(horse)
    -- เดิมเรียก native พิเศษ 0x82368787EA73C0F7 (current) / 0x4700A416E8324EF3 (max) ก่อน แต่บน
    -- build นี้มันคืนค่าเพี้ยน/คนละสเกล และเพราะ 0.0 เป็น truthy ใน Lua guard เดิม
    -- (if currentHealth and maxHealth and maxHealth > 0) เลยผ่านแล้วคำนวณได้ 0% แทนที่จะตกไป
    -- fallback — ทำให้แถบเลือดม้าโชว์ว่าง/ค่าผิด. เปลี่ยนมาใช้ path เดียวกับเลือด "คน" ที่พิสูจน์แล้วว่า
    -- ถูก (GetEntityHealth + GetEntityMaxHealth ดึง max จริงแบบ dynamic ต่อม้าแต่ละตัว — bonded
    -- horse ที่ max สูงกว่าปกติก็คำนวณ % ถูก) ตัด native พิเศษที่พังทิ้ง
    return getEntityHealthPercent(horse, Config.Horse.HealthMin, Config.Horse.HealthMax)
end

local function getHorseStaminaPercent(horse)
    local provided = safeProviderNumber(Config.Providers.HorseStamina, horse)

    if provided then
        return clamp(provided, 0, 100)
    end

    local currentStamina = invokeNativeFloat(0x775A1CA7893AA8B5, horse)
    local maxStamina = invokeNativeFloat(0xCB42AFE2B613EE55, horse)

    if currentStamina and maxStamina and maxStamina > 0 then
        return normalize(currentStamina, 0, maxStamina)
    end

    if type(GetAttributeCoreValue) == 'function' then
        local ok, coreValue = pcall(GetAttributeCoreValue, horse, 1)

        if ok and tonumber(coreValue) then
            return clamp(coreValue, 0, 100)
        end
    end

    return clamp(Config.Horse.StaminaFallback, 0, 100)
end

local function getHorseConditionPercent(horse)
    local provided = safeProviderNumber(Config.Providers.HorseCondition, horse)

    if provided then
        return clamp(provided, 0, 100)
    end

    local cleanliness = invokeNativeInteger(0x147149F2E909323C, horse, 16)

    if cleanliness then
        return clamp(100 - cleanliness, 0, 100)
    end

    return clamp(Config.Horse.ConditionFallback, 0, 100)
end

local function sendConfig()
    local statusIcons = {}

    for _, item in ipairs(Config.StatusIcons or {}) do
        if item.enabled ~= false and item.key then
            statusIcons[#statusIcons + 1] = {
                key = tostring(item.key),
                icon = tostring(item.icon or item.key),
            }
        end
    end

    SendNUIMessage({
        action = 'hud:config',
        layout = Config.Layout,
        secondaryBar = {
            enabled = Config.SecondaryBar.Enabled == true,
        },
        statusIcons = statusIcons,
        radarMap = {
            enabled = RADAR_CONFIG.Enabled == true,
            mode = radarMode,
            debug = Config.Debug == true,
            theme = (RADAR_CONFIG.Map or {}).Theme,
            zoom = (RADAR_CONFIG.Map or {}).Zoom,
            layout = RADAR_CONFIG.Layout or {},
            map = RADAR_CONFIG.Map or {},
            style = RADAR_CONFIG.Style or {},
        },
    })
end

local function sendHudVisibility(force)
    local visible = hudExplicitVisible and playerReady and vorpUiVisible and not isPauseMenuVisible()

    if force or visible ~= lastHudVisible then
        SendNUIMessage({
            action = 'hud:setVisible',
            visible = visible,
        })
        lastHudVisible = visible
    end

    return visible
end

local function sendHorseVisibility(visible, force)
    visible = visible == true and hudExplicitVisible and horseExplicitVisible == true and playerReady and vorpUiVisible and not isPauseMenuVisible()

    if force or visible ~= lastHorseVisible then
        SendNUIMessage({
            action = 'horse:setVisible',
            visible = visible,
        })
        lastHorseVisible = visible
    end

    return visible
end

local function buildHudPayload()
    refreshMJStatusValues(false)

    local ped = PlayerPedId()
    local serverId = GetPlayerServerId(PlayerId())
    local health = 0
    local secondary = nil

    if entityExists(ped) then
        health = getEntityHealthPercent(ped, Config.Player.HealthMin, Config.Player.HealthMax)

        if Config.SecondaryBar.Enabled == true and Config.SecondaryBar.Source == 'stamina' then
            secondary = getPlayerStaminaPercent(ped)
        end
    end

    return {
        action = 'hud:update',
        player = {
            id = serverId,
        },
        voice = {
            mode = currentVoiceMode,
            talking = getTalkingState(),
        },
        status = {
            health = round(health),
            secondary = secondary and round(secondary) or nil,
            icons = getStatusIcons(ped),
        },
    }
end

local function sendHudUpdate(force)
    local payload = buildHudPayload()
    local shouldSendPayload, encoded = shouldSend(lastHudMessage, payload, force)

    if shouldSendPayload then
        SendNUIMessage(payload)
        lastHudMessage = encoded
    end
end

local function buildHorsePayload(horse)
    return {
        action = 'horse:update',
        horse = {
            mounted = true,
            health = round(getHorseHealthPercent(horse)),
            stamina = round(getHorseStaminaPercent(horse)),
            condition = Config.Horse.ThirdStatEnabled ~= false and round(getHorseConditionPercent(horse)) or nil,
        },
    }
end

local function sendHorseUpdate(horse, force)
    local payload = buildHorsePayload(horse)
    local shouldSendPayload, encoded = shouldSend(lastHorseMessage, payload, force)

    if shouldSendPayload then
        SendNUIMessage(payload)
        lastHorseMessage = encoded
    end
end

local function sendHorseReset()
    SendNUIMessage({
        action = 'horse:update',
        horse = {
            mounted = false,
            health = 0,
            stamina = 0,
            condition = Config.Horse.ThirdStatEnabled ~= false and 0 or nil,
        },
    })

    lastHorseMessage = nil
end

local function normalizeRadarMode(mode)
    mode = tostring(mode or ''):lower()

    if mode == 'on' then mode = 'always' end
    if mode == 'mounted' or mode == 'mount' then mode = 'horse' end
    if mode == 'none' or mode == 'false' or mode == '0' then mode = 'off' end

    if VALID_RADAR_MODES[mode] then
        return mode
    end

    return nil
end

local function loadRadarPreference()
    radarMode = normalizeRadarMode(radarMode) or 'horse'

    if RADAR_CONFIG.SavePlayerPreference ~= true or type(GetResourceKvpString) ~= 'function' then
        return
    end

    local ok, saved = pcall(GetResourceKvpString, RADAR_CONFIG.PreferenceKey or 'nx_hud:radarMode')
    local normalized = ok and normalizeRadarMode(saved) or nil
    if normalized then radarMode = normalized end
end

local function saveRadarPreference()
    if RADAR_CONFIG.SavePlayerPreference ~= true or type(SetResourceKvp) ~= 'function' then
        return
    end

    pcall(SetResourceKvp, RADAR_CONFIG.PreferenceKey or 'nx_hud:radarMode', radarMode)
end

local function shouldShowRadar(mounted)
    if RADAR_CONFIG.Enabled ~= true then return false end
    if not hudExplicitVisible or not playerReady or not vorpUiVisible or isPauseMenuVisible() then return false end
    if radarMode == 'off' then return false end
    if radarMode == 'horse' then return mounted == true end
    return radarMode == 'always'
end

local function sendRadarVisibility(mounted, force)
    local visible = shouldShowRadar(mounted == true)

    if force or visible ~= lastRadarVisible then
        SendNUIMessage({
            action = 'radar:setVisible',
            visible = visible,
            mode = radarMode,
        })
        lastRadarVisible = visible
    end

    return visible
end

local function applyNativeRadarVisibility()
    if RADAR_CONFIG.Enabled == true and RADAR_CONFIG.HideNativeRadar == true then
        setNativeRadarType(0)
    end
end

local function setRadarMode(mode, notify)
    local normalized = normalizeRadarMode(mode)
    if not normalized then return false end

    radarMode = normalized
    saveRadarPreference()
    SendNUIMessage({ action = 'radar:setMode', mode = radarMode })

    local mounted = getMountEntity(PlayerPedId()) ~= nil
    sendRadarVisibility(mounted, true)

    if notify == true then
        TriggerEvent('vorp:TipBottom', ('Radar map: %s'):format(string.upper(radarMode)), 3000)
    end

    return true
end

local function sendRadarUpdate(ped)
    if not entityExists(ped) then return end

    local coords = GetEntityCoords(ped)
    SendNUIMessage({
        action = 'radar:update',
        x = coords.x,
        y = coords.y,
        heading = GetEntityHeading(ped),
    })
end

local function notifyHudState()
    local toggleConfig = Config.Commands and Config.Commands.Toggle or {}

    if toggleConfig.Notify ~= true then
        return
    end

    TriggerEvent('vorp:TipBottom', 'HUD: ' .. (hudExplicitVisible and 'open' or 'close'), 3000)
end

local function setHudEnabled(visible, notify)
    hudExplicitVisible = visible == true

    sendHudVisibility(true)

    if not hudExplicitVisible then
        sendHorseVisibility(false, true)
    else
        sendHudUpdate(true)
    end

    sendRadarVisibility(getMountEntity(PlayerPedId()) ~= nil, true)

    if notify == true then
        notifyHudState()
    end
end

local function setPlayerReady(ready, force)
    ready = ready == true

    if playerReady == ready and force ~= true then
        return
    end

    playerReady = ready
    refreshMJStatusValues(true)
    sendHudVisibility(true)

    if playerReady then
        sendHudUpdate(true)
    else
        sendHorseVisibility(false, true)
        sendHorseReset()
    end

    sendRadarVisibility(getMountEntity(PlayerPedId()) ~= nil, true)
end

local function setVorpUiVisible(visible)
    vorpUiVisible = visible ~= false
    sendHudVisibility(true)

    if not vorpUiVisible then
        sendHorseVisibility(false, true)
    else
        sendHudUpdate(true)
    end

    sendRadarVisibility(getMountEntity(PlayerPedId()) ~= nil, true)
end

local function applyNativeHudVisibility()
    local nativeConfig = Config.NativeHud or {}

    if type(Citizen) ~= 'table' or type(Citizen.InvokeNative) ~= 'function' then
        return
    end

    local groups = {
        { enabled = nativeConfig.HidePlayerHealth, components = { 4, 5 } },
        { enabled = nativeConfig.HidePlayerStamina, components = { 0, 1 } },
        { enabled = nativeConfig.HidePlayerDeadEye, components = { 2, 3 } },
        { enabled = nativeConfig.HideHorseHealth, components = { 6, 7 } },
        { enabled = nativeConfig.HideHorseStamina, components = { 8, 9 } },
        { enabled = nativeConfig.HideHorseCourage, components = { 10, 11 } },
    }

    for _, group in ipairs(groups) do
        if group.enabled == true then
            for _, component in ipairs(group.components) do
                Citizen.InvokeNative(0xC116E6DF68DCE667, component, 2)
            end
        end
    end
end

local function sendMockHud()
    local duration = 10000

    if type(GetGameTimer) == 'function' then
        debugPreviewUntil = GetGameTimer() + duration
    end

    SendNUIMessage({
        action = 'hud:setVisible',
        visible = true,
    })

    SendNUIMessage({
        action = 'hud:update',
        player = {
            id = 9999,
        },
        voice = {
            mode = 'NORMAL',
            talking = true,
        },
        status = {
            health = 87,
            secondary = 64,
            icons = {
                { key = 'food', icon = 'food', value = 92 },
                { key = 'water', icon = 'water', value = 71 },
                { key = 'core', icon = 'core', value = 48 },
            },
        },
    })

    SendNUIMessage({
        action = 'horse:setVisible',
        visible = true,
    })

    SendNUIMessage({
        action = 'horse:update',
        horse = {
            mounted = true,
            health = 82,
            stamina = 58,
            condition = 76,
        },
    })

    SendNUIMessage({ action = 'radar:setVisible', visible = true, mode = radarMode })
    SendNUIMessage({ action = 'radar:update', x = -282.5, y = 806.5, heading = 72.0 })
end

RegisterNetEvent(EVENT_PREFIX .. ':client:setVisible', function(visible)
    setHudEnabled(visible == true, false)
end)

RegisterNetEvent(EVENT_PREFIX .. ':client:show', function()
    setHudEnabled(true, false)
end)

RegisterNetEvent(EVENT_PREFIX .. ':client:hide', function()
    setHudEnabled(false, false)
end)

RegisterNetEvent(EVENT_PREFIX .. ':client:setHorseVisible', function(visible)
    horseExplicitVisible = visible == true
    sendHorseVisibility(horseExplicitVisible, true)
end)

RegisterNetEvent(EVENT_PREFIX .. ':client:setRadarMode', function(mode)
    setRadarMode(mode, false)
end)

RegisterNetEvent(EVENT_PREFIX .. ':client:setVoiceMode', function(mode)
    currentVoiceMode = normalizeVoiceMode(mode)
    sendHudUpdate(true)
end)

AddEventHandler('pma-voice:setTalkingMode', function(mode)
    currentVoiceMode = normalizeVoiceMode(mode)
    sendHudUpdate(true)
end)

RegisterNetEvent('vorp:SelectedCharacter', function()
    local delay = tonumber((Config.Integration or {}).SelectedCharacterDelay) or 0

    CreateThread(function()
        Wait(delay)
        setPlayerReady(true, true)
    end)
end)

RegisterNetEvent('vorp_core:Client:playerLeave', function()
    setPlayerReady(false, true)
end)

RegisterNetEvent('vorp:showUi', function(active)
    if (Config.Integration or {}).FollowVorpShowUi ~= false then
        setVorpUiVisible(active)
    end
end)

RegisterNetEvent(EVENT_PREFIX .. ':client:updateStatus', function(values)
    if type(values) ~= 'table' then
        return
    end

    for key, value in pairs(values) do
        local statusValue = value

        if type(value) == 'table' then
            statusValue = value.value
        end

        setExternalStatusValue(key, statusValue)
    end

    sendHudUpdate(true)
end)

RegisterNUICallback('ready', function(_, cb)
    local ped = PlayerPedId()
    local horse = getMountEntity(ped)

    sendConfig()
    sendHudVisibility(true)
    sendHudUpdate(true)
    sendHorseVisibility(horse ~= nil, true)
    if horse then sendHorseUpdate(horse, true) end
    sendRadarVisibility(horse ~= nil, true)
    if shouldShowRadar(horse ~= nil) then sendRadarUpdate(ped) end

    cb({ ok = true, radarMode = radarMode })
end)

local toggleCommand = Config.Commands and Config.Commands.Toggle or {}

if toggleCommand.Enabled == true then
    RegisterCommand(toggleCommand.Name or 'togglehud', function()
        setHudEnabled(not hudExplicitVisible, true)
    end, false)
end

local radarCommand = Config.Commands and Config.Commands.RadarMap or {}

if radarCommand.Enabled == true then
    RegisterCommand(radarCommand.Name or 'radarmap', function(_, args)
        local requested = args and args[1] or nil

        if not setRadarMode(requested, radarCommand.Notify == true) then
            print(('[%s] usage: /%s <always|horse|off>'):format(
                RESOURCE_NAME,
                radarCommand.Name or 'radarmap'
            ))
        end
    end, false)
end

exports('showHud', function()
    setHudEnabled(true, false)
end)

exports('hideHud', function()
    setHudEnabled(false, false)
end)

exports('setHudVisible', function(visible)
    setHudEnabled(visible == true, false)
end)

exports('toggleHud', function()
    setHudEnabled(not hudExplicitVisible, false)
end)

exports('setRadarMode', function(mode)
    return setRadarMode(mode, false)
end)

exports('getRadarMode', function()
    return radarMode
end)

local testCommand = Config.Commands and Config.Commands.Test or {}

if Config.Debug == true and testCommand.Enabled == true then
    RegisterCommand(testCommand.Name or 'nx_hud_test', function(_, args)
        if args and args[1] == 'off' then
            debugPreviewUntil = 0
            sendHudVisibility(true)
            sendHorseVisibility(false, true)
            sendHudUpdate(true)
            return
        end

        sendMockHud()
    end, false)
end

CreateThread(function()
    Wait(getConfiguredInterval('StartupDelay', 1000, 0))
    previousRadarType = getNativeRadarType()
    if previousRadarType < 0 then
        previousRadarType = tonumber(RADAR_CONFIG.RestoreNativeRadarType) or 2
    end
    radarInitialized = true

    applyNativeHudVisibility()
    applyNativeRadarVisibility()

    local interval = tonumber((Config.NativeHud or {}).ReapplyInterval) or 0

    while interval > 0 do
        Wait(interval)
        applyNativeHudVisibility()
        applyNativeRadarVisibility()
    end
end)

CreateThread(function()
    Wait(getConfiguredInterval('StartupDelay', 1000, 0))
    SetNuiFocus(false, false)
    loadRadarPreference()
    currentVoiceMode = normalizeVoiceMode(currentVoiceMode)
    refreshMJStatusValues(true)

    sendConfig()
    sendHudVisibility(true)
    sendHorseVisibility(false, true)
    sendRadarVisibility(false, true)
    sendHudUpdate(true)

    if INTEGRATION.WaitForSelectedCharacter == true then
        local readyDelay = tonumber(INTEGRATION.StartupReadyDelay) or 0

        if readyDelay > 0 then
            CreateThread(function()
                Wait(readyDelay)
                setPlayerReady(true, false)
            end)
        end
    end

    while true do
        Wait(getConfiguredInterval('MainHud', 500, 250))

        if not isDebugPreviewActive() then
            local forceRefresh
            forceRefresh, lastHudRefreshAt = shouldForceRefresh(lastHudRefreshAt)

            if sendHudVisibility(forceRefresh) then
                sendHudUpdate(forceRefresh)
            end
        end
    end
end)

CreateThread(function()
    Wait(getConfiguredInterval('StartupDelay', 1000, 0))

    while true do
        Wait(getConfiguredInterval('HorseHud', 500, 250))

        if not isDebugPreviewActive() then
            local forceRefresh
            forceRefresh, lastHorseRefreshAt = shouldForceRefresh(lastHorseRefreshAt)

            local ped = PlayerPedId()
            local horse = getMountEntity(ped)

            if horse then
                horseWasMounted = true

                if sendHorseVisibility(true, forceRefresh) then
                    sendHorseUpdate(horse, forceRefresh)
                end
            else
                if horseWasMounted then
                    sendHorseReset()
                    horseWasMounted = false
                end

                sendHorseVisibility(false, forceRefresh)
            end
        end
    end
end)

CreateThread(function()
    Wait(getConfiguredInterval('StartupDelay', 1000, 0))

    while true do
        Wait(getConfiguredInterval('RadarMap', 75, 30))

        if not isDebugPreviewActive() then
            local ped = PlayerPedId()
            local mounted = getMountEntity(ped) ~= nil

            if sendRadarVisibility(mounted, false) then
                sendRadarUpdate(ped)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= RESOURCE_NAME then
        return
    end

    SendNUIMessage({
        action = 'hud:setVisible',
        visible = false,
    })

    SendNUIMessage({
        action = 'horse:setVisible',
        visible = false,
    })

    SendNUIMessage({
        action = 'radar:setVisible',
        visible = false,
    })

    if radarInitialized and RADAR_CONFIG.RestoreNativeRadarOnStop == true then
        setNativeRadarType(tonumber(RADAR_CONFIG.RestoreNativeRadarType) or previousRadarType or 2)
    end

    SetNuiFocus(false, false)
end)
