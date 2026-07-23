Lang = "English"

Config = {
	-- ======================= DEVELOPMENT ============================== --
	Debug                      = false, -- If your server is live set this to false.  to true only if you are testing things

	InventoryOrder             = "weapons", -- Items or weapons what should should first in inventory

	-- relog เข้ามาแล้วให้เด้งอาวุธที่ถืออยู่ตอนออก กลับขึ้นมือเองอัตโนมัติไหม
	--   false = เข้ามาแบบมือเปล่า (อาวุธยังอยู่ในกระเป๋าปกติ หยิบใช้เองได้) — ตามที่ลูกค้าขอ
	--   true  = พฤติกรรมเดิม (re-equip อาวุธที่เคยถือให้อัตโนมัติ)
	RestoreEquippedWeaponsOnLoad = false,

	DevMode                    = false, -- If your server is live set this to false.  to true only if you are testing things (auto load inventory when script restart and before character selection. Alos add /getInv command)

	dbupdater                  = true,
	-- ======================= CONFIGURATION ============================= --
	ShowCharacterNameOnGive    = false, -- When giving an item, show the character name of nearby players instead of their player ID. if set to false, show the player ID

	DoubleClickToUse           = true, -- If toggled to false, items in inventory will right click then left click "use"

	NewPlayers                 = false, -- If you dont want new players to give money or items then set to true. this can avoid cheaters giving stuff on first join

	CoolDownNewPlayer          = 120, -- In seconds how long they have to wait before they can give items or money

	-- GOLD ITEM LIKE DOLLARS
	UseRolItem                 = false, -- To show rol in inventory

	UseGoldItem                = false,

	AddGoldItem                = true,   -- Should there be an item in inventory to represent gold

	AddDollarItem              = true,    -- Should there be an item in inventory to represent dollars

	AddAmmoItem                = false,    -- Should there be an item in inventory to represent the gun belt

	InventorySearchable        = true,    -- Should the search bar appear in inventories

	-- ปิดไว้: เดิม true ทำให้ช่องค้นหาแย่งคีย์บอร์ดโฟกัสทันทีตอนเปิดกระเป๋า — ปุ่มลัด fastslot
	-- (เลข 1-6, ดู client/fastslot.lua) ถูก JS guard กันไม่ให้ยิงตอน target เป็น input/textarea
	-- (html/app.js เจตนาถูกต้อง กันพิมพ์ค้นหาโดนตีความเป็นปุ่มลัด) ผลคือกด 1-6 ทันทีหลังเปิดกระเป๋า
	-- (ก่อนคลิกที่อื่นให้ blur ออกจากช่องค้นหา) เงียบ ดูเหมือนกดติดๆ ดับๆ แบบสุ่ม — ปิด autofocus
	-- ผู้เล่นต้องคลิกช่องค้นหาเองก่อนพิมพ์ (เหมือนกระเป๋า RedM ปกติ) แลกกับ fastslot กดติดเสมอ
	InventorySearchAutoFocus   = false,   -- Search autoofocuses when you type

	DisableDeathInventory      = true,    -- Prevent the ability to access inventory while dead

	OpenKey                    = 0xC1989F95, -- I

	UseFilter                  = true,    -- If true then will use the filter opening inventory

	Filter                     = "OJDominoBlur",

	PickupKey                  = 0x760A9C6F, -- G key PROMPT PICKUP

	discordid                  = true,    -- Turn to true if ur using discord whitelist

	DeleteOnlyDontDrop         = true,   -- If true then dropping items only deletes from inventory and box on the floor is not created

	UseLanternPutOnBelt        = true,    -- If true then lanterns will be put on belt

	UseWeight                  = false,   -- false = use per-item limits and weapon-count limits; ignore character weight capacity

	WeightMeasure              = "kg",    -- Weight measure (kg, lbs, etc)

	DeleteItemOnUseWhenExpired = true,   -- if true items on use that are expired will be deleted

	DeletePickups              = {
		Enable = true, -- if true it will add timer to delete pickups
		Time = 10, -- after this time pick up wll be deleted, IN MINUTES
	},

	DuelWield				   = true,   -- If true duel wielding will be allowed.

	-- =================== CLEAR ITEMS WEAPONS MONEY GOLD ===================== --

	UseClearAll                = false, -- If you want to use the clear item function

	OnPlayerRespawn            = {
		Money = {
			JobLock         = { "police", "doctor" }, -- Wont remove from these jobs
			ClearMoney      = true,          -- If true then removes all money from player
			MoneyPercentage = false,         -- If false wont use percentage if you add number   0.1 = 10% of money user have instead of all
		},
		Items = {
			JobLock       = { "police", "doctor" },
			itemWhiteList = { "consumable_raspberrywater", "ammorevolvernormal" }, -- Dont delete these items
			AllItems      = true,                                         -- If true then removes all items from player
		},
		Weapons = {
			JobLock           = { "police", "doctor" },
			WeaponWhitelisted = { "WEAPON_MELEE_KNIFE", "WEAPON_BOW" }, -- Dont delete these weapons
			AllWeapons        = true,                          -- If true then removes all weapons from player
		},
		Ammo = {
			JobLock = { "police", "doctor" }, -- Wont remove from these jobs
			AllAmmo = true,          -- If true then removes all ammo from player
		},
		Gold = {
			JobLock        = { "police", "doctor" },
			ClearGold      = false,
			GoldPercentage = false,
		}
	},

	-- Weapon count limit. Standard-item limits come from the `items.limit` database column.
	MaxItemsInInventory        = {
		Weapons = 6,
	},

	-- HERE YOU CAN SET THE MAX AMOUNT OF WEAPONS PER JOB (IF YOU WANT)
	JobsAllowed                = {
		police = 10 -- Job name and max weapons allowed dont allow less than the above
	},

	-- FIRST JOIN
	startItems                 = {
		food_sandwich = 10, -- แซนวิช
		food_bread    = 10, -- ขนมปัง
		water         = 10, -- น้ำดื่ม
		food_coffee   = 10, -- กาแฟ
		bandage_s     = 5,  -- ผ้าพันแผลเล็ก
		bandage_xl    = 5,  -- ผ้าพันแผลใหญ่
	},

	startWeapons               = {
		"WEAPON_MELEE_KNIFE" -- WEAPON HASH NAME
	},

	-- Items that dont get added up torwards your max weapon count
	notweapons                 = {
		WEAPON_KIT_BINOCULARS_IMPROVED = true,
		WEAPON_KIT_BINOCULARS = true,
		WEAPON_FISHINGROD = true,
		WEAPON_KIT_CAMERA = true,
		WEAPON_KIT_CAMERA_ADVANCED = true,
		WEAPON_MELEE_LANTERN = true,
		WEAPON_MELEE_DAVY_LANTERN = true,
		WEAPON_MELEE_LANTERN_HALLOWEEN = true,
		WEAPON_KIT_METAL_DETECTOR = true,
		WEAPON_MELEE_HAMMER = true,
		WEAPON_MELEE_KNIFE = true,
	},

	-- Weapons that are considered non throwables
	nonAmmoThrowables          = {
		WEAPON_MELEE_CLEAVER = true,
		WEAPON_MELEE_HATCHET = true,
		WEAPON_MELEE_HATCHET_HUNTER = true
	},

	-- Weapons that dont need serial numbers
	noSerialNumber             = {
		WEAPON_MELEE_KNIFE = true,
		WEAPON_MELEE_KNIFE_JAWBONE = true,
		WEAPON_MELEE_KNIFE_TRADER = true,
		WEAPON_MELEE_KNIFE_CIVIL_WAR = true,
		WEAPON_MELEE_KNIFE_HORROR = true,
		WEAPON_MELEE_KNIFE_MINER = true,
		WEAPON_MELEE_KNIFE_RUSTIC = true,
		WEAPON_MELEE_KNIFE_VAMPIRE = true,
		WEAPON_MELEE_MACHETE = true,
		WEAPON_MELEE_MACHETE_COLLECTOR = true,
		WEAPON_MELEE_HAMMER = true,
		WEAPON_MELEE_TORCH = true,
		WEAPON_MELEE_CLEAVER = true,
		WEAPON_MELEE_HATCHET = true,
		WEAPON_MELEE_HATCHET_HUNTER = true,
		WEAPON_MELEE_HATCHET_DOUBLE_BIT = true,
		WEAPON_KIT_BINOCULARS_IMPROVED = true,
		WEAPON_KIT_BINOCULARS = true,
		WEAPON_KIT_CAMERA = true,
		WEAPON_KIT_CAMERA_ADVANCED = true,
		WEAPON_KIT_METAL_DETECTOR = true,
		WEAPON_MELEE_LANTERN = true,
		WEAPON_MELEE_DAVY_LANTERN = true,
		WEAPON_MELEE_LANTERN_HALLOWEEN = true,
		WEAPON_FISHINGROD = true,
		WEAPON_BOW = true,
		WEAPON_BOW_IMPROVED = true,
		WEAPON_LASSO = true,
		WEAPON_LASSO_REINFORCED = true,
		WEAPON_MOONSHINEJUG_MP = true,
	},

	-- for dropped weapons , some will spawn standing so we modify their rotation
	weaponAdjustments          = {
		WEAPON_MELEE_KNIFE = 90.0,
		WEAPON_BOW = 90.0,
		WEAPON_BOW_IMPROVED = 90.0,
		WEAPON_MELEE_KNIFE_RUSTIC = 90.0,
		WEAPON_MELEE_KNIFE_HORROR = 90.0,
		WEAPON_MELEE_KNIFE_CIVIL_WAR = 90.0,
		WEAPON_MELEE_KNIFE_JAWBONE = 90.0,
		WEAPON_MELEE_KNIFE_MINER = 90.0,
		WEAPON_MELEE_KNIFE_VAMPIRE = 90.0,
		WEAPON_MELEE_HATCHET = 90.0,
		WEAPON_MELEE_HATCHET_HUNTER = 90.0,
		WEAPON_MELEE_HATCHET_DOUBLE_BIT = 90.0,
		WEAPON_MELEE_MACHETE_COLLECTOR = 90.0,
		WEAPON_MELEE_MACHETE = 90.0,
		WEAPON_MELEE_CLEAVER = 90.0,
		WEAPON_MELEE_HAMMER = 90.0,
		WEAPON_FISHINGROD = 90.0,
		-- add here if more need to change rotation
	},
	
    -- FastSlot (control hash ปุ่ม 1-7) ยังใช้อยู่ — client/fastslot.lua อ่านค่าพวกนี้ไปเช็คปุ่ม
    -- แต่ "เฉพาะตอนกระเป๋าเปิด" เท่านั้น (ตอนกระเป๋าปิดไม่แตะ control เลย ดู FastSlotCount ด้านล่าง)
    -- [ไม่ใช้แล้ว] DisableWeaponWheel — เป็นของระบบ fastslot เดิมที่เข้ารหัส ไม่มีโค้ดไหนอ่านแล้ว
    DisableWeaponWheel = true,
	FastSlot = {
		[1] = {
			key = 0xE6F612E4,
			contest = "Item Slot 1"  -- กำหนดคอนเทนต์ที่จะแสดงเมื่อกดปุ่ม 1
		},
		[2] = {
			key = 0x1CE6D9EB,
			contest = "Item Slot 2"  -- กำหนดคอนเทนต์ที่จะแสดงเมื่อกดปุ่ม 2
		},
		[3] = {
			key = 0x4F49CC4C,
			contest = "Item Slot 3"  -- กำหนดคอนเทนต์ที่จะแสดงเมื่อกดปุ่ม 3
		},
		[4] = {
			key = 0x8F9F9E58,
			contest = "Item Slot 4"  -- กำหนดคอนเทนต์ที่จะแสดงเมื่อกดปุ่ม 4
		},
		[5] = {
			key = 0xAB62E997,
			contest = "Item Slot 5"  -- กำหนดคอนเทนต์ที่จะแสดงเมื่อกดปุ่ม 5
		},
		[6] = {
			key = 0xA1FDE2A6,
			contest = "Item Slot 6"  -- เพิ่มไอเทมใน Slot 6
		},
		[7] = {
			key = 0xB03A913B,
			contest = "Item Slot 7"  -- เพิ่มไอเทมใน Slot 7
		},
	},

	-- ===== Fast Slot / Hotbar (ระบบเปิดใหม่ แทน MJDevFastSlot.lua ที่เข้ารหัส) =====
	-- จำนวนช่อง — NUI รองรับ 6 ช่อง (อย่าตั้งเกิน 6 นอกจากจะแก้ html/app.js ด้วย)
	--
	-- ปุ่ม 1-6 ทำงาน "เฉพาะตอนเปิดกระเป๋า" เท่านั้น รับปุ่ม 2 ทางคู่กันกันพลาด:
	--   1) html/app.js ดัก keydown ตอน NUI ได้ keyboard focus แล้วยิง callback UseFastSlot
	--   2) client/fastslot.lua poll control hash (Config.FastSlot ด้านบน) เผื่อ CEF ไม่ได้รับปุ่ม
	-- server มี cooldown 500ms กรองให้เหลือครั้งเดียวถ้าทั้งสองทางยิงพร้อมกัน
	-- ตอนกระเป๋าปิดไม่แตะ control ของเกมเลย ปุ่ม 1-6 จึงเป็นการเลือกอาวุธปกติของเกมเต็มที่
	FastSlotCount = 6,

	-- ===== Global hotkey: Alt + 1..6 ใช้ fast-slot ได้ "ทุกเมื่อ" (กระเป๋าเปิดหรือปิด) =====
	-- ใช้ raw key (virtual key code) ไม่แตะ control ของเกม → Alt+เลข "ไม่ชน" ปุ่มสลับอาวุธ 1-6 ปกติ
	--   true  = เปิด (แนะนำ) — กด Alt ค้าง แล้วกด 1-6 เพื่อใช้ของในช่องนั้นได้เลย ไม่ต้องเปิดกระเป๋า
	--   false = ปิด — ใช้ fast-slot ได้เฉพาะตอนเปิดกระเป๋าแบบเดิม
	FastSlotGlobalHotkey = true,
	-- virtual key code ของปุ่ม modifier (ค่าเริ่ม 0x12 = Alt ซ้าย/ขวา / ถ้าอยากใช้ Ctrl ตั้ง 0x11 / Shift 0x10)
	FastSlotHotkeyModifierVK = 0x12,
	-- dropp items can have a diferent model added them here item name and object
	spawnableProps             = {
		default_box = "p_cottonbox01x", -- default when object is not found will always spawn this object for weapon or items
		money_bag = "p_moneybag02x", -- prop for the money pickup
		gold_bag = "s_pickup_goldbar01x", -- prop for the gold pickup
		-- add more here
	}
}
