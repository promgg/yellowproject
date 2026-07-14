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
-- ไอเทมรางวัล — คงที่ x1 ต่อชิ้น ต่อการชำแหละ 1 ครั้ง (เนื้อ 1 + หนัง 1)
-- โครงสร้างตามที่ตกลงกัน: key เดียวกัน (small/medium/large) ใช้แทนทั้ง "แถบเนื้อ" (small/medium/large)
-- และ "แถบหนัง" (low/medium/high) แบบ 1:1 ตามตำแหน่ง (small<->low, medium<->medium, large<->high)
-- เพราะเนื้อ/หนังเป็น 2 แกนอิสระต่อกัน (ดู Config.SkinTiers) — ฝั่ง server ใช้ Config.HideRankToItemsKey
-- แปลง hide-rank (low/medium/high) กลับมาเป็น key ของตารางนี้ (small/medium/large) ก่อน lookup .hide
------------------------------------------------------------------------------------------------------------------------------
Config.Items = {
    small  = { meat = 'meat_small',  hide = 'hide_low' },
    medium = { meat = 'meat_medium', hide = 'hide_medium' },
    large  = { meat = 'meat_large',  hide = 'hide_high' },
}

-- แปลง hide-rank (low/medium/high) -> key ของ Config.Items (small/medium/large)
Config.HideRankToItemsKey = { low = 'small', medium = 'medium', high = 'large' }

------------------------------------------------------------------------------------------------------------------------------
-- Config.SkinTiers — ดึงมาจาก [VORP]/vorp_hunting/config.lua -> Config.SkinnableAnimals
-- เอาเฉพาะ entry ที่ action == "Skinned" (สัตว์เลี้ยงลูกด้วยนม/สัตว์เลื้อยคลานที่มีหนัง/เปลือก)
-- ตัด entry action == "Picked" ทั้งหมดออก (นก/ปลา/กระรอก/คางคก/ปู ฯลฯ ที่ "เก็บ" ไม่ใช่ "ถลก")
--
-- นก (Duck/Eagle/Turkey/Goose/Chicken/Vulture/...): ต้นฉบับให้ item "bird" ไม่มีหนัง —
-- ตามที่ผู้เล่นสั่ง นกให้ "เนื้ออย่างเดียว" (entry ไม่มี key `hide` → server แจกเฉพาะเนื้อ)
--
-- legendary: ทุกตัว hide = 'high' (ผู้เล่นสั่ง) ไม่ว่าจะเป็นนักล่าหรือไม่
--
-- แกนเนื้อ (ตามขนาดตัว, ดูจาก givenItem แรกที่เป็นชนิดเนื้อจริงของสัตว์ต้นฉบับ):
--   stringy/game/herptile        -> small
--   venison/pork/Mutton/wool     -> medium
--   beef/biggame/BigGameMeat/aligatormeat -> large
-- แกนหนัง (ตามความอันตราย, อิสระจากแกนเนื้อ):
--   ชื่อมี Bear/Wolf/Cougar/Panther/Alligator (รวม Legendary) -> high (นักล่า)
--   ไม่ใช่นักล่า แต่ meat = large หรือ medium (สัตว์ตัวใหญ่/ปศุสัตว์) -> medium
--   นอกนั้น -> low
------------------------------------------------------------------------------------------------------------------------------
Config.SkinTiers = {
    -- ── สัตว์เล็ก/กลาง ทั่วไป ──────────────────────────────────────────────
    [-1797625440] = { name = 'Armadillo',                meat = 'small',  hide = 'low' },    -- stringy, ไม่ใช่นักล่า
    [-1170118274] = { name = 'American Badger',          meat = 'small',  hide = 'low' },    -- stringy, ไม่ใช่นักล่า
    [1755643085]  = { name = 'American Pronghorn Doe',   meat = 'medium', hide = 'medium' }, -- venison, กวางตัวกลาง
    [-1124266369] = { name = 'Bear',                      meat = 'large',  hide = 'high' },   -- biggame, นักล่า (Bear)
    [-1568716381] = { name = 'Big Horn Ram',              meat = 'medium', hide = 'medium' }, -- Mutton
    [-1963605336] = { name = 'Buck',                      meat = 'medium', hide = 'medium' }, -- REVIEW/DEVIATION: givenItem[1] ต้นฉบับคือ "buckantler" (เขา) ไม่ใช่เนื้อ — ใช้ "venison" ที่อยู่ในลิสต์แทนแทนการยึด givenItem[1] เป๊ะๆ
    [1556473961]  = { name = 'Bison',                     meat = 'large',  hide = 'medium' }, -- beef, ตัวใหญ่แต่ไม่ใช่นักล่า
    [367637652]   = { name = 'Bison',                     meat = 'large',  hide = 'medium' }, -- hash โมเดลอื่นของ Bison
    [1957001316]  = { name = 'Bull',                      meat = 'large',  hide = 'medium' }, -- beef, ปศุสัตว์ตัวใหญ่
    [1110710183]  = { name = 'Deer',                      meat = 'medium', hide = 'medium' }, -- venison
    [252669332]   = { name = 'American Red Fox',          meat = 'small',  hide = 'low' },    -- game, ไม่ใช่นักล่าตามนิยาม (ไม่อยู่ใน Bear/Wolf/Cougar/Panther/Alligator)
    [-1143398950] = { name = 'Big Grey Wolf',              meat = 'small',  hide = 'high' },   -- game แต่เป็นนักล่า (Wolf) -> ตั้งใจให้ small+high
    [-885451903]  = { name = 'Medium Grey Wolf',           meat = 'small',  hide = 'high' },   -- นักล่า (Wolf)
    [-829273561]  = { name = 'Small Grey Wolf',            meat = 'small',  hide = 'high' },   -- นักล่า (Wolf)
    [-407730502]  = { name = 'Snapping Turtle',            meat = 'small',  hide = 'low' },    -- stringy
    [-22968827]   = { name = 'Water Snake',                meat = 'small',  hide = 'low' },    -- stringy
    [-229688157]  = { name = 'CottonMouth Water Snake',    meat = 'small',  hide = 'low' },    -- stringy
    [-1790499186] = { name = 'Snake Red Boa',              meat = 'small',  hide = 'low' },    -- stringy
    [1464167925]  = { name = 'Snake Fer-De-Lance',         meat = 'small',  hide = 'low' },    -- stringy
    [846659001]   = { name = 'Black-Tailed Rattlesnake',   meat = 'small',  hide = 'low' },    -- stringy
    [545068538]   = { name = 'Western Rattlesnake',        meat = 'small',  hide = 'low' },    -- stringy
    [-121266332]  = { name = 'Striped Skunk',              meat = 'small',  hide = 'low' },    -- stringy
    [40345436]    = { name = 'Merino Sheep',               meat = 'medium', hide = 'medium' }, -- Mutton, ปศุสัตว์
    [1458540991]  = { name = 'North American Racoon',      meat = 'small',  hide = 'low' },    -- game
    [-541762431]  = { name = 'Black-Tailed Jackrabbit',    meat = 'small',  hide = 'low' },    -- game
    [-1414989025] = { name = 'Virginia Possum',            meat = 'small',  hide = 'low' },    -- stringy
    [1007418994]  = { name = 'Berkshire Pig',              meat = 'medium', hide = 'medium' }, -- pork, ปศุสัตว์
    [1654513481]  = { name = 'Panther',                    meat = 'large',  hide = 'high' },   -- biggame, นักล่า (Panther)
    [90264823]    = { name = 'Cougar',                     meat = 'large',  hide = 'high' },   -- biggame, นักล่า (Cougar)
    [-50684386]   = { name = 'Florida Cracker Cow',        meat = 'large',  hide = 'medium' }, -- beef, ปศุสัตว์ตัวใหญ่
    [480688259]   = { name = 'Coyote',                     meat = 'small',  hide = 'low' },    -- game, ไม่ใช่นักล่าตามนิยาม
    [45741642]    = { name = 'Gila Monster',               meat = 'small',  hide = 'low' },    -- herptile
    [-753902995]  = { name = 'Alpine Goat',                meat = 'small',  hide = 'low' },    -- game
    [-1854059305] = { name = 'Green Iguana',               meat = 'small',  hide = 'low' },    -- herptile
    [-593056309]  = { name = 'Desert Iguana',              meat = 'small',  hide = 'low' },    -- herptile
    [1751700893]  = { name = 'Peccary Pig',                meat = 'medium', hide = 'medium' }, -- pork
    [-1098441944] = { name = 'Moose',                      meat = 'large',  hide = 'medium' }, -- biggame, ตัวใหญ่ไม่ใช่นักล่า
    [-1134449699] = { name = 'American Muskrat',           meat = 'small',  hide = 'low' },    -- stringy
    [556355544]   = { name = 'Angus Ox',                   meat = 'large',  hide = 'medium' }, -- biggame, ปศุสัตว์ตัวใหญ่
    [-1892280447] = { name = 'Alligator Small',            meat = 'small',  hide = 'high' },   -- game (ตัวเล็ก) แต่เป็นนักล่า (Alligator)
    [-2004866590] = { name = 'Alligator',                  meat = 'large',  hide = 'high' },   -- biggame, นักล่า (Alligator)
    [-1295720802] = { name = 'Northern American Alligator', meat = 'large', hide = 'high' },   -- biggame, นักล่า (Alligator)
    [759906147]   = { name = 'North American Beaver',      meat = 'small',  hide = 'low' },    -- game
    [730092646]   = { name = 'American Black Bear',        meat = 'large',  hide = 'high' },   -- biggame, นักล่า (Bear)
    [195700131]   = { name = 'Hereford Bull',               meat = 'large',  hide = 'medium' }, -- beef, ปศุสัตว์ตัวใหญ่

    -- ── Legendary — ทุกตัว hide = 'high' (ผู้เล่นสั่ง: legendary ทุกตัวหนัง High หมด ไม่ว่านักล่าหรือไม่) ──
    -- meat ยังตามขนาดตัวเดิม เปลี่ยนเฉพาะ hide ให้เป็น high ทั้งหมด
    [-2021043433] = { name = 'Legendary White Elk',          meat = 'medium', hide = 'high' }, -- venison
    [-1747620994] = { name = 'Legendary Boa',                meat = 'small',  hide = 'high' }, -- stringy
    [674287411]   = { name = 'Legendary Sun Alligator',      meat = 'large',  hide = 'high' }, -- aligatormeat, นักล่า
    [-1598866821] = { name = 'Legendary Bull Alligator',     meat = 'large',  hide = 'high' }, -- aligatormeat, นักล่า
    [-1149999295] = { name = 'Legendary White Beaver',       meat = 'small',  hide = 'high' }, -- stringy
    [2028722809]  = { name = 'Legendary Giant Boar',         meat = 'medium', hide = 'high' }, -- pork (hash ซ้ำกับ Boar ปกติที่ถูกคอมเมนต์ปิดไว้ในต้นฉบับ)
    [-389300196]  = { name = 'Legendary WakpaBoar',          meat = 'medium', hide = 'high' }, -- pork
    [-1433814131] = { name = 'Legendary Maza Cougar',        meat = 'large',  hide = 'high' }, -- biggame, นักล่า
    [-1307757043] = { name = 'Legendary Midnight Paw Coyote', meat = 'small', hide = 'high' }, -- stringy
    [-1189368951] = { name = 'Legendary Ghost Panther',      meat = 'large',  hide = 'high' }, -- biggame, นักล่า
    [-1392359921] = { name = 'Legendary Onyx Wolf',          meat = 'small',  hide = 'high' }, -- game, นักล่า
    [-551216071]  = { name = 'Legendary Owiza Bear',         meat = 'large',  hide = 'high' }, -- biggame, นักล่า
    [-511163808]  = { name = 'Legendary Chalk Horn Ram',     meat = 'medium', hide = 'high' }, -- Mutton
    [-1754211037] = { name = 'Legendary Buck',               meat = 'medium', hide = 'high' }, -- DEVIATION: givenItem[1]="buckantler" (เขา) ไม่ใช่เนื้อ ใช้ venison แทน
    [-915290938]  = { name = 'Legendary Winyan Bison',       meat = 'large',  hide = 'high' }, -- beef
    [-117665949]  = { name = 'Legendary Snowflake Moose',    meat = 'large',  hide = 'high' }, -- biggame

    -- ── นก — "เนื้ออย่างเดียว" (ผู้เล่นสั่ง: นกให้แค่เนื้อ ไม่มีหนัง) ────────────────
    -- ไม่มี key `hide` = server แจกเฉพาะเนื้อ (ดู server/main.lua) meat = 'small' ทุกตัว
    -- (นกทุกชนิดต้นฉบับให้ givenItem[1] = "bird") — ปรับ meat เป็น medium รายตัวได้ทีหลังถ้าต้องการ
    [-1003616053] = { name = 'Duck',                     meat = 'small' },
    [1459778951]  = { name = 'Eagle',                    meat = 'small' },
    [831859211]   = { name = 'Egret',                    meat = 'small' },
    [1104697660]  = { name = 'Vulture',                  meat = 'small' },
    [-466054788]  = { name = 'Wild Turkey',              meat = 'small' },
    [-2011226991] = { name = 'Wild Turkey',              meat = 'small' },
    [-166054593]  = { name = 'Wild Turkey',              meat = 'small' },
    [-164963696]  = { name = 'Herring Seagull',          meat = 'small' },
    [-1076508705] = { name = 'Roseate Spoonbill',        meat = 'small' },
    [2023522846]  = { name = 'Dominique Rooster',        meat = 'small' },
    [-466687768]  = { name = 'Red-Footed Booby',         meat = 'small' },
    [-575340245]  = { name = 'Western Raven',            meat = 'small' },
    [2079703102]  = { name = 'Greater Prairie Chicken',  meat = 'small' },
    [1416324601]  = { name = 'Ring-Necked Pheasant',     meat = 'small' },
    [1265966684]  = { name = 'American White Pelican',   meat = 'small' },
    [-1797450568] = { name = 'Blue And Yellow Macaw',    meat = 'small' },
    [120598262]   = { name = 'Californian Condor',       meat = 'small' },
    [-2063183075] = { name = 'Dominique Chicken',        meat = 'small' },
    [-2073130256] = { name = 'Double-Crested Cormorant', meat = 'small' },
    [-564099192]  = { name = 'Whooping Crane',           meat = 'small' },
    [723190474]   = { name = 'Canada Goose',             meat = 'small' },
    [-2145890973] = { name = 'Ferruinous Hawk',          meat = 'small' },
    [1095117488]  = { name = 'Great Blue Heron',         meat = 'small' },
    [386506078]   = { name = 'Common Loon',              meat = 'small' },
    [-86244272]   = { name = 'Great Horned Owl',         meat = 'small' },
}
