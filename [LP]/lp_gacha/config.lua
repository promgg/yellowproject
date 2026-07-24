Config = {}

Config.Debug = false -- true = พิมพ์ debug log (ต้อง gate ทุก print ด้วยตัวนี้)

-- Discord log การแจกรางวัล (กันโกง/ตรวจย้อนหลัง). ตั้งจริงผ่าน convar ใน server.cfg:
--   set lp_gacha_discord_webhook "https://discord.com/api/webhooks/..."
Config.Discord = {
    Enable  = true,
    Webhook = GetConvar('lp_gacha_discord_webhook', ''),
}

Config.QtyMax        = 100  -- เพดานจำนวนต่อการเปิด 1 ครั้ง (เพดานจริงยังถูกจำกัดด้วยจำนวนตั๋วที่ถืออยู่อีกชั้น)
Config.SpinCooldown  = 2000 -- ms เว้นระยะระหว่างการกดสปินแต่ละ batch ต่อผู้เล่น (กันสแปม)
Config.HorseStable   = 'valentine' -- คอกที่ม้ารางวัลจะเข้า (คอลัมน์ kd_horses.stable) — ต้องตรงกับ id คอกใน kd_stable

-- แจกของหลังอนิเมชันเผยผลจบ (NUI ยิง revealDone มา) กันผู้เล่นเห็นของเข้ากระเป๋าก่อนหลอดจบ
-- ค่านี้คือ "failsafe" เท่านั้น: ถ้า NUI ไม่ยิง revealDone ใน N ms (หลุด/error) server แจกเอง
-- ตั้งให้ยาวกว่าอนิเมชันที่ยาวสุด (เปิดเยอะ = การ์ดหลายใบ สุ่มเลขทีละใบ ~หลายวิ) กันแจกก่อนเผยจบ
Config.RevealFailsafeMs = 20000

-- ประกาศทั้งเซิร์ฟตอนใครสุ่มได้ของหายาก (banner บนจอทุกคน)
Config.Broadcast = {
    Enable   = true,                    -- ปิดทั้งระบบได้ที่นี่
    Rarities = { legendary = true },    -- rarity ที่จะประกาศ (เพิ่ม epic = true ได้)
    -- ข้อความ: %s ตัวแรก = ชื่อผู้เล่น, ตัวที่สอง = ชื่อรางวัล
    Message  = 'คุณ %s ได้รับ %s',
}

-- เคสสุ่มได้อาวุธแต่ถือซ้ำ/กระเป๋าเต็ม -> ชดเชยเป็นเงินแทน (ผู้เล่นต้องได้ของเสมอ)
Config.WeaponComp = {
    currency = 0,   -- 0 = เงินเขียว (money), 1 = ทอง (gold)
    default  = 500, -- ค่าชดเชยเริ่มต้นถ้าอาวุธนั้นไม่ได้ตั้งราคาไว้ด้านล่าง
    prices   = {
        -- ['weapon_melee_machete'] = 800,
    },
}

--[[ โครงสร้างรางวัล
    type: 'item' | 'money' | 'gold' | 'horse' | 'weapon'
    amount: ทำหน้าที่ 2 อย่างพร้อมกัน = น้ำหนักสุ่มภายใน tier + จำนวนที่ได้จริงเมื่อออกใบนั้น
    การสุ่ม 2 ชั้น: สุ่ม tier ตาม chance (รวมกัน 100) ก่อน แล้วสุ่มของใน tier ตามน้ำหนัก amount
    rarity: ใช้แค่ลงสีการ์ดใน UI (basic/common/uncommon/rare/epic/legendary)
    horse: ต้องมี model + gender (ชื่อม้าถูกสุ่มเป็น Paradise-<4หลัก> ตอนแจก)
]]
Config.Pools = {
    -- ===== ตั๋วกาชาโปรโมทเซิร์ฟ =====
    promo = {
        ticket = 'gacha_promo',
        label  = 'กาชาโปรโมทเซิร์ฟ',
        tiers  = {
            { chance = 50, rewards = {
                { type = 'item', item = 'food_bread',  label = 'ขนมปัง',              amount = 5, rarity = 'basic'    },
                { type = 'item', item = 'water',       label = 'น้ำดื่ม',              amount = 5, rarity = 'basic'    },
                { type = 'item', item = 'bandage_s',   label = 'ผ้าพันแผลเล็ก',        amount = 5, rarity = 'common'   },
                { type = 'item', item = 'bandage_xl',  label = 'ผ้าพันแผลใหญ่',        amount = 3, rarity = 'uncommon' },
                { type = 'item', item = 'painkiller',  label = 'ยาขวดรักษาแผลใหญ่',    amount = 3, rarity = 'uncommon' },
            }},
            { chance = 30, rewards = {
                { type = 'item', item = 'mat_diamond', label = 'เพชร',   amount = 2, rarity = 'rare' },
                { type = 'item', item = 'mat_ruby',    label = 'ทับทิม', amount = 2, rarity = 'rare' },
                { type = 'item', item = 'mat_emerald', label = 'มรกต',   amount = 2, rarity = 'rare' },
            }},
            { chance = 20, rewards = {
                { type = 'item',  item = 'aed', label = 'กล่องชุบเพื่อน', amount = 1, rarity = 'epic' },
                -- ม้า Turkoman - Gold (จาก kd_stable overwriteConfig index 8) — ดู grantReward ฝั่ง server ว่าเข้า kd_stable ถูกไหม
                { type = 'horse', item = 'a_c_horse_turkoman_gold', label = 'ม้า Turkoman - Gold', model = 'a_c_horse_turkoman_gold', gender = 'male', speed = 7, acceleration = 6, handling = 2, amount = 1, rarity = 'legendary' },
            }},
        },
    },

    -- ===== สุ่มม้า (ใช้ทอง จากการเติมเงินเพื่อสุ่ม) =====
    support = {
        ticket = 'gacha_support',
        label  = 'สุ่มม้า',
        tiers  = {
            { chance = 50, rewards = {
                { type = 'item', item = 'food_bread',        label = 'ขนมปัง',           amount = 5, rarity = 'basic'    },
                { type = 'item', item = 'food_oxtail_soup',  label = 'ซุปหางวัว',         amount = 5, rarity = 'basic'    },
                { type = 'item', item = 'food_orange_juice', label = 'น้ำส้ม',            amount = 5, rarity = 'basic'    },
                { type = 'item', item = 'gun_oil',           label = 'น้ำมันขัดปืน',      amount = 5, rarity = 'common'   },
                { type = 'item', item = 'cigar',             label = 'ซิการ์',            amount = 5, rarity = 'common'   },
                { type = 'item', item = 'water',             label = 'น้ำดื่ม',           amount = 5, rarity = 'basic'    },
                { type = 'item', item = 'bandage_s',         label = 'ผ้าพันแผลเล็ก',     amount = 5, rarity = 'common'   },
                { type = 'item', item = 'bandage_xl',        label = 'ผ้าพันแผลใหญ่',     amount = 5, rarity = 'common'   },
                { type = 'item', item = 'painkiller',        label = 'ยาขวดรักษาแผลใหญ่', amount = 5, rarity = 'uncommon' },
            }},
            { chance = 30, rewards = {
                { type = 'item', item = 'mat_diamond', label = 'เพชร',   amount = 2, rarity = 'rare' },
                { type = 'item', item = 'mat_ruby',    label = 'ทับทิม', amount = 2, rarity = 'rare' },
                { type = 'item', item = 'mat_emerald', label = 'มรกต',   amount = 2, rarity = 'rare' },
            }},
            { chance = 20, rewards = {
                { type = 'item',  item = 'aed',        label = 'กล่องชุบเพื่อน',           amount = 1, rarity = 'epic'      },
                { type = 'item',  item = 'bonus_gun5',  label = 'สมุดคัมภีร์ (+5% ตีปืน)',   amount = 1, rarity = 'legendary' },
                { type = 'item',  item = 'bonus_gun10', label = 'ม้ากางเขนทอง (+10% ตีปืน)', amount = 1, rarity = 'legendary' },
                -- ม้ากาชา 6 ตัว (จาก kd_stable overwriteConfig index 10-15) — แต่ละตัว weight เท่ากัน
                { type = 'horse', item = 'a_c_horse_americanpaint_greyovero', label = 'ม้า American Paint - Grey Overo', model = 'a_c_horse_americanpaint_greyovero', gender = 'male', speed = 6, acceleration = 7, handling = 2, amount = 1, rarity = 'legendary' },
                { type = 'horse', item = 'a_c_horse_andalusian_perlino',      label = 'ม้า Andalusian - Perlino',        model = 'a_c_horse_andalusian_perlino',      gender = 'male', speed = 6, acceleration = 6, handling = 2, amount = 1, rarity = 'legendary' },
                { type = 'horse', item = 'a_c_horse_appaloosa_leopard',       label = 'ม้า Appaloosa - Leopard',         model = 'a_c_horse_appaloosa_leopard',       gender = 'male', speed = 6, acceleration = 7, handling = 2, amount = 1, rarity = 'legendary' },
                { type = 'horse', item = 'a_c_horse_belgian_blondchestnut',   label = 'ม้า Belgian Draft - Blond Chestnut', model = 'a_c_horse_belgian_blondchestnut', gender = 'male', speed = 6, acceleration = 6, handling = 2, amount = 1, rarity = 'legendary' },
                { type = 'horse', item = 'a_c_horse_breton_steelgrey',        label = 'ม้า Breton - Steel Grey',         model = 'a_c_horse_breton_steelgrey',        gender = 'male', speed = 6, acceleration = 6, handling = 2, amount = 1, rarity = 'legendary' },
                { type = 'horse', item = 'a_c_horse_kentuckysaddle_black',    label = 'ม้า Kentucky Saddler - Black',    model = 'a_c_horse_kentuckysaddle_black',    gender = 'male', speed = 6, acceleration = 7, handling = 2, amount = 1, rarity = 'legendary' },
            }},
        },
    },
}
