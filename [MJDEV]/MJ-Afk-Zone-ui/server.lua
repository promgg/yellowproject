local VORPcore = exports.vorp_core:GetCore()
local jsonFile = 'user_afk.json'
local afkData = {}
local lastUpdateTime = {}
local lastClaimTime = {}
local afkStartTime = {}         -- High: track start time server-side
local requestCooldowns = {}     -- Medium: cooldown for requestAFKTimes

local UPDATE_COOLDOWN = 5000    -- ms (GetGameTimer)
local CLAIM_COOLDOWN  = 10      -- seconds
local REQUEST_COOLDOWN = 2000   -- ms

-- ── ตรวจว่าผู้เล่นอยู่ในมิติพักผ่อนของ saloon นั้นจริง ────────────────────────
-- เดิม server เชื่อ client ล้วนๆ — ยิง startAFK แล้วรอ 15 วิ… ที่จริงคือรอ 15 นาที แต่ยิงจาก
-- ที่ไหนก็ได้บนแผนที่ ไม่เคยเช็คพิกัดเลย ตอนนี้ผูกกับ routing bucket ของ lp_interior แทน
-- ซึ่งปลอมไม่ได้เพราะ server เป็นคนตั้งเอง
local function inAfkZone(src, zoneName)
    local zoneData = Config.AFKZones[zoneName]
    if not zoneData or not zoneData.zoneKey then return false end

    if GetResourceState('lp_interior') ~= 'started' then
        print('^3[MJ-Afk-Zone-ui]^7 lp_interior ไม่ได้ start — ข้ามการตรวจมิติ (ระบบ AFK จะไม่ปลอดภัย)')
        return false
    end

    local ok, res = pcall(function()
        return exports.lp_interior:IsPlayerInAfkBucket(src, zoneData.zoneKey)
    end)
    if not ok or res ~= true then return false end

    -- ตรวจระยะซ้ำอีกชั้น เผื่อ bucket ค้างจากบั๊กอื่น
    if zoneData.npc then
        local ped = GetPlayerPed(src)
        if not ped or ped == 0 then return false end
        if #(GetEntityCoords(ped) - zoneData.npc.coords) > (Config.RewardDistance or 40.0) then
            return false
        end
    end

    return true
end

-- ── Discord log ──────────────────────────────────────────────────────────────
local function sendDiscordLog(message)
    local url = Config.DiscordWebhookUrl   -- High: ใช้ Config แทน nil variable
    if not url or url == "" then return end
    PerformHttpRequest(url, function() end, 'POST', json.encode({
        username = "AFK Zone Logger",
        embeds = {{
            title       = "AFK Reward Claimed",
            description = message,
            color       = 65280,
            timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    }), { ['Content-Type'] = 'application/json' })
end

-- ── Load / Save JSON ─────────────────────────────────────────────────────────
Citizen.CreateThread(function()
    local content = LoadResourceFile(GetCurrentResourceName(), jsonFile)
    if content then
        -- Medium: pcall กัน crash ถ้า JSON corrupted
        local ok, decoded = pcall(json.decode, content)
        afkData = (ok and decoded) or {}
    else
        SaveResourceFile(GetCurrentResourceName(), jsonFile, json.encode({}, { indent = true }), -1)
        afkData = {}
    end
end)

local function SaveAFKData()
    SaveResourceFile(GetCurrentResourceName(), jsonFile, json.encode(afkData, { indent = true }), -1)
end

-- ── updateTime ───────────────────────────────────────────────────────────────
RegisterNetEvent("MJ-Afk-Zone-ui:updateTime")
AddEventHandler("MJ-Afk-Zone-ui:updateTime", function(zoneName, time)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    if not identifier then return end
    if not zoneName or type(time) ~= "number" then return end
    -- High: validate zoneName
    if not Config.AFKZones[zoneName] then return end

    -- Medium: cooldown ใช้ GetGameTimer() แทน os.time()*1000
    local now = GetGameTimer()
    local lastTime = lastUpdateTime[identifier] or 0
    if (now - lastTime) < UPDATE_COOLDOWN then return end
    lastUpdateTime[identifier] = now

    if not afkData[identifier] then afkData[identifier] = {} end
    afkData[identifier][zoneName] = time
    SaveAFKData()
end)

-- ── requestAFKTimes ──────────────────────────────────────────────────────────
RegisterNetEvent("MJ-Afk-Zone-ui:requestAFKTimes")
AddEventHandler("MJ-Afk-Zone-ui:requestAFKTimes", function()
    local src = source
    -- Medium: rate limit
    local now = GetGameTimer()
    local last = requestCooldowns[src] or 0
    if (now - last) < REQUEST_COOLDOWN then return end
    requestCooldowns[src] = now

    local identifier = GetPlayerIdentifier(src, 0)
    if not identifier then return end

    local times = afkData[identifier] or {}
    TriggerClientEvent("MJ-Afk-Zone-ui:loadAFKTimes", src, times)
end)

-- ── claimReward ──────────────────────────────────────────────────────────────
RegisterNetEvent("MJ-Afk-Zone-ui:claimReward")
AddEventHandler("MJ-Afk-Zone-ui:claimReward", function(zoneName)
    local src = source
    local userObj = VORPcore.getUser(src)
    if not userObj then return end
    -- getUsedCharacter เป็น property (table ตัวละครโดยตรง) ไม่ใช่ function — ห้ามใส่ ()
    -- ใส่ () แล้ว error "attempt to call a table value" ทุกครั้งที่ claim ทำให้แจกของไม่เคยทำงาน
    local user = userObj.getUsedCharacter
    if not user or not zoneName then return end

    local zoneData = Config.AFKZones[zoneName]
    if not zoneData then return end

    local identifier = GetPlayerIdentifier(src, 0)
    if not identifier then return end

    -- ต้องอยู่ในมิติพักผ่อนของร้านนั้นจริง ณ ตอนจ่าย ไม่ใช่แค่ตอนเริ่ม
    -- (เดินออกจากร้านแล้วยิง claim เองไม่ผ่านด่านนี้)
    if not inAfkZone(src, zoneName) then
        print(('^3[MJ-Afk-Zone-ui]^7 ปฏิเสธ claim: src=%s ไม่ได้อยู่ในมิติพักผ่อนของ "%s"')
            :format(tostring(src), zoneName))
        return
    end

    -- High: ตรวจ server-side duration แทนการเชื่อ client
    local startTime = afkStartTime[src] and afkStartTime[src][zoneName]
    if not startTime then return end
    local elapsed = os.time() - startTime
    if elapsed < zoneData.duration then return end

    -- Cooldown กัน spam
    local now = os.time()
    local lastClaim = lastClaimTime[identifier] and lastClaimTime[identifier][zoneName] or 0
    if now - lastClaim < CLAIM_COOLDOWN then return end
    if not lastClaimTime[identifier] then lastClaimTime[identifier] = {} end
    lastClaimTime[identifier][zoneName] = now

    -- เริ่มนับรอบใหม่จาก "ตอนนี้" ไม่ใช่ล้างเป็น nil
    -- เดิมล้างทิ้ง แล้ว client ที่นอนต่อจะยิง claim รอบสองมาเจอ startTime = nil แล้วโดนปฏิเสธ
    -- ตลอดไป = ได้รางวัลได้ครั้งเดียวต่อการนอนหนึ่งครั้ง ทั้งที่ตั้งใจให้ได้ทุก 15 นาที
    afkStartTime[src][zoneName] = now

    -- ให้ของ
    for _, reward in ipairs(zoneData.rewards) do
        exports.vorp_inventory:addItem(src, reward.item, reward.count)
    end

    -- รีเซ็ตเวลาใน JSON
    if not afkData[identifier] then afkData[identifier] = {} end
    afkData[identifier][zoneName] = 0
    SaveAFKData()

    local playerName = GetPlayerName(src)
    local rewardsStr = ""
    for _, reward in ipairs(zoneData.rewards) do
        rewardsStr = rewardsStr .. reward.count .. "x " .. reward.label .. "\n"
    end

    -- แจ้งเตือนหลังจ่ายจริงเท่านั้น เดิม client เด้ง "Reward claimed" ทันทีที่ยิง event
    -- โดยไม่รู้ว่า server ปฏิเสธหรือเปล่า = ขึ้นว่าได้ของทั้งที่ไม่ได้อะไรเลย
    TriggerClientEvent("MJ-Afk-Zone-ui:rewardGranted", src, zoneData.label,
        ('%s — ได้รับรางวัล %s'):format(zoneData.label, (rewardsStr:gsub('\n$', ''):gsub('\n', ', '))))
    sendDiscordLog(string.format(
        "**Player:** %s (ID: %d)\n**Zone:** %s\n**Rewards:**\n%s",
        playerName, src, zoneData.label, rewardsStr
    ))
end)

-- ── startAFK (server-side tracking) ─────────────────────────────────────────
RegisterNetEvent("MJ-Afk-Zone-ui:startAFK")
AddEventHandler("MJ-Afk-Zone-ui:startAFK", function(zoneName)
    local src = source
    if not zoneName or not Config.AFKZones[zoneName] then return end

    -- กันไว้ตั้งแต่ต้นทาง: ยิง startAFK จากนอกร้านแล้วรอ 15 นาทีค่อยมา claim ไม่ได้
    if not inAfkZone(src, zoneName) then return end

    if not afkStartTime[src] then afkStartTime[src] = {} end
    afkStartTime[src][zoneName] = os.time()
end)

-- ── Cleanup on disconnect ────────────────────────────────────────────────────
AddEventHandler('playerDropped', function()
    local src = source
    afkStartTime[src]    = nil
    requestCooldowns[src] = nil
end)
