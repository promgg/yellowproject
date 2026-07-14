-- lp_herbs / config.lua  (shared_script)
-- งานเก็บสมุนไพร — port แนวคิดจาก [VORP]/vorp_herbs แต่รื้อทำใหม่ให้ทำงานสไตล์ MJ-Mining
-- (spawn prop ที่ coords -> กดค้าง E -> progbar -> ได้ของ) โดย server เป็นเจ้าของทุก
-- การตัดสิน (ดู server/main.lua). shared_script นี้เป็น data ล้วน ไม่มีข้อมูลลับ.
--
-- โครงสร้าง (ตกผลึกจาก grill):
--   * 3 โซนตามเมือง ที่พิกัด farm ของ mj_planting (Valentine/Annesburg/Rhodes)
--   * แต่ละโซนมี list สมุนไพร — spawn "1 prop ต่อ 1 ชนิด" (โพซิชันสุ่มกระจาย, ชนิดตายตัว)
--   * 1 prop = 1 ชนิดตายตัว (ไม่สุ่ม roll) — item จาก mj_planting, model จาก vorp_herbs
--   * มือเปล่า ไม่ต้องมี tool

Config = {}

Config.Debug = true -- gate สำหรับ dbg() print (ปิดตอน production)

-- ── การควบคุม / ระยะ / จังหวะ ────────────────────────────────────────────────
Config.KEY_E        = 0x17BEC168 -- E (hold-to-gather)
Config.HoldMs       = 900        -- ms กดค้าง E ก่อนเริ่มเก็บ (เท่า MJ-Mining/MJ-Lumberjack)
Config.GatherRange  = 2.5        -- เมตร — ระยะที่โชว์ hint + server ยอมรับ
Config.StreamRadius = 80.0       -- เมตร — สร้าง prop เฉพาะต้นในรัศมีนี้รอบผู้เล่น ลบเมื่อออกไกล
Config.GatherDuration = 9        -- วินาที — ความยาว progbar ต่อการเก็บ 1 ต้น
Config.Cooldown     = 60         -- วินาที — ต้นเดิมเก็บซ้ำได้อีกครั้งเมื่อครบเวลานี้ (server คุม)
Config.Amount       = 1          -- จำนวน item ต่อการเก็บ 1 ครั้ง

-- อนิเมชันตอนเก็บ (lp_progbar เล่นให้ตลอด duration) — เดิมใช้ scenario 'WORLD_HUMAN_GARDENER_PLANT'
-- แต่ไม่เล่น (scenario ไม่มีจริง/ไม่ตรงกับที่ TaskStartScenarioInPlace ต้องการ) เปลี่ยนมาใช้ท่า
-- "เก็บเกี่ยว" ตัวเดียวกับ MJ-Planting (ยืนยันแล้วว่าเล่นได้จริงจาก core/client_core.lua บรรทัด
-- harvest action) — animDict/anim คู่ ไม่ใช่ scenario
Config.GatherAnim = { animDict = 'mech_pickup@plant@berries', anim = 'base' }

-- ── คลังสมุนไพร (ดึงจาก vorp_herbs ไว้เป็นข้อมูลกลาง) ─────────────────────────
-- ทุก entry = { item, label, model } — เอาไว้เลือกไปใส่ในโซนด้านล่าง (Config.Zones[].herbs)
-- item เหล่านี้มาจาก DB ของ vorp_herbs (มีอยู่แล้วในเซิร์ฟที่เคยรัน vorp_herbs) — คลังนี้ไม่ได้
-- ถูกใช้โดยตรงในเกม เป็นแค่ reference ให้ copy ไปวางในโซน (โซนทดลองด้านล่างใช้ item จาก
-- mj_planting ตามที่ตกลง แต่หยิบ model จากคลังนี้)
Config.HerbLibrary = {
    { item = 'blueberry',             label = 'Blueberry',            model = 'rdr_bush_dry_thin_ba_sim' },
    { item = 'Indian_Tobbaco',        label = 'Indian Tobacco',       model = 's_indiantobacco01x' },
    { item = 'cotton',                label = 'Cotton',               model = 'crp_cotton_bd_sim' },
    { item = 'Oregano',               label = 'Oregano',              model = 'rdr_bush_ficus_aa_sim' },
    { item = 'Basil',                 label = 'Basil',                model = 'rdr_bush_bram_aa_sim' },
    { item = 'Agarita',               label = 'Agarita',              model = 'rdr_bush_thick_aa_sim' },
    { item = 'Creeking_Thyme',        label = 'Creeking Thyme',       model = 'rdr_bush_lrg_aa_sim' },
    { item = 'Milk_Weed',             label = 'Milk Weed',            model = 'rdr_bush_bram_dead_aa_sim' },
    { item = 'Crows_Garlic',          label = 'Crows Garlic',         model = 'rdr_bush_brush_grn_aa_sim' },
    { item = 'English_Mace',          label = 'English Mace',         model = 'p_sap_poplar_ab_sim' },
    { item = 'Hummingbird_Sage',      label = 'Hummingbird Sage',     model = 'rdr_bush_thorn_aa_sim' },
    { item = 'Oleander_Sage',         label = 'Oleander Sage',        model = 'rdr_bush_creosotebush' },
    { item = 'Desert_Sage',           label = 'Desert Sage',          model = 'rdr2_bush_desertbroom' },
    { item = 'American_Ginseng',      label = 'American Ginseng',     model = 'rdr_bush_sumac_aa_sim' },
    { item = 'Alaskan_Ginseng',       label = 'Alaskan Ginseng',      model = 'rdr_bush_mang_aa_sim' },
    { item = 'Red_Raspberry',         label = 'Red Raspberry',        model = 'rdr_bush_leafy_aa_sim' },
    { item = 'apple',                 label = 'Apple',                model = 'p_tree_apple_01' },
    { item = 'Grain',                 label = 'Grain',                model = 'crp_wheat_dry_aa_sim' },
    { item = 'Agave',                 label = 'Agave',                model = 'rdr_bush_agave_aa_sim' },
    { item = 'Red_Sage',              label = 'Red Sage',             model = 'rdr_bush_scrub_aa_sim' },
    { item = 'Black_Currant',         label = 'Black Currant',        model = 'blackcurrant_p' },
    { item = 'Bitter_Weed',           label = 'Bitter Weed',          model = 'rdr_bush_aloe_aa_sim' },
    { item = 'Evergreen_Huckleberry', label = 'Evergreen Huckleberry', model = 'rdr2_bush_desertironwood' },
    { item = 'Bulrush',               label = 'Bulrush',              model = 'rdr_bush_cat_tail_aa_sim' },
    { item = 'Wisteria',              label = 'Wisteria',             model = 'p_sap_poplar_aa_sim' },
    { item = 'Wild_Rhubarb',          label = 'Wild Rhubarb',         model = 'rdr2_bush_scruboak' },
    { item = 'sugar',                 label = 'Sugarcane',            model = 'crp_sugarcane_ac_sim' },
}

-- ── โซนเก็บสมุนไพร (3 เมืองทดลอง) ─────────────────────────────────────────────
-- center/radius = โซนที่ต้อง "ยืนอยู่ใน" ถึงจะเก็บได้ (server คำนวณเมืองจากพิกัดจริงเทียบ
--   center/radius นี้เอง ไม่เชื่อ client) — พิกัดยกมาจาก MJ-Planting farm ของแต่ละเมือง
-- scatter/minSpacing = สุ่มกระจายตำแหน่ง prop รอบ center (กันวางทับกัน)
-- herbs = list สมุนไพรของโซน (item จาก mj_planting, model จากคลังด้านบน) — spawn "1 prop
--   ต่อ 1 ชนิด" (โพซิชันสุ่ม, ชนิดตายตัวตาม index) => โซนละ #herbs ต้น. ลบ/เพิ่ม entry ตรงนี้
--   ได้เลย (เช่นอยากเหลือ 3 ต้น ก็ลบ 1 ชนิด) — server ยึด index ใน list นี้เป็น id ของชนิด
Config.Zones = {
    {
        name   = 'Valentine Herbs',
        town   = 'Valentine',
        center = vector3(-847.4569, 320.4838, 95.5757),
        radius = 25.0,
        scatter = 18.0, -- รัศมีสุ่มกระจาย prop รอบ center
        minSpacing = 5.0,
        blip = { sprite = 'blip_ambient_hitching_post', color = 'COLOR_GREEN', name = 'เก็บสมุนไพร - Valentine' },
        herbs = {
            { item = 'job_corn',       label = 'ข้าวโพด',  model = 'crp_wheat_dry_aa_sim' },
            { item = 'job_carrot',     label = 'แครอท',    model = 'rdr_bush_ficus_aa_sim' },
            { item = 'job_Yarrow',     label = 'ยาร์โรว์', model = 'rdr_bush_thick_aa_sim' },
            { item = 'job_sugarcane',  label = 'อ้อย',     model = 'crp_sugarcane_ac_sim' },
        },
    },
    {
        name   = 'Annesburg Herbs',
        town   = 'Annesburg',
        center = vector3(2967.7837, 773.5686, 51.3994),
        radius = 25.0,
        scatter = 18.0,
        minSpacing = 5.0,
        blip = { sprite = 'blip_ambient_hitching_post', color = 'COLOR_GREEN', name = 'เก็บสมุนไพร - Annesburg' },
        herbs = {
            { item = 'job_mushroom', label = 'เห็ดป่า', model = 'rdr_bush_aloe_aa_sim' },
            { item = 'job_Ginseng',  label = 'โสม',     model = 'rdr_bush_sumac_aa_sim' },
            { item = 'job_opium',    label = 'ฝิ่น',    model = 'rdr_bush_creosotebush' },
            { item = 'job_berry',    label = 'เบอรี่',  model = 'rdr_bush_leafy_aa_sim' },
        },
    },
    {
        name   = 'Rhodes Herbs',
        town   = 'Rhodes',
        center = vector3(969.6452, -1962.3392, 47.4799),
        radius = 25.0,
        scatter = 18.0,
        minSpacing = 5.0,
        blip = { sprite = 'blip_ambient_hitching_post', color = 'COLOR_GREEN', name = 'เก็บสมุนไพร - Rhodes' },
        herbs = {
            { item = 'job_tobacco_plant', label = 'ยาสูบ',    model = 's_indiantobacco01x' },
            { item = 'job_barley',        label = 'บาร์เลย์', model = 'crp_wheat_dry_aa_sim' },
            { item = 'job_cotton',        label = 'ฝ้าย',     model = 'crp_cotton_bd_sim' },
            { item = 'job_orange',        label = 'ส้ม',      model = 'rdr_bush_thick_aa_sim' },
        },
    },
}

-- ── คำนวณตำแหน่ง prop แบบ deterministic (ทำครั้งเดียวตอน config โหลด — shared_script รันทั้งฝั่ง
-- client และ server อิสระต่อกัน) ── ปัญหาที่แก้: ถ้าใช้ math.randomseed(GetGameTimer()) แบบ
-- MJ-Mining ต้นแบบ แต่ละ client จะสุ่มตำแหน่งไม่ตรงกัน (ผู้เล่นเห็น "ข้าวโพด" อยู่คนละจุดกัน) และ
-- server จะไม่มีทางรู้พิกัด prop จริงเลย (เช็คระยะได้แค่ "อยู่ในโซนกว้างๆ" ไม่เช็คระยะถึง prop จริง)
-- ── ใช้ seed คงที่ต่อ (zoneIdx, herbIdx) แทน: math.random ด้วย seed เดียวกันให้ sequence เดียวกัน
-- เป๊ะทุก client/server เสมอ (Lua PRNG deterministic) ผลคือพิกัดตรงกัน 100% โดยไม่ต้อง sync เครือข่าย
-- เลย และ server ใช้ herb.coords เช็คระยะจริงได้ (ดู server/main.lua resolveGather)
do
    local function isSpacedFrom(placed, x, y, minSpacing)
        local m2 = minSpacing * minSpacing
        for _, p in ipairs(placed) do
            local dx, dy = p.x - x, p.y - y
            if (dx * dx + dy * dy) < m2 then return false end
        end
        return true
    end

    local function pickRandomXY(center, radius)
        local ang  = math.random() * 2 * math.pi
        local dist = math.sqrt(math.random()) * radius
        return center.x + math.cos(ang) * dist, center.y + math.sin(ang) * dist
    end

    for zi, zone in ipairs(Config.Zones) do
        local scatter    = zone.scatter or 15.0
        local minSpacing = zone.minSpacing or 5.0
        local placed = {}
        for hi, herb in ipairs(zone.herbs) do
            math.randomseed(zi * 1009 + hi) -- คงที่ต่อ (zone,herb) — ไม่ใช้เวลา/client เป็น seed
            local x, y, attempt = nil, nil, 0
            repeat
                attempt = attempt + 1
                local cx, cy = pickRandomXY(zone.center, scatter)
                if isSpacedFrom(placed, cx, cy, minSpacing) then x, y = cx, cy end
            until (x and y) or attempt >= 40
            if not x then x, y = pickRandomXY(zone.center, scatter) end
            herb.coords = vector3(x, y, zone.center.z)
            herb.key    = ('z%d_h%d'):format(zi, hi)
            placed[#placed + 1] = { x = x, y = y }
        end
    end
end

-- ── โหมดสแกน (prop จริงทั่วแมพ) ────────────────────────────────────────────────
-- เพิ่มเข้ามาคู่กับ Config.Zones เดิม (ไม่แตะของเดิมเลย) — สแกนหา prop จริงที่ Rockstar
-- วางไว้ในแมพ (ไม่ใช่ prop ปลอมที่ client spawn เอง) จำกัดเฉพาะ 12 ชนิดที่มีอยู่แล้วในโซนด้านบน
-- ใช้ค่า UX เดิมทั้งหมด (GatherRange/GatherDuration/GatherAnim/HoldMs/Cooldown/Amount) ไม่แยกชุดใหม่
Config.Scan = {
    Enabled    = true,
    ThrottleMs = 400, -- ทุก 400ms (ไม่ใช่ทุกเฟรมแบบ vorp_herbs) กันภาระ client เกินจำเป็น
}

-- คีย์ cooldown แบบราย (ผู้เล่น, จุดโดยประมาณ) ปัดพิกัดจริงเป็นจำนวนเต็มเมตร — pure function
-- ไม่มี native เลย เรียกได้ทั้ง client (cache local UX) และ server (cooldown จริง) ปลอดภัยใน shared_script
function Config.coordsKey(v)
    return ('%d_%d_%d'):format(math.floor(v.x), math.floor(v.y), math.floor(v.z))
end

-- Config.ScanModels: ดึงโมเดลจาก Config.Zones มา dedupe (โมเดลไหนซ้ำกัน 2 ชนิด เอาตัวที่เจอก่อน
-- ตามลำดับ zone/herb ที่ประกาศไว้ด้านบน) => job_corn ชนะ job_barley, job_Yarrow ชนะ job_orange
-- โดยอัตโนมัติ ไม่ต้อง special-case เพราะ Valentine (zone 1) ประกาศก่อน Rhodes (zone 3) อยู่แล้ว
-- ไม่มี field coords (ต่างจาก Config.Zones) เพราะตำแหน่ง prop จริงในโลกไม่ deterministic
-- หมายเหตุ: คำนวณ GetHashKey(model) ที่นี่ไม่ได้ (native เรียกใน shared_script build step ไม่ได้)
-- ต้องให้แต่ละฝั่งที่ต้องใช้ hash (จริงๆ มีแค่ client) ไป GetHashKey เองตอน runtime
do
    local seenModel = {}
    Config.ScanModels = {}
    for _, zone in ipairs(Config.Zones) do
        for _, herb in ipairs(zone.herbs) do
            if not seenModel[herb.model] then
                seenModel[herb.model] = true
                Config.ScanModels[#Config.ScanModels + 1] = { model = herb.model, item = herb.item, label = herb.label }
            end
        end
    end
end
