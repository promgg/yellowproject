Config = {}

-- การตั้งค่ากลุ่ม Admin
Config.AdminGroup = "admin"  -- สามารถเปลี่ยนกลุ่มนี้ตามที่เซิร์ฟเวอร์ของคุณใช้งาน

-- คำสั่งที่ใช้ในการเปิด UI
Config.AdminCommand = "acode"  -- คำสั่งสำหรับ Admin
Config.PlayerCommand = "pcode"  -- คำสั่งสำหรับ Player 

-- โค้ดที่สุ่มได้พร้อมรางวัล
Config.RandomCodes = {
    {
        items = {
            {name = "water", count = 5},
            {name = "bread", count = 3}
        },
        money = 1000
    },
    {
        items = {
            {name = "meat", count = 2}
        },
        money = 2000,
        weapon = "weapon_revolver_cattleman",
        weapon_ammo = 6
    }
}

-- ตัวอย่างของรางวัลใน Config
Config.RewardCodes = {
    -- โค้ดทดสอบชั่วคราว — ใช้ไอเทมจริงที่มีในระบบ (food_bread/water/bandage_s) สำหรับเทสระบบ
    -- redeem เอง (cooldown, ใช้ซ้ำไม่ได้, time window, ได้ของจริง) ลบออกได้เมื่อตั้งโค้ดจริงแล้ว
    ["UATTEST5"] = {
        items = {
            {name = "mat_diamond", count = 60},
        },
        money = 5000,
    },
    ["WELCOME2025"] = {
        items = {
            {name = "water", count = 2},
            {name = "bread", count = 1}
        },
        money = 1000,  -- เงิน
        -- weapon = "weapon_rpg",  -- อาวุธ
        -- weapon_ammo = 10  -- กระสุน
    },
    ["VIPGIFT"] = {
        items = {
            {name = "armor", count = 1},
            {name = "medkit", count = 2}
        },
    },
    ["SUPERDEAL"] = {
        items = {
            {name = "water", count = 5},
            {name = "bread", count = 3},
            {name = "cooked_beef", count = 2}
        },
        money = 10000,  -- เงิน
        weapon = "weapon_rpg",  -- อาวุธ
        weapon_ammo = 10  -- กระสุน
    }
}

-- Check the current time and compare with valid time window
Config.CodeTimeWindow = {
    Starttime = "2026-01-01 00:00:00",
    Endtime   = "2026-12-31 23:59:59"
}
