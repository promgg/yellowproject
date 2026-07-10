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
    -- ===== กาชาโปรโมทเซิร์ฟ =====
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
                { type = 'item', item = 'aed',         label = 'กล่องชุบเพื่อน', amount = 1, rarity = 'epic' },
            }},
            { chance = 20, rewards = {
                { type = 'horse', item = 'a_c_horse_suffolkpunch_sorrel', label = 'ม้า Suffolk Punch', model = 'a_c_horse_suffolkpunch_sorrel', gender = 'male', amount = 1, rarity = 'legendary' },
            }},
        },
    },

    -- ===== กาชาสนับสนุน =====
    support = {
        ticket = 'gacha_support',
        label  = 'กาชาสนับสนุน',
        tiers  = {
            { chance = 50, rewards = {
                { type = 'item', item = 'food_bread',  label = 'ขนมปัง',           amount = 5, rarity = 'basic'    },
                { type = 'item', item = 'water',       label = 'น้ำดื่ม',           amount = 5, rarity = 'basic'    },
                { type = 'item', item = 'bandage_s',   label = 'ผ้าพันแผลเล็ก',     amount = 5, rarity = 'common'   },
                { type = 'item', item = 'bandage_xl',  label = 'ผ้าพันแผลใหญ่',     amount = 5, rarity = 'common'   },
                { type = 'item', item = 'painkiller',  label = 'ยาขวดรักษาแผลใหญ่', amount = 5, rarity = 'uncommon' },
            }},
            { chance = 30, rewards = {
                { type = 'item', item = 'mat_diamond', label = 'เพชร',   amount = 2, rarity = 'rare' },
                { type = 'item', item = 'mat_ruby',    label = 'ทับทิม', amount = 2, rarity = 'rare' },
                { type = 'item', item = 'mat_emerald', label = 'มรกต',   amount = 2, rarity = 'rare' },
                { type = 'item', item = 'aed',         label = 'กล่องชุบเพื่อน', amount = 1, rarity = 'epic' },
            }},
            { chance = 20, rewards = {
                { type = 'item',  item = 'buff_book_marksman', label = 'สมุดคัมภีร์ (+5% ตีปืน)',   amount = 1, rarity = 'legendary' },
                { type = 'item',  item = 'buff_cross_gold',    label = 'ไม้กางเขนทอง (+10% ตีปืน)', amount = 1, rarity = 'legendary' },
                { type = 'horse', item = 'a_c_horse_arabian_white', label = 'ม้า Arabian White', model = 'a_c_horse_arabian_white', gender = 'male', amount = 1, rarity = 'legendary' },
            }},
        },
    },
}
