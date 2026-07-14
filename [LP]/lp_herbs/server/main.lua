-- lp_herbs / server/main.lua
-- ผู้ตัดสินตัวจริงทั้งหมด — client ส่งมาแค่ propKey ("z<zoneIdx>_h<herbIdx>") ของต้นที่อ้างว่า
-- เก็บเสร็จ. server derive ชนิด/เมืองจาก config เอง (client โกงชนิด/จำนวนไม่ได้), เช็คว่าผู้เล่น
-- ยืนในโซนจริงด้วยพิกัดที่ server รู้เอง, บังคับ per-prop cooldown เอง, canCarry ก่อนแจก, มี
-- rate-limit กันสแปมยิงตรง, cleanup ตอน playerDropped. (ตาม 12-point security checklist)

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

RegisterServerEvent('lp_herbs:sv:gather', function(propKey)
    local src = source

    -- rate-limit รวม: กันสแปมยิงตรงเพื่อดูป (การเก็บจริงกินเวลา GatherDuration อยู่แล้ว)
    if ratelimited(src, (Config.GatherDuration or 9) * 800) then
        dbg('reject src=%s: rate-limited', src); return
    end

    local zone, herb = resolveGather(src, propKey)
    if not zone or not herb then return end -- resolveGather log เหตุผลแล้ว

    -- per-prop cooldown ฝั่ง server (client แก้ usedUntil เองไม่มีผล)
    local now = GetGameTimer()
    propCd[src] = propCd[src] or {}
    local last = propCd[src][propKey]
    if last and (now - last) < ((Config.Cooldown or 60) * 1000) then
        notify(src, 'info', 'ต้นนี้เพิ่งเก็บไป รอสักครู่', 3000)
        return
    end

    -- canCarry ก่อนแจกเสมอ
    local amount = Config.Amount or 1
    if not exports.vorp_inventory:canCarryItem(src, herb.item, amount) then
        notify(src, 'warning', 'กระเป๋าเต็ม — ' .. (herb.label or herb.item), 4000)
        return
    end

    -- ผ่านครบ -> ล็อก cooldown + rate-limit ก่อนแจก (กัน race), แล้วแจกจริง
    propCd[src][propKey] = now
    cooldowns[src]       = now

    exports.vorp_inventory:addItem(src, herb.item, amount)
    notify(src, 'success', ('เก็บ%sสำเร็จ +%d'):format(herb.label or herb.item, amount), 4000)
    TriggerClientEvent('lp_herbs:cl:awarded', src, herb.item)

    -- soft integration กับ lp_leaderboard (ถ้ามี) — เงียบถ้าไม่มี resource นี้ (แนบ src เอง)
    TriggerEvent('lp_leaderboard:SV:HerbGather', { src = src, amount = amount })

    logTx('grant src=%s zone=%s herb=%s x%d', src, zone.town, herb.item, amount)
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
    propCd[source]    = nil
end)
