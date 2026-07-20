NX_GR = NX_GR or {}
NX_GR.Event = {}

-- ── วงจรชีวิตอีเวนต์สุสานแดนบน ────────────────────────────────────────────────
-- เมืองที่มี Config.GraveZones (valentine/annesburg/rhodes) จะเปิดอีเวนต์วันละครั้ง
-- ตามเวลาใน Config.Villages[id].schedule แล้วปิดตัวเองเมื่อครบ durationMinutes
-- แดนใต้ไม่มีคีย์ใน Config.GraveZones เลยไม่มีอะไรในไฟล์นี้แตะมันทั้งสิ้น

local active = {}          -- [villageId] = state (มีเฉพาะเมืองที่อีเวนต์กำลังรันอยู่)
local lastStartedDay = {}  -- [villageId] = 'YYYY-MM-DD' — กันอีเวนต์รีสตาร์ตซ้ำในวันเดียวกันหลังจบไปแล้ว

local NO_CITY_BUCKET = '__no_city__' -- คนที่ยังไม่ได้เลือกเมืองต้นสังกัด รวมกันเป็นถังเดียว
                                     -- ถ้าปล่อยให้ nil ไม่ถูกนับ คนไม่มีเมืองจะทะลุ cap เข้าได้ไม่จำกัด

local PRESENCE_MIN_INTERVAL_MS = 400  -- กันสแปม zonePresence ตอนเดินเลียบขอบวง
local PRESENCE_MAX_PER_MINUTE  = 40   -- เผื่อไว้มากกว่า Config.Security.maxRequestsPerMinute
                                      -- เพราะ event นี้ยิงตามการเดินจริง ไม่ใช่การกดของผู้เล่น
local presenceGuard = {}   -- [source] = { lastAt = ms, count = n, resetAt = epoch }

local function eventConfig()
    return Config.GraveEvent or {}
end

local function isEnabled()
    return eventConfig().enabled == true
end

local function zoneRadius()
    return eventConfig().zoneRadius or 40.0
end

-- ── state push ไปหา client ────────────────────────────────────────────────────
-- ส่งแค่ข้อมูลที่ client ต้องใช้วาดวง/นับถอยหลัง ไม่ส่งรายชื่อ occupants ออกไป
local function buildPayload()
    local payload = {}
    for villageId, state in pairs(active) do
        payload[#payload + 1] = {
            villageId = villageId,
            label     = state.label,
            coords    = { x = state.coords.x, y = state.coords.y, z = state.coords.z },
            radius    = zoneRadius(),
            sealAt    = state.sealAt,
            endsAt    = state.endsAt,
            sealed    = state.sealed,
            now       = os.time(), -- client ใช้เทียบหา "เหลืออีกกี่วินาที" โดยไม่ต้องเชื่อนาฬิกาเครื่องตัวเอง
        }
    end
    return payload
end

local function pushState(target)
    TriggerClientEvent('nx_graverobbery:client:zoneState', target or -1, buildPayload())
end

-- ── เริ่ม / seal / จบ ─────────────────────────────────────────────────────────
-- เวลาเปิดตามตารางของ "วันนี้" เป็น epoch — ไทม์ไลน์ทั้งหมดอิงจากค่านี้ ไม่ใช่เวลาที่โค้ดเพิ่งสังเกตเห็น
local function scheduledOpenEpoch(villageId)
    local schedule = (Config.Villages[villageId] or {}).schedule
    if not schedule then return nil end
    local now = os.date('*t')
    return os.time({
        year = now.year, month = now.month, day = now.day,
        hour = schedule.openHour or 0, min = schedule.openMinute or 0, sec = 0,
    })
end

-- forced = แอดมินสั่งเปิดเอง ไม่ใช่รอบตามตาราง
local function startEvent(villageId, zone, dayKey, forced)
    local cfg = eventConfig()

    -- ยึดเวลาเปิดตามตารางเป็นจุดตั้งต้น ไม่ใช่ os.time() ตอนที่ thread เพิ่งเห็น
    -- ถ้าเซิร์ฟบูต 13:30 ของรอบ 13:00 อีเวนต์ต้องจบ 14:00 ตามรอบเดิม (และเลยจุด seal ไปแล้ว)
    -- ไม่ใช่เริ่มนับใหม่แล้วลากไปถึง 14:30 ซึ่งกลายเป็นแถมเวลาให้ฟรีทุกครั้งที่รีสตาร์ท
    --
    -- แต่ตอนแอดมินสั่งเปิดเองต้องนับจาก "ตอนนี้" เท่านั้น ไม่งั้นสั่งเปิดตอน 20:00 ของรอบ 13:00
    -- จะได้ sealAt/endsAt ที่ผ่านไปแล้วทั้งคู่ อีเวนต์จะปิดตัวเองทันทีในลูปถัดไป
    local base = (not forced and scheduledOpenEpoch(villageId)) or os.time()

    active[villageId] = {
        villageId = villageId,
        coords    = zone.coords,
        label     = zone.label or villageId,
        startedAt = base,
        sealAt    = base + (cfg.windowMinutes or 8) * 60,
        endsAt    = base + (cfg.durationMinutes or 60) * 60,
        sealed    = false,
        occupants = {}, -- [source] = cityBucket
        allowed   = {}, -- [source] = true — ว่างจนกว่าจะ seal
    }
    lastStartedDay[villageId] = dayKey

    local text = (cfg.announceText or '%s'):format(zone.label or villageId)
    TriggerClientEvent('nx_graverobbery:client:eventAnnounce', -1, text)
    pushState()

    if Config.Debug then
        print(('[nx_graverobbery] event started village=%s seal=%s end=%s'):format(
            villageId, tostring(active[villageId].sealAt), tostring(active[villageId].endsAt)))
    end
end

local function sealEvent(villageId, state)
    state.sealed = true

    -- snapshot: ใครอยู่ในวง ณ วินาที seal ได้สิทธิ์ถาวรตลอดอีเวนต์
    -- แยก allowed ออกจาก occupants เพราะ occupants เปลี่ยนตลอดเวลา (เดินเข้าออกได้)
    -- ส่วน allowed ต้องแช่แข็งไว้ ไม่งั้นคนที่ออกไปแป๊บนึงจะกลับเข้ามาไม่ได้
    for src in pairs(state.occupants) do
        state.allowed[src] = true
    end

    pushState()

    if Config.Debug then
        local n = 0
        for _ in pairs(state.allowed) do n = n + 1 end
        print(('[nx_graverobbery] event sealed village=%s occupants=%d'):format(villageId, n))
    end
end

local function endEvent(villageId)
    active[villageId] = nil
    pushState()

    if Config.Debug then
        print(('[nx_graverobbery] event ended village=%s'):format(villageId))
    end
end

-- ── ตัวจับเวลาหลัก ───────────────────────────────────────────────────────────
-- เช็คทุก 10 วินาที: พอถึงเวลาเปิดของเมืองไหน (และวันนี้ยังไม่เคยรัน) ก็เริ่มให้
local function shouldStartNow(villageId, dayKey)
    if lastStartedDay[villageId] == dayKey then return false end -- วันนี้รันไปแล้ว ไม่รันซ้ำ

    local village = Config.Villages[villageId]
    local schedule = village and village.schedule
    if not schedule or schedule.enabled ~= true then return false end

    local now = os.date('*t')
    local nowMinutes  = now.hour * 60 + now.min
    local openMinutes = (schedule.openHour or 0) * 60 + (schedule.openMinute or 0)
    if nowMinutes < openMinutes then return false end

    -- เซิร์ฟบูต (หรือ resource restart) หลังเลยจุด seal ของรอบนั้นไปแล้ว = ข้ามรอบนี้ทั้งวัน
    --
    -- เหตุผล: ไทม์ไลน์ยึดเวลาเปิดตามตาราง ถ้าเปิดอีเวนต์ตอนที่เลย seal ไปแล้ว รายชื่อคนที่
    -- "อยู่ในวงตอน seal" จะว่างเปล่า (state เดิมหายไปกับการรีสตาร์ท) กลายเป็นวงที่ประกาศออกไป
    -- แต่ไม่มีใครเข้าได้เลยตลอดชั่วโมงที่เหลือ — ดูเหมือนระบบพังมากกว่าเป็นอีเวนต์
    local cfg = eventConfig()
    if (nowMinutes - openMinutes) >= (cfg.windowMinutes or 8) then
        lastStartedDay[villageId] = dayKey
        return false
    end

    return true
end

CreateThread(function()
    while true do
        Wait(10000)

        if isEnabled() then
            local dayKey = os.date('%Y-%m-%d')
            local now = os.time()

            for villageId, zone in pairs(Config.GraveZones or {}) do
                local state = active[villageId]

                if not state then
                    if shouldStartNow(villageId, dayKey) then
                        startEvent(villageId, zone, dayKey)
                    end
                else
                    if not state.sealed and now >= state.sealAt then
                        sealEvent(villageId, state)
                    end
                    if now >= state.endsAt then
                        endEvent(villageId)
                    end
                end
            end
        end
    end
end)

-- ── API ให้ไฟล์อื่นเรียก ──────────────────────────────────────────────────────
-- true เฉพาะตอนอีเวนต์ของเมืองนั้นกำลังรันอยู่จริง
-- เมืองที่ไม่มี zone (แดนใต้) จะได้ false เสมอ — ผู้เรียกต้องเช็ค schedule เองก่อน (ดู schedule.lua)
function NX_GR.Event.IsOpen(villageId)
    return active[villageId] ~= nil
end

-- ต้องยืนอยู่ในวงถึงจะขุดได้ — แต่เมืองที่ไม่มีอีเวนต์ (แดนใต้) ผ่านตลอด ไม่กระทบของเดิม
function NX_GR.Event.IsOccupant(source, villageId)
    local state = active[villageId]
    if not state then return true end
    return state.occupants[source] ~= nil
end

function NX_GR.Event.GetState(villageId)
    return active[villageId]
end

-- ── สั่งเปิด/ปิดด้วยมือ (คำสั่งแอดมินใน main.lua) ─────────────────────────────
-- ใช้ได้เฉพาะเมืองแดนบนที่มี Config.GraveZones — แดนใต้ไม่มีอีเวนต์ให้เปิดปิด
-- คุมด้วยคูลดาวน์รายหลุมแทน ขุดได้ตลอดเวลาอยู่แล้ว
function NX_GR.Event.ListVillages()
    local ids = {}
    for villageId in pairs(Config.GraveZones or {}) do
        ids[#ids + 1] = villageId
    end
    table.sort(ids)
    return ids
end

-- คืน ok, เหตุผลที่ไม่สำเร็จ
function NX_GR.Event.ForceStart(villageId)
    if not isEnabled() then return false, 'disabled' end

    local zone = (Config.GraveZones or {})[villageId]
    if not zone then return false, 'no_zone' end
    if active[villageId] then return false, 'already_running' end

    -- ตั้ง lastStartedDay เป็นวันนี้ด้วย เพื่อไม่ให้ตัวจับเวลาอัตโนมัติเปิดซ้ำอีกรอบในวันเดียวกัน
    -- หลังจากที่แอดมินสั่งเปิดเองไปแล้ว
    startEvent(villageId, zone, os.date('%Y-%m-%d'), true)
    return true
end

function NX_GR.Event.ForceEnd(villageId)
    if not active[villageId] then return false, 'not_running' end
    endEvent(villageId)
    return true
end

-- ── presence จาก client (server ตรวจระยะเองเสมอ ไม่เชื่อค่า inside ที่ส่งมา) ──
local function checkPresenceGuard(source)
    local guard = presenceGuard[source]
    local nowMs = GetGameTimer()
    local nowSec = os.time()

    if not guard then
        presenceGuard[source] = { lastAt = nowMs, count = 1, resetAt = nowSec + 60 }
        return true
    end

    if nowMs - guard.lastAt < PRESENCE_MIN_INTERVAL_MS then return false end
    guard.lastAt = nowMs

    if nowSec >= guard.resetAt then
        guard.count = 1
        guard.resetAt = nowSec + 60
        return true
    end

    guard.count = guard.count + 1
    if guard.count > PRESENCE_MAX_PER_MINUTE then
        NX_GR.Security.Log(source, 'zonePresence', 'rate_limited')
        return false
    end

    return true
end

local function countBucket(state, bucket, exceptSource)
    local count = 0
    for src, srcBucket in pairs(state.occupants) do
        if srcBucket == bucket and src ~= exceptSource then
            count = count + 1
        end
    end
    return count
end

local function deny(source, villageId, reason)
    TriggerClientEvent('nx_graverobbery:client:zoneDenied', source, villageId, reason)
end

RegisterNetEvent('nx_graverobbery:server:zonePresence', function(villageId, _inside)
    local source = source
    if not isEnabled() then return end
    if not NX_GR.IsValidId(villageId) then return end
    if not (Config.GraveZones or {})[villageId] then return end
    if not checkPresenceGuard(source) then return end

    local state = active[villageId]
    if not state then return end

    -- ไม่เชื่อ _inside ที่ client ส่งมา — วัดระยะจากพิกัดจริงฝั่ง server เองทุกครั้ง
    local coords = NX_GR.Security.GetPlayerCoords(source)
    if not coords then
        state.occupants[source] = nil
        return
    end

    local tolerance = (Config.Security.startDistanceTolerance or 3.0)
    local insideNow = NX_GR.Distance(coords, state.coords) <= (zoneRadius() + tolerance)

    if not insideNow then
        state.occupants[source] = nil
        return
    end

    -- อยู่ในวงอยู่แล้ว = ไม่ต้องนับใหม่ (ไม่งั้นตัวเองจะไปกินโควตาเมืองตัวเองซ้ำ)
    if state.occupants[source] then return end

    if state.sealed and not state.allowed[source] then
        deny(source, villageId, 'sealed')
        return
    end

    local character = NX_GR.VORP.GetCharacter(source)
    if not character then return end

    local bucket = NX_GR.CitySelect.GetPlayerVillageId(source, character) or NO_CITY_BUCKET
    local maxPerCity = eventConfig().maxPerCity or 10

    if countBucket(state, bucket, source) >= maxPerCity then
        deny(source, villageId, 'city_full')
        return
    end

    state.occupants[source] = bucket
end)

-- client ขอ state ตอนโหลดเสร็จ / หลัง reconnect
RegisterNetEvent('nx_graverobbery:server:requestZoneState', function()
    local source = source
    if not NX_GR.Security.CheckRateLimit(source, 'requestZoneState') then return end
    pushState(source)
end)

AddEventHandler('playerDropped', function()
    local droppedSource = source
    presenceGuard[droppedSource] = nil
    for _, state in pairs(active) do
        state.occupants[droppedSource] = nil
        state.allowed[droppedSource] = nil
    end
end)
