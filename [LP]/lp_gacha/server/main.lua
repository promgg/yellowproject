local Core = exports.vorp_core:GetCore()

-- ================================================================
--  lp_gacha server — server-authoritative
--  * server สุ่มผู้ชนะเองทั้งหมด client ได้แค่ผลไปเล่นแอนิเมชัน
--  * จุดเข้าที่เชื่อ source: registerUsableItem callback + net event ที่อ่าน source ตัวจริง
--  * ทุกสปิน: validate pool/qty -> lock+cooldown -> re-check ตั๋ว -> subItem สำเร็จก่อน -> ค่อยแจก
-- ================================================================

local function dbg(...)
    if Config.Debug then print('[lp_gacha]', ...) end
end

-- ---------- precompute display list (drop-rate + belt) ต่อ pool ----------
-- chancePct = โอกาสจริงต่อชิ้น = chance ของ tier * (น้ำหนักของชิ้น / ผลรวมน้ำหนักใน tier)
local Display = {}
local function buildDisplay(pool)
    local list = {}
    for _, tier in ipairs(pool.tiers) do
        local sumW = 0
        for _, rw in ipairs(tier.rewards) do sumW = sumW + rw.amount end
        for _, rw in ipairs(tier.rewards) do
            list[#list + 1] = {
                key       = rw.item,
                name      = rw.label,
                image     = rw.item,
                type      = rw.type, -- ให้ client รู้ว่าเป็น item (โหลดรูปจาก vorp_inventory) หรือ horse (รูปโลคอล)
                rarity    = rw.rarity or 'common',
                amount    = rw.amount,
                chancePct = tier.chance * (rw.amount / sumW),
            }
        end
    end
    return list
end

for poolId, pool in pairs(Config.Pools) do
    Display[poolId] = buildDisplay(pool)
end

-- ---------- weighted roll (server-side เท่านั้น) ----------
local function pickWeighted(entries, weightOf)
    local total = 0
    for _, e in ipairs(entries) do total = total + weightOf(e) end
    local r = math.random() * total
    for _, e in ipairs(entries) do
        r = r - weightOf(e)
        if r <= 0 then return e end
    end
    return entries[#entries]
end

local function rollWinner(pool)
    local tier   = pickWeighted(pool.tiers, function(t) return t.chance end)
    local reward = pickWeighted(tier.rewards, function(rw) return rw.amount end)
    return reward
end

-- ---------- grant (server-side) ----------
local function grantReward(src, xPlayer, reward)
    local t = reward.type
    if t == 'item' then
        -- ignoreStackLimit=true: ของรางวัลกาชายัดเกิน stack limit ปกติได้ (โชว์ e.g. 100/10) —
        -- ตั้งใจให้เป็นของพิเศษ/ของสะสม ไอเทมที่กดใช้ได้จะถูกบล็อกไม่ให้กดใช้ตอนเกิน limit
        -- ต่างหาก (ดู vorp_inventory InventoryService.UseItem) ส่วนทางเก็บของปกติ (ขุด/งาน/
        -- ร้านค้า) ไม่ผ่านช่องทางนี้ จะยังถูกบล็อกไม่ให้เกิน limit ตามเดิม
        exports.vorp_inventory:addItem(src, reward.item, reward.amount, nil, nil, nil, nil, nil, true)

    elseif t == 'money' then
        xPlayer.addCurrency(0, reward.amount)

    elseif t == 'gold' then
        xPlayer.addCurrency(1, reward.amount)

    elseif t == 'horse' then
        local horseName = ('Paradise-%04d'):format(math.random(0, 9999))
        MySQL.query.await(
            'INSERT INTO `player_horses` (identifier, charid, name, model, gender, captured) VALUES (?, ?, ?, ?, ?, ?)',
            { xPlayer.identifier, xPlayer.charIdentifier, horseName, reward.model or reward.item, reward.gender or 'male', 0 }
        )

    elseif t == 'weapon' then
        local canCarry = exports.vorp_inventory:canCarryWeapons(src, 1, nil, reward.item)
        if canCarry then
            exports.vorp_inventory:createWeapon(src, reward.item)
        else
            -- ถือซ้ำ/กระเป๋าเต็ม -> ชดเชยเป็นเงินแทน (ผู้เล่นต้องได้ของเสมอ)
            local comp = Config.WeaponComp.prices[reward.item] or Config.WeaponComp.default
            xPlayer.addCurrency(Config.WeaponComp.currency, comp)
            dbg(('weapon %s ถือไม่ได้ -> ชดเชย %d (currency %d)'):format(reward.item, comp, Config.WeaponComp.currency))
        end
    end
end

-- ---------- Discord log ----------
local function logGrant(src, xPlayer, pool, winners)
    if not (Config.Discord.Enable and Config.Discord.Webhook ~= '') then return end
    local lines = {}
    for _, w in ipairs(winners) do
        lines[#lines + 1] = ('%s x%d'):format(w.label, w.amount)
    end
    local content = ('**%s** | %s (id %d, char %s) เปิด %d ครั้ง ได้: %s'):format(
        pool.label, xPlayer.identifier, src, tostring(xPlayer.charIdentifier), #winners, table.concat(lines, ', '))
    PerformHttpRequest(Config.Discord.Webhook, function() end, 'POST',
        json.encode({ username = 'lp_gacha', content = content }), { ['Content-Type'] = 'application/json' })
end

-- ---------- open NUI (จาก usable item, source ตัวจริงจาก vorp) ----------
local function openGacha(src, poolId)
    local pool = Config.Pools[poolId]
    if not pool then return end
    local count = exports.vorp_inventory:getItemCount(src, nil, pool.ticket) or 0
    TriggerClientEvent('lp_gacha:open', src, {
        pool     = poolId,
        label    = pool.label,
        ticket   = pool.ticket, -- ให้ NUI โชว์รูปตั๋วเป็นรูป box
        boxCount = count,
        qtyMax   = Config.QtyMax,
        items    = Display[poolId],
    })
end

for poolId, pool in pairs(Config.Pools) do
    exports.vorp_inventory:registerUsableItem(pool.ticket, function(data)
        if data and data.source then
            openGacha(data.source, poolId)
        end
    end)
end

-- ---------- anti-spam state ----------
local activeSpin = {} -- [src] = true ระหว่างประมวลผลสปิน (กันซ้อน/re-entrant)
local lastSpin   = {} -- [src] = GetGameTimer() ครั้งล่าสุด (กันถี่)
local pending    = {} -- [src] = { xPlayer, pool, rewards, winners } รอ client ยืนยัน reveal จบ แล้วค่อยแจก

-- แจกของจริง + log + ประกาศ (idempotent — เคลียร์ pending ก่อน กันแจกซ้ำ)
-- เรียกได้จาก: revealDone (ปกติ) / failsafe timer / playerDropped — ตัวไหนถึงก่อนได้หมด
local function doGrant(src)
    local p = pending[src]
    if not p then return end
    pending[src] = nil

    for _, reward in ipairs(p.rewards) do
        grantReward(src, p.xPlayer, reward)
    end
    logGrant(src, p.xPlayer, p.pool, p.winners)

    -- ประกาศทั้งเซิร์ฟถ้าได้ของหายาก (dedupe ต่อชนิด) — ยิงตอนแจก = หลังเผยผล ไม่สปอยล์
    if Config.Broadcast and Config.Broadcast.Enable then
        local pname = ((p.xPlayer.firstname or '') .. ' ' .. (p.xPlayer.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
        if pname == '' then pname = 'ผู้เล่น' end
        local announced = {}
        for _, w in ipairs(p.winners) do
            if Config.Broadcast.Rarities[w.rarity] and not announced[w.item] then
                announced[w.item] = true
                local text = (Config.Broadcast.Message or 'คุณ %s ได้รับ %s'):format(pname, w.label or w.item)
                TriggerClientEvent('lp_gacha:broadcast', -1, text)
            end
        end
    end
end

-- client ยืนยันว่าอนิเมชันเผยผลจบแล้ว → แจกตอนนี้ (reveal ยาวไม่คงที่ callback แม่นกว่า timer)
RegisterNetEvent('lp_gacha:revealDone', function()
    doGrant(source)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if pending[src] then doGrant(src) end -- ยังมีของค้างตอนออก → แจกก่อน กันตั๋วหายฟรี
    activeSpin[src] = nil
    lastSpin[src]   = nil
end)

-- ---------- spin (client ส่งได้แค่ "คำขอ") ----------
RegisterNetEvent('lp_gacha:spin', function(poolId, qty)
    local src = source -- source ตัวจริงจาก event context ไม่ใช่พารามิเตอร์

    -- validate pool
    local pool = Config.Pools[poolId]
    if not pool then
        dbg(('spin: pool ไม่ถูกต้องจาก src %d'):format(src))
        return
    end

    -- validate qty
    if type(qty) ~= 'number' then return end
    qty = math.floor(qty)
    if qty < 1 or qty > Config.QtyMax then
        dbg(('spin: qty นอกช่วงจาก src %d (%s)'):format(src, tostring(qty)))
        return
    end

    -- anti-spam: กันซ้อน + cooldown
    if activeSpin[src] then return end
    local now = GetGameTimer()
    if lastSpin[src] and (now - lastSpin[src]) < Config.SpinCooldown then
        TriggerClientEvent('lp_gacha:spinRejected', src, 'cooldown')
        return
    end
    activeSpin[src] = true

    local ok, err = pcall(function()
        local User = Core.getUser(src)
        if not User then return end
        local xPlayer = User.getUsedCharacter

        -- re-check จำนวนตั๋วจริง ณ ตอนสปิน (ไม่เชื่อค่าตอนเปิด NUI)
        local have = exports.vorp_inventory:getItemCount(src, nil, pool.ticket) or 0
        if have < qty then
            TriggerClientEvent('lp_gacha:spinRejected', src, 'notenough')
            return
        end

        -- หักตั๋วทั้ง batch ก่อน ต้องสำเร็จก่อนถึงแจก (กัน dupe / จ่ายแล้วไม่ได้ของ)
        local subbed = false
        exports.vorp_inventory:subItem(src, pool.ticket, qty, nil, function(success)
            subbed = success
        end)
        if not subbed then
            TriggerClientEvent('lp_gacha:spinRejected', src, 'subfail')
            return
        end

        -- สุ่มทั้ง batch ก่อน (ตัดสินว่าได้อะไร) แต่ "ยังไม่แจก"
        -- กันผู้เล่นเห็นของเข้ากระเป๋าก่อนอนิเมชันเผยผลจบ (เดาออกว่าได้อะไร)
        local rewards, winners = {}, {}
        for i = 1, qty do
            local reward = rollWinner(pool)
            rewards[i] = reward
            winners[i] = {
                item   = reward.item,
                label  = reward.label,
                image  = reward.item,
                rarity = reward.rarity or 'common',
                amount = reward.amount,
                type   = reward.type,
            }
        end

        -- ถ้ามีของค้างจากสปินก่อน (client ยังไม่ยืนยัน) แจกให้จบก่อน กันของหายตอนเปิดรัว
        if pending[src] then doGrant(src) end

        -- เก็บ pending ไว้ แจกจริงตอน client ยิง revealDone (อนิเมชันเผยผลจบ)
        -- reveal สุ่มเลขทีละใบ ความยาวไม่คงที่ ใช้ callback แม่นกว่า timer ตายตัว
        pending[src] = { xPlayer = xPlayer, pool = pool, rewards = rewards, winners = winners }

        -- ส่งผลให้ client เล่นอนิเมชัน (ตั๋วหักไปแล้ว remaining ถูกต้อง)
        local remaining = exports.vorp_inventory:getItemCount(src, nil, pool.ticket) or 0
        TriggerClientEvent('lp_gacha:result', src, winners, remaining)

        -- failsafe: ถ้า client ไม่ยิง revealDone ใน N วิ (หลุด/error/ปิดหน้า) แจกเองกันตั๋วหายฟรี
        local capture = src
        Citizen.SetTimeout(Config.RevealFailsafeMs or 20000, function()
            if pending[capture] then doGrant(capture) end
        end)
    end)

    lastSpin[src]   = GetGameTimer()
    activeSpin[src] = nil

    if not ok then
        dbg('spin error:', err)
    end
end)
