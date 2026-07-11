Config = {}

Config.Command    = 'allmenu'
Config.DefaultKey = 0x1F6D95E5  -- F4 (RDR3 input hash)

-- รูป banner ใน header slider (เพิ่มได้หลายรูป)
-- แนะนำขนาด 1179×307px
Config.Banners = {
  'assets/2f90f681ae977f2e3a26a17b7da205b63be7dd05.png',
}

-- เมนูทั้งหมด — ไอเท็มแรกจะแสดงเป็นการ์ดใหญ่เสมอ
-- image: วางไฟล์ที่  html/assets/img/
--   การ์ดใหญ่ (ไอเท็มแรก) แนะนำขนาด 313×346 px
--   การ์ดเล็ก (ไอเท็มที่ 2 เป็นต้นไป)  แนะนำขนาด 277×167 px
-- action type:
--   'command'      → รัน /name ที่ client
--   'client_event' → TriggerEvent(name, ...)
--   nil            → แสดง "ยังไม่เปิดให้บริการ"
Config.Items = {
  {
    id     = 'battlepass',
    title  = 'แบทเทิลพาส',
    desc   = 'อัพเลเวลเพื่อรับของรางวัล Last Paradise',
    image  = 'assets/img/battlepass.png',
    action = { type = 'command', name = 'battlepass' }, -- lp_battlepass
  },
  {
    id     = 'guide',
    title  = 'คู่มือการใช้งาน',
    desc   = 'การใช้ชีวิตใน Last Paradise',
    image  = 'assets/img/guide.png',
    action = nil,
  },
  {
    id     = 'expired',
    title  = 'ไอเท็มหมดอายุ',
    desc   = 'เมนูเช็คไอเท็ม',
    image  = 'assets/img/expired.png',
    action = nil,
  },
  {
    id     = 'shop',
    title  = 'ร้านค้า',
    desc   = 'ร้านค้าพิเศษ',
    image  = 'assets/img/shop.png',
    action = nil,
  },
  {
    id     = 'login',
    title  = 'ล็อคอิน',
    desc   = 'เปิดเมนูล็อคอิน',
    image  = 'assets/img/login.png',
    action = { type = 'command', name = 'welfare' }, -- lp_welfarelogin
  },
  {
    id     = 'leaderboard',
    title  = 'กระดานอันดับ',
    desc   = 'อันดับผู้เล่น สังหาร/เมือง/อาชีพ',
    image  = 'assets/img/market.png', -- TODO: เปลี่ยนเป็นไอคอน leaderboard เฉพาะได้ (ตอนนี้ยืมของ market ไปก่อน)
    action = { type = 'command', name = 'leaderboard' }, -- lp_leaderboard
  },
  {
    id     = 'report',
    title  = 'แจ้งแอดมิน',
    desc   = 'เมื่อพบปัญหาหรือข้อสงสัย',
    image  = 'assets/img/report.png',
    action = { type = 'command', name = 'report' },
  },
}
