Config = {}
-- ✅ ผลลัพธ์

-- สามารถควบคุมค่าดาเมจอาวุธทั้งหมด
-- ปิด/เปิดการทำ Critical Hit ได้ตามต้องการ
-- ป้องกันปัญหาการยิงหัวทีเดียวตาย (Headshot One-Shot Kill)

Config.PvPDamageOnly = false -- เปิด = true / ปิด = false
-- 📌 รายละเอียดการตั้งค่า
-- Config.PvPDamageOnly

-- ถ้าเป็น true → ค่าดาเมจจะมีผลเฉพาะเวลาผู้เล่นยิงกันเอง (PvP)
-- ถ้าเป็น false → ค่าดาเมจจะมีผลกับทุกเป้าหมาย (NPC และผู้เล่น)
-- Config.WeaponDamage

-- ใช้สำหรับกำหนดค่าดาเมจของแต่ละอาวุธ
-- มีพารามิเตอร์ 3 ค่า
-- Name → ชื่ออาวุธ
-- Damage → ค่าดาเมจที่ต้องการ (ค่าเริ่มต้น = 1.0)
-- EnableCritical → เปิด/ปิดการติด Critical Hit (ค่าดาเมจพิเศษ)

Config.OneShotHeadshot = false -- เปิด = true / ปิด = false
-- ถ้า Config.OneShotHeadshot = true → โดนยิงหัว = ตายทันที
-- ถ้า Config.OneShotHeadshot = false → ใช้ค่าดาเมจที่กำหนดไว้


Config.WeaponDamage = {
    
    -- Melee (อาวุธระยะประชิด)
    {Name = 'WEAPON_UNARMED', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_MELEE_CLEAVER', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_MELEE_HAMMER', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_MELEE_HATCHET', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_MELEE_HATCHET_HUNTER', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_MELEE_KNIFE', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_MELEE_KNIFE_HORROR', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_MELEE_KNIFE_JAWBONE', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_MELEE_KNIFE_RUSTIC', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_MELEE_KNIFE_TRADER', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_MELEE_MACHETE', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_MELEE_MACHETE_COLLECTOR', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_MELEE_MACHETE_HORROR', Damage = 1.0, EnableCritical = true},


    -- Revolvers (ปืนลูกโม่)
    {Name = 'WEAPON_REVOLVER_CATTLEMAN', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_REVOLVER_CATTLEMAN_MEXICAN', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_REVOLVER_DOUBLEACTION', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_REVOLVER_DOUBLEACTION_GAMBLER', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_REVOLVER_LEMAT', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_REVOLVER_NAVY', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_REVOLVER_NAVY_CROSSOVER', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_REVOLVER_SCHOFIELD', Damage = 1.0, EnableCritical = true},

    -- Pistols (ปืนพกออโต้)
    {Name = 'WEAPON_PISTOL_M1899', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_PISTOL_MAUSER', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_PISTOL_SEMIAUTO', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_PISTOL_VOLCANIC', Damage = 1.0, EnableCritical = true},

    -- Snipers (ปืนสไนเปอร์)
    {Name = 'WEAPON_SNIPERRIFLE_CARCANO', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_SNIPERRIFLE_ROLLINGBLOCK', Damage = 1.0, EnableCritical = true},

    -- Rifles (ปืนไรเฟิล)
    {Name = 'WEAPON_RIFLE_BOLTACTION', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_RIFLE_ELEPHANT', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_RIFLE_SPRINGFIELD', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_RIFLE_VARMINT', Damage = 1.0, EnableCritical = true},

    -- Repeaters (ปืนลูกซองกึ่งอัตโนมัติ)
    {Name = 'WEAPON_REPEATER_CARBINE', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_REPEATER_EVANS', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_REPEATER_HENRY', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_REPEATER_WINCHESTER', Damage = 1.0, EnableCritical = true},

    -- Thrown (อาวุธขว้าง)
    {Name = 'WEAPON_THROWN_DYNAMITE', Damage = 1.0, EnableCritical = true},
    -- {Name = 'WEAPON_THROWN_MOLOTOV', Damage = 1.0, EnableCritical = true}, -- Doesn't have affect

    {Name = 'WEAPON_THROWN_POISONBOTTLE', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_THROWN_THROWING_KNIVES', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_THROWN_TOMAHAWK', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_THROWN_TOMAHAWK_ANCIENT', Damage = 1.0, EnableCritical = true},

    -- Shotguns (ปืนลูกซอง)
    {Name = 'WEAPON_SHOTGUN_DOUBLEBARREL', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_SHOTGUN_PUMP', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_SHOTGUN_REPEATING', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_SHOTGUN_SAWEDOFF', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_SHOTGUN_SEMIAUTO', Damage = 1.0, EnableCritical = true},

    -- Bows (ธนู)
    {Name = 'WEAPON_BOW', Damage = 1.0, EnableCritical = true},
    {Name = 'WEAPON_BOW_IMPROVED', Damage = 1.0, EnableCritical = true},
}
