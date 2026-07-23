-- ═══════════════════════════════════════════════════════════════════════════
--  lp_stablehook — ปิดปุ่ม "มอบม้า/มอบเกวียน" (bequeath) ของ kd_stable
--
--  ทำไมต้องทำแบบนี้:
--  kd_stable เป็น escrow (.fxap) แก้โค้ดไม่ได้ และ "ไม่มีวิธีปิด bequeath ที่รองรับเลย"
--  (เช็คครบแล้ว: ไม่มี config flag / ไม่มี Config restriction function / ไม่มี server filter /
--   ไม่มี export เปลี่ยนเจ้าของม้า / Config.keys.bequeath = false ก็ทดสอบแล้วไม่มีผล)
--
--  ทางที่ใช้ได้คือ client filter "updatePreviewPrompt" ซึ่ง:
--      arg1 = currentPrompt  → ชื่อ prompt เป็นสตริง เช่น "bequeath"  ← ค่านี้คือค่าที่ filter คืน
--      arg2 = itemMenuData   → { current, data, item, menu }
--                              item.action = "bequeathHorse", menu = "horseManager"
--
--  คืน false แทน "bequeath" → kd_stable เอาไปเปิดหา Config.keys[...] ได้ nil
--  → jo.prompt.create() เจอ guard `if not group or not key then return false end`
--    (jo_libs/modules/prompt/client.lua:198) → prompt ไม่ถูกสร้าง = ผู้เล่นกดไม่ได้
--
--  ⚠️ ปิดได้แค่ "ปุ่มฝั่ง client" เท่านั้น — โค้ด server ของ kd_stable ที่รับคำสั่งมอบยังอยู่
--     (escrow แก้ไม่ได้ และไม่มี hook ให้บล็อก) คนที่ยิง event เองเป็นยังทำได้
-- ═══════════════════════════════════════════════════════════════════════════

local dumped = {} -- [filterName] = จำนวนครั้งที่พิมพ์ไปแล้ว

-- ── ตัวช่วย dump (ปิดไว้ default — เปิดใน config ถ้าจะสำรวจโครงสร้างเมนูเพิ่ม) ──

local function preview(v)
    local t = type(v)
    if t == 'string' then
        if #v > 60 then return ('"%s..." (ยาว %d)'):format(v:sub(1, 60), #v) end
        return ('"%s"'):format(v)
    elseif t == 'number' or t == 'boolean' then
        return tostring(v)
    elseif t == 'function' then
        return '<function>'
    elseif t == 'table' then
        local n = 0
        for _ in pairs(v) do n = n + 1 end
        return ('<table %d key>'):format(n)
    end
    return ('<%s>'):format(t)
end

local function dumpTable(tbl, indent, depth, maxDepth)
    local keys = {}
    for k in pairs(tbl) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

    for _, k in ipairs(keys) do
        local v = tbl[k]
        print(('%s%s = %s'):format(indent, tostring(k), preview(v)))
        if type(v) == 'table' and depth < maxDepth then
            dumpTable(v, indent .. '    ', depth + 1, maxDepth)
        end
    end
end

local function dumpValue(filterName, label, value)
    local cfg = Config.Dump
    dumped[filterName] = (dumped[filterName] or 0) + 1

    print(('^3[lp_stablehook]^7 ===== %s / %s (ครั้งที่ %d) ====='):format(
        filterName, label, dumped[filterName]))

    if type(value) == 'table' then
        dumpTable(value, '    ', 1, cfg.maxDepth or 3)
    else
        print('    ' .. preview(value))
    end

    if dumped[filterName] >= (cfg.limitPerFilter or 2) then
        print(('^3[lp_stablehook]^7 %s: ครบโควตาพิมพ์แล้ว หยุดพิมพ์ (restart resource เพื่อดูใหม่)')
            :format(filterName))
    end
end

local function shouldDump(filterName)
    local cfg = Config.Dump
    if not cfg or cfg.enabled ~= true then return false end
    return (dumped[filterName] or 0) < (cfg.limitPerFilter or 2)
end

-- ── ปิด prompt bequeath ──────────────────────────────────────────────────────
-- เทียบชื่อแบบ normalize (เผื่อ kd_stable เปลี่ยน case ในเวอร์ชันหน้า)
local blockedPrompts = {}
for _, name in ipairs(Config.BlockPrompts or {}) do
    blockedPrompts[tostring(name):lower()] = true
end

local blockedCount = 0

-- คืนค่าที่ควรส่งกลับให้ kd_stable สำหรับ filter updatePreviewPrompt
local function filterPreviewPrompt(currentPrompt, itemMenuData)
    if not Config.DisableBequeath then return currentPrompt end
    if type(currentPrompt) ~= 'string' then return currentPrompt end

    if not blockedPrompts[currentPrompt:lower()] then
        return currentPrompt
    end

    blockedCount = blockedCount + 1
    if Config.Debug then
        local action = itemMenuData and itemMenuData.item and itemMenuData.item.action
        print(('^2[lp_stablehook]^7 บล็อก prompt "%s" (action=%s) ครั้งที่ %d')
            :format(currentPrompt, tostring(action), blockedCount))
    end

    -- false → Config.keys[false] = nil → jo.prompt.create เจอ guard แล้ว return ทันที
    -- ไม่สร้าง prompt และไม่ไปถึง GetHashFromString ที่จะพังถ้าได้ค่าไม่ใช่สตริง
    return false
end

-- ── ลงทะเบียน filter ─────────────────────────────────────────────────────────
-- ⚠️ filter ต้องคืนค่าเสมอ ไม่งั้นเมนู kd_stable จะเพี้ยน
-- (jo_libs ห่อ callback ด้วย pcall อยู่แล้ว — error จะคงค่าเดิมไว้ให้ แต่ไม่ควรพึ่ง)
CreateThread(function()
    Wait(2000) -- เผื่อ kd_stable ยังประกาศ export ไม่เสร็จ

    -- รวมชื่อ filter ที่ต้องดัก: ตัวที่จะ dump + ตัวที่ใช้บล็อก (ไม่ให้ซ้ำ)
    local wanted, seen = {}, {}
    local function want(name)
        if name and not seen[name] then
            seen[name] = true
            wanted[#wanted + 1] = name
        end
    end

    want('updatePreviewPrompt') -- ตัวที่ใช้บล็อก bequeath — ต้องมีเสมอ
    if Config.Dump and Config.Dump.enabled then
        for _, name in ipairs(Config.Filters or {}) do want(name) end
    end

    for _, filterName in ipairs(wanted) do
        local ok, err = pcall(function()
            exports.kd_stable:registerFilter(filterName, function(value, extra)
                if shouldDump(filterName) then
                    dumpValue(filterName, 'arg1', value)
                    if extra ~= nil then
                        dumpValue(filterName, 'arg2', extra)
                    end
                end

                if filterName == 'updatePreviewPrompt' then
                    return filterPreviewPrompt(value, extra)
                end

                return value -- filter อื่นเป็นแค่การสังเกต ไม่แก้อะไร
            end)
        end)

        if not ok then
            print(('^1[lp_stablehook]^7 ดัก filter "%s" ไม่สำเร็จ: %s'):format(filterName, tostring(err)))
        elseif Config.Debug then
            print(('^2[lp_stablehook]^7 ดัก filter "%s" แล้ว'):format(filterName))
        end
    end

    if Config.DisableBequeath then
        print('^2[lp_stablehook]^7 ปิดปุ่มมอบม้า/เกวียน (bequeath) แล้ว')
    end
end)
