

Config = {}

Config["Keys"] = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

Config.Debug = true -- true = print debug ตอนเข้า/ออกระยะโต๊ะคราฟ + เตือนถ้ามีหลายโต๊ะอยู่ในระยะพร้อมกัน (F8 console)
Config["Font"] = "font4thai"	-- รูปแบบตัวอักษร
Config["Keys"] = 'G'
Config["Image_Source"] = "nui://vorp_inventory/html/img/items/" -- ตำแหน่งรูปภาพ
Config["Animation"] = {"mech_inventory@crafting@fallbacks", "full_craft_and_stow"}
Config["Craft_Table"] = {

	-- {
	-- 	Position =  {x = -368.72, y = 795.92, z = 116.28, h = 28.44}, --{x = -368.72, y = 795.92, z = 116.28}
	-- 	Table_Name = "Item Crafting", 
	-- 	Max_Distance = 2.5,
	-- 	Disable_Model = true, -- ปิดโมเดล
    --     -- job = {"police","medic"},
	-- 	Model = GetHashKey and GetHashKey("p_campfirecombined03x") or "p_campfirecombined03x",
	-- 	Name = "~y~Item Crafting",
	-- 	Desc = "Helsing Town",

	-- 	Map_blip = true,
 	-- 	Blip_name = "CraftingTable",
	-- 	Blip_sprite = 12, -- สำหรับเปลี่ยน รูปแบบ ของ blip
	-- 	Blip_scale = 1.2,
	-- 	Blip_color = 47,

	-- 	Category = { 1,2,3 } --Category = { 1,2,3,4,5,6,7 }, -- โต๊ะตัวนี้จะมีหมวดอะไร อิงจาก Config[category]
	-- },

	{
		Position = {x = 1413.1591, y = 273.8957, z = 89.5322, h = 284.6054},
		Table_Name = "General Crafting",
		Max_Distance = 2.5,
		Disable_Model = true,
		Model = GetHashKey and GetHashKey("p_campfirecombined03x") or "p_campfirecombined03x",
		Name = "~y~General Crafting",
		Desc = "โต๊ะคราฟทั่วไป",

		Map_blip = true,
		Blip_name = "GeneralCraftingTable",
		Blip_sprite = -758970771, -- blip_shop_blacksmith
		Blip_scale = 1.2,
		Blip_color = 47,

		Category = { 8 } -- โต๊ะคราฟทั่วไป
	},

	{
		Position = {x = 1415.5193, y = 277.5291, z = 89.5114, h = 111.2098},
		Table_Name = "Weapon Crafting",
		Max_Distance = 2.5,
		Disable_Model = true,
		Model = GetHashKey and GetHashKey("p_campfirecombined03x") or "p_campfirecombined03x",
		Name = "~y~Weapon Crafting",
		Desc = "โต๊ะคราฟอาวุธ",

		Map_blip = true,
		Blip_name = "WeaponCraftingTable",
		Blip_sprite = 1576459965, -- blip_supplies_ammo
		Blip_scale = 1.2,
		Blip_color = 47,

		Category = { 9 } -- เอาแค่ Tier 1 ก่อน (category 9 = "อาวุธ Tier 1" ใน config_sv.lua) Tier 2-10 (category 10-18) ยังไม่ลงโต๊ะ
	},

	-- พิกัดด้านล่างเป็นตำแหน่งคร่าวๆ ใกล้ตัวเมือง ยังไม่ได้วัดจุดจริงในเกม ต้องปรับพิกัดให้ตรงจุดก่อนขึ้นจริง
	{
		Position = {x = -359.5163, y = 742.1522, z = 116.0760, h = -79.3870},
		Table_Name = "Valentine Cooking",
		Max_Distance = 2.5,
		-- จุดนี้มีกาต้มน้ำ (p_kettle03x) อยู่ในแมพของเกมอยู่แล้ว เลยไม่ต้องสร้างซ้อน
		-- ไม่งั้นจะได้ prop ทับกันสองอันตรงจุดเดียว
		Disable_Model = true,
		Model = GetHashKey and GetHashKey("p_kettle03x") or "p_kettle03x", -- อ้างอิงเฉยๆ ไม่ได้ถูกสร้าง (Disable_Model = true)
		Name = "~y~Cooking Table",
		Desc = "โต๊ะทำอาหาร Valentine",

		Map_blip = true,
		Blip_name = "ValentineCookingTable",
		Blip_sprite = -1852063472, -- blip_supplies_food
		Blip_scale = 1.2,
		Blip_color = 47,

		Category = { 19 } -- โต๊ะทำอาหาร Valentine
	},

	{
		Position = {x = 1305.7445, y = -1277.4363, z = 74.9953, h = -66.9541},
		Table_Name = "Rhodes Cooking",
		Max_Distance = 2.5,
		Disable_Model = false,
		Model = GetHashKey and GetHashKey("p_campfirecombined02x") or "p_campfirecombined02x",
		Name = "~y~Cooking Table",
		Desc = "โต๊ะทำอาหาร Rhodes",

		Map_blip = true,
		Blip_name = "RhodesCookingTable",
		Blip_sprite = -1852063472, -- blip_supplies_food
		Blip_scale = 1.2,
		Blip_color = 47,

		Category = { 20 } -- โต๊ะทำอาหาร Rhodes
	},

	{
		Position = {x = 2938.2727, y = 1308.6079, z = 43.5394, h = -109.1218},
		Table_Name = "Annesburg Cooking",
		Max_Distance = 2.5,
		Disable_Model = false,
		Model = GetHashKey and GetHashKey("p_campfirecombined02x") or "p_campfirecombined02x",
		Name = "~y~Cooking Table",
		Desc = "โต๊ะทำอาหาร Annesburg",

		Map_blip = true,
		Blip_name = "AnnesburgCookingTable",
		Blip_sprite = -1852063472, -- blip_supplies_food
		Blip_scale = 1.2,
		Blip_color = 47,

		Category = { 21 } -- โต๊ะทำอาหาร Annesburg
	},

	-- ── โต๊ะงานไม้ (เหลาไม้ + ทำไม้แผ่น) ──────────────────────────────────────
	-- เดิมบล็อกนี้ถูกคอมเมนต์ทิ้งเพราะไม่เคยมีพิกัดจริง (x ว่างจนไฟล์ syntax error ทั้งไฟล์)
	-- ตอนนี้ได้พิกัดที่วัดในเกมแล้ว 3 จุด ใช้ prop p_sawhorse04x เป็นตัวมาร์ก
	{
		Position = {x = -32.0531, y = 1234.1144, z = 171.8039, h = -177.0000},
		Table_Name = "Wood Crafting 1",
		Max_Distance = 2.5,
		Disable_Model = false,
		Model = GetHashKey and GetHashKey("p_sawhorse04x") or "p_sawhorse04x",
		Name = "~y~Wood Crafting",
		Desc = "โต๊ะงานไม้",

		Map_blip = true,
		Blip_name = "WoodCraftingTable1",
		Blip_sprite = -758970771, -- blip_shop_blacksmith
		Blip_scale = 1.2,
		Blip_color = 47,

		Category = { 22 } -- เหลาไม้ + ทำไม้แผ่น
	},

	{
		Position = {x = 3021.0964, y = 1755.0084, z = 82.7649, h = 113.0000},
		Table_Name = "Wood Crafting 2",
		Max_Distance = 2.5,
		Disable_Model = false,
		Model = GetHashKey and GetHashKey("p_sawhorse04x") or "p_sawhorse04x",
		Name = "~y~Wood Crafting",
		Desc = "โต๊ะงานไม้",

		Map_blip = true,
		Blip_name = "WoodCraftingTable2",
		Blip_sprite = -758970771, -- blip_shop_blacksmith
		Blip_scale = 1.2,
		Blip_color = 47,

		Category = { 22 } -- เหลาไม้ + ทำไม้แผ่น
	},

	{
		Position = {x = 674.1143, y = -1253.0436, z = 43.0176, h = -111.0000},
		Table_Name = "Wood Crafting 3",
		Max_Distance = 2.5,
		Disable_Model = false,
		Model = GetHashKey and GetHashKey("p_sawhorse04x") or "p_sawhorse04x",
		Name = "~y~Wood Crafting",
		Desc = "โต๊ะงานไม้",

		Map_blip = true,
		Blip_name = "WoodCraftingTable3",
		Blip_sprite = -758970771, -- blip_shop_blacksmith
		Blip_scale = 1.2,
		Blip_color = 47,

		Category = { 22 } -- เหลาไม้ + ทำไม้แผ่น
	},


	{
		Position = {x = -368.5274, y = 794.9661, z = 116.1981, h = 185.1594},
		Table_Name = "General Crafting - Valentine",
		Max_Distance = 2.5,
		Disable_Model = true,
		Model = GetHashKey and GetHashKey("p_campfirecombined03x") or "p_campfirecombined03x",
		Name = "~y~General Crafting",
		Desc = "โต๊ะคราฟทั่วไป Valentine",

		Map_blip = true,
		Blip_name = "GeneralCraftingTableValentine",
		Blip_sprite = -758970771, -- blip_shop_blacksmith
		Blip_scale = 1.2,
		Blip_color = 47,

		Category = { 8 } -- โต๊ะคราฟทั่วไป
	},

	{
		Position = {x = 2873.5984, y = 1359.5076, z = 62.4794, h = 315.3127},
		Table_Name = "General Crafting - Annesburg",
		Max_Distance = 2.5,
		Disable_Model = true,
		Model = GetHashKey and GetHashKey("p_campfirecombined03x") or "p_campfirecombined03x",
		Name = "~y~General Crafting",
		Desc = "โต๊ะคราฟทั่วไป Annesburg",

		Map_blip = true,
		Blip_name = "GeneralCraftingTableAnnesburg",
		Blip_sprite = -758970771, -- blip_shop_blacksmith
		Blip_scale = 1.2,
		Blip_color = 47,

		Category = { 8 } -- โต๊ะคราฟทั่วไป
	},

	{
		Position = {x = 1259.0687, y = -1323.2338, z = 76.8877, h = 161.0100},
		Table_Name = "General Crafting - Rhodes",
		Max_Distance = 2.5,
		Disable_Model = true,
		Model = GetHashKey and GetHashKey("p_campfirecombined03x") or "p_campfirecombined03x",
		Name = "~y~General Crafting",
		Desc = "โต๊ะคราฟทั่วไป Rhodes",

		Map_blip = true,
		Blip_name = "GeneralCraftingTableRhodes",
		Blip_sprite = -758970771, -- blip_shop_blacksmith
		Blip_scale = 1.2,
		Blip_color = 47,

		Category = { 8 } -- โต๊ะคราฟทั่วไป
	},

}


Config.LsitWeapons = {
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
