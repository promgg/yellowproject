

-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 

Config = {}
Config['DiscordWebhook'] = "https://discord.com/api/webhooks/1347337578105409556/aRyk1tWhN5pay9T0Vi3CJ1ne3sgCBdZbsD2NrjJZEpHDRN0qOAFny3Cvdr90krqMXzUB" -- ใส่ Webhook URL ของคุณที่นี่

Config['DeleteAnimalTime'] = 120 -- สามารถเปลี่ยนค่าได้ตามต้องการ
Config["Animals"] = {
    {
        ["Coords"] = vector3(1480.6, -1593.08, 72.6), -- ตำแหน่งของสัตว์ในโลก (X, Y, Z)
        ['Radius'] = 100.0, -- รัศมีที่สัตว์สามารถอยู่ในพื้นที่นี้ได้ (หน่วยเป็นเมตร)
        ['blips'] = {
            name = "Animal", -- ชื่อที่จะแสดงในบลิป (บนแผนที่)
            sprite = -1085232344, -- ไอคอนบลิปสำหรับสัตว์
            scale = 0.6, -- ขนาดของบลิป
            modifier = "BLIP_MODIFIER_MP_COLOR_32", -- สีที่ใช้สำหรับบลิป
        },
        ["Animal"] = {
            ["Name"] = "water", -- ชื่อของสัตว์ (สำหรับใช้ภายในระบบ)
            ["Label"] = "Sheep", -- ชื่อแสดงในเกมสำหรับสัตว์
            ["Model"] = "a_c_raccoon_01", -- โมเดลของสัตว์ (ใช้สำหรับการแสดงในเกม)
            ["Price"] = 10, -- ราคาในการซื้อสัตว์
            ["Food"] = "water", -- ชื่อของอาหารที่ต้องการให้สัตว์
            ["Time"] = 60, -- เวลาที่สัตว์สามารถมีชีวิตอยู่ (อายุสูงสุด)
            ["NeedFood"] = {20, 60}, -- ช่วงความต้องการอาหารของสัตว์ (ใช้สำหรับคำนวณการให้อาหาร)
            ["Drop"] = {
                ["water"] = {
                    ["percent"] = 100, -- เปอร์เซ็นต์การทิ้งไอเทม
                    ["number"] = {1,1} -- จำนวนที่ทิ้ง (ตั้งค่าให้เป็น 1 ชิ้น)
                },
            },
            ["TimeWithoutFood"] = 60,  -- เวลาที่สัตว์จะตายหากไม่ได้รับอาหาร (ในวินาที)
        }
    },
    {
        ["Coords"] = vector3(1388.84, 340.48, 87.56), -- ตำแหน่งของสัตว์ในโลก (X, Y, Z)
        ['Radius'] = 100.0, -- รัศมีที่สัตว์สามารถอยู่ในพื้นที่นี้ได้ (หน่วยเป็นเมตร)
        ['blips'] = {
            name = "Animal", -- ชื่อที่จะแสดงในบลิป (บนแผนที่)
            sprite = -1085232344, -- ไอคอนบลิปสำหรับสัตว์
            scale = 0.6, -- ขนาดของบลิป
            modifier = "BLIP_MODIFIER_MP_COLOR_32", -- สีที่ใช้สำหรับบลิป
        },
        ["Animal"] = {
            ["Name"] = "water", -- ชื่อของสัตว์ (สำหรับใช้ภายในระบบ)
            ["Label"] = "Sheep", -- ชื่อแสดงในเกมสำหรับสัตว์
            ["Model"] = "a_c_toad_01", -- โมเดลของสัตว์ (ใช้สำหรับการแสดงในเกม)
            ["Price"] = 10, -- ราคาในการซื้อสัตว์
            ["Food"] = "water", -- ชื่อของอาหารที่ต้องการให้สัตว์
            ["Time"] = 60, -- เวลาที่สัตว์สามารถมีชีวิตอยู่ (อายุสูงสุด)
            ["NeedFood"] = {20, 60}, -- ช่วงความต้องการอาหารของสัตว์ (ใช้สำหรับคำนวณการให้อาหาร)
            ["Drop"] = {
                ["water"] = {
                    ["percent"] = 100, -- เปอร์เซ็นต์การทิ้งไอเทม
                    ["number"] = {1,1} -- จำนวนที่ทิ้ง (ตั้งค่าให้เป็น 1 ชิ้น)
                },
            },
            ["TimeWithoutFood"] = 60,  -- เวลาที่สัตว์จะตายหากไม่ได้รับอาหาร (ในวินาที)
        }
    },
}

Config['Messages'] = {
    ResourceName = "^2ResourceName ^0",
    InsufficientMoney = "ต้องการเงินจำนวน %s",
    AnimalNotFound = "ไม่พบสัตว์ที่ต้องการให้อาหาร",
    FeedSuccess = "ให้อาหารสำเร็จ",
    NotEnoughFood = "ไม่มีอาหารเพียงพอ",
    EnterZone = "โปรดเข้าวงภายใน ",
    Seconds = " วินาที",
    AnimalDied = "สัตว์หมายเลข %d ได้ตายแล้ว",
    AnimalDeleted = "สัตว์ถูกลบเนื่องจากออกมาไกลเกินไป"
}

Config['SendNotification'] = function(text, type)
    exports.pNotify:SendNotification({
        text = text,
        type = type,
        timeout = 3000,
        layout = "centerRight"
    })
end

Config['SendNotification_Sv'] = function(src, text, type)
    TriggerClientEvent('pNotify:SendNotification', src, {
        text = text,
        type = type,
        timeout = 10000,
        layout = "centerRight"
    })
end