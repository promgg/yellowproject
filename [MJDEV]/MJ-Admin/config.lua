Config = {}
-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 

Config["ambulance"] = {
	["server_revive"] = "vorp_core:Client:OnPlayerRevive", 
	["server_reviveall"] = "vorp_core:Client:OnPlayerRevive",
}

-- Controls
Config.ReviveControl = `INPUT_DYNAMIC_SCENARIO` -- E
Config.RespawnControl = `INPUT_RELOAD` -- R
Config.ToggleControl = `INPUT_FRONTEND_X` -- Space
Config.Cooldown = 5000

Config.SetNoclip =  {
	---------------------- NO CLIP ----------------------
	ShowControls = true,
	Controls = {
		goUp = 0xDE794E3E, -- Q
		goDown = 0x26E9DC00, -- Z
		turnLeft = 0x7065027D, -- A
		turnRight = 0xB4E465B4, -- D
		goForward = 0x8FD015D8, -- W
		goBackward = 0xD27782E3, -- S
		changeSpeed = 0x8FFC75D6, -- L-Shift
		camMode = 0x24978A28, -- H
		ShowControls = 0x8AAA0AD4 -- left alt
	},

	Speeds = {
		-- You can add or edit existing speeds with relative label
		{ label = 'Very Slow', speed = 0 },
		{ label = 'Slow', speed = 0.5 },
		{ label = 'Normal', speed = 2 },
		{ label = 'Fast', speed = 10 },
		{ label = 'Very Fast', speed = 15 },
		{ label = 'Max', speed = 29 },
		{ label = 'Max Pro', speed = 35 },
	},

	Offsets = {
		y = 0.2, -- Forward and backward movement speed multiplier
		z = 0.1, -- Upward and downward movement speed multiplier
		h = 1, -- Rotation movement speed multiplier
	},

	FrozenPosition = true,

}

Config["Perms"] = {
	["admin"] = {
		InfiAmmo = true,
		Golden = true,
		CanKick = true,
		CanBanTemp = true,
		CanBanPerm = true,
		CanUnban = true,
		CanAddCash = true,
		CanAddBank = true,
		CanGodmode = true,
		CanGodmodeAll = true,
		CanOpenPlayerInventory = true,
		CanGiveItem = true,
		CanTpWp = true,
		CanTeleport = true,
		CanTeleportAll = true,
		CanSpectate = true,
		CanFreeze = true,
		CanFreezeAll = true,
		CanTargetSkinMenu = true,
		CanSlay = true,
		CanSlayAll = true,
		CanNameAll = true,
		CanStaminaAll = true,
		CanPromote = true,
		CanGiveWeapon = true,
		CanNoClip = true,
		CanSpawnVehicle = true,
		CanAnnounce = true,
		CanSetJob = true,
		CanSetTime = true,
		CanRevive = true,
		CanChangeTime = true,
		CanFreezeTime = true,
		CanChangeWeather = true,
		CanBlackout = true,
		CanFreezeWeather = true
	}
	
}

Config['SETJOB'] = {
    {
        name = "unemployed",          -- ชื่ออาชีพ
        label = "Unemployed",-- ชื่อแสดงของอาชีพ
        ranks = {                   -- รายการตำแหน่งในอาชีพนี้
            { grade = 0, label = "Unemployed" },      -- เกรด 1 ตำแหน่ง Unemployed
        }
    },
    {
        name = "police",          -- ชื่ออาชีพ
        label = "Police's Office",-- ชื่อแสดงของอาชีพ
        ranks = {                   -- รายการตำแหน่งในอาชีพนี้
            { grade = 1, label = "Police" },      -- เกรด 1 ตำแหน่ง Police
            { grade = 2, label = "Sergeant" }     -- เกรด 2 ตำแหน่ง Sergeant
        }
    },
    {
        name = "sheriff",          -- ชื่ออาชีพ
        label = "Sheriff's Office",-- ชื่อแสดงของอาชีพ
        ranks = {                   -- รายการตำแหน่งในอาชีพนี้
            { grade = 1, label = "sheriff" },      -- เกรด 1 ตำแหน่ง sheriff
            { grade = 2, label = "Sergeant" }     -- เกรด 2 ตำแหน่ง Sergeant
        }
    },
    {
        name = "doctor",          -- ชื่ออาชีพ
        label = "Medical Staff",   -- ชื่อแสดงของอาชีพ
        ranks = {                   -- รายการตำแหน่งในอาชีพนี้
            { grade = 1, label = "Paramedic" },   -- เกรด 1 ตำแหน่ง Paramedic
            { grade = 2, label = "Doctor" }       -- เกรด 2 ตำแหน่ง Doctor
        }
    }
}

--------------------รถที่เสกได้โดยแอดมิน----------------------------
-----------------------------------------------------------------
Config['LsitWagons'] = {
    {model = "cart01", label = "Cart 1"},
    {model = "cart02", label = "Cart 2"},
    {model = "cart03", label = "Cart 3"},
    {model = "cart04", label = "Cart 4"},   
    {model = "cart05", label = "Cart 5"},
    {model = "cart06", label = "Cart 6"},
    {model = "cart07", label = "Cart 7"},
    {model = "cart08", label = "Cart 8"},
    {model = "armysupplywagon", label = "Army Supply Wagon"},
    {model = "buggy01", label = "Buggy 1"},
    {model = "buggy02", label = "Buggy 2"},
    {model = "buggy03", label = "Buggy 3"},
    {model = "chuckwagon000x", label = "Chuck Wagon 1"},
    {model = "chuckwagon002x", label = "Chuck Wagon 2"},
    {model = "coach2", label = "Coach 2"},
    {model = "coach3", label = "Coach 3"},
    {model = "coach4", label = "Coach 4"},
    {model = "coach5", label = "Coach 5"},
    {model = "coach6", label = "Coach 6"},
    {model = "coal_wagon", label = "Coal Wagon"},
    {model = "oilwagon01x", label = "Oil Wagon 1"},
    {model = "oilwagon02x", label = "Oil Wagon 2"},
    {model = "policewagon01x", label = "Police Wagon"},
    {model = "wagon02x", label = "Wagon 2"},
    {model = "wagon03x", label = "Wagon 3"},
    {model = "wagon04x", label = "Wagon 4"},
    {model = "wagon05x", label = "Wagon 5"},
    {model = "wagon06x", label = "Wagon 6"},
    {model = "logwagon", label = "Log Wagon"},
    {model = "wagonprison01x", label = "Wagon Prison"},
    {model = "stagecoach001x", label = "Stage Coach 1"},
    {model = "stagecoach002x", label = "Stage Coach 2"},
    {model = "stagecoach003x", label = "Stage Coach 3"},
    {model = "stagecoach004x", label = "Stage Coach 4"},
    {model = "stagecoach005x", label = "Stage Coach 5"},
    {model = "stagecoach006x", label = "Stage Coach 6"},
    {model = "utilliwag", label = "Utility Wagon"},
    {model = "gatchuck", label = "Gat Chuck"},
    {model = "gatchuck_2", label = "Gat Chuck 2"},
    {model = "wagoncircus01x", label = "Wagon Circus 1"},
    {model = "wagoncircus02x", label = "Wagon Circus 2"},
    {model = "wagondairy01x", label = "Wagon Dairy"},
    {model = "wagonwork01x", label = "Wagon Work"},
    {model = "wagontraveller01x", label = "Wagon Traveller"},
    {model = "supplywagon", label = "Supply Wagon 1"},
    {model = "supplywagon2", label = "Supply Wagon 2"},
    {model = "caboose01x", label = "Caboose"},
    {model = "northpassenger01x", label = "North Passenger"},
    {model = "northsteamer01x", label = "North Steamer"},
    {model = "handcart", label = "Handcart"},
    {model = "keelboat", label = "Keelboat"},
    {model = "canoe", label = "Canoe"},
    {model = "canoetreetrunk", label = "Canoe Tree Trunk"},
    {model = "pirogue", label = "Pirogue"},
    {model = "rcboat", label = "RC Boat"},
    {model = "rowboat", label = "Rowboat"},
    {model = "rowboatswamp", label = "Swamp Rowboat"},
    {model = "skiff", label = "Skiff"},
    {model = "ship_guama02", label = "Guama Ship"},
    {model = "ship_nbdguama", label = "NBD Guama Ship"},
    {model = "horseboat", label = "Horse Boat"},
    {model = "breach_cannon", label = "Breach Cannon"},
    {model = "gatling_gun", label = "Gatling Gun"},
    {model = "gatlingmaxim02", label = "Gatling Maxim"},
    {model = "smuggler02", label = "Smuggler"},
    {model = "turbineboat", label = "Turbine Boat"},
    {model = "hotaairballoon01", label = "Hot Air Balloon"},
    {model = "hotchkiss_cannon", label = "Hotchkiss Cannon"},
    {model = "privatecoalcar01x", label = "Private Coal Car"},
    {model = "privatesteamer01x", label = "Private Steamer"},
    {model = "privatedining01x", label = "Private Dining"},
    {model = "privateflatcar01x", label = "Private Flat Car"},
    {model = "privateboxcar04x", label = "Private Box Car 4"},
    {model = "privatebaggage01x", label = "Private Baggage"},
    {model = "privatepassenger01x", label = "Private Passenger"},
    {model = "northflatcar01x", label = "North Flat Car"},
    {model = "northcoalcar01x", label = "North Coal Car"},
    {model = "northpassenger03x", label = "North Passenger 3"},
    {model = "privateboxcar02x", label = "Private Box Car 2"},
    {model = "armoredcar03x", label = "Armored Car"},
    {model = "privateopensleeper02x", label = "Private Open Sleeper"},
    {model = "wintersteamer", label = "Winter Steamer"},
    {model = "wintercoalcar", label = "Winter Coal Car"},
    {model = "privateboxcar01x", label = "Private Box Car 1"},
    {model = "privateobservationcar", label = "Private Observation Car"},
    {model = "privatearmoured", label = "Private Armoured"},
}

Config['LsitWeapons'] = {
    {
        label        = "Lasso",
        Desc        = "Used Up When You Hogtie Someone, The Reinforced one has unlimited hogtie usage",
        AttachPoint = "",             -- TODO add attach point
        name    = "WEAPON_LASSO", -- DONT TOUCH
        Weight      = 0.50,           -- 50 kg
    },
    {
        label        = "Reinforced Lasso",
        Desc        = "No Hogtie Limit",
        AttachPoint = "",
        name    = "WEAPON_LASSO_REINFORCED",
        Weight      = 0.55,
    },
    {
        label = "Knife",
        Desc = "Knife used mainly for skinning animals",
        AttachPoint = "",
        name = "WEAPON_MELEE_KNIFE",
        Weight = 0.33,
    },
    {
        label = "Knife Rustic",
        Desc = "old looking knife, could it be still useful ?",
        AttachPoint = "",
        name = "WEAPON_MELEE_KNIFE_RUSTIC",
        Weight = 0.40,
    },
    {
        label = "Knife Horror",
        Desc = "This knife was used to do plenty of unpleasant things",
        AttachPoint = "",
        name = "WEAPON_MELEE_KNIFE_HORROR",
        Weight = 0.40,
    },
    {
        label = "Knife Civil War",
        Desc = "A knife with a lot of history",
        AttachPoint = "",
        name = "WEAPON_MELEE_KNIFE_CIVIL_WAR",
        Weight = 0.45,
    },
    {
        label = "Knife Jawbone",
        Desc = "A knife made of ancient bones",
        AttachPoint = "",
        name = "WEAPON_MELEE_KNIFE_JAWBONE",
        Weight = 0.37,
    },
    {
        label = "Knife Miner",
        Desc = "Miners bestfriend",
        AttachPoint = "",
        name = "WEAPON_MELEE_KNIFE_MINER",
        Weight = 0.40,
    },
    {
        label = "Knife Vampire",
        Desc = "They cant be real...",
        AttachPoint = "",
        name = "WEAPON_MELEE_KNIFE_VAMPIRE",
        Weight = 0.39,
    },
    {
        label = "Cleaver",
        Desc = "Scary looking but useful",
        AttachPoint = "",
        name = "WEAPON_MELEE_CLEAVER",
        Weight = 0.73,
    },
    {
        label = "Hachet",
        Desc = "A piece of wood with a blade",
        AttachPoint = "",
        name = "WEAPON_MELEE_HATCHET",
        Weight = 1.05,
    },
    {
        label = "Hachet Double Bit",
        Desc = "A Piece of wood with twice the blade",
        AttachPoint = "",
        name = "WEAPON_MELEE_HATCHET_DOUBLE_BIT",
        Weight = 1.15,
    },
    {
        label = "Hachet Hewing",
        Desc = "Some say this hatchet is magical",
        AttachPoint = "",
        name = "WEAPON_MELEE_HATCHET_HEWING",
        Weight = 1.10,
    },
    {
        label = "Hachet Hunter",
        Desc = "A Hunters bestfriend",
        AttachPoint = "",
        name = "WEAPON_MELEE_HATCHET_HUNTER",
        Weight = 1.15,
    },
    {
        label = "Hachet Viking",
        Desc = "Smells of fish and salt",
        AttachPoint = "",
        name = "WEAPON_MELEE_HATCHET_VIKING",
        Weight = 1.20,
    },
    {
        label = "Tomahawk",
        Desc = "A weapon befitting a warrior",
        AttachPoint = "",
        name = "WEAPON_THROWN_TOMAHAWK",
        Weight = 1.30,
    },
    {
        label = "Tomahawk Ancient",
        Desc = "This one is Ancient",
        AttachPoint = "",
        name = "WEAPON_THROWN_TOMAHAWK_ANCIENT",
        Weight = 1.50,
    },
    {
        label = "Throwing Knifes",
        Desc = "Folks love playing with these",
        AttachPoint = "",
        name = "WEAPON_THROWN_THROWING_KNIVES",
        Weight = 1.05,
    },
    {
        label = "Machete",
        Desc = "Useful in the jungle",
        AttachPoint = "",
        name = "WEAPON_MELEE_MACHETE",
        Weight = 1.3,
    },
    {
        label = "Bow",
        Desc = "A Simple but effective weapon",
        AttachPoint = "",
        name = "WEAPON_BOW",
        Weight = 0.85,
    },
    {
        label = "Pistol Semi-Auto",
        Desc = "repeating single-chamber handgun",
        AttachPoint = "",
        name = 'WEAPON_PISTOL_SEMIAUTO',
        Weight = 1.18,
    },
    {
        label = "Pistol Mauser",
        Desc = "semi-automatic pistol that was originally produced by German arms manufacturer Mauser",
        AttachPoint = "",
        name = "WEAPON_PISTOL_MAUSER",
        Weight = 1.13,
    },
    {
        label = "Pistol Volcanic",
        Desc = " an improved version of the Rocket Ball ammunition",
        AttachPoint = "",
        name = "WEAPON_PISTOL_VOLCANIC",
        Weight = 1.10,
    },
    {
        label = "Pistol M1899",
        Desc = "its magazine-loaded ammunition allows for a swift reload",
        AttachPoint = "",
        name = "WEAPON_PISTOL_M1899",
        Weight = 1.15,
    },
    {
        label = "Revolver Schofield",
        Desc = "single-action, cartridge-firing, top-break revolver",
        AttachPoint = "",
        name = "WEAPON_REVOLVER_SCHOFIELD",
        Weight = 1.30,
    },
    {
        label = "Revolver Navy",
        Desc = "cap and ball revolver that was designed by Samuel Colt",
        AttachPoint = "",
        name = "WEAPON_REVOLVER_NAVY",
        Weight = 1.20,
    },
    {
        label = "Revolver Navy Crossover",
        Desc = "a revolver that is also a shotgun",
        AttachPoint = "",
        name = "WEAPON_REVOLVER_NAVY_CROSSOVER",
        Weight = 1.25,
    },
    {
        label = "Revolver Lemat",
        Desc = "a revolver that is also a shotgun",
        AttachPoint = "",
        name = "WEAPON_REVOLVER_LEMAT",
        Weight = 1.86,
    },
    {
        label = "Revolver Double Action",
        Desc = "has a trigger that both cocks the hammer and releases it in one pull ",
        AttachPoint = "",
        name = "WEAPON_REVOLVER_DOUBLEACTION",
        Weight = 0.94,
    },
    {
        label = "Revolver Cattleman",
        Desc = "A cowboys bestfriend",
        AttachPoint = "",
        name = "WEAPON_REVOLVER_CATTLEMAN",
        Weight = 1.04,
    },
    {
        label = "Revolver Cattleman mexican",
        Desc = "a different flavor",
        AttachPoint = "",
        name = "WEAPON_REVOLVER_CATTLEMAN_MEXICAN",
        Weight = 1.04,
    },
    {
        label = "Varmint Rifle",
        Desc = "A rifle useful for hunting critters",
        AttachPoint = "",
        name = "WEAPON_RIFLE_VARMINT",
        Weight = 3.80,
    },
    {
        label = "Winchester Repeater",
        Desc = "lever-action repeating rifles manufactured by the Winchester Repeating Arms Company",
        AttachPoint = "",
        name = "WEAPON_REPEATER_WINCHESTER",
        Weight = 4.30,
    },
    {
        label = "Henry Reapeater",
        Desc = " lever-action tubular magazine rifle",
        AttachPoint = "",
        name = "WEAPON_REPEATER_HENRY",
        Weight = 4.20,
    },
    {
        label = "Evans Repeater",
        Desc = "a lever-action repeating rifle designed by Warren R. Evans as a high capacity rifle",
        AttachPoint = "",
        name = "WEAPON_REPEATER_EVANS",
        Weight = 4.45,
    },
    {
        label = "Carabine Reapeater",
        Desc =
        "A reliable and popular repeating rifle, the Buck Carbine provides medium damage and a decent firing rate",
        AttachPoint = "",
        name = "WEAPON_REPEATER_CARBINE",
        Weight = 4.10,
    },
    {
        label = "Rolling Block Rifle",
        Desc = "Remington Rolling Block is a family of breech-loading rifles",
        AttachPoint = "",
        name = "WEAPON_SNIPERRIFLE_ROLLINGBLOCK",
        Weight = 4.20,
    },
    {
        label = "Carcano Rifle",
        Desc = "The Carcano is an Italian, bolt action rifle",
        AttachPoint = "",
        name = "WEAPON_SNIPERRIFLE_CARCANO",
        Weight = 3.62,
    },
    {
        label = "Springfield Rifle",
        Desc = "Army's standard issue rifle",
        AttachPoint = "",
        name = "WEAPON_RIFLE_SPRINGFIELD",
        Weight = 3.90,
    },
    {
        label = "Elephant Rifle",
        Desc = "Best Weapon for a hunter looking to take down large prey",
        AttachPoint = "",
        name = "WEAPON_RIFLE_ELEPHANT",
        Weight = 12.50,
    },
    {
        label = "BoltAction Rifle",
        Desc = "manual firearm action that is operated by directly manipulating the bolt",
        AttachPoint = "",
        name = "WEAPON_RIFLE_BOLTACTION",
        Weight = 4.08,
    },
    {
        label = "Semi-Auto Shotgun",
        Desc = "a repeating shotgun with a semi-automatic action, capable of automatically chambering a new shell",
        AttachPoint = "",
        name = "WEAPON_SHOTGUN_SEMIAUTO",
        Weight = 3.53,
    },
    {
        label = "Sawedoff Shotgun",
        Desc = "shotgun with a shorter gun barre",
        AttachPoint = "",
        name = "WEAPON_SHOTGUN_SAWEDOFF",
        Weight = 1.90,
    },
    {
        label = "Repeating Shotgun",
        Desc = "The Lancaster Repeating Shotgun",
        AttachPoint = "",
        name = "WEAPON_SHOTGUN_REPEATING",
        Weight = 3.60,
    },
    {
        label = "Double Barrel Exotic Shotgun",
        Desc = "exotic-rarity variant of the Double Barrel Shotgun",
        AttachPoint = "",
        name = "WEAPON_SHOTGUN_DOUBLEBARREL_EXOTIC",
        Weight = 3.71,
    },
    {
        label = "Pump Shotgun",
        Desc = "repeating firearm action that is operated manually by moving a sliding handguard",
        AttachPoint = "",
        name = "WEAPON_SHOTGUN_PUMP",
        Weight = 3.60,
    },
    {
        label = "Double Barrel Shotgun",
        Desc =
        "break-action shotgun with two parallel barrels, allowing two single shots to be fired in quick succession",
        AttachPoint = "",
        name = "WEAPON_SHOTGUN_DOUBLEBARREL",
        Weight = 3.65,
    },
    {
        label = "Camera",
        Desc = "a journalists bestfriend",
        AttachPoint = "",
        name = "WEAPON_KIT_CAMERA",
        Weight = 0.47,
    },
    {
        label = "Improved Binoculars",
        Desc = "See things clearly !",
        AttachPoint = "",
        name = "WEAPON_KIT_BINOCULARS_IMPROVED",
        Weight = 1.50,
    },
    {
        label = "Knife Trader",
        Desc = "a traders bestfriend",
        AttachPoint = "",
        name = "WEAPON_MELEE_KNIFE_TRADER",
        Weight = 0.45,
    },
    {
        label = "Binoculars",
        Desc = "lets you see far things",
        AttachPoint = "",
        name = "WEAPON_KIT_BINOCULARS",
        Weight = 1.45,
    },
    {
        label = "Advanced Camera",
        Desc = "a camera thats slightly technologicaly better",
        AttachPoint = "",
        name = "WEAPON_KIT_CAMERA_ADVANCED",
        Weight = 0.55,
    },
    {
        label = "Lantern",
        Desc = "lets you see better in the dark",
        AttachPoint = "",
        name = "WEAPON_MELEE_LANTERN",
        Weight = 0.56,
    },
    {
        label = "Davy Lantern",
        Desc = "safety lamp for use in flammable atmospheres",
        AttachPoint = "",
        name = "WEAPON_MELEE_DAVY_LANTERN",
        Weight = 0.65,
    },
    {
        label = "Halloween Lantern",
        Desc = "made with a real human skull",
        AttachPoint = "",
        name = "WEAPON_MELEE_LANTERN_HALLOWEEN",
        Weight = 1.20,
    },
    {
        label = "Poison Bottle",
        Desc = "who knows whats in this thing",
        AttachPoint = "",
        name = "WEAPON_THROWN_POISONBOTTLE",
        Weight = 0.35,
    },
    {
        label = "Metal Detector",
        Desc = "helps you find valuables",
        AttachPoint = "",
        name = "WEAPON_KIT_METAL_DETECTOR",
        Weight = 0.45,
    },
    {
        label = "Dynamite",
        Desc = "boomstick",
        AttachPoint = "",
        name = "WEAPON_THROWN_DYNAMITE",
        Weight = 0.19,
    },
    {
        label = "Molotov",
        Desc = "an arsonists bestfriend",
        AttachPoint = "",
        name = "WEAPON_THROWN_MOLOTOV",
        Weight = 0.45,
    },
    {
        label = "Improved Bow",
        Desc = "a bow with better accuracy",
        AttachPoint = "",
        name = "WEAPON_BOW_IMPROVED",
        Weight = 1.10,
    },
    {
        label = "Machete Collector",
        Desc = "every collector needs one",
        AttachPoint = "",
        name = "WEAPON_MELEE_MACHETE_COLLECTOR",
        Weight = 1.40,
    },
    {
        label = "Electric Lantern",
        Desc = "a marvel of technology",
        AttachPoint = "",
        name = "WEAPON_MELEE_LANTERN_ELECTRIC",
        Weight = 0.95,
    },
    {
        label = "Torch",
        Desc = "your basic stick on fire",
        AttachPoint = "",
        name = "WEAPON_MELEE_TORCH",
        Weight = 1.50,
    },
    {
        label = "Moonshine Jug",
        Desc = "those are very fun",
        AttachPoint = "",
        name = "WEAPON_MOONSHINEJUG_MP",
        Weight = 2.00,
    },
    {
        label = "Bolas",
        Desc = "every badass cowboy needs one",
        AttachPoint = "",
        name = "WEAPON_THROWN_BOLAS",
        Weight = 0.55,
    },
    {
        label = "Bolas Hawkmoth",
        Desc = "a bola with a twist",
        AttachPoint = "",
        name = "WEAPON_THROWN_BOLAS_HAWKMOTH",
        Weight = 0.65,
    },
    {
        label = "Bolas Ironspiked",
        Desc = "a more edgy bola",
        AttachPoint = "",
        name = "WEAPON_THROWN_BOLAS_IRONSPIKED",
        Weight = 0.75,
    },
    {
        label = "Bolas Intertwined",
        Desc = "a stronger bola",
        AttachPoint = "",
        name = "WEAPON_THROWN_BOLAS_INTERTWINED",
        Weight = 0.60,
    },
    {
        label = "Fishing Rod",
        Desc = "whats better than catching fish",
        AttachPoint = "",
        name = "WEAPON_FISHINGROD",
        Weight = 1.10,
    },
    {
        label = "Machete Horror",
        Desc = "this one scares people",
        AttachPoint = "",
        name = "WEAPON_MACHETE_HORROR",
        Weight = 1.40,
    },
    {
        label = "Lantern Haloween",
        Desc = "made with a real human skull",
        AttachPoint = "",
        name = "WEAPON_MELEE_LANTERN_HALOWEEN",
        Weight = 0.95,
    },
    {
        label        = "Hammer",
        Desc        = "Richards Hammer!",
        AttachPoint = "",
        name    = "WEAPON_MELEE_HAMMER",
        Weight      = 1.25,
    },
    {
        label        = "High Roller Double-Action Revolver",
        Desc        = "Double-action Revolver with gambler motifs engraved across the weapon",
        AttachPoint = "",
        name    = "WEAPON_REVOLVER_DOUBLEACTION_GAMBLER",
        Weight      = 1.05,
    },
}

Config.AttackTypes = {
	{
		models = {
			`A_C_SharkTiger`,
			`A_C_SharkHammerhead_01`
		},
		animation = {
			dict = "creatures_reptile@alligator@melee@streamed_core",
			name = "attack"
		},
		radius = 3.0,
		force = 2.0,
		damage = 75
	},
	{
		models = {
			`A_C_Alligator_01`,
			`MP_A_C_Alligator_01`
		},
		animation = {
			dict = "creatures_reptile@alligator@melee@streamed_core",
			name = "attack"
		},
		radius = 2.5,
		force = 2.0,
		damage = 25
	},
	{
		models = {
			`A_C_Alligator_02`
		},
		animation = {
			dict = "amb_creatures_reptile@gator_giant@nip_attack",
			name = "nip"
		},
		radius = 3.0,
		force = 2.0,
		damage = 25
	},
	{
		models = {
			`A_C_Badger_01`
		},
		animation = {
			dict = "creatures_mammal@badger@melee",
			name = "nip_attack"
		},
		radius = 2.0,
		force = 1.0,
		damage = 15
	},
	{
		models = {
			`A_C_Bear_01`,
			`A_C_BearBlack_01`,
			`MP_A_C_Bear_01`
		},
		animation = {
			dict = "creatures_mammal@bear@melee@streamed_core",
			name = "attack"
		},
		radius = 3.0,
		force = 5.0,
		damage = 30
	},
	{
		models = {
			`A_C_Beaver_01`,
			`MP_A_C_Beaver_01`
		},
		animation = {
			dict = "creatures_mammal@beaver@melee",
			name = "nip_attack"
		},
		radius = 2.0,
		force = 1.0,
		damage = 15
	},
	{
		models = {
			`A_C_Cougar_01`,
			`A_C_Panther_01`,
			`MP_A_C_Cougar_01`,
			`MP_A_C_Panther_01`
		},
		animation = {
			dict = "creatures_mammal@cougar@melee@streamed_core",
			name = "attack"
		},
		radius = 2.0,
		force = 3.0,
		damage = 20
	},
	{
		models = {
			`A_C_Coyote_01`,
			`MP_A_C_Coyote_01`
		},
		animation = {
			dict = "creatures_mammal@coyote@melee@streamed_core",
			name = "attack"
		},
		radius = 2.5,
		force = 2.0,
		damage = 25
	},
	{
		models = {
			`A_C_DogAmericanFoxhound_01`,
			`A_C_DogAustralianShepherd_01`,
			`A_C_DogBluetickCoonhound_01`,
			`A_C_DogCatahoulaCur_01`,
			`A_C_DogChesBayRetriever_01`,
			`A_C_DogCollie_01`,
			`A_C_DogHobo_01`,
			`A_C_DogHound_01`,
			`A_C_DogHusky_01`,
			`A_C_DogLab_01`,
			`A_C_DogLion_01`,
			`A_C_DogPoodle_01`,
			`A_C_DogRufus_01`,
			`A_C_DogStreet_01`,
			`MP_A_C_DogAmericanFoxhound_01`
		},
		animation = {
			dict = "creatures_mammal@dog_pers@melee@streamed_core",
			name = "attack"
		},
		radius = 2.5,
		force = 2.0,
		damage = 20
	},
	{
		models = {
			`A_C_Muskrat_01`
		},
		animation = {
			dict = "creatures_mammal@muskrat@melee",
			name = "nip_attack"
		},
		radius = 2.0,
		force = 1.0,
		damage = 15
	},
	{
		models = {
			`A_C_Raccoon_01`
		},
		animation = {
			dict = "creatures_mammal@raccoon@melee",
			name = "nip_attack"
		},
		radius = 2.0,
		force = 1.0,
		damage = 15
	},
	{
		models = {
			`A_C_Wolf`,
			`MP_A_C_Wolf_01`,
			`A_C_LionMangy_01`
		},
		animation = {
			dict = "creatures_mammal@wolf@melee@attacks@streamed_core",
			name = "attack"
		},
		radius = 3.0,
		force = 3.0,
		damage = 30
	},
	{
		models = {
			`A_C_Wolf_Medium`
		},
		animation = {
			dict = "creatures_mammal@wolf_medium@melee@attacks@streamed_core",
			name = "attack"
		},
		radius = 3.0,
		force = 3.0,
		damage = 25
	},
	{
		models = {
			`A_C_Wolf_Small`
		},
		animation = {
			dict = "creatures_mammal@wolf_small@melee@attacks@streamed_core",
			name = "attack"
		},
		radius = 3.0,
		force = 3.0,
		damage = 20
	}
}

Config.AttackCooldown = 5000
