
-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 

Config = {}

-- true = พิมพ์ log ลง F8 ตอนกินของ/ลด stamina — ใช้ตอนไล่หาสาเหตุ ปิดตอนขึ้นจริง
-- (log จะบอกว่ากินแล้วค่าถูกบันทึกจริงไหม และ stamina โดนอะไรสู้อยู่หรือเปล่า)
Config.Debug = true

Config.ShowUI = false -- เปิดปิด UI
----------------------------------
-- การตั้งค่าความเครียด (Stress Settings)
----------------------------------
Config.MinimumStress = 50 -- กำหนดค่าความเครียดขั้นต่ำที่ทำให้เกิดอาการสั่นของหน้าจอ

----------------------------------
-- การตั้งค่าการแสดงผล HUD (Heads-Up Display)
----------------------------------
Config.HidePlayerHealthNative  = true -- ซ่อนค่า Health ของตัวละคร
Config.HidePlayerStaminaNative = true -- ซ่อนค่า Stamina ของตัวละคร
Config.HidePlayerDeadEyeNative = true -- ซ่อนค่า Dead Eye ของตัวละคร

----------------------------------
-- hud horse display settings
----------------------------------
Config.HideHorseHealthNative  = true -- ซ่อนค่า Health ของม้า
Config.HideHorseStaminaNative = true -- ซ่อนค่า Stamina ของม้า
Config.HideHorseCourageNative = true -- ซ่อนค่า Courage ของม้า

----------------------------------
-- การตั้งค่าความเสียหายจากสุขภาพ (Health Damage Settings)
----------------------------------
Config.DoHealthDamage = true         --เปิดใช้งานระบบที่ทำให้ตัวละครได้รับความเสียหายจากอุณหภูมิ

----------------------------------
-- ปิดใช้งานเอฟเฟกต์เมื่อได้รับความเสียหายจากอุณหภูมิ    
----------------------------------
Config.DoHealthDamageFx = true      --ปิดใช้งานเอฟเฟกต์เมื่อได้รับความเสียหายจากอุณหภูมิ      

----------------------------------
-- เปิดใช้งานเสียงความเจ็บปวดเมื่อตัวละครได้รับความเสียหาย
----------------------------------
Config.DoHealthPainSound = true    

----------------------------------
-- การตั้งค่าอุณหภูมิและเสื้อผ้า (Temperature & Clothing)
----------------------------------
Config.TempFormat = 'celsius' --  ใช้หน่วยอุณหภูมิเป็นเซลเซียส fahrenheit & celsius
----------------------------------
-- warmth add while wearing
----------------------------------
Config.WearingHat      = 0
Config.WearingShirt    = 0
Config.WearingPants    = 0
Config.WearingBoots    = 0
Config.WearingCoat     = 15 -- ใส่เสื้อโค้ทจะเพิ่มความอบอุ่นให้ตัวละคร 15 หน่วย
Config.WearingOpenCoat = 15 -- ใส่เสื้อโค้ทแบบเปิดจะเพิ่มความอบอุ่นให้ตัวละคร 15 หน่วย
Config.WearingGloves   = 0
Config.WearingVest     = 0
Config.WearingPoncho   = 0
Config.WearingSkirt    = 0
Config.WearingChaps    = 0

----------------------------------
-- warmth limit before impacts health
----------------------------------
Config.MinTemp = -25 -- อุณหภูมิต่ำสุดที่เริ่มมีผลกระทบต่อสุขภาพ
Config.MaxTemp = 40  -- อุณหภูมิสูงสุดที่เริ่มมีผลกระทบต่อสุขภาพ

----------------------------------
-- การตั้งค่าความสะอาด (Cleanliness Settings)
----------------------------------
Config.FlyEffect = true -- เปิดใช้งานเอฟเฟกต์แมลงวันบินรอบตัวละครเมื่อสกปรก
Config.MinCleanliness = 30 -- เมื่อค่าความสะอาดต่ำกว่า 30 จะเริ่มมีผลกระทบต่อสุขภาพ

----------------------------------
-- amount of health to remove if min/max temp reached
----------------------------------
Config.RemoveHealth = 5

----------------------------------
-- ตั้งค่าความรุนแรงของอาการสั่นของหน้าจอตามระดับของความเครียด (ยิ่งเครียดมาก ยิ่งสั่นมาก)
----------------------------------
Config.Intensity = {
    ["shake"] = {
        [1] = {
            min = 50,
            max = 60,
            intensity = 0.12,
        },
        [2] = {
            min = 60,
            max = 70,
            intensity = 0.17,
        },
        [3] = {
            min = 70,
            max = 80,
            intensity = 0.22,
        },
        [4] = {
            min = 80,
            max = 90,
            intensity = 0.28,
        },
        [5] = {
            min = 90,
            max = 100,
            intensity = 0.32,
        },
    }
}

Config.EffectInterval = { -- กำหนดช่วงเวลาสุ่มที่หน้าจอจะเกิดเอฟเฟกต์สั่น เมื่อค่าความเครียดถึงระดับที่กำหนด
    [1] = {
        min = 50,
        max = 60,
        timeout = math.random(50000, 60000)
    },
    [2] = {
        min = 60,
        max = 70,
        timeout = math.random(40000, 50000)
    },
    [3] = {
        min = 70,
        max = 80,
        timeout = math.random(30000, 40000)
    },
    [4] = {
        min = 80,
        max = 90,
        timeout = math.random(20000, 30000)
    },
    [5] = {
        min = 90,
        max = 100,
        timeout = math.random(15000, 20000)
    }
}

-- การตั้งค่าความหิวและกระหาย (Hunger & Thirst Settings)
Config.MaxHunger = 100000 -- กำหนดค่าความหิวสูงสุดที่ตัวละครสามารถมีได้
Config.MaxThirst = 100000 -- กำหนดค่าความกระหายสูงสุดที่ตัวละครสามารถมีได้
Config.MaxStress = 100000 -- กำหนดค่าความกระหายสูงสุดที่ตัวละครสามารถมีได้
Config.MaxStamina = 100000   -- ค่าสูงสุดของ Stamina

Config.MinThirst = 0
Config.MinHunger = 0
Config.MinStress = 0
Config.MinStamina = 0

Config.SavePlayersStatus      = true        -- Future deprecated. Advised not to use, as it will be removed.
-- ทุกกี่ ms ที่ server ดึงค่าสดจาก client มาเซฟลง DB (+อัปเดต object)
-- ยิ่งถี่ ค่าตอน "ออก" ยิ่งใกล้ค่าจริง (playerDropped เซฟได้แค่ค่าล่าสุดที่ดึงมา ไม่ใช่ค่า ณ วินาทีออก)
-- ลดจาก 5 นาที -> 1 นาที ให้ "ออกเท่าไหนเข้าก็เท่านั้น" คลาดเคลื่อนไม่เกิน ~1 นาที
Config.SaveStatusTickInterval = 60000 -- 1 minute

-- ── อัตราลดของหลอดหิว/กระหาย ────────────────────────────────────────────────
-- ตั้งเป็น "กี่นาทีจากเต็มถึงศูนย์" ตรงๆ อ่านแล้วรู้เลยว่าผู้เล่นมีเวลาเท่าไหร่
-- โค้ดคำนวณค่าที่ลดต่อรอบเอง (needs.lua) ไม่ต้องมานั่งคูณหารเวลาปรับ
--
-- ⚠️ ของเดิมคือ Config.HungerTickInterval = 80000 / ThirstTickInterval = 75000 ซึ่ง
--    "ไม่เคยถูกใช้งานเลย" — needs.lua:7-8 อ่านใส่ตัวแปร foodtime/thirsttime แล้วทิ้งไว้เฉยๆ
--    ลูปจริงใช้ Wait(10000) ตายตัวและลดทีละ 10 จากเต็ม 100,000
--    = หลอดหมดใน 27.8 ชั่วโมง ไม่ใช่ 80/75 วินาทีตามที่คอมเมนต์เดิมเขียนไว้
Config.NeedsTickInterval    = 10000 -- ตรวจ/ลดหลอดทุกกี่ ms (ค่าเดิมที่ hardcode ไว้ใน needs.lua)
Config.HungerMinutesToEmpty = 100   -- อิ่มเต็ม -> หิวจนหมด ใช้เวลากี่นาที
Config.ThirstMinutesToEmpty = 100   -- น้ำเต็ม -> หมด ใช้เวลากี่นาที

Config.StressTickInterval = 90000   -- กำหนดให้ค่าความเครียดลดลงทุก ๆ 60 วินาที

-- ── สเตมิน่าตอนวิ่ง ─────────────────────────────────────────────────────────
-- ปิดระบบ drain เองแล้ว — ให้เกม gate การวิ่งตามธรรมชาติ (แนวทางเดียวกับ vorp_metabolism
-- ที่จงใจไม่ยุ่งกับ stamina เลย)
--
-- เหตุผล: เดิม drainSeconds สั่ง ChangePedStamina ลดค่า "หลอดนอก" (GetPlayerStamina)
-- ลงไป 0 ได้จริง แต่ค่านั้น "ไม่ใช่" ตัวที่เกมใช้ตัดสินว่ายังวิ่งได้ไหม เกมดูหลอด
-- sprint ภายในของมันเองซึ่ง regen เร็วและยังเต็มอยู่ = ตัวละครวิ่งต่อได้แม้หลอดนอก 0
-- (บั๊กที่เจอ: ปล่อย shift แล้วยังวิ่ง / stamina หมดก็ยังวิ่ง)
--
-- การ "เขียนเลข stamina ทับ" จึงไม่ gate การวิ่ง เพราะ sprint เป็น control ไม่ใช่ attribute
-- พอปิดระบบนี้ เกมจะลด sprint-stamina จริงเองแล้วดรอปเป็นจ๊อกตอนหมดตามปกติ
-- (vorp_core StaminaRecharge แค่ปรับความเร็ว regen ไม่ได้เติมให้เต็ม จึงไม่ขวาง)
--
-- ข้อแลก: คุมเวลา "วิ่งกี่วิหมด" เป๊ะ ๆ ไม่ได้ เกมเป็นคนกำหนด ถ้าวันหลังอยากคุมเวลาจริง
-- ต้องกลับไปทางที่บล็อก INPUT_SPRINT (0x8FFC75D6) ทุกเฟรมตอนหลอดหมดแทน
Config.Stamina = {
    enabled       = false, -- false = ปล่อยให้เกม gate เอง (ดูเหตุผลข้างบน)
    drainSeconds  = 8.0,   -- ใช้เมื่อ enabled = true เท่านั้น
    sprintOnly    = false,
    tickMs        = 100,
}

Config.FoodItems = {
    ["bread"] = {
        prop_name = 'p_bread03x', -- โมเดลของขนมปัง
        Animation = "eat", -- แอนิเมชันกิน
        Effect = "",
        EffectDuration = "",
        hunger = 40000, -- เพิ่มค่าความหิว
        thirst = 0, -- ไม่เพิ่มค่ากระหาย
        stress = -400, -- ลดค่าความเครียด
        stamina = 10 -- เพิ่มค่า Stamina
    },
    ["water"] = {
        prop_name = 'p_water01x',
        Animation = "drink",
        Effect = "",
        EffectDuration = "",
        hunger = 0,
        thirst = 55000,
        stress = -400,
        stamina = 10
    },
    ["burger"] = {
        prop_name = 'prop_food_bs_burger',
        Animation = "eat",
        Effect = "PlayerDrunkSaloon1",
        EffectDuration = 1,
        hunger = 70000,
        thirst = 0,
        stress = 0,
        stamina = 10
    },
    ["coffeebeans"] = {
        prop_name = 'p_mugcoffee01x',
        Animation = "drink",
        Effect = "",
        EffectDuration = "",
        hunger = 70000,
        thirst = 28000,
        stress = -600,
        stamina = 1000
    },

    -- ===== ไอเทมเริ่มต้นผู้เล่นใหม่ (startItems ใน vorp_inventory) =====
    -- ยังไม่เคยลงทะเบียนใน MJ-STATUS มาก่อน — ค่าประเมินจาก desc ใน DB เทียบ tier เบากว่า food_taco
    -- (tier เบาสุดเดิม 40%/10%/10% -> 2500/500/-500) เพราะ % ใน desc ต่ำกว่าทุก tier ที่มีอยู่
    -- แนะนำให้เจ้าของระบบ tune ตัวเลขจริงอีกทีตามความรู้สึกเกม ไม่ใช่ค่าที่ผ่านการเทสสมดุลมาก่อน
    ["food_sandwich"] = { -- แซนวิช - เพิ่มอิ่ม 15% | นํ้า 8%
        prop_name = 'p_bread03x',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 15000,
        thirst = 8000,
        stress = 0,
        stamina = 10
    },
    ["food_bread"] = { -- ขนมปัง - เพิ่มอิ่ม 10% | นํ้า 5%
        prop_name = 'p_bread03x',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 10000,
        thirst = 5000,
        stress = 0,
        stamina = 10
    },
    ["food_coffee"] = { -- กาแฟ - เพิ่มนํ้า 10% | ลดเครียด 20%
        prop_name = 'p_mugcoffee01x',
        Animation = "drink",
        Effect = "",
        EffectDuration = "",
        hunger = 0,
        thirst = 10000,
        stress = -400,
        stamina = 10
    },

    -- ===== ของขายในร้านค้าทั่วไป (nx_shop หมวด food) =====
    -- 5 ตัวนี้ขายอยู่ในร้านมาตลอดแต่ไม่เคยลงทะเบียนที่นี่ — ผู้เล่นซื้อมาใช้แล้วไม่มีผลอะไรเลย
    --
    -- ⚠️ ค่า stress คิดจาก "จุดตาย" ที่ 2,000 ไม่ใช่ Config.MaxStress (100,000)
    --    เพราะ needs.lua:167-183 เริ่มหักเลือด -20 HP ซ้ำๆ ทันทีที่ Stress แตะ MaxStress*0.02
    --    ช่วงที่ใช้งานได้จริงจึงเป็น 0-2,000 ส่วนที่เกินนั้นแตะไม่ถึงอยู่แล้วเพราะตายก่อน
    --    -> เหล้า +10% = +200 (กิน 10 แก้วถึงจุดอันตราย) | บุหรี่ -20% = -400 (มวนเดียวแก้ได้ 2 แก้ว)
    ["food_canned_beans"] = { -- ถั่วกระป๋อง - เพิ่มอิ่ม 25%
        prop_name = 'p_can01x',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 25000,
        thirst = 0,
        stress = 0,
        stamina = 10
    },
    ["food_beer"] = { -- เบียร์ - เพิ่มน้ำ 20% | เพิ่มเครียด 10%
        prop_name = 'p_bottlebeer01x',
        Animation = "drink",
        Effect = "PlayerDrunkSaloon1",
        EffectDuration = 1,
        hunger = 0,
        thirst = 20000,
        stress = 200,
        stamina = 10
    },
    ["food_brandy"] = { -- บรั่นดี - เพิ่มน้ำ 20% | เพิ่มเครียด 10%
        prop_name = 'p_bottlenavyrum01x',
        Animation = "drink",
        Effect = "PlayerDrunkSaloon1",
        EffectDuration = 1,
        hunger = 0,
        thirst = 20000,
        stress = 200,
        stamina = 10
    },
    ["food_vodka"] = { -- วิสกี้ - เพิ่มน้ำ 20% | เพิ่มเครียด 10%
        prop_name = 'p_bottlenavyrum01x',
        Animation = "drink",
        Effect = "PlayerDrunkSaloon1",
        EffectDuration = 1,
        hunger = 0,
        thirst = 20000,
        stress = 200,
        stamina = 10
    },
    ["cigarette"] = { -- บุหรี่ - ลดเครียด 20% | ไม่อิ่ม ไม่แก้กระหาย
        -- โค้ดรองรับแค่ 2 ท่า (needs.lua:222): "eat" กับที่เหลือทั้งหมดเป็นท่าดื่ม
        -- ท่าดื่มคือยกมือเข้าปาก ใกล้เคียงการสูบที่สุดในบรรดาที่มี
        prop_name = 'p_cigarette01x',
        Animation = "drink",
        Effect = "",
        EffectDuration = "",
        hunger = 0,
        thirst = 0,
        stress = -400,
        stamina = 0
    },

    -- ===== เมนูโต๊ะทำอาหาร Valentine / Rhodes / Annesburg =====
    -- ค่าเทียบสัดส่วนจาก % ใน desc ของแต่ละไอเทม (เพิ่มข้าว/เพิ่มน้ำ/ลดเครียด) โดยอิงสเกลเดียวกับ bread/water/burger/coffeebeans ด้านบน
    ["food_sugarcane_juice"] = { -- น้ำอ้อย (Valentine) - เพิ่มน้ำ70% ลดเครียด20%
        prop_name = 'p_water01x',
        Animation = "drink",
        Effect = "",
        EffectDuration = "",
        hunger = 0,
        thirst = 70000,
        stress = -400,
        stamina = 10
    },
    ["food_oxtail_soup"] = { -- ซุปหางวัว (Valentine) - เพิ่มข้าว70% เพิ่มน้ำ40% ลดเครียด30%
        prop_name = 'p_bowl04x_stew',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 70000,
        thirst = 40000,
        stress = -600,
        stamina = 50
    },
    ["food_braised_ribs"] = { -- ตุ๋นซี่โครง (Valentine) - เพิ่มข้าว50% เพิ่มน้ำ20% ลดเครียด20%
        prop_name = 'p_bowl04x_stew',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 50000,
        thirst = 20000,
        stress = -400,
        stamina = 30
    },
    ["food_taco"] = { -- ทาโก้ (Valentine) - เพิ่มข้าว40% เพิ่มน้ำ10% ลดเครียด10%
        prop_name = 'p_bread03x',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 40000,
        thirst = 10000,
        stress = -200,
        stamina = 20
    },

    ["food_orange_juice"] = { -- น้ำส้ม (Rhodes) - เพิ่มน้ำ70% ลดเครียด20%
        prop_name = 'p_water01x',
        Animation = "drink",
        Effect = "",
        EffectDuration = "",
        hunger = 0,
        thirst = 70000,
        stress = -400,
        stamina = 10
    },
    ["food_beef_stew"] = { -- สตูเนื้อ (Rhodes) - เพิ่มข้าว70% เพิ่มน้ำ40% ลดเครียด30%
        prop_name = 'p_bowl04x_stew',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 70000,
        thirst = 40000,
        stress = -600,
        stamina = 50
    },
    ["food_salted_meat_stew"] = { -- เนื้อตุ๋นเกลือ (Rhodes) - เพิ่มข้าว50% เพิ่มน้ำ20% ลดเครียด20%
        prop_name = 'p_bowl04x_stew',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 50000,
        thirst = 20000,
        stress = -400,
        stamina = 30
    },
    ["food_pasta_sauce"] = { -- พาสต้าซอส (Rhodes) - เพิ่มข้าว40% เพิ่มน้ำ10% ลดเครียด10%
        prop_name = 'p_bread03x',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 40000,
        thirst = 10000,
        stress = -200,
        stamina = 20
    },

    ["food_berry_juice"] = { -- น้ำเบอรี่ (Annesburg) - เพิ่มน้ำ70% ลดเครียด20%
        prop_name = 'p_water01x',
        Animation = "drink",
        Effect = "",
        EffectDuration = "",
        hunger = 0,
        thirst = 70000,
        stress = -400,
        stamina = 10
    },
    ["food_herb_roasted_meat"] = { -- เนื้อย่างสมุนไพร (Annesburg) - เพิ่มข้าว70% เพิ่มน้ำ40% ลดเครียด30%
        prop_name = 'p_bowl04x_stew',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 70000,
        thirst = 40000,
        stress = -600,
        stamina = 50
    },
    ["food_mushroom_rib_soup"] = { -- ต้มซี่โครงเห็ด (Annesburg) - เพิ่มข้าว50% เพิ่มน้ำ20% ลดเครียด20%
        prop_name = 'p_bowl04x_stew',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 50000,
        thirst = 20000,
        stress = -400,
        stamina = 30
    },
    ["food_spaghetti"] = { -- สปาเก็ตตี้ (Annesburg) - เพิ่มข้าว40% เพิ่มน้ำ10% ลดเครียด10%
        prop_name = 'p_bread03x',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 40000,
        thirst = 10000,
        stress = -200,
        stamina = 20
    }
}

-- local thirst = exports['MJ-STATUS']:MJ_Shirst() -- ดึงค่าความกระหายของตัวละคร
-- local hunger = exports['MJ-STATUS']:MJ_Hunger() -- ดึงค่าความหิวของตัวละคร
-- local stress = exports['MJ-STATUS']:MJ_Stress() -- ดึงค่าความเครียดของตัวละคร
-- exports["MJ-STATUS"]:AddStress(10) -- เพิ่มค่าความเครียดขึ้น 10 หน่วย

