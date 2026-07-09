ConfigSv = {}

ConfigSv["Routers"] = {
    ["getNotify"] = "pNotify:SendNotification",
    ["getSetJob"] = "vorp:setJob",
}

ConfigSv["License_Key"] = ""

ConfigSv["NoItemLimit"] = false

ConfigSv["Craft_Table_Sound_Distance"] = 5.0
ConfigSv["Craft_Table_Sound"] = {
    ["Success"] = "success",
    ["Failed"] = "failed"
}

ConfigSv["DiscordCraftingLog"] = false

ConfigSv["Craft_Discord_Log"] = {
    ["Item"] = " ",
    ["Weapon"] = " "
}

ConfigSv["Other_Discord_LogEvent"] = function(player, source, status, item, count, percent, percent_fail, type)
    if type == "item_standard" then
        -- Add custom item crafting log here if needed.
    elseif type == "item_weapon" then
        -- Add custom weapon crafting log here if needed.
    end
end

ConfigSv["Category"] = {
    [1] = {
        name = "อาวุธ",
        list = {
            {
                item = "WEAPON_REVOLVER_NAVY",
                label = "Navy Revolver",
                type = "item_weapon",
                recipe = {
                    [1] = {
                        label = "สูตรประหยัด",
                        title = "สูตรประหยัด",
                        description = "ใช้วัตถุน้อยกว่า แต่มีโอกาสล้มเหลวสูงกว่า",
                        fail_chance = 20,
                        success_rate = 80,
                        max_stack = 2,
                        cost = {
                            ["Money"] = 50,
                        },
                        blueprint = {
                            ["iron"] = 10,
                            ["wood"] = 4,
                            ["mechanism"] = 1,
                        },

                        -- ของที่ต้องมีติดตัวก่อนคราฟ แต่จะไม่ถูกลบตอนคราฟ
                        toolsList = {
                            ["hammer"] = 1,
                        },

                        -- ของที่มีโอกาสได้รับคืนเมื่อคราฟไม่สำเร็จ
                        failedList = {
                            ["iron"] = 2,
                        },

                        -- ตัวอย่างการตั้งการ์ดสูตรบน UI
                        variantCards = {
                            [1] = {
                                label = "ประหยัด",
                                description = "ใช้ของน้อยกว่า แต่เสี่ยงกว่า",
                            },
                        },

                        -- ตัวอย่าง field เสริมที่ recipe รองรับ:
                        -- jobList = { ["gunsmith"] = true },
                        -- allowedJob = "gunsmith",
                        -- giveAmount = 1,
                        -- metadata = {},
                        -- requiredLevel = 1,
                        -- exp = 10,
                        -- craftTime = 5000,
                        -- animation = {},
                    },
                    [2] = {
                        label = "สูตรมาตรฐาน",
                        title = "สูตรมาตรฐาน",
                        description = "ใช้วัตถุดิบมากขึ้น แต่โอกาสสำเร็จสูงกว่า",
                        fail_chance = 10,
                        success_rate = 90,
                        max_stack = 2,
                        cost = {
                            ["Money"] = 100,
                        },
                        blueprint = {
                            ["iron"] = 20,
                            ["wood"] = 8,
                            ["mechanism"] = 2,
                        },
                        toolsList = {
                            ["hammer"] = 1,
                            ["weapon_blueprint"] = 1,
                        },
                        failedList = {
                            ["iron"] = 4,
                            ["mechanism"] = 1,
                        },
                        variantCards = {
                            [1] = {
                                label = "มาตรฐาน",
                                description = "สมดุลระหว่างต้นทุนและโอกาสสำเร็จ",
                            },
                        },
                    },
                },
            },
            {
                item = "WEAPON_REVOLVER_SCHOFIELD",
                label = "Schofield Revolver",
                type = "item_weapon",
                recipe = {
                    [1] = {
                        label = "สูตรหลัก",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 50,
                        cost = {
                            ["Money"] = 10,
                        },
                        blueprint = {
                            ["gunpowder"] = 5,
                            ["shell"] = 5,
                        },
                    },
                },
            },
        }
    },
    [2] = {
        name = "ยา",
        list = {
            {
                item = "herbal_medicine",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สูตรหลัก",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["herbal"] = 5,
                            ["water"] = 2,
                        },
                    },
                },
            },
            {
                item = "bandage",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สูตรหลัก",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["herbal_medicine"] = 2,
                            ["specialherb"] = 5,
                            ["water"] = 2,
                        },
                    },
                },
            },
        }
    },
    [3] = {
        name = "อาหาร",
        list = {
            {
                item = "bread",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สูตรหลัก",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["corn"] = 5,
                        },
                    },
                },
            },
            {
                item = "consumable_chickenpie",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สูตรหลัก",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 20,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["raw_meat"] = 2,
                            ["salt"] = 2,
                        },
                    },
                },
            },
            {
                item = "consumable_chocolatecake",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สูตรหลัก",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 20,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["Black_Berry"] = 2,
                            ["blueberry"] = 2,
                            ["water"] = 2,
                        },
                    },
                },
            },
        }
    },
    [4] = {
        name = "การตีบัตรแต่งตัว",
        list = {
            {
                item = "leatherpurify",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สูตรหลัก",
                        fail_chance = 85,
                        success_rate = 15,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 500,
                        },
                        blueprint = {
                            ["animal_skin"] = 20,
                        },
                    },
                },
            },
        }
    },
    [5] = {
        name = "เหมืองแร่",
        list = {
            {
                item = "tin_ore",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สูตรหลัก",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 40,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["tin_ore_scrap"] = 10,
                        },
                    },
                },
            },
            {
                item = "silvermineral",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สูตรหลัก",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 40,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["silver_ore_scrap"] = 10,
                        },
                    },
                },
            },
            {
                item = "copper_ore",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สูตรหลัก",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 40,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["copper_ore_scrap"] = 10,
                        },
                    },
                },
            },
            {
                item = "gold",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สูตรหลัก",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 40,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["gold_ore_scrap"] = 20,
                        },
                    },
                },
            },
        }
    },
    [6] = {
        name = "วัสดุก่อสร้าง",
        list = {
            {
                item = "plywood",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สูตรหลัก",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 40,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["bark"] = 10,
                        },
                    },
                },
            },
            {
                item = "plank",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สูตรหลัก",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 40,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["sapwood"] = 10,
                        },
                    },
                },
            },
            {
                item = "hardwood",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สูตรหลัก",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 40,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["heartwood"] = 10,
                        },
                    },
                },
            },
        }
    },
    [7] = {
        name = "ชนเผ่า",
        list = {
            {
                item = "tribal_bow",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สูตรหลัก",
                        fail_chance = 50,
                        success_rate = 50,
                        max_stack = 5,
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
                },
            },
            {
                item = "fire_arrow",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สูตรหลัก",
                        fail_chance = 50,
                        success_rate = 50,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["arrow"] = 5,
                            ["fire"] = 2,
                        },
                    },
                },
            },
        }
    },
    [8] = {
        name = "โต๊ะคราฟทั่วไป",
        list = {
            {
                item = "misc_toolbox",
                label = "กล่องเครื่องมือ",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "กล่องเครื่องมือ",
                        fail_chance = 20,
                        success_rate = 80,
                        max_stack = 5,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["mat_iron"] = 5,
                            ["mat_copper"] = 5,
                            ["met_wood_planks"] = 5,
                        },
                    },
                },
            },
            {
                item = "misc_trainbomb",
                label = "ระเบิดลากสาย",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "ระเบิดลากสาย",
                        fail_chance = 65,
                        success_rate = 35,
                        max_stack = 5,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["mat_nitrate"] = 10,
                            ["mat_sulfur"] = 10,
                            ["mat_coal"] = 10,
                            ["met_resin"] = 10,
                        },
                    },
                },
            },
            {
                item = "aed",
                label = "กล่องปฐมพยาบาล",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "กล่องปฐมพยาบาล",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 5,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["job_cotton"] = 5,
                            ["job_mushroom"] = 5,
                            ["job_Yarrow"] = 5,
                            ["met_resin"] = 5,
                            ["met_bark"] = 5,
                        },
                    },
                },
            },
            {
                item = "job_animalfood",
                label = "อาหารสัตว์",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สูตรข้าวโพด-แครอท",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["job_corn"] = 5,
                            ["job_carrot"] = 5,
                        },
                    },
                    [2] = {
                        label = "สูตรเห็ดป่า-โสม",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["job_mushroom"] = 5,
                            ["job_Ginseng"] = 5,
                        },
                    },
                    [3] = {
                        label = "สูตรต้นยาสูบ-ข้าวบาร์เลย์",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["job_tobacco_plant"] = 5,
                            ["job_barley"] = 5,
                        },
                    },
                },
            },
        }
    },
    [9] = {
        name = "อาวุธ Tier 1",
        list = {
            {
                item = "part_mauser_frame",
                label = "Mauser Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Mauser Frame",
                        fail_chance = 40,
                        success_rate = 60,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_necklace"] = 7,
                            ["loot_ring"] = 10,
                            ["loot_watch"] = 6,
                            ["mat_diamond"] = 5,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 1,
                        },
                    },
                },
            },
            {
                item = "part_mauser_barrel",
                label = "Mauser Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Mauser Barrel",
                        fail_chance = 30,
                        success_rate = 70,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_silver_tooth"] = 6,
                            ["loot_ring"] = 7,
                            ["loot_chinese_coin"] = 5,
                            ["mat_ruby"] = 5,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 1,
                        },
                    },
                },
            },
            {
                item = "part_mauser_stock",
                label = "Mauser Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Mauser Stock",
                        fail_chance = 40,
                        success_rate = 60,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_necklace"] = 5,
                            ["loot_earring"] = 7,
                            ["loot_chinese_coin"] = 8,
                            ["mat_emerald"] = 5,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 1,
                        },
                    },
                },
            },
            {
                item = "part_mauser_molds",
                label = "Mauser Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Mauser Molds",
                        fail_chance = 40,
                        success_rate = 60,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 5,
                        },
                    },
                },
            },
            {
                item = "weapon_mauser_pistol",
                label = "Mauser Pistol",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Mauser Pistol",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_mauser_frame"] = 1,
                            ["part_mauser_barrel"] = 1,
                            ["part_mauser_stock"] = 1,
                            ["part_mauser_molds"] = 1,
                            ["misc_toolbox"] = 1,
                        },
                    },
                },
            },
            {
                item = "part_schofield_frame",
                label = "Schofield Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Schofield Frame",
                        fail_chance = 40,
                        success_rate = 60,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_chinese_coin"] = 6,
                            ["loot_ring"] = 5,
                            ["loot_earring"] = 10,
                            ["mat_diamond"] = 5,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 1,
                        },
                    },
                },
            },
            {
                item = "part_schofield_barrel",
                label = "Schofield Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Schofield Barrel",
                        fail_chance = 30,
                        success_rate = 70,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_necklace"] = 10,
                            ["loot_watch"] = 7,
                            ["loot_ring"] = 6,
                            ["mat_ruby"] = 5,
                            ["mat_coal"] = 10,
                            ["misc_toolbox"] = 1,
                        },
                    },
                },
            },
            {
                item = "part_schofield_stock",
                label = "Schofield Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Schofield Stock",
                        fail_chance = 40,
                        success_rate = 60,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_chinese_coin"] = 9,
                            ["loot_silver_tooth"] = 6,
                            ["loot_brooch"] = 7,
                            ["mat_emerald"] = 5,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 1,
                        },
                    },
                },
            },
            {
                item = "part_schofield_molds",
                label = "Schofield Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Schofield Molds",
                        fail_chance = 40,
                        success_rate = 60,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 5,
                        },
                    },
                },
            },
            {
                item = "weapon_schofield_revolver",
                label = "Schofield Revolver",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Schofield Revolver",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_schofield_frame"] = 1,
                            ["part_schofield_barrel"] = 1,
                            ["part_schofield_stock"] = 1,
                            ["part_schofield_molds"] = 1,
                            ["misc_toolbox"] = 1,
                        },
                    },
                },
            },
            {
                item = "part_carbine_frame",
                label = "Carbine Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Carbine Frame",
                        fail_chance = 40,
                        success_rate = 60,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_watch"] = 10,
                            ["loot_necklace"] = 8,
                            ["loot_earring"] = 9,
                            ["mat_diamond"] = 5,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 1,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_carbine_barrel",
                label = "Carbine Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Carbine Barrel",
                        fail_chance = 30,
                        success_rate = 70,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_chinese_coin"] = 8,
                            ["loot_brooch"] = 6,
                            ["loot_ring"] = 6,
                            ["loot_silver_tooth"] = 5,
                            ["mat_ruby"] = 5,
                            ["mat_stone"] = 10,
                            ["misc_toolbox"] = 1,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_carbine_stock",
                label = "Carbine Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Carbine Stock",
                        fail_chance = 40,
                        success_rate = 60,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_necklace"] = 5,
                            ["loot_silver_tooth"] = 9,
                            ["loot_brooch"] = 7,
                            ["mat_emerald"] = 5,
                            ["mat_copper"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 1,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_carbine_molds",
                label = "Carbine Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Carbine Molds",
                        fail_chance = 40,
                        success_rate = 60,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 8,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "weapon_carbine_repeater",
                label = "Carbine Repeater",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Carbine Repeater",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_carbine_frame"] = 1,
                            ["part_carbine_barrel"] = 1,
                            ["part_carbine_stock"] = 1,
                            ["part_carbine_molds"] = 1,
                            ["misc_toolbox"] = 1,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
        }
    },
    [10] = {
        name = "อาวุธ Tier 2",
        list = {
            {
                item = "part_axe_head",
                label = "Axe Head",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Axe Head",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_necklace"] = 10,
                            ["loot_chinese_coin"] = 8,
                            ["loot_silver_tooth"] = 6,
                            ["mat_diamond"] = 10,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 2,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "part_rivet",
                label = "Rivet (Hunter Hatchet)",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Rivet (Hunter Hatchet)",
                        fail_chance = 60,
                        success_rate = 40,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_watch"] = 8,
                            ["loot_brooch"] = 9,
                            ["loot_gold_tooth"] = 8,
                            ["mat_ruby"] = 10,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 2,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "part_axe_handle",
                label = "Axe Handle",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Axe Handle",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_silver_tooth"] = 5,
                            ["loot_ring"] = 6,
                            ["loot_silver_coin"] = 10,
                            ["mat_emerald"] = 10,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 2,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "part_hunter_hatchet_molds",
                label = "Hunter Hatchet Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Hunter Hatchet Molds",
                        fail_chance = 60,
                        success_rate = 40,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 8,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "weapon_hunter_hatchet",
                label = "Hunter Hatchet",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Hunter Hatchet",
                        -- PDF has toolbox=1 here (every other Tier-2 recipe uses 2) - reproduced as documented, may be a source typo.
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_axe_head"] = 1,
                            ["part_rivet"] = 1,
                            ["part_axe_handle"] = 1,
                            ["part_hunter_hatchet_molds"] = 1,
                            ["misc_toolbox"] = 1,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "part_arrowhead",
                label = "Arrowhead",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Arrowhead",
                        fail_chance = 20,
                        success_rate = 80,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["mat_iron"] = 5,
                            ["mat_copper"] = 5,
                            ["mat_stone"] = 5,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "part_arrow_shaft",
                label = "Arrow Shaft",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Arrow Shaft",
                        fail_chance = 20,
                        success_rate = 80,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["mat_iron"] = 5,
                            ["met_wood_sharp"] = 5,
                            ["met_wood_planks"] = 5,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "part_igniter_arrow",
                label = "Igniter arrow",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Igniter arrow",
                        fail_chance = 20,
                        success_rate = 80,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["met_bark"] = 5,
                            ["met_resin"] = 5,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "weapon_fire_arrow",
                label = "Fire Arrow (ธนูไฟ)",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Fire Arrow (ธนูไฟ)",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_arrowhead"] = 1,
                            ["part_arrow_shaft"] = 1,
                            ["part_igniter_arrow"] = 1,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "part_henry_frame",
                label = "Henry Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Henry Frame",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_brooch"] = 6,
                            ["loot_ring"] = 10,
                            ["loot_silver_tooth"] = 9,
                            ["mat_diamond"] = 7,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 2,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_henry_barrel",
                label = "Henry Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Henry Barrel",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_silver_coin"] = 9,
                            ["loot_chinese_coin"] = 4,
                            ["loot_watch"] = 8,
                            ["mat_ruby"] = 8,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 2,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_henry_stock",
                label = "Henry Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Henry Stock",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_ring"] = 8,
                            ["loot_earring"] = 10,
                            ["loot_necklace"] = 5,
                            ["mat_emerald"] = 8,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 2,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_henry_molds",
                label = "Henry Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Henry Molds",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 10,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "weapon_henry_repeater",
                label = "Litchfield Repeater Henry",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Litchfield Repeater Henry",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_henry_frame"] = 1,
                            ["part_henry_barrel"] = 1,
                            ["part_henry_stock"] = 1,
                            ["part_henry_molds"] = 1,
                            ["misc_toolbox"] = 2,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
        }
    },
    [11] = {
        name = "อาวุธ Tier 3",
        list = {
            {
                item = "part_bow_limb",
                label = "Bow Limb",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Bow Limb",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_watch"] = 8,
                            ["loot_silver_tooth"] = 10,
                            ["loot_necklace"] = 6,
                            ["mat_diamond"] = 4,
                            ["mat_iron"] = 10,
                            ["met_wood_sharp"] = 10,
                            ["misc_toolbox"] = 3,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "part_bow_arm",
                label = "Bow Arm",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Bow Arm",
                        fail_chance = 65,
                        success_rate = 35,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_hairpin"] = 5,
                            ["loot_chinese_coin"] = 8,
                            ["loot_gold_tooth"] = 5,
                            ["mat_ruby"] = 5,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 3,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "part_bowstring",
                label = "Bowstring",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Bowstring",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["bear_hide"] = 10,
                            ["bear_claw"] = 10,
                            ["mat_emerald"] = 6,
                            ["met_stick"] = 10,
                            ["hide_medium"] = 10,
                            ["hide_high"] = 10,
                            ["misc_toolbox"] = 3,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "part_bow_molds",
                label = "Bow Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Bow Molds",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 8,
                            ["blueprint_medium"] = 6,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "weapon_bow_large",
                label = "Bow (ธนูใหญ่)",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Bow (ธนูใหญ่)",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_bow_limb"] = 1,
                            ["part_bow_arm"] = 1,
                            ["part_bowstring"] = 1,
                            ["part_bow_molds"] = 1,
                            ["misc_toolbox"] = 3,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "part_semi_pistol_frame",
                label = "Semi-Pistol Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Semi-Pistol Frame",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_brooch"] = 10,
                            ["loot_earring"] = 8,
                            ["loot_gold_tooth"] = 8,
                            ["mat_diamond"] = 6,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 3,
                        },
                    },
                },
            },
            {
                item = "part_semi_pistol_barrel",
                label = "Semi-Pistol Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Semi-Pistol Barrel",
                        fail_chance = 65,
                        success_rate = 35,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_ring"] = 7,
                            ["loot_silver_tooth"] = 8,
                            ["loot_silver_coin"] = 5,
                            ["mat_ruby"] = 6,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 3,
                        },
                    },
                },
            },
            {
                item = "part_semi_pistol_stock",
                label = "Semi-Pistol Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Semi-Pistol Stock",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_watch"] = 6,
                            ["loot_hairpin"] = 7,
                            ["loot_necklace"] = 5,
                            ["mat_emerald"] = 6,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 3,
                        },
                    },
                },
            },
            {
                item = "part_semi_pistol_molds",
                label = "Semi-Pistol Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Semi-Pistol Molds",
                        fail_chance = 60,
                        success_rate = 40,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 9,
                            ["blueprint_medium"] = 7,
                        },
                    },
                },
            },
            {
                item = "weapon_semi_auto_pistol",
                label = "Semi-Automatic Pistol",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Semi-Automatic Pistol",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_semi_pistol_frame"] = 1,
                            ["part_semi_pistol_barrel"] = 1,
                            ["part_semi_pistol_stock"] = 1,
                            ["part_semi_pistol_molds"] = 1,
                            ["misc_toolbox"] = 3,
                        },
                    },
                },
            },
            {
                item = "part_winchester_frame",
                label = "Winchester Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Winchester Frame",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_hairpin"] = 8,
                            ["loot_silver_coin"] = 9,
                            ["loot_silver_tooth"] = 10,
                            ["mat_diamond"] = 8,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 3,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_winchester_barrel",
                label = "Winchester Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Winchester Barrel",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_necklace"] = 10,
                            ["loot_watch"] = 9,
                            ["loot_gold_tooth"] = 9,
                            ["mat_ruby"] = 5,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 3,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_winchester_stock",
                label = "Winchester Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Winchester Stock",
                        -- source sheet lists 7 materials but only 6 quantities; toolbox qty=3 inferred from every other Tier-3 recipe
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_chinese_coin"] = 5,
                            ["loot_earring"] = 8,
                            ["loot_silver_tooth"] = 8,
                            ["mat_emerald"] = 6,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 3,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_winchester_molds",
                label = "Winchester Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Winchester Molds",
                        fail_chance = 60,
                        success_rate = 40,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 10,
                            ["blueprint_medium"] = 8,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "weapon_winchester_repeater",
                label = "Lancaster Repeater Winchester",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Lancaster Repeater Winchester",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_winchester_frame"] = 1,
                            ["part_winchester_barrel"] = 1,
                            ["part_winchester_stock"] = 1,
                            ["part_winchester_molds"] = 1,
                            ["misc_toolbox"] = 3,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
        }
    },
    [12] = {
        name = "อาวุธ Tier 4",
        list = {
            {
                item = "part_navy_frame",
                label = "Navy Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Navy Frame",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_necklace"] = 9,
                            ["loot_earring"] = 8,
                            ["loot_hairpin"] = 10,
                            ["loot_silver_tooth"] = 10,
                            ["mat_diamond"] = 7,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 4,
                        },
                    },
                },
            },
            {
                item = "part_navy_barrel",
                label = "Navy Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Navy Barrel",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_ring"] = 10,
                            ["loot_watch"] = 6,
                            ["loot_gold_tooth"] = 8,
                            ["loot_chinese_coin"] = 8,
                            ["mat_ruby"] = 7,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 4,
                        },
                    },
                },
            },
            {
                item = "part_navy_stock",
                label = "Navy Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Navy Stock",
                        fail_chance = 75,
                        success_rate = 25,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_silver_coin"] = 9,
                            ["loot_brooch"] = 10,
                            ["loot_earring"] = 7,
                            ["mat_emerald"] = 7,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 4,
                        },
                    },
                },
            },
            {
                item = "part_navy_molds",
                label = "Navy Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Navy Molds",
                        fail_chance = 60,
                        success_rate = 40,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 10,
                            ["blueprint_medium"] = 8,
                        },
                    },
                },
            },
            {
                item = "weapon_navy_revolver",
                label = "Navy Revolver",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Navy Revolver",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_navy_frame"] = 1,
                            ["part_navy_barrel"] = 1,
                            ["part_navy_stock"] = 1,
                            ["part_navy_molds"] = 1,
                            ["misc_toolbox"] = 4,
                        },
                    },
                },
            },
            {
                item = "part_double_barrel_frame",
                label = "Double Barrel Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Double Barrel Frame",
                        fail_chance = 75,
                        success_rate = 25,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_gold_tooth"] = 10,
                            ["loot_silver_tooth"] = 9,
                            ["loot_earring"] = 10,
                            ["loot_watch"] = 5,
                            ["mat_diamond"] = 8,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 4,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_double_barrel_barrel",
                label = "Double Barrel Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Double Barrel Barrel",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_necklace"] = 7,
                            ["loot_silver_coin"] = 10,
                            ["loot_brooch"] = 10,
                            ["loot_ring"] = 6,
                            ["mat_ruby"] = 8,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 4,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_double_barrel_stock",
                label = "Double Barrel Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Double Barrel Stock",
                        fail_chance = 75,
                        success_rate = 25,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_chinese_coin"] = 9,
                            ["loot_brooch"] = 8,
                            ["loot_hairpin"] = 10,
                            ["loot_earring"] = 7,
                            ["mat_emerald"] = 8,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 4,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_double_barrel_molds",
                label = "Double Barrel Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Double Barrel Molds",
                        fail_chance = 60,
                        success_rate = 40,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 10,
                            ["blueprint_medium"] = 9,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "weapon_double_barrel",
                label = "Double Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Double Barrel",
                        -- source row lists only the 4 parts (toolbox label missing) but the qty column has a 5th value (4) matching the tier pattern; included as inferred
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_double_barrel_frame"] = 1,
                            ["part_double_barrel_barrel"] = 1,
                            ["part_double_barrel_stock"] = 1,
                            ["part_double_barrel_molds"] = 1,
                            ["misc_toolbox"] = 4,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_machete_blade",
                label = "Machete Blade",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Machete Blade",
                        fail_chance = 75,
                        success_rate = 25,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_necklace"] = 8,
                            ["loot_ring"] = 5,
                            ["loot_watch"] = 7,
                            ["loot_gold_tooth"] = 6,
                            ["mat_diamond"] = 6,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 4,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_machete_tang",
                label = "Machete Tang",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Machete Tang",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_earring"] = 7,
                            ["loot_silver_tooth"] = 9,
                            ["loot_silver_coin"] = 8,
                            ["loot_hairpin"] = 6,
                            ["mat_ruby"] = 5,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 4,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_machete_stock",
                label = "Machete Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Machete Stock",
                        fail_chance = 65,
                        success_rate = 35,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_brooch"] = 8,
                            ["loot_chinese_coin"] = 7,
                            ["loot_earring"] = 10,
                            ["mat_emerald"] = 6,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 4,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_machete_molds",
                label = "Machete Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Machete Molds",
                        fail_chance = 50,
                        success_rate = 50,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 5,
                            ["blueprint_medium"] = 7,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "weapon_machete",
                label = "Machete",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Machete",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_machete_blade"] = 1,
                            ["part_machete_tang"] = 1,
                            ["part_machete_stock"] = 1,
                            ["part_machete_molds"] = 1,
                            ["misc_toolbox"] = 4,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
        }
    },
    [13] = {
        name = "อาวุธ Tier 5",
        list = {
            {
                item = "part_springfield_frame",
                label = "Springfield Rifle Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Springfield Rifle Frame",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_nail"] = 7,
                            ["loot_gold_tooth"] = 10,
                            ["loot_earring"] = 10,
                            ["loot_brooch"] = 8,
                            ["mat_diamond"] = 7,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 5,
                        },
                    },
                },
            },
            {
                item = "part_springfield_barrel",
                label = "Springfield Rifle Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Springfield Rifle Barrel",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_nail"] = 5,
                            ["loot_hairpin"] = 10,
                            ["loot_watch"] = 7,
                            ["loot_necklace"] = 10,
                            ["mat_ruby"] = 7,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 5,
                        },
                    },
                },
            },
            {
                item = "part_springfield_stock",
                label = "Springfield Rifle Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Springfield Rifle Stock",
                        fail_chance = 75,
                        success_rate = 25,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_silver_coin"] = 7,
                            ["loot_silver_tooth"] = 8,
                            ["loot_gold_tooth"] = 5,
                            ["loot_ring"] = 7,
                            ["mat_emerald"] = 7,
                            ["rock_salt"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 5,
                        },
                    },
                },
            },
            {
                item = "part_springfield_molds",
                label = "Springfield Rifle Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Springfield Rifle Molds",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 10,
                            ["blueprint_medium"] = 8,
                            ["blueprint_high"] = 5,
                        },
                    },
                },
            },
            {
                item = "weapon_springfield_rifle",
                label = "Springfield Rifle",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Springfield Rifle",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_springfield_frame"] = 1,
                            ["part_springfield_barrel"] = 1,
                            ["part_springfield_stock"] = 1,
                            ["part_springfield_molds"] = 1,
                            ["misc_toolbox"] = 5,
                        },
                    },
                },
            },
            {
                item = "part_volcanic_frame",
                label = "Volcanic Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Volcanic Frame",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_ring"] = 4,
                            ["loot_silver_tooth"] = 5,
                            ["loot_earring"] = 6,
                            ["loot_chinese_coin"] = 3,
                            ["mat_diamond"] = 7,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 5,
                        },
                    },
                },
            },
            {
                item = "part_volcanic_barrel",
                label = "Volcanic Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Volcanic Barrel",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_nail"] = 6,
                            ["loot_brooch"] = 5,
                            ["loot_silver_tooth"] = 8,
                            ["loot_necklace"] = 3,
                            ["mat_ruby"] = 7,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 5,
                        },
                    },
                },
            },
            {
                item = "part_volcanic_stock",
                label = "Volcanic Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Volcanic Stock",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_nail"] = 6,
                            ["loot_hairpin"] = 8,
                            ["loot_brooch"] = 4,
                            ["loot_silver_coin"] = 5,
                            ["mat_emerald"] = 7,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 5,
                        },
                    },
                },
            },
            {
                item = "part_volcanic_molds",
                label = "Volcanic Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Volcanic Molds",
                        fail_chance = 60,
                        success_rate = 40,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 5,
                            ["blueprint_medium"] = 6,
                            ["blueprint_high"] = 4,
                        },
                    },
                },
            },
            {
                item = "weapon_volcanic_pistol",
                label = "Volcanic Pistol",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Volcanic Pistol",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_volcanic_frame"] = 1,
                            ["part_volcanic_barrel"] = 1,
                            ["part_volcanic_stock"] = 1,
                            ["part_volcanic_molds"] = 1,
                            ["misc_toolbox"] = 5,
                        },
                    },
                },
            },
            {
                item = "part_lemat_frame",
                label = "LeMat Revolver Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "LeMat Revolver Frame",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_ring"] = 7,
                            ["loot_silver_tooth"] = 5,
                            ["loot_earring"] = 6,
                            ["loot_chinese_coin"] = 3,
                            ["mat_diamond"] = 7,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 5,
                        },
                    },
                },
            },
            {
                item = "part_lemat_barrel",
                label = "LeMat Revolver Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "LeMat Revolver Barrel",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_nail"] = 6,
                            ["loot_brooch"] = 5,
                            ["loot_silver_tooth"] = 5,
                            ["loot_necklace"] = 3,
                            ["mat_ruby"] = 7,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 5,
                        },
                    },
                },
            },
            {
                item = "part_lemat_stock",
                label = "LeMat Revolver Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "LeMat Revolver Stock",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_nail"] = 6,
                            ["loot_hairpin"] = 5,
                            ["loot_brooch"] = 4,
                            ["loot_silver_coin"] = 5,
                            ["mat_emerald"] = 7,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 5,
                        },
                    },
                },
            },
            {
                item = "part_lemat_molds",
                label = "LeMat Revolver Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "LeMat Revolver Molds",
                        fail_chance = 60,
                        success_rate = 40,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 5,
                            ["blueprint_medium"] = 8,
                            ["blueprint_high"] = 6,
                        },
                    },
                },
            },
            {
                item = "weapon_lemat_revolver",
                label = "LeMat Revolver",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "LeMat Revolver",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_lemat_frame"] = 1,
                            ["part_lemat_barrel"] = 1,
                            ["part_lemat_stock"] = 1,
                            ["part_lemat_molds"] = 1,
                            ["misc_toolbox"] = 5,
                        },
                    },
                },
            },
        }
    },
    [14] = {
        name = "อาวุธ Tier 6",
        list = {
            {
                item = "part_tomahawk_head",
                label = "Tomahawk Head",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Tomahawk Head",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_nail"] = 10,
                            ["loot_hairpin"] = 8,
                            ["loot_silver_tooth"] = 6,
                            ["loot_gold_tooth"] = 7,
                            ["loot_ring"] = 9,
                            ["mat_diamond"] = 5,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 6,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "part_rivet",
                label = "Rivet (Tomahawk)",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Rivet (Tomahawk)",
                        fail_chance = 75,
                        success_rate = 25,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_nail"] = 10,
                            ["loot_necklace"] = 5,
                            ["loot_watch"] = 8,
                            ["loot_silver_coin"] = 8,
                            ["loot_brooch"] = 7,
                            ["mat_ruby"] = 5,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 6,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "part_tomahawk_stock",
                label = "Tomahawk Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Tomahawk Stock",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_nail"] = 10,
                            ["loot_chinese_coin"] = 7,
                            ["loot_gold_tooth"] = 5,
                            ["loot_silver_coin"] = 5,
                            ["mat_emerald"] = 7,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 6,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "part_tomahawk_molds",
                label = "Tomahawk Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Tomahawk Molds",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 8,
                            ["blueprint_medium"] = 6,
                            ["blueprint_high"] = 8,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "weapon_tomahawk",
                label = "Tomahawk",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Tomahawk",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_tomahawk_head"] = 1,
                            ["part_rivet"] = 1,
                            ["part_tomahawk_stock"] = 1,
                            ["part_tomahawk_molds"] = 1,
                            ["misc_toolbox"] = 6,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "part_repeating_frame",
                label = "RepeatingFrame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "RepeatingFrame",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_nail"] = 10,
                            ["loot_necklace"] = 6,
                            ["loot_ring"] = 5,
                            ["loot_brooch"] = 6,
                            ["mat_diamond"] = 7,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 6,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_repeating_barrel",
                label = "Repeating Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Repeating Barrel",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_nail"] = 10,
                            ["loot_earring"] = 7,
                            ["loot_gold_tooth"] = 8,
                            ["loot_silver_tooth"] = 5,
                            ["mat_ruby"] = 7,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 6,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_repeating_stock",
                label = "Repeating Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Repeating Stock",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_nail"] = 10,
                            ["loot_hairpin"] = 7,
                            ["loot_silver_coin"] = 5,
                            ["loot_earring"] = 5,
                            ["mat_emerald"] = 5,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 6,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_repeating_molds",
                label = "Repeating Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Repeating Molds",
                        fail_chance = 75,
                        success_rate = 25,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 7,
                            ["blueprint_medium"] = 9,
                            ["blueprint_high"] = 9,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "weapon_repeating_shotgun",
                label = "Repeating Shotgun",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Repeating Shotgun",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_repeating_frame"] = 1,
                            ["part_repeating_barrel"] = 1,
                            ["part_repeating_stock"] = 1,
                            ["part_repeating_molds"] = 1,
                            ["misc_toolbox"] = 6,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
        }
    },
    [15] = {
        name = "อาวุธ Tier 7",
        list = {
            {
                item = "part_m1899_frame",
                label = "M1899 Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "M1899 Frame",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bangle"] = 10,
                            ["loot_gold_tooth"] = 5,
                            ["loot_silver_coin"] = 7,
                            ["loot_hairpin"] = 6,
                            ["mat_diamond"] = 7,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 7,
                        },
                    },
                },
            },
            {
                item = "part_m1899_barrel",
                label = "M1899 Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "M1899 Barrel",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bangle"] = 10,
                            ["loot_nail"] = 7,
                            ["loot_necklace"] = 7,
                            ["loot_ring"] = 8,
                            ["mat_ruby"] = 7,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 7,
                        },
                    },
                },
            },
            {
                item = "part_m1899_stock",
                label = "M1899 Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "M1899 Stock",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bangle"] = 10,
                            ["loot_watch"] = 7,
                            ["loot_chinese_coin"] = 9,
                            ["loot_earring"] = 5,
                            ["mat_emerald"] = 7,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 7,
                        },
                    },
                },
            },
            {
                item = "part_m1899_molds",
                label = "M1899 Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "M1899 Molds",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 5,
                            ["blueprint_medium"] = 9,
                            ["blueprint_high"] = 7,
                            ["blueprint_ultra"] = 3,
                        },
                    },
                },
            },
            {
                item = "weapon_m1899_pistol",
                label = "M1899 Pistol",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "M1899 Pistol",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_m1899_frame"] = 1,
                            ["part_m1899_barrel"] = 1,
                            ["part_m1899_stock"] = 1,
                            ["part_m1899_molds"] = 1,
                            ["misc_toolbox"] = 7,
                        },
                    },
                },
            },
            {
                item = "part_evans_frame",
                label = "Evans Repeater Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Evans Repeater Frame",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bangle"] = 10,
                            ["loot_earring"] = 6,
                            ["loot_gold_tooth"] = 5,
                            ["loot_ring"] = 8,
                            ["mat_diamond"] = 8,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 7,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_evans_barrel",
                label = "Evans Repeater Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Evans Repeater Barrel",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bangle"] = 10,
                            ["loot_necklace"] = 9,
                            ["loot_watch"] = 8,
                            ["loot_silver_coin"] = 7,
                            ["mat_ruby"] = 8,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 7,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_evans_stock",
                label = "Evans Repeater Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Evans Repeater Stock",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bangle"] = 10,
                            ["loot_hairpin"] = 8,
                            ["loot_nail"] = 9,
                            ["loot_silver_tooth"] = 6,
                            ["mat_emerald"] = 8,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 7,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_evans_molds",
                label = "Evans Repeater Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Evans Repeater Molds",
                        fail_chance = 75,
                        success_rate = 25,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 8,
                            ["blueprint_medium"] = 5,
                            ["blueprint_high"] = 7,
                            ["blueprint_ultra"] = 5,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "weapon_evans_repeater",
                label = "Evans Repeater",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Evans Repeater",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_evans_frame"] = 1,
                            ["part_evans_barrel"] = 1,
                            ["part_evans_stock"] = 1,
                            ["part_evans_molds"] = 1,
                            ["misc_toolbox"] = 7,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
        }
    },
    [16] = {
        name = "อาวุธ Tier 8",
        list = {
            {
                item = "part_bolt_action_frame",
                label = "Bolt Action Rifle Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Bolt Action Rifle Frame",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bangle"] = 10,
                            ["loot_brooch"] = 7,
                            ["loot_silver_tooth"] = 8,
                            ["loot_hairpin"] = 8,
                            ["mat_diamond"] = 9,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 8,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_bolt_action_barrel",
                label = "Bolt Action Rifle Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Bolt Action Rifle Barrel",
                        fail_chance = 85,
                        success_rate = 15,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bangle"] = 9,
                            ["loot_gold_tooth"] = 9,
                            ["loot_watch"] = 7,
                            ["loot_chinese_coin"] = 8,
                            ["mat_ruby"] = 9,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 8,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_bolt_action_stock",
                label = "Bolt Action Rifle Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Bolt Action Rifle Stock",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bangle"] = 7,
                            ["loot_nail"] = 10,
                            ["loot_silver_coin"] = 10,
                            ["loot_earring"] = 8,
                            ["mat_emerald"] = 7,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 8,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_bolt_action_molds",
                label = "Bolt Action Rifle Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Bolt Action Rifle Molds",
                        fail_chance = 80,
                        success_rate = 20,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 9,
                            ["blueprint_medium"] = 9,
                            ["blueprint_high"] = 7,
                            ["blueprint_ultra"] = 8,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "weapon_bolt_action_rifle",
                label = "Bolt Action Rifle",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Bolt Action Rifle",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_bolt_action_frame"] = 1,
                            ["part_bolt_action_barrel"] = 1,
                            ["part_bolt_action_stock"] = 1,
                            ["part_bolt_action_molds"] = 1,
                            ["misc_toolbox"] = 8,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_bottle",
                label = "Bottle",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Bottle",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_gold_tooth"] = 6,
                            ["loot_brooch"] = 8,
                            ["loot_nail"] = 5,
                            ["mat_diamond"] = 9,
                            ["mat_emerald"] = 8,
                            ["mat_ruby"] = 9,
                            ["mat_iron"] = 10,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "part_wick",
                label = "Wick",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Wick",
                        fail_chance = 70,
                        success_rate = 30,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bangle"] = 7,
                            ["met_resin"] = 10,
                            ["mat_coal"] = 10,
                            ["mat_nitrate"] = 10,
                            ["mat_sulfur"] = 10,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
            {
                item = "weapon_fire_bottle",
                label = "Fire Bottle",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Fire Bottle",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_bottle"] = 1,
                            ["part_wick"] = 1,
                        },
                        jobList = { ["native"] = true },
                    },
                },
            },
        }
    },
    [17] = {
        name = "อาวุธ Tier 9",
        list = {
            {
                item = "part_rolling_block_frame",
                label = "Rolling Block Rifle Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Rolling Block Rifle Frame",
                        fail_chance = 85,
                        success_rate = 15,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bracelet"] = 10,
                            ["loot_mirror"] = 10,
                            ["loot_bangle"] = 7,
                            ["loot_gold_tooth"] = 8,
                            ["loot_earring"] = 9,
                            ["mat_diamond"] = 10,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 9,
                        },
                    },
                },
            },
            {
                item = "part_rolling_block_barrel",
                label = "Rolling Block Rifle Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Rolling Block Rifle Barrel",
                        fail_chance = 85,
                        success_rate = 15,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bracelet"] = 10,
                            ["loot_mirror"] = 9,
                            ["loot_bangle"] = 10,
                            ["loot_nail"] = 8,
                            ["loot_silver_tooth"] = 7,
                            ["mat_ruby"] = 10,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 9,
                        },
                    },
                },
            },
            {
                item = "part_rolling_block_stock",
                label = "Rolling Block Rifle Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Rolling Block Rifle Stock",
                        fail_chance = 90,
                        success_rate = 10,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bracelet"] = 10,
                            ["loot_mirror"] = 9,
                            ["loot_bangle"] = 7,
                            ["loot_hairpin"] = 9,
                            ["loot_watch"] = 8,
                            ["mat_emerald"] = 10,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 9,
                        },
                    },
                },
            },
            {
                item = "part_rolling_block_molds",
                label = "Rolling Block Rifle Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Rolling Block Rifle Molds",
                        fail_chance = 85,
                        success_rate = 15,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 10,
                            ["blueprint_medium"] = 10,
                            ["blueprint_high"] = 8,
                            ["blueprint_ultra"] = 8,
                            ["blueprint_rare"] = 6,
                        },
                    },
                },
            },
            {
                item = "weapon_rolling_block_rifle",
                label = "Rolling Block Rifle",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Rolling Block Rifle",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_rolling_block_frame"] = 1,
                            ["part_rolling_block_barrel"] = 1,
                            ["part_rolling_block_stock"] = 1,
                            ["part_rolling_block_molds"] = 1,
                            ["misc_toolbox"] = 9,
                        },
                    },
                },
            },
            {
                item = "part_pump_action_frame",
                label = "Pump-Action Shotgun Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Pump-Action Shotgun Frame",
                        fail_chance = 90,
                        success_rate = 10,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bracelet"] = 10,
                            ["loot_mirror"] = 10,
                            ["loot_bangle"] = 8,
                            ["loot_earring"] = 9,
                            ["loot_brooch"] = 7,
                            ["mat_diamond"] = 10,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 9,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_pump_action_barrel",
                label = "Pump-Action Shotgun Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Pump-Action Shotgun Barrel",
                        fail_chance = 85,
                        success_rate = 15,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bracelet"] = 10,
                            ["loot_mirror"] = 8,
                            ["loot_bangle"] = 9,
                            ["loot_hairpin"] = 9,
                            ["loot_ring"] = 8,
                            ["mat_ruby"] = 10,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 9,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_pump_action_stock",
                label = "Pump-Action Shotgun Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Pump-Action Shotgun Stock",
                        fail_chance = 85,
                        success_rate = 15,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bracelet"] = 10,
                            ["loot_mirror"] = 9,
                            ["loot_bangle"] = 7,
                            ["loot_nail"] = 9,
                            ["loot_gold_tooth"] = 8,
                            ["mat_emerald"] = 10,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 9,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_pump_action_molds",
                label = "Pump-Action Shotgun Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Pump-Action Shotgun Molds",
                        fail_chance = 85,
                        success_rate = 15,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 10,
                            ["blueprint_medium"] = 10,
                            ["blueprint_high"] = 8,
                            ["blueprint_ultra"] = 9,
                            ["blueprint_rare"] = 8,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "weapon_pump_action_shotgun",
                label = "Pump-Action Shotgun",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Pump-Action Shotgun",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_pump_action_frame"] = 1,
                            ["part_pump_action_barrel"] = 1,
                            ["part_pump_action_stock"] = 1,
                            ["part_pump_action_molds"] = 1,
                            ["misc_toolbox"] = 9,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
        }
    },
    [18] = {
        name = "อาวุธ Tier 10",
        list = {
            {
                item = "part_sawedoff_frame",
                label = "Sawed-Off Shotgun Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Sawed-Off Shotgun Frame",
                        fail_chance = 90,
                        success_rate = 10,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bracelet"] = 10,
                            ["loot_mirror"] = 10,
                            ["loot_bangle"] = 10,
                            ["loot_nail"] = 10,
                            ["loot_hairpin"] = 10,
                            ["mat_diamond"] = 10,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 10,
                        },
                    },
                },
            },
            {
                item = "part_sawedoff_barrel",
                label = "Sawed-Off Shotgun Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Sawed-Off Shotgun Barrel",
                        fail_chance = 85,
                        success_rate = 15,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bracelet"] = 10,
                            ["loot_mirror"] = 10,
                            ["loot_bangle"] = 10,
                            ["loot_earring"] = 10,
                            ["loot_brooch"] = 10,
                            ["mat_ruby"] = 10,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 10,
                        },
                    },
                },
            },
            {
                item = "part_sawedoff_stock",
                label = "Sawed-Off Shotgun Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Sawed-Off Shotgun Stock",
                        fail_chance = 90,
                        success_rate = 10,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bracelet"] = 10,
                            ["loot_mirror"] = 10,
                            ["loot_bangle"] = 10,
                            ["loot_gold_tooth"] = 10,
                            ["loot_silver_tooth"] = 10,
                            ["mat_emerald"] = 10,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 10,
                        },
                    },
                },
            },
            {
                item = "part_sawedoff_molds",
                label = "Sawed-Off Shotgun Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Sawed-Off Shotgun Molds",
                        fail_chance = 90,
                        success_rate = 10,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 10,
                            ["blueprint_medium"] = 10,
                            ["blueprint_high"] = 10,
                            ["blueprint_ultra"] = 10,
                            ["blueprint_rare"] = 10,
                        },
                    },
                },
            },
            {
                item = "weapon_sawedoff_shotgun",
                label = "Sawed-Off Shotgun",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Sawed-Off Shotgun",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_sawedoff_frame"] = 1,
                            ["part_sawedoff_barrel"] = 1,
                            ["part_sawedoff_stock"] = 1,
                            ["part_sawedoff_molds"] = 1,
                            ["misc_toolbox"] = 10,
                        },
                    },
                },
            },
            {
                item = "part_semi_auto_shotgun_frame",
                label = "Semi-Auto Shotgun Frame",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Semi-Auto Shotgun Frame",
                        fail_chance = 85,
                        success_rate = 15,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bracelet"] = 10,
                            ["loot_mirror"] = 10,
                            ["loot_bangle"] = 10,
                            ["loot_necklace"] = 10,
                            ["loot_silver_coin"] = 10,
                            ["mat_diamond"] = 10,
                            ["mat_iron"] = 10,
                            ["misc_toolbox"] = 10,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_semi_auto_shotgun_barrel",
                label = "Semi-Auto Shotgun Barrel",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Semi-Auto Shotgun Barrel",
                        fail_chance = 90,
                        success_rate = 10,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bracelet"] = 10,
                            ["loot_mirror"] = 10,
                            ["loot_bangle"] = 10,
                            ["loot_silver_tooth"] = 10,
                            ["loot_hairpin"] = 10,
                            ["mat_ruby"] = 10,
                            ["mat_copper"] = 10,
                            ["misc_toolbox"] = 10,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_semi_auto_shotgun_stock",
                label = "Semi-Auto Shotgun Stock",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Semi-Auto Shotgun Stock",
                        fail_chance = 90,
                        success_rate = 10,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["loot_bracelet"] = 10,
                            ["loot_mirror"] = 10,
                            ["loot_bangle"] = 10,
                            ["loot_nail"] = 10,
                            ["loot_earring"] = 10,
                            ["mat_emerald"] = 10,
                            ["mat_stone"] = 10,
                            ["met_wood_planks"] = 10,
                            ["misc_toolbox"] = 10,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "part_semi_auto_shotgun_molds",
                label = "Semi-Auto Shotgun Molds",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Semi-Auto Shotgun Molds",
                        fail_chance = 90,
                        success_rate = 10,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["blueprint_low"] = 10,
                            ["blueprint_medium"] = 10,
                            ["blueprint_high"] = 10,
                            ["blueprint_ultra"] = 10,
                            ["blueprint_rare"] = 10,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
            {
                item = "weapon_semi_auto_shotgun",
                label = "Semi-Auto Shotgun",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "Semi-Auto Shotgun",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 1,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["part_semi_auto_shotgun_frame"] = 1,
                            ["part_semi_auto_shotgun_barrel"] = 1,
                            ["part_semi_auto_shotgun_stock"] = 1,
                            ["part_semi_auto_shotgun_molds"] = 1,
                            ["misc_toolbox"] = 10,
                        },
                        jobList = { ["white"] = true },
                    },
                },
            },
        }
    },
    [19] = {
        name = "โต๊ะทำอาหาร Valentine",
        list = {
            {
                item = "food_sugarcane_juice",
                label = "น้ำอ้อย",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "น้ำอ้อย",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["job_sugarcane"] = 5,
                            ["water"] = 1,
                        },
                    },
                },
            },
            {
                item = "food_oxtail_soup",
                label = "ซุปหางวัว",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "ซุปหางวัว",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["meat_large"] = 2,
                            ["job_Yarrow"] = 1,
                            ["job_corn"] = 2,
                            ["job_carrot"] = 3,
                        },
                    },
                },
            },
            {
                item = "food_braised_ribs",
                label = "ตุ๋นซี่โครง",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "ตุ๋นซี่โครง",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["meat_medium"] = 2,
                            ["job_corn"] = 2,
                            ["job_carrot"] = 3,
                        },
                    },
                },
            },
            {
                item = "food_taco",
                label = "ทาโก้",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "ทาโก้",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["meat_small"] = 3,
                            ["job_carrot"] = 4,
                        },
                    },
                },
            },
        }
    },
    [20] = {
        name = "โต๊ะทำอาหาร Rhodes",
        list = {
            {
                item = "food_orange_juice",
                label = "น้ำส้ม",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "น้ำส้ม",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["job_orange"] = 5,
                            ["water"] = 1,
                        },
                    },
                },
            },
            {
                item = "food_beef_stew",
                label = "สตูเนื้อ",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สตูเนื้อ",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["meat_large"] = 2,
                            ["job_tobacco_plant"] = 1,
                            ["job_barley"] = 2,
                            ["job_cotton"] = 3,
                        },
                    },
                },
            },
            {
                item = "food_salted_meat_stew",
                label = "เนื้อตุ๋นเกลือ",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "เนื้อตุ๋นเกลือ",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["meat_medium"] = 2,
                            ["job_barley"] = 2,
                            ["job_cotton"] = 3,
                        },
                    },
                },
            },
            {
                item = "food_pasta_sauce",
                label = "พาสต้าซอส",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "พาสต้าซอส",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["meat_small"] = 3,
                            ["job_barley"] = 4,
                        },
                    },
                },
            },
        }
    },
    [21] = {
        name = "โต๊ะทำอาหาร Annesburg",
        list = {
            {
                item = "food_berry_juice",
                label = "น้ำเบอรี่",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "น้ำเบอรี่",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["job_berry"] = 5,
                            ["water"] = 1,
                        },
                    },
                },
            },
            {
                item = "food_herb_roasted_meat",
                label = "เนื้อย่างสมุนไพร",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "เนื้อย่างสมุนไพร",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["meat_large"] = 2,
                            ["job_mushroom"] = 1,
                            ["job_Ginseng"] = 2,
                            ["job_opium"] = 3,
                        },
                    },
                },
            },
            {
                item = "food_mushroom_rib_soup",
                label = "ต้มซี่โครงเห็ด",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "ต้มซี่โครงเห็ด",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["meat_medium"] = 2,
                            ["job_Ginseng"] = 2,
                            ["job_opium"] = 3,
                        },
                    },
                },
            },
            {
                item = "food_spaghetti",
                label = "สปาเก็ตตี้",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "สปาเก็ตตี้",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 10,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["meat_small"] = 3,
                            ["job_Ginseng"] = 4,
                        },
                    },
                },
            },
        }
    },
    [22] = {
        name = "เหลาไม้",
        list = {
            {
                item = "met_wood_sharp",
                label = "แท่งไม้เหลา",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "แท่งไม้เหลา",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 40,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["met_stick"] = 10,
                        },
                    },
                },
            },
        }
    },
    [23] = {
        name = "ทำไม้แผ่น",
        list = {
            {
                item = "met_wood_planks",
                label = "แผ่นไม้",
                type = "item_standard",
                recipe = {
                    [1] = {
                        label = "แผ่นไม้",
                        fail_chance = 0,
                        success_rate = 100,
                        max_stack = 40,
                        cost = {
                            ["Money"] = 0,
                        },
                        blueprint = {
                            ["met_log"] = 5,
                        },
                    },
                },
            },
        }
    },
}
