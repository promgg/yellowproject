-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 
Config = {}

Config['Debug'] = false -- เช็คค่าตัวแปรต่างๆ แนะนำ false ไว้

Config = {
    inline = true, -- ข้อความหนาและทำให้ข้อความเป็นตัวหนา
    -- ตั้งค่าจริงผ่าน convar ใน server.cfg:
    --   set mj_randomnumber_webhook_url "https://discord.com/api/webhooks/..."
    --   set mj_randomnumber_logs_webhook "https://discord.com/api/webhooks/..."
    webhookURL = GetConvar("mj_randomnumber_webhook_url", ""), -- URL ของ Webhook สำหรับแจ้งเตือน
    logsWebhook = GetConvar("mj_randomnumber_logs_webhook", ""), -- URL ของ Webhook สำหรับบันทึกเวลาผู้เล่นรับของ
    message = "เซิร์ฟเวอร์ได้เปิดใช้งานแล้ว!", -- ข้อความที่จะส่งไปยัง Webhook
    numberMin = 1, -- เลขสุ่มต่ำสุด
    numberMax = 100, -- เลขสุ่มสูงสุด
    numberCount = 10, -- จำนวนตัวเลขที่ต้องการสุ่ม
    imageURL = "https://i.postimg.cc/523w5jh3/re.png", -- รูปภาพที่จะแสดงในดิสคอร์ด
    rewards = {
        [1] = {item = "money", quantity = 500},            -- เงินปกติ 500$ 0 = money, 1 = gold
        [2] = {item = "gold", quantity = 1000},            -- เงินดำ 1000$ 0 = money, 1 = gold
        [3] = {item = "test", quantity = 1},               -- อาวุธปืน 1 กระบอก
        [4] = {item = "test", quantity = 5},               -- ไอเทมอาหาร 5 ชิ้น
    }  
}
