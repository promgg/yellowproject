local VORPcore = exports.vorp_core:GetCore()

local rewardCooldowns = {}

-- ── เครื่องมือ monitor เรทปลาที่ได้จริง (เก็บไว้ถาวร ไม่ใช่ debug ทิ้ง) ──
-- เก็บสถิติเงียบๆ ทุกครั้งที่มีคนได้ปลา ดูสรุปด้วยคำสั่ง /fishstats ในคอนโซลเซิร์ฟ (ไม่ spam console
-- ระหว่างเล่นปกติ — ถ้าอยากเห็น log สดทุกครั้งที่ได้ปลาระหว่างดีบัค ตั้ง DEBUG_FISH_VERBOSE = true ชั่วคราว)
local DEBUG_FISH_VERBOSE = false
-- fishStats[path][item] = count ; path = 'mini_hit' (กดมินิเกมโดน) | 'normal' (AFK) — ทั้งคู่ใช้ getReward() แล้ว
local fishStats = { mini_hit = {}, normal = {} }

local function recordFish(path, item)
    local bucket = fishStats[path] or fishStats.normal
    bucket[item] = (bucket[item] or 0) + 1
    if DEBUG_FISH_VERBOSE then
        print(('[MJ-AfkFishing:dbg] path=%s -> %s'):format(path, item))
    end
end

local function dumpFishStats()
    for _, path in ipairs({ 'mini_hit', 'normal' }) do
        local bucket = fishStats[path]
        local total = 0
        for _, n in pairs(bucket) do total = total + n end
        print(('[MJ-AfkFishing:dbg] ===== %s : total=%d ====='):format(path, total))
        -- เรียงมากไปน้อย
        local rows = {}
        for item, n in pairs(bucket) do rows[#rows + 1] = { item = item, n = n } end
        table.sort(rows, function(a, b) return a.n > b.n end)
        for _, row in ipairs(rows) do
            print(('[MJ-AfkFishing:dbg]   %-34s %5d  (%.1f%%)'):format(row.item, row.n, total > 0 and row.n / total * 100 or 0))
        end
    end
end

RegisterCommand('fishstats', function(src)
    if src ~= 0 then return end -- คอนโซลเซิร์ฟเท่านั้น
    dumpFishStats()
end, true)

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
    -- เดิม: สุ่มเลขเดียว (roll) แล้วใช้ร่วมกันทุกไอเทมในพูล พอมีหลายตัว qualify พร้อมกัน
    -- (roll <= chance) ก็เลือกตัวที่ chance ต่ำสุด (หายากสุด) เสมอ — ทำให้ปลาทั่วไปที่ตั้ง
    -- chance สูงๆ (เช่น 70%) แทบไม่มีโอกาสชนะเลยจริงๆ (จำลองแล้วออกจริงแค่ ~2%)
    -- ลองเปลี่ยนเป็นสุ่มอิสระทีละไอเทมแล้ว (เรียงหายากสุดก่อน หยุดที่ตัวแรกที่ผ่าน) แต่พบปัญหาใหม่:
    -- ไอเทมที่ถูกเช็คทีหลัง (chance สูง/ปลาทั่วไป) โดนไอเทมที่เช็คก่อนหน้า "แย่งชนะ" ไปเรื่อยๆ
    -- (bluegill_small ตั้ง 70% ออกจริงแค่ ~20% เพราะโดน perch_small ที่เช็คก่อนแย่งไปก่อน) —
    -- ลำดับการเช็คมีผลเอียงผลเสมอไม่ว่าจะเรียงยังไง เพราะงั้นเปลี่ยนมาใช้ weighted-random pick แทน —
    -- สุ่ม 1 ครั้ง เลือก 1 ไอเทมตามสัดส่วนน้ำหนักจริงเทียบทั้งพูล (ตัวเลข "chance" ทำหน้าที่เป็นน้ำหนัก
    -- สัมพัทธ์ ไม่ใช่ % อิสระแท้ๆ — เป็นไปไม่ได้ที่ปลา 30 ชนิดรวมกันเกิน 1000% จะได้ % อิสระตรงตัว
    -- พร้อมกันหมดไม่ว่าจะใช้วิธีไหน) ผลคือได้ปลาทุกรอบ ไม่มี "พลาดไม่ได้อะไรเลย" อีกต่อไป
    if #pool == 0 then return nil end
    local total = 0
    for _, r in ipairs(pool) do total = total + r.chance end
    local roll = math.random(total)
    local cum = 0
    for _, r in ipairs(pool) do
        cum = cum + r.chance
        if roll <= cum then return r end
    end
    return pool[#pool]
end

-- (ลบ getRareReward ออกแล้ว — เดิมกดมินิเกมโดนจะกรองเอาเฉพาะปลา chance<=30 = ได้แต่ปลาหายากล้วน
--  ทุกครั้งที่กดโดน ทำให้ปลา legendary ออกทั้งที่โอกาสตั้งไว้ 1-6% ตอนนี้ทุก path ใช้ getReward()
--  พูลรวมตาม % จริงใน config เหมือนกันหมด — ตาราง % เป็นความจริงเดียว)

-- เช็คว่าปลา "ทุกชนิด" ที่ตกได้ในโซนนี้ยังพกเพิ่มได้ไหม — มีชนิดใดชนิดหนึ่งเต็ม = false
-- (เจ้าของกำหนด: มีของบางชนิดเต็ม = ตกไม่ได้เลย เหมือน MJ-Mining/MJ-Lumberjack)
local function canCarryAllAvailable(src, zoneHashes)
    local pool = getAvailableRewards(zoneHashes)
    if #pool == 0 then return true end
    for _, r in ipairs(pool) do
        if not exports.vorp_inventory:canCarryItem(src, r.item, r.amount) then
            return false
        end
    end
    return true
end

-- callback ให้ client เช็คก่อน "เริ่ม" ตกปลา — บล็อกทันทีถ้ามีปลาบางชนิดเต็ม (ไม่ต้องรอจบรอบ 60 วิ + ไม่เปลืองเหยื่อ)
VORPcore.Callback.Register('MJ-AfkFishing:canStart', function(source, cb, rawZoneHashes)
    local zoneHashes = sanitizeZoneHashes(rawZoneHashes)
    cb(canCarryAllAvailable(source, zoneHashes))
end)

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

    -- backstop: ระหว่าง AFK ถ้ากระเป๋าเต็มระหว่างทาง หยุดก่อนหักเหยื่อ (ไม่เปลืองเหยื่อฟรี)
    if not canCarryAllAvailable(src, zoneHashes) then
        TriggerClientEvent('fishing:inventoryFull', src)
        return
    end

    exports.vorp_inventory:subItem(src, Config.BaitItem, Config.BaitPerCatch)
    local reward = getReward(zoneHashes)
    if reward then
        recordFish('normal', reward.item) -- AFK path (getReward)
        giveReward(src, reward)
    end
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

    -- backstop: กระเป๋าเต็มระหว่างทาง หยุดก่อนหักเหยื่อ (ไม่เปลืองเหยื่อฟรี)
    if not canCarryAllAvailable(src, zoneHashes) then
        TriggerClientEvent('fishing:inventoryFull', src)
        return
    end

    exports.vorp_inventory:subItem(src, Config.BaitItem, Config.BaitPerCatch)
    -- กดโดน/พลาด ต่างกันแค่ "ได้ปลา vs ไม่ได้อะไร" (พลาดไม่มาถึง server อยู่แล้ว — client คัดออกก่อน)
    -- ไม่ใช่คุณภาพปลา — ทุกกรณีใช้ getReward() พูลรวมตาม % จริงใน config
    local reward = getReward(zoneHashes)
    if reward then
        recordFish(isHit and 'mini_hit' or 'normal', reward.item)
        giveReward(src, reward)
    end
end)
