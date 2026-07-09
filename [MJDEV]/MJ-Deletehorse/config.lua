

Config = {}

Config.TextUIRestart = '🌙 เซิฟเวอร์ Restart โปรดรอสักครู่ แล้วทำการเชื่อมต่อใหม่' -- ข้อความที่จะแสดงเมื่อเตะผู้เล่นออกจากเซิฟเวอรื
Config.webhooks_Autorestart = '' -- Webhook ห้องที่จะให้แจ้งเตือน
Config.imagebot = 'https://media.discordapp.net/attachments/1070059251046817883/1119256315743711303/JKLlogoFivem_noBG.png'  -- รูปภาพของ BOT แจ้งเตือนในดิส
Config.text1 = '⌛ เซิฟเวอร์จะรีสตาร์ทในอีก ' -- ข้อความที่จะให้แสดงของ BOT
Config.text2 = '🚧 เซิฟเวอร์กำลังรีสตาร์ท ...' -- ข้อความที่จะให้แสดงของ BOT
Config.nameserver = 'REDM' -- ชื่อเซิฟเวอร์

Config.closecmd = true -- true / false จะให้ทำการปิดตัวรัน และ รันเซิฟออโต้หรือไม่
Config.cmd_name = 'start !runserver.bat'  -- ชื่อตัวรันเซิฟของคุณ //สำคัญมาก

Config.RunRestartNotify = {
    command = 'rsnoti', -- คำสั่งที่ใช้รีเซิฟเวอร์
    group = {
        ['admin'] = true,
    },
}

Config.CanCelRestartNotify = {
    command = 'ccrsnoti', -- คำสั่งที่ใช้ยกเลิกการรีเซิฟเวอร์
    group = {
        ['admin'] = true,
    },
}

--/////////// Config ส่วนของ Restart Server ///////////
Config.DeleteAllVehicle = {
    command = 'devh', -- คำสั่งที่ใช้ลบรถ
    group = {
        ['admin'] = true,
    },
}

Config.CanCelDeleteAllVehicle = {
    command = 'ccdelallcar', -- คำสั่งที่ใช้ยกเลิกการลบรถ
    group = {       
        ['admin'] = true,
    },
}

--/////////// ตั้งเวลาลบรถ และ เวลาRestart เซิฟเวอร์ ///////////
Config.Timer = {
    -- DelCar (ปรับเวลาใหม่ตามที่แจ้ง)
    { '01:25', 3, 'delcar' },
    { '04:25', 3, 'delcar' },
    { '05:50', 10, 'restart' }, -- เวลา restart เดิม
    { '08:25', 3, 'delcar' },
    { '10:25', 3, 'delcar' },
    { '13:25', 3, 'delcar' },
    { '16:25', 3, 'delcar' },
    { '17:50', 10, 'restart' }, -- เวลา restart เดิม
    { '19:25', 3, 'delcar' },
    { '22:25', 3, 'delcar' },
}

--/////////// เสียงแจ้งเตือนเวลาลบรถ ///////////
Config.SoundNotifyDeleteHorseAndWagon = {
    { time = 3, file = 'delcar3', volume = 0.50 },
    { time = 1, file = 'delcar1', volume = 0.50 },
    { time = 0, file = 'delcar0', volume = 0.50 },
}

--/////////// เสียงแจ้งเตือนเวลารีเซิฟเวอร์ ///////////
Config.SoundNotifyRestartServer = {
    { time = 10, file = 'restart1', volume = 0.50 },
	{ time = 7, file = 'restart1', volume = 0.50 },
	{ time = 3, file = 'restart1', volume = 0.50 },
	{ time = 2, file = 'restart1', volume = 0.50 },
    { time = 1, file = 'restart2', volume = 0.50 },
    { time = 0, file = 'restart4', volume = 0.50 }
}
