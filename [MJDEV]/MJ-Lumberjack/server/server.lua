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

    -- ตรงนี้แค่เช็คว่ามีขวาน ไม่หักความทนทานแล้ว — ย้ายไปหักตอนตัดสำเร็จจริงใน addItem
    -- (เดิมหักที่นี่ ยกเลิกมินิเกมกลางคันก็เสียความทนทานฟรี ทั้งที่ยังไม่ได้ต้นไม้เลย)
    -- เลขนี้เป็นแค่ค่าโชว์ ส่งเลขเต็มไปก่อน — จะรู้ว่าเหลือจริงเท่าไหร่ต้องไล่ดูทั้งกระเป๋า
    -- แบบเดียวกับตอนหัก (getItem คืนอันไหนก็ได้ อาจไม่ใช่อันที่จะโดนหักจริง) และ client
    -- ก็ไม่ได้เอาค่านี้ไปแสดงที่ไหนอยู่แล้ว — ตัวเลขจริงอยู่ในคำอธิบายไอเทมซึ่ง server เขียนให้
    TriggerClientEvent("!MJ-Lumberjack:axechecked", _source, tree, Config.ChopsPerAxe or 10)
end)

-- ── หักความทนทานขวาน (เรียกหลังตัดสำเร็จเท่านั้น) ────────────────────────────
-- นับจำนวนครั้งใน metadata.uses ครบ ChopsPerAxe แล้วหักขวานทิ้ง 1 อัน
--
-- ทำไมต้องไล่ดูทั้งกระเป๋าแทน getItem: setItemMetadata ด้วย amount = 1 จะ "แยกกอง" อันที่ใช้อยู่
-- ออกจากกองที่ยังใหม่ พอถือหลายอันจึงมีทั้งอันสึกแล้วและอันใหม่ปนกัน getItem คืนอันไหนก็ได้
-- ถ้าไปโดนอันใหม่ทุกครั้ง ตัวนับจะไม่เดินเลย = ขวานไม่มีวันพัง
--
-- กติกาเลือก: อันที่ "เหลือน้อยที่สุด" ก่อนเสมอ (uses มากสุด) ให้พังไปทีละอัน
-- ไม่งั้นจะได้ขวานสึกครึ่งๆ กลางๆ เต็มกระเป๋า / ไม่มีอันสึกเลยค่อยหยิบอันใหม่
local function consumeAxeUse(src)
    if not Config.AxeDurability then return end
    local maxUses = tonumber(Config.ChopsPerAxe) or 10
    if maxUses <= 0 then return end

    exports.vorp_inventory:getUserInventoryItems(src, function(items)
        if type(items) ~= 'table' then return end

        local target
        for _, it in pairs(items) do
            if it.name == Config.Axe then
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
            exports.vorp_inventory:subItem(src, Config.Axe, 1, target.metadata)
            notify(src, 'error', ('ขวานพังแล้ว (ใช้ครบ %d ครั้ง)'):format(maxUses), 5000)
            TriggerClientEvent("!MJ-Lumberjack:noaxe", src)
        else
            local remaining = maxUses - used
            exports.vorp_inventory:setItemMetadata(src, target.id, {
                uses = used,
                description = ('ตัดได้อีก %d ครั้ง'):format(remaining),
            }, 1)
            if remaining <= 3 then
                notify(src, 'warning', ('ขวานใกล้พัง เหลืออีก %d ครั้ง'):format(remaining), 4000)
            end
        end
    end)
end

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
        if last and (now - last) < (Config.TreeCooldown or 60000) then
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
    consumeAxeUse(_source) -- ตัดสำเร็จแล้วค่อยหักความทนทาน
    -- lp_leaderboard (LUMBERJACK RANK): soft integration — ยิงเฉยๆ ไม่ต้อง depend, เงียบถ้าไม่มี resource นี้
    -- ต้องแนบ src เอง เพราะ TriggerEvent ข้าม resource ไม่รับประกัน global `source` ฝั่งผู้รับ
    TriggerEvent('lp_leaderboard:SV:LumberChop', { src = _source, amount = count })
    -- notify(_source, 'success', 'ได้รับ ' .. pick.label .. ' x' .. count, 3000)
    TriggerClientEvent('!MJ-Lumberjack:itemAwarded', _source, pick.name)
end)
