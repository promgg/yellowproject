-- lp_interior (server) — ตัดสินใจเรื่อง routing bucket ฝั่ง server เท่านั้น
--
-- ตั้งใจไม่ทำตาม !MJ-Dimension ที่รับ bucketId มาจาก client ตรงๆ แล้ว SetPlayerRoutingBucket เลย
-- (ผู้เล่นยิง event เองย้ายไปมิติไหนก็ได้ รวมถึงมิติส่วนตัวของคนอื่น) ที่นี่ client บอกได้แค่
-- "ผมเข้าจุดที่ index N" แล้ว server เปิด config เอง + ตรวจระยะซ้ำก่อนย้าย

local RESOURCE = GetCurrentResourceName()

local playerBucket = {} -- [src] = bucket id ที่เราตั้งให้ (nil = อยู่มิติหลัก)
local playerZone = {}   -- [src] = index ใน Config.Interiors ที่ผู้เล่นอยู่ (nil = อยู่มิติหลัก)
local playerAfk = {}    -- [src] = true เมื่ออยู่ในมิติ AFK ของโซนนั้น
local populationDone = {} -- [bucket] = true เมื่อตั้งค่า population แล้ว

-- บรรทัดแรกสุด ยังไม่แตะ Config เลย — ถ้าไม่เห็นบรรทัดนี้ใน console เซิร์ฟหลัง ensure
-- แปลว่าไฟล์นี้ไม่ได้ถูกโหลดเลย (ไม่มีไฟล์บนเครื่องนั้น / fxmanifest ไม่ได้ประกาศ server_scripts)
print(('[%s] ^2server/main.lua โหลดแล้ว^7'):format(RESOURCE))

-- ลงทะเบียนไว้บนสุด ก่อน guard ของ Config ด้านล่าง เพื่อให้เป็นการทดสอบเส้นทาง
-- client -> server ล้วนๆ: ต่อให้ Config พังจนไฟล์ return ทิ้งกลางคัน ตัวนี้ก็ยังตอบได้
-- ใช้คู่กับคำสั่ง /interiorping ฝั่ง client
RegisterNetEvent('lp_interior:ping', function()
    local src = source
    print(('[%s] ได้รับ ping จาก src=%s'):format(RESOURCE, tostring(src)))
    TriggerClientEvent('lp_interior:pong', src, ('server ได้ยินแล้ว (src=%s)'):format(tostring(src)))
end)

-- แยกออกมาอีกบรรทัด เพราะถ้า Config เป็น nil บน server (config.lua ไม่เข้า context เซิร์ฟ)
-- การอ่าน #Config.Interiors จะ error ทันที ทำให้ทั้งไฟล์หยุดกลางคัน = RegisterNetEvent
-- ด้านล่างไม่ทำงาน client ยิง event มาก็ไม่มีใครรับ (ตรงกับอาการที่ไม่มี [BUCKET] ตอบกลับ)
if not Config or not Config.Interiors then
    print(('[%s] ^1ผิดพลาด:^7 Config ไม่ถูกโหลดใน context ของ server — ตรวจ shared_script ใน fxmanifest')
        :format(RESOURCE))
    return
end

print(('[%s] ^2พร้อมทำงาน^7 — interior ใน config: %d จุด, Dimension.Enabled=%s')
    :format(RESOURCE, #Config.Interiors, tostring(Config.Dimension and Config.Dimension.Enabled)))

-- afk = true -> ใช้ afkBucket ของ entry แทน bucket ปกติ (อาคารเดียวกัน คนละมิติ)
local function bucketFor(entry, src, afk)
    local base = entry.bucket
    if afk and entry.afkBucket then
        base = entry.afkBucket
    end

    -- PerPlayer: ให้แต่ละคนได้มิติของตัวเอง โดยบวก src เข้ากับ bucket ฐาน
    -- (ยังคงอยู่ในช่วง 7100+ ที่กันไว้ ไม่ชนกับ bucket ที่ resource อื่นใช้)
    if Config.Dimension.PerPlayer then
        return base + (src * 1000)
    end
    return base
end

-- ตรวจซ้ำฝั่ง server ว่าผู้เล่นอยู่ใกล้จุดนั้นจริง (pattern เดียวกับ nx_shop/lp_gunsmith)
-- กันคนยิง event เองจากอีกฝั่งแผนที่เพื่อเข้ามิติที่ไม่ควรเข้า
-- คืน ระยะ หรือ nil ถ้าไกลเกิน/หา ped ไม่เจอ
local function distanceToEntry(src, entry)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end

    local dist = #(GetEntityCoords(ped) - entry.coords)
    if dist > (Config.Dimension.ServerDistanceCheck or 60.0) then
        return nil, dist
    end
    return dist
end

local function ensurePopulation(bucket)
    if not Config.Dimension.EnablePopulation then return end
    if populationDone[bucket] then return end

    -- ตั้งตรงๆ เสมอ ไม่พึ่ง default ของ FiveM ที่อาจต่างกันตามเวอร์ชัน ไม่งั้น interior จะร้างไม่มี NPC
    -- ห่อ pcall เพราะ native ตัวนี้ยังไม่มี resource อื่นในโปรเจกต์ใช้ (ยังไม่ได้พิสูจน์บน build นี้)
    -- ถ้าไม่มีจริงก็แค่ไม่มี NPC ไม่ควรทำให้ระบบย้ายมิติพังทั้งตัว
    local ok, err = pcall(SetRoutingBucketPopulationEnabled, bucket, true)
    if not ok then
        print(('[%s] ^3เตือน:^7 SetRoutingBucketPopulationEnabled ใช้ไม่ได้ (%s) — มิติแยกจะไม่มี NPC'):format(
            RESOURCE, tostring(err)))
    end
    populationDone[bucket] = true
end

local function resetPlayer(src)
    playerZone[src] = nil
    playerAfk[src] = nil
    if not playerBucket[src] then return end
    SetPlayerRoutingBucket(src, 0)
    playerBucket[src] = nil
end

-- อ่าน bucket จริงจากเซิร์ฟเวอร์หลังตั้งค่าแล้ว แล้วส่งกลับไปพิมพ์ที่ F8 ของผู้เล่นด้วย
-- (client อ่านเองไม่ได้ GetPlayerRoutingBucket เป็น server native) — ใช้ยืนยันว่า "ย้ายจริง"
-- ไม่ใช่แค่ event ถูกส่ง ถ้าเลขไม่เปลี่ยนแปลว่า SetPlayerRoutingBucket ไม่มีผล
local function reportBucket(src, note)
    local actual
    local ok, res = pcall(GetPlayerRoutingBucket, src)
    if ok then actual = res end

    local line = ('[%s] [BUCKET] src=%s  bucket=%s  %s'):format(
        RESOURCE, tostring(src), tostring(actual), note or '')
    print(line)

    TriggerClientEvent('lp_interior:bucketReport', src, actual, note)
end

RegisterNetEvent('lp_interior:enter', function(index)
    local src = source
    if not Config.Dimension.Enabled then return end

    -- ตรวจ index ที่ client ส่งมาว่าอยู่ในช่วงจริง
    index = tonumber(index)
    if not index then return end

    local entry = Config.Interiors[index]
    if not entry then return end

    local dist, tooFar = distanceToEntry(src, entry)
    if not dist then
        if tooFar then
            print(('[%s] ปฏิเสธ enter: src=%s อยู่ห่างจาก "%s" %.1fm (เกิน %.1fm)'):format(
                RESOURCE, tostring(src), entry.key, tooFar, Config.Dimension.ServerDistanceCheck or 60.0))
        end
        return
    end

    local bucket = bucketFor(entry, src, false)
    ensurePopulation(bucket)
    SetPlayerRoutingBucket(src, bucket)
    playerBucket[src] = bucket
    playerZone[src] = index
    playerAfk[src] = nil

    reportBucket(src, ('เข้า "%s" (ระยะ %.1fm)'):format(entry.key, dist))
end)

-- ── สลับเข้า/ออกมิติ AFK ─────────────────────────────────────────────────
-- MJ-Afk-Zone-ui เรียกผ่าน export ToggleAfk() ฝั่ง client ซึ่งยิง event นี้มา
-- ตรวจซ้ำทุกอย่างเองเหมือน enter: client บอกได้แค่ "โซนไหน" ไม่ได้บอกเลข bucket
RegisterNetEvent('lp_interior:setAfk', function(index, on)
    local src = source
    if not Config.Dimension.Enabled or not Config.Afk or not Config.Afk.Enabled then return end

    index = tonumber(index)
    if not index then return end

    -- ต้องอยู่ในโซนนั้นจริงตามที่ server จำไว้ ไม่ใช่แค่ที่ client อ้าง
    -- กันคนยิง event เองเพื่อกระโดดเข้ามิติ AFK ของร้านที่ตัวเองไม่ได้อยู่
    if playerZone[src] ~= index then
        print(('[%s] ปฏิเสธ setAfk: src=%s อ้างโซน index=%s แต่ server จำไว้ว่า %s'):format(
            RESOURCE, tostring(src), tostring(index), tostring(playerZone[src])))
        return
    end

    local entry = Config.Interiors[index]
    if not entry or not entry.afkBucket then return end

    local dist = distanceToEntry(src, entry)
    if not dist then return end

    on = on == true
    local bucket = bucketFor(entry, src, on)
    ensurePopulation(bucket)
    SetPlayerRoutingBucket(src, bucket)
    playerBucket[src] = bucket
    playerAfk[src] = on or nil

    reportBucket(src, ('%s มิติ AFK ของ "%s"'):format(on and 'เข้า' or 'ออกจาก', entry.key))
end)

RegisterNetEvent('lp_interior:leave', function()
    local src = source
    resetPlayer(src)
    reportBucket(src, 'ออกกลับมิติหลัก')
end)

-- เช็ค bucket ปัจจุบันตามต้องการ — พิมพ์ทั้ง console เซิร์ฟและ F8 ของคนที่สั่ง
RegisterCommand('bucket', function(source)
    if source == 0 then
        -- สั่งจาก console: ไล่ดูทุกคนที่เราย้ายมิติไว้
        print(('[%s] [BUCKET] รายการผู้เล่นที่อยู่ในมิติแยก:'):format(RESOURCE))
        local n = 0
        for src, b in pairs(playerBucket) do
            print(('  src=%s -> bucket=%s'):format(tostring(src), tostring(b)))
            n = n + 1
        end
        if n == 0 then print('  (ไม่มีใครอยู่ในมิติแยก)') end
        return
    end

    reportBucket(source, 'เช็คตามคำสั่ง /bucket')
end, false)

-- ผู้เล่นหลุด/ออกเกมขณะอยู่ในมิติแยก — ล้าง state ไม่ให้ค้าง
AddEventHandler('playerDropped', function()
    local src = source
    playerBucket[src] = nil
    playerZone[src] = nil
    playerAfk[src] = nil
end)

-- ── exports ให้ resource อื่นใช้ต่อ (ฝั่ง server) ────────────────────────
-- MJ-Afk-Zone-ui ใช้ตรวจก่อนจ่ายรางวัลว่าคนนี้อยู่ในมิติ AFK ของร้านนั้นจริง
-- ไม่ใช่แค่ยิง event มาเฉยๆ
exports('IsPlayerInAfkBucket', function(src, key)
    if not playerAfk[src] then return false end

    local index = playerZone[src]
    if not index then return false end

    local entry = Config.Interiors[index]
    if not entry then return false end

    -- ไม่ระบุ key = ถามแค่ว่า "อยู่มิติ AFK ที่ไหนสักแห่งไหม"
    if key and entry.key ~= key then return false end
    return true
end)

-- คืน key ของโซนที่ผู้เล่นอยู่ หรือ nil ถ้าอยู่มิติหลัก
exports('GetPlayerZoneKey', function(src)
    local index = playerZone[src]
    if not index then return nil end
    local entry = Config.Interiors[index]
    return entry and entry.key or nil
end)

-- resource ถูกหยุดขณะมีคนอยู่ในมิติแยก — ดึงทุกคนกลับมิติหลัก ไม่งั้นค้างอยู่มิติเปล่าจนกว่าจะ relog
AddEventHandler('onResourceStop', function(res)
    if res ~= RESOURCE then return end
    for src in pairs(playerBucket) do
        SetPlayerRoutingBucket(src, 0)
    end
    playerBucket = {}
    playerZone = {}
    playerAfk = {}
end)
