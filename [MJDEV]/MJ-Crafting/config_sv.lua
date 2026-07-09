
ConfigSv = {}

ConfigSv["Routers"] = {
	["getNotify"] = "pNotify:SendNotification",
    ["getSetJob"] = "vorp:setJob",
}

ConfigSv["License_Key"] = "" -- หากเปลี่ยนหรือลบทิ้งจะไม่สามารถใช้งานได้

ConfigSv["NoItemLimit"] = false -- ไม่ตรวจว่ามีของในตัวอยู่เท่าไร จะสามารถคราฟของเกินจำนวนได้

ConfigSv["Craft_Table_Sound_Distance"] = 5.0 -- ระยะสูงสุดที่จะได้ยินเสียงหากตั้งค่าเสียงไว้
ConfigSv["Craft_Table_Sound"] = { -- ตารางเสียง กรุณาลงใน html/sound และใส่ใน resource ด้วยก่อนใช้งาน (รองรับ ogg อย่างเดียว) 
	["Success"] = "success", -- ชื่อไฟล์เสียงเมื่อตอนคราฟเสร็จ เช่น success.ogg พิมพืแค่ success
	["Failed"] = "failed" -- ชื่อไฟล์เสียงเมื่อตอนล้มเหลว
}

ConfigSv["DiscordCraftingLog"] = false -- หากปรับเป็น false จะเป็นปิดการใช่งานlogของระบบ ต้องนำ EventของระบบLogอื่นมาวางในฟังชั้น ConfigSv["Other_Discord_LogEvent"]

ConfigSv["Craft_Discord_Log"] = { -- Discord Webhook 
	["Item"] = " ", -- ใส่ webhook สำหรับให้ข้อความไปออกเมื่อคราฟของได้
	["Weapon"] = " " -- ใส่ webhook สำหรับให้ข้อความไปออกเมื่อคราฟปืนได้
}

ConfigSv["Other_Discord_LogEvent"] = function(player ,source ,status ,item ,count ,percent, percent_fail, type)
	if type == "item_standard" then
		-- local sendToDiscord = '' .. player.name .. ' ได้คราฟ ' .. item .. ' จำนวน ' .. count .. ' เปอร์เซน ' .. percent ..''
        -- print(sendToDiscord)
	elseif type == "item_weapon" then 
		-- local sendToDiscord = '' .. player.name .. ' ได้คราฟ ' .. item .. ' จำนวน ' .. count .. ' เปอร์เซน ' .. percent ..''
        -- print(sendToDiscord)
	end
end

ConfigSv["Category"] = {	
    [1] = {
        name = "อาวุธ",
        list = {
            {
                item = "WEAPON_REVOLVER_NAVY",
                fail_chance = 10,         -- โอกาสล้มเหลว 10%
                success_rate = 90,        -- โอกาสตีติด 90%
                max_stack = 2,            -- เก็บในตัวได้ 2 ชิ้น
                cost = {
                    ["Money"] = 50,
                },
                blueprint = {
                    ["iron"] = 10,
                    ["wood"] = 4,
                    ["mechanism"] = 1,
                },
            },
            {
                item = "WEAPON_REVOLVER_SCHOFIELD",
                fail_chance = 0,
                success_rate = 100,       -- โอกาสตีติด 100%
                max_stack = 50,           -- เก็บในตัวได้ 50 นัด
                cost = {
                    ["Money"] = 10,
                },
                blueprint = {
                    ["gunpowder"] = 5,
                    ["shell"] = 5,
                },
            },
        }
    },
    [2] = {
        name = "ยา",
        list = {
            {
                item = "herbal_medicine",
                fail_chance = 0,
                success_rate = 100,  -- โอกาสตีติด 100%
                max_stack = 10,      -- เก็บในตัวได้อย่างละ 10 ชิ้น
                cost = {
                    ["Money"] = 0, 
                },				
                blueprint = {
                    ["herbal"] = 5,
                    ["water"] = 2,
                },
            },
            {
                item = "bandage",
                fail_chance = 0,
                success_rate = 100,  -- โอกาสตีติด 100%
                max_stack = 10,      -- เก็บในตัวได้อย่างละ 10 ชิ้น
                cost = {
                    ["Money"] = 0, 
                },				
                blueprint = {
                    ["herbal_medicine"] = 2,
                    ["specialherb"] = 5,
                    ["water"] = 2,
                },
            },
        }
    },
    [3] = {
        name = "อาหาร",
        list = {
            {
                item = "bread",
                fail_chance = 0,
                success_rate = 100,  -- โอกาสตีติด 100%
                max_stack = 10,      -- เก็บในตัวได้อย่างละ 10 ชิ้น
                cost = {
                    ["Money"] = 0, 
                },				
                blueprint = {
                    ["corn"] = 5,
                },
            },
            {
                item = "consumable_chickenpie",
                fail_chance = 0,
                success_rate = 100,  -- โอกาสตีติด 100%
                max_stack = 20,      -- เก็บในตัวได้อย่างละ 20 ชิ้น
                cost = {
                    ["Money"] = 0, 
                },				
                blueprint = {
                    ["raw_meat"] = 2,
                    ["salt"] = 2,
                },
            },
            {
                item = "consumable_chocolatecake",
                fail_chance = 0,
                success_rate = 100,  -- โอกาสตีติด 100%
                max_stack = 20,      -- เก็บในตัวได้อย่างละ 20 ชิ้น
                cost = {
                    ["Money"] = 0, 
                },				
                blueprint = {
                    ["Black_Berry"] = 2,
                    ["blueberry"] = 2,
                    ["water"] = 2,
                },
            },
        }
    },
    [4] = {
        name = "การตีบัตรแต่งตัว",
        list = {
            {
                item = "leatherpurify",
                fail_chance = 85,
                success_rate = 15,  -- โอกาสตีติด 15%
                max_stack = 10,     -- เก็บในตัวได้อย่างละ 10 ชิ้น
                cost = {
                    ["Money"] = 500,  -- เงินเขียว 500
                },				
                blueprint = {
                    ["animal_skin"] = 20,
                },
            },
        }
    },
    [5] = {
        name = "เหมืองแร่",
        list = {
            {
                item = "tin_ore",
                fail_chance = 0,
                success_rate = 100,  -- โอกาสตีติด 100%
                max_stack = 40,      -- เก็บในตัวได้อย่างละ 40 ชิ้น
                cost = {
                    ["Money"] = 0, 
                },				
                blueprint = {
                    ["tin_ore_scrap"] = 10,
                },
            },
            {
                item = "silvermineral",
                fail_chance = 0,
                success_rate = 100,  -- โอกาสตีติด 100%
                max_stack = 40,      -- เก็บในตัวได้อย่างละ 40 ชิ้น
                cost = {
                    ["Money"] = 0, 
                },				
                blueprint = {
                    ["silver_ore_scrap"] = 10,
                },
            },
            {
                item = "copper_ore",
                fail_chance = 0,
                success_rate = 100,  -- โอกาสตีติด 100%
                max_stack = 40,      -- เก็บในตัวได้อย่างละ 40 ชิ้น
                cost = {
                    ["Money"] = 0, 
                },				
                blueprint = {
                    ["copper_ore_scrap"] = 10,
                },
            },
            {
                item = "gold",
                fail_chance = 0,
                success_rate = 100,  -- โอกาสตีติด 100%
                max_stack = 40,      -- เก็บในตัวได้อย่างละ 40 ชิ้น
                cost = {
                    ["Money"] = 0, 
                },				
                blueprint = {
                    ["gold_ore_scrap"] = 20,
                },
            },
        }
    },
    [6] = {
        name = "วัสดุก่อสร้าง",
        list = {
            {
                item = "plywood",
                fail_chance = 0,
                success_rate = 100,  -- โอกาสตีติด 100%
                max_stack = 40,      -- เก็บในตัวได้อย่างละ 40 ชิ้น
                cost = {
                    ["Money"] = 0, 
                },				
                blueprint = {
                    ["bark"] = 10,
                },
            },
            {
                item = "plank",
                fail_chance = 0,
                success_rate = 100,  -- โอกาสตีติด 100%
                max_stack = 40,      -- เก็บในตัวได้อย่างละ 40 ชิ้น
                cost = {
                    ["Money"] = 0, 
                },				
                blueprint = {
                    ["sapwood"] = 10,
                },
            },
            {
                item = "hardwood",
                fail_chance = 0,
                success_rate = 100,  -- โอกาสตีติด 100%
                max_stack = 40,      -- เก็บในตัวได้อย่างละ 40 ชิ้น
                cost = {
                    ["Money"] = 0, 
                },				
                blueprint = {
                    ["heartwood"] = 10,
                },
            },
        }
    },
    [7] = {
        name = "ชนเผ่า",
        list = {
            {
                item = "tribal_bow",
                fail_chance = 50,
                success_rate = 50,  -- โอกาสตีติด 50%
                max_stack = 5,      -- เก็บในตัวได้อย่างละ 5 ชิ้น
                cost = {
                    ["Money"] = 0, 
                },				
                blueprint = {
                    ["hardwood"] = 30,
                    ["copper_ore"] = 30,
                    ["silver_coin"] = 10,
                    ["coffin_wood"] = 10,
                    ["small_bow"] = 1,
                },
            },
            {
                item = "fire_arrow",
                fail_chance = 50,
                success_rate = 50,  -- โอกาสตีติด 50%
                max_stack = 10,     -- เก็บในตัวได้อย่างละ 10 ชิ้น
                cost = {
                    ["Money"] = 0, 
                },				
                blueprint = {
                    ["arrow"] = 5,
                    ["fire"] = 2,
                },
            },
        }
    },
}




