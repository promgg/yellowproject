Config = {}

-- เปิด UI ด้วยปุ่ม E ค้าง (control 0x17BEC168) ผ่าน lp_textui:TextUIHold — poll เฉพาะตอนยืนในโซน (client/main.lua)
Config.zoneRadius  = 30.0          -- metres around zone coords
Config.holdMs      = 900           -- กดค้าง E กี่ ms ถึงเปิด (เท่ากับ MJ-Lumberjack/MJ-Mining/MJ-Planting)

-- ── ต้นทุนในการเพิ่มสัตว์ (money sink กัน item printer) ───────────────
Config.addPrice    = 10           -- ราคาซื้อสัตว์ต่อ 1 ตัวตอน Add
Config.moneyType   = 0            -- 0 = dollars, 1 = gold (VORP removeCurrency type)

-- ped settings
Config.syncPed     = false        -- true = NetworkCreateEntity (all players see), false = local only
Config.pedOffset   = { x = 0.0, y = 0.0, z = 0.0 }  -- spawn offset from player position

-- feeding mechanics
Config.feedWindow  = 5 * 60      -- seconds player has to feed before animal dies (5 min)
Config.hpDecayTime = 5 * 60      -- seconds for HP to drain from 100 → 0 (5 min)
                                 -- feedsRequired × hpDecayTime = เวลาต่อรอบ (5 × 5 นาที = 25 นาที)

-- รูปไอเทม (อาหาร/ของรางวัล) ดึงจาก vorp_inventory อัตโนมัติจากชื่อ item:
--   nui://vorp_inventory/html/img/items/<item_name>.png   (ตั้งใน app.js: ITEM_ICON_BASE)
-- รูปสัตว์ (image ต่อ zone ด้านล่าง) วางไฟล์ไว้ที่โฟลเดอร์เดียวกันนั้น

-- zones  {x, y, z, heading}
Config.Zones = {
  ['bison'] = {
    coords    = vector4(-617.6779, -25.5035, 85.5194, 116.5602),
    pedModel  = 'a_c_buffalo_01',
    -- RDR2 มีควายแค่ 3 โมเดลและไม่มีตัววัยเด็กเลย (a_c_buffalo_01 ปกติ / tatanka ตัวใหญ่กว่า /
    -- mp_ ตัวเดียวกัน) อยากได้ลูกควายจึงย่อโมเดลตัวเต็มวัยเอา — ไม่ใส่ฟิลด์นี้ = ขนาดปกติ
    pedScale  = 0.5,
    image     = 'nui://vorp_inventory/html/img/items/animal_bison.png',
    maxSlots  = 5,
    feedsRequired = 1,
    nameTH    = 'เลี้ยงใบสัน',
    itemFeed  = { { name = 'job_animalfood', qty = 1 } },
    itemReward = { { name = 'meat_large', qty = 2 } },
    blip = {
      sprite = -1646261997,         -- sprite hash (int)
      scale  = 0.5,
      label  = 'ฟาร์มสัตว์: ใบสัน',
    },
  },
  ['tiger'] = {
    coords    = vector4(2985.9424, 2195.9185, 166.2030, 73.1517),
    pedModel  = 'a_c_panther_01',
    image     = 'nui://vorp_inventory/html/img/items/animal_tiger.png',
    maxSlots  = 5,
    feedsRequired = 1,
    nameTH    = 'เลี้ยงเสือ',
    itemFeed  = { { name = 'job_animalfood', qty = 1 } },
    itemReward = { { name = 'meat_large', qty = 2 } },
    blip = {
      sprite = -1646261997,
      scale  = 0.5,
      label  = 'ฟาร์มสัตว์: เสือ',
    },
  },
  ['croc'] = {
    coords    = vector4(1377.9629, -866.6765, 69.3180, 339.3852),
    pedModel  = 'a_c_alligator_01',
    image     = 'nui://vorp_inventory/html/img/items/animal_alligator.png',
    maxSlots  = 5,
    feedsRequired = 1,
    nameTH    = 'เลี้ยงจรเข้',
    itemFeed  = { { name = 'job_animalfood', qty = 1 } },
    itemReward = { { name = 'meat_large', qty = 2 } },
    blip = {
      sprite = -1646261997,
      scale  = 0.5,
      label  = 'ฟาร์มสัตว์: จรเข้',
    },
  },
}
