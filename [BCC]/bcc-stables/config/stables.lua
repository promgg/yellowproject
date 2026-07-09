Stables = {
	valentine = {
        shop = {
            name = 'Valentine Stable',                  -- Name of Shop on Menu
            prompt = 'Valentine Stable',                -- Text Below the Prompt Button
            distance = 2.0,                             -- Distance Between Player and Shop to Show Menu Prompt
            jobsEnabled = false,                        -- Allow Shop Access to Specified Jobs Only
            jobs = {                                    -- Insert Job and Job Grade - ex. jobs = {{name = 'police', grade = 1},{name = 'doctor', grade = 3}}
                {name = 'police', grade = 1},
                {name = 'doctor', grade = 3}
            },
            hours = {
                active = false,                         -- Shop uses Open and Closed Hours
                open = 7,                               -- Shop Open Time / 24 Hour Clock
                close = 21                              -- Shop Close Time / 24 Hour Clock
            }
        },
        blip = {
            show = true,                                -- Show Blip On Map
            showClosed = true,                          -- Show Blip On Map when Closed (if true, 'show' must be true)
            name = 'Valentine Stable',                  -- Name of Blip on Map
            sprite = 1938782895,                        -- Default: 1258184551
            color = {
                open = 'WHITE',                         -- Shop Open - Default: White - Blip Colors Shown Below
                closed = 'RED',                         -- Shop Closed - Deafault: Red - Blip Colors Shown Below
                job = 'YELLOW_ORANGE'                   -- Shop Job Locked - Default: Yellow - Blip Colors Shown Below
            }
        },
        npc = {
            active = true,                              -- Turn NPC On / Off
            model = 'u_m_m_bwmstablehand_01',           -- Model Used for NPC
            coords = vector3(-365.3135, 791.9982, 116.1748),  -- NPC and Shop Blip Positions
            heading = 91.6457,                          -- NPC Heading
            distance = 100.0                            -- Distance Between Player and Shop for NPC to Spawn
        },
        horse = {
            -- หมายเหตุ: offset จาก npc.coords แบบกะคร่าวๆ (+4,+4) ยังไม่ได้ทดสอบในเกมจริง อาจต้องปรับให้ม้า/กล้องไม่ทับ NPC
            coords = vector3(-361.3135, 795.9982, 116.1748),  -- Horse Spawn and Return Positions
            heading = 271.6457,                         -- Horse Spawn Heading
            camera = vector3(-363.3135, 793.9982, 116.1748),  -- Camera Location to View Horse When In-Menu
        },
        trainerBuy = false,                             -- Only Trainers can Buy Horses from this Stable
	},
    -----------------------------------------------------

	-- strawberry = {
    --     shop = {
    --         name = 'Strawberry Stable',
    --         prompt = 'Strawberry Stable',
    --         distance = 2.0,
    --         jobsEnabled = false,
    --         jobs = {
    --             {name = 'police', grade = 1},
    --             {name = 'doctor', grade = 3}
    --         },
    --         hours = {
    --             active = false,
    --             open = 7,
    --             close = 21
    --         }
    --     },
    --     blip = {
    --         show = true,
    --         showClosed = true,
    --         name = 'Strawberry Stable',
    --         sprite = 1938782895,
    --         color = {
    --             open = 'WHITE',
    --             closed = 'RED',
    --             job = 'YELLOW_ORANGE'
    --         }
    --     },
    --     npc = {
    --         active = true,
    --         model = 'u_m_m_bwmstablehand_01',
    --         coords = vector3(-1817.85, -564.86, 156.06),
    --         heading = 335.86,
    --         distance = 100.0
    --     },
    --     horse = {
    --         coords = vector3(-1823.94, -560.85, 156.06),
    --         heading = 257.86,
    --         camera = vector3(-1822.55, -563.93, 156.13),
    --     },
    --     trainerBuy = false,
	-- },
    -- -----------------------------------------------------

	-- vanhorn = {
    --     shop = {
    --         name = 'Van Horn Stable',
    --         prompt = 'Van Horn Stable',
    --         distance = 2.0,
    --         jobsEnabled = false,
    --         jobs = {
    --             {name = 'police', grade = 1},
    --             {name = 'doctor', grade = 3}
    --         },
    --         hours = {
    --             active = false,
    --             open = 7,
    --             close = 21
    --         }
    --     },
    --     blip = {
    --         show = true,
    --         showClosed = true,
    --         name = 'Van Horn Stable',
    --         sprite = 1938782895,
    --         color = {
    --             open = 'WHITE',
    --             closed = 'RED',
    --             job = 'YELLOW_ORANGE'
    --         }
    --     },
    --     npc = {
    --         active = true,
    --         model = 'u_m_m_bwmstablehand_01',
    --         coords = vector3(2967.53, 792.71, 51.4),
    --         heading = 353.62,
    --         distance = 100.0
    --     },
    --     horse = {
    --         coords = vector3(2971.66, 796.82, 51.4),
    --         heading = 96.54,
    --         camera = vector3(2970.67, 793.65, 51.4),
    --     },
    --     trainerBuy = false
	-- },
    -- -----------------------------------------------------

	-- lemoyne = {
    --     shop = {
    --         name = 'Lemoyne Stable',
    --         prompt = 'Lemoyne Stable',
    --         distance = 2.0,
    --         jobsEnabled = false,
    --         jobs = {
    --             {name = 'police', grade = 1},
    --             {name = 'doctor', grade = 3}
    --         },
    --         hours = {
    --             active = false,
    --             open = 7,
    --             close = 21
    --         }
    --     },
    --     blip = {
    --         show = true,
    --         showClosed = true,
    --         name = 'Lemoyne Stable',
    --         sprite = 1938782895,
    --         color = {
    --             open = 'WHITE',
    --             closed = 'RED',
    --             job = 'YELLOW_ORANGE'
    --         }
    --     },
    --     npc = {
    --         active = true,
    --         model = 'u_m_m_bwmstablehand_01',
    --         coords = vector3(1210.73, -189.78, 101.39),
    --         heading = 107.52,
    --         distance = 100.0
    --     },
    --     horse = {
    --         coords = vector3(1210.5, -196.25, 101.38),
    --         heading = 15.61,
    --         camera = vector3(1211.89, -192.76, 101.46),
    --     },
    --     trainerBuy = false
	-- },
    -- -----------------------------------------------------

	-- saintdenis = {
    --     shop = {
    --         name = 'Saint Denis Stable',
    --         prompt = 'Saint Denis Stable',
    --         distance = 2.0,
    --         jobsEnabled = false,
    --         jobs = {
    --             {name = 'police', grade = 1},
    --             {name = 'doctor', grade = 3}
    --         },
    --         hours = {
    --             active = false,
    --             open = 7,
    --             close = 21
    --         }
    --     },
    --     blip = {
    --         show = true,
    --         showClosed = true,
    --         name = 'Saint Denis Stable',
    --         sprite = 1938782895,
    --         color = {
    --             open = 'WHITE',
    --             closed = 'RED',
    --             job = 'YELLOW_ORANGE'
    --         }
    --     },
    --     npc = {
    --         active = true,
    --         model = 'u_m_m_bwmstablehand_01',
    --         coords = vector3(2505.53, -1453.93, 46.32),
    --         heading = 99.45,
    --         distance = 100.0
    --     },
    --     horse = {
    --         coords = vector3(2502.59, -1438.62, 46.32),
    --         heading = 182.93,
    --         camera = vector3(2505.65, -1441.49, 46.29),
    --     },
    --     trainerBuy = false
	-- },
    -- -----------------------------------------------------

	-- blackwater = {
    --     shop = {
    --         name = 'Blackwater Stable',
    --         prompt = 'Blackwater Stable',
    --         distance = 2.0,
    --         jobsEnabled = false,
    --         jobs = {
    --             {name = 'police', grade = 1},
    --             {name = 'doctor', grade = 3}
    --         },
    --         hours = {
    --             active = false,
    --             open = 7,
    --             close = 21
    --         }
    --     },
    --     blip = {
    --         show = true,
    --         showClosed = true,
    --         name = 'Blackwater Stable',
    --         sprite = 1938782895,
    --         color = {
    --             open = 'WHITE',
    --             closed = 'RED',
    --             job = 'YELLOW_ORANGE'
    --         }
    --     },
    --     npc = {
    --         active = true,
    --         model = 'u_m_m_bwmstablehand_01',
    --         coords = vector3(-871.0, -1369.63, 43.53),
    --         heading = 6.64,
    --         distance = 100.0
    --     },
    --     horse = {
    --         coords = vector3(-864.7, -1366.19, 43.55),
    --         heading = 88.47,
    --         camera = vector3(-867.11, -1368.86, 43.54),
    --     },
    --     trainerBuy = false
	-- },
    -- -----------------------------------------------------

    -- armadillo = {
    --     shop = {
    --         name = 'Armadillo Stable',
    --         prompt = 'Armadillo Stable',
    --         distance = 2.0,
    --         jobsEnabled = false,
    --         jobs = {
    --             {name = 'police', grade = 1},
    --             {name = 'doctor', grade = 3}
    --         },
    --         hours = {
    --             active = false,
    --             open = 7,
    --             close = 21
    --         }
    --     },
    --     blip = {
    --         show = true,
    --         showClosed = true,
    --         name = 'Armadillo Stable',
    --         sprite = 1938782895,
    --         color = {
    --             open = 'WHITE',
    --             closed = 'RED',
    --             job = 'YELLOW_ORANGE'
    --         }
    --     },
    --     npc = {
    --         active = true,
    --         model = 'u_m_m_bwmstablehand_01',
    --         coords = vector3(-3706.91, -2539.68, -13.78),
    --         heading = 358.23,
    --         distance = 100.0
    --     },
    --     horse = {
    --         coords = vector3(-3702.17, -2534.99, -14.02),
    --         heading = 87.22,
    --         camera = vector3(-3704.84, -2537.68, -13.84),
    --     },
    --     trainerBuy = false
	-- },
    -- -----------------------------------------------------

	-- tumbleweed = {
    --     shop = {
    --         name = 'Tumbleweed Stable',
    --         prompt = 'Tumbleweed Stable',
    --         distance = 2.0,
    --         jobsEnabled = false,
    --         jobs = {
    --             {name = 'police', grade = 1},
    --             {name = 'doctor', grade = 3}
    --         },
    --         hours = {
    --             active = false,
    --             open = 7,
    --             close = 21
    --         }
    --     },
    --     blip = {
    --         show = true,
    --         showClosed = true,
    --         name = 'Tumbleweed Stable',
    --         sprite = 1938782895,
    --         color = {
    --             open = 'WHITE',
    --             closed = 'RED',
    --             job = 'YELLOW_ORANGE'
    --         }
    --     },
    --     npc = {
    --         active = true,
    --         model = 'u_m_m_bwmstablehand_01',
    --         coords = vector3(-5515.2, -3040.17, -2.39),
    --         heading = 180.76,
    --         distance = 100.0
    --     },
    --     horse = {
    --         coords = vector3(-5524.48, -3044.31, -2.39),
    --         heading = 263.98,
    --         camera = vector3(-5521.37, -3041.23, -2.39),
    --     },
    --     trainerBuy = false
	-- },
    -- -----------------------------------------------------

	-- guarma = {
    --     shop = {
    --         name = 'Guarma Stable',
    --         prompt = 'Guarma Stable',
    --         distance = 2.0,
    --         jobsEnabled = false,
    --         jobs = {
    --             {name = 'police', grade = 1},
    --             {name = 'doctor', grade = 3}
    --         },
    --         hours = {
    --             active = false,
    --             open = 7,
    --             close = 21
    --         }
    --     },
    --     blip = {
    --         show = true,
    --         showClosed = true,
    --         name = 'Guarma Stable',
    --         sprite = 1938782895,
    --         color = {
    --             open = 'WHITE',
    --             closed = 'RED',
    --             job = 'YELLOW_ORANGE'
    --         }
    --     },
    --     npc = {
    --         active = true,
    --         model = 'u_m_m_bwmstablehand_01',
    --         coords = vector3(1340.28, -6853.88, 47.19),
    --         heading = 68.92,
    --         distance = 100.0
    --     },
    --     horse = {
    --         coords = vector3(1335.06, -6850.62, 47.34),
    --         heading = 185.14,
    --         camera = vector3(1337.84, -6853.13, 47.23),
    --     },
    --     trainerBuy = false
	-- },
    -----------------------------------------------------

    -- พิกัดด้านล่างนี้ใช้ค่าเดียวที่ส่งมาเป็น npc.coords แล้ว offset horse/camera แบบกะคร่าวๆ (+4,+4 / +2,+2)
    -- ยังไม่ได้ทดสอบในเกมจริง ต้องเข้าไปดูว่าม้า/กล้อง/NPC ไม่ทับกันแล้วปรับอีกที
    emeraldranch = {
        shop = {
            name = 'Emerald Ranch Stable',
            prompt = 'Emerald Ranch Stable',
            distance = 2.0,
            jobsEnabled = false,
            jobs = {
                {name = 'police', grade = 1},
                {name = 'doctor', grade = 3}
            },
            hours = {
                active = false,
                open = 7,
                close = 21
            }
        },
        blip = {
            show = true,
            showClosed = true,
            name = 'Emerald Ranch Stable',
            sprite = 1938782895,
            color = {
                open = 'WHITE',
                closed = 'RED',
                job = 'YELLOW_ORANGE'
            }
        },
        npc = {
            active = true,
            model = 'u_m_m_bwmstablehand_01',
            coords = vector3(1407.7335, 273.8170, 89.5298),
            heading = 287.0656,
            distance = 100.0
        },
        horse = {
            coords = vector3(1411.7335, 277.8170, 89.5298),
            heading = 107.0656,
            camera = vector3(1409.7335, 275.8170, 89.5298),
        },
        trainerBuy = false
    },
    -----------------------------------------------------

    rhodes = {
        shop = {
            name = 'Rhodes Stable',
            prompt = 'Rhodes Stable',
            distance = 2.0,
            jobsEnabled = false,
            jobs = {
                {name = 'police', grade = 1},
                {name = 'doctor', grade = 3}
            },
            hours = {
                active = false,
                open = 7,
                close = 21
            }
        },
        blip = {
            show = true,
            showClosed = true,
            name = 'Rhodes Stable',
            sprite = 1938782895,
            color = {
                open = 'WHITE',
                closed = 'RED',
                job = 'YELLOW_ORANGE'
            }
        },
        npc = {
            active = true,
            model = 'u_m_m_bwmstablehand_01',
            coords = vector3(1435.7383, -1294.9196, 78.9199),
            heading = 7.3988,
            distance = 100.0
        },
        horse = {
            coords = vector3(1439.7383, -1290.9196, 78.9199),
            heading = 187.3988,
            camera = vector3(1437.7383, -1292.9196, 78.9199),
        },
        trainerBuy = false
    },
    -----------------------------------------------------

    annesburg = {
        shop = {
            name = 'Annesburg Stable',
            prompt = 'Annesburg Stable',
            distance = 2.0,
            jobsEnabled = false,
            jobs = {
                {name = 'police', grade = 1},
                {name = 'doctor', grade = 3}
            },
            hours = {
                active = false,
                open = 7,
                close = 21
            }
        },
        blip = {
            show = true,
            showClosed = true,
            name = 'Annesburg Stable',
            sprite = 1938782895,
            color = {
                open = 'WHITE',
                closed = 'RED',
                job = 'YELLOW_ORANGE'
            }
        },
        npc = {
            active = true,
            model = 'u_m_m_bwmstablehand_01',
            coords = vector3(2976.2861, 1430.3289, 44.7171),
            heading = 225.9213,
            distance = 100.0
        },
        horse = {
            coords = vector3(2980.2861, 1434.3289, 44.7171),
            heading = 45.9213,
            camera = vector3(2978.2861, 1432.3289, 44.7171),
        },
        trainerBuy = false
    }
}
-----------------------------------------------------