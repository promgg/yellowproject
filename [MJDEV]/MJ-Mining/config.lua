Config = {}

Config.Pickaxe   = "tool_pickaxe"

-- false = ซื้อจอบครั้งเดียวใช้ได้ตลอด ไม่มีวันหัก/พัง (แค่เช็คว่ามีจอบไหมก่อนขุด)
-- true  = เปิดระบบ durability ลดทุกครั้งที่ขุด แล้วมีโอกาสหักตอน durability ต่ำกว่า 20
Config.PickaxeDurability = false

Config.KEY_E   = 0x17BEC168  -- E
Config.KEY_X   = 0x8CC9CD42  -- X

-- เปลี่ยนจากระบบกด LMB ซ้ำหลายครั้งต่อก้อน เป็น auto-loop ครั้งเดียวเหมือน MJ-Lumberjack (กด E ครั้งเดียว เล่นจนจบ)
Config.MiningDuration = 30    -- วินาที ต่อ 1 ก้อน (หลอดโหลดเต็ม = จบรอบ, สุ่มไอเทม 1 ครั้ง) ตามสเปกลูกค้าเดิม (6วิ x 5 ครั้ง)
Config.RockCooldown   = 900000  -- 15 นาที (ms)

-- ระยะกด E ขุดจริง (marker/scan หาไกลกว่านี้ได้เพื่อนำทาง แต่ hint+E ใช้รัศมีนี้เท่านั้น กันเห็น hint แต่กดไม่ติด)
Config.MineRange = 3.0

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
    { mode = "random", center = vector3(-60.8620, 173.0856, 98.3558), radius = 20.0, count = 6, minSpacing = 7.0 }, -- Valentine
    { mode = "random", center = vector3(1501.8263, -1848.4946, 57.7638), radius = 20.0, count = 6, minSpacing = 7.0 }, -- Rhodes
    { mode = "random", center = vector3(2354.3000, 1413.1196, 102.4316), radius = 20.0, count = 6, minSpacing = 7.0 }, -- Annesburg

    -- { mode = "manual", coords = vector3(-60.8620, 173.0856, 98.3558) }, -- Valentine
    -- { mode = "manual", coords = vector3(1501.8263, -1848.4946, 57.7638) }, -- Rhodes
    -- { mode = "manual", coords = vector3(2354.3000, 1413.1196, 102.4316) }, -- Annesburg
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
