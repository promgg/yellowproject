Config = {}

Config.Pickaxe   = "tool_pickaxe"

-- false = ซื้อจอบครั้งเดียวใช้ได้ตลอด ไม่มีวันหัก/พัง (แค่เช็คว่ามีจอบไหมก่อนขุด)
-- true  = เปิดระบบ durability ลดทุกครั้งที่ขุด แล้วมีโอกาสหักตอน durability ต่ำกว่า 20
-- true = จอบสึก ขุดครบ Config.MinesPerPickaxe ครั้ง หักจอบ 1 อัน / false = ใช้ได้ตลอดไม่มีวันพัง
Config.PickaxeDurability = true
Config.MinesPerPickaxe   = 10  -- ขุดกี่ครั้งถึงหักจอบ 1 อัน (นับเฉพาะครั้งที่ขุดสำเร็จ ยกเลิกกลางคันไม่นับ)

Config.KEY_E   = 0x17BEC168  -- E
Config.KEY_X   = 0x8CC9CD42  -- X

-- เปลี่ยนจากระบบกด LMB ซ้ำหลายครั้งต่อก้อน เป็น auto-loop ครั้งเดียวเหมือน MJ-Lumberjack (กด E ครั้งเดียว เล่นจนจบ)
Config.MiningDuration = 30    -- วินาที ต่อ 1 ก้อน (หลอดโหลดเต็ม = จบรอบ, สุ่มไอเทม 1 ครั้ง) ตามสเปกลูกค้าเดิม (6วิ x 5 ครั้ง)
Config.RockCooldown   = 60000   -- 1 นาที (ms) — ก้อนเดิมขุดซ้ำได้เมื่อครบเวลานี้ (แยกกันรายบุคคล)

-- ระยะกด E ขุดจริง (marker/scan หาไกลกว่านี้ได้เพื่อนำทาง แต่ hint+E ใช้รัศมีนี้เท่านั้น กันเห็น hint แต่กดไม่ติด)
Config.MineRange = 3.0

-- ระยะที่ marker ขึ้นเหนือก้อนแร่ — ขึ้น "ทุกก้อน" ในระยะนี้ ไม่ใช่แค่ก้อนที่ใกล้สุด
-- ตั้ง 80 ให้ครอบทั้งโซน (RocksZone รัศมี 50) ได้แม้ยืนริมขอบ
Config.MarkerRange = 80.0

-- ระยะสตรีมหิน (เมตร): สร้าง object หินเฉพาะก้อนที่อยู่ในรัศมีนี้รอบผู้เล่น ลบเมื่อออกไกล
-- เพราะสร้างตอนผู้เล่นอยู่ใกล้ collision จะโหลดแล้ว หินตกพื้นถูก (กันหินลอยกลางอากาศ) + ไม่เปลือง object
Config.StreamRadius = 80.0

-- ── โซนเหมืองแต่ละเมือง ── field Town ใช้จับคู่กับ Config.MiningRewards[Town]
Config.RocksZone = {
    {
        Name = "Valentine Mining",
        Town = "Valentine",
        Coords = vector3(-68.4079, 163.3624, 98.7570), -- heading 245.6089
        Radius = 50.0,
        Blips = {
            Color = "COLOR_RED",
            Style = "BLIP_STYLE_CHALLENGE_OBJECTIVE",
            Sprite = "blip_ambient_hitching_post"
        }
    },
    {
        Name = "Rhodes Mining",
        Town = "Rhodes",
        Coords = vector3(1501.8263, -1848.4946, 57.7638), -- heading 358.4254
        Radius = 50.0,
        Blips = {
            Color = "COLOR_RED",
            Style = "BLIP_STYLE_CHALLENGE_OBJECTIVE",
            Sprite = "blip_ambient_hitching_post"
        }
    },
    {
        Name = "Annesburg Mining",
        Town = "Annesburg",
        Coords = vector3(2354.3000, 1413.1196, 102.4316), -- heading 58.7781
        Radius = 50.0,
        Blips = {
            Color = "COLOR_RED",
            Style = "BLIP_STYLE_CHALLENGE_OBJECTIVE",
            Sprite = "blip_ambient_hitching_post"
        }
    },
}

-- ตำแหน่งที่สปาวน์ก้อนหินให้ขุดได้จริง — แต่ละจุดเลือกโหมดได้ 2 แบบ (พอร์ตแนวคิด random มาจาก
-- rimlay-jobx: model:genratecoords()/createobject() — สุ่มจุดในรัศมี เว้นระยะห่างขั้นต่ำ กันวางทับกัน):
--   mode = "manual" : coords เดียว fixed (แบบเดิม ต้องวางเองทีละจุด)
--   mode = "random" : สุ่มกระจาย count ก้อนในรัศมี center รอบจุดศูนย์กลาง ไม่ต้องวางเองทีละก้อน
--                      (minSpacing = ระยะห่างขั้นต่ำระหว่างก้อน กันวางทับกัน, default 7.0 เมตร)
Config.MiningZones = {
    -- count 6 -> 10 ก้อนต่อเมือง (radius 20 คงเดิม — จำลองอัลกอริทึม buildRockDefs 2000 รอบแล้ว
    -- ใส่ 10 ก้อนที่ระยะห่าง 7 ม. ได้ครบทุกรอบ ไม่มีก้อนไหนตกไปใช้ fallback ที่วางทับกัน
    -- ไม่ขยายรัศมีดีกว่า ก้อนจะได้ไม่กระจายออกไปโผล่บนภูมิประเทศที่ยังไม่ได้ตรวจ)
    { mode = "random", center = vector3(-60.8620, 173.0856, 98.3558), radius = 20.0, count = 10, minSpacing = 7.0 }, -- Valentine
    { mode = "random", center = vector3(1501.8263, -1848.4946, 57.7638), radius = 20.0, count = 10, minSpacing = 7.0 }, -- Rhodes
    -- { mode = "random", center = vector3(2354.3000, 1413.1196, 102.4316), radius = 20.0, count = 6, minSpacing = 7.0 }, -- Annesburg

    -- { mode = "manual", coords = vector3(-60.8620, 173.0856, 98.3558) }, -- Valentine
    -- { mode = "manual", coords = vector3(1501.8263, -1848.4946, 57.7638) }, -- Rhodes
    { mode = "manual", coords = vector3(2363.4851, 1410.4780, 105.8705) }, -- Annesburg
    { mode = "manual", coords = vector3(2354.8176, 1422.5095, 98.9491) }, -- Annesburg
    { mode = "manual", coords = vector3(2338.0120, 1416.3689, 97.9154) }, -- Annesburg
    { mode = "manual", coords = vector3(2327.9375, 1433.3787, 89.2085) }, -- Annesburg
    { mode = "manual", coords = vector3(2329.3333, 1450.4409, 89.3269) }, -- Annesburg
    { mode = "manual", coords = vector3( 2356.1023, 1403.9558, 104.3499) }, -- Annesburg   
    -- เพิ่มอีก 5 จุด (พิกัดเดินเก็บในเกม) — Annesburg รวมเป็น 11 จุด
    -- manual ไม่มีระบบเว้นระยะเหมือน random: 3 คู่นี้ห่างกันแค่ 4.6-5.7 m (ต่ำกว่า minSpacing 7 ของ random)
    -- ยังขุดได้ปกติ แค่ก้อนจะดูชิดกัน — ถ้าเห็นแล้วเบียดไปบอกได้ ขยับจุดได้ทีละจุด
    { mode = "manual", coords = vector3(2345.1482, 1397.5557, 104.4244) }, -- Annesburg
    { mode = "manual", coords = vector3(2338.9031, 1405.9114, 102.5099) }, -- Annesburg
    { mode = "manual", coords = vector3(2337.7500, 1410.6438, 100.1080) }, -- Annesburg (ใกล้จุดที่ 3 เดิม 5.7 m)
    { mode = "manual", coords = vector3(2356.0933, 1399.3822, 105.7895) }, -- Annesburg (ใกล้จุดที่ 6 เดิม 4.6 m)
    { mode = "manual", coords = vector3(2347.6687, 1407.3798, 101.3167) }, -- Annesburg
}

Config.MiningObject = "old_hen_rock_scree_sim_08"

-- รางวัลแยกตามเมือง (ต้องยืนอยู่ในโซนของเมืองนั้นถึงจะสุ่มจาก pool นี้ได้)
-- chance เป็น % ตรงๆ รวมกัน = 100 พอดีในแต่ละเมือง (ไม่มีโอกาส "ไม่ได้ของ" สำหรับแร่ ตามสเปก)
-- server.lua เช็คเมืองปัจจุบันผ่าน native _GET_MAP_ZONE_AT_COORDS (type=1=TOWN) แล้วสุ่ม roll 1-100 แบบ cumulative จาก pool ของเมืองนั้น
Config.MiningRewards = {
    Valentine = {
        { name = "mat_diamond", label = "เพชร",     chance = 10, amount = 1 },
        { name = "mat_iron",    label = "เหล็ก",     chance = 15, amount = 1 },
        { name = "mat_copper",  label = "ทองแดง",    chance = 20, amount = 1 },
        { name = "mat_coal",    label = "ถ่านหิน",   chance = 25, amount = 1 },
        { name = "mat_stone",   label = "หิน",       chance = 30, amount = 1 },
    },
    Rhodes = {
        { name = "mat_emerald", label = "มรกต",      chance = 10, amount = 1 },
        { name = "mat_iron",    label = "เหล็ก",     chance = 15, amount = 1 },
        { name = "mat_copper",  label = "ทองแดง",    chance = 20, amount = 1 },
        { name = "mat_sulfur",  label = "ซัลเฟอร์",  chance = 25, amount = 1 },
        { name = "mat_stone",   label = "หิน",       chance = 30, amount = 1 },
    },
    Annesburg = {
        { name = "mat_ruby",    label = "ทับทิม",    chance = 10, amount = 1 },
        { name = "mat_iron",    label = "เหล็ก",     chance = 15, amount = 1 },
        { name = "mat_copper",  label = "ทองแดง",    chance = 20, amount = 1 },
        { name = "mat_nitrate", label = "ไนเตรท",    chance = 25, amount = 1 },
        { name = "mat_stone",   label = "หิน",       chance = 30, amount = 1 },
    },
}
