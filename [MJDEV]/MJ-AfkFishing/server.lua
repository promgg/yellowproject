local VORPcore = exports.vorp_core:GetCore()

local rewardCooldowns = {}

local function checkRewardCooldown(src, minMs)
    local t = GetGameTimer()
    local last = rewardCooldowns[src] or 0
    if (t - last) < minMs then
        return false
    end
    rewardCooldowns[src] = t
    return true
end

AddEventHandler('playerDropped', function()
    rewardCooldowns[source] = nil
end)

-- _GET_MAP_ZONE_AT_COORDS ใช้ได้แค่ฝั่ง client เท่านั้น (server ไม่มีแมพ/world โหลดอยู่) —
-- zoneHashes เลยมาจาก client แนบมากับ event แทนที่จะเรียก native เองตรงนี้
local function sanitizeZoneHashes(zoneHashes)
    if type(zoneHashes) ~= 'table' then return {} end
    local clean = {}
    for _, zoneType in pairs(Config.ZoneType) do
        local v = zoneHashes[zoneType]
        if type(v) == 'number' then clean[zoneType] = v end
    end
    return clean
end

local function isNearZone(zoneHashes)
    for _, zoneType in pairs(Config.ZoneType) do
        local hash = zoneHashes[zoneType]
        if hash and hash ~= 0 then return true end
    end
    return false
end

local function getAvailableRewards(zoneHashes)
    local function isRewardAvailable(reward)
        if not reward.zones then return true end
        for _, z in ipairs(reward.zones) do
            if zoneHashes[z.type] == GetHashKey(z.name) then return true end
        end
        return false
    end

    local available = {}
    for _, r in ipairs(Config.FishingRewards) do
        if isRewardAvailable(r) then table.insert(available, r) end
    end
    return available
end

local function getReward(zoneHashes)
    local pool = getAvailableRewards(zoneHashes)
    local roll = math.random(100)
    local result = nil
    for _, r in ipairs(pool) do
        if roll <= r.chance then
            if not result or r.chance < result.chance then result = r end
        end
    end
    return result
end

local function getRareReward(zoneHashes)
    local pool = getAvailableRewards(zoneHashes)
    local rarePool = {}
    local total = 0
    for _, r in ipairs(pool) do
        if r.chance <= Config.MiniRareChanceThreshold then
            table.insert(rarePool, r)
            total = total + r.chance
        end
    end
    if #rarePool == 0 then
        return getReward(zoneHashes)
    end
    local roll = math.random(total)
    local cum = 0
    for _, r in ipairs(rarePool) do
        cum = cum + r.chance
        if roll <= cum then return r end
    end
    return rarePool[#rarePool]
end

local function giveReward(src, reward)
    local added = exports.vorp_inventory:addItem(src, reward.item, reward.amount)
    if added == false then
        TriggerClientEvent('fishing:inventoryFull', src)
        return
    end
    -- lp_leaderboard (FISH RANK): soft integration — ยิงเฉยๆ ไม่ต้อง depend, เงียบถ้าไม่มี resource นี้
    -- ต้องส่ง src แนบไปในตัว payload เอง เพราะ TriggerEvent ข้าม resource ไม่รับประกันว่า
    -- global `source` ฝั่งผู้รับจะเป็นผู้เล่นคนเดิม (มันเป็นแค่ local trigger ไม่ใช่ network event)
    TriggerEvent('lp_leaderboard:SV:FishCatch', { src = src, amount = reward.amount })
    TriggerClientEvent('fishing:rewardGiven', src, reward.item)
end

-- เช็คว่ามีเบ็ดตกปลาติดตัวไหม (server-side, กันไคลเอนต์โกงข้าม client-side check)
local function hasFishingRod(src)
    local item = exports.vorp_inventory:getItem(src, Config.RodItem)
    return item ~= nil and item ~= false
end

RegisterServerEvent('fishing:giveReward')
AddEventHandler('fishing:giveReward', function(rawZoneHashes)
    local src = source
    if not checkRewardCooldown(src, Config.FishingTime * 800) then return end
    local zoneHashes = sanitizeZoneHashes(rawZoneHashes)
    if not isNearZone(zoneHashes) then return end
    if not hasFishingRod(src) then return end

    local User = VORPcore.getUser(src)
    if not User or not User.getUsedCharacter then return end

    exports.vorp_inventory:subItem(src, Config.BaitItem, Config.BaitPerCatch)
    local reward = getReward(zoneHashes)
    if reward then giveReward(src, reward) end
end)

RegisterServerEvent('fishing:giveRewardMini')
AddEventHandler('fishing:giveRewardMini', function(isHit, rawZoneHashes)
    local src = source
    if not checkRewardCooldown(src, Config.MiniGameTime * 800) then return end
    local zoneHashes = sanitizeZoneHashes(rawZoneHashes)
    if not isNearZone(zoneHashes) then return end
    if not hasFishingRod(src) then return end

    local User = VORPcore.getUser(src)
    if not User or not User.getUsedCharacter then return end

    if type(isHit) ~= 'boolean' then isHit = false end

    exports.vorp_inventory:subItem(src, Config.BaitItem, Config.BaitPerCatch)
    local reward = isHit and getRareReward(zoneHashes) or getReward(zoneHashes)
    if reward then giveReward(src, reward) end
end)
