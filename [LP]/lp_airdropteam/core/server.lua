script_name = 'lp_airdropteam'

VORPcore = exports['vorp_core']:GetCore()
Inventory = exports.vorp_inventory:vorp_inventoryApi()

IsAirdropStarted = false
AirdropState = {}
AirdropCount = 0
AirdropRemaining = 0          -- server GetGameTimer() timestamp (ms) when unlock ends
AirdropCooldown = 0           -- server GetGameTimer() timestamp (ms) when auto-remove ends

-- Zone presence (player count inside the ring)
local ZonePlayers = {} -- [airdropId] = { [src] = true }
local ZoneCounts  = {} -- [airdropId] = int


-- Zone lock (after unlock ends): lock membership per airdrop
local ZoneLockActive = false
local ZoneLockAllowed = {}     -- [airdropId] = { [src]=true }
local ZoneLockEliminated = {}  -- [airdropId] = { [src]=true }

local function ResetZoneLock()
    ZoneLockActive = false
    ZoneLockAllowed = {}
    ZoneLockEliminated = {}
end

local function BuildZoneLockSnapshotFor(src)
    local snap = {}
    if type(AirdropState) ~= "table" then return snap end
    for aid in pairs(AirdropState) do
        local airdropId = tonumber(aid) or aid
        local allowed = (ZoneLockAllowed[airdropId] and ZoneLockAllowed[airdropId][src]) and true or false
        local eliminated = (ZoneLockEliminated[airdropId] and ZoneLockEliminated[airdropId][src]) and true or false
        snap[airdropId] = { locked = ZoneLockActive, allowed = allowed, eliminated = eliminated }
    end
    return snap
end

local function ActivateZoneLock()
    if not (Config and Config["ZoneLockEnabled"]) then return end
    if ZoneLockActive then return end
    if not IsAirdropStarted then return end
    if AirdropRemaining and AirdropRemaining > 0 then return end

    ZoneLockActive = true
    ZoneLockAllowed = {}
    ZoneLockEliminated = {}

    for aid in pairs(AirdropState or {}) do
        local airdropId = tonumber(aid) or aid
        ZoneLockAllowed[airdropId] = {}
        ZoneLockEliminated[airdropId] = {}

        local set = ZonePlayers[airdropId] or {}
        for src in pairs(set) do
            ZoneLockAllowed[airdropId][src] = true
        end
    end

    for _, pid in ipairs(GetPlayers()) do
        local src = tonumber(pid)
        if src then
            TriggerClientEvent(script_name .. ":CL:ZoneLockSnapshot", src, BuildZoneLockSnapshotFor(src))
        end
    end
end

-- Looting marker (show "AIRDROP" above the player who is currently holding-to-loot)
local LootingPlayers = {} -- [airdropId] = { [src] = true }

-- Loot lock (mutex): only one player can hold-to-loot per airdrop at a time
local LootLocks = {} -- [airdropId] = { src = int, since = ms, name = string }

-- Resolve a nice display name for UI (prefer RP character name, fallback to platform name)
local function getDisplayNameBySrc(src)
    local name = nil

    local ok, user = pcall(function()
        return VORPcore.getUser(src)
    end)

    if ok and user and user.getUsedCharacter then
        local xPlayer = user.getUsedCharacter
        local f = (xPlayer and xPlayer.firstname) or ""
        local l = (xPlayer and xPlayer.lastname) or ""
        name = (tostring(f) .. " " .. tostring(l))
            :gsub("%s+", " ")
            :gsub("^%s+", "")
            :gsub("%s+$", "")
    end

    if not name or name == "" then
        local pn = GetPlayerName(src)
        if pn and pn ~= "" then
            name = pn
        else
            name = "Unknown"
        end
    end

    return name
end

local function broadcastLootBusy(airdropId, src, isBusy)
    if not airdropId then return end
    if isBusy then
        TriggerClientEvent(script_name .. ":CL:LootBusy", -1, airdropId, src, getDisplayNameBySrc(src), true)
    else
        TriggerClientEvent(script_name .. ":CL:LootBusy", -1, airdropId, src or 0, "", false)
    end
end

local function tableCount(t)
    local c = 0
    if type(t) ~= "table" then return 0 end
    for _ in pairs(t) do c = c + 1 end
    return c
end

local function ResetZonePresence()
    ResetZoneLock()
    ZonePlayers = {}
    ZoneCounts = {}

    -- Pre-seed ids so clients can show 0/Max immediately
    if type(AirdropState) == "table" then
        for id in pairs(AirdropState) do
            ZonePlayers[id] = {}
            ZoneCounts[id] = 0
        end
    end

    for id in pairs(ZoneCounts) do
        TriggerClientEvent(script_name .. ":CL:ZoneCount", -1, id, 0)
    end
end

-- =========================
-- Helpers
-- =========================

-- =========================
-- Server-synced crate prop
-- - Creates ONE networked crate prop per airdrop (shared for all players)
-- - Prop is deleted ONLY when loot is successfully completed (claim) or auto-removed
-- =========================
local function _getPropHash()
    local model = Config and Config["Prop"]
    if type(model) == "number" then
        return model
    end
    return GetHashKey(tostring(model))
end

local function _deleteServerProp(v)
    if not v then return end
    if v.PropEntity and DoesEntityExist(v.PropEntity) then
        pcall(DeleteEntity, v.PropEntity)
    end
    v.PropEntity = nil
    v.PropNetId = nil
end

local function _spawnServerProp(v)
    if not v or not v.SpawnCoords then return end

    -- Ensure we don't leak an old entity if event restarts
    _deleteServerProp(v)

    local ok, ent = pcall(CreateObject, _getPropHash(), v.SpawnCoords.x, v.SpawnCoords.y, v.SpawnCoords.z - 1.0, true, true, false)
    if not ok or not ent or ent == 0 then
        -- If server entity creation is not available in this environment, clients will fallback to local prop.
        return
    end

    -- log จริงยืนยันว่า entity หายไปเลยหลัง Wait(0) เดียว (ไม่ใช่แค่ยัง sync ไม่เสร็จ) — object ที่
    -- สร้างฝั่ง server เฉยๆ โดยไม่ SetEntityAsMissionEntity มักโดนระบบ culling ของเกมลบทิ้งอัตโนมัติ
    -- เพราะไม่มีอะไร "ยึด" มันไว้ ต้องเรียกทันทีหลัง CreateObject ก่อนที่จะโดนเก็บกวาด
    -- (native เดียวกับที่ยืนยันแล้วว่าใช้จริงในโปรเจกต์นี้: vorp_horsepreview, bcc-utils/PedAPI.SetStatic)
    pcall(SetEntityAsMissionEntity, ent, true, true)

    Citizen.Wait(0)
    if not DoesEntityExist(ent) then
        print(('[lp_airdropteam] _spawnServerProp: entity %s no longer exists after Wait(0), aborting prop setup'):format(tostring(ent)))
        return
    end

    pcall(FreezeEntityPosition, ent, true)
    v.PropEntity = ent

    local ok2, netId = pcall(NetworkGetNetworkIdFromEntity, ent)
    if ok2 then
        v.PropNetId = netId
    end
end

local function pickFromRange(v, fallback)
    if type(v) == "number" then return v end
    if type(v) == "table" then
        if #v == 1 then return v[1] end
        if #v >= 2 then return math.random(v[1], v[2]) end
    end
    return fallback
end

local function safePlayerName(xPlayer)
    local f = xPlayer and xPlayer.firstname or ""
    local l = xPlayer and xPlayer.lastname or ""
    local name = (f .. " " .. l):gsub("%s+", " "):gsub("^%s", "")
    if name == "" then return "Unknown" end
    return name
end

local function safeCharId(xPlayer, src)
    return (xPlayer and (xPlayer.charIdentifier or xPlayer.identifier)) or src
end

-- Helper: Send Discord embed
function MJ_SendDiscordEmbed(title, description, fields)
    if not Config or not Config["DiscordWebhook"] or Config["DiscordWebhook"] == "" then
        return
    end
    local embed = {
        ["title"] = title,
        ["description"] = description or "",
        ["color"] = 5793266,
        ["fields"] = fields or {},
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    local payload = {
        username = Config["DiscordBotName"] or "Airdrop Alert",
        avatar_url = Config["DiscordAvatar"] or nil,
        embeds = {embed}
    }
    PerformHttpRequest(Config["DiscordWebhook"], function(err, text, headers) end, 'POST', json.encode(payload), {['Content-Type'] = 'application/json'})
end

-- =========================
-- State bootstrap
-- =========================
local function BuildAirdropState()
    AirdropState = {}
    for k, v in pairs(Config["Airdrop"]) do
        AirdropState[k] = {
            id = k,
            HaveAirdrop = true,
            Label = v.Label,
            NameAirdrop = v.Label,
            sprite = v.MainBlip.sprite,
            scale = v.MainBlip.scale,
            color = v.MainBlip.color,
            text = v.MainBlip.text,
            Coords = v.Coords,
            SpawnCoords = nil,
            Item = v.Item,
            PropNetId = nil,
            PropEntity = nil
        }
    end
end

Citizen.CreateThread(function()
    Citizen.Wait(1500)
    BuildAirdropState()
end)

-- =========================
-- Client handshake + sync
-- =========================
RegisterServerEvent(script_name .. ":CL:GetEvent_Airdrop")
AddEventHandler(script_name .. ":CL:GetEvent_Airdrop", function()
    TriggerClientEvent(script_name .. ":SV:GetEvent_Airdrop", source)
end)

RegisterNetEvent(script_name .. ":SV:RequestSync")
AddEventHandler(script_name .. ":SV:RequestSync", function()
    local src = source

    local unlockRemaining = 0
    if IsAirdropStarted and AirdropRemaining and AirdropRemaining > 0 then
        unlockRemaining = math.max(0, AirdropRemaining - GetGameTimer())
    end

    local removeRemaining = 0
    if IsAirdropStarted and AirdropCooldown and AirdropCooldown > 0 then
        removeRemaining = math.max(0, AirdropCooldown - GetGameTimer())
    end

    -- Snapshot current loot locks so reconnecting players can see who is looting
    local locksSnapshot = {}
    if IsAirdropStarted and type(LootLocks) == "table" then
        for airdropId, lock in pairs(LootLocks) do
            if lock and lock.src then
                locksSnapshot[tonumber(airdropId) or airdropId] = {
                    src = lock.src,
                    name = lock.name or getDisplayNameBySrc(lock.src)
                }
            end
        end
    end

    TriggerClientEvent(script_name .. ":CL:SyncState", src, {
        started = IsAirdropStarted,
        unlockRemaining = unlockRemaining,
        removeRemaining = removeRemaining,
        locks = locksSnapshot,
        zoneLock = (ZoneLockActive and BuildZoneLockSnapshotFor(src) or {})
    }, AirdropState, ZoneCounts)
end)

-- =========================
-- Zone presence (player count)
-- =========================
RegisterNetEvent(script_name .. ":SV:ZonePresence")
AddEventHandler(script_name .. ":SV:ZonePresence", function(airdropId, inside)
    local src = source
    if not IsAirdropStarted then return end
    if not airdropId then return end

    airdropId = tonumber(airdropId) or airdropId
    if not AirdropState or not AirdropState[airdropId] then return end

    ZonePlayers[airdropId] = ZonePlayers[airdropId] or {}
    local set = ZonePlayers[airdropId]

    if inside then
        set[src] = true
    else
        set[src] = nil
    end

    local newCount = tableCount(set)
    if ZoneCounts[airdropId] ~= newCount then
        ZoneCounts[airdropId] = newCount
        TriggerClientEvent(script_name .. ":CL:ZoneCount", -1, airdropId, newCount)
    end

    -- Zone lock enforcement (after unlock ends)
    if (Config and Config["ZoneLockEnabled"]) and ZoneLockActive and (AirdropRemaining == 0) then
        local allowed = ZoneLockAllowed[airdropId] and ZoneLockAllowed[airdropId][src]
        if inside and not allowed then
            -- outsider tried to enter
            TriggerClientEvent(script_name .. ":CL:ZoneDenied", src, airdropId)
        elseif (not inside) and allowed then
            -- allowed player left the ring -> eliminate
            ZoneLockEliminated[airdropId] = ZoneLockEliminated[airdropId] or {}
            if not ZoneLockEliminated[airdropId][src] then
                ZoneLockEliminated[airdropId][src] = true
                TriggerClientEvent(script_name .. ":CL:ZoneEliminated", src, airdropId)
                TriggerClientEvent(script_name .. ":CL:ZoneLockSnapshot", src, BuildZoneLockSnapshotFor(src))
            end
        end
    end
end)


-- client-side confirm (optional): mark eliminated
RegisterNetEvent(script_name .. ":SV:MarkEliminated")
AddEventHandler(script_name .. ":SV:MarkEliminated", function(airdropId)
    local src = source
    if not (Config and Config["ZoneLockEnabled"]) then return end
    if not ZoneLockActive then return end
    if AirdropRemaining and AirdropRemaining > 0 then return end

    airdropId = tonumber(airdropId) or airdropId
    if not airdropId then return end
    if not (ZoneLockAllowed[airdropId] and ZoneLockAllowed[airdropId][src]) then return end

    ZoneLockEliminated[airdropId] = ZoneLockEliminated[airdropId] or {}
    if ZoneLockEliminated[airdropId][src] then return end

    ZoneLockEliminated[airdropId][src] = true
    TriggerClientEvent(script_name .. ":CL:ZoneEliminated", src, airdropId)
    TriggerClientEvent(script_name .. ":CL:ZoneLockSnapshot", src, BuildZoneLockSnapshotFor(src))
end)

-- =========================
-- Looting marker (AIRDROP tag above looter)
-- =========================
RegisterNetEvent(script_name .. ":SV:SetLooting")
AddEventHandler(script_name .. ":SV:SetLooting", function(airdropId, isLooting)
    local src = source
    if not IsAirdropStarted then return end
    if not airdropId then return end

    airdropId = tonumber(airdropId) or airdropId
    if not AirdropState or not AirdropState[airdropId] then return end

    LootingPlayers[airdropId] = LootingPlayers[airdropId] or {}

    if isLooting then
        -- Enforce mutex: if another player is already looting, ignore.
        local lock = LootLocks[airdropId]
        if lock and lock.src ~= src then
            return
        end

        -- Acquire / refresh lock
        LootLocks[airdropId] = { src = src, since = GetGameTimer(), name = getDisplayNameBySrc(src) }
        broadcastLootBusy(airdropId, src, true)

        -- Mark tag
        LootingPlayers[airdropId][src] = true
        TriggerClientEvent(script_name .. ":CL:LootingTag", -1, airdropId, src, true)
    else
        local lock = LootLocks[airdropId]
        if lock and lock.src == src then
            LootLocks[airdropId] = nil
            broadcastLootBusy(airdropId, src, false)

            if LootingPlayers[airdropId] and LootingPlayers[airdropId][src] then
                LootingPlayers[airdropId][src] = nil
                TriggerClientEvent(script_name .. ":CL:LootingTag", -1, airdropId, src, false)
            end
        else
            -- If non-owner tries to clear, just remove their tag entry (safety)
            if LootingPlayers[airdropId] and LootingPlayers[airdropId][src] then
                LootingPlayers[airdropId][src] = nil
                TriggerClientEvent(script_name .. ":CL:LootingTag", -1, airdropId, src, false)
            end
        end
    end
end)


-- =========================
-- Loot lock (mutex)
-- =========================
local function isLockOwner(airdropId, src)
    local lock = LootLocks[airdropId]
    return lock and lock.src == src
end

local function clearLock(airdropId, restoreProps)
    local lock = LootLocks[airdropId]
    if not lock then return end

    local owner = lock.src
    LootLocks[airdropId] = nil
    broadcastLootBusy(airdropId, owner, false)

    -- stop tag
    if LootingPlayers[airdropId] and LootingPlayers[airdropId][owner] then
        LootingPlayers[airdropId][owner] = nil
        TriggerClientEvent(script_name .. ":CL:LootingTag", -1, airdropId, owner, false)
    end
end

RegisterNetEvent(script_name .. ":SV:TryLoot")
AddEventHandler(script_name .. ":SV:TryLoot", function(airdropId)
    local src = source
    if not IsAirdropStarted then
        TriggerClientEvent(script_name .. ":CL:LootLockResult", src, airdropId, false, 0)
        return
    end

    if not airdropId then
        TriggerClientEvent(script_name .. ":CL:LootLockResult", src, airdropId, false, 0)
        return
    end

    airdropId = tonumber(airdropId) or airdropId
    local v = (AirdropState and AirdropState[airdropId])
    if not v or not v.HaveAirdrop then
        TriggerClientEvent(script_name .. ":CL:LootLockResult", src, airdropId, false, 0)
        return
    end

    -- still locked (warmup not finished)
    if AirdropRemaining and AirdropRemaining > 0 and AirdropRemaining > GetGameTimer() then
        TriggerClientEvent(script_name .. ":CL:LootLockResult", src, airdropId, false, 0)
        return
    end

-- Zone lock deny (after unlock ends)
if (Config and Config["ZoneLockEnabled"]) and ZoneLockActive and (AirdropRemaining == 0) then
    local allowed = ZoneLockAllowed[airdropId] and ZoneLockAllowed[airdropId][src]
    if not allowed then
        TriggerClientEvent(script_name .. ":CL:LootLockResult", src, airdropId, false, 0, "no_right")
        return
    end
    local eliminated = ZoneLockEliminated[airdropId] and ZoneLockEliminated[airdropId][src]
    if eliminated then
        TriggerClientEvent(script_name .. ":CL:LootLockResult", src, airdropId, false, 0, "eliminated")
        return
    end
end


    local lock = LootLocks[airdropId]
    if lock and lock.src ~= src then
        TriggerClientEvent(script_name .. ":CL:LootLockResult", src, airdropId, false, lock.src)
        return
    end

    -- acquire / refresh lock
    LootLocks[airdropId] = { src = src, since = GetGameTimer(), name = getDisplayNameBySrc(src) }
    broadcastLootBusy(airdropId, src, true)

    -- mark tag
    LootingPlayers[airdropId] = LootingPlayers[airdropId] or {}
    LootingPlayers[airdropId][src] = true
    TriggerClientEvent(script_name .. ":CL:LootingTag", -1, airdropId, src, true)
    -- ok
    TriggerClientEvent(script_name .. ":CL:LootLockResult", src, airdropId, true, src)
end)

RegisterNetEvent(script_name .. ":SV:ReleaseLoot")
AddEventHandler(script_name .. ":SV:ReleaseLoot", function(airdropId)
    local src = source
    if not airdropId then return end

    airdropId = tonumber(airdropId) or airdropId
    if isLockOwner(airdropId, src) then
        clearLock(airdropId, true)
    end
end)

-- Timeout safety: if a lock is stuck (crash/bug), auto-release it
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        if IsAirdropStarted and next(LootLocks) ~= nil then
            local now = GetGameTimer()
            local timeout = (Config and Config["LootLockTimeout"]) or 20000
            for airdropId, lock in pairs(LootLocks) do
                if lock and lock.since and (now - lock.since) > timeout then
                    clearLock(airdropId, true)
                else
                    -- owner dropped but lock still exists
                    if lock and lock.src and GetPlayerPing(lock.src) == 0 then
                        clearLock(airdropId, true)
                    end
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source

    -- release any loot locks held by this player
    for airdropId, lock in pairs(LootLocks) do
        if lock and lock.src == src then
            clearLock(airdropId, true)
        end
    end

    -- remove from looting marker sets
    for airdropId, set in pairs(LootingPlayers) do
        if set and set[src] then
            set[src] = nil
            TriggerClientEvent(script_name .. ":CL:LootingTag", -1, airdropId, src, false)
        end
    end

    for airdropId, set in pairs(ZonePlayers) do
        if set and set[src] then
            set[src] = nil
            local newCount = tableCount(set)
            if ZoneCounts[airdropId] ~= newCount then
                ZoneCounts[airdropId] = newCount
                TriggerClientEvent(script_name .. ":CL:ZoneCount", -1, airdropId, newCount)
            end
        end
    end
end)

-- =========================
-- Admin command / Auto schedule
-- =========================
if Config['Command'] then
    RegisterCommand(Config['Command'], function(source, args, rawCommand)
        print(('[lp_airdropteam] /%s received from source=%d'):format(Config['Command'], source))

        local user = VORPcore.getUser(source)
        if not user then
            print('[lp_airdropteam] VORPcore.getUser(source) returned nil, aborting')
            return
        end
        local xPlayer = user.getUsedCharacter
        if not xPlayer then
            print('[lp_airdropteam] user.getUsedCharacter is nil, aborting')
            return
        end

        print('[lp_airdropteam] xPlayer.group=' .. tostring(xPlayer.group))

        if xPlayer.group == 'superadmin' or xPlayer.group == 'admin' then
            if IsAirdropStarted then
                print('[lp_airdropteam] IsAirdropStarted already true, ignoring')
                return
            end
            local ok, err = pcall(GameStart)
            if not ok then
                print('[lp_airdropteam] GameStart() ERRORED: ' .. tostring(err))
            else
                print('[lp_airdropteam] GameStart() completed OK, IsAirdropStarted=' .. tostring(IsAirdropStarted))
            end
        else
            print('[lp_airdropteam] source=' .. source .. ' is not admin/superadmin, ignoring')
        end
    end)
else
    print('[lp_airdropteam] Config[\'Command\'] is nil/false -- admin command was never registered!')
end

if Config["AutoTime"] then
    Citizen.CreateThread(function()
        while true do
            if not IsAirdropStarted then
                local date_local = os.date("%H:%M", os.time())
                for _, configTime in ipairs(Config["TimeAirdrop"] or {}) do
                    if configTime == date_local then
                        GameStart()
                    end
                end
            end
            Citizen.Wait(10000)
        end
    end)
end

-- =========================
-- Game flow
-- =========================
function GameStart()
    if IsAirdropStarted then return end

    -- lp_airdropteam: เริ่มรอบทีม (safe zone timer + เปิดให้เข้าร่วมได้) ควบคู่กับ crate เดิม
    StartTeamRound()

    -- Reset counters
    AirdropCount = 0

    -- Make sure base state exists
    if not AirdropState or next(AirdropState) == nil then
        BuildAirdropState()
    end

    ResetZonePresence()

    -- reset looting markers
    for k in pairs(LootingPlayers) do
        LootingPlayers[k] = nil
    end

    AirdropRemaining = GetGameTimer() + (Config["TimeToUnlock"] or 0)

    for k, v in pairs(AirdropState) do
        v.id = k
        v.NameAirdrop = v.Label
        v.Blip = {
            sprite = v.sprite,
            scale = v.scale,
            color = v.color,
            text = v.text
        }
        local rdm = math.random(1, #v.Coords)
        v.SpawnCoords = v.Coords[rdm]
        v.HaveAirdrop = true
        _spawnServerProp(v)
        AirdropCount = AirdropCount + 1
    end

    IsAirdropStarted = true
    AirdropCooldown = 0

    TriggerClientEvent(script_name .. ":CL:AirdropStart", -1, AirdropState)

    Citizen.CreateThread(function()
        while IsAirdropStarted and AirdropRemaining > 0 do
            local t = (AirdropRemaining - GetGameTimer()) / 1000
            for _, v in pairs(AirdropState) do
                v.Text = t
            end
            if t <= 0 then
                for _, v in pairs(AirdropState) do
                    v.Text = "เกมกำลังดำเนินการ"
                end
                AirdropRemaining = 0
                -- Activate zone lock shortly after unlock ends (snapshot players inside)
                Citizen.CreateThread(function()
                    Citizen.Wait(1000)
                    ActivateZoneLock()
                end)
                CoolDownAirdrop()
            end
            Citizen.Wait(1000)
        end
    end)
end

function CoolDownAirdrop()
    AirdropCooldown = GetGameTimer() + (Config["TimeToRemove"] or 0)
    Citizen.CreateThread(function()
        while IsAirdropStarted and AirdropCooldown > 0 do
            local t = (AirdropCooldown - GetGameTimer()) / 1000
            if t <= 0 then
                AirdropCooldown = 0
                AirdropAutoDelete()
            end
            Citizen.Wait(1000)
        end
    end)
end

function AirdropAutoDelete()
    IsAirdropStarted = false
    ResetZoneLock()

    -- lp_airdropteam: จบรอบ วาปทุกคนที่ยังไม่ถูกเด้งออกกลับจุดเข้าร่วมของทีมตัวเอง
    EndTeamRound()

    -- clear loot locks (broadcast UI reset)
    if type(LootLocks) == "table" then
        for airdropId, lock in pairs(LootLocks) do
            if lock and lock.src then
                broadcastLootBusy(tonumber(airdropId) or airdropId, lock.src, false)
            end
        end
    end
    LootLocks = {}
    AirdropCount = 0
    AirdropRemaining = 0
    AirdropCooldown = 0

    for _, v in pairs(AirdropState) do
        if v.HaveAirdrop then
            v.Text = "ไม่มีผู้ครอบครองได้"
            v.HaveAirdrop = false
            
            _deleteServerProp(v)
            TriggerClientEvent(script_name .. ':Revive', -1, v.id)
            TriggerClientEvent(script_name .. ":CL:DeleteAirdrop", -1, v.id)
        end
    end

    -- clear looting markers
    for airdropId, set in pairs(LootingPlayers) do
        if type(set) == "table" then
            for src in pairs(set) do
                TriggerClientEvent(script_name .. ":CL:LootingTag", -1, airdropId, src, false)
            end
        end
        LootingPlayers[airdropId] = nil
    end

    ResetZonePresence()
end

function GameFinish()
    IsAirdropStarted = false
    AirdropCount = 0
    AirdropRemaining = 0
    AirdropCooldown = 0

    -- lp_airdropteam: จบรอบ วาปทุกคนที่ยังไม่ถูกเด้งออกกลับจุดเข้าร่วมของทีมตัวเอง
    EndTeamRound()

    -- delete all server props (safety)
    if type(AirdropState) == "table" then
        for _, v in pairs(AirdropState) do
            _deleteServerProp(v)
        end
    end
    -- clear loot locks (broadcast UI reset)
    if type(LootLocks) == "table" then
        for airdropId, lock in pairs(LootLocks) do
            if lock and lock.src then
                broadcastLootBusy(tonumber(airdropId) or airdropId, lock.src, false)
            end
        end
    end
    LootLocks = {}

    -- clear looting markers
    for airdropId, set in pairs(LootingPlayers) do
        if type(set) == "table" then
            for src in pairs(set) do
                TriggerClientEvent(script_name .. ":CL:LootingTag", -1, airdropId, src, false)
            end
        end
        LootingPlayers[airdropId] = nil
    end

    ResetZonePresence()
end

-- =========================
-- Atomic Claim (prevents double-loot)
-- =========================
local function resolveAirdrop(arg)
    if not AirdropState then return nil, nil end

    local id = tonumber(arg)
    if id and AirdropState[id] then
        return id, AirdropState[id]
    end

    if type(arg) == "string" then
        for aid, v in pairs(AirdropState) do
            if v and v.Label == arg then
                return aid, v
            end
        end
    end

    return nil, nil
end

local function ClaimAirdrop(src, arg)
    local xPlayer = VORPcore.getUser(src).getUsedCharacter
    local airdropId, v = resolveAirdrop(arg)

    if not airdropId or not v then
        TriggerClientEvent(script_name .. ":CL:ClaimResult", src, false, "ไม่พบ Airdrop")
        return false
    end

    if not v.HaveAirdrop then
        TriggerClientEvent(script_name .. ":CL:ClaimResult", src, false, "Airdrop ถูกเปิดไปแล้ว")
        return false
    end

    -- Mark claimed FIRST (prevents double-loot)
    v.Text = "เกมจบแล้ว"
    v.HaveAirdrop = false
    v.NameAirdrop = xPlayer and xPlayer.firstname or v.Label

    _deleteServerProp(v)

    local rewards = {}
    for _, value in ipairs(v.Item or {}) do
        local pct = value.Percent or 100
        if math.random(1, 100) <= pct then
            if value.Item then
                local count = pickFromRange(value.Count, 1)
                exports['vorp_inventory']:addItem(src, value.Item, count)
                table.insert(rewards, ("• %s x%d"):format(value.Item, count))
            elseif value.Weapon then
                local ammo = { ["nothing"] = 0 }
                local components = { ["nothing"] = 0 }
                exports.vorp_inventory:createWeapon(src, string.upper(value.Weapon), ammo, components)
                table.insert(rewards, ("• Weapon: %s"):format(string.upper(value.Weapon)))
            elseif value.Money then
                local money = pickFromRange(value.Money, 0)
                if money > 0 then
                    xPlayer.addCurrency(0, money)
                    table.insert(rewards, ("• Money: $%d"):format(money))
                end
            elseif value.BlackMoney then
                local black = pickFromRange(value.BlackMoney, 0)
                if black > 0 then
                    xPlayer.addCurrency(1, black)
                    table.insert(rewards, ("• BlackMoney: $%d"):format(black))
                end
            end
        end
    end

    -- clear loot lock (no restore; crate is being claimed and will be deleted)
    if LootLocks[airdropId] then
        local owner = LootLocks[airdropId].src
        LootLocks[airdropId] = nil
        broadcastLootBusy(airdropId, owner or src, false)
    end

    -- stop looting marker for this player (safety)
    if LootingPlayers[airdropId] and LootingPlayers[airdropId][src] then
        LootingPlayers[airdropId][src] = nil
        TriggerClientEvent(script_name .. ":CL:LootingTag", -1, airdropId, src, false)
    end

    -- Discord logs
    local playerName = safePlayerName(xPlayer)
    local charid = safeCharId(xPlayer, src)
    local airdropName = tostring(v.Label or arg or airdropId)

    if Config["NotifyLoot"] and #rewards > 0 then
        local fields = {
            {name = "Player", value = string.format("%s (ID: %s)", playerName, tostring(charid)), inline = false},
            {name = "Airdrop", value = airdropName, inline = true},
            {name = "Rewards", value = table.concat(rewards, "\n"), inline = false}
        }
        MJ_SendDiscordEmbed("Airdrop Looted", "ผู้เล่นได้รับของจาก Airdrop", fields)
    end

    if Config["NotifyClaim"] then
        local fields = {
            {name = "Player", value = string.format("%s (ID: %s)", playerName, tostring(charid)), inline = false},
            {name = "Airdrop", value = airdropName, inline = true}
        }
        MJ_SendDiscordEmbed("Airdrop Claimed", "ผู้เล่นเปิดกล่อง Airdrop สำเร็จ", fields)
    end

    -- lp_leaderboard (บอร์ดเมือง): ผู้ลูทกล่องได้คนแรกของรอบ = เมืองตัวเองชนะรอบนี้
    if RecordAirdropWinner then RecordAirdropWinner(src) end

    -- Notify clients
    TriggerClientEvent(script_name .. ':Revive', -1, airdropId)
    TriggerClientEvent(script_name .. ":CL:DeleteAirdrop", -1, airdropId)
    TriggerClientEvent(script_name .. ":CL:ClaimResult", src, true, (#rewards > 0 and table.concat(rewards, "\n") or "สำเร็จ") )

    AirdropCount = math.max(0, AirdropCount - 1)
    if AirdropCount == 0 then
        GameFinish()
    end

    return true
end

RegisterServerEvent(script_name .. ":SV:ClaimAirdrop")
AddEventHandler(script_name .. ":SV:ClaimAirdrop", function(name)
    ClaimAirdrop(source, name)
end)

-- Backward compatibility (old client)
RegisterServerEvent(script_name .. ":SV:Getitem")
AddEventHandler(script_name .. ":SV:Getitem", function(name)
    ClaimAirdrop(source, name)
end)

RegisterServerEvent(script_name .. ":SV:DeleteAirdrop")
AddEventHandler(script_name .. ":SV:DeleteAirdrop", function(name)
    ClaimAirdrop(source, name)
end)

-- =========================
-- Original verify / lock (kept)
-- =========================

if GetCurrentResourceName() ~= script_name then
    os.exit()
end
