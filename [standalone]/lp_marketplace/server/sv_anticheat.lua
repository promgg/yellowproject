-- sv_anticheat.lua — Anti-Cheat Level 1

local rateLimitData = {}   -- { [charIdentifier] = { count, windowStart } }

-- ── 1. Rate Limit ─────────────────────────────────────────────────────────────
local function CheckRateLimit(charIdentifier)
    local now   = os.time()
    local entry = rateLimitData[charIdentifier]
    if not entry or (now - entry.windowStart) >= 60 then
        rateLimitData[charIdentifier] = { count = 1, windowStart = now }
        return true
    end
    entry.count = entry.count + 1
    return entry.count <= Config.RateLimit.listingsPerMinute
end

-- ── Trigger ───────────────────────────────────────────────────────────────────
local function TriggerAntiCheat(source, reason)
    local name = GetPlayerName(source) or tostring(source)

    Log('anticheat', '🚨 Anti-Cheat',
        ('**ผู้เล่น:** %s\n**เหตุผล:** %s'):format(name, reason),
        {{ name = 'Source', value = tostring(source), inline = true }})

    -- Kick ทันที — Discord webhook log ไว้ให้ admin ban ผ่าน txAdmin
    if Config.AntiCheat.banOnDetect or Config.AntiCheat.kickOnDetect then
        DropPlayer(source, '[lp_marketplace] ตรวจพบความผิดปกติ: ' .. reason)
    end
end

-- ── 2-4. Validate Listing ──────────────────────────────────────────────────────
function ValidateListing(source, itemName, quantity, price, currency)
    local Character = GetCharacter(source)
    if not Character then return false, 'player_not_found' end

    local charIdentifier = Character.charIdentifier

    -- Check 1: rate limit
    if not CheckRateLimit(charIdentifier) then
        Log('anticheat', '⚠️ Rate Limit', (GetPlayerName(source) or '') .. ' ลงขายบ่อยเกินไป')
        return false, 'rate_limited'
    end

    -- Check 2: มีไอเทมจริง
    local count = InvGetCount(source, itemName)
    if count < quantity then
        TriggerAntiCheat(source, 'ลงขายไอเทมที่ไม่มีในคลัง: ' .. itemName)
        return false, 'no_item'
    end

    -- Check 3: quantity valid (soft reject — ไม่ ban เพราะอาจมาจาก UI bug)
    if quantity <= 0 then
        return false, 'invalid_qty'
    end

    -- Check 4: price range
    local cfg = (Config.ItemPriceConfig[itemName] and Config.ItemPriceConfig[itemName][currency])
             or Config.DefaultPriceConfig[currency]
    -- guard cfg nil — currency ที่ไม่รู้จัก (ไม่มีใน DefaultPriceConfig)
    if not cfg then
        return false, 'invalid_currency'
    end
    if price < cfg.min or price > cfg.max then
        TriggerAntiCheat(source, ('ราคาผิดปกติ [%s] %s: %d (allowed %d-%d)'):format(
            currency, itemName, price, cfg.min, cfg.max))
        return false, 'invalid_price'
    end

    return true, 'ok'
end

-- ── Cleanup rate limit memory (ทุก 5 นาที) ───────────────────────────────────
CreateThread(function()
    while true do
        Wait(300000)
        local now = os.time()
        for id, entry in pairs(rateLimitData) do
            if now - entry.windowStart > 120 then
                rateLimitData[id] = nil
            end
        end
    end
end)
