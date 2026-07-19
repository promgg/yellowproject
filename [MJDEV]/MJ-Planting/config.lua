
-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 
MJDEV = {}

-- เปิดไว้เฉพาะตอน dev — คุม print debug/info ทั้งฝั่ง client/server (ข้อ 6/11 ของ security checklist)
MJDEV.Debug = false

-- การควบคุม
MJDEV.Controls = {
    EnterKey  = 0x17BEC168, -- E
    CancelKey = 0x8CC9CD42  -- X
}

-- ปุ๋ยที่ใช้ในขั้น "ใส่ปุ๋ย" — หัก 1 ต่อการปลูก 1 ต้น (item 'compost' label "ปุ๋ย" ขายใน nx_shop หมวด farming อยู่แล้ว)
MJDEV.FertilizerItem = "compost"

-- ── Interaction (floating hold-E ที่ต้นพืชแต่ละต้น: ใส่ปุ๋ย / รดน้ำ / เก็บเกี่ยว) ──
MJDEV.InteractRange  = 2.0  -- ระยะที่โชว์ prompt ลอยเหนือต้น
MJDEV.InteractHoldMs = 900  -- กดค้าง E กี่ ms ถึงเริ่ม action (เท่ากับจุดเติมน้ำ)

-- อนิเมชั่นตอน "เติมน้ำ" ที่จุดปั๊ม (lp_progbar) — verify กับ scenarios.lua (femga/rdr3_discoveries mirror
-- ใน [standalone]/spooni_spooner/data/rdr3/scenarios.lua:2603) แล้วว่า WORLD_HUMAN_BUCKET_FILL มีจริง
-- (ท่าตักน้ำใส่ถัง คนละท่ากับ BUCKET_POUR_LOW ที่ใช้ตอนรดน้ำต้นไม้)
MJDEV.RefillAnim = {
    duration = 4000,
    label    = 'กำลังเติมน้ำ...',
    task     = 'WORLD_HUMAN_BUCKET_FILL',
}

-- จุดเติมน้ำ — ถังน้ำ (tool_bucket) เก็บจำนวนครั้งที่รดได้เหลือไว้ใน metadata.uses
-- ถังใหม่/ถังที่รดจนหมด (uses = 0) ต้องมาเติมที่จุดนี้ก่อนถึงจะรดต่อได้ (ถังไม่หายไปตอนหมด)
MJDEV.WaterRefill = {
    usesPerRefill = 10, -- เติม 1 ครั้ง รดได้กี่ครั้ง
    holdMs        = 900, -- กดค้าง E กี่ ms ถึงเติมสำเร็จ (เท่ากับ MJ-Lumberjack/MJ-Mining)
    propModel     = "p_waterpump01x",
    range         = 3.0, -- ระยะกด E เติมน้ำจริง

    -- พิกัด/heading ของ prop เติมน้ำแยกตาม zoneId (ปรับพิกัดจริงตรงนี้ได้เลย ไม่ผูกกับจุดปลูกอีกต่อไป)
    -- ถ้า zoneId ไหนไม่มีในตารางนี้ client_waterrefill.lua จะ fallback ไปใช้ zone.coords + heading 0.0 แทน
    points = {
        valentine_farm  = { coords = vector3(-855.6186, 331.2108, 96.1075), heading = 77.0 },
        annesburg_farm  = { coords = vector3(2969.4299, 788.4561, 51.3998 ), heading = 5.5112 },
        rhodes_farm     = { coords = vector3(968.0037, -1996.9865, 45.885 ), heading = 176.6739 },
    },
}

MJDEV['Planting'] = {
    -- ═══════════════════════════════════════════════════════════════
    -- จุดปลูกผัก 3 เมือง ตามสเปกลูกค้า (20 นาที, ได้ 10 ชิ้น, ราคาขาย 5 เหรียญ/ชิ้น — ราคาขายตั้งในระบบร้านค้าแยกต่างหาก ไม่ใช่ในนี้)
    -- model = crp_seedling_aa_sim (ระยะแรก/ต้นกล้า) ทุกชนิดพืช, model2 = crp_wheat_stk_ab_sim (ต้นพร้อมเก็บเกี่ยว) ทุกชนิดพืช ตามที่กำหนด
    -- ═══════════════════════════════════════════════════════════════

    -- ── Valentine: ข้าวโพด / แครอท / ยาร์โรว์ / อ้อย ──
    {
        model = "crp_seedling_aa_sim",
        model2 = 'crp_wheat_stk_ab_sim',
        coords = vector3(-847.4569, 320.4838, 95.5757), -- heading 112.3678
        zoneId = "valentine_farm", -- เชื่อม entry ที่จุดเดียวกันเข้าด้วยกัน (รวม reward panel / Count / เช็คระยะห่าง)
        zoneName = "Valentine", -- ชื่ออ่านง่ายไว้ใช้ในข้อความแจ้งเตือน
        count = 10,
        range = 40.0,
        plantmax = 1200, -- 1200 วิ = 20 นาที (เพิ่ม Hungry ทีละ 1 ทุก 1 วิ)
        percent_feed = {1, 5},
        watering = 600, -- รดน้ำตอนโตครึ่งทาง (600 วิ = 10 นาที)
        time_need = 40 * 60 * 1000, -- กันเผื่อเวลารดน้ำ/หลงลืม (โตจริงใช้ plantmax 20 นาที ตัวนี้เป็นแค่ timeout ลบทิ้งถ้าถูกปล่อยทิ้งร้าง)
        Dis = 3.0,
        blips = {
            enabled = true,
            sprite = 669307703,
            scale = 1.2,
            color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE',
            text = "Valentine Farm - Corn"
        },
        bandits = 40,
        item = {
            seed = "seed_corn",
            feed = "tool_bucket"
        },
        giveitem = {
            {item = "job_corn", count = 10, percent = 100},
        }
    },
    {
        model = "crp_seedling_aa_sim",
        model2 = 'crp_wheat_stk_ab_sim',
        coords = vector3(-847.4569, 320.4838, 95.5757), -- heading 112.3678
        zoneId = "valentine_farm", -- เชื่อม entry ที่จุดเดียวกันเข้าด้วยกัน (รวม reward panel / Count / เช็คระยะห่าง)
        zoneName = "Valentine", -- ชื่ออ่านง่ายไว้ใช้ในข้อความแจ้งเตือน
        count = 10,
        range = 40.0,
        plantmax = 1200, -- 1200 วิ = 20 นาที (เพิ่ม Hungry ทีละ 1 ทุก 1 วิ)
        percent_feed = {1, 5},
        watering = 600, -- รดน้ำตอนโตครึ่งทาง (600 วิ = 10 นาที)
        time_need = 40 * 60 * 1000,
        Dis = 3.0,
        blips = {
            enabled = true,
            sprite = 669307703,
            scale = 1.2,
            color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE',
            text = "Valentine Farm - Carrot"
        },
        bandits = 40,
        item = {
            seed = "seed_carrot",
            feed = "tool_bucket"
        },
        giveitem = {
            {item = "job_carrot", count = 10, percent = 100},
        }
    },
    {
        model = "crp_seedling_aa_sim",
        model2 = 'crp_wheat_stk_ab_sim',
        coords = vector3(-847.4569, 320.4838, 95.5757), -- heading 112.3678
        zoneId = "valentine_farm", -- เชื่อม entry ที่จุดเดียวกันเข้าด้วยกัน (รวม reward panel / Count / เช็คระยะห่าง)
        zoneName = "Valentine", -- ชื่ออ่านง่ายไว้ใช้ในข้อความแจ้งเตือน
        count = 10,
        range = 40.0,
        plantmax = 1200, -- 1200 วิ = 20 นาที (เพิ่ม Hungry ทีละ 1 ทุก 1 วิ)
        percent_feed = {1, 5},
        watering = 600, -- รดน้ำตอนโตครึ่งทาง (600 วิ = 10 นาที)
        time_need = 40 * 60 * 1000,
        Dis = 3.0,
        blips = {
            enabled = true,
            sprite = 669307703,
            scale = 1.2,
            color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE',
            text = "Valentine Farm - Yarrow"
        },
        bandits = 40,
        item = {
            seed = "seed_yarrow",
            feed = "tool_bucket"
        },
        giveitem = {
            {item = "job_Yarrow", count = 10, percent = 100},
        }
    },
    {
        model = "crp_seedling_aa_sim",
        model2 = 'crp_wheat_stk_ab_sim',
        coords = vector3(-847.4569, 320.4838, 95.5757), -- heading 112.3678
        zoneId = "valentine_farm", -- เชื่อม entry ที่จุดเดียวกันเข้าด้วยกัน (รวม reward panel / Count / เช็คระยะห่าง)
        zoneName = "Valentine", -- ชื่ออ่านง่ายไว้ใช้ในข้อความแจ้งเตือน
        count = 10,
        range = 40.0,
        plantmax = 1200, -- 1200 วิ = 20 นาที (เพิ่ม Hungry ทีละ 1 ทุก 1 วิ)
        percent_feed = {1, 5},
        watering = 600, -- รดน้ำตอนโตครึ่งทาง (600 วิ = 10 นาที)
        time_need = 40 * 60 * 1000,
        Dis = 3.0,
        blips = {
            enabled = true,
            sprite = 669307703,
            scale = 1.2,
            color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE',
            text = "Valentine Farm - Sugarcane"
        },
        bandits = 40,
        item = {
            seed = "seed_sugarcane",
            feed = "tool_bucket"
        },
        giveitem = {
            {item = "job_sugarcane", count = 10, percent = 100},
        }
    },

    -- ── Annesburg: เห็ดป่า / โสม / ฝิ่น / เบอรี่ ──
    {
        model = "crp_seedling_aa_sim",
        model2 = 'crp_wheat_stk_ab_sim',
        coords = vector3(2967.7837, 773.5686, 51.3994), -- heading 107.1493
        zoneId = "annesburg_farm",
        zoneName = "Annesburg",
        count = 10,
        range = 40.0,
        plantmax = 1200, -- 1200 วิ = 20 นาที (เพิ่ม Hungry ทีละ 1 ทุก 1 วิ)
        percent_feed = {1, 5},
        watering = 600, -- รดน้ำตอนโตครึ่งทาง (600 วิ = 10 นาที)
        time_need = 40 * 60 * 1000,
        Dis = 3.0,
        blips = {
            enabled = true,
            sprite = 669307703,
            scale = 1.2,
            color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE',
            text = "Annesburg Farm - Mushroom"
        },
        bandits = 40,
        item = {
            seed = "seed_mushroom",
            feed = "tool_bucket"
        },
        giveitem = {
            {item = "job_mushroom", count = 10, percent = 100},
        }
    },
    {
        model = "crp_seedling_aa_sim",
        model2 = 'crp_wheat_stk_ab_sim',
        coords = vector3(2967.7837, 773.5686, 51.3994), -- heading 107.1493
        zoneId = "annesburg_farm",
        zoneName = "Annesburg",
        count = 10,
        range = 40.0,
        plantmax = 1200, -- 1200 วิ = 20 นาที (เพิ่ม Hungry ทีละ 1 ทุก 1 วิ)
        percent_feed = {1, 5},
        watering = 600, -- รดน้ำตอนโตครึ่งทาง (600 วิ = 10 นาที)
        time_need = 40 * 60 * 1000,
        Dis = 3.0,
        blips = {
            enabled = true,
            sprite = 669307703,
            scale = 1.2,
            color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE',
            text = "Annesburg Farm - Ginseng"
        },
        bandits = 40,
        item = {
            seed = "seed_Ginseng",
            feed = "tool_bucket"
        },
        giveitem = {
            {item = "job_Ginseng", count = 10, percent = 100},
        }
    },
    {
        model = "crp_seedling_aa_sim",
        model2 = 'crp_wheat_stk_ab_sim',
        coords = vector3(2967.7837, 773.5686, 51.3994), -- heading 107.1493
        zoneId = "annesburg_farm",
        zoneName = "Annesburg",
        count = 10,
        range = 40.0,
        plantmax = 1200, -- 1200 วิ = 20 นาที (เพิ่ม Hungry ทีละ 1 ทุก 1 วิ)
        percent_feed = {1, 5},
        watering = 600, -- รดน้ำตอนโตครึ่งทาง (600 วิ = 10 นาที)
        time_need = 40 * 60 * 1000,
        Dis = 3.0,
        blips = {
            enabled = true,
            sprite = 669307703,
            scale = 1.2,
            color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE',
            text = "Annesburg Farm - Opium"
        },
        bandits = 40,
        item = {
            seed = "seed_opium",
            feed = "tool_bucket"
        },
        giveitem = {
            {item = "job_opium", count = 10, percent = 100},
        }
    },
    {
        model = "crp_seedling_aa_sim",
        model2 = 'crp_wheat_stk_ab_sim',
        coords = vector3(2967.7837, 773.5686, 51.3994), -- heading 107.1493
        zoneId = "annesburg_farm",
        zoneName = "Annesburg",
        count = 10,
        range = 40.0,
        plantmax = 1200, -- 1200 วิ = 20 นาที (เพิ่ม Hungry ทีละ 1 ทุก 1 วิ)
        percent_feed = {1, 5},
        watering = 600, -- รดน้ำตอนโตครึ่งทาง (600 วิ = 10 นาที)
        time_need = 40 * 60 * 1000,
        Dis = 3.0,
        blips = {
            enabled = true,
            sprite = 669307703,
            scale = 1.2,
            color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE',
            text = "Annesburg Farm - Berry"
        },
        bandits = 40,
        item = {
            seed = "seed_berry",
            feed = "tool_bucket"
        },
        giveitem = {
            {item = "job_berry", count = 10, percent = 100},
        }
    },

    -- ── Rhodes: ต้นยาสูบ / ข้าวบาร์เลย์ / ฝ้าย / ส้ม ──
    {
        model = "crp_seedling_aa_sim",
        model2 = 'crp_wheat_stk_ab_sim',
        coords = vector3(969.6452, -1962.3392, 47.4799), -- heading 337.4934
        zoneId = "rhodes_farm",
        zoneName = "Rhodes",
        count = 10,
        range = 40.0,
        plantmax = 1200, -- 1200 วิ = 20 นาที (เพิ่ม Hungry ทีละ 1 ทุก 1 วิ)
        percent_feed = {1, 5},
        watering = 600, -- รดน้ำตอนโตครึ่งทาง (600 วิ = 10 นาที)
        time_need = 40 * 60 * 1000,
        Dis = 3.0,
        blips = {
            enabled = true,
            sprite = 669307703,
            scale = 1.2,
            color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE',
            text = "Rhodes Farm - Tobacco"
        },
        bandits = 40,
        item = {
            seed = "seed_tobacco_plant",
            feed = "tool_bucket"
        },
        giveitem = {
            {item = "job_tobacco_plant", count = 10, percent = 100},
        }
    },
    {
        model = "crp_seedling_aa_sim",
        model2 = 'crp_wheat_stk_ab_sim',
        coords = vector3(969.6452, -1962.3392, 47.4799), -- heading 337.4934
        zoneId = "rhodes_farm",
        zoneName = "Rhodes",
        count = 10,
        range = 40.0,
        plantmax = 1200, -- 1200 วิ = 20 นาที (เพิ่ม Hungry ทีละ 1 ทุก 1 วิ)
        percent_feed = {1, 5},
        watering = 600, -- รดน้ำตอนโตครึ่งทาง (600 วิ = 10 นาที)
        time_need = 40 * 60 * 1000,
        Dis = 3.0,
        blips = {
            enabled = true,
            sprite = 669307703,
            scale = 1.2,
            color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE',
            text = "Rhodes Farm - Barley"
        },
        bandits = 40,
        item = {
            seed = "seed_barley",
            feed = "tool_bucket"
        },
        giveitem = {
            {item = "job_barley", count = 10, percent = 100},
        }
    },
    {
        model = "crp_seedling_aa_sim",
        model2 = 'crp_wheat_stk_ab_sim',
        coords = vector3(969.6452, -1962.3392, 47.4799), -- heading 337.4934
        zoneId = "rhodes_farm",
        zoneName = "Rhodes",
        count = 10,
        range = 40.0,
        plantmax = 1200, -- 1200 วิ = 20 นาที (เพิ่ม Hungry ทีละ 1 ทุก 1 วิ)
        percent_feed = {1, 5},
        watering = 600, -- รดน้ำตอนโตครึ่งทาง (600 วิ = 10 นาที)
        time_need = 40 * 60 * 1000,
        Dis = 3.0,
        blips = {
            enabled = true,
            sprite = 669307703,
            scale = 1.2,
            color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE',
            text = "Rhodes Farm - Cotton"
        },
        bandits = 40,
        item = {
            seed = "seed_cotton",
            feed = "tool_bucket"
        },
        giveitem = {
            {item = "job_cotton", count = 10, percent = 100},
        }
    },
    {
        model = "crp_seedling_aa_sim",
        model2 = 'crp_wheat_stk_ab_sim',
        coords = vector3(969.6452, -1962.3392, 47.4799), -- heading 337.4934
        zoneId = "rhodes_farm",
        zoneName = "Rhodes",
        count = 10,
        range = 40.0,
        plantmax = 1200, -- 1200 วิ = 20 นาที (เพิ่ม Hungry ทีละ 1 ทุก 1 วิ)
        percent_feed = {1, 5},
        watering = 600, -- รดน้ำตอนโตครึ่งทาง (600 วิ = 10 นาที)
        time_need = 40 * 60 * 1000,
        Dis = 3.0,
        blips = {
            enabled = true,
            sprite = 669307703,
            scale = 1.2,
            color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE',
            text = "Rhodes Farm - Orange"
        },
        bandits = 40,
        item = {
            seed = "seed_orange",
            feed = "tool_bucket"
        },
        giveitem = {
            {item = "job_orange", count = 10, percent = 100},
        }
    },
}

-- ผูก idx คงที่ (ตำแหน่งในตาราง) ให้แต่ละ entry ไว้อ้างอิงข้าม client<->server แบบไม่ต้องส่งทั้งก้อน
-- (client ใช้ตอนเรียก ConfirmPlace:SV, server ใช้ตอน revalidate ว่า entry ที่ client อ้างถึงมีจริง)
for i, entry in ipairs(MJDEV['Planting']) do
    entry.idx = i
end

-- ระยะ LOD ของ per-plant UI panel
MJDEV.LOD = {
    show = 4.0,  -- m — ระยะสูงสุดที่แสดง panel (opacity 0 ที่ระยะนี้)
    fade = 3.0,  -- m — ระยะที่เริ่ม fade (opacity 1.0 ถึงระยะนี้ แล้วค่อยๆจางถึง show)
}

MJDEV.Icons = {
    Normal = {
        Icon_on = false,
        Icon = {
            iconDict = "menu_textures",
            iconName = "menu_icon_alert",
            color = { r = 255, g = 255, b = 255, a = 250 }
        }
    },
    Feed = {
        Icon_on = false,
        Icon = {
            iconDict = "itemtype_textures",
            iconName = "transaction_trim",
            color = { r = 255, g = 255, b = 175, a = 250 }
        }
    }
}

-- zone (optional) = MJDEV['Planting'][i] ของเมล็ดที่ใช้ ถ้ามีจะบอกชื่อโซนที่ปลูกได้จริงให้ผู้เล่นด้วย
function MJDEV.NoZone(zone)
    local text = (zone and zone.zoneName)
        and ('เมล็ดนี้ปลูกได้แค่ที่ %s เท่านั้น'):format(zone.zoneName)
        or 'คุณไม่ได้อยู่ในโซนปลูกพืช'
    exports.pNotify:SendNotification({ type = 'error', text = text, timeout = 4000 })
end

function MJDEV.NoItemFeed()
    exports.pNotify:SendNotification({ type = 'error', text = 'คุณไม่มีถังน้ำ', timeout = 4000 })
end

function MJDEV.TextUIFeed(point)
    DrawText3D(point.x , point.y , point.z+0.1, 'Press ~g~[E] ~s~to Watering plants.') 
end

function MJDEV.TextUIGive(point)
    DrawText3D(point.x , point.y , point.z+0.1, 'Press ~g~[E] ~s~to cut down trees.') 
end
