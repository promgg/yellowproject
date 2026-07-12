Config = {}

-- ─── วิธีเปิด UI ───────────────────────────────────────────────────────────────
-- 'command' = เปิดด้วย command อย่างเดียว
-- 'zone'    = เปิดที่ zone อย่างเดียว
-- 'both'    = ทั้ง command และ zone
Config.OpenMethod = 'both'
Config.Command    = 'market'

-- ไอเทมที่ต้องมีสำหรับ command (ถ้า enabled = false ไม่ต้องมีไอเทม)
Config.CommandItem = {
    enabled = false,
    item    = 'market_card',
}

-- ─── Zone ──────────────────────────────────────────────────────────────────────
-- เปิด UI ด้วยปุ่ม E ค้าง (control 0x17BEC168) ผ่าน lp_textui:TextUIHold — poll เฉพาะตอนยืนในโซน (client/cl_main.lua)
Config.HoldMs = 900 -- กดค้าง E กี่ ms ถึงเปิดตลาด (เท่ากับ MJ-Planting/lp_animalFarm)

Config.Zones = {
    {
        name   = 'market_central',
        label  = 'ตลาดกลาง',
        coords = vector3(1421.9254, 356.3162, 88.8898),
        radius = 3.0,
        item   = { enabled = false, item = '' },
        blip   = { enabled = true,  sprite = 819673798, scale = 0.6, label = 'ตลาดกลาง' }, -- blip_shop_market_stall
        textui = 'กด [E] เพื่อเปิดตลาด',
        ped    = { enabled = true, model = 'casp_coachrobbery_micah_males_01', heading = 0.0 },
    },
    -- เพิ่ม zone อื่น ๆ ได้ที่นี่
}

-- ─── ภาษี ──────────────────────────────────────────────────────────────────────
Config.TaxRate = 10     -- เปอร์เซ็นต์ภาษีที่หักจากผู้ขายตอนรับเงิน
Config.TaxMin  = 100    -- ภาษีขั้นต่ำ (หน่วย: เงิน)

-- ─── การลงขาย ──────────────────────────────────────────────────────────────────
Config.DurationOptions      = { 12, 24, 48 }   -- ตัวเลือกระยะเวลาขาย (ชั่วโมง)
Config.MaxListingsPerPlayer = 10               -- จำนวนสินค้าลงขายสูงสุดต่อผู้เล่น
Config.ItemsPerPage         = 20               -- จำนวนรายการต่อหน้าในแท็บ BUY

-- ─── Anti-Cheat ────────────────────────────────────────────────────────────────
Config.RateLimit = {
    listingsPerMinute = 3,   -- ลงขายได้ไม่เกิน N ครั้งต่อนาที
}
-- หมายเหตุ: "banOnDetect" ไม่ได้ ban ถาวรเอง — TriggerAntiCheat() ใน sv_anticheat.lua
-- แค่ DropPlayer() (kick) และ log เข้า Discord ผู้ดูแลต้อง ban เองผ่าน txAdmin
Config.AntiCheat = {
    banOnDetect  = true,    -- true = kick + log (ให้แอดมิน ban ผ่าน txAdmin) — ไม่ใช่ ban อัตโนมัติ
    kickOnDetect = false,
}

-- ─── Log ───────────────────────────────────────────────────────────────────────
Config.Log = {
    enabled   = true,
    webhook   = 'YOUR_DISCORD_WEBHOOK_HERE',
    botName   = 'Marketplace',
    botAvatar = '',
    color     = 12889622,   -- decimal สีทอง (brass)
    events = {
        list      = true,
        buy       = true,
        cancel    = true,
        claim     = true,
        anticheat = true,
    },
}

-- ─── UI Theme (ส่งไปยัง NUI) — Wanted Poster palette (ตรงกับ UI/Gacha) ────────
Config.Theme = {
    accentBuy     = '#60cd8e',   -- เขียว uncommon (แทน buy)
    accentSell    = '#ff6b6b',   -- danger-red (แทน sell/ยกเลิก)
    accentItem    = '#f0ca78',   -- whiskey-gold (แทน item/claim)
    btnBuyBg      = 'rgba(96,205,142,0.14)',
    btnSellBg     = 'rgba(255,107,107,0.14)',
    btnItemBg     = 'rgba(240,202,120,0.14)',
    accent        = '#937036',   -- brass
    accentDeep    = '#573d18',   -- brass-deep
    bgPrimary     = '#131313',   -- void-black
    bgSecondary   = '#1c1c1c',
    bgTertiary    = '#232323',   -- smoke-overlay base
    bgHover       = '#2a2a2a',
    border        = '#7c5526',   -- saddle-brown
    textPrimary   = '#ffffff',   -- ink-white
    textSecondary = '#d9d9d9',   -- ledger-silver
    textMuted     = '#747474',   -- ledger-silver-deep
    radius        = '4px',       -- cards are printed tickets: square-ish
    radiusSm      = '4px',
}
