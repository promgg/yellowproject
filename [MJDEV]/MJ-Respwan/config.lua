
Config = {}

local second = 1000
local minute = 60 * second
Config.Debug = false
-- ตั้งค่าจริงผ่าน convar ใน server.cfg: set mj_respwan_discord_webhook "https://discord.com/api/webhooks/..."
Config.DISCORD_WEBHOOK = GetConvar("mj_respwan_discord_webhook", "")
Config.SpawnTime = 5 * minute -- ===> เวลาตายรอเกิด
Config.VipSpawnTime = 5 * minute -- ===> เวลาตายรอเกิด

Config.VIP = {"vip_card", "revive_token"} -- Inventory items for VIP

Config.Animations = {
    revive = {dict = "mech_revive@unapproved", anim = "revive", duration = 7000},
    heal = {dict = "mini_games@story@mob4@heal_jules@bandage@arthur", anim = "bandage_fast", duration = 5000},
}

-- ไอเท็มที่ใช้งานได้
Config.Items = {
    bandage_s = {              -- ชื่อไอเท็ม
        health = 15,         -- จำนวนเลือดที่จะเพิ่ม
        stamina = 0,       -- จำนวนความแข็งแรงที่จะเพิ่ม
        revive = false,      -- หากตั้งค่าเป็น true จะชุบชีวิตผู้เล่น
    },
    bandage_xl = {
        health = 30,
        stamina = 0,
        revive = false,
    },
    painkiller = {
        health = 80,
        stamina = 0,
        revive = false,
    },
    stamina = {
        health = 0,
        stamina = 90,
        revive = false,
    },
    aed = {
        health = 0,
        stamina = 0,
        revive = true,
    },
}
