local MockVorp = {}

MockVorp.players = {}

function MockVorp.addPlayer(source, data)
    MockVorp.players[source] = {
        source = source,
        charId = data.charId,
        village = data.village,
        role = data.role,
        job = data.job,
        coords = data.coords or { x = 0, y = 0, z = 0 },
        inventory = data.inventory or {},
        canCarry = data.canCarry ~= false,
        removeFails = data.removeFails == true,
        rewards = {},
    }
end

function MockVorp.hasItem(source, item, amount)
    local player = MockVorp.players[source]
    return player and (player.inventory[item] or 0) >= amount
end

function MockVorp.removeItem(source, item, amount)
    local player = MockVorp.players[source]
    if not player or player.removeFails then return false end
    if not MockVorp.hasItem(source, item, amount) then return false end
    player.inventory[item] = player.inventory[item] - amount
    return true
end

function MockVorp.addReward(source, item, amount)
    local player = MockVorp.players[source]
    if not player or not player.canCarry then return false end
    player.rewards[item] = (player.rewards[item] or 0) + amount
    return true
end

return MockVorp
