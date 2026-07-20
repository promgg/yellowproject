LP_DM = LP_DM or {}
LP_DM.Event = {}

local active = false
local endsAt = 0
local scores = {}          -- [cityId] = number
local pairCooldowns = {}    -- [canonicalPairKey] = expiresAt (os.time())
local endTimerRef = 0       -- generation counter — กัน timer เก่าค้างยิง End() ซ้ำถ้ามีคน forcestart ทับ

-- แปลงชื่อเป็น hash ครั้งเดียวตอนโหลด แล้วเก็บเป็น set เพื่อเช็คด้วยการ index ตรงๆ
-- (deathCause ที่ได้จาก GetPedCauseOfDeath เป็น hash อยู่แล้ว)
local deniedCauses = {}
for _, name in ipairs(Config.DeniedDeathCauses or {}) do
    deniedCauses[joaat(name)] = true
end

local function pairKey(sourceA, sourceB)
    local a, b = tonumber(sourceA), tonumber(sourceB)
    if a > b then a, b = b, a end
    return a .. ':' .. b
end

local function resetScores()
    scores = {}
    for _, city in ipairs(Config.Cities) do
        scores[city.id] = 0
    end
end

function LP_DM.Event.IsActive()
    if active and os.time() >= endsAt then
        -- กันเคส timer thread ล่าช้า/ค้าง — เช็คจากเวลาจริงเป็นแหล่งความจริงเสมอ
        LP_DM.Event.End()
        return false
    end
    return active
end

local function buildCityPayload()
    local list = {}
    for _, city in ipairs(Config.Cities) do
        list[#list + 1] = { id = city.id, code = city.code, label = city.label, score = scores[city.id] or 0 }
    end
    return list
end

function LP_DM.Event.Start()
    if LP_DM.Event.IsActive() then return false end

    resetScores()
    pairCooldowns = {}
    active = true
    endsAt = os.time() + (Config.Schedule.durationMinutes or 20) * 60
    endTimerRef = endTimerRef + 1
    local myGen = endTimerRef

    -- ส่ง durationMs (ระยะเวลานับถอยหลังจากตอนนี้) แทน endsAt แบบ timestamp — กัน client นาฬิกาเพี้ยน
    -- (client จับเวลาด้วย GetGameTimer() ของตัวเองแทน ไม่ต้องพึ่งนาฬิกาเครื่องผู้เล่น)
    TriggerClientEvent('lp_deathmatch:client:start', -1, {
        cities = buildCityPayload(),
        durationMs = (Config.Schedule.durationMinutes or 20) * 60000,
    })

    LP_DM.Security.Log(0, 'event', 'started')

    SetTimeout((Config.Schedule.durationMinutes or 20) * 60 * 1000, function()
        if myGen == endTimerRef and active then
            LP_DM.Event.End()
        end
    end)

    return true
end

-- จัดกลุ่มอันดับจริง (คะแนนเท่ากัน = อันดับเดียวกัน) เช่น 5,5,2 -> อันดับ 1 (2 เมือง), อันดับ 3 (1 เมือง)
local function computeRanking()
    local entries = {}
    for _, city in ipairs(Config.Cities) do
        entries[#entries + 1] = { id = city.id, code = city.code, label = city.label, score = scores[city.id] or 0 }
    end
    table.sort(entries, function(a, b) return a.score > b.score end)

    local groups = {}
    local rank, i = 1, 1
    while i <= #entries do
        local score = entries[i].score
        local group = { rank = rank, score = score, cities = { entries[i] } }
        local j = i + 1
        while j <= #entries and entries[j].score == score do
            table.insert(group.cities, entries[j])
            j = j + 1
        end
        groups[#groups + 1] = group
        rank = rank + #group.cities
        i = j
    end
    return groups
end

local RANK_TO_TIER = { [1] = 'first', [2] = 'second', [3] = 'third' }

function LP_DM.Event.End()
    if not active then return end
    active = false
    endTimerRef = endTimerRef + 1 -- กัน timer เก่า (ถ้ามี) ยิง End() ซ้ำหลังจากนี้

    local groups = computeRanking()
    local finalCities = buildCityPayload()

    -- แจกรางวัลเฉพาะผู้เล่นที่ออนไลน์ตอนนี้และเป็นเมืองที่ติดอันดับ 1-3 เท่านั้น (ไม่ใช่ทุกคนที่เคยลงทะเบียนเมืองนั้น)
    for _, group in ipairs(groups) do
        local tier = RANK_TO_TIER[group.rank]
        if tier then
            local rankCfg = Config.Rewards[tier]
            local citySet = {}
            for _, c in ipairs(group.cities) do citySet[c.id] = true end

            for _, playerId in ipairs(GetPlayers()) do
                local source = tonumber(playerId)
                local character = LP_DM.VORP.GetCharacter(source)
                if character then
                    local villageId = LP_DM.CitySelect.GetPlayerVillageId(source, character)
                    if villageId and citySet[villageId] then
                        LP_DM.Rewards.GiveForRank(source, character, rankCfg, #group.cities)
                        LP_DM.VORP.Notify(source, LP_DM.Locale('reward_won', { rank = group.rank }), 6000, 'success')
                    end
                end
            end
        end
    end

    TriggerClientEvent('lp_deathmatch:client:end', -1, {
        cities = finalCities,
        groups = groups,
    })

    LP_DM.Security.Log(0, 'event', 'ended')
end

-- ให้ client ที่พึ่งต่อ/reconnect ระหว่างอีเว้นท์กำลังทำงานอยู่ sync สถานะปัจจุบันได้ (ไม่งั้นจะไม่เห็น scoreboard เลย)
function LP_DM.Event.GetSyncPayload()
    if not LP_DM.Event.IsActive() then return nil end
    return {
        cities = buildCityPayload(),
        durationMs = math.max(0, (endsAt - os.time())) * 1000,
    }
end

function LP_DM.Event.ReportKill(killerSource, victimSource, weaponHash)
    if not LP_DM.Event.IsActive() then return false, 'not_running' end
    if killerSource == victimSource then return false, 'self' end

    local killerChar = LP_DM.VORP.GetCharacter(killerSource)
    local victimChar = LP_DM.VORP.GetCharacter(victimSource)
    if not killerChar or not victimChar then return false, 'invalid_player' end

    -- สาเหตุการตายต้องไม่อยู่ใน denylist (ชกมือเปล่า/ตกที่สูง/จมน้ำ/ไฟ/สัตว์ ไม่นับแต้ม)
    if deniedCauses[weaponHash] then
        return false, 'cause_denied'
    end

    if not LP_DM.Security.ArePlausiblyNear(killerSource, victimSource) then
        LP_DM.Security.Log(killerSource, 'reportKill', 'too_far', { victim = victimSource })
        return false, 'too_far'
    end

    local key = pairKey(killerSource, victimSource)
    local current = os.time()
    if pairCooldowns[key] and pairCooldowns[key] > current then
        return false, 'pair_cooldown'
    end

    local killerVillage = LP_DM.CitySelect.GetPlayerVillageId(killerSource, killerChar)
    local victimVillage = LP_DM.CitySelect.GetPlayerVillageId(victimSource, victimChar)
    if not killerVillage or not victimVillage or killerVillage == victimVillage then
        return false, 'no_op' -- ไม่มีเมือง หรือฆ่าคนเมืองเดียวกัน — ไม่มีแต้ม ไม่ผิดกฎ แค่ไม่ทำอะไร
    end

    pairCooldowns[key] = current + (Config.Security.pairCooldownMinutes or 10) * 60
    scores[killerVillage] = (scores[killerVillage] or 0) + 1

    TriggerClientEvent('lp_deathmatch:client:scoreUpdate', -1, { cityId = killerVillage, score = scores[killerVillage] })

    local cityCfg
    for _, city in ipairs(Config.Cities) do
        if city.id == killerVillage then cityCfg = city break end
    end
    LP_DM.VORP.Notify(killerSource, LP_DM.Locale('kill_confirmed', { city = cityCfg and cityCfg.label or killerVillage }), 4000, 'success')
    LP_DM.Security.Log(killerSource, 'reportKill', ('confirmed city=%s score=%d'):format(killerVillage, scores[killerVillage]))

    return true
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    active = false
end)
