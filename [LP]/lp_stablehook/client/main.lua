-- ═══════════════════════════════════════════════════════════════════════════
--  เฟสแรก: dump โครงสร้างที่ kd_stable ส่งเข้า filter
--
--  ⚠️ ตัวนี้ "ไม่แก้อะไร" — คืนค่าเดิมกลับไปทุกครั้ง แค่พิมพ์ให้ดูว่าข้างในมีอะไร
--  พอรู้ว่าปุ่ม bequeath (มอบม้า) เก็บเป็น field ชื่ออะไร ค่อยเขียนตัวลบจริงทับไฟล์นี้
--
--  ดู log ที่ F8 console ในเกม (เป็น client filter ไม่ใช่ server)
-- ═══════════════════════════════════════════════════════════════════════════

local dumped = {} -- [filterName] = จำนวนครั้งที่พิมพ์ไปแล้ว

-- แสดงค่าแบบย่อ ไม่ให้ string ยาวหรือ table ใหญ่ระเบิดคอนโซล
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
    -- เรียงคีย์ให้อ่านง่าย (คีย์ปนตัวเลข/สตริงได้ เลยเทียบด้วย tostring)
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

-- ── ลงทะเบียน filter ─────────────────────────────────────────────────────────
-- ⚠️ filter ต้อง "คืนค่าเดิม" เสมอ ไม่งั้นเมนูของ kd_stable จะเพี้ยน/หาย
-- (jo_libs ห่อ callback ด้วย pcall อยู่แล้ว ถ้า error มันจะคงค่าเดิมไว้ให้ — แต่ก็ไม่ควรพึ่ง)
CreateThread(function()
    -- เผื่อ kd_stable ยังไม่ประกาศ export ตอน resource นี้เพิ่งขึ้น
    Wait(2000)

    for _, filterName in ipairs(Config.Filters or {}) do
        local ok, err = pcall(function()
            exports.kd_stable:registerFilter(filterName, function(value, extra)
                if shouldDump(filterName) then
                    -- filterYourHorseLine ส่ง (item, horseData) — โชว์ทั้งคู่
                    -- filterHorseData ส่ง (horseData) เดี่ยวๆ — extra จะเป็น nil
                    dumpValue(filterName, 'arg1', value)
                    if extra ~= nil then
                        dumpValue(filterName, 'arg2', extra)
                    end
                end
                return value -- ไม่แก้อะไร คืนของเดิมกลับไป
            end)
        end)

        if ok then
            print(('^2[lp_stablehook]^7 ดัก filter "%s" แล้ว'):format(filterName))
        else
            print(('^1[lp_stablehook]^7 ดัก filter "%s" ไม่สำเร็จ: %s'):format(filterName, tostring(err)))
        end
    end

    print('^2[lp_stablehook]^7 พร้อมแล้ว — เปิดเมนูคอกม้า แล้วดู log ที่ F8')
end)
