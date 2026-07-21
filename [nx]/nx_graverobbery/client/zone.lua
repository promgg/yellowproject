NX_GR = NX_GR or {}

-- ── วงอีเวนต์สุสาน (ฝั่ง client) ───────────────────────────────────────────────
-- หน้าที่: วาดวง, รายงานเข้า/ออกวงให้ server, แสดงนับถอยหลังก่อนวงปิด
-- กติกาทั้งหมด (cap ต่อเมือง / seal) ตัดสินที่ server — ที่นี่แค่แสดงผลกับดันตัวออกให้เห็นภาพ

local zones = {}          -- [villageId] = { coords = vector3, radius, sealAt, endsAt, sealed, label }
local reported = {}       -- [villageId] = true/false — สถานะที่รายงานไป server ล่าสุด (ยิงเฉพาะตอนเปลี่ยน)
local countdownFired = {} -- [villageId] = { [threshold] = true } — กันเตือนซ้ำที่วินาทีเดิม
local grOutfitOn = false   -- ใส่ชุดประจำเมืองอยู่ไหม (กันเรียก export ซ้ำทุกรอบ)
local serverClockSkew = 0 -- ส่วนต่างนาฬิกา server - client (วินาที) ใช้แปลง sealAt/endsAt ให้ตรง

local DRAW_DISTANCE = 300.0            -- ไกลกว่านี้ไม่ต้องวาดเลย
local COUNTDOWN_THRESHOLDS = { 300, 180, 60, 30, 10 }

local function nowServer()
    return os.time() + serverClockSkew
end

-- ── รับ state จาก server ──────────────────────────────────────────────────────
RegisterNetEvent('nx_graverobbery:client:zoneState', function(payload)
    local incoming = {}

    for _, z in ipairs(payload or {}) do
        if z.now then serverClockSkew = z.now - os.time() end

        local previous = zones[z.villageId]
        incoming[z.villageId] = {
            label  = z.label,
            coords = vector3(z.coords.x, z.coords.y, z.coords.z),
            radius = z.radius or 40.0,
            sealAt = z.sealAt,
            endsAt = z.endsAt,
            sealed = z.sealed == true,
        }

        -- แจ้งครั้งเดียวตอนวงเพิ่งปิด (ขอบขาขึ้นของ sealed)
        if previous and not previous.sealed and incoming[z.villageId].sealed then
            NX_GR.Notify(NX_GR.Locale('zone_sealed_now'), 'warning')
        end
    end

    -- เมืองที่หายไปจาก payload = อีเวนต์จบแล้ว เคลียร์ state ที่จำไว้ทิ้ง
    for villageId in pairs(zones) do
        if not incoming[villageId] then
            reported[villageId] = nil
            countdownFired[villageId] = nil
        end
    end

    zones = incoming
end)

RegisterNetEvent('nx_graverobbery:client:eventAnnounce', function(text)
    if type(text) == 'string' and text ~= '' then
        NX_GR.Notify(text, 'success', 8000)
    end
end)

-- ── โดน server ปฏิเสธ = ดันออกนอกวง (cosmetic เฉยๆ server ไม่ได้นับเราเป็นคนในวงอยู่แล้ว) ──
RegisterNetEvent('nx_graverobbery:client:zoneDenied', function(villageId, reason)
    local zone = zones[villageId]
    if not zone then return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- ดันไปตามแนวจากจุดกลางวงมาหาตัวเรา ให้พ้นขอบไป 3m
    local dx, dy = coords.x - zone.coords.x, coords.y - zone.coords.y
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 0.1 then dx, dy, length = 1.0, 0.0, 1.0 end -- ยืนตรงกลางเป๊ะ: เลือกทิศไหนก็ได้

    local push = zone.radius + 3.0
    SetEntityCoordsNoOffset(ped,
        zone.coords.x + (dx / length) * push,
        zone.coords.y + (dy / length) * push,
        coords.z, false, false, false)

    reported[villageId] = false

    if reason == 'sealed' then
        NX_GR.Notify(NX_GR.Locale('zone_sealed'), 'error', 6000)
    elseif reason == 'city_full' then
        NX_GR.Notify(NX_GR.Locale('zone_city_full'), 'error', 6000)
    end
end)

-- ── วาดวง ────────────────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        local sleep = 500
        local M = (Config.GraveEvent or {}).marker

        if M and next(zones) then
            local coords = GetEntityCoords(PlayerPedId())

            for _, zone in pairs(zones) do
                if #(coords - zone.coords) <= DRAW_DISTANCE then
                    sleep = 0
                    local radius = zone.radius
                    -- native วงกลมของ RedM — อย่าเปลี่ยนไปใช้ DrawMarker แบบ type เป็นเลข มันไม่ขึ้น
                    Citizen.InvokeNative(0x2A32FAA57B937173, M.hash,
                        zone.coords.x, zone.coords.y, zone.coords.z + (M.zOffset or -10.0),
                        0.0, 0.0, 0.0, 0, 0.0, 0.0,
                        radius * 2, radius * 2, radius,
                        M.r, M.g, M.b, M.a,
                        true, true, 2, false, false, false, false)
                end
            end
        end

        Wait(sleep)
    end
end)

-- ── รายงานเข้า/ออกวง + นับถอยหลังก่อน seal ───────────────────────────────────
CreateThread(function()
    while true do
        Wait(500)

        if next(zones) then
            local coords = GetEntityCoords(PlayerPedId())
            local insideAny = false

            for villageId, zone in pairs(zones) do
                local inside = #(coords - zone.coords) <= zone.radius
                if inside then insideAny = true end

                -- ยิงเฉพาะตอนสถานะเปลี่ยน ไม่ใช่ทุกรอบ ลด traffic และไม่ชน rate limit
                if reported[villageId] ~= inside then
                    reported[villageId] = inside
                    TriggerServerEvent('nx_graverobbery:server:zonePresence', villageId, inside)
                end

                -- นับถอยหลังเฉพาะคนที่อยู่ในวงและวงยังไม่ปิด
                -- ใช้ pNotify เป็นช่วงๆ แทน lp_textui เพราะ targets.lua ใช้ lp_textui
                -- ทำ prompt กด E ค้างอยู่แล้ว ถ้าเขียนทับกันจะแย่ง UI เดียวกันไปมา
                if inside and not zone.sealed and zone.sealAt then
                    local remaining = zone.sealAt - nowServer()
                    local fired = countdownFired[villageId]
                    if not fired then
                        fired = {}
                        countdownFired[villageId] = fired
                    end

                    for _, threshold in ipairs(COUNTDOWN_THRESHOLDS) do
                        if remaining > 0 and remaining <= threshold and not fired[threshold] then
                            fired[threshold] = true
                            NX_GR.Notify(NX_GR.Locale('zone_seal_in', { seconds = threshold }), 'warning')
                            break -- เตือนระดับเดียวต่อรอบ กันเด้งรัวตอนเพิ่งเข้าวงตอนเวลาเหลือน้อย
                        end
                    end
                end
            end

            -- ใส่/ถอดชุดประจำเมืองตามอยู่ในวงใดวงหนึ่งไหม — เรียก export เฉพาะตอนสถานะเปลี่ยน
            -- WearCityOutfit() ไม่ใส่ param = ใช้เมืองของผู้เล่นเอง (สีเมืองตัวเอง)
            if insideAny and not grOutfitOn then
                grOutfitOn = true
                pcall(function() exports.nx_cityselect:WearCityOutfit() end)
            elseif not insideAny and grOutfitOn then
                grOutfitOn = false
                pcall(function() exports.nx_cityselect:RemoveCityOutfit() end)
            end
        elseif grOutfitOn then
            -- ไม่มีวงเลย (อีเวนต์จบ) แต่ยังใส่ชุดอยู่ — คืนชุดกันค้าง
            grOutfitOn = false
            pcall(function() exports.nx_cityselect:RemoveCityOutfit() end)
        end
    end
end)

CreateThread(function()
    Wait(1500) -- ให้ client/main.lua ตั้งตัวก่อน แล้วค่อยขอ state (เผื่อเข้าเซิร์ฟกลางอีเวนต์)
    TriggerServerEvent('nx_graverobbery:server:requestZoneState')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    zones = {}
    reported = {}
    countdownFired = {}
end)
