-- lp_leaderboard / config.lua
-- ระบบจัดอันดับหลายหมวด (server-authoritative) — เก็บสถิติสะสมถาวรใน DB
-- 2 บอร์ด: KILL RANK (PvP ทั้งเซิร์ฟ) + CITY RANK (ชนะไฟล์ airdrop ต่อรอบ ต่อเมือง)

Config = {}

Config.Debug = true

-- คำสั่งเปิด (RedM ไม่มี keymap — ใช้ RegisterCommand ล้วน)
Config.Command  = 'leaderboard'
Config.Aliases  = { 'rank' }

Config.TopN         = 50    -- จำนวนแถวสูงสุดที่ส่งให้ NUI ต่อบอร์ด
Config.PushInterval = 2500  -- ms — รอบ live-push ให้ผู้ที่เปิด UI ค้าง (throttle)
Config.PersistEvery = 10000 -- ms — flush แถวที่เปลี่ยนลง DB เป็นรอบ

-- กลุ่มแอดมิน (เช็คฝั่ง server เท่านั้น) — ใช้กับ /lbreset (เช็คจาก char.group ในเกม)
Config.AdminGroups = { 'admin', 'superadmin' }

-- ACE object สำหรับ /clearleaderboard (เช็คด้วย IsPlayerAceAllowed แทน group)
-- ให้สิทธิ์ใน server.cfg เช่น:  add_ace group.admin lp_leaderboard.admin allow
Config.AcePermission = 'lp_leaderboard.admin'

-- ── KILL RANK ─────────────────────────────────────────────────────────────
Config.Kill = {
    pointsPerKill = 1,     -- Score = kills * pointsPerKill
    countDeaths   = true,  -- นับ deaths ให้เหยื่อ
    ignoreSelf    = true,  -- ตายเอง/สภาพแวดล้อม (killer == เหยื่อ) ไม่นับ kill
    ignoreNpc     = true,  -- ถูก NPC/สิ่งแวดล้อมฆ่า (killerServerId=0) ไม่ให้เครดิต kill
    ignoreSameCity = true, -- ยิงคนเมืองเดียวกัน (ทีมเดียวกัน) ไม่นับทั้ง kill/score ของ killer และ death ของเหยื่อ
    -- กันปั๊ม: คู่ (killer→victim) เดิมเครดิตซ้ำได้ทุกๆ กี่วินาที (0 = ปิดการกัน)
    farmCooldown  = 90,    -- วินาที
    -- anti-spoof: event ตายถูกยิงจาก client (MJ-Respwan) — ตรวจระยะ killer↔victim ด้วยพิกัด
    -- ที่ "server รู้เอง" (GetEntityCoords) ถ้าไกลเกินนี้ถือว่าผิดปกติ/ปลอม ไม่เครดิต (0 = ปิด)
    maxKillDistance = 300, -- เมตร (เผื่อสไนเปอร์ระยะไกล)
}

-- badge ตาม Score (เลือกอันที่ min สูงสุดที่ <= score)
Config.Badges = {
    { min = 0,    name = 'BRONZE',   color = '#c78b4b' },
    { min = 50,   name = 'SILVER',   color = '#c7ccd1' },
    { min = 150,  name = 'GOLD',     color = '#f0ca78' },
    { min = 400,  name = 'PLATINUM', color = '#7fe0d4' },
    { min = 1000, name = 'DIAMOND',  color = '#8ab6ff' },
}

-- ── GATHER JOBS (FISH / MINING / PLANTING / LUMBER) ────────────────────────
-- ทุกหมวดกลุ่มนี้หน้าตาเดียวกันหมด: รับ event จาก resource งานนั้นๆ ทุกครั้งที่ทำสำเร็จ 1 ครั้ง
--   Score       = ผลรวมจำนวนไอเทมที่ได้จริงสะสม (ไม่ใช่แค่นับครั้ง)
--   count       = จำนวนครั้งที่ทำสำเร็จ (โชว์เป็นคอลัมน์ที่ 2 ใน NUI ตาม countLabel)
-- badge แยกสเกลต่อหมวด เพราะแต่ละงานได้ของเร็ว/ช้าไม่เท่ากัน — ปรับตัวเลข min ตรงนี้ได้เลย
-- ปรับ/ปิดหมวดไหนก็แก้ที่ Config.Categories ด้านล่าง (enabled) ไม่ต้องแตะโค้ด sv_main.lua

Config.FishBadges = {
    { min = 0,    name = 'BRONZE',   color = '#c78b4b' },
    { min = 100,  name = 'SILVER',   color = '#c7ccd1' },
    { min = 300,  name = 'GOLD',     color = '#f0ca78' },
    { min = 700,  name = 'PLATINUM', color = '#7fe0d4' },
    { min = 1500, name = 'DIAMOND',  color = '#8ab6ff' },
}

Config.MiningBadges = {
    { min = 0,    name = 'BRONZE',   color = '#c78b4b' },
    { min = 80,   name = 'SILVER',   color = '#c7ccd1' },
    { min = 250,  name = 'GOLD',     color = '#f0ca78' },
    { min = 600,  name = 'PLATINUM', color = '#7fe0d4' },
    { min = 1200, name = 'DIAMOND',  color = '#8ab6ff' },
}

Config.PlantingBadges = {
    { min = 0,    name = 'BRONZE',   color = '#c78b4b' },
    { min = 50,   name = 'SILVER',   color = '#c7ccd1' },
    { min = 150,  name = 'GOLD',     color = '#f0ca78' },
    { min = 400,  name = 'PLATINUM', color = '#7fe0d4' },
    { min = 1000, name = 'DIAMOND',  color = '#8ab6ff' },
}

Config.LumberBadges = {
    { min = 0,    name = 'BRONZE',   color = '#c78b4b' },
    { min = 100,  name = 'SILVER',   color = '#c7ccd1' },
    { min = 300,  name = 'GOLD',     color = '#f0ca78' },
    { min = 700,  name = 'PLATINUM', color = '#7fe0d4' },
    { min = 1500, name = 'DIAMOND',  color = '#8ab6ff' },
}

Config.HuntingBadges = {
    { min = 0,    name = 'BRONZE',   color = '#c78b4b' },
    { min = 100,  name = 'SILVER',   color = '#c7ccd1' },
    { min = 300,  name = 'GOLD',     color = '#f0ca78' },
    { min = 700,  name = 'PLATINUM', color = '#7fe0d4' },
    { min = 1500, name = 'DIAMOND',  color = '#8ab6ff' },
}

-- รวมศูนย์: หมวดไหนเป็น gather job บ้าง, ฟังก์ชัน sv_main.lua วนลูปตัวนี้ตัวเดียวสร้างทุกอย่างให้อัตโนมัติ
-- (ตาราง DB, event handler, build/badge) — เพิ่มหมวดใหม่ในอนาคต = เพิ่ม entry ที่นี่ + ต่อ event จาก
-- resource ต้นทาง แค่นั้น ไม่ต้องแก้ sv_main.lua เลย
Config.GatherJobs = {
    fish     = { event = Events.fishCatch,    table = 'lp_leaderboard_fish',     badges = Config.FishBadges,     countLabel = 'CATCHES'  },
    mining   = { event = Events.miningGather, table = 'lp_leaderboard_mining',   badges = Config.MiningBadges,   countLabel = 'DIGS'     },
    planting = { event = Events.plantHarvest, table = 'lp_leaderboard_planting', badges = Config.PlantingBadges, countLabel = 'HARVESTS' },
    lumber   = { event = Events.lumberChop,   table = 'lp_leaderboard_lumber',   badges = Config.LumberBadges,   countLabel = 'CHOPS'    },
    hunting  = { event = Events.huntSkin,     table = 'lp_leaderboard_hunting',  badges = Config.HuntingBadges,  countLabel = 'SKINS'    },
}

-- ── CITY RANK ─────────────────────────────────────────────────────────────
-- cityId มาจาก lp_airdropteam (teams[].cityId) — map เป็นชื่อโชว์ในบอร์ด
Config.CityNames = {
    valentine = 'Valentine',
    rhodes    = 'Rhodes',
    annesburg = 'Annesburg',
    saintdenis= 'Saint Denis',
    blackwater= 'Blackwater',
    strawberry= 'Strawberry',
}

-- หมวดใน tab bar (โครงรองรับเพิ่มได้ — เพิ่ม data source ฝั่ง server เอง)
-- enabled = false -> ซ่อน tab จาก NUI + หยุดรับ event สะสมคะแนนของหมวดนั้นทั้งหมด
-- (ไม่ใส่ enabled เลย = ถือว่าเปิดอยู่ ค่า default คือ true)
-- group = 'jobs' -> หมวดพวกนี้จะถูกยุบรวมเป็นแทบเดียว "JOBS" ในท็อปบาร์ แล้วมี pill ย่อยสลับข้างใน
--   (NUI จัดกลุ่มเอง; server ส่งหมวด enabled ตามเดิม แค่แนบ field group ไปด้วย)
--   แทบ JOBS โผล่เมื่อมีอาชีพ enabled อย่างน้อย 1 ตัว, pill ย่อยโชว์เฉพาะที่เปิด
Config.Categories = {
    { id = 'kill',     label = 'KILL RANK',       th = 'อันดับสังหาร',     icon = 'target',  enabled = true  },
    { id = 'city',     label = 'CITY RANK',       th = 'อันดับเมือง',       icon = 'flag',    enabled = true  },
    { id = 'fish',     label = 'FISH RANK',       th = 'อันดับตกปลา',      icon = 'fish',    enabled = true, group = 'jobs' }, -- ปิดไว้ก่อน รอทดสอบในเซิร์ฟจริง
    { id = 'mining',   label = 'MINING RANK',     th = 'อันดับขุดเหมืองทอง', icon = 'mining',  enabled = true, group = 'jobs' }, -- ปิดไว้ก่อน รอทดสอบในเซิร์ฟจริง
    { id = 'planting', label = 'FARMING RANK',    th = 'อันดับปลูกต้นไม้',   icon = 'plant',   enabled = true,  group = 'jobs' }, -- เปิดแล้ว (MJ-Planting ยิง event มาจริง)
    { id = 'lumber',   label = 'LUMBERJACK RANK', th = 'อันดับตัดไม้',      icon = 'axe',     enabled = true, group = 'jobs' }, -- ปิดไว้ก่อน รอทดสอบในเซิร์ฟจริง
    { id = 'hunting',  label = 'HUNTING RANK',    th = 'อันดับล่าสัตว์',    icon = 'skull',   enabled = true, group = 'jobs' }, -- lp_hunting — ไม่มี icon เฉพาะสัตว์/รอยเท้าใน nui, ใช้ 'skull' (มีอยู่แล้วใน IC ของ script.js) แทน
}

-- meta ของแต่ละ group (ชื่อ/ไอคอนของแทบรวมในท็อปบาร์)
Config.Groups = {
    jobs = { label = 'JOBS', th = 'อาชีพ', icon = 'briefcase' },
}

Config.Locale = {
    adminOnly   = 'เฉพาะแอดมินเท่านั้น',
    resetDone   = 'รีเซ็ตกระดานอันดับเรียบร้อย',
    notReady    = 'ระบบยังไม่พร้อม ลองใหม่อีกครั้ง',
}
