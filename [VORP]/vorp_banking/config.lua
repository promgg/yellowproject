Config                    = {}

Config.Lang               = "English"

Config.Key                = 0x17BEC168 -- [E] (เปลี่ยนจาก G เดิม ให้ตรงกับปุ่มโต้ตอบมาตรฐานของรีซอร์สอื่นในโปรเจกต์)
Config.HoldMs             = 900        -- ต้องกดค้างกี่ ms ถึงจะเปิดเมนูธนาคาร (lp_textui:TextUIHold)
Config.TxCooldownMs       = 750        -- คูลดาวน์ต่อ event การเงินต่อผู้เล่น (กัน spam/dupe จากการยิงถี่)

-- ── แจ้งเตือนผ่าน pNotify ทั้งหมด (แทน VORPcore.NotifyRightTip เดิม) ──
-- เรียกได้ทั้งฝั่ง server ({source=..., text=..., time=..., type=...}) และฝั่ง client ({text=..., time=..., type=...})
function Notify(data)
    local text = data.text or "No message"
    local duration = data.time or 4000
    local notificationType = data.type or "info"
    if notificationType == "info" then notificationType = "information" end -- pNotify (noty) ใช้คำเต็ม ไม่ใช่ "info"
    local src = data.source

    if IsDuplicityVersion() then
        TriggerClientEvent("pNotify:SendNotification", src, { type = notificationType, text = text, timeout = duration })
    else
        exports.pNotify:SendNotification({ type = notificationType, text = text, timeout = duration })
    end
end

Config.banktransfer       = true       -- If you want to use bank transfer

Config.feeamount          = 0.9        -- 0.9 is 10% of the transferred amount, 0.5 is 50% of the transferred amount, 0.7 is 30% of the transferred amount

-- ── ตู้เซฟ (locker) — ค่ากลางที่ใช้ร่วมกันทุกธนาคาร ──
-- costslot/maxslots ต่อธนาคารด้านล่างอ้างอิงค่าจากตรงนี้ ปรับที่เดียวมีผลทุกเมือง
Config.SafeBox = {
    defaultInvspace = 50,  -- ช่องเริ่มต้นเมื่อเปิดบัญชีธนาคารครั้งแรก
    minSlots        = 20,  -- ขั้นต่ำของระบบตู้ (กันค่าที่เพี้ยน/ต่ำกว่านี้ผ่านไปได้)
    maxSlots        = 500, -- ขั้นสูงสุดที่อัปเกรดได้
    costPerSlot     = 100, -- ราคาต่อ 1 ช่อง
    -- true = ใช้ตู้เซฟ/อัปเกรดช่องได้เฉพาะธนาคารของเมืองบ้านเกิดตัวเอง (เช็คผ่าน nx_cityselect)
    -- ฝาก/ถอน/โอนเงินไม่ถูกล็อก ใช้ธนาคารเมืองไหนก็ได้เหมือนเดิม
    -- ถ้า nx_cityselect ไม่ได้ติดตั้ง/ไม่ start จะไม่ล็อก (fail-open) กันฟีเจอร์ตายทั้งระบบ
    lockToOwnCity   = true,
}

Config.banks              = {

    Valentine = {                                              -- Names must be the same in databse BANKS TABLE
        city = "Valentine",                                    -- Names must be the same in databse BANKS TABLE
        name = "Valentine Bank",
        BankLocation = { x = -308.02, y = 773.82, z = 116.7 }, -- Bank Location (X, Y, Z)
        blipsprite = -2128054417,
        blipAllowed = true,
        NpcAllowed = true,
        NpcModel = "S_M_M_BankClerk_01",
        NpcPosition = { x = -308.02, y = 773.82, z = 116.7, h = 18.69 }, -- NPC Postition (X, Y, Z, H)
        StoreHoursAllowed = true,
        StoreOpen = 7,                                                   -- am
        StoreClose = 22,                                                 -- pm
        distOpen = 3.5,
        gold = true,                                                     -- If you want deposit and withdraw gold
        items = true,                                                    -- If you want use safebox
        upgrade = true,                                                  -- If you want upgrade safebox
        costslot = Config.SafeBox.costPerSlot,                           -- choose price for upgrade + 1 slot
        maxslots = Config.SafeBox.maxSlots,                              -- choose max slots for upgrade
        canStoreWeapons = true,
    },

    Rhodes = {
        name = "Rhodes Bank",
        BankLocation = { x = 1294.14, y = -1303.06, z = 77.04 },
        city = "Rhodes",
        blipsprite = -2128054417,
        blipAllowed = true,
        NpcAllowed = true,
        NpcModel = "S_M_M_BankClerk_01",
        NpcPosition = { x = 1292.84, y = -1304.74, z = 76.04, h = 327.08 },
        StoreHoursAllowed = true,
        StoreOpen = 7,   -- am
        StoreClose = 21, -- pm
        distOpen = 3.5,
        gold = false,
        items = true,
        upgrade = true,
        costslot = Config.SafeBox.costPerSlot,
        maxslots = Config.SafeBox.maxSlots,
        canStoreWeapons = true,


    },

    Annesburg = {
        name = "Annesburg Bank",
        BankLocation = { x = 2938.9592, y = 1287.0208, z = 44.6528 },
        city = "Annesburg",
        blipsprite = -2128054417,
        blipAllowed = true,
        NpcAllowed = true,
        NpcModel = "S_M_M_BankClerk_01",
        NpcPosition = { x = 2938.9592, y = 1287.0208, z = 44.6528, h = 335.5728 },
        StoreHoursAllowed = true,
        StoreOpen = 7,   -- am
        StoreClose = 21, -- pm
        distOpen = 3.5,
        gold = false,
        items = true,
        upgrade = true,
        costslot = Config.SafeBox.costPerSlot,
        maxslots = Config.SafeBox.maxSlots,
        canStoreWeapons = true,

    },
     -- Blackwater = {
    --     name = "Blackwater Bank",
    --     BankLocation = { x = -813.18, y = -1277.60, z = 43.68 },
    --     city = "Blackwater",
    --     blipsprite = -2128054417,
    --     blipAllowed = true,
    --     NpcAllowed = true,
    --     NpcModel = "S_M_M_BankClerk_01",
    --     NpcPosition = { x = -813.18, y = -1275.42, z = 42.64, h = 176.86 },
    --     StoreHoursAllowed = true,
    --     StoreOpen = 7,   -- am
    --     StoreClose = 21, -- pm
    --     distOpen = 3.5,
    --     gold = true,
    --     items = true,
    --     upgrade = true,
    --     costslot = 10,
    --     maxslots = 100,
    --     canStoreWeapons = true,

    -- },

    -- SaintDenis = {
    --     city = "SaintDenis",
    --     name = "Saint Denis Bank",
    --     BankLocation = { x = 2644.08, y = -1292.21, z = 52.29 },
    --     blipsprite = -2128054417,
    --     blipAllowed = true,
    --     NpcAllowed = true,
    --     NpcModel = "S_M_M_BankClerk_01",
    --     NpcPosition = { x = 2645.12, y = -1294.37, z = 51.25, h = 30.64 },
    --     StoreHoursAllowed = true,
    --     StoreOpen = 7,   -- am
    --     StoreClose = 23, -- pm
    --     distOpen = 3.5,
    --     gold = true,
    --     items = true,
    --     upgrade = true,
    --     costslot = 10,
    --     maxslots = 100,
    --     canStoreWeapons = true,


    -- },
}
