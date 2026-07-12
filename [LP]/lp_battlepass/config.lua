-- lp_battlepass / config.lua  (shared)
-- Battle Pass 30 เลเวล 2 track (Standard/Premium) — EXP จากเควสรายวัน (hook lp_daliyquest ทีหลัง)
-- + ไอเทมเพิ่ม EXP/เลเวล + คำสั่งแอดมิน  |  Premium ปลดล็อกด้วยการถือ vip_card
--
-- ⚠ ความปลอดภัย: ค่าใน config นี้เป็น "ข้อมูลรางวัล" ที่ server ใช้ตัดสินเท่านั้น
--   client ไม่เคยส่ง level/xp/amount — server lookup จากตารางนี้ฝั่งเดียว ห้ามใส่ secret
-- ชื่อไอเทมยืนยันตรงจาก DB จริง (mjdevcore_18k.items)

Config = {}

Config.Debug = false                 -- true = debug print (gate ทุก print ด้วยตัวนี้)

-- ── Progression ────────────────────────────────────────────────────────────
Config.MaxLevel       = 30            -- จำนวนเลเวลใน pass
Config.XpPerLevel     = 100           -- EXP ต่อ 1 เลเวล
Config.DailyXpCap     = 300           -- เพดาน EXP/วัน จากเควส (= 3 เลเวล/วัน); item/admin ไม่นับ cap

-- ── การเปิด UI ─────────────────────────────────────────────────────────────
-- RegisterKeyMapping ไม่รองรับใน RedM → เปิดด้วยคำสั่ง + เชื่อม lp_allmenu หมวด battlepass
Config.Command = 'battlepass'

-- ── Premium gating (ถือไอเทมในกระเป๋า แบบ lp_welfarelogin) ─────────────────
Config.VIP = { items = { 'vip_card' } }   -- มีไอเทมใดไอเทมหนึ่ง (count>0) = ปลดล็อก Premium

-- ── ไอเทมเพิ่ม EXP / เลเวล โดยตรง (ใช้ผ่าน RegisterUsableItem; ไม่นับ DailyXpCap) ──
-- หมายเหตุ: ถ้าไอเทมเหล่านี้ยังไม่มีใน DB handler จะไม่ถูกเรียก (ไม่ error) — สร้าง item เพิ่มได้ทีหลัง
Config.XpUpItem = {
    { item = 'xp10',  xp = 10 },
    { item = 'xp20',  xp = 20 },
    { item = 'xp50',  xp = 50 },
    { item = 'xp100', xp = 100 },
    { item = 'xp150', xp = 150 },
}
Config.LevelUpItem = {
    { item = 'up1level',  level = 1 },
    { item = 'up2level',  level = 2 },
    { item = 'up5level',  level = 5 },
    { item = 'up10level', level = 10 },
    { item = 'up15level', level = 15 },
}

-- ── กลุ่มที่ใช้คำสั่งแอดมิน /addbp /removebp ได้ (เช็ค character.group ฝั่ง server) ──
Config.AdminGroups = { 'admin', 'superadmin' }

-- ── รูปแบบ reward ──────────────────────────────────────────────────────────
--   { title=, type='item',     item=, amount=, desc= }
--   { title=, type='currency', currency='money'|'gold'|'rol', amount=, desc= }
-- index ของตาราง = เลเวล (1..30)

-- ── Standard track (แถวปกติ) ───────────────────────────────────────────────
Config.LevelRewards = {
    { title='ตุ๋นซี่โครง',   type='item', item='food_braised_ribs',   amount=5,  desc='x5'  },
    { title='น้ำส้ม',        type='item', item='food_orange_juice',   amount=10, desc='x10' },
    { title='เนื้อย่างสมุนไพร', type='item', item='food_herb_roasted_meat', amount=5, desc='x5' },
    { title='Gun Oil',       type='item', item='oil_gun',             amount=1,  desc='x1'  },
    { title='ผ้าพันแผลใหญ่', type='item', item='bandage_xl',          amount=5,  desc='x5'  },
    { title='ยารักษาม้า',    type='item', item='hr_medicine',         amount=3,  desc='x3'  },
    { title='ยาชูกำลัง',     type='item', item='stamina',             amount=2,  desc='x2'  },
    { title='Lock pick',     type='item', item='lockpick',            amount=2,  desc='x2'  },
    { title='มรกต',          type='item', item='mat_emerald',         amount=2,  desc='x2'  },
    { title='ยาแก้ปวด',      type='item', item='painkiller',          amount=2,  desc='x2'  },
    { title='กล่องเครื่องมือ', type='item', item='misc_toolbox',       amount=1,  desc='x1'  },
    { title='เพชร',          type='item', item='mat_diamond',         amount=2,  desc='x2'  },
    { title='แผ่นไม้',       type='item', item='met_wood_planks',     amount=5,  desc='x5'  },
    { title='กล่องชุบเพื่อน', type='item', item='aed',                amount=1,  desc='x1'  },
    { title='Blueprint Low', type='item', item='blueprint_low',       amount=1,  desc='x1'  },
    { title='ทับทิม',        type='item', item='mat_ruby',            amount=2,  desc='x2'  },
    { title='เหล็ก',         type='item', item='mat_iron',            amount=5,  desc='x5'  },
    { title='ระเบิดลากสาย',  type='item', item='misc_trainbomb',      amount=1,  desc='x1'  },
    { title='พลั่วหลุมศพ',   type='item', item='tool_grave_shovel',   amount=2,  desc='x2'  },
    { title='ระเบิดลูกเล็ก', type='item', item='small_bomb',          amount=1,  desc='x1'  },
    { title='สมุดคัมภีร์',   type='item', item='bonus_gun5',          amount=1,  desc='x1'  },
    { title='Gun Oil',       type='item', item='oil_gun',             amount=3,  desc='x3'  },
    { title='Lock pick',     type='item', item='lockpick',            amount=3,  desc='x3'  },
    { title='พลั่วหลุมศพ',   type='item', item='tool_grave_shovel',   amount=3,  desc='x3'  },
    { title='ยาแก้ปวด',      type='item', item='painkiller',          amount=5,  desc='x5'  },
    { title='ยาชูกำลัง',     type='item', item='stamina',             amount=5,  desc='x5'  },
    { title='ทับทิม',        type='item', item='mat_ruby',            amount=5,  desc='x5'  },
    { title='เพชร',          type='item', item='mat_diamond',         amount=5,  desc='x5'  },
    { title='มรกต',          type='item', item='mat_emerald',         amount=5,  desc='x5'  },
    { title='กล่องชุบเพื่อน', type='item', item='aed',                amount=1,  desc='x1'  },
}

-- ── Premium track (แถวทอง — ต้องถือ vip_card) ──────────────────────────────
Config.LevelRewardsVIP = {
    { title='ซุปหางวัว',     type='item', item='food_oxtail_soup',    amount=10, desc='x10' },
    { title='นํ้าเบอรี่',    type='item', item='food_berry_juice',    amount=15, desc='x15' },
    { title='สตูเนื้อ',      type='item', item='food_beef_stew',      amount=10, desc='x10' },
    { title='ผ้าพันแผลใหญ่', type='item', item='bandage_xl',          amount=10, desc='x10' },
    { title='ยารักษาม้า',    type='item', item='hr_medicine',         amount=5,  desc='x5'  },
    { title='Lock pick',     type='item', item='lockpick',            amount=5,  desc='x5'  },
    { title='Gun Oil',       type='item', item='oil_gun',             amount=5,  desc='x5'  },
    { title='ยาชูกำลัง',     type='item', item='stamina',             amount=5,  desc='x5'  },
    { title='กล่องเครื่องมือ', type='item', item='misc_toolbox',       amount=1,  desc='x1'  },
    { title='แผ่นไม้',       type='item', item='met_wood_planks',     amount=10, desc='x10' },
    { title='เพชร',          type='item', item='mat_diamond',         amount=5,  desc='x5'  },
    { title='กล่องชุบเพื่อน', type='item', item='aed',                amount=1,  desc='x1'  },
    { title='มรกต',          type='item', item='mat_emerald',         amount=5,  desc='x5'  },
    { title='เหล็ก',         type='item', item='mat_iron',            amount=15, desc='x15' },
    { title='ทับทิม',        type='item', item='mat_ruby',            amount=5,  desc='x5'  },
    { title='พลั่วหลุมศพ',   type='item', item='tool_grave_shovel',   amount=5,  desc='x5'  },
    { title='Blueprint Low', type='item', item='blueprint_low',       amount=1,  desc='x1'  },
    { title='ระเบิดลูกเล็ก', type='item', item='small_bomb',          amount=2,  desc='x2'  },
    { title='ระเบิดลากสาย',  type='item', item='misc_trainbomb',      amount=2,  desc='x2'  },
    { title='Gun Oil',       type='item', item='oil_gun',             amount=8,  desc='x8'  },
    { title='ยาแก้ปวด',      type='item', item='painkiller',          amount=10, desc='x10' },
    { title='Blueprint Low', type='item', item='blueprint_low',       amount=1,  desc='x1'  },
    { title='สมุดคัมภีร์',   type='item', item='bonus_gun5',          amount=1,  desc='x1'  },
    { title='ยาชูกำลัง',     type='item', item='stamina',             amount=10, desc='x10' },
    { title='กล่องเครื่องมือ', type='item', item='misc_toolbox',       amount=2,  desc='x2'  },
    { title='กล่องชุบเพื่อน', type='item', item='aed',                amount=2,  desc='x2'  },
    { title='ไม้กางเขนทอง',  type='item', item='bonus_gun10',         amount=1,  desc='x1'  },
    { title='Blueprint Low', type='item', item='blueprint_low',       amount=2,  desc='x2'  },
    { title='สมุดคัมภีร์',   type='item', item='bonus_gun5',          amount=1,  desc='x1'  },
    { title='กระเป๋าแมวสีดำ', type='item', item='black_cat_bag',       amount=1,  desc='x1'  },
}

Config.Locale = {
    levelUp       = 'เลื่อนเลเวล Battle Pass',
    claimSuccess  = 'รับรางวัลสำเร็จ',
    claimAlready  = 'รับรางวัลนี้ไปแล้ว',
    notReached    = 'ยังไปไม่ถึงเลเวลนี้',
    notVip        = 'ต้องมี vip_card จึงจะรับรางวัล Premium ได้',
    weaponDupe    = 'คุณมีอาวุธนี้อยู่แล้ว',
    dailyCapped   = 'วันนี้ได้ EXP จากเควสครบเพดานแล้ว',
    notOnline     = 'ผู้เล่นไม่ออนไลน์',
    adminOnly     = 'เฉพาะแอดมิน',
}
