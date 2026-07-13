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
        MaxStress = 100000,
        InvertStress = true,
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
        Width = 410,
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
    Enabled = true,

    -- always = show whenever the HUD is visible
    -- horse  = show only while mounted
    -- off    = never show
    Mode = 'horse',
    SavePlayerPreference = true,
    PreferenceKey = 'nx_hud:radarMode',

    HideNativeRadar = true,
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
    { key = 'core', icon = 'brain', default = 100, enabled = true },
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
