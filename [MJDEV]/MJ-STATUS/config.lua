
-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 

Config = {}
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
Config.SaveStatusTickInterval = 300000 -- 5 minutes
Config.HungerTickInterval = 80000  -- ความหิวจะลดลงทุก ๆ 90 วินาที
Config.ThirstTickInterval  = 75000  -- ความกระหายจะลดลงทุก ๆ 75 วินาที
Config.StressTickInterval = 90000   -- กำหนดให้ค่าความเครียดลดลงทุก ๆ 60 วินาที

Config.FoodItems = {
    ["bread"] = {
        prop_name = 'p_bread03x', -- โมเดลของขนมปัง
        Animation = "eat", -- แอนิเมชันกิน
        Effect = "",
        EffectDuration = "",
        hunger = 3000, -- เพิ่มค่าความหิว
        thirst = 0, -- ไม่เพิ่มค่ากระหาย
        stress = -1000, -- ลดค่าความเครียด
        stamina = 10 -- เพิ่มค่า Stamina
    },
    ["water"] = {
        prop_name = 'p_water01x',
        Animation = "drink",
        Effect = "",
        EffectDuration = "",
        hunger = 0,
        thirst = 4000,
        stress = -1000,
        stamina = 10
    },
    ["burger"] = {
        prop_name = 'prop_food_bs_burger',
        Animation = "eat",
        Effect = "PlayerDrunkSaloon1",
        EffectDuration = 1,
        hunger = 5000,
        thirst = 10,
        stress = -10,
        stamina = 10
    },
    ["coffeebeans"] = {
        prop_name = 'p_mugcoffee01x',
        Animation = "drink",
        Effect = "",
        EffectDuration = "",
        hunger = 5000,
        thirst = 2000,
        stress = -1500,
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
        hunger = 2000,
        thirst = 800,
        stress = 0,
        stamina = 10
    },
    ["food_bread"] = { -- ขนมปัง - เพิ่มอิ่ม 10% | นํ้า 5%
        prop_name = 'p_bread03x',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 1500,
        thirst = 500,
        stress = 0,
        stamina = 10
    },
    ["food_coffee"] = { -- กาแฟ - เพิ่มนํ้า 10% | ลดเครียด 20%
        prop_name = 'p_mugcoffee01x',
        Animation = "drink",
        Effect = "",
        EffectDuration = "",
        hunger = 0,
        thirst = 500,
        stress = -1000,
        stamina = 10
    },

    -- ===== เมนูโต๊ะทำอาหาร Valentine / Rhodes / Annesburg =====
    -- ค่าเทียบสัดส่วนจาก % ใน desc ของแต่ละไอเทม (เพิ่มข้าว/เพิ่มน้ำ/ลดเครียด) โดยอิงสเกลเดียวกับ bread/water/burger/coffeebeans ด้านบน
    ["food_sugarcane_juice"] = { -- น้ำอ้อย (Valentine) - เพิ่มน้ำ70% ลดเครียด20%
        prop_name = 'p_water01x',
        Animation = "drink",
        Effect = "",
        EffectDuration = "",
        hunger = 0,
        thirst = 4500,
        stress = -1000,
        stamina = 10
    },
    ["food_oxtail_soup"] = { -- ซุปหางวัว (Valentine) - เพิ่มข้าว70% เพิ่มน้ำ40% ลดเครียด30%
        prop_name = 'p_bowl04x_stew',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 5000,
        thirst = 2500,
        stress = -1500,
        stamina = 50
    },
    ["food_braised_ribs"] = { -- ตุ๋นซี่โครง (Valentine) - เพิ่มข้าว50% เพิ่มน้ำ20% ลดเครียด20%
        prop_name = 'p_bowl04x_stew',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 3500,
        thirst = 1000,
        stress = -1000,
        stamina = 30
    },
    ["food_taco"] = { -- ทาโก้ (Valentine) - เพิ่มข้าว40% เพิ่มน้ำ10% ลดเครียด10%
        prop_name = 'p_bread03x',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 2500,
        thirst = 500,
        stress = -500,
        stamina = 20
    },

    ["food_orange_juice"] = { -- น้ำส้ม (Rhodes) - เพิ่มน้ำ70% ลดเครียด20%
        prop_name = 'p_water01x',
        Animation = "drink",
        Effect = "",
        EffectDuration = "",
        hunger = 0,
        thirst = 4500,
        stress = -1000,
        stamina = 10
    },
    ["food_beef_stew"] = { -- สตูเนื้อ (Rhodes) - เพิ่มข้าว70% เพิ่มน้ำ40% ลดเครียด30%
        prop_name = 'p_bowl04x_stew',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 5000,
        thirst = 2500,
        stress = -1500,
        stamina = 50
    },
    ["food_salted_meat_stew"] = { -- เนื้อตุ๋นเกลือ (Rhodes) - เพิ่มข้าว50% เพิ่มน้ำ20% ลดเครียด20%
        prop_name = 'p_bowl04x_stew',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 3500,
        thirst = 1000,
        stress = -1000,
        stamina = 30
    },
    ["food_pasta_sauce"] = { -- พาสต้าซอส (Rhodes) - เพิ่มข้าว40% เพิ่มน้ำ10% ลดเครียด10%
        prop_name = 'p_bread03x',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 2500,
        thirst = 500,
        stress = -500,
        stamina = 20
    },

    ["food_berry_juice"] = { -- น้ำเบอรี่ (Annesburg) - เพิ่มน้ำ70% ลดเครียด20%
        prop_name = 'p_water01x',
        Animation = "drink",
        Effect = "",
        EffectDuration = "",
        hunger = 0,
        thirst = 4500,
        stress = -1000,
        stamina = 10
    },
    ["food_herb_roasted_meat"] = { -- เนื้อย่างสมุนไพร (Annesburg) - เพิ่มข้าว70% เพิ่มน้ำ40% ลดเครียด30%
        prop_name = 'p_bowl04x_stew',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 5000,
        thirst = 2500,
        stress = -1500,
        stamina = 50
    },
    ["food_mushroom_rib_soup"] = { -- ต้มซี่โครงเห็ด (Annesburg) - เพิ่มข้าว50% เพิ่มน้ำ20% ลดเครียด20%
        prop_name = 'p_bowl04x_stew',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 3500,
        thirst = 1000,
        stress = -1000,
        stamina = 30
    },
    ["food_spaghetti"] = { -- สปาเก็ตตี้ (Annesburg) - เพิ่มข้าว40% เพิ่มน้ำ10% ลดเครียด10%
        prop_name = 'p_bread03x',
        Animation = "eat",
        Effect = "",
        EffectDuration = "",
        hunger = 2500,
        thirst = 500,
        stress = -500,
        stamina = 20
    }
}

-- local thirst = exports['MJ-STATUS']:MJ_Shirst() -- ดึงค่าความกระหายของตัวละคร
-- local hunger = exports['MJ-STATUS']:MJ_Hunger() -- ดึงค่าความหิวของตัวละคร
-- local stress = exports['MJ-STATUS']:MJ_Stress() -- ดึงค่าความเครียดของตัวละคร
-- exports["MJ-STATUS"]:AddStress(10) -- เพิ่มค่าความเครียดขึ้น 10 หน่วย

