Config = {}

-- กำหนดหมวดหมู่ของสินค้า (Define product categories)
Config.Items = {
    -- ============================================================
    -- ตลาดกลาง/ทุกเมือง : รับซื้อทุกอย่างเหมือนกันหมด
    -- ราคา : Max = ราคาขายในตารางงานฟาร์ม, Min = floor(0.7 x Max)
    -- ค่า default : RandomWhenStart=true, RangeChange={1,2}, AmountToChange=500
    -- ============================================================
    ['market'] = {
        -- ---------- พืชไร่ (5/ชิ้น) ----------
        ['job_corn']          = { Label = 'ข้าวโพด',       Min = 3,  Max = 5,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['job_carrot']        = { Label = 'แครอท',         Min = 3,  Max = 5,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['job_Yarrow']        = { Label = 'ยาร์โรว์',      Min = 3,  Max = 5,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['job_sugarcane']     = { Label = 'อ้อย',          Min = 3,  Max = 5,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['job_mushroom']      = { Label = 'เห็ดป่า',       Min = 3,  Max = 5,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['job_Ginseng']       = { Label = 'โสม',           Min = 3,  Max = 5,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['job_opium']         = { Label = 'ฝิ่น',          Min = 3,  Max = 5,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['job_berry']         = { Label = 'เบอรี่',        Min = 3,  Max = 5,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['job_tobacco_plant'] = { Label = 'ต้นยาสูบ',      Min = 3,  Max = 5,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['job_barley']        = { Label = 'ข้าวบาร์เลย์',  Min = 3,  Max = 5,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['job_cotton']        = { Label = 'ฝ้าย',          Min = 3,  Max = 5,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['job_orange']        = { Label = 'ส้ม',           Min = 3,  Max = 5,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },

        -- ---------- แร่ ----------
        ['mat_diamond']       = { Label = 'เพชร',          Min = 12, Max = 18, RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['mat_ruby']          = { Label = 'ทับทิม',        Min = 12, Max = 18, RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['mat_emerald']       = { Label = 'มรกต',          Min = 12, Max = 18, RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['mat_iron']          = { Label = 'เหล็ก',         Min = 9,  Max = 14, RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['mat_copper']        = { Label = 'ทองแดง',        Min = 7,  Max = 10, RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['mat_coal']          = { Label = 'ถ่านหิน',       Min = 4,  Max = 7,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['mat_nitrate']       = { Label = 'ไนเตรท',        Min = 4,  Max = 7,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['mat_sulfur']        = { Label = 'ซัลเฟอร์',      Min = 4,  Max = 7,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['mat_stone']         = { Label = 'หิน',           Min = 3,  Max = 5,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },

        -- ---------- ไม้ / แปรรูปไม้ ----------
        ['met_log']           = { Label = 'ท่อนไม้',       Min = 4,  Max = 7,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['met_stick']         = { Label = 'กิ่งไม้',       Min = 3,  Max = 5,  RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['met_wood_planks']   = { Label = 'ไม้แผ่น',       Min = 9,  Max = 13, RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['met_bark']          = { Label = 'เปลือกไม้',     Min = 7,  Max = 10, RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
        ['met_resin']         = { Label = 'ยางไม้',        Min = 9,  Max = 13, RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },

        -- ---------- เนื้อ ----------
        ['meat_large']        = { Label = 'เนื้อใหญ่',     Min = 7,  Max = 10, RandomWhenStart = true, RangeChange = {1, 2}, AmountToChange = 500 },
    },

    -- ============================================================
    -- ของเดิม (คอมเมนต์ไว้ตามที่ตกลง)
    -- ============================================================
    -- ['normal'] = {  -- สินค้าทั่วไป (General goods)
    --     ['wood'] = { Label = 'ไม้เนื้อแข็ง', Min = 40, Max = 60, RandomWhenStart = true, RangeChange = {1, 4}, AmountToChange = 20 },
    --     ['water'] = { Label = 'ขวดน้ำ', Min = 60, Max = 110, RandomWhenStart = true, RangeChange = {1, 4}, AmountToChange = 20 },
    --     ['sugarcane_seeds'] = { Label = 'เมล็ดอ้อย', Min = 40, Max = 60, RandomWhenStart = true, RangeChange = {1, 4}, AmountToChange = 20 },
    --     ['silver_scrap'] = { Label = 'เศษแร่เงิน', Min = 20, Max = 40, RandomWhenStart = true, RangeChange = {1, 4}, AmountToChange = 20 },
    --     ['potato'] = { Label = 'มันฝรั่ง', Min = 20, Max = 40, RandomWhenStart = true, RangeChange = {1, 4}, AmountToChange = 20 },
    --     ['iron_ore'] = { Label = 'แร่เหล็ก', Min = 30, Max = 50, RandomWhenStart = true, RangeChange = {2, 5}, AmountToChange = 1500 },
    --     ['copper_ore'] = { Label = 'แร่ทองแดง', Min = 30, Max = 50, RandomWhenStart = true, RangeChange = {2, 5}, AmountToChange = 1500 },
    --     ['gold_ore'] = { Label = 'แร่ทองคำ', Min = 10, Max = 30, RandomWhenStart = true, RangeChange = {1, 3}, AmountToChange = 1000 },
    --     ['wheat'] = { Label = 'ข้าวสาลี', Min = 50, Max = 80, RandomWhenStart = true, RangeChange = {1, 6}, AmountToChange = 1800 },
    --     ['cotton'] = { Label = 'ฝ้าย', Min = 30, Max = 50, RandomWhenStart = true, RangeChange = {2, 5}, AmountToChange = 1600 },
    --     ['resource_heart_chicken'] = { Label = 'เนื้อไก่', Min = 40, Max = 70, RandomWhenStart = true, RangeChange = {2, 7}, AmountToChange = 1700 },
    --     ['leather'] = { Label = 'หนังสัตว์', Min = 25, Max = 45, RandomWhenStart = true, RangeChange = {2, 6}, AmountToChange = 1500 },
    --     ['fish'] = { Label = 'ปลา', Min = 15, Max = 30, RandomWhenStart = true, RangeChange = {1, 3}, AmountToChange = 1200 },
    --     ['coal'] = { Label = 'ถ่านหิน', Min = 50, Max = 80, RandomWhenStart = true, RangeChange = {2, 6}, AmountToChange = 1500 },
    --     ['large_meat'] = { Label = 'เนื้อยักษ์', Min = 50, Max = 80, RandomWhenStart = true, RangeChange = {2, 6}, AmountToChange = 1500 },
    -- },
    -- ['oil'] = {  -- สินค้าน้ำมัน (Oil-related products)
    --     ['oil'] = { Label = 'น้ำมันดิบ', Min = 100, Max = 500, RandomWhenStart = true, RangeChange = {5, 15}, AmountToChange = 1000 }
    -- }
}

Config.Locations = {
    -- ================= ตลาดกลาง (Emerald Ranch) =================
    -- {
    --     Blip = {
    --         Enable = true,
    --         Sprite = -1656531561,
    --         Color = 8,
    --         Scale = 0.25,
    --         Label = 'ตลาดกลาง'
    --     },
    --     Coords = vector4(1421.9254, 356.3162, 88.8898, 306.9405),
    --     NPCModel = 'A_M_M_BiVWorker_01',
    --     NPCHeading = 306.9405,
    --     NPCText = 'ตลาดกลาง',
    --     Items = Config.Items['market']
    -- },

    -- ================= ตลาด Valentine =================
    {
        Blip = {
            Enable = true,
            Sprite = 1838354131, -- blip_ambient_loan_shark
            Color = 8,
            Scale = 0.25,
            Label = 'ตลาด Valentine'
        },
        Coords = vector4(-177.82354736328125, 647.0216064453125, 113.5841064453125, 70.6711),
        NPCModel = 'A_M_M_BiVWorker_01',
        NPCHeading = 70.6711,
        NPCText = 'ตลาด Valentine',
        Items = Config.Items['market']
    },

    -- ================= ตลาด Rhodes =================
    {
        Blip = {
            Enable = true,
            Sprite = 1838354131, -- blip_ambient_loan_shark
            Color = 8,
            Scale = 0.25,
            Label = 'ตลาด Rhodes'
        },
        Coords = vector4(1230.1090, -1279.5339, 76.0215, 320.6857),
        NPCModel = 'A_M_M_BiVWorker_01',
        NPCHeading = 320.6857,
        NPCText = 'ตลาด Rhodes',
        Items = Config.Items['market']
    },

    -- ================= ตลาด Annesburg =================
    {
        Blip = {
            Enable = true,
            Sprite = 1838354131, -- blip_ambient_loan_shark
            Color = 8,
            Scale = 0.25,
            Label = 'ตลาด Annesburg'
        },
        Coords = vector4(2932.4133, 1301.7303, 44.4802, 245.1862),
        NPCModel = 'A_M_M_BiVWorker_01',
        NPCHeading = 245.1862,
        NPCText = 'ตลาด Annesburg',
        Items = Config.Items['market']
    }

    -- ================= ของเดิม (คอมเมนต์ไว้) =================
    -- ,{
    --     Blip = { Enable = true, Sprite = -1656531561, Color = 8, Scale = 0.25, Label = 'Economy' },
    --     Coords = vector4(-369.36, 738.4, 116.4, 8.6),
    --     NPCModel = 'A_M_M_BiVWorker_01',
    --     NPCHeading = 337.24,
    --     NPCText = 'Central Seller',
    --     Items = Config.Items['normal']
    -- },
    -- {
    --     Blip = { Enable = true, Sprite = -1656531561, Color = 8, Scale = 0.25, Label = 'Oil Economy' },
    --     Coords = vector3(-369.28, 734.48, 116.6),
    --     NPCModel = 'A_M_M_BiVWorker_01',
    --     NPCHeading = 329.18,
    --     NPCText = 'Oil Seller',
    --     Items = Config.Items['oil']
    -- }
}
