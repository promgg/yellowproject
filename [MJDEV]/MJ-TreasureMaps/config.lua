Config = {}

Config.framework = "vorp" --"redemrp" or "vorp" or "rsg"

Config.ShovelItem = "shovel" --inventory name of the shovel item for grave dig
Config.MapItem = "treasuremap" --inventory name of the shovel item for grave dig
Config.DiggingTimer = 15   --seconds

Config.Keys = {
    DrawText3D = "Press [G] To Digging up Treasure.",
    Prompt = 0x760A9C6F,
}

Config.Normal =  { 
    iconDict = "pm_awards_mp",
    iconName = 'awards_set_h_008', 
    color = {r = 0, g = 255, b = 128, a = 250}
}

Config.Treasure = {
    shovel = "p_shovel02x", 
    box   = "p_boxmedburied01x",
    anim = {"amb_work@world_human_gravedig@working@male_b@base", "base"}, -- amb_work@world_human_gravedig@working@male_b@base
    bone = "skel_r_hand",
    pos = {0.06, -0.06, -0.03, 270.0, 165.0, 17.0},
}

Config.Maps = {
    map = "p_cs_newspaper_02x_noanim", 
    anim = {"mech_carry_box", "idle"}, -- amb_work@world_human_gravedig@working@male_b@base
    bone = "SKEL_L_Finger12",
    pos = {
        x = 0.15, 
        y = -0.0399,
        z = 0,
        xr = 0.0,
        yr = 0.0,
        zr = 0.0
    },
}

Config.Bandits = {
    model = 'A_M_M_NEAROUGHTRAVELLERS_01',
    Weapon = 'WEAPON_PISTOL',
    percent = 80,
    random_npc = {1, 3}
}

Config.BlipTreasure = {
    Blips = 'BLIP_STYLE_PICKUP',
    blipName = 'Treasure', 
    blipScale = 0.2 
}

Config.Rewards = {
    {item = "Golden_Currant", count = 1},
    {item = "Golden_Currant_Seed", count = 1},
    {item = "rock", count = 1},
}


Config.PoliceAlert = function()
    TriggerServerEvent('police:server:policeAlert', 'treasure is being robbed')
end

Config.Progressbars = function()
    exports.redemrp_progressbars:DisplayProgressBar(Config.DiggingTimer * 1000, "Digging up treasure....")
end

Config.Texts = {
    Prompt = "Digging",
    TreasureRobbery = "Treasure Robbery",
    TreasureDisplay = "Treasure:",
    CantDoThat = "You cant do that now!",
    TreasureRobbed = "Treasure is already robbed!",
    NoShovel = "No shovel item!",
    FoundItem = "You have found some item!",
}

Config.Textures = {
    cross = {"scoretimer_textures", "scoretimer_generic_cross"},
    locked = {"menu_textures","stamp_locked_rank"},
    tick = {"scoretimer_textures","scoretimer_generic_tick"},
    money = {"inventory_items", "money_moneystack"},
    alert = {"menu_textures", "menu_icon_alert"},
}

Config.treasures = {
    --Rhodes
    [1] = {
        name = "Pirate Treasure", 
        coords = vector3(-375.1724853515625, -1117.2174072265625, 42.17617416381836),
        heading = 26.0788,
    },
	[2] = {
        name = "Island Treasure", 
        coords = vector3(459.523193359375, -1343.9447021484375, 45.0999870300293),
        heading = 26.0788,
    },
	[3] = {
        name = "Dutton Hidden Treasure", 
        coords = vector3(2208.862548828125, -676.1303100585938, 41.74824142456055),
        heading = 26.0788,
    },
	[4] = {
        name = "Bensons Treasure", 
        coords = vector3(1236.1353759765625, 1190.959228515625, 149.29251098632812),
        heading = 26.0788,
    },
	[5] = {
        name = "Colt's Stash", 
        coords = vector3(2465.093994140625, 297.0570068359375, 70.42799377441406),
        heading = 26.0788,
    },
	[6] = {
        name = "Pirate Treasure", 
        coords = vector3(758.05029296875, -849.074462890625, 55.40609741210937),
        heading = 26.0788,
    },
    [7] = {
        name = "Pirate Treasure", 
        coords = vector3(-874.64, 1866.12, 406.04),
        heading = 126.92,
    },
    [8] = {
        name = "Pirate Treasure", 
        coords = vector3(-1789.8, 1703.68, 239.04),
        heading = 126.92,
    },
    [9] = {
        name = "Pirate Treasure", 
        coords = vector3(-946.8124, 2182.4795, 341.8848),
        heading = 296.64,
    },
    [10] = {
        name = "Pirate Treasure", 
        coords = vector3(-6275.64, -3579.8, -31.92),
        heading = 10.04,
    },
}

