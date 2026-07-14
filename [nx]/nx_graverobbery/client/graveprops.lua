NX_GR = NX_GR or {}

local SPAWN_RADIUS = 30.0
local DESPAWN_RADIUS = 35.0 -- hysteresis กันสปอน/ลบซ้ำๆ ตอนยืนคาบเส้น
local PROP_MODELS = { `p_gravemarker01x`, `p_gravemarker02x` }

local spawned = {} -- [graveId] = entityHandle

local function propModelFor(grave)
    -- สลับโมเดลตามเลขหลุมให้ดูเป็นสุสานจริง ไม่ใช่ปั๊มโมเดลเดียวซ้ำทั้งคลัสเตอร์
    local idx = tonumber(grave.id:match('_hole_(%d+)$')) or 1
    return PROP_MODELS[(idx % #PROP_MODELS) + 1]
end

local function loadModel(hash)
    RequestModel(hash)
    local deadline = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        Citizen.Wait(50)
        if GetGameTimer() > deadline then return false end
    end
    return true
end

local function spawnProp(grave)
    if spawned[grave.id] then return end
    local hash = propModelFor(grave)
    if not loadModel(hash) then return end

    local obj = CreateObject(hash, grave.coords.x, grave.coords.y, grave.coords.z, false, false, false)
    SetEntityHeading(obj, grave.heading or 0.0)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetEntityAsMissionEntity(obj, true, true)
    SetModelAsNoLongerNeeded(hash)
    spawned[grave.id] = obj
end

local function despawnProp(graveId)
    local obj = spawned[graveId]
    if obj and DoesEntityExist(obj) then
        DeleteEntity(obj)
    end
    spawned[graveId] = nil
end

CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local playerCoords = GetEntityCoords(PlayerPedId())
        for _, grave in ipairs(Config.Graves) do
            if grave.enabled then
                local dist = #(playerCoords - grave.coords)
                if not spawned[grave.id] and dist <= SPAWN_RADIUS then
                    spawnProp(grave)
                elseif spawned[grave.id] and dist > DESPAWN_RADIUS then
                    despawnProp(grave.id)
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for graveId in pairs(spawned) do
        despawnProp(graveId)
    end
end)
