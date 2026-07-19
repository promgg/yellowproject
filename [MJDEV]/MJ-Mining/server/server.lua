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

    -- Config.PickaxeDurability = false: ซื้อจอบครั้งเดียวใช้ได้ตลอด ไม่มีวันหัก/พัง แค่เช็คว่ามีจอบพอ
    if not Config.PickaxeDurability then
        TriggerClientEvent("mining:axechecked", _source, 99)
        return
    end

    local meta       = axe.metadata
    local durability = 99

    if not next(meta) then
        local metadata = { description = "Durability 99", durability = 99 }
        exports.vorp_inventory:setItemMetadata(_source, axe.id, metadata, 1)
        durability = 99
        TriggerClientEvent("mining:axechecked", _source, durability)
    else
        durability = (meta.durability or 99) - 1
        local metadata = { description = "Durability " .. durability, durability = durability }

        if durability < 20 then
            local roll = math.random(1, 3)
            if roll == 1 then
                notify(_source, 'error', 'Your pickaxe broke!', 5000)
                exports.vorp_inventory:subItem(_source, Config.Pickaxe, 1, meta)
                TriggerClientEvent("mining:noaxe", _source)
                return
            end
        end

        exports.vorp_inventory:setItemMetadata(_source, axe.id, metadata, 1)
        TriggerClientEvent("mining:axechecked", _source, durability)
    end
end)

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
    -- lp_leaderboard (MINING RANK): soft integration — ยิงเฉยๆ ไม่ต้อง depend, เงียบถ้าไม่มี resource นี้
    -- ต้องแนบ src เอง เพราะ TriggerEvent ข้าม resource ไม่รับประกัน global `source` ฝั่งผู้รับ
    TriggerEvent('lp_leaderboard:SV:MiningGather', { src = _source, amount = count })
    TriggerClientEvent('mining:itemAwarded', _source, pick.name)
end)
