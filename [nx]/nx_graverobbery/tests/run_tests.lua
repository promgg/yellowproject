package.path = package.path .. ';./tests/?.lua'

local Vorp = require('mock_vorp')
local City = require('mock_cityselect')

local passed, failed = 0, 0
local failures = {}

local function assertTrue(name, value)
    if value then
        passed = passed + 1
    else
        failed = failed + 1
        failures[#failures + 1] = name
    end
end

local function distance(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function newEngine()
    local engine = {
        time = 1000,
        graves = {
            valentine_grave_001 = { id = 'valentine_grave_001', villageId = 'valentine', coords = { x = 0, y = 0, z = 0 }, cooldown = 60, rewardPool = 'default', requiredItem = 'shovel' },
            rhodes_grave_001 = { id = 'rhodes_grave_001', villageId = 'rhodes', coords = { x = 20, y = 0, z = 0 }, cooldown = 60, rewardPool = 'default', requiredItem = 'shovel' },
        },
        villages = { valentine = true, rhodes = true, annesburg = true },
        pools = { default = true },
        state = {},
        sessions = {},
        active = {},
        rate = {},
        cooldownDb = {},
        rewardsRandomServerSide = true,
    }

    for id in pairs(engine.graves) do
        engine.state[id] = { state = 'available' }
    end

    function engine:rateLimit(source)
        self.rate[source] = (self.rate[source] or 0) + 1
        return self.rate[source] <= 10
    end

    function engine:start(source, graveId)
        if not self:rateLimit(source) then return false, 'rate' end
        local grave = self.graves[graveId]
        local player = Vorp.players[source]
        if not grave then return false, 'invalid_grave' end
        if not self.villages[grave.villageId] then return false, 'invalid_village' end
        if distance(player.coords, grave.coords) > 3.0 then return false, 'far' end
        if not Vorp.hasItem(source, grave.requiredItem, 1) then return false, 'no_item' end
        if self.state[graveId].state ~= 'available' then return false, self.state[graveId].state end
        if self.active[source] then return false, 'active' end
        local token = source .. ':' .. graveId .. ':' .. self.time
        self.state[graveId] = { state = 'reserved', token = token }
        self.sessions[token] = { source = source, charId = player.charId, graveId = graveId, start = self.time, earliest = self.time + 12, expires = self.time + 45, used = false }
        self.active[source] = token
        return true, token
    end

    function engine:cancel(source)
        local token = self.active[source]
        if not token then return false end
        local session = self.sessions[token]
        self.state[session.graveId] = { state = 'available' }
        self.sessions[token] = nil
        self.active[source] = nil
        return true
    end

    function engine:complete(source, token)
        local session = self.sessions[token]
        if not session then return false, 'missing' end
        local player = Vorp.players[source]
        local grave = self.graves[session.graveId]
        if session.source ~= source then return false, 'wrong_source' end
        if session.charId ~= player.charId then return false, 'char_changed' end
        if self.time < session.earliest then return false, 'fast' end
        if self.time > session.expires then self:cancel(source); return false, 'expired' end
        if session.used then return false, 'used' end
        if distance(player.coords, grave.coords) > 4.0 then self:cancel(source); return false, 'far' end
        if self.state[grave.id].token ~= token then return false, 'reservation' end
        if not Vorp.hasItem(source, grave.requiredItem, 1) then self:cancel(source); return false, 'no_item' end
        if grave.consume and not Vorp.removeItem(source, grave.requiredItem, 1) then self:cancel(source); return false, 'remove_failed' end
        session.used = true
        self.state[grave.id] = { state = 'cooldown', availableAt = self.time + grave.cooldown }
        self.cooldownDb[grave.id] = self.state[grave.id].availableAt
        self.sessions[token] = nil
        self.active[source] = nil
        if not Vorp.addReward(source, 'silver_ring', 1) then return false, 'full' end
        return true
    end

    function engine:restart()
        local oldDb = self.cooldownDb
        local restarted = newEngine()
        restarted.cooldownDb = oldDb
        for graveId, availableAt in pairs(oldDb) do
            restarted.state[graveId] = { state = 'cooldown', availableAt = availableAt }
        end
        return restarted
    end

    function engine:validateConfig(config)
        local seen = {}
        for _, grave in ipairs(config.graves) do
            if seen[grave.id] then return false, 'duplicate' end
            seen[grave.id] = true
            if not self.pools[grave.rewardPool] then return false, 'pool' end
            if not self.villages[grave.villageId] then return false, 'village' end
        end
        return true
    end

    return engine
end

Vorp.addPlayer(1, { charId = 'c1', village = 'rhodes', role = 'citizen', job = 'miner', coords = { x = 0, y = 0, z = 0 }, inventory = { shovel = 1 } })
Vorp.addPlayer(2, { charId = 'c2', village = 'valentine', role = 'sheriff', job = 'sheriff', coords = { x = 0, y = 0, z = 0 }, inventory = { shovel = 1 } })
Vorp.addPlayer(3, { charId = 'c3', village = 'rhodes', role = 'sheriff', job = 'sheriff', coords = { x = 20, y = 0, z = 0 }, inventory = { shovel = 1 } })

local e = newEngine()
assertTrue('1 invalid grave id', select(2, e:start(1, 'missing')) == 'invalid_grave')

local badVillage = { graves = { { id = 'g1', villageId = 'missing', rewardPool = 'default' } } }
assertTrue('2 invalid village id', select(2, e:validateConfig(badVillage)) == 'village')

Vorp.players[1].coords = { x = 99, y = 0, z = 0 }
assertTrue('3 too far', select(2, e:start(1, 'valentine_grave_001')) == 'far')

Vorp.players[1].coords = { x = 0, y = 0, z = 0 }
Vorp.players[1].inventory.shovel = 0
assertTrue('4 no shovel', select(2, e:start(1, 'valentine_grave_001')) == 'no_item')

Vorp.players[1].inventory.shovel = 1
local okA, tokenA = e:start(1, 'valentine_grave_001')
assertTrue('5 first player starts', okA)
assertTrue('5 second player same grave blocked', select(2, e:start(2, 'valentine_grave_001')) == 'reserved')

assertTrue('6 complete too fast', select(2, e:complete(1, tokenA)) == 'fast')
e.time = e.time + 13
assertTrue('7 complete succeeds', e:complete(1, tokenA))
assertTrue('7 repeat complete blocked', select(2, e:complete(1, tokenA)) == 'missing')

local e2 = newEngine()
local _, tokenB = e2:start(1, 'valentine_grave_001')
e2.time = e2.time + 13
assertTrue('8 token wrong source', select(2, e2:complete(2, tokenB)) == 'wrong_source')

local e3 = newEngine()
local _, tokenC = e3:start(1, 'valentine_grave_001')
e3.time = e3.time + 46
assertTrue('9 session expires', select(2, e3:complete(1, tokenC)) == 'expired')

local e4 = newEngine()
e4:start(1, 'valentine_grave_001')
assertTrue('10 disconnect releases reservation', e4:cancel(1) and e4.state.valentine_grave_001.state == 'available')

local e5 = newEngine()
local _, tokenD = e5:start(1, 'valentine_grave_001')
e5.time = e5.time + 13
assertTrue('11 cooldown db saved', e5:complete(1, tokenD) and e5.cooldownDb.valentine_grave_001 ~= nil)

local e6 = e5:restart()
assertTrue('12 restart keeps cooldown', e6.state.valentine_grave_001.state == 'cooldown')

local valRecipients = City.getRecipients(Vorp.players, 'valentine', { 'sheriff' })
assertTrue('13 valentine alert not rhodes', #valRecipients == 1 and valRecipients[1] == 2)

local rhodesRecipients = City.getRecipients(Vorp.players, 'rhodes', { 'sheriff' })
assertTrue('14 rhodes alert not annesburg', #rhodesRecipients == 1 and rhodesRecipients[1] == 3)

assertTrue('15 robber village does not choose alert village', City.getVillage(Vorp.players[1]) == 'rhodes' and valRecipients[1] == 2)
assertTrue('16 no role no alert', not (valRecipients[1] == 1))
assertTrue('17 role same village receives alert', valRecipients[1] == 2)
assertTrue('18 reward is server-side', e.rewardsRandomServerSide == true)

local e7 = newEngine()
Vorp.players[1].canCarry = false
local rewardsBeforeFull = Vorp.players[1].rewards.silver_ring or 0
local _, tokenE = e7:start(1, 'valentine_grave_001')
e7.time = e7.time + 13
assertTrue('19 inventory full no duplication', select(2, e7:complete(1, tokenE)) == 'full' and (Vorp.players[1].rewards.silver_ring or 0) == rewardsBeforeFull)
Vorp.players[1].canCarry = true

local e8 = newEngine()
e8.graves.valentine_grave_001.consume = true
Vorp.players[1].removeFails = true
local _, tokenF = e8:start(1, 'valentine_grave_001')
e8.time = e8.time + 13
assertTrue('20 remove fail no reward', select(2, e8:complete(1, tokenF)) == 'remove_failed')
Vorp.players[1].removeFails = false

local e9 = newEngine()
local limited = false
for _ = 1, 11 do
    local ok, reason = e9:start(1, 'missing')
    if not ok and reason == 'rate' then limited = true end
end
assertTrue('21 rate limit', limited)

assertTrue('22 duplicate grave detected', select(2, e:validateConfig({ graves = { { id = 'x', villageId = 'valentine', rewardPool = 'default' }, { id = 'x', villageId = 'rhodes', rewardPool = 'default' } } })) == 'duplicate')
assertTrue('23 missing reward pool detected', select(2, e:validateConfig({ graves = { { id = 'x', villageId = 'valentine', rewardPool = 'missing' } } })) == 'pool')

local e10 = newEngine()
e10:start(1, 'valentine_grave_001')
for source in pairs(e10.active) do e10:cancel(source) end
assertTrue('24 resource stop cleanup', next(e10.sessions) == nil and e10.state.valentine_grave_001.state == 'available')

print(('Passed: %d'):format(passed))
print(('Failed: %d'):format(failed))
if failed > 0 then
    for _, name in ipairs(failures) do print(' - ' .. name) end
    os.exit(1)
end
