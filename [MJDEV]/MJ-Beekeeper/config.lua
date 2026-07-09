Config = {}

-- การตั้งค่า
Config.CheckTime = 30000 -- 30 วินาที (ตรวจสอบความพร้อมของรังผึ้ง)
Config.BeeSting = 10 -- การเสียพลังชีวิตต่อการโดนต่อย (ทุก 5 วินาที)

-- การควบคุม
Config.Controls = {
    EnterKey = 0xD9D0E1C0 -- SPACE (ปุ่ม SPACE)
}

-- การวางรังผึ้งและการเก็บน้ำผึ้ง
Config.ApiBeeHives = {
    MaxHives = 5, -- จำนวนรังผึ้งสูงสุด
    CooldownTime = 60,  -- 600 วินาที = 10 นาที
    CollectionDistance = 150.0 -- ระยะทางที่สามารถเก็บน้ำผึ้งได้
}

-- ข้อความ
Config.Texts = {
    CollectPrompt = "กด [SPACE] เพื่อเก็บน้ำผึ้ง!", -- ข้อความเมื่อกดเพื่อเก็บน้ำผึ้ง
    Collecting = "กำลังเก็บน้ำผึ้ง...", -- ข้อความขณะเก็บน้ำผึ้ง
    EmptyHive = "รังผึ้งว่างเปล่า", -- ข้อความเมื่อรังผึ้งไม่มีน้ำผึ้ง
    Collected = "เก็บน้ำผึ้งแล้ว!" -- ข้อความหลังจากเก็บน้ำผึ้ง
}

-- การตั้งค่ารังผึ้ง
Config.BeeHives = {
    { label = 'BeeHive', name = 'beehive_box1', model = 'bee_house_gk_1' },
    { label = 'BeeHive', name = 'beehive_box2', model = 'bee_house_gk_2' },
    { label = 'BeeHive', name = 'beehive_box3', model = 'bee_house_gk_3' },
    { label = 'BeeHive', name = 'beehive_box4', model = 'bee_house_gk_4' },
    { label = 'BeeHive', name = 'beehive_box5', model = 'bee_house_gk_5' },
    { label = 'BeeHive', name = 'beehive_box6', model = 'bee_house_gk_6' },
}

-- ตำแหน่งของสถานีและ Blip สำหรับผู้เลี้ยงผึ้ง
Config.BeekeeperPoint = {
    {
        name = 'Beekeeper Crafting 1',
        coords = vector3(-2312.68, 571.04, 119.68),
        radius = 50.0,
        blips = {
            enabled = true,  -- เปิดการแสดง Blip
            sprite = 1865251988,  -- รูปไอคอนของบลิป (เลขจาก GTA)
            scale = 0.7,  -- ขนาดของบลิป
            color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE',
            text = 'Beekeeper Crafting 1'  -- ข้อความของบลิป
        }
    },
    {
        name = 'Beekeeper Crafting 2',
        coords = vector3(-1642.77, -335.851, 172.22273),
        radius = 50.0,
        blips = {
            enabled = true,
            sprite = 1865251988,
            scale = 0.7,
            color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE',
            text = 'Beekeeper Crafting 2'
        }
    },
    -- เพิ่มจุดอื่นๆ ตามต้องการ
}


-- อนิเมชั่นสำหรับการเก็บน้ำผึ้ง
Config.ApiaryItem = {
    Name = "รังผึ้ง",
    AnimDict = "amb_work@world_human_box_pickup@1@male_a@stand_exit_withprop",
    AnimName = "exit_front"
}

-- รางวัลที่ได้รับเมื่อเก็บน้ำผึ้ง
Config.Rewards = {
    { Item = "honey", Amount = 1 }, -- น้ำผึ้ง
    { Item = "honeycomb", Amount = 100 }, -- รังผึ้ง
    { Item = "bee", Amount = 1 } -- ผึ้ง
}


