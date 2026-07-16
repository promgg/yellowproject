-- local VorpCore = exports.vorp_core:GetCore()

local function notify(source, kind, text, duration)
    TriggerClientEvent("pNotify:SendNotification", source, { type = kind, text = text, timeout = duration or 3000 })
end

-- ── anti-spam/anti-dupe (server-side) ────────────────────────────────────────
-- axecheck/addItem เป็น RegisterServerEvent ที่ client ยิงได้ ถ้าไม่กันจะสแปมยิงตรงเพื่อดูป
-- ของ + ปั๊มอันดับ (lp_leaderboard) โดยไม่ต้องมีขวาน/อยู่ในโซน/รอมินิเกม — กันด้วย cooldown ต่อคน
local cooldowns = {} -- [src][action] = GetGameTimer() ล่าสุด
local function checkCooldown(src, action, minMs)
    local t = GetGameTimer()
    cooldowns[src] = cooldowns[src] or {}
    if (t - (cooldowns[src][action] or 0)) < minMs then return false end
    cooldowns[src][action] = t
    return true
end

-- per-position cooldown ฝั่ง server (client โกงพิกัดไม่ได้ประโยชน์ — cooldown ต่อคนรวม 24วิ
-- ด้านล่างคุมอัตราอยู่แล้ว อันนี้แค่กัน "ตัดต้นเดิมซ้ำทันที" ให้สมจริงขึ้น เหมือน rock cooldown ของ Mining)
local posCd = {} -- [src][roundedCoordKey] = GetGameTimer()
local function coordKey(c)
    if type(c) ~= 'table' or type(c.x) ~= 'number' then return nil end
    return ('%d_%d_%d'):format(math.floor(c.x + 0.5), math.floor(c.y + 0.5), math.floor((c.z or 0) + 0.5))
end

-- โซนตัดไม้ต้อง validate จากพิกัดจริงฝั่ง server (ไม่เชื่อ client ว่า "อยู่ในโซน") — Config.lumberZone
-- เป็น shared_script อ่านได้ทั้งคู่ ครอบคลุมทั้งเรื่องโซน+ข้อจำกัดเมืองในตัว (เมืองที่ chop_allowed=false
-- ไม่มี entry ใน lumberZone เลย เข้าเงื่อนไขเดียวกันพอดี ไม่ต้องพึ่ง native เช็คเมือง)
local function isPlayerInAnyLumberZone(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local pc = GetEntityCoords(ped)
    for _, zone in pairs(Config.lumberZone) do
        if #(pc - zone.Coords) <= zone.Radius then return true end
    end
    return false
end

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
    posCd[source]     = nil
end)

-- เช็คก่อนเริ่มตัด: เจ้าของกำหนดว่า "มีของชนิดใดชนิดหนึ่งที่ตัดไม้ดรอปได้เต็ม limit แล้ว = ตัดไม่ได้เลย"
-- (เดิมเช็ค canCarry หลังเล่นท่าตัดจบ ~30 วิ แล้วค่อยแจ้ง "เต็ม" = เสียเวลาฟรี) — พฤติกรรมเดียวกับ MJ-Mining
-- คืน false ถ้ามี "แม้แต่ชนิดเดียว" ใน Config.Items ที่พกเพิ่มไม่ได้
local function canCarryAllRewards(src)
    for _, v in ipairs(Config.Items) do
        if not exports.vorp_inventory:canCarryItem(src, v.name, v.amount) then
            return false -- ของชนิดนี้เต็มแล้ว -> บล็อกการตัดทั้งหมด
        end
    end
    return true
end

RegisterServerEvent("!MJ-Lumberjack:axecheck", function(tree)
    local _source = source
    if not checkCooldown(_source, 'axecheck', 800) then return end -- กันสแปม axecheck ถี่
    if not isPlayerInAnyLumberZone(_source) then return end -- ต้องยืนในโซนตัดไม้จริง (ครอบคลุมข้อจำกัดเมืองในตัว)

    local axe     = exports.vorp_inventory:getItem(_source, Config.Axe)

    if not axe then
        TriggerClientEvent("!MJ-Lumberjack:noaxe", _source)
        notify(_source, 'error', 'คุณไม่มีขวาน', 5000)
        return
    end

    -- มีของชนิดใดชนิดหนึ่งเต็ม -> บล็อกก่อนเริ่มท่าตัด (ไม่หักความทนขวาน ไม่เสียเวลา)
    if not canCarryAllRewards(_source) then
        TriggerClientEvent("!MJ-Lumberjack:blocked", _source)
        notify(_source, 'warning', 'กระเป๋าเต็ม — มีของบางชนิดเต็มแล้ว ตัดต่อไม่ได้', 5000)
        return
    end

    -- Config.AxeDurability = false: ซื้อขวานครั้งเดียวใช้ได้ตลอด ไม่มีวันหัก/พัง แค่เช็คว่ามีขวานพอ
    if not Config.AxeDurability then
        TriggerClientEvent("!MJ-Lumberjack:axechecked", _source, tree, 99)
        return
    end

    local meta       = axe.metadata
    local durability = 99

    if not next(meta) then
        -- ขวานใหม่ ตั้ง durability
        local metadata = { description = "Durability 99", durability = 99 }
        exports.vorp_inventory:setItemMetadata(_source, axe.id, metadata, 1)
        durability = 99
        TriggerClientEvent("!MJ-Lumberjack:axechecked", _source, tree, durability)
    else
        durability = (meta.durability or 99) - 1
        local metadata = { description = "Durability " .. durability, durability = durability }

        if durability < 20 then
            local roll = math.random(1, 3)
            if roll == 1 then
                notify(_source, 'error', 'ขวานของคุณหักแล้ว!', 5000)
                exports.vorp_inventory:subItem(_source, Config.Axe, 1, meta)
                TriggerClientEvent("!MJ-Lumberjack:noaxe", _source)
                return
            end
        end

        exports.vorp_inventory:setItemMetadata(_source, axe.id, metadata, 1)
        TriggerClientEvent("!MJ-Lumberjack:axechecked", _source, tree, durability)
    end
end)

RegisterServerEvent('!MJ-Lumberjack:addItem', function(treeCoords)
    local _source = source

    -- กันสแปมยิงตรง: ต้องอยู่ในโซน + มีขวานจริง + เว้นระยะตามมินิเกม (server-authoritative)
    if not checkCooldown(_source, 'award', (Config.ChopDuration or 30) * 800) then return end
    if not isPlayerInAnyLumberZone(_source) then return end
    if not exports.vorp_inventory:getItem(_source, Config.Axe) then return end

    -- per-position cooldown: ต้นเดิม (พิกัดปัดเศษ) ตัดซ้ำได้เมื่อครบเวลา (ถ้า coords ไม่ valid ก็ข้าม
    -- เช็คนี้ แต่ยังติด cooldown รวม 24วิ ด้านบนอยู่ดี)
    local key = coordKey(treeCoords)
    if key then
        local now = GetGameTimer()
        posCd[_source] = posCd[_source] or {}
        local last = posCd[_source][key]
        if last and (now - last) < 900000 then -- 15 นาที (เท่า RockCooldown ของ Mining)
            notify(_source, 'info', 'ต้นนี้เพิ่งตัดไป รอสักครู่', 3000)
            return
        end
        posCd[_source][key] = now
    end

    -- roll 1-100 แบบ cumulative: ไล่บวก chance ทีละตัวตามลำดับใน Config.Items
    -- met_log=10, met_stick=50, met_bark=30, met_resin=10 -> รวม 100% ไม่มีโอกาส "ไม่ได้ของ"
    local roll       = math.random(100)
    local cumulative = 0
    local pick       = nil

    for _, v in ipairs(Config.Items) do
        cumulative = cumulative + v.chance
        if roll <= cumulative then
            pick = v
            break
        end
    end

    if not pick then
        notify(_source, 'warning', 'ไม่ได้ไอเทมรอบนี้', 3000)
        return
    end

    local count    = pick.amount
    local canCarry = exports.vorp_inventory:canCarryItem(_source, pick.name, count)

    if not canCarry then
        notify(_source, 'warning', 'กระเป๋าเต็ม — ' .. pick.label, 5000)
        return
    end

    exports.vorp_inventory:addItem(_source, pick.name, count)
    -- lp_leaderboard (LUMBERJACK RANK): soft integration — ยิงเฉยๆ ไม่ต้อง depend, เงียบถ้าไม่มี resource นี้
    -- ต้องแนบ src เอง เพราะ TriggerEvent ข้าม resource ไม่รับประกัน global `source` ฝั่งผู้รับ
    TriggerEvent('lp_leaderboard:SV:LumberChop', { src = _source, amount = count })
    -- notify(_source, 'success', 'ได้รับ ' .. pick.label .. ' x' .. count, 3000)
    TriggerClientEvent('!MJ-Lumberjack:itemAwarded', _source, pick.name)
end)
