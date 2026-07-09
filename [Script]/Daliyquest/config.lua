Config = {}

-- เควสที่เปิดใช้งาน
Config.Quests = {
  plant = {
    name   = 'ปลูกผัก',
    desc   = 'ปลูกแครอท และเก็บ จำนวน 20 ต้น',
    img    = 'assets/q-plant.png',
    target = 20,
    reward = { { name = 'carrot', qty = 5 } },
  },
  hunt = {
    name   = 'ล่าสัตว์',
    desc   = 'ล่ากวาง 10 ตัว',
    img    = 'assets/q-hunt.png',
    target = 10,
    reward = { { name = 'venison', qty = 3 } },
  },
  mail = {
    name   = 'ส่งจดหมาย',
    desc   = 'ส่งจดหมายให้เพื่อน 1 ครั้ง',
    img    = 'assets/q-mail.png',
    target = 1,
    reward = { { name = 'stamina_cure', qty = 2 } },
  },
  mine = {
    name   = 'ขุดเหมือง',
    desc   = 'หาทองแดง หรือเหล็ก จำนวน 20 ชิ้น',
    img    = 'assets/q-mine.png',
    target = 20,
    reward = { { name = 'iron', qty = 5 } },
  },
  craft = {
    name   = 'คราฟไอเทม',
    desc   = 'คราฟไอเทมที่ชื่อว่า "ผ้าพันแผล"',
    img    = 'assets/q-craft.png',
    target = 1,
    reward = { { name = 'bandage', qty = 3 } },
  },
}

-- ลำดับแสดงผลใน UI
Config.QuestOrder = { 'plant', 'hunt', 'mail', 'mine', 'craft' }

-- คำสั่งเปิด/ปิด UI
Config.ToggleCommand = 'quest_toggle'
