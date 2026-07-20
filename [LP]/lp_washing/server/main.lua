-- ═══════════════════════════════════════════════════════════════════════════
--  lp_washing — server
--
--  โหมดแม่น้ำไม่มีอะไรมาที่ server เลย (ฟรี ไม่มีของ ไม่มีผลต่อ gameplay)
--  ไฟล์นี้มีไว้จุดเดียว: หักเงินค่าอาบน้ำ ซึ่ง client แตะไม่ได้
-- ═══════════════════════════════════════════════════════════════════════════

local Core = exports.vorp_core:GetCore()

-- ── rate limit ───────────────────────────────────────────────────────────────
local cooldowns = {}
local COOLDOWN_MS = 3000

local function checkCooldown(src)
    local t = GetGameTimer()
    local last = cooldowns[src] or 0
    if (t - last) < COOLDOWN_MS then return false end
    cooldowns[src] = t
    return true
end

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)

-- ── ค้นหาจุดอาบน้ำจาก id ที่ client ส่งมา ────────────────────────────────────
-- client บอกได้แค่ "id" ราคากับพิกัดอ่านจาก config ฝั่ง server เสมอ
-- ไม่รับตัวเลขราคาจาก client เด็ดขาด
local function findLocation(id)
    for _, loc in ipairs(Config.BathHouse.locations) do
        if loc.id == id then return loc end
    end
    return nil
end

Core.Callback.Register('lp_washing:PayBath', function(source, cb, locationId)
    local src = source

    if not Config.BathHouse.enabled then return cb({ ok = false, reason = 'ระบบอาบน้ำปิดอยู่' }) end
    if type(locationId) ~= 'string' then return cb({ ok = false, reason = 'ข้อมูลไม่ถูกต้อง' }) end
    if not checkCooldown(src) then return cb({ ok = false, reason = 'กำลังทำรายการ กรุณารอสักครู่' }) end

    local loc = findLocation(locationId)
    if not loc then return cb({ ok = false, reason = 'ไม่พบจุดอาบน้ำนี้' }) end

    -- ยืนยันว่าอยู่ตรงนั้นจริง — กันคนยิง event จากอีกมุมแผนที่
    -- เผื่อระยะไว้เท่าตัวกัน lag/ก้าวเท้าระหว่างรอ callback
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return cb({ ok = false, reason = 'ไม่พบตัวละคร' }) end
    local dist = #(GetEntityCoords(ped) - loc.stand)
    if dist > (Config.BathHouse.range * 2.0) then
        return cb({ ok = false, reason = 'คุณอยู่ไกลจากอ่างเกินไป' })
    end

    local User = Core.getUser(src)
    if not User then return cb({ ok = false, reason = 'ไม่พบผู้ใช้' }) end
    local Character = User.getUsedCharacter
    if not Character then return cb({ ok = false, reason = 'ไม่พบตัวละคร' }) end

    local price = Config.BathHouse.price
    local mtype = Config.BathHouse.moneyType

    -- เช็คยอดก่อนหัก — removeCurrency ของ VORP ไม่คืนค่าว่าสำเร็จไหม
    -- ถ้าไม่เช็คเองก่อนจะกลายเป็นอาบฟรีตอนเงินไม่พอ
    local balance = (mtype == 1) and Character.gold or Character.money
    if type(balance) ~= 'number' or balance < price then
        return cb({ ok = false, reason = 'เงินไม่พอ' })
    end

    local ok = pcall(function() Character.removeCurrency(mtype, price) end)
    if not ok then
        print(('^1[lp_washing]^7 หักเงินไม่สำเร็จ src=%s loc=%s'):format(src, locationId))
        return cb({ ok = false, reason = 'หักเงินไม่สำเร็จ' })
    end

    if Config.Debug then
        print(('[lp_washing] src=%s จ่ายค่าอาบน้ำ %s ที่ %s'):format(src, price, locationId))
    end

    cb({ ok = true })
end)
