Config = {}
Config.Align = "top-left"                 -- ตำแหน่งเมนู

Config.Lang = "English"                   -- ภาษาที่ต้องการใช้งาน ตรวจสอบให้แน่ใจว่ามีในไฟล์ translation.lua

Config.AllowOnlyDeadToAlert = true        -- หากตั้งค่าเป็น true จะมีเฉพาะผู้เล่นที่ตายเท่านั้นที่สามารถเรียกหมอได้

Config.AlertDoctorCommand = "calldoctor"  -- คำสั่งเรียกหมอ
Config.cancelalert = "cancelDoctorAlert"  -- คำสั่งยกเลิกการเรียกหมอ
Config.finishalert = "finishDoctorAlert"  -- คำสั่งจบการเรียกหมอ
Config.DoctorMenuCommand = 'doctormenu'   -- คำสั่งเข้าสู่โหมดปฏิบัติหน้าที่และวาร์ป

-- เพิ่มชื่ออาชีพที่นี่
Config.MedicJobs = {
    doctor = true,        -- หมอ
    headdoctor = true,    -- หัวหน้าหมอ
    shaman = true,        -- หมอผี
}

Config.Keys = { -- ปุ่มสำหรับใช้งาน (prompts)
    B = 0x4CC0E2FE        -- ปุ่ม B
}

-- อาชีพที่สามารถจ้างงานได้
Config.JobLabels = {
    doctor = "หมอ",
    headdoctor = "หัวหน้าหมอ",
    shaman = "หมอผี",
}

-- อาชีพที่สามารถเปิดเมนูจ้างงานได้
Config.DoctorJobs = {
    headdoctor = true,    -- เฉพาะหัวหน้าหมอ
}

-- หากตั้งค่าเป็น true คลังอุปกรณ์ของสถานีหมอจะใช้ร่วมกัน หากเป็น false จะเป็นของแต่ละสถานี
Config.ShareStorage = true

-- ตำแหน่งคลังอุปกรณ์
Config.Storage = {
    Valentine = {
        Name = "คลังอุปกรณ์การแพทย์",
        Limit = 1000,
        Coords = vector3(-288.74, 808.77, 119.44)
    },
    Strawberry = {
        Name = "คลังอุปกรณ์การแพทย์",
        Limit = 1000,
        Coords = vector3(-1803.33, -432.59, 158.83)
    },
    SaintDenis = {
        Name = "คลังอุปกรณ์การแพทย์",
        Limit = 1000,
        Coords = vector3(2733.1, -1230.26, 50.42)
    },
}

-- หากตั้งค่าเป็น true สามารถใช้เมนูวาร์ปได้ หากเป็น false ต้องไปยังจุดที่กำหนดเท่านั้น
Config.UseTeleportsMenu = false

-- ตำแหน่งวาร์ป
Config.Teleports = {
    Valentine = {
        Name = "วาร์ป Valentine",
        Coords = vector3(-280.38, 817.81, 119.38)
    },
    Strawberry = {
        Name = "วาร์ป Strawberry",
        Coords = vector3(-1793.37, -422.81, 155.97)
    },
    SaintDenis = {
        Name = "วาร์ป Saint Denis",
        Coords = vector3(2723.1, -1238.92, 49.95)
    },
}

-- บลิ๊ปสำหรับสถานีหมอ
Config.Blips = {
    Color = "COLOR_WHITE",
    Style = "BLIP_STYLE_FRIENDLY_ON_RADAR",
    Sprite = "blip_mp_travelling_saleswoman"
}

Config.AlertBlips = {
    Color = "COLOR_RED",
    Style = "BLIP_STYLE_CHALLENGE_OBJECTIVE",
    Sprite = "blip_mp_travelling_saleswoman"
}

-- ตำแหน่งสถานีหมอ
Config.Stations = {
    Valentine = {
        Name = "Medic Valentine",
        Coords = vector3(-288.82, 808.44, 119.43),
        Teleports = Config.Teleports,
        Storage = Config.Storage
    },
    Strawberry = {
        Name = "Medic Strawberry",
        Coords = vector3(-1807.87, -430.77, 158.83),
        Teleports = Config.Teleports,
        Storage = Config.Storage
    },
    SaintDenis = {
        Name = "Medic Saint Denis",
        Coords = vector3(2721.29, -1233.11, 50.37),
        Teleports = Config.Teleports,
        Storage = Config.Storage
    },
}

-- ไอเท็มที่ใช้งานได้
Config.Items = {
    bandage = {              -- ชื่อไอเท็ม
        health = 50,         -- จำนวนเลือดที่จะเพิ่ม
        stamina = 100,       -- จำนวนความแข็งแรงที่จะเพิ่ม
        revive = false,      -- หากตั้งค่าเป็น true จะชุบชีวิตผู้เล่น
        mustBeOnDuty = false -- หากตั้งค่าเป็น true ผู้เล่นต้องอยู่ในหน้าที่เพื่อใช้ไอเท็มนี้
    },
    potion = {
        health = 100,
        stamina = 0,
        revive = false,
        mustBeOnDuty = false
    },
    syringe = {
        health = 0,
        stamina = 0,
        revive = true,
        mustBeOnDuty = true
    },
}
