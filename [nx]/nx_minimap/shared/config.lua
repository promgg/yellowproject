Config = {}

-- Native minimap positioning is superseded by nx_hud's integrated NUI radar.
Config.Enabled = false
Config.Debug = false

-- GTA/FiveM can move these minimap components. RedM builds commonly ignore
-- this position override, so use nx_hud layout to keep custom HUD clear.
Config.Layout = {
    AlignX = 'L',
    AlignY = 'B',
    OffsetX = 0.0,
    OffsetY = -0.30,
    Scale = 1.0,

    Components = {
        minimap = {
            X = -0.0045,
            Y = 0.002,
            W = 0.150,
            H = 0.188888,
        },
        minimap_mask = {
            X = 0.020,
            Y = 0.032,
            W = 0.111,
            H = 0.159,
        },
        minimap_blur = {
            X = -0.030,
            Y = 0.022,
            W = 0.266,
            H = 0.237,
        },
    },
}

Config.Apply = {
    StartDelay = 1500,
    InitialAttempts = 6,
    InitialInterval = 1500,
    Persistent = true,
    PersistentInterval = 1500,
    RefreshBigmap = true,
}

Config.Commands = {
    Apply = 'nx_minimap_apply',
    Reset = 'nx_minimap_reset',
    SetY = 'nx_minimap_y',
}
