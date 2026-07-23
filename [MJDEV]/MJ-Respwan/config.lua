
Config = {}

local second = 1000
local minute = 60 * second
Config.Debug = true
-- ตั้งค่าจริงผ่าน convar ใน server.cfg: set mj_respwan_discord_webhook "https://discord.com/api/webhooks/..."
Config.DISCORD_WEBHOOK = GetConvar("mj_respwan_discord_webhook", "")
Config.SpawnTime = 5 * minute -- ===> เวลาตายรอเกิด
Config.VipSpawnTime = 5 * minute -- ===> เวลาตายรอเกิด

Config.VIP = {"vip_card", "revive_token"} -- Inventory items for VIP

-- ===== ปุ่มบนหน้าจอตาย (death screen bottom bar) =====
-- ชื่อปุ่ม -> ตัวอักษรคีย์ (map เข้ากับตาราง Keys[...] ใน core/client.lua สำหรับ IsControlJustPressed)
Config.Keys = {
    clearBody     = 'G', -- ซิงค์ร่างกายใหม่ (แก้ร่างค้าง/desync)
    respawn       = 'E', -- เกิดใหม่ที่โรงพยาบาล (เปิดใช้เมื่อ countdown = 0)
    leaveActivity = 'X', -- ออกจากกิจกรรม (ปิดไว้ default — ใช้ผ่าน export)
    callDoctor    = 'B', -- เรียกหมอ (ปิดไว้ — ยังไม่มีอาชีพหมอ)
    callHelp      = 'H', -- ขอความช่วยเหลือ (ส่งสัญญาณให้ผู้เล่นใกล้เคียง)
}

Config.HoldTime          = 600    -- ms ต้องกดค้างปุ่มนานเท่านี้ถึงจะทำงาน (เหมือน lp_textui)
Config.ClearBodyCooldown = 5      -- วินาที cooldown ปุ่ม CLEAR BODY
Config.HelpCooldown      = 20     -- วินาที cooldown ปุ่ม CALL FOR HELP
Config.HelpRadius        = 100.0  -- ระยะ (เมตร) ที่ผู้เล่นจะได้รับสัญญาณขอความช่วยเหลือ
Config.HelpBlipTime      = 30000  -- ms อายุของ blip ขอความช่วยเหลือบนแผนที่

-- เปิด/ปิดปุ่มเริ่มต้น (false = ซ่อนปุ่มไปเลย ไม่แสดงบนแถบ + กดไม่ได้)
Config.Buttons = {
    clearBody     = false, -- ซ่อนไว้ก่อน ยังไม่เปิดใช้ (ตั้ง true เพื่อโชว์ปุ่ม CLEAR BODY [G])
    callHelp      = false, -- ซ่อนไว้ก่อน ยังไม่เปิดใช้ (ตั้ง true เพื่อโชว์ปุ่ม CALL FOR HELP [H])
    leaveActivity = false, -- placeholder — เปิดผ่าน export SetLeaveActivityButton หรือใช้ export LeaveActivityRespawn
    callDoctor    = false, -- ยังไม่มีระบบอาชีพหมอในเซิร์ฟเวอร์
}

Config.Animations = {
    revive = {dict = "mech_revive@unapproved", anim = "revive", duration = 7000},

    -- "heal" category (bandage_s/bandage_xl) — เดิมใช้ anim "bandage_fast" ใน dict เดียวกันนี้ +
    -- flags=1 + duration=-1 (loop ไม่รู้จบ) แล้วค้าง เดินไม่ได้แม้ progbar จบแล้ว (ทดสอบแล้วจริง) —
    -- เช็คเจอว่า vorp_metabolism ใช้ dict เดียวกันแต่คลิป "tourniquet_slow" + flags=31 +
    -- duration=5000 (จำกัดเวลา ไม่ loop ตลอดไป) เล่นได้จริงและไม่ค้าง (useItemsActions.lua:26-48)
    -- เปลี่ยนมาใช้ค่าที่พิสูจน์แล้วนี้แทนทั้งหมด — "เดินได้ วิ่งไม่ได้" ยังเป็นพฤติกรรมเดิมของ primary
    -- task (เสริมด้วย disableSprint=true ให้ชัดเจน ไม่พึ่งผลข้างเคียงอย่างเดียว) กด Backspace ยกเลิก
    -- ท่า/UI ได้ (canCancel=true) แต่ item/เลือดเสียไปแล้วตั้งแต่กดใช้ ไม่ได้คืน (server ทำงานทันทีไม่รอ client)
    -- prop ผ้าพันแผล — model + bone + offset/rotation ยกมาจาก vorp_metabolism ตรงๆ
    -- (useItemsActions.lua:26-48, playAnimBandage) ยืนยันแล้วว่าใช้กับ dict/anim ตัวเดียวกันนี้จริง
    heal = {
        dict = "mini_games@story@mob4@heal_jules@bandage@arthur", anim = "tourniquet_slow",
        duration = 5000, flags = 31, canCancel = true,
        controlDisables = { disableSprint = true },
        prop = {
            model = "p_cs_bandage01x",
            boneName = "SKEL_L_HAND",
            coords = { x = 0.10, y = 0.0, z = 0.03 },
            rotation = { x = 0.0, y = -60.0, z = -90.0 },
        },
    },

    -- "quick" category (painkiller/stamina) — ยืมท่ากิน/ดื่มจาก vorp_metabolism (useItemsActions.lua)
    -- flags=49 (ทดลอง loop+upperbody+playercontrol ให้เดิน/วิ่งได้ระหว่างเล่น) ทดสอบแล้วไม่เล่นท่าเลย
    -- ("ไม่มีท่าทาง") — ไม่มี pattern พิสูจน์แล้วเรื่องนี้ในโปรเจกต์นี้ทั้งหมด (เช็คทั้ง repo แล้ว)
    -- ค่าที่เดามาจาก native reference ทั่วไปของ FiveM ใช้ไม่ได้กับ build นี้ — ถอยกลับมาใช้ flags=31
    -- ที่พิสูจน์แล้วว่าเล่นท่านี้ได้จริงจาก vorp_metabolism ตรงๆ (useItemsActions.lua เรียกด้วยค่านี้)
    -- ก่อน แต่นั่นแปลว่า "เดิน/วิ่งระหว่างใช้" ยังทำไม่ได้ — พฤติกรรมตอนนี้ล็อคเหมือน heal (ต้องทดลอง
    -- ค่า flags อื่นในเกมจริงร่วมกันทีหลังถ้ายังต้องการ movement-permissive จริงๆ)
    -- prop ขวดยา — model + bone + offset/rotation ยกมาจาก vorp_metabolism ตรงๆ
    -- (useItemsActions.lua:87-113, playAnimDrink) ยืนยันแล้วว่าใช้กับ dict/anim ตัวเดียวกันนี้จริง
    -- (โมเดล p_bottlemedicine09x ตรงกับที่เรียก "ยาขวด" ไว้ตอนคุยกันก่อนหน้า)
    quick = {
        dict = "amb_rest_drunk@world_human_drinking@male_a@idle_a", anim = "idle_a",
        duration = 4000, flags = 31, canCancel = true,
        controlDisables = {},
        prop = {
            model = "p_bottlemedicine09x",
            boneName = "SKEL_R_HAND",
            coords = { x = 0.08, y = -0.04, z = -0.05 },
            rotation = { x = -75.0, y = 0.0, z = 0.0 },
        },
    },
}

-- ไอเท็มที่ใช้งานได้
-- category ชี้ไปที่ Config.Animations[category] ด้านบน (bandage-type ใช้ 'heal', quick-type ใช้ 'quick')
-- — aed (revive=true) ไม่ใช้ field นี้ เพราะไปคนละ flow กัน (ReviveAnim ไม่ใช่ HealAnim)
Config.Items = {
    bandage_s = {              -- ชื่อไอเท็ม
        health = 15,         -- จำนวนเลือดที่จะเพิ่ม
        stamina = 0,       -- จำนวนความแข็งแรงที่จะเพิ่ม
        revive = false,      -- หากตั้งค่าเป็น true จะชุบชีวิตผู้เล่น
        category = 'heal',
    },
    bandage_xl = {
        health = 30,
        stamina = 0,
        revive = false,
        category = 'heal',
    },
    painkiller = {
        health = 80,
        stamina = 0,
        revive = false,
        category = 'quick',
    },
    stamina = {
        health = 0,
        stamina = 90,
        revive = false,
        category = 'quick',
    },
    aed = {
        health = 0,
        stamina = 0,
        revive = true,
    },
}
