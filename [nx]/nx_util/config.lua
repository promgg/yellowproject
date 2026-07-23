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
    -- ⚠️ flag กลุ่มนี้เป็น "global ต่อ ped" ใช้กับ *ทุกเป้าหมาย* (ทั้งผู้เล่นและสัตว์) แยกไม่ได้
    --    → ปิดท่าที่ใช้ล่าสัตว์เมื่อไหร่ ล่าสัตว์พังทันที เลยเหลือเฉพาะท่าที่ใช้ก่อกวนคนล้วน ๆ
    Flags = {
        -- 4,  -- ADF_KICK            เตะ
        5,  -- ADF_SHOVE           ผลัก
        6,  -- ADF_CHOKE           รัดคอ
        13, -- ADF_DISARM          ปัดอาวุธหลุดมือ (สัตว์ไม่ถืออาวุธ จึงไม่กระทบล่าสัตว์)
        32, -- ADF_AUTO_SHOVE      ผลักอัตโนมัติตอนเดินชน
      17, --STEALTH_KILL  แทงมีดสัตว์ตอนย่อง (ท่าล่าสัตว์หลัก)
      16, --EXECUTION     เชือดสัตว์ที่บาดเจ็บ
      15, --TAKEDOWN      ทุ่ม/จับล้มสัตว์
      3,  --KNOCKOUT      น็อกสัตว์
      34, --PAIRED_TURN_ATTACK  ท่าโจมตีแบบ paired/sync — ฟันสัตว์ใช้ anim กลุ่มนี้
      33, --TACKLE              พุ่งเข้าใส่เป้าหมาย (ใช้กับสัตว์ด้วย)
      1,  --GRAPPLE             คว้า/จับ — รวมจับสัตว์เล็ก + melee ระยะติดตัว
      34, --PAIRED_TURN_ATTACK  ท่าโจมตีแบบ paired/sync — ฟันสัตว์ใช้ anim กลุ่มนี้
      33, --TACKLE              พุ่งเข้าใส่เป้าหมาย (ใช้กับสัตว์ด้วย)
      1,  --GRAPPLE             คว้า/จับ — รวมจับสัตว์เล็ก + melee ระยะติดตัว
    },    
    -- ตั้งใจ "ไม่" ปิดกลุ่มป้องกัน/ดิ้นหนี เพราะปิดแล้วผู้เล่นจะติดกับ ออกจากท่าไม่ได้:
    --   7 BLOCKING · 8 COUNTER · 10 DODGE · 11 PARRY · 20 STRUGGLE
    --   21 ESCAPE · 22 REVERSAL · 23 BREAKOUT · 24 RELEASE
    Debug = false,
}
