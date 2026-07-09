local resourceName = GetCurrentResourceName()
local runtimeOffsetY = nil
local nativeWarningShown = false

local function debugLog(message)
    if Config.Debug then
        print(('[%s] %s'):format(resourceName, message))
    end
end

local function warnOnce(message)
    if nativeWarningShown then
        return
    end

    nativeWarningShown = true
    print(('[%s] %s'):format(resourceName, message))
end

local function asNumber(value, fallback)
    local number = tonumber(value)

    if number == nil then
        return fallback
    end

    return number
end

local function canSetMinimapPosition()
    return type(SetMinimapComponentPosition) == 'function'
end

local function refreshMinimap()
    if not Config.Apply.RefreshBigmap then
        return
    end

    if type(SetBigmapActive) == 'function' then
        local ok = pcall(SetBigmapActive, true, false)
        Wait(0)

        if ok then
            pcall(SetBigmapActive, false, false)
        end
    elseif type(SetRadarBigmapEnabled) == 'function' then
        local ok = pcall(SetRadarBigmapEnabled, true, false)
        Wait(0)

        if ok then
            pcall(SetRadarBigmapEnabled, false, false)
        end
    end
end

local function getLayout(reset)
    local layout = Config.Layout or {}

    return {
        alignX = layout.AlignX or 'L',
        alignY = layout.AlignY or 'B',
        offsetX = reset and 0.0 or asNumber(layout.OffsetX, 0.0),
        offsetY = reset and 0.0 or asNumber(runtimeOffsetY, asNumber(layout.OffsetY, 0.0)),
        scale = asNumber(layout.Scale, 1.0),
        components = layout.Components or {},
    }
end

local function applyComponent(name, component, layout)
    local x = asNumber(component.X, 0.0) + layout.offsetX + asNumber(component.OffsetX, 0.0)
    local y = asNumber(component.Y, 0.0) + layout.offsetY + asNumber(component.OffsetY, 0.0)
    local w = asNumber(component.W, 0.0) * layout.scale * asNumber(component.ScaleX, 1.0)
    local h = asNumber(component.H, 0.0) * layout.scale * asNumber(component.ScaleY, 1.0)

    return pcall(SetMinimapComponentPosition, name, layout.alignX, layout.alignY, x, y, w, h)
end

local function applyMinimapPosition(reason, reset)
    if not Config.Enabled then
        return false
    end

    if not canSetMinimapPosition() then
        warnOnce('SetMinimapComponentPosition is not available in this RedM runtime; minimap position was not changed.')
        return false
    end

    local layout = getLayout(reset)

    for name, component in pairs(layout.components) do
        local ok, err = applyComponent(name, component, layout)

        if not ok then
            warnOnce(('Failed to apply minimap component "%s": %s'):format(name, err or 'unknown error'))
            return false
        end
    end

    refreshMinimap()
    debugLog(('applied minimap layout (%s), offsetY=%s'):format(reason or 'manual', tostring(layout.offsetY)))
    return true
end

local function runInitialApply()
    Wait(asNumber(Config.Apply.StartDelay, 1500))

    local attempts = math.max(1, asNumber(Config.Apply.InitialAttempts, 1))
    local interval = math.max(250, asNumber(Config.Apply.InitialInterval, 1500))

    for _ = 1, attempts do
        applyMinimapPosition('startup', false)
        Wait(interval)
    end
end

CreateThread(function()
    if not Config.Enabled then
        return
    end

    runInitialApply()

    if not Config.Apply.Persistent then
        return
    end

    local interval = math.max(500, asNumber(Config.Apply.PersistentInterval, 1500))

    while true do
        Wait(interval)
        applyMinimapPosition('persistent', false)
    end
end)

RegisterNetEvent('vorp:SelectedCharacter', function()
    CreateThread(function()
        Wait(1500)
        applyMinimapPosition('vorp:selectedCharacter', false)
    end)
end)

RegisterNetEvent('nx_minimap:client:apply', function(offsetY)
    if offsetY ~= nil then
        runtimeOffsetY = asNumber(offsetY, runtimeOffsetY)
    end

    applyMinimapPosition('event', false)
end)

RegisterNetEvent('nx_minimap:client:reset', function()
    runtimeOffsetY = nil
    applyMinimapPosition('event-reset', true)
end)

RegisterCommand(Config.Commands.Apply, function()
    applyMinimapPosition('command', false)
end, false)

RegisterCommand(Config.Commands.Reset, function()
    runtimeOffsetY = nil
    applyMinimapPosition('command-reset', true)
end, false)

RegisterCommand(Config.Commands.SetY, function(_, args)
    runtimeOffsetY = asNumber(args and args[1], Config.Layout.OffsetY)
    applyMinimapPosition('command-set-y', false)
    print(('[%s] minimap OffsetY set to %s'):format(resourceName, tostring(runtimeOffsetY)))
end, false)

exports('apply', function(offsetY)
    if offsetY ~= nil then
        runtimeOffsetY = asNumber(offsetY, runtimeOffsetY)
    end

    return applyMinimapPosition('export', false)
end)

exports('reset', function()
    runtimeOffsetY = nil
    return applyMinimapPosition('export-reset', true)
end)
