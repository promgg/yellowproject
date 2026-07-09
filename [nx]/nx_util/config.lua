Config = {}

Config.AntiCombat = {
    Enable = true,

    -- ระยะที่เริ่มบล็อก combat contextual action ใกล้ผู้เล่นอื่น
    ProximityRadius = 2.2,

    -- true = บล็อกเฉพาะตอนวิ่ง/sprint
    -- false = บล็อกเมื่ออยู่ใกล้ผู้เล่นเสมอ
    OnlyWhenRunning = true,

    -- true = ถ้ากำลังเล็งปืน ให้ยังยิงได้
    AllowShootingWhenAiming = true,

    -- true = บล็อก INPUT_ATTACK เฉพาะตอนถือ melee/unarmed
    BlockAttackOnlyMeleeWeapon = true,

    -- false = ปล่อย animation แนว RP threat เช่น ล็อคคอ, มีดจี้, ปืนจ่อหัว
    -- true = บล็อก grapple/choke/lock-on/context threat action ใกล้ผู้เล่นด้วย
    BlockRoleplayThreatActions = false,

    -- true = debug print ตอนระบบเริ่มทำงาน
    Debug = false
}
