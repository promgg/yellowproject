------------------------------------------------------------------------------------------------------------------------------
-- lp_hunting — ชำแหละซากสัตว์ (skinning)
--
-- Config นี้เป็น shared_script: client อ่านเพื่อรู้ว่า ped ตัวไหนชำแหละได้ (โชว์ปุ่ม E)
-- server อ่านเพื่อตรวจสอบ+ตัดสินไอเทม/XP เอง — ไม่มีข้อมูลลับ ปลอดภัยที่จะให้ client เห็น
--
-- flow: เข้าใกล้ซากตายแล้ว -> [E] ค้าง (lp_textui) -> TASK_LOOT_ENTITY (เกมเล่นท่าถลกจริง)
-- -> ดัก EVENT_LOOT_COMPLETE -> ลบ prop หนัง -> ส่ง netId ให้ server ตรวจ+ตัดสินรางวัลเอง
-- (client ไม่มีสิทธิ์บอกไอเทม/จำนวน/tier — server lookup เองทั้งหมด)
------------------------------------------------------------------------------------------------------------------------------

Config = {}

Config.Debug = false -- true = ดู log การตรวจสอบ/แจกรางวัลใน server console + client (เปิดตอนแก้ปัญหาเท่านั้น)

Config.Range      = 2.5  -- เมตร — ระยะที่โชว์ปุ่ม [E] ชำแหละ (client) และระยะที่ server ยอมรับ (ให้ใกล้เคียง native prompt)
Config.HoldMs     = 900  -- ms — เวลาที่ต้องกด E ค้างก่อนเริ่มถลก (lp_textui:TextUIHold)
Config.Xp         = 1    -- XP ที่ได้ต่อการชำแหละ 1 ครั้ง (Character.addXp)
Config.RateLimitMs = 3000 -- ms — server กันชำแหละถี่เกินต่อคน (ปกติแอนิเมชันเกมกินเวลามากกว่านี้อยู่แล้ว)

-- ถ้าเช็คก่อนถลกแล้วพบว่ากระเป๋าเต็ม จะไม่เริ่มแอนิเมชันถลกเลย — ซากยังอยู่ให้กลับมาถลกทีหลังได้
-- (ไม่ลบทิ้งทันทีเหมือนเดิม) แต่กันซากกองค้างแผนที่ไม่รู้จบด้วย despawn timer นี้: หลังถูก reject
-- ครั้งแรกของซากตัวนั้น ถ้ายังไม่มีใครถลกสำเร็จภายในเวลานี้ server จะลบซากทิ้งเอง
Config.AbandonedCarcassDespawnMs = 5 * 60 * 1000 -- 5 นาที

-- รายชื่อมีดที่ใช้ชำแหละได้ — ต้อง "ถืออยู่ในมือ" ตอนกดถึงจะผ่าน (client เช็คด้วย GetCurrentPedWeapon)
-- รายชื่อตรงกับ noSerialNumber knife list ใน
-- [VORP]/vorp_inventory/config/config.lua (มีดทุกแบบไม่มี serial number)
Config.KnifeWeapons = {
    'WEAPON_MELEE_KNIFE', 'WEAPON_MELEE_KNIFE_JAWBONE', 'WEAPON_MELEE_KNIFE_TRADER',
    'WEAPON_MELEE_KNIFE_CIVIL_WAR', 'WEAPON_MELEE_KNIFE_HORROR', 'WEAPON_MELEE_KNIFE_MINER',
    'WEAPON_MELEE_KNIFE_RUSTIC', 'WEAPON_MELEE_KNIFE_VAMPIRE',
}
-- ต้อง "ถือมีดอยู่ในมือ" ตอนกดชำแหละ ไม่ใช่แค่มีในกระเป๋า — ระบบจะไม่หยิบมีดให้อัตโนมัติแล้ว
-- (เดิมเรียก vorp_inventory:useWeapon() สวมให้เอง ตอนนี้เอาออก ผู้เล่นต้องหยิบเอง)
Config.RequireKnifeMsg = 'คุณไม่มีมีดที่จะใช้แล่'

-- ห้ามชำแหละถ้าซากอยู่ในเขตเมืองของ nx_cityselect (Config.Cities[i].zones/minZ/maxZ ของรีซอร์สนั้น)
-- ใช้ exports.nx_cityselect:GetCityAtCoords() ตัดสินฝั่ง server เสมอ (ไม่เชื่อ client) — ปิดเช็คนี้ได้
-- ด้วยการตั้ง false เฉยๆ ถ้าไม่ต้องการ, หรือถ้า nx_cityselect ไม่ได้ ensure ไว้ระบบจะ fail-open (อนุญาตให้
-- ชำแหละตามปกติ ไม่บล็อคทั้งระบบเพราะ resource อื่นมีปัญหา) แต่จะ dbg แจ้งเตือนไว้
Config.BlockInCityZones = true
Config.CityZoneBlockedMsg = 'ห้ามชำแหละสัตว์ในเขตเมือง'

-- โซนห้ามชำแหละเพิ่มเติม อิสระจาก nx_cityselect ทั้งหมด (ไม่ผ่าน export ของ nx_cityselect เลย —
-- ตามที่สั่ง: ไม่ต้องเพิ่มเป็นเมืองใน nx_cityselect, บล็อคตรงนี้ในตัว lp_hunting เอง) เดินวัดพิกัดมุม
-- จริงในเกม (points เรียงตามลำดับที่เดินได้), minZ/maxZ กันชั้นบน/ล่างของพื้นที่ (ประมาณจาก z จริงที่วัดได้
-- ~93-94.5 บวก buffer กันตึก/เนิน — ปรับได้ถ้ายังหลุดโซน)
Config.ExtraBlockedZones = {
    {
        id     = 'emerald_ranch',
        label  = 'Emerald Ranch',
        points = {
            { x = 1535.2341, y = 457.5506 },
            { x = 1325.4066, y = 442.0233 },
            { x = 1352.3242, y = 224.7928 },
            { x = 1444.0068, y = 209.5100 },
        },
        minZ = 80.0,
        maxZ = 140.0,
    },
}

------------------------------------------------------------------------------------------------------------------------------
-- ไอเทมรางวัล — เปลี่ยนจากโครงเดิม (meat/hide คงที่ 1:1 ต่อสัตว์) มาเป็นระบบกลุ่ม + สุ่ม
------------------------------------------------------------------------------------------------------------------------------
-- ── ของที่ได้ต่อกลุ่มสัตว์ ────────────────────────────────────────────────────
-- ทุก entry ใน Config.SkinTiers มี key `group` ชี้มาที่ตารางนี้ (ไม่มี group = ใช้ 'other')
--
-- always  = ได้แน่นอนทุกครั้ง
-- pickOne = สุ่มเลือกมา 1 อย่างจากลิสต์ (ได้ 1 ชิ้นเสมอ)
-- rolls   = สุ่มทีละอย่างแยกกันอิสระ ตาม chance (%) — ได้หลายอย่างพร้อมกันได้ หรือไม่ได้เลยก็ได้
--
-- หมี: ทั้ง 3 อย่างสุ่ม 50% แยกกัน (มีโอกาสได้ครบทั้ง 3 = 12.5% และมีโอกาสไม่ได้อะไรเลย = 12.5%)
-- หนังออกแค่ 3 กลุ่มนี้เท่านั้น (หมาป่า/เสือ/หมี) สัตว์อื่นไม่มีหนังเลย
Config.GroupLoot = {
    bear = {
        rolls = {
            { item = 'meat_large', chance = 50 },
            { item = 'hide_high',  chance = 50 },
            { item = 'bear_claw',  chance = 50 },
        },
    },
    tiger = {
        always = { 'meat_medium' },
        rolls  = { { item = 'hide_medium', chance = 50 } },
    },
    wolf = {
        pickOne = { 'meat_small', 'meat_medium' },
        rolls   = { { item = 'hide_low', chance = 50 } },
    },
    deer = {
        always = { 'meat_small' },
    },
    alligator = {
        always = { 'meat_medium' },
    },
    -- สัตว์ที่เหลือทั้งหมด (รวมนก ปศุสัตว์ งู ฯลฯ) — เนื้อเล็กหรือกลางอย่างใดอย่างหนึ่ง ไม่มีหนัง
    other = {
        pickOne = { 'meat_small', 'meat_medium' },
    },
}

------------------------------------------------------------------------------------------------------------------------------
-- Config.SkinTiers — ดึงมาจาก [VORP]/vorp_hunting/config.lua -> Config.SkinnableAnimals
-- เอาเฉพาะ entry ที่ action == "Skinned" (สัตว์เลี้ยงลูกด้วยนม/สัตว์เลื้อยคลานที่มีหนัง/เปลือก)
-- ตัด entry action == "Picked" ทั้งหมดออก (นก/ปลา/กระรอก/คางคก/ปู ฯลฯ ที่ "เก็บ" ไม่ใช่ "ถลก")
--
-- ตารางนี้ทำหน้าที่ 2 อย่าง: (1) whitelist ว่า ped ตัวไหน "ชำแหละได้" (client ใช้ตัดสินใจโชว์ปุ่ม E)
-- และ (2) บอกว่าสัตว์ตัวนั้นอยู่กลุ่มไหน -> ของที่ได้ดูจาก Config.GroupLoot[group]
-- ped ที่ไม่อยู่ในตารางนี้ = ชำแหละไม่ได้เลย (สำคัญ: ห้ามเปลี่ยนเป็น default 'other' ไม่งั้นคนก็ถลกได้)
--
-- กลุ่ม: bear(3) / tiger(4, = Panther+Cougar) / wolf(4) / deer(5) / alligator(5) / other(65)
------------------------------------------------------------------------------------------------------------------------------
Config.SkinTiers = {
    -- ── สัตว์เล็ก/กลาง ทั่วไป ──────────────────────────────────────────────
    [-1797625440] = { name = 'Armadillo', group = 'other' },
    [-1170118274] = { name = 'American Badger', group = 'other' },
    [1755643085] = { name = 'American Pronghorn Doe', group = 'deer' },
    [-1124266369] = { name = 'Bear', group = 'bear' },
    [-1568716381] = { name = 'Big Horn Ram', group = 'other' },
    [-1963605336] = { name = 'Buck', group = 'deer' },
    [1556473961] = { name = 'Bison', group = 'other' },
    [367637652] = { name = 'Bison', group = 'other' },
    [1957001316] = { name = 'Bull', group = 'other' },
    [1110710183] = { name = 'Deer', group = 'deer' },
    [252669332] = { name = 'American Red Fox', group = 'other' },
    [-1143398950] = { name = 'Big Grey Wolf', group = 'wolf' },
    [-885451903] = { name = 'Medium Grey Wolf', group = 'wolf' },
    [-829273561] = { name = 'Small Grey Wolf', group = 'wolf' },
    [-407730502] = { name = 'Snapping Turtle', group = 'other' },
    [-22968827] = { name = 'Water Snake', group = 'other' },
    [-229688157] = { name = 'CottonMouth Water Snake', group = 'other' },
    [-1790499186] = { name = 'Snake Red Boa', group = 'other' },
    [1464167925] = { name = 'Snake Fer-De-Lance', group = 'other' },
    [846659001] = { name = 'Black-Tailed Rattlesnake', group = 'other' },
    [545068538] = { name = 'Western Rattlesnake', group = 'other' },
    [-121266332] = { name = 'Striped Skunk', group = 'other' },
    [40345436] = { name = 'Merino Sheep', group = 'other' },
    [1458540991] = { name = 'North American Racoon', group = 'other' },
    [-541762431] = { name = 'Black-Tailed Jackrabbit', group = 'other' },
    [-1414989025] = { name = 'Virginia Possum', group = 'other' },
    [1007418994] = { name = 'Berkshire Pig', group = 'other' },
    [1654513481] = { name = 'Panther', group = 'tiger' },
    [90264823] = { name = 'Cougar', group = 'tiger' },
    [-50684386] = { name = 'Florida Cracker Cow', group = 'other' },
    [480688259] = { name = 'Coyote', group = 'other' },
    [45741642] = { name = 'Gila Monster', group = 'other' },
    [-753902995] = { name = 'Alpine Goat', group = 'other' },
    [-1854059305] = { name = 'Green Iguana', group = 'other' },
    [-593056309] = { name = 'Desert Iguana', group = 'other' },
    [1751700893] = { name = 'Peccary Pig', group = 'other' },
    [-1098441944] = { name = 'Moose', group = 'other' },
    [-1134449699] = { name = 'American Muskrat', group = 'other' },
    [556355544] = { name = 'Angus Ox', group = 'other' },
    [-1892280447] = { name = 'Alligator Small', group = 'alligator' },
    [-2004866590] = { name = 'Alligator', group = 'alligator' },
    [-1295720802] = { name = 'Northern American Alligator', group = 'alligator' },
    [759906147] = { name = 'North American Beaver', group = 'other' },
    [730092646] = { name = 'American Black Bear', group = 'bear' },
    [195700131] = { name = 'Hereford Bull', group = 'other' },

    -- ── Legendary — เข้ากลุ่มตามชนิดเหมือนสัตว์ปกติ (ไม่มีสิทธิพิเศษเรื่องหนังแล้ว) ──
    -- เช่น Legendary Owiza Bear = กลุ่ม bear, Legendary Onyx Wolf = กลุ่ม wolf, ที่เหลือเป็น other
    [-2021043433] = { name = 'Legendary White Elk', group = 'deer' },
    [-1747620994] = { name = 'Legendary Boa', group = 'other' },
    [674287411] = { name = 'Legendary Sun Alligator', group = 'alligator' },
    [-1598866821] = { name = 'Legendary Bull Alligator', group = 'alligator' },
    [-1149999295] = { name = 'Legendary White Beaver', group = 'other' },
    [2028722809] = { name = 'Legendary Giant Boar', group = 'other' },
    [-389300196] = { name = 'Legendary WakpaBoar', group = 'other' },
    [-1433814131] = { name = 'Legendary Maza Cougar', group = 'tiger' },
    [-1307757043] = { name = 'Legendary Midnight Paw Coyote', group = 'other' },
    [-1189368951] = { name = 'Legendary Ghost Panther', group = 'tiger' },
    [-1392359921] = { name = 'Legendary Onyx Wolf', group = 'wolf' },
    [-551216071] = { name = 'Legendary Owiza Bear', group = 'bear' },
    [-511163808] = { name = 'Legendary Chalk Horn Ram', group = 'other' },
    [-1754211037] = { name = 'Legendary Buck', group = 'deer' },
    [-915290938] = { name = 'Legendary Winyan Bison', group = 'other' },
    [-117665949] = { name = 'Legendary Snowflake Moose', group = 'other' },

    -- ── นก — อยู่กลุ่ม other เหมือนสัตว์ทั่วไป (สุ่มเนื้อเล็ก/กลาง ไม่มีหนัง) ────────────────
    [-1003616053] = { name = 'Duck', group = 'other' },
    [1459778951] = { name = 'Eagle', group = 'other' },
    [831859211] = { name = 'Egret', group = 'other' },
    [1104697660] = { name = 'Vulture', group = 'other' },
    [-466054788] = { name = 'Wild Turkey', group = 'other' },
    [-2011226991] = { name = 'Wild Turkey', group = 'other' },
    [-166054593] = { name = 'Wild Turkey', group = 'other' },
    [-164963696] = { name = 'Herring Seagull', group = 'other' },
    [-1076508705] = { name = 'Roseate Spoonbill', group = 'other' },
    [2023522846] = { name = 'Dominique Rooster', group = 'other' },
    [-466687768] = { name = 'Red-Footed Booby', group = 'other' },
    [-575340245] = { name = 'Western Raven', group = 'other' },
    [2079703102] = { name = 'Greater Prairie Chicken', group = 'other' },
    [1416324601] = { name = 'Ring-Necked Pheasant', group = 'other' },
    [1265966684] = { name = 'American White Pelican', group = 'other' },
    [-1797450568] = { name = 'Blue And Yellow Macaw', group = 'other' },
    [120598262] = { name = 'Californian Condor', group = 'other' },
    [-2063183075] = { name = 'Dominique Chicken', group = 'other' },
    [-2073130256] = { name = 'Double-Crested Cormorant', group = 'other' },
    [-564099192] = { name = 'Whooping Crane', group = 'other' },
    [723190474] = { name = 'Canada Goose', group = 'other' },
    [-2145890973] = { name = 'Ferruinous Hawk', group = 'other' },
    [1095117488] = { name = 'Great Blue Heron', group = 'other' },
    [386506078] = { name = 'Common Loon', group = 'other' },
    [-86244272] = { name = 'Great Horned Owl', group = 'other' },
}
