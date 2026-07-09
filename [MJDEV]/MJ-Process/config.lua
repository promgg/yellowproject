-- © 2026 MJDev | All rights reserved | Discord: discord.gg/gHRNMDQKzb
-- ห้ามนำไปจำหน่าย/แจกจ่าย/เผยแพร่ หรือแก้ไขเพื่อเผยแพร่ โดยไม่ได้รับอนุญาตเป็นลายลักษณ์อักษร

Config = {}

-- 🟢 ตั้งค่าระบบ Discord Webhook
Config.Webhook = "https://discord.com/api/webhooks/xxxxxx/xxxxxx" -- ใส่ลิงก์เว็บฮุค
Config.BotName = "MJ Process Log" 
Config.BotAvatar = "https://i.imgur.com/wKz1kH0.png"

Config.EnableOnce = true 
Config.EnableAuto = true 

Config.Locations = {
    -- 🟢 จุดที่ 1: สถานีแปรรูปไม้
    {
        Name = "Lumberjack Station",
        Coords = vector3(-428.2, 506.24, 98.0), 
        Heading = 60.88,
        NPCModel = "a_m_m_valtownfolk_01",
        BlipSprite = 1809053896,
        BlipName = "Lumberjack Station",
        Recipes = {
            {
                Label = "Process Raw Wood",
                InputItem = "provision_calderon_cross",
                InputCount = 2,
                Outputs = {
                    { Item = "resource_resin", Count = 1 },
                    { Item = "lumber_pine_wood_logs", Count = 1 },
                    { Item = "lumber_pine_split_logs", Count = 1 },
                    { Item = "lumber_resource_cork", Count = 2 }
                },
                ProcessTime = 5000, 
                Scenario = "WORLD_HUMAN_CHOP_WOOD", 
                ProcessSound = "" 
            }
        }
    },
    
    -- 🟢 จุดที่ 2: สถานีแปรรูปเหมือง
    {
        Name = "Mining Station",
        Coords = vector3(2879.48, 1401.44, 68.72), 
        Heading = 90.0,
        NPCModel = "a_m_m_valtownfolk_01",
        BlipSprite = 1809053896,
        BlipName = "Mining Station",
        Recipes = {
            {
                Label = "Smelt Iron Ore",
                InputItem = "iron", 
                InputCount = 2,
                Outputs = {
                    { Item = "copperore", Count = 1 },
                    { Item = "ironbar", Count = 1 },
                    { Item = "ironore", Count = 1 },
                    { Item = "graveheart_stone", Count = 1 },
                    { Item = "whispering_shale", Count = 1 },
                    { Item = "coal", Count = 1 }
                },
                ProcessTime = 6000, 
                Scenario = "WORLD_HUMAN_HAMMER_SMITH", 
                ProcessSound = "" 
            }
        }
    }
}