local function notify(source, kind, text, duration)
    TriggerClientEvent("pNotify:SendNotification", source, { type = kind, text = text, timeout = duration or 3000 })
end

-- ── anti-spam/anti-dupe (server-side) ────────────────────────────────────────
-- mining:addItem / axecheck เป็น RegisterServerEvent ที่ client ยิงได้ ถ้าไม่กันจะสแปมยิงตรงเพื่อ
-- ดูปของ + ปั๊มอันดับ (lp_leaderboard) โดยไม่ต้องมีจอบ/อยู่หน้าเหมือง/รอมินิเกม — กันด้วย cooldown ต่อคน
local cooldowns = {} -- [src][action] = GetGameTimer() ล่าสุด
local function checkCooldown(src, action, minMs)
    local t = GetGameTimer()
    cooldowns[src] = cooldowns[src] or {}
    if (t - (cooldowns[src][action] or 0)) < minMs then return false end
    cooldowns[src][action] = t
    return true
end

-- per-rock cooldown ฝั่ง server (client แก้ usedUntil เองไม่ได้) — ก้อนเดิมขุดซ้ำได้เมื่อครบ RockCooldown
local rockCd = {} -- [src][rockKey] = GetGameTimer()

-- เมืองของผู้เล่นคำนวณจากพิกัด "ที่ server รู้เอง" (ไม่เชื่อ townName จาก client) — กันส่งเมืองอื่นมาปั๊มแร่หายาก
local function serverTownForPlayer(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local pc = GetEntityCoords(ped)
    for _, zone in pairs(Config.RocksZone) do
        if #(pc - zone.Coords) <= zone.Radius then return zone.Town end
    end
    return nil
end

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
    rockCd[source]    = nil
end)

RegisterServerEvent("mining:axecheck")
AddEventHandler("mining:axecheck", function()
    local _source = source
    if not checkCooldown(_source, 'axecheck', 800) then return end -- กันสแปมยิง axecheck ถี่
    local axe     = exports.vorp_inventory:getItem(_source, Config.Pickaxe)

    if not axe then
        TriggerClientEvent("mining:noaxe", _source)
        notify(_source, 'error', 'You need a pickaxe.', 5000)
        return
    end

    -- ตรงนี้แค่เช็คว่ามีจอบ ไม่หักความทนทานแล้ว — ย้ายไปหักตอนขุดสำเร็จจริงใน addItem
    -- (เดิมหักที่นี่ ยกเลิกมินิเกมกลางคันก็เสียความทนทานฟรี ทั้งที่ยังไม่ได้แร่เลย)
    -- เลขนี้เป็นแค่ค่าโชว์ ส่งเลขเต็มไปก่อน — จะรู้ว่าเหลือจริงเท่าไหร่ต้องไล่ดูทั้งกระเป๋า
    -- แบบเดียวกับตอนหัก (getItem คืนอันไหนก็ได้ อาจไม่ใช่อันที่จะโดนหักจริง) และ client
    -- ก็ไม่ได้เอาค่านี้ไปแสดงที่ไหนอยู่แล้ว — ตัวเลขจริงอยู่ในคำอธิบายไอเทมซึ่ง server เขียนให้
    TriggerClientEvent("mining:axechecked", _source, Config.MinesPerPickaxe or 10)
end)

-- ── หักความทนทานจอบ (เรียกหลังขุดสำเร็จเท่านั้น) ─────────────────────────────
-- นับจำนวนครั้งใน metadata.uses ครบ MinesPerPickaxe แล้วหักจอบทิ้ง 1 อัน
--
-- ทำไมต้องไล่ดูทั้งกระเป๋าแทน getItem: setItemMetadata ด้วย amount = 1 จะ "แยกกอง" อันที่ใช้อยู่
-- ออกจากกองที่ยังใหม่ พอถือหลายอันจึงมีทั้งอันสึกแล้วและอันใหม่ปนกัน getItem คืนอันไหนก็ได้
-- ถ้าไปโดนอันใหม่ทุกครั้ง ตัวนับจะไม่เดินเลย = จอบไม่มีวันพัง
--
-- กติกาเลือก: อันที่ "เหลือน้อยที่สุด" ก่อนเสมอ (uses มากสุด) ให้พังไปทีละอัน
-- ไม่งั้นจะได้จอบสึกครึ่งๆ กลางๆ เต็มกระเป๋า / ไม่มีอันสึกเลยค่อยหยิบอันใหม่
local function consumePickaxeUse(src)
    if not Config.PickaxeDurability then return end
    local maxUses = tonumber(Config.MinesPerPickaxe) or 10
    if maxUses <= 0 then return end

    exports.vorp_inventory:getUserInventoryItems(src, function(items)
        if type(items) ~= 'table' then return end

        local target
        for _, it in pairs(items) do
            if it.name == Config.Pickaxe then
                local uses = tonumber(it.metadata and it.metadata.uses) or 0
                -- uses มากกว่า = เหลือน้อยกว่า -> เลือกอันนั้น
                if not target or uses > target.uses then
                    target = { id = it.id, uses = uses, metadata = it.metadata or {} }
                end
            end
        end
        if not target then return end

        local used = target.uses + 1
        if used >= maxUses then
            exports.vorp_inventory:subItem(src, Config.Pickaxe, 1, target.metadata)
            notify(src, 'error', ('จอบพังแล้ว (ใช้ครบ %d ครั้ง)'):format(maxUses), 5000)
            TriggerClientEvent("mining:noaxe", src)
        else
            local remaining = maxUses - used
            exports.vorp_inventory:setItemMetadata(src, target.id, {
                uses = used,
                description = ('ขุดได้อีก %d ครั้ง'):format(remaining),
            }, 1)
            if remaining <= 3 then
                notify(src, 'warning', ('จอบใกล้พัง เหลืออีก %d ครั้ง'):format(remaining), 4000)
            end
        end
    end)
end

-- เมืองไม่เชื่อ client แล้ว — คำนวณจากพิกัดผู้เล่นเทียบ Config.RocksZone ฝั่ง server (serverTownForPlayer)
-- แทนการใช้ native _GET_MAP_ZONE_AT_COORDS (client-only) หรือรับ townName จาก client (โกงได้)
RegisterServerEvent("mining:addItem")
AddEventHandler("mining:addItem", function(rockKey)
    local _source = source

    -- กันสแปมยิงตรง: ต้องมีจอบจริง + เว้นระยะตามมินิเกม (server-authoritative)
    if not checkCooldown(_source, 'award', (Config.MiningDuration or 30) * 800) then return end
    if not exports.vorp_inventory:getItem(_source, Config.Pickaxe) then return end

    -- เมืองคำนวณจากพิกัดจริงฝั่ง server (ไม่เชื่อ client) — ต้องยืนในโซนเหมืองจริงเท่านั้น
    local town    = serverTownForPlayer(_source)
    local rewards = town and Config.MiningRewards[town]
    if not rewards then
        notify(_source, 'warning', 'Nothing found this swing.', 3000)
        return
    end

    -- per-rock cooldown ฝั่ง server: ก้อนเดิม (rockKey) ขุดซ้ำได้เมื่อครบ RockCooldown (client โกงไม่ได้)
    -- ถ้า rockKey ไม่ valid ก็ข้ามเช็คนี้ แต่ยังติด cooldown รวม 24วิ ด้านบนอยู่ดี
    if type(rockKey) == 'string' and #rockKey > 0 and #rockKey <= 24 then
        local now = GetGameTimer()
        rockCd[_source] = rockCd[_source] or {}
        local last = rockCd[_source][rockKey]
        if last and (now - last) < (Config.RockCooldown or 900000) then
            notify(_source, 'info', 'ก้อนนี้เพิ่งขุดไป รอสักครู่', 3000)
            return
        end
        rockCd[_source][rockKey] = now
    end

    -- roll 1-100 แบบ cumulative: ไล่บวก chance ทีละตัวตามลำดับใน Config.MiningRewards[townName]
    local roll       = math.random(100)
    local cumulative = 0
    local pick       = nil

    for _, v in ipairs(rewards) do
        cumulative = cumulative + v.chance
        if roll <= cumulative then
            pick = v
            break
        end
    end

    if not pick then
        notify(_source, 'warning', 'Nothing found this swing.', 3000)
        return
    end

    local count    = pick.amount
    local canCarry = exports.vorp_inventory:canCarryItem(_source, pick.name, count)

    if not canCarry then
        notify(_source, 'warning', 'Inventory full — ' .. pick.label, 5000)
        return
    end

    exports.vorp_inventory:addItem(_source, pick.name, count)
    consumePickaxeUse(_source) -- ขุดสำเร็จแล้วค่อยหักความทนทาน
    -- lp_leaderboard (MINING RANK): soft integration — ยิงเฉยๆ ไม่ต้อง depend, เงียบถ้าไม่มี resource นี้
    -- ต้องแนบ src เอง เพราะ TriggerEvent ข้าม resource ไม่รับประกัน global `source` ฝั่งผู้รับ
    TriggerEvent('lp_leaderboard:SV:MiningGather', { src = _source, amount = count })
    TriggerClientEvent('mining:itemAwarded', _source, pick.name)
end)
