-- lp_welfarelogin / config.lua  (shared)
-- ระบบ 2 อย่างในหน้าจอเดียว:
--   1) Daily Login (30 วัน) — 2 track: Standard/ฟรี (แถวดำ) + VIP (แถวทอง) — คลิกการ์ดเพื่อเคลม
--   2) Online Reward — สะสมเวลาออนไลน์รายวัน แจกอัตโนมัติเมื่อถึง tier — รีเซ็ต 04:00
--
-- ⚠ ความปลอดภัย: ค่าใน config นี้เป็น "ข้อมูลรางวัล" ที่ server ใช้ตัดสินเท่านั้น
--   client ไม่เคยส่งจำนวน/ชนิด/ราคา — server lookup จากตารางนี้ฝั่งเดียว
--   ห้ามใส่ secret ใด ๆ ในไฟล์นี้ (ถูกโหลดฝั่ง client ด้วย)
--
-- ชื่อไอเทมยืนยันตรงจาก DB จริง (mjdevcore_18k.items) — เช็คแล้วมีครบทุกตัว

Config = {}

Config.Debug        = false               -- true = log + คำสั่ง /welfaredebug (สำหรับเทสเท่านั้น)
Config.ResourceName = 'lp_welfarelogin'

-- ── เวลา / การรีเซ็ต ───────────────────────────────────────────────────────
Config.ResetHour         = 4              -- welfare-day พลิกตอน 04:00 (daily login + online แชร์กัน)
Config.OnlineTickSeconds = 60             -- server ticker เดินทุกกี่วินาที (นับเวลา + เช็ค tier)
Config.OnlineTestSpeedup = 1              -- ตัวคูณเร่งเกณฑ์ tier ออนไลน์ (1 = ไม่เร่ง; ใช้ค่าอื่นตอนเทสเท่านั้น)
Config.AutoSaveSeconds   = 120            -- flush cache ลง DB เป็นระยะ

-- ── การเปิด UI ─────────────────────────────────────────────────────────────
-- RegisterKeyMapping ไม่รองรับใน RedM → เปิดด้วยคำสั่ง /welfare อย่างเดียว
-- และเชื่อมกับ lp_allmenu หมวด "ล็อคอิน" (login) ที่ตั้ง action = command → welfare
Config.Command   = 'welfare'
Config.AutoPopup = false                  -- เด้ง UI อัตโนมัติครั้งแรกของ welfare-day ตอน spawn (ปิดไว้)

-- ── VIP gating (เช็คจากไอเทมในกระเป๋า แบบ MJ-Respwan) ──────────────────────
-- มีไอเทมใดไอเทมหนึ่งในลิสต์ (count > 0) = เป็น VIP → เคลมแถวทองได้
-- vip_card สร้างไว้ใน DB แล้ว (mjdevcore_18k.items id=3114 label='บัตร VIP')
Config.VIP = {
    items = { 'vip_card' },
}

-- ── รูปแบบ reward ที่ใช้ได้ทุกที่ ───────────────────────────────────────────
--   { type = 'item',     name = 'food_bread', amount = 5 }
--   { type = 'currency', currency = 'money'|'gold'|'rol', amount = 300 }
-- 'img'/'title' ใช้แสดงบนการ์ดเท่านั้น (img = ชื่อไอเทมใน vorp_inventory)

-- ── Daily Login ────────────────────────────────────────────────────────────
Config.Daily = { cycleDays = 30 }

-- index = วันที่ (1..30) — Standard track (แถวฟรี)
Config.DailyFree = {
    { title = 'ขนมปัง x5',        img = 'food_bread',    rewards = { { type='item', name='food_bread',   amount=5 } } },
    { title = 'บุหรี่ x5',        img = 'cigarette',     rewards = { { type='item', name='cigarette',    amount=5 } } },
    { title = 'ยารักษาม้า x1',    img = 'hr_medicine',   rewards = { { type='item', name='hr_medicine',  amount=1 } } },
    { title = 'วิสกี้ x3',        img = 'food_vodka',    rewards = { { type='item', name='food_vodka',   amount=3 } } },
    { title = 'น้ำดื่ม x5',       img = 'water',         rewards = { { type='item', name='water',        amount=5 } } },
    { title = 'หญ้าม้า x3',       img = 'hr_grass',      rewards = { { type='item', name='hr_grass',     amount=3 } } },
    { title = 'กาแฟ x5',          img = 'food_coffee',   rewards = { { type='item', name='food_coffee',  amount=5 } } },
    { title = 'ผ้าพันแผลเล็ก x5', img = 'bandage_s',     rewards = { { type='item', name='bandage_s',    amount=5 } } },
    { title = 'Gun Oil x1',       img = 'oil_gun',       rewards = { { type='item', name='oil_gun',      amount=1 } } },
    { title = 'เงิน $300',        img = 'money',         rewards = { { type='currency', currency='money', amount=300 } } }, -- day 10
    { title = 'ขนมปัง x5',        img = 'food_bread',    rewards = { { type='item', name='food_bread',   amount=5 } } },
    { title = 'บุหรี่ x5',        img = 'cigarette',     rewards = { { type='item', name='cigarette',    amount=5 } } },
    { title = 'ยารักษาม้า x1',    img = 'hr_medicine',   rewards = { { type='item', name='hr_medicine',  amount=1 } } },
    { title = 'วิสกี้ x3',        img = 'food_vodka',    rewards = { { type='item', name='food_vodka',   amount=3 } } },
    { title = 'น้ำดื่ม x5',       img = 'water',         rewards = { { type='item', name='water',        amount=5 } } },
    { title = 'หญ้าม้า x3',       img = 'hr_grass',      rewards = { { type='item', name='hr_grass',     amount=3 } } },
    { title = 'กาแฟ x5',          img = 'food_coffee',   rewards = { { type='item', name='food_coffee',  amount=5 } } },
    { title = 'ผ้าพันแผลเล็ก x5', img = 'bandage_s',     rewards = { { type='item', name='bandage_s',    amount=5 } } },
    { title = 'Gun Oil x1',       img = 'oil_gun',       rewards = { { type='item', name='oil_gun',      amount=1 } } },
    { title = 'เงิน $400',        img = 'money',         rewards = { { type='currency', currency='money', amount=400 } } }, -- day 20
    { title = 'ผ้าพันแผลใหญ่ x3', img = 'bandage_xl',    rewards = { { type='item', name='bandage_xl',   amount=3 } } },
    { title = 'ยารักษาม้า x1',    img = 'hr_medicine',   rewards = { { type='item', name='hr_medicine',  amount=1 } } },
    { title = 'วิสกี้ x3',        img = 'food_vodka',    rewards = { { type='item', name='food_vodka',   amount=3 } } },
    { title = 'แซนวิส x5',        img = 'food_sandwich', rewards = { { type='item', name='food_sandwich',amount=5 } } },
    { title = 'ยาแก้ปวด x2',      img = 'painkiller',    rewards = { { type='item', name='painkiller',   amount=2 } } },
    { title = 'Gun Oil x1',       img = 'oil_gun',       rewards = { { type='item', name='oil_gun',      amount=1 } } },
    { title = 'หญ้าม้า x3',       img = 'hr_grass',      rewards = { { type='item', name='hr_grass',     amount=3 } } },
    { title = 'บุหรี่ x5',        img = 'cigarette',     rewards = { { type='item', name='cigarette',    amount=5 } } },
    { title = 'ยาชูกำลัง x2',     img = 'stamina',       rewards = { { type='item', name='stamina',      amount=2 } } },
    { title = 'เงิน $500',        img = 'money',         rewards = { { type='currency', currency='money', amount=500 } } }, -- day 30
}

-- VIP track (แถวทอง) — ใช้รางวัลชุดเดียวกับ Standard ไปก่อน (ตามที่ตกลง)
-- หมายเหตุ: VIP เคลมได้ทั้งแถวฟรี + แถวนี้ = ได้ 2 เท่าของ Standard ต่อวัน
-- แก้เป็นชุด VIP จริงภายหลังได้ โดยแทนบรรทัดล่างด้วยตาราง 30 ช่อง { {...}, {...}, ... }
Config.DailyVip = Config.DailyFree

-- ── Online Reward (6 tier ตรงกับ score bar) ────────────────────────────────
-- minutes = เกณฑ์เวลาออนไลน์สะสมของ welfare-day (แจกอัตโนมัติเมื่อถึง)
Config.Online = {
    { id = 1, minutes = 60,  hours = 1, title = 'พาสต้าซอส x2',   img = 'food_pasta_sauce',
      rewards = { { type='item', name='food_pasta_sauce', amount=2 } } },
    { id = 2, minutes = 120, hours = 2, title = 'ผ้าพันแผลใหญ่ x10', img = 'bandage_xl',
      rewards = { { type='item', name='bandage_xl', amount=10 } } },
    { id = 3, minutes = 180, hours = 3, title = 'พลั่วขุดหลุม x3', img = 'tool_shovel',
      rewards = { { type='item', name='tool_shovel', amount=3 } } }, -- DB: tool_shovel=พลั่วพรวนดิน (มี tool_grave_shovel=พลั่วหลุมศพ ด้วย)
    { id = 4, minutes = 240, hours = 4, title = 'ยาแก้ปวด x3',    img = 'painkiller',
      rewards = { { type='item', name='painkiller', amount=3 } } },
    { id = 5, minutes = 300, hours = 5, title = 'Gun Oil x3',     img = 'oil_gun',
      rewards = { { type='item', name='oil_gun', amount=3 } } },
    { id = 6, minutes = 360, hours = 6, title = 'ชุดใหญ่ 6 ชม.',  img = 'food_herb_roasted_meat',
      rewards = {
          { type='item',     name='food_herb_roasted_meat', amount=3 },
          { type='item',     name='food_sugarcane_juice',   amount=5 },
          { type='currency', currency='money',              amount=500 },
      } },
}
Config.OnlineMaxHours = 6                  -- ใช้คำนวณ % ของแถบ score bar (onlineHours / นี้)

-- ── ข้อความแจ้งเตือน (pNotify) ─────────────────────────────────────────────
Config.Locale = {
    claimSuccess  = 'รับรางวัลสำเร็จ',
    claimAlready  = 'รับรางวัลนี้ไปแล้ว',
    claimLocked   = 'ยังปลดล็อกวันนี้ไม่ได้',
    notVip        = 'ต้องเป็น VIP จึงจะรับรางวัลแถวทองได้',
    inventoryFull = 'พื้นที่กระเป๋าไม่พอ',
    onlineReward  = 'ได้รับรางวัลเวลาออนไลน์',
    dailyReset    = 'ระบบ Welfare รีเซ็ตประจำวันแล้ว',
}
