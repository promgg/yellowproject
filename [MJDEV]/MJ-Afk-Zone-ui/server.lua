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
    -- Critical: getUsedCharacter ต้องเรียกเป็น function
    local userObj = VORPcore.getUser(src)
    if not userObj then return end
    local user = userObj.getUsedCharacter()
    if not user or not zoneName then return end

    local zoneData = Config.AFKZones[zoneName]
    if not zoneData then return end

    local identifier = GetPlayerIdentifier(src, 0)
    if not identifier then return end

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

    -- รีเซ็ต start time
    afkStartTime[src][zoneName] = nil

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
    if not afkStartTime[src] then afkStartTime[src] = {} end
    afkStartTime[src][zoneName] = os.time()
end)

-- ── Cleanup on disconnect ────────────────────────────────────────────────────
AddEventHandler('playerDropped', function()
    local src = source
    afkStartTime[src]    = nil
    requestCooldowns[src] = nil
end)
