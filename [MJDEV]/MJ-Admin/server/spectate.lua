--- Logic for starting to spectate + authorization + routing buckets
--- @param targetId number The player id to spectate.
local function handleSpectatePlayer(targetId)
    local src = source
    -- Sanity as this is still converted tonumber on client side
    if type(targetId) ~= 'string' and type(targetId) ~= 'number' then
        return
    end
    targetId = tonumber(targetId)

    local allow = true

    if allow then
        local targetPed = GetPlayerPed(targetId)
        -- Lets exit if the target doesn't exist
        if not targetPed then
            return
        end
        -- checking if spectator and target are on the same routing bucket
        local targetBucket = GetPlayerRoutingBucket(targetId)
        local srcBucket = GetPlayerRoutingBucket(src)
        local sourcePlayerStateBag = Player(src).state
        if srcBucket ~= targetBucket then
            -- if there was a routing bucket set, we shouldn't overwrite it due to the cycle feature
            if sourcePlayerStateBag.__spectateReturnBucket == nil then
                sourcePlayerStateBag.__spectateReturnBucket = srcBucket
            end
            SetPlayerRoutingBucket(src, targetBucket)
        end
        TriggerClientEvent('MJDEV1999:spectate:start', src, targetId, GetEntityCoords(targetPed))
    end
end

RegisterNetEvent('MJDEV1993:req:spectate:start', handleSpectatePlayer)

--- Called to get the previous/next player to cycle to
--- @param currentTargetId number The current target id.
--- @param isNextPlayer boolean If we should cycle to the next player or not.
RegisterNetEvent('MJDEV1993:req:spectate:cycle', function(currentTargetId, isNextPlayer)
    local src = source
    local onlinePlayers = {}

    TriggerEvent("MJDEV-FlagWar:getData", function(GetPlayersFlagWar)
        onlinePlayers = GetPlayersFlagWar
    end)

    if #onlinePlayers <= 2 then
        return TriggerClientEvent('MJDEV1999:spectate:cycleFailed', src)
    end

    onlinePlayers[src] = nil

    -- Find next target
    local nextTargetId
    local currentTargetServerIndex = tableIndexOf(onlinePlayers, tostring(currentTargetId))

    if currentTargetServerIndex < 0 then
        debugPrint('Current spectate target id not found for online players, resetting to onlinePlayers[1]')
        nextTargetId = onlinePlayers[1]
        -- TODO: the correct thing would be to do a while to find the corect next/rev, based on value and not index
    else
        if isNextPlayer then
            nextTargetId = onlinePlayers[currentTargetServerIndex + 1] or onlinePlayers[1]
        else
            nextTargetId = onlinePlayers[currentTargetServerIndex - 1] or onlinePlayers[#onlinePlayers]
        end

    end

    print(nextTargetId)

    handleSpectatePlayer(nextTargetId)
end)

RegisterNetEvent('MJDEV1993:req:spectate:end', function()
    local src = source
    local allow = true
    if allow then
        local sourcePlayerStateBag = Player(src).state
        -- If this is nil, assume that no routing bucket change is needed,
        -- as it wasn't stored
        local prevRoutBucket = sourcePlayerStateBag.__spectateReturnBucket
        -- Since lua treats 0 as truthy, actually don't need to handle
        -- explicit nil check for int 0
        if prevRoutBucket then
            SetPlayerRoutingBucket(src, prevRoutBucket)
            sourcePlayerStateBag.__spectateReturnBucket = nil
        end
    end
end)

function PlayerHasTxPermission(src)
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(src) or nil
    if playerGroup == 'admin' then
        return true
    else
        return false
    end
end

function debugPrint(a)
    print(a)
end

function tableIndexOf(tgtTable, value)
    for i = 1, #tgtTable do
        if tgtTable[i] == value then
            return i
        end
    end
    return -1
end
