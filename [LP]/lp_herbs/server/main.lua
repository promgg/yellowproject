-- lp_herbs / server/main.lua
-- ผู้ตัดสินตัวจริงทั้งหมด — client ส่งมาแค่ propKey ของต้นที่อ้างว่าเก็บเสร็จ:
--   โหมดโซน "z<zoneIdx>_h<herbIdx>" — server derive ชนิด/เมือง/พิกัดจาก config เองทั้งหมด
--   โหมดสแกน "s<scanIdx>" + พิกัดจริงที่ client รายงาน — server derive ชนิดจาก Config.ScanModels
--     เอง (ไม่เชื่อชื่อไอเทมจาก client เด็ดขาด) และเช็คแค่ระยะจากตัวผู้เล่นจริงถึงพิกัดที่รายงาน
--     (พิสูจน์ว่ามี prop จริงอยู่ตรงนั้นจริงไหมทำไม่ได้ในหลักการ — native ตรวจ prop สภาพแวดล้อม
--     เป็น client-apiset เท่านั้น ไม่มีทาง verify ฝั่ง server ได้เลย นี่คือ mitigation ที่ทำได้จริง
--     ตรงกับ pattern ของ vorp_mining/vorp_lumberjack ในโปรเจกต์นี้)
-- ทั้งสองโหมด: บังคับ per-(player,spot) cooldown เอง, canCarry ก่อนแจก, มี rate-limit กันสแปมยิงตรง,
-- cleanup ตอน playerDropped. (ตาม 12-point security checklist)

local function dbg(fmt, ...) if Config.Debug then print(('[lp_herbs] ' .. fmt):format(...)) end end
-- always-on (ไม่ผูกกับ Config.Debug) — การแจกไอเทมเป็น transaction ควร log ได้แม้ปิด debug ใน production
local function logTx(fmt, ...) print(('[lp_herbs][TX] ' .. fmt):format(...)) end
local function notify(src, kind, text, timeout)
    TriggerClientEvent('lp_herbs:cl:notify', src, kind, text, timeout)
end

-- ── anti-spam / anti-dupe (server-side) ──────────────────────────────────────
local cooldowns = {} -- [src] = GetGameTimer() ล่าสุดที่เก็บสำเร็จ (rate limit รวม)
local propCd    = {} -- [src][propKey] = GetGameTimer() (per-prop cooldown)

local function ratelimited(src, minMs)
    local t = GetGameTimer()
    if cooldowns[src] and (t - cooldowns[src]) < minMs then return true end
    return false
end

-- เมือง/ชนิด derive จาก propKey + พิกัดจริง ไม่เชื่อ client:
--   propKey "z<zi>_h<hi>" -> zone = Config.Zones[zi], herb = zone.herbs[hi]
--   herb.coords คำนวณ deterministic ไว้แล้วใน config.lua (เหมือนกันเป๊ะกับที่ client เห็น) —
--   เช็คระยะถึง prop จริง ไม่ใช่แค่ "อยู่ในโซนกว้างๆ" (ปิดช่องยิง propKey ข้ามจุดโดยไม่เดินไปหา)
local function resolveGather(src, propKey)
    if type(propKey) ~= 'string' then return nil end
    local zi, hi = propKey:match('^z(%d+)_h(%d+)$')
    zi, hi = tonumber(zi), tonumber(hi)
    if not zi or not hi then return nil end

    local zone = Config.Zones[zi]
    if not zone then return nil end
    local herb = zone.herbs[hi]
    if not herb or not herb.coords then return nil end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local pc = GetEntityCoords(ped)
    local dist = #(pc - herb.coords)
    if dist > ((Config.GatherRange or 2.5) + 1.0) then
        dbg('reject src=%s key=%s: too far (%.1fm)', src, propKey, dist)
        return nil
    end

    return zone, herb
end

-- โหมดสแกน: server ไม่มีทาง verify ว่ามี prop จริงอยู่ที่พิกัดนี้จริงไหม (ข้อจำกัดเอนจิ้น ไม่ใช่
-- ทางลัด) — เชื่อได้แค่ว่า scanIdx ต้องอยู่ใน Config.ScanModels จริง (ชนิดไอเทม derive จากตรงนี้
-- เท่านั้น ไม่เชื่อ client เลย) แล้วเช็คระยะจากตัวผู้เล่นจริงถึงพิกัดที่รายงานมา (mitigation เดียวกับ
-- resolveGather ด้านบน แต่เทียบกับพิกัดที่ client ส่งมาแทนพิกัด config)
local function resolveScanGather(src, scanIdx, reportedCoords)
    if type(scanIdx) ~= 'number' then return nil end
    local sm = Config.ScanModels and Config.ScanModels[scanIdx]
    if not sm then return nil end

    if type(reportedCoords) ~= 'vector3' then
        dbg('reject src=%s scan=%s: bad coords type', src, tostring(scanIdx))
        return nil
    end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local pc = GetEntityCoords(ped)
    local dist = #(pc - reportedCoords)
    if dist > ((Config.GatherRange or 2.5) + 1.0) then
        dbg('reject src=%s scan=%d: too far (%.1fm)', src, scanIdx, dist)
        return nil
    end

    return sm
end

-- แจกของจริง (canCarry -> addItem -> notify -> cl:awarded -> leaderboard -> log) ใช้ร่วมกันทั้ง
-- โหมดโซนและโหมดสแกน กันโค้ดซ้ำ — คืน true ถ้าแจกสำเร็จ (ผู้เรียกต้องล็อก cooldown เองถ้าได้ true)
local function grantHerb(src, item, label, amount, sourceTag)
    if not exports.vorp_inventory:canCarryItem(src, item, amount) then
        notify(src, 'warning', 'กระเป๋าเต็ม — ' .. (label or item), 4000)
        return false
    end

    exports.vorp_inventory:addItem(src, item, amount)
    notify(src, 'success', ('เก็บ%sสำเร็จ +%d'):format(label or item, amount), 4000)
    TriggerClientEvent('lp_herbs:cl:awarded', src, item)

    -- soft integration กับ lp_leaderboard (ถ้ามี) — เงียบถ้าไม่มี resource นี้ (แนบ src เอง)
    TriggerEvent('lp_leaderboard:SV:HerbGather', { src = src, amount = amount })

    logTx('grant src=%s mode=%s item=%s x%d', src, sourceTag, item, amount)
    return true
end

RegisterServerEvent('lp_herbs:sv:gather', function(propKey, reportedCoords)
    local src = source

    -- rate-limit รวม: กันสแปมยิงตรงเพื่อดูป (การเก็บจริงกินเวลา GatherDuration อยู่แล้ว)
    if ratelimited(src, (Config.GatherDuration or 9) * 800) then
        dbg('reject src=%s: rate-limited', src); return
    end
    if type(propKey) ~= 'string' then return end

    local zi, hi = propKey:match('^z(%d+)_h(%d+)$')
    if zi and hi then
        -- ── โหมดโซน (พฤติกรรมเดิมทุกจุด) ──
        local zone, herb = resolveGather(src, propKey)
        if not zone or not herb then return end -- resolveGather log เหตุผลแล้ว

        local now = GetGameTimer()
        propCd[src] = propCd[src] or {}
        local last = propCd[src][propKey]
        if last and (now - last) < ((Config.Cooldown or 60) * 1000) then
            notify(src, 'info', 'ต้นนี้เพิ่งเก็บไป รอสักครู่', 3000)
            return
        end

        if grantHerb(src, herb.item, herb.label, Config.Amount or 1, 'zone') then
            propCd[src][propKey] = now
            cooldowns[src]       = now
        end
        return
    end

    local si = propKey:match('^s(%d+)$')
    if si then
        -- ── โหมดสแกน (ใหม่) ──
        local scanIdx = tonumber(si)
        local sm = resolveScanGather(src, scanIdx, reportedCoords)
        if not sm then return end -- resolveScanGather log เหตุผลแล้ว

        -- คีย์ cooldown ผูกกับจุดโดยประมาณ ไม่ใช่แค่ชนิด (คนละจุดของพืชชนิดเดียวกันไม่ควรติด
        -- cooldown ร่วมกัน) — prefix 's' ต่างจาก 'z' ของโซน ชนกันไม่ได้แม้ใช้ table เดียวกัน
        local cdKey = ('s%d_%s'):format(scanIdx, Config.coordsKey(reportedCoords))
        local now = GetGameTimer()
        propCd[src] = propCd[src] or {}
        local last = propCd[src][cdKey]
        if last and (now - last) < ((Config.Cooldown or 60) * 1000) then
            notify(src, 'info', 'ต้นนี้เพิ่งเก็บไป รอสักครู่', 3000)
            return
        end

        if grantHerb(src, sm.item, sm.label, Config.Amount or 1, 'scan') then
            propCd[src][cdKey] = now
            cooldowns[src]     = now
        end
        return
    end

    dbg('reject src=%s: unrecognized key format %s', src, tostring(propKey))
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
    propCd[source]    = nil -- เคลียร์ทั้ง key โซน (z...) และสแกน (s...) ในทีเดียว อยู่ table เดียวกัน
end)
