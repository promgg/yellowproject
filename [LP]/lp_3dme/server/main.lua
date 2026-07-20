-- lp_3dme (server) — เจ้าของความจริงทั้งหมด
--
-- client ส่งมาได้แค่ "ขอพูดชนิดนี้ ข้อความนี้" เท่านั้น
-- ความยาว / ผลลูกเต๋า / ใครเห็นบ้าง ตัดสินที่นี่ทั้งหมด

local RESOURCE = GetCurrentResourceName()

local descriptions = {} -- [serverId] = ข้อความ /desc ที่ตั้งค้างไว้
local rateState    = {} -- [serverId] = { lastAt = ms, count = n, windowResetAt = ms }

-- ── helpers ──────────────────────────────────────────────────────────────────
local function dbg(fmt, ...)
    if Config.Debug then print(('[%s] ' .. fmt):format(RESOURCE, ...)) end
end

local function notify(src, text, ntype)
    TriggerClientEvent('pNotify:SendNotification', src, {
        text = text, type = ntype or 'error', timeout = 4000,
    })
end

-- ตัดอักขระควบคุมทิ้ง (รวม \n \r \t) กันคนยัดบรรทัดใหม่ให้กล่องยืดเต็มจอ
-- ไม่ต้อง escape HTML ที่นี่เพราะฝั่ง NUI ใช้ textContent ไม่ได้แตะ innerHTML เลย
-- (escape ตรงนี้จะกลายเป็นเห็น &amp; ในเกมแทน & ซึ่งผิด)
local function sanitize(text, maxLength)
    text = tostring(text or '')
    text = text:gsub('%c', ' ')      -- อักขระควบคุม -> ช่องว่าง
    text = text:gsub('%s+', ' ')     -- ยุบช่องว่างซ้ำ
    text = text:gsub('^%s+', ''):gsub('%s+$', '')
    if text == '' then return nil end
    if #text > maxLength then
        -- ตัดด้วย # (ไบต์) ไม่ใช่จำนวนตัวอักษร — ภาษาไทยตัวนึงกิน 3 ไบต์ใน UTF-8
        -- ตัดกลางตัวอักษรจะได้ไบต์เสีย จึงถอยกลับจนเจอขอบตัวอักษรที่ถูกต้อง
        text = text:sub(1, maxLength)
        while #text > 0 and text:byte(#text) >= 0x80 and text:byte(#text) <= 0xBF do
            text = text:sub(1, #text - 1)
        end
    end
    return text
end

local function checkRate(src)
    local now = GetGameTimer()
    local st = rateState[src]
    if not st then
        st = { lastAt = 0, count = 0, windowResetAt = now + 60000 }
        rateState[src] = st
    end

    if now >= st.windowResetAt then
        st.count = 0
        st.windowResetAt = now + 60000
    end

    if (now - st.lastAt) < (Config.RateLimit.minIntervalMs or 1500) then
        return false, 'พิมพ์เร็วเกินไป รอสักครู่'
    end
    if st.count >= (Config.RateLimit.maxPerMinute or 15) then
        return false, 'ส่งข้อความถี่เกินไป รออีกสักครู่'
    end

    st.lastAt = now
    st.count = st.count + 1
    return true
end

-- คนที่อยู่ในระยะและควรได้รับข้อความนี้ (รวมตัวคนพูดเองเสมอ)
-- กรองที่ server ไม่ใช่ broadcast ทั้งเซิร์ฟแล้วให้ client กรองเอง — ไม่งั้นดักอ่านได้ทั้งแมพ
local function playersInRange(srcCoords, range, alwaysInclude)
    local targets = {}
    local rangeSq = range * range

    for _, pid in ipairs(GetPlayers()) do
        local id = tonumber(pid)
        if id then
            if id == alwaysInclude then
                targets[#targets + 1] = id
            else
                local ped = GetPlayerPed(id)
                if ped and ped ~= 0 then
                    local d = GetEntityCoords(ped) - srcCoords
                    if (d.x * d.x + d.y * d.y + d.z * d.z) <= rangeSq then
                        targets[#targets + 1] = id
                    end
                end
            end
        end
    end

    return targets
end

local function broadcast(src, typeKey, text)
    local cfg = Config.Types[typeKey]
    if not cfg then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end

    local targets = playersInRange(GetEntityCoords(ped), cfg.range, src)
    for _, id in ipairs(targets) do
        TriggerClientEvent('lp_3dme:show', id, src, typeKey, text)
    end

    dbg('%s จาก src=%s ถึง %d คน: %s', typeKey, tostring(src), #targets, text)
end

-- ── /desc — ป้ายค้าง ────────────────────────────────────────────────────────
-- ส่งสถานะให้ทุกคนเพราะมันเปลี่ยนน้อยมากและเป็นข้อความสั้น การซิงก์ตามระยะแบบ
-- realtime จะซับซ้อนเกินความจำเป็น — client กรองระยะตอนวาดอีกที
local function pushDesc(target)
    TriggerClientEvent('lp_3dme:descState', target or -1, descriptions)
end

local function setDesc(src, text)
    if text then
        descriptions[src] = text
    else
        descriptions[src] = nil
    end
    pushDesc()
end

-- ── คำสั่งข้อความทั่วไป ─────────────────────────────────────────────────────
for typeKey, cfg in pairs(Config.Types) do
    -- dice/roll มีตรรกะของตัวเอง ลงทะเบียนแยกด้านล่าง
    if typeKey ~= 'dice' and typeKey ~= 'roll' then
        RegisterCommand(typeKey, function(src, args)
            if src == 0 then
                print(('[%s] คำสั่งนี้ใช้จาก console ไม่ได้ (ต้องมีตัวละครอยู่ในแมพ)'):format(RESOURCE))
                return
            end

            local text = sanitize(table.concat(args, ' '), Config.MaxLength)
            if not text then
                notify(src, ('ใช้: /%s <ข้อความ>'):format(typeKey), 'info')
                return
            end

            local ok, reason = checkRate(src)
            if not ok then notify(src, reason) return end

            broadcast(src, typeKey, text)
        end, false)

        TriggerClientEvent('chat:addSuggestion', -1, '/' .. typeKey, cfg.help, {
            { name = 'ข้อความ', help = ('สูงสุด %d ตัวอักษร'):format(Config.MaxLength) },
        })
    end
end

-- ── /dice [จำนวนลูก] [จำนวนหน้า] ────────────────────────────────────────────
-- ผลสุ่มทั้งหมดคำนวณที่นี่ client ไม่มีทางส่งผลลัพธ์ที่อยากได้เข้ามา
RegisterCommand('dice', function(src, args)
    if src == 0 then return end

    local ok, reason = checkRate(src)
    if not ok then notify(src, reason) return end

    local count = math.floor(tonumber(args[1]) or Config.Dice.defaultCount)
    local sides = math.floor(tonumber(args[2]) or Config.Dice.defaultSides)

    count = math.max(1, math.min(count, Config.Dice.maxCount))
    sides = math.max(2, math.min(sides, Config.Dice.maxSides))

    local rolls, total = {}, 0
    for i = 1, count do
        local r = math.random(1, sides)
        rolls[i] = r
        total = total + r
    end

    local text
    if count == 1 then
        text = ('ทอย d%d ได้ %d'):format(sides, total)
    else
        text = ('ทอย %dd%d ได้ %s = %d'):format(count, sides, table.concat(rolls, ' + '), total)
    end

    broadcast(src, 'dice', text)
end, false)

RegisterCommand('roll', function(src)
    if src == 0 then return end

    local ok, reason = checkRate(src)
    if not ok then notify(src, reason) return end

    local value = math.random(Config.Roll.min, Config.Roll.max)
    broadcast(src, 'roll', ('สุ่มได้ %d / %d'):format(value, Config.Roll.max))
end, false)

TriggerClientEvent('chat:addSuggestion', -1, '/dice', Config.Types['dice'].help, {
    { name = 'จำนวนลูก', help = ('ไม่ใส่ = %d, สูงสุด %d'):format(Config.Dice.defaultCount, Config.Dice.maxCount) },
    { name = 'จำนวนหน้า', help = ('ไม่ใส่ = %d, สูงสุด %d'):format(Config.Dice.defaultSides, Config.Dice.maxSides) },
})
TriggerClientEvent('chat:addSuggestion', -1, '/roll', Config.Types['roll'].help, {})

-- ── /desc ───────────────────────────────────────────────────────────────────
if Config.Desc.enabled then
    RegisterCommand('desc', function(src, args)
        if src == 0 then return end

        local text = sanitize(table.concat(args, ' '), Config.Desc.maxLength)

        if not text then
            -- สั่งเปล่าๆ = ลบป้ายทิ้ง
            if descriptions[src] then
                setDesc(src, nil)
                notify(src, 'ลบคำบรรยายแล้ว', 'success')
            else
                notify(src, 'ใช้: /desc <คำบรรยาย>  (สั่งเปล่าๆ อีกครั้งเพื่อลบ)', 'info')
            end
            return
        end

        local ok, reason = checkRate(src)
        if not ok then notify(src, reason) return end

        setDesc(src, text)
        notify(src, 'ตั้งคำบรรยายแล้ว', 'success')
    end, false)

    TriggerClientEvent('chat:addSuggestion', -1, '/desc', 'ป้ายบรรยายค้างเหนือหัว (สั่งเปล่าๆ เพื่อลบ)', {
        { name = 'คำบรรยาย', help = ('สูงสุด %d ตัวอักษร'):format(Config.Desc.maxLength) },
    })
end

-- คนเพิ่งเข้าเกมต้องได้ป้ายของคนอื่นที่ตั้งค้างไว้อยู่แล้วด้วย
RegisterNetEvent('lp_3dme:requestDesc', function()
    pushDesc(source)
end)

-- ── cleanup ─────────────────────────────────────────────────────────────────
AddEventHandler('playerDropped', function()
    local src = source
    rateState[src] = nil
    if descriptions[src] then
        descriptions[src] = nil
        pushDesc()
    end
end)
