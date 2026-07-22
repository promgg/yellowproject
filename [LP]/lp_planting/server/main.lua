-- ═══════════════════════════════════════════════════════════════════════════
--  lp_planting — server (ตัวตัดสินทุกอย่าง)
--
--  client มีหน้าที่แค่ "แสดงผล" (prop/ท่าทาง/prompt) และ "ขอ" เท่านั้น
--  ทุกการหักของ/แจกของ/เลื่อนขั้น ต้องผ่านที่นี่และถูกตรวจซ้ำเสมอ
--
--  สถานะอยู่ 2 ที่: ตาราง Plants ใน memory (อ่านเร็ว) + DB (อยู่ข้ามรีสตาร์ท)
--  เขียน DB ทุกครั้งที่สถานะเปลี่ยน ไม่รอ save เป็นรอบ — ถ้าเซิร์ฟดับกะทันหัน
--  จะได้ไม่เสียความคืบหน้าที่ผู้เล่นเพิ่งทำไป
-- ═══════════════════════════════════════════════════════════════════════════

local VORPcore = {}
TriggerEvent('getCore', function(core) VORPcore = core end)

local Inventory = exports.vorp_inventory:vorp_inventoryApi()

local function dbg(fmt, ...)
    if Config.Debug then print(('[lp_planting] ' .. fmt):format(...)) end
end

-- [plantId] = { id, charId, zoneId, seed, stage, coords, heading, plantedAt, wateredAt }
local Plants = {}

-- ── helper ───────────────────────────────────────────────────────────────────

local function getChar(src)
    local user = VORPcore.getUser(src)
    return user and user.getUsedCharacter or nil
end

local function isNear(src, coords, range)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - coords) <= range
end

local function notify(src, text, kind)
    TriggerClientEvent('pNotify:SendNotification', src, {
        text = text, type = kind or 'error', timeout = 4000, layout = 'topRight' })
end

-- anti-spam ต่อคนต่อ action
local cooldowns = {}
local function cooldownOk(src, tag, ms)
    cooldowns[src] = cooldowns[src] or {}
    local now = GetGameTimer()
    if (now - (cooldowns[src][tag] or 0)) < ms then return false end
    cooldowns[src][tag] = now
    return true
end

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
    -- ⚠️ ไม่ลบต้นของคนที่ออกไป (ต่างจาก MJ-Planting เดิม) — นั่นคือสาเหตุที่ปลูกแล้ว
    -- หลุดเน็ตทีเสียเมล็ดฟรี ตอนนี้ต้นอยู่ใน DB รอเจ้าของกลับมาเก็บ
end)

-- ส่งรายการต้นของตัวละครนี้ให้ client ไป spawn
local function plantsOf(charId)
    local list = {}
    local now = os.time()
    for id, p in pairs(Plants) do
        if p.charId == charId then
            list[#list + 1] = {
                id = id, zoneId = p.zoneId, seed = p.seed, stage = p.stage,
                coords = p.coords, heading = p.heading,
                -- ส่ง "ผ่านมากี่วินาทีแล้ว" ไม่ใช่ timestamp ดิบ
                -- client ไม่มี os.time() ให้เทียบ (มีแต่ GetGameTimer ซึ่งนับจากตอนเปิดเกม)
                -- ถ้าส่ง timestamp ไปแล้วให้ client ลบเอง จะได้เลขมั่วแบบที่ MJ-Planting เดิมเป็น
                grownSeconds = p.wateredAt and (now - p.wateredAt) or nil,
            }
        end
    end
    return list
end

local function countInZone(charId, zoneId)
    local n = 0
    for _, p in pairs(Plants) do
        if p.charId == charId and p.zoneId == zoneId then n = n + 1 end
    end
    return n
end

local function deletePlant(id)
    local p = Plants[id]
    if not p then return end
    Plants[id] = nil
    MySQL.update('DELETE FROM lp_planting WHERE id = ?', { id })
    -- บอกทุก client ให้เก็บ prop ทิ้ง (เจ้าของอาจออฟไลน์อยู่ ไม่มีใครรับก็ไม่เป็นไร)
    TriggerClientEvent('lp_planting:removePlant', -1, id)
end

-- ── โหลดจาก DB ตอนบูต ────────────────────────────────────────────────────────
MySQL.ready(function()
    MySQL.query('SELECT id, charidentifier, zone_id, seed, stage, x, y, z, heading, planted_at, watered_at FROM lp_planting', {}, function(rows)
        if not rows then
            print('^1[lp_planting]^7 อ่านตาราง lp_planting ไม่ได้ — รัน sql/lp_planting.sql แล้วหรือยัง')
            return
        end

        local loaded, dropped = 0, 0
        for _, r in ipairs(rows) do
            -- config อาจถูกแก้ตั้งแต่ครั้งก่อน (ลบพืช/ลบโซน) แถวที่หาพืชไม่เจอแล้ว
            -- ปล่อยไว้จะกลายเป็นต้นผีที่กดอะไรไม่ได้ ลบทิ้งตั้งแต่ตอนโหลด
            if Config.SeedLookup[r.seed] and Config.Zones[r.zone_id] then
                Plants[r.id] = {
                    id = r.id, charId = r.charidentifier, zoneId = r.zone_id,
                    seed = r.seed, stage = r.stage,
                    coords = vector3(r.x, r.y, r.z), heading = r.heading or 0.0,
                    plantedAt = r.planted_at, wateredAt = r.watered_at,
                }
                loaded = loaded + 1
            else
                MySQL.update('DELETE FROM lp_planting WHERE id = ?', { r.id })
                dropped = dropped + 1
            end
        end

        print(('^2[lp_planting]^7 โหลดต้นไม้จาก DB %d ต้น%s')
            :format(loaded, dropped > 0 and (' (ทิ้ง %d ต้นที่พืช/โซนหายไปจาก config)'):format(dropped) or ''))
    end)
end)

-- ── ลงทะเบียนเมล็ดเป็นไอเทมใช้ได้ ────────────────────────────────────────────
CreateThread(function()
    for seed in pairs(Config.SeedLookup) do
        exports.vorp_inventory:registerUsableItem(seed, function(data)
            local src = data.source
            exports.vorp_inventory:closeInventory(src)
            TriggerClientEvent('lp_planting:useSeed', src, seed)
        end)
    end
end)

-- ── ส่งต้นของตัวเองให้ client ───────────────────────────────────────────────
VORPcore.addRpcCallback('lp_planting:getMyPlants', function(source, cb)
    local char = getChar(source)
    if not char then cb({}) return end
    cb(plantsOf(char.charIdentifier))
end)

-- ── เช็คถังน้ำ (ไม่หักอะไร ใช้ให้ client กันเล่นท่าเปล่า) ────────────────────
VORPcore.addRpcCallback('lp_planting:checkBucket', function(source, cb)
    exports.vorp_inventory:getItemByName(source, Config.WaterBucketItem, function(item)
        if not item then cb({ hasBucket = false, uses = 0 }) return end
        cb({ hasBucket = true, uses = (item.metadata and tonumber(item.metadata.uses)) or 0 })
    end)
end)

VORPcore.addRpcCallback('lp_planting:hasItem', function(source, cb, itemName)
    if not itemName then cb(false) return end
    cb((Inventory.getItemCount(source, itemName) or 0) > 0)
end)

-- ── เติมน้ำใส่ถัง ───────────────────────────────────────────────────────────
VORPcore.addRpcCallback('lp_planting:refillBucket', function(source, cb)
    local src = source
    if not cooldownOk(src, 'refill', 3000) then cb({ ok = false }) return end

    -- ต้องยืนใกล้จุดเติมน้ำจริง ไม่งั้นยิง RPC จากที่ไหนก็เติมได้
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then cb({ ok = false }) return end
    local pos = GetEntityCoords(ped)

    local nearPoint = false
    for _, zone in pairs(Config.Zones) do
        for _, pt in ipairs(zone.waterPoints or {}) do
            if #(pos - pt.coords) <= (Config.WaterRefill.range + 2.0) then nearPoint = true break end
        end
        if nearPoint then break end
    end
    if not nearPoint then cb({ ok = false, reason = 'far' }) return end

    exports.vorp_inventory:getItemByName(src, Config.WaterBucketItem, function(item)
        if not item then cb({ ok = false, reason = 'nobucket' }) return end

        local uses = (item.metadata and tonumber(item.metadata.uses)) or 0
        if uses >= Config.WaterRefill.usesPerRefill then cb({ ok = false, reason = 'full' }) return end

        -- amount ต้อง = item.count เสมอ ไม่งั้น setItemMetadata แยกกองถังออกเป็นชิ้นใหม่
        exports.vorp_inventory:setItemMetadata(src, item.id,
            { uses = Config.WaterRefill.usesPerRefill }, item.count,
            function(success) cb({ ok = success == true }) end)
    end)
end)

-- ── STEP 1: ปลูก ────────────────────────────────────────────────────────────
VORPcore.addRpcCallback('lp_planting:place', function(source, cb, seed, coords, heading)
    local src = source
    if not cooldownOk(src, 'place', 1500) then cb({ ok = false }) return end

    local char = getChar(src)
    if not char then cb({ ok = false }) return end

    local info = seed and Config.SeedLookup[seed]
    if not info or type(coords) ~= 'vector3' then cb({ ok = false, reason = 'badseed' }) return end

    if not isNear(src, info.zone.coords, info.zone.range) then
        cb({ ok = false, reason = 'notinzone' }) return
    end

    -- โควตา — ของเดิมมี count = 10 ใน config แต่ไม่เคยถูกอ่านเลย ปลูกได้ไม่จำกัด
    if countInZone(char.charIdentifier, info.zoneId) >= Config.MaxPlantsPerZone then
        cb({ ok = false, reason = 'quota' }) return
    end

    -- ระยะห่างเช็คเฉพาะ "ต้นของตัวเอง" เท่านั้น ไม่เช็คของผู้เล่นคนอื่น
    -- (เดิมเช็คทุกคน ทำให้ปลูกไม่ได้เพราะคนอื่นมาปลูกไว้ก่อนในจุดใกล้ ๆ)
    -- ยอมให้ต้นของคนละคนซ้อนทับกันได้ — prop เป็นของฝั่ง client ต่างคนต่างเห็นของตัวเอง
    local minDis = info.zone.minDistance or 1.0
    for _, p in pairs(Plants) do
        if p.charId == char.charIdentifier and p.zoneId == info.zoneId
            and #(p.coords - coords) < minDis then
            cb({ ok = false, reason = 'tooclose' }) return
        end
    end

    if (Inventory.getItemCount(src, seed) or 0) <= 0 then
        cb({ ok = false, reason = 'noseed' }) return
    end
    Inventory.subItem(src, seed, 1)

    local now = os.time()
    MySQL.insert(
        'INSERT INTO lp_planting (charidentifier, zone_id, seed, stage, x, y, z, heading, planted_at) VALUES (?,?,?,?,?,?,?,?,?)',
        { char.charIdentifier, info.zoneId, seed, 'fertilize', coords.x, coords.y, coords.z, heading or 0.0, now },
        function(insertId)
            if not insertId then
                -- บันทึกไม่ได้แต่หักเมล็ดไปแล้ว ต้องคืน ไม่งั้นผู้เล่นเสียของฟรี
                Inventory.addItem(src, seed, 1)
                print('^1[lp_planting]^7 INSERT ล้มเหลว — คืนเมล็ดให้ผู้เล่นแล้ว')
                cb({ ok = false, reason = 'dberror' })
                return
            end

            Plants[insertId] = {
                id = insertId, charId = char.charIdentifier, zoneId = info.zoneId,
                seed = seed, stage = 'fertilize',
                coords = coords, heading = heading or 0.0,
                plantedAt = now, wateredAt = nil,
            }
            dbg('char=%s ปลูก %s id=%s zone=%s', tostring(char.charIdentifier), seed, tostring(insertId), info.zoneId)
            cb({ ok = true, plantId = insertId })
        end
    )
end)

-- ── ตรวจสิทธิ์ + ระยะ ก่อนทำอะไรกับต้น (ใช้ร่วมทุก step) ────────────────────
local function claimPlant(src, plantId, wantStage)
    local char = getChar(src)
    if not char then return nil, 'nochar' end

    local p = Plants[plantId]
    if not p then return nil, 'gone' end
    if p.charId ~= char.charIdentifier then return nil, 'notyours' end
    if wantStage and p.stage ~= wantStage then return nil, 'wrongstage' end
    if not isNear(src, p.coords, Config.InteractRange + 1.0) then return nil, 'far' end

    return p, nil, char
end

-- ── STEP 2: ใส่ปุ๋ย ─────────────────────────────────────────────────────────
VORPcore.addRpcCallback('lp_planting:fertilize', function(source, cb, plantId)
    local src = source
    if not cooldownOk(src, 'fertilize', 2000) then cb({ ok = false }) return end

    local p, err = claimPlant(src, plantId, 'fertilize')
    if not p then cb({ ok = false, reason = err }) return end

    if (Inventory.getItemCount(src, Config.FertilizerItem) or 0) <= 0 then
        cb({ ok = false, reason = 'noitem' }) return
    end
    Inventory.subItem(src, Config.FertilizerItem, 1)

    p.stage = 'water'
    MySQL.update('UPDATE lp_planting SET stage = ? WHERE id = ?', { 'water', plantId })
    cb({ ok = true })
end)

-- ── STEP 3: รดน้ำ (stamp wateredAt = เริ่มนับเวลาโต) ────────────────────────
VORPcore.addRpcCallback('lp_planting:water', function(source, cb, plantId)
    local src = source
    if not cooldownOk(src, 'water', 2000) then cb({ ok = false }) return end

    local p, err = claimPlant(src, plantId, 'water')
    if not p then cb({ ok = false, reason = err }) return end

    exports.vorp_inventory:getItemByName(src, Config.WaterBucketItem, function(item)
        local uses = item and item.metadata and tonumber(item.metadata.uses) or 0
        if not item or uses <= 0 then cb({ ok = false, reason = 'nowater' }) return end

        -- amount ต้อง = item.count เสมอ ไม่งั้น setItemMetadata จะแยกกองถังออกเป็นชิ้นใหม่
        exports.vorp_inventory:setItemMetadata(src, item.id, { uses = uses - 1 }, item.count, function()
            local now = os.time()
            p.stage, p.wateredAt = 'grow', now
            MySQL.update('UPDATE lp_planting SET stage = ?, watered_at = ? WHERE id = ?', { 'grow', now, plantId })
            cb({ ok = true, remaining = uses - 1 })
        end)
    end)
end)

-- ── STEP 4: เก็บเกี่ยว ──────────────────────────────────────────────────────
VORPcore.addRpcCallback('lp_planting:harvest', function(source, cb, plantId)
    local src = source
    if not cooldownOk(src, 'harvest', 2000) then cb({ ok = false }) return end

    local p, err = claimPlant(src, plantId, 'grow')
    if not p then cb({ ok = false, reason = err }) return end
    if not p.wateredAt then cb({ ok = false, reason = 'notready' }) return end

    -- server ตัดสินเองว่าโตครบเวลาจริงไหม ไม่เชื่อ client ว่า "พร้อมแล้ว"
    local info = Config.SeedLookup[p.seed]
    if (os.time() - p.wateredAt) < info.growSeconds then
        cb({ ok = false, reason = 'notready' }) return
    end

    local reward = info.crop.reward
    if not Inventory.canCarryItem(src, reward.item, reward.count) then
        cb({ ok = false, reason = 'fullinv' }) return
    end

    exports.vorp_inventory:addItem(src, reward.item, reward.count)
    TriggerEvent('lp_leaderboard:SV:PlantHarvest', { src = src, amount = reward.count })
    -- hook เควสรายวัน — ของเดิมยิง 'MJ-Planting:Giveitem' ซึ่งถูกถอดออกไปตอน rewrite
    -- ทำให้เควสปลูกต้นไม้นับไม่ขึ้นมานาน ส่งชื่อเมล็ดจริงไป lp_daliyquest จะเทียบเองได้
    TriggerEvent('lp_planting:harvested', src, p.seed, reward.item, reward.count)

    deletePlant(plantId)
    cb({ ok = true, item = reward.item, count = reward.count })
end)

-- ── ทิ้งต้นเอง (ผู้เล่นกดยกเลิก) ────────────────────────────────────────────
VORPcore.addRpcCallback('lp_planting:destroy', function(source, cb, plantId)
    local src = source
    if not cooldownOk(src, 'destroy', 1000) then cb({ ok = false }) return end
    local p, err = claimPlant(src, plantId, nil)
    if not p then cb({ ok = false, reason = err }) return end
    deletePlant(plantId)
    cb({ ok = true })
end)

-- ── กวาดต้นหมดอายุ ──────────────────────────────────────────────────────────
-- นับจาก planted_at ทำไม่ครบทุกขั้นภายใน 24 ชม. = ลบทิ้ง
CreateThread(function()
    while true do
        Wait(300000) -- ทุก 5 นาที

        local hours = tonumber(Config.PlantTimeoutHours) or 0
        if hours > 0 then
            local cutoff = os.time() - (hours * 3600)
            local expired = {}
            for id, p in pairs(Plants) do
                if p.plantedAt < cutoff then expired[#expired + 1] = id end
            end
            for _, id in ipairs(expired) do deletePlant(id) end
            if #expired > 0 then
                print(('^3[lp_planting]^7 ลบต้นหมดอายุ %d ต้น (เกิน %d ชม.)'):format(#expired, hours))
            end
        end
    end
end)
