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
        coords = vector3(1439.3651, 328.5001, 89.5615),
        radius = 3.0,
        item   = { enabled = false, item = '' },
        blip   = { enabled = true,  sprite = 819673798, scale = 0.6, label = 'ตลาดกลาง' }, -- blip_shop_market_stall
        textui = 'กด [E] เพื่อเปิดตลาด',
        -- casp_coachrobbery_lenny_males_01 เดิม เป็นโมเดลเฉพาะคัตซีนภารกิจปล้นรถม้า (Lenny) ไม่ stream
        -- เป็น ped ทั่วไปนอกภารกิจ ทำให้ LoadModel timeout ไม่มี NPC ขึ้น เปลี่ยนเป็นโมเดลที่ยืนยันแล้ว
        -- ว่าใช้งานได้จริงในเซิร์ฟนี้ (ใช้ใน MJ-Economy ตลาด 3 จุดที่ผ่าน ECO-11 มาแล้ว)
        ped    = { enabled = true, model = 'A_M_M_BiVWorker_01', heading = 276.1277 },
    },
    -- เพิ่ม zone อื่น ๆ ได้ที่นี่
}

-- ─── ภาษี ──────────────────────────────────────────────────────────────────────
Config.TaxRate = 10     -- เปอร์เซ็นต์ภาษีที่หักจากผู้ขายตอนรับเงิน (0 = ปิดภาษี)
Config.TaxMin  = 1    -- ภาษีขั้นต่ำ (หน่วย: เงิน)

-- คิดภาษีที่นี่ที่เดียว — ทั้งตอนซื้อ, ตอนจ่ายเงินให้ผู้ขาย และตอนโชว์ยอดใน UI
-- เดิมสูตรนี้ถูกก๊อปไว้ 3 ที่ (server 2 + NUI 1) และไม่ตรงกันด้วย: ฝั่ง NUI ยกเว้น TaxMin
-- เมื่อ TaxRate = 0 แต่ server ยังหัก TaxMin อยู่ ตั้งเป็น 0 เมื่อไหร่ยอดที่โชว์กับที่หักจริง
-- จะไม่ตรงกันทันที — ยึดตาม NUI (rate 0 = ปิดภาษีจริง) เพราะเป็นความหมายที่คนตั้งค่าคาดหวัง
function CalcTax(gross)
    gross = tonumber(gross) or 0
    if (Config.TaxRate or 0) <= 0 then return 0 end
    return math.max(Config.TaxMin or 0, math.floor(gross * Config.TaxRate / 100))
end

-- คืน net, tax, gross จากราคาต่อชิ้น × จำนวน
function CalcPayout(price, quantity)
    local gross = (tonumber(price) or 0) * (tonumber(quantity) or 1)
    local tax   = CalcTax(gross)
    return gross - tax, tax, gross
end

-- ─── การลงขาย ──────────────────────────────────────────────────────────────────
-- ตัวเลือกระยะเวลาขาย เขียนได้ 2 แบบ:
--   ตัวเลขเปล่า            = ชั่วโมง (แบบเดิม ยังใช้ได้)   เช่น 24
--   { value = N, unit = }  = 'hour' หรือ 'day'            เช่น { value = 7, unit = 'day' }
-- ตั้งเป็นวันได้เลยไม่ต้องคูณ 24 เอง และป้ายในหน้าลงขายจะขึ้นหน่วยตรงตามที่ตั้ง
Config.DurationOptions      = {
    { value = 7, unit = 'day' },
}
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

-- ─── Duration helper ───────────────────────────────────────────────────────────
-- แปลงตัวเลือกใน Config.DurationOptions เป็นชั่วโมง + ป้ายภาษาไทย ให้ที่เดียว
-- server ใช้คิด expires_at, client ส่งป้ายที่แปลงแล้วให้ NUI (NUI จะได้ไม่ต้องรู้เรื่องหน่วยเอง)
function ResolveDuration(option)
    -- ตัวเลขเปล่า = ชั่วโมง (รูปแบบเดิมก่อนรองรับหน่วยวัน)
    if type(option) == 'number' then
        return option, ('%d ชั่วโมง'):format(option)
    end

    if type(option) == 'table' then
        local value = tonumber(option.value) or 0
        if option.unit == 'day' then
            return value * 24, ('%d วัน'):format(value)
        end
        return value, ('%d ชั่วโมง'):format(value)
    end

    -- ตั้งค่าผิดรูปแบบ: ตกลงมาที่ 24 ชม. ดีกว่าปล่อยให้ expires_at เป็น nil แล้วลงขายไม่ได้ทั้งระบบ
    return 24, '24 ชั่วโมง'
end

-- ลิสต์ที่แปลงแล้วสำหรับส่งเข้า NUI: { { hours = 168, label = '7 วัน' }, ... }
function GetDurationChoices()
    local choices = {}
    for i, option in ipairs(Config.DurationOptions) do
        local hours, label = ResolveDuration(option)
        choices[i] = { hours = hours, label = label }
    end
    return choices
end
