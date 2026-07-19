-- lp_interior (server) — ตัดสินใจเรื่อง routing bucket ฝั่ง server เท่านั้น
--
-- ตั้งใจไม่ทำตาม !MJ-Dimension ที่รับ bucketId มาจาก client ตรงๆ แล้ว SetPlayerRoutingBucket เลย
-- (ผู้เล่นยิง event เองย้ายไปมิติไหนก็ได้ รวมถึงมิติส่วนตัวของคนอื่น) ที่นี่ client บอกได้แค่
-- "ผมเข้าจุดที่ index N" แล้ว server เปิด config เอง + ตรวจระยะซ้ำก่อนย้าย

local RESOURCE = GetCurrentResourceName()

local playerBucket = {} -- [src] = bucket id ที่เราตั้งให้ (nil = อยู่มิติหลัก)
local populationDone = {} -- [bucket] = true เมื่อตั้งค่า population แล้ว

-- บรรทัดแรกสุด ยังไม่แตะ Config เลย — ถ้าไม่เห็นบรรทัดนี้ใน console เซิร์ฟหลัง ensure
-- แปลว่าไฟล์นี้ไม่ได้ถูกโหลดเลย (ไม่มีไฟล์บนเครื่องนั้น / fxmanifest ไม่ได้ประกาศ server_scripts)
print(('[%s] ^2server/main.lua โหลดแล้ว^7'):format(RESOURCE))

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

local function bucketFor(entry, src)
    -- PerPlayer: ให้แต่ละคนได้มิติของตัวเอง โดยบวก src เข้ากับ bucket ฐาน
    -- (ยังคงอยู่ในช่วง 7100+ ที่กันไว้ ไม่ชนกับ bucket ที่ resource อื่นใช้)
    if Config.Dimension.PerPlayer then
        return entry.bucket + (src * 1000)
    end
    return entry.bucket
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

    -- ตรวจซ้ำฝั่ง server ว่าผู้เล่นอยู่ใกล้จุดนั้นจริง (pattern เดียวกับ nx_shop/lp_gunsmith)
    -- กันคนยิง event เองจากอีกฝั่งแผนที่เพื่อเข้ามิติที่ไม่ควรเข้า
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end

    local coords = GetEntityCoords(ped)
    local dist = #(coords - entry.coords)
    if dist > (Config.Dimension.ServerDistanceCheck or 60.0) then
        print(('[%s] ปฏิเสธ enter: src=%s อยู่ห่างจาก "%s" %.1fm (เกิน %.1fm)'):format(
            RESOURCE, tostring(src), entry.key, dist, Config.Dimension.ServerDistanceCheck or 60.0))
        return
    end

    local bucket = bucketFor(entry, src)
    ensurePopulation(bucket)
    SetPlayerRoutingBucket(src, bucket)
    playerBucket[src] = bucket

    reportBucket(src, ('เข้า "%s" (ระยะ %.1fm)'):format(entry.key, dist))
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
end)

-- resource ถูกหยุดขณะมีคนอยู่ในมิติแยก — ดึงทุกคนกลับมิติหลัก ไม่งั้นค้างอยู่มิติเปล่าจนกว่าจะ relog
AddEventHandler('onResourceStop', function(res)
    if res ~= RESOURCE then return end
    for src in pairs(playerBucket) do
        SetPlayerRoutingBucket(src, 0)
    end
    playerBucket = {}
end)
