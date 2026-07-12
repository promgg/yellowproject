NX_GR = NX_GR or {}
NX_GR.Cooldowns = {}

local state = {}

local function publicState(graveId)
    local entry = state[graveId]
    return {
        graveId = graveId,
        state = entry.state,
        availableAt = entry.availableAt,
    }
end

function NX_GR.Cooldowns.Init(gravesById)
    state = {}
    for graveId in pairs(gravesById) do
        state[graveId] = { state = 'available', reservedBy = nil, availableAt = nil }
    end

    local rows = MySQL.query.await('SELECT grave_id, UNIX_TIMESTAMP(available_at) AS available_at FROM nx_graverobbery_graves WHERE available_at IS NOT NULL', {})
    local current = os.time()
    for _, row in ipairs(rows or {}) do
        if state[row.grave_id] and tonumber(row.available_at or 0) > current then
            state[row.grave_id].state = 'cooldown'
            state[row.grave_id].availableAt = tonumber(row.available_at)
        end
    end
end

function NX_GR.Cooldowns.Get(graveId)
    return state[graveId]
end

function NX_GR.Cooldowns.IsAvailable(graveId)
    local entry = state[graveId]
    if not entry then return false end
    if entry.state == 'cooldown' and entry.availableAt and entry.availableAt <= os.time() then
        entry.state = 'available'
        entry.availableAt = nil
    end
    return entry.state == 'available'
end

function NX_GR.Cooldowns.Reserve(graveId, token)
    if not NX_GR.Cooldowns.IsAvailable(graveId) then return false end
    state[graveId].state = 'reserved'
    state[graveId].reservedBy = token
    return true
end

function NX_GR.Cooldowns.Release(graveId, token)
    local entry = state[graveId]
    if not entry or entry.state ~= 'reserved' or entry.reservedBy ~= token then return false end
    entry.state = 'available'
    entry.reservedBy = nil
    return true
end

function NX_GR.Cooldowns.Commit(grave, character)
    local availableAt = os.time() + ((grave.robbery.cooldownMinutes or 0) * 60)
    state[grave.id].state = 'cooldown'
    state[grave.id].reservedBy = nil
    state[grave.id].availableAt = availableAt

    local affected = MySQL.update.await(
        [[INSERT INTO nx_graverobbery_graves (grave_id, village_id, looted_at, available_at, looted_by_character)
          VALUES (?, ?, FROM_UNIXTIME(?), FROM_UNIXTIME(?), ?)
          ON DUPLICATE KEY UPDATE village_id = VALUES(village_id), looted_at = VALUES(looted_at), available_at = VALUES(available_at), looted_by_character = VALUES(looted_by_character)]],
        { grave.id, grave.villageId, os.time(), availableAt, character.charIdentifier }
    )

    return affected ~= false
end

function NX_GR.Cooldowns.ResetGrave(graveId)
    if not state[graveId] then return false end
    state[graveId] = { state = 'available', reservedBy = nil, availableAt = nil }
    MySQL.update.await('DELETE FROM nx_graverobbery_graves WHERE grave_id = ?', { graveId })
    return true
end

function NX_GR.Cooldowns.ResetVillage(villageId, gravesById)
    for graveId, grave in pairs(gravesById) do
        if grave.villageId == villageId then
            NX_GR.Cooldowns.ResetGrave(graveId)
        end
    end
end

function NX_GR.Cooldowns.ResetAll()
    for graveId in pairs(state) do
        state[graveId] = { state = 'available', reservedBy = nil, availableAt = nil }
    end
    MySQL.update.await('DELETE FROM nx_graverobbery_graves', {})
end

function NX_GR.Cooldowns.BuildPublicState()
    local graves = {}
    for graveId in pairs(state) do
        graves[graveId] = publicState(graveId)
    end
    return { graves = graves }
end

function NX_GR.Cooldowns.Sync(graveId, target)
    if graveId then
        TriggerClientEvent('nx_graverobbery:client:syncGraveState', target or -1, publicState(graveId))
    else
        TriggerClientEvent('nx_graverobbery:client:syncGraveState', target or -1, NX_GR.Cooldowns.BuildPublicState())
    end
end

function NX_GR.Cooldowns.CleanupExpired()
    local current = os.time()
    for _, entry in pairs(state) do
        if entry.state == 'cooldown' and entry.availableAt and entry.availableAt <= current then
            entry.state = 'available'
            entry.availableAt = nil
            entry.reservedBy = nil
        end
    end
end
