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
    BlockRoleplayThreatActions = true,

    -- true = debug print ตอนระบบเริ่มทำงาน
    Debug = false
}

-- Persistent ped action flags. These are global for the local player and are
-- independent from the proximity/control checks in AntiCombat above.
Config.ActionDisableFlags = {
    Enable = true,
    Flags = {
        0,  -- ADF_MELEE           ต่อยเปล่า/ฟันระยะประชิด
        1,  -- ADF_GRAPPLE         จับล็อกตัว
        2,  -- ADF_ATTACK          แอ็กชันโจมตี (ดู note ด้านล่าง)
        3,  -- ADF_KNOCKOUT        น็อกสลบ
        4,  -- ADF_KICK            เตะ
        5,  -- ADF_SHOVE           ผลัก
        6,  -- ADF_CHOKE           รัดคอ
        13, -- ADF_DISARM          ปัดอาวุธหลุดมือ
        15, -- ADF_TAKEDOWN        ทุ่ม/จับล้ม
        16, -- ADF_EXECUTION       ประหาร (finisher)
        17, -- ADF_STEALTH_KILL    ลอบสังหาร
        26, -- ADF_ARM_GRAB        คว้าแขน
        27, -- ADF_LEG_GRAB        คว้าขา
        28, -- ADF_KNOCKDOWN       ทำให้ล้ม
        30, -- ADF_DEFENSIVE_AREA_AUTO_GRAPPLE  auto-grapple ในพื้นที่ป้องกัน
        31, -- ADF_GRAPPLE_TRANSITION           เปลี่ยนท่าขณะล็อกตัว
        32, -- ADF_AUTO_SHOVE      ผลักอัตโนมัติตอนเดินชน
        33, -- ADF_TACKLE          พุ่งเข้าใส่
        34, -- ADF_PAIRED_TURN_ATTACK           โจมตีคู่แบบหมุนตัว
    },
    -- ตั้งใจ "ไม่" ปิดกลุ่มป้องกัน/ดิ้นหนี เพราะปิดแล้วผู้เล่นจะติดกับ ออกจากท่าไม่ได้:
    --   7 BLOCKING · 8 COUNTER · 10 DODGE · 11 PARRY · 20 STRUGGLE
    --   21 ESCAPE · 22 REVERSAL · 23 BREAKOUT · 24 RELEASE
    Debug = false,
}
