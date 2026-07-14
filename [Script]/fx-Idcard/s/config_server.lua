-- server-only config — ไม่ผ่าน shared_scripts จึงไม่ถูกส่งไปฝั่ง client เลย
-- (webhook URL ไม่ควรหลุดไปอยู่ในไฟล์ที่ client โหลดได้ — ตั้งผ่าน convar fx_idcard_webhook ทับค่านี้ได้เสมอ)

-- เว้นว่างไว้เพื่อปิด Discord log
Config.DiscordWebhook = ""
Config.DiscordBotName = "FX Identity Card"
