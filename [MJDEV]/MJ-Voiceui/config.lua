-- © 2026 MJDev | All rights reserved | Discord: discord.gg/gHRNMDQKzb
-- ห้ามนำไปจำหน่าย/แจกจ่าย/เผยแพร่ หรือแก้ไขเพื่อเผยแพร่ โดยไม่ได้รับอนุญาตเป็นลายลักษณ์อักษร

Config = {
    LerpSpeed = 0.085,
    UIDuration = 2500, -- เวลาที่ UI แจ้งเตือนแสดงผล (มิลลิวินาที)
    Modes = {
        [1] = { -- Whisper
            name = "กระซิบ",
            distance = 2.5,
            color = { r = 147, g = 211, b = 89, a = 200 }
        },
        [2] = { -- Normal
            name = "ปกติ",
            distance = 8.0,
            color = { r = 108, g = 203, b = 234, a = 200 }
        },
        [3] = { -- Shouting
            name = "ตะโกน",
            distance = 20.0,
            color = { r = 255, g = 0, b = 0, a = 200 }
        }
    }
}