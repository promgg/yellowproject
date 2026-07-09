Config = {}

Config.Debug = false
Config.ResourceName = 'nx_hud'

Config.UpdateIntervals = {
    MainHud = 500,
    HorseHud = 500,
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
    StartupReadyDelay = 20000,
    SelectedCharacterDelay = 20000,
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
    Test = {
        Enabled = true,
        Name = 'nx_hud_test',
    },
}

Config.Layout = {
    Scale = 0.7,
    Main = {
        Anchor = 'bottom-left',
        -- RedM keeps the native minimap fixed, so keep this HUD clear of it.
        Left = 300,
        Bottom = 28,
        Top = 24,
        Width = 728,
        Height = 118,
    },
    Horse = {
        Left = 642,
        Top = 45,
        Width = 86,
        Height = 65,
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
    {
        key = 'food',
        icon = 'food',
        default = 100,
        enabled = true,
    },
    {
        key = 'water',
        icon = 'water',
        default = 100,
        enabled = true,
    },
    {
        key = 'core',
        icon = 'core',
        default = 100,
        enabled = true,
    },
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

-- Optional adapters. Other resources can leave these nil and update values through
-- nx_hud:client:updateStatus or nx_hud:client:setVoiceMode instead.
Config.Providers = {
    PlayerStamina = nil,
    HorseStamina = nil,
    HorseCondition = nil,
    StatusIcons = nil,
}
