Config = {}

Config.Debug = false
Config.ResourceName = 'nx_hud'

Config.UpdateIntervals = {
    MainHud = 350,
    HorseHud = 300,
    RadarMap = 75,
    StartupDelay = 1000,
    ForceRefresh = 5000,
}

Config.Visibility = {
    MainHud = true,
    HorseHud = true,
    HideOnPause = true,
}

Config.NativeHud = {
    HidePlayerHealth = true,
    HidePlayerStamina = true,
    HidePlayerDeadEye = true,
    HideHorseHealth = true,
    HideHorseStamina = true,
    HideHorseCourage = true,
    ReapplyInterval = 5000,
}

Config.Integration = {
    WaitForSelectedCharacter = true,
    StartupReadyDelay = 3000,
    SelectedCharacterDelay = 1000,
    FollowVorpShowUi = false,

    MJStatus = {
        Enabled = true,
        Resource = 'MJ-STATUS',
        PollInterval = 2000,
        MaxHunger = 100000,
        MaxThirst = 100000,
        -- ความเครียดจริงใน MJ-STATUS ทำงานบนสเกล 0..100 (log โหลดค่าจริง ~1.2, คอมเมนต์อ้าง
        -- "เกิน 90/ถึง 100", MinimumStress=50, ตาราง shake 50..100) — ไม่ใช่ 0..100000 อย่างชื่อ
        -- Config.MaxStress ทำให้เข้าใจผิด. ตั้ง MaxStress=100 ให้ statusPercent map ตรง 1:1
        -- (stress 1.2 -> 1.2%, 90 -> 90%). InvertStress=false: หลอด "เติมตาม" ความเครียดจริง
        -- (สงบ=ว่าง, เครียด=เต็ม) เดิม invert ทำให้สงบแล้วหลอดเต็มตลอด = ไม่ตรงจริง
        MaxStress = 100,
        InvertStress = false,
        Exports = {
            Hunger = 'setHunger',
            Thirst = 'setThirst',
            Stress = 'setStress',
            Temperature = 'setTemp',
        },
        Map = {
            Hunger = 'food',
            Thirst = 'water',
            Stress = 'core',
        },
    },
}

Config.Voice = {
    DefaultMode = 'NORMAL',
    MaxModeLength = 10,
    PollTalking = true,
    ModeLabels = {
        [1] = 'WHISPER',
        [2] = 'NORMAL',
        [3] = 'SHOUT',
    },
}

Config.Commands = {
    Toggle = {
        Enabled = true,
        Name = 'togglehud',
        Notify = true,
    },
    RadarMap = {
        Enabled = true,
        Name = 'radarmap',
        Notify = true,
    },
    Test = {
        Enabled = true,
        Name = 'nx_hud_test',
    },
}

-- Layout is based on Hud.zip's 1920x1080 Figma reference. The whole group
-- scales from the bottom-left anchor, so it also remains aligned at 16:10/21:9.
Config.Layout = {
    Scale = 1.0,
    Main = {
        Anchor = 'bottom-left',
        Left = 18,
        Bottom = 28,
        Top = 24,
        -- ขยายจาก 410 เป็น 520 เพราะแถววงกลมสถานะยาวขึ้นเป็น 7 วง (เริ่มที่ x=230
        -- ยาวถึง ~503px) ทุกอย่างใน HUD ยึด left/bottom หมด การขยายความกว้างจึงไม่ขยับอะไร
        Width = 520,
        Height = 300,
    },
    Horse = {
        Left = 345,
        Bottom = 4,
        Width = 64,
        Height = 56,
    },
}

Config.RadarMap = {
    -- ปิดแผนที่ radar แบบ custom ของ HUD แล้วกลับไปใช้ minimap ของเกมแทน
    -- โค้ด/markup/CSS ของ radar ยังอยู่ครบ (แค่ไม่ทำงาน) เผื่ออยากเปิดกลับมาใช้ทีหลัง
    Enabled = false,

    -- always = show whenever the HUD is visible
    -- horse  = show only while mounted
    -- off    = never show
    Mode = 'horse',
    SavePlayerPreference = true,
    PreferenceKey = 'nx_hud:radarMode',

    -- ต้องเป็น false ตอน Enabled = false ไม่งั้นเราจะไปซ่อน minimap ของเกมทิ้ง
    -- ทั้งที่ไม่มี radar ของเราขึ้นมาแทน = ผู้เล่นไม่เหลือแผนที่เลย
    HideNativeRadar = false,
    RestoreNativeRadarOnStop = true,
    RestoreNativeRadarType = 2,

    Layout = {
        Left = 0,
        Bottom = 67,
        Size = 210,
        Opacity = 0.98,
    },

    Map = {
        Zoom = 6,
        Theme = 'detailed', -- original | detailed | dark | black
        TileSize = 256,
        CoordinateScale = 0.01552,
        LongitudeOffset = 111.29,
        LatitudeOffset = -63.60,
        TileUrls = {
            original = 'https://s.rsg.sc/sc/images/games/RDR2/map/game/{z}/{x}/{y}.jpg',
            detailed = 'https://map-tiles.b-cdn.net/assets/rdr3/webp/detailed/{z}/{x}_{y}.webp',
            dark = 'https://map-tiles.b-cdn.net/assets/rdr3/webp/darkmode/{z}/{x}_{y}.webp',
            black = 'https://map-tiles.b-cdn.net/assets/rdr3/webp/black/{z}/{x}_{y}.webp',
        },
    },

    Style = {
        Frame = '#0a0907',
        FrameAccent = '#d1a76b',
        Player = '#f5d797',
        PlayerOutline = '#090806',
        Tint = '#c99c54',
        TintOpacity = 0.06,
    },
}

Config.Player = {
    HealthMin = 0,
    HealthMax = 600,
    StaminaFallback = 100,
    StaminaOffset = 0,
}

Config.SecondaryBar = {
    Enabled = true,
    Source = 'stamina',
}

Config.StatusIcons = {
    { key = 'food', icon = 'food', default = 100, enabled = true },
    { key = 'water', icon = 'water', default = 100, enabled = true },
    -- core = ความเครียด (stress) — ค่าสูง = อันตราย → เตือน/แดงตอน "ใกล้เต็ม" ไม่ใช่ใกล้ 0
    -- (alarmHigh กลับเกณฑ์สีเตือนใน NUI เฉพาะวงนี้ ส่วนหลอดเติมตามค่าปกติอยู่แล้ว)
    { key = 'core', icon = 'brain', default = 100, enabled = true, alarmHigh = true },
}

Config.StatusAliases = {
    hunger = 'food',
    food = 'food',
    thirst = 'water',
    water = 'water',
    stress = 'core',
    core = 'core',
}

Config.Horse = {
    HealthMin = 0,
    HealthMax = 1000,
    StaminaFallback = 100,
    ConditionFallback = 100,
    ThirdStatEnabled = true,
}

-- Optional adapters. Other resources may instead use
-- nx_hud:client:updateStatus / nx_hud:client:setVoiceMode.
Config.Providers = {
    PlayerStamina = nil,
    HorseStamina = nil,
    HorseCondition = nil,
    StatusIcons = nil,
}
