NX_GR = NX_GR or {}

local targetIds = {}
local graveState = {}

local function isAvailable(graveId)
    local state = graveState[graveId]
    return not state or state.state == 'available'
end

local function addSphereTarget(grave)
    local id = exports.ox_target:addSphereZone({
        coords = grave.coords,
        radius = grave.interaction.radius or 1.5,
        debug = Config.Debug,
        options = {
            {
                label = NX_GR.Locale('dig_grave'),
                icon = 'fa-solid fa-skull',
                distance = grave.interaction.distance or 2.0,
                canInteract = function()
                    return isAvailable(grave.id)
                end,
                onSelect = function()
                    TriggerServerEvent('nx_graverobbery:server:requestStart', grave.id)
                end,
            },
            {
                label = NX_GR.Locale('pray_grave'),
                icon = 'fa-solid fa-hands-praying',
                distance = grave.interaction.distance or 2.0,
                canInteract = function()
                    return Config.Pray.enabled
                end,
                onSelect = function()
                    TriggerServerEvent('nx_graverobbery:server:pray', grave.id)
                end,
            },
        },
    })
    targetIds[#targetIds + 1] = id
end

local function addBoxTarget(grave)
    local target = grave.target or {}
    local id = exports.ox_target:addBoxZone({
        coords = grave.coords,
        size = target.size or vec3(1.5, 1.5, 1.5),
        rotation = target.rotation or grave.heading or 0.0,
        debug = Config.Debug,
        options = {
            {
                label = NX_GR.Locale('dig_grave'),
                icon = 'fa-solid fa-skull',
                distance = grave.interaction.distance or 2.0,
                canInteract = function()
                    return isAvailable(grave.id)
                end,
                onSelect = function()
                    TriggerServerEvent('nx_graverobbery:server:requestStart', grave.id)
                end,
            },
        },
    })
    targetIds[#targetIds + 1] = id
end

local function addModelTarget(grave)
    local target = grave.target or {}
    local models = target.models or {}
    exports.ox_target:addModel(models, {
        {
            label = NX_GR.Locale('dig_grave'),
            icon = 'fa-solid fa-skull',
            distance = grave.interaction.distance or 2.0,
            canInteract = function(entity)
                return isAvailable(grave.id) and #(GetEntityCoords(entity) - grave.coords) <= (target.modelRadius or 4.0)
            end,
            onSelect = function()
                TriggerServerEvent('nx_graverobbery:server:requestStart', grave.id)
            end,
        },
    })
end

function NX_GR.RegisterTargets()
    if GetResourceState('ox_target') ~= 'started' then
        print('^1[nx_graverobbery]^7 ox_target is not started; grave targets were not registered.')
        return
    end

    for _, grave in ipairs(Config.Graves) do
        if grave.enabled then
            local targetType = grave.target and grave.target.type or 'sphere'
            if targetType == 'box' then
                addBoxTarget(grave)
            elseif targetType == 'model' then
                addModelTarget(grave)
            else
                addSphereTarget(grave)
            end
        end
    end
end

function NX_GR.ApplyGraveState(payload)
    if payload.graves then
        graveState = payload.graves
    elseif payload.graveId then
        graveState[payload.graveId] = payload
    end
end

function NX_GR.RemoveTargets()
    if GetResourceState('ox_target') ~= 'started' then return end
    for _, id in ipairs(targetIds) do
        pcall(function()
            exports.ox_target:removeZone(id)
        end)
    end
    targetIds = {}
end
