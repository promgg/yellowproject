-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb
--
-- MJ-Airdrop | VORP RedM RDR3
-- - Hold-to-loot + progress bar
-- - Cancel loot if taking damage / getting shot / dying / moving away
-- - Sync zone player count + show in UI
-- - Fix decimals in timer UI on reconnect (ms -> int seconds)
-- - Crate PTFX (SCR_ADV_SOK)

script_name = script_name or 'MJ-Airdrop'

Keys = {
    ["E"] = 0xCEFD9220, -- INPUT_CONTEXT
    ["G"] = 0x760A9C6F, -- INPUT_INTERACT_OPTION1
}

VORPcore = exports['vorp_core']:GetCore()

AirdropRemaining = 0
IsAirdropStarted = false
AirdropState = {}
OutZoneAi = {}
Radius = 100.0

-- Zone counts (synced from server)
local ZoneCount = {} -- [airdropId] = count


-- Zone lock after unlock ends (membership locked)
local USE_ZONE_LOCK = (Config and Config["ZoneLockEnabled"]) == true
local ZoneLockState = {} -- [airdropId] = { locked=true, allowed=bool, eliminated=bool }
local ZoneDotActive = {} -- [airdropId] = true/false

-- If the player already "served" the punishment (died once), do NOT restart DoT after respawn.
-- Still blocks re-entry into the locked ring.
local ZonePunished = {} -- [airdropId] = true

-- Looting marker (show "AIRDROP" above player who is currently holding-to-loot)
local LootingTag = {} -- [airdropId] = { [serverId] = true }

-- Loot busy info for UI (who is currently looting this airdrop)
-- [airdropId] = { src = int, name = string, busy = true }
local LootBusy = {}

-- Prevent "press to loot" text from re-appearing while an airdrop is being finalized/removed
-- (fix: after successful loot, the UI prompt could briefly re-show and then get stuck)
local SuppressLootPrompt = {} -- [airdropId] = true

-- =========================
-- Native RDR2 Prompt (Hold E)
-- - Shows real E prompt + circular hold progress
-- - Uses server-side looting mutex (only one looter)
-- =========================
-- Forced OFF per requested UX:
-- - No native prompt / no 2D text
-- - Use NUI bottom hint + hold-to-loot + progress bar
local USE_NATIVE_LOOT_PROMPT = false
local USE_LOOT_PROGRESS_UI = (Config and (Config['ShowLootProgressUI'] ~= false)) or true

local LootPrompt = {
    handle = nil,
    group = GetRandomIntInRange(0, 0xFFFFFF),
    shown = false,
    currentAirdrop = nil
}

local function ensureLootPrompt()
    if LootPrompt.handle or not USE_NATIVE_LOOT_PROMPT then return end
    local lootKey = (Config and Config['LootKey']) or Keys['E']
    local holdMs  = (Config and Config['TimeToPickingAirdrop']) or 5000

    local prompt = PromptRegisterBegin()
    PromptSetControlAction(prompt, lootKey)
    PromptSetText(prompt, CreateVarString(10, 'LITERAL_STRING', (Config and Config['NativePromptText']) or 'เก็บ Airdrop'))
    -- Start hidden until player is actually in range
    PromptSetEnabled(prompt, false)
    PromptSetVisible(prompt, false)

    -- Hold-to-complete with circular progress. Prefer native auto-fill (configurable duration).
    if Citizen and Citizen.InvokeNative then
        -- _PROMPT_SET_HOLD_AUTO_FILL_MODE(prompt, autoFillTimeMs, holdTimeMs)
        Citizen.InvokeNative(0x3CE932E737C145D6, prompt, holdMs, holdMs)
    elseif PromptSetHoldAutoFillMode then
        pcall(PromptSetHoldAutoFillMode, prompt, holdMs, holdMs)
    elseif PromptSetHoldMode then
        -- Some builds expose this as (prompt, holdTimeMs)
        pcall(PromptSetHoldMode, prompt, holdMs)
    elseif PromptSetStandardizedHoldMode then
        -- Fallback: standardized hold (duration not configurable)
        pcall(PromptSetStandardizedHoldMode, prompt, 1)
    end

    -- Group/tab so the prompt looks like a real RDR2 context prompt
    if Citizen and Citizen.InvokeNative then
        -- _PROMPT_SET_GROUP(prompt, groupId, tabIndex)
        Citizen.InvokeNative(0x2F11D3A254169EA4, prompt, LootPrompt.group, 0)
    elseif PromptSetGroup then
        pcall(PromptSetGroup, prompt, LootPrompt.group, 0)
    end
    PromptRegisterEnd(prompt)
    LootPrompt.handle = prompt
end

local function showLootPromptFor(airdropId, groupTitle)
    if not USE_NATIVE_LOOT_PROMPT then return end
    ensureLootPrompt()
    if not LootPrompt.handle then return end

    LootPrompt.currentAirdrop = airdropId
    LootPrompt.shown = true

    -- keep it visible + update group label every frame
    PromptSetVisible(LootPrompt.handle, true)
    PromptSetEnabled(LootPrompt.handle, true)

    if PromptSetActiveGroupThisFrame then
        PromptSetActiveGroupThisFrame(LootPrompt.group, CreateVarString(10, 'LITERAL_STRING', tostring(groupTitle or 'Airdrop')))
    end
end

local function hideLootPromptFor(airdropId)
    if not USE_NATIVE_LOOT_PROMPT then return end
    if not LootPrompt.handle then return end
    -- Allow force-hide (airdropId == nil) to prevent stuck prompts
    if airdropId ~= nil and LootPrompt.currentAirdrop ~= airdropId then return end

    LootPrompt.shown = false
    LootPrompt.currentAirdrop = nil
    PromptSetVisible(LootPrompt.handle, false)
    PromptSetEnabled(LootPrompt.handle, false)
    if PromptRestartModes then
        PromptRestartModes(LootPrompt.handle)
    end
end

local function resetLootPrompt()
    if not USE_NATIVE_LOOT_PROMPT then return end
    if not LootPrompt.handle then return end
    local holdMs = (Config and Config['TimeToPickingAirdrop']) or 5000

    if PromptRestartModes then
        PromptRestartModes(LootPrompt.handle)
    end

    -- Re-apply hold duration (so the circle always matches Config)
    if Citizen and Citizen.InvokeNative then
        Citizen.InvokeNative(0x3CE932E737C145D6, LootPrompt.handle, holdMs, holdMs)
    elseif PromptSetHoldAutoFillMode then
        pcall(PromptSetHoldAutoFillMode, LootPrompt.handle, holdMs, holdMs)
    elseif PromptSetHoldMode then
        pcall(PromptSetHoldMode, LootPrompt.handle, holdMs)
    end
end

local function lootPromptCompleted()
    if not USE_NATIVE_LOOT_PROMPT then return false end
    if not LootPrompt.handle or not PromptHasHoldModeCompleted then return false end
    return PromptHasHoldModeCompleted(LootPrompt.handle)
end

local function isSomeoneLooting(airdropId)
    -- Prefer explicit server busy broadcast (fast + accurate)
    local b = LootBusy and LootBusy[airdropId]
    if b and b.busy then return true end

    -- Fallback: infer from looting tag set
    local t = LootingTag and LootingTag[airdropId]
    if not t then return false end
    for _ in pairs(t) do return true end
    return false
end

local function isMeLooting(airdropId)
    local myId = GetPlayerServerId(PlayerId())
    local t = LootingTag and LootingTag[airdropId]
    return t and t[myId] == true
end

local function getLootBusyName(airdropId)
    local b = LootBusy and LootBusy[airdropId]
    if b and b.busy then
        if b.name and b.name ~= "" then
            return b.name, b.src
        end
        return "", b.src
    end

    -- Fallback: infer from LootingTag and resolve platform name
    local t = LootingTag and LootingTag[airdropId]
    if t then
        for sid in pairs(t) do
            local pid = GetPlayerFromServerId(sid)
            if pid and pid ~= -1 then
                local pn = GetPlayerName(pid)
                return pn or "", sid
            end
            return "", sid
        end
    end
    return "", 0
end

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    if not onScreen then return end

    local str = CreateVarString(10, 'LITERAL_STRING', tostring(text))
    SetTextScale(0.35, 0.35)
    SetTextColor(255, 215, 0, 235)
    SetTextCentre(true)
    SetTextDropshadow(1, 0, 0, 0, 255)
	-- RedM does not expose SetTextOutline() in some builds.
	-- Guard it so the script never crashes; dropshadow keeps readability.
	if SetTextOutline then
		SetTextOutline()
	end
    DisplayText(str, _x, _y)
end

-- =========================
-- Screen-bottom prompt (center)
-- - Used when Config.UseNativeLootPrompt = false
-- - Matches the user's request: show "กด G" prompt in the middle-bottom
-- =========================
local function keyHintForControlHash(controlHash)
    -- Common keys
    if controlHash == Keys["G"] then
        return "~INPUT_INTERACT_OPTION1~" -- G
    elseif controlHash == Keys["E"] then
        return "~INPUT_CONTEXT~"          -- E
    end
    -- Fallback: still show something sensible
    return "~INPUT_INTERACT_OPTION1~"
end

local function DrawBottomCenterText(text)
    if not text or text == '' then return end
    local str = CreateVarString(10, 'LITERAL_STRING', tostring(text))
    SetTextScale(0.40, 0.40)
    SetTextColor(255, 255, 255, 220)
    SetTextCentre(true)
    SetTextDropshadow(1, 0, 0, 0, 255)
    if SetTextOutline then
        SetTextOutline()
    end
    -- (x=0.5,y=0.92) = center-bottom
    DisplayText(str, 0.50, 0.92)
end

-- Looting state
local Loot = {
    active = false,
    requesting = false,
    requestId = nil,
    airdropId = nil,
    label = nil,
    coords = nil,
    startMs = 0,
    startHP = 0,
}

-- Prevent spammy stacked notifications when a loot is repeatedly cancelled (e.g. DoT ticks)
local _lastLootCancel = { at = 0, reason = "" }

-- =========================
-- Airdrop Crate PTFX (client)
-- =========================
local AirdropPtfx = {
    assetLoaded = {},
    handles = {} -- [airdropId] = ptfxHandle
}

local function normalizeColorValue(value)
    value = value or 0
    value = value / 255.0
    if value > 1.0 then value = 1.0 end
    if value < 0.0 then value = 0.0 end
    return value
end

local function EnsurePtfxAsset(asset)
    if not asset or asset == '' then return false end
    if AirdropPtfx.assetLoaded[asset] then return true end

    RequestNamedPtfxAsset(asset)
    while not HasNamedPtfxAssetLoaded(asset) do
        Wait(20)
    end

    AirdropPtfx.assetLoaded[asset] = true
    return true
end

local function StartAirdropPtfx(airdropId, coords)
    if not Config or not Config["Ptfx"] or not Config["Ptfx"].Enabled then return end
    if not airdropId or not coords then return end
    if AirdropPtfx.handles[airdropId] then return end

    local cfg = Config["Ptfx"]
    if not EnsurePtfxAsset(cfg.Asset) then return end

    UseParticleFxAsset(cfg.Asset)

    local x, y, z = coords.x, coords.y, coords.z

    if cfg.GroundSnap then
        local groundCheck, ground = GetGroundZAndNormalFor_3dCoord(x, y, z)
        if groundCheck then
            z = ground - 1.0
        end
    end

    local scale = cfg.Scale or 1.0
    local zOffset = (cfg.ZOffset or 0.0)

    -- mimic user's example: z - scale
    local fxZ = (z - scale) + zOffset

    local handle = StartParticleFxLoopedAtCoord(
        cfg.FxName or 'scr_adv_sok_torchsmoke',
        x, y, fxZ,
        0.0, 0.0, 0.0,
        scale,
        false, false, false, true
    )

    if handle and handle ~= 0 then
        AirdropPtfx.handles[airdropId] = handle

        local c = cfg.Color or { r = 255, g = 255, b = 255 }
        SetParticleFxLoopedColour(
            handle,
            normalizeColorValue(c.r),
            normalizeColorValue(c.g),
            normalizeColorValue(c.b),
            1
        )

        local dur = tonumber(cfg.Duration or 0) or 0
        if dur > 0 then
            local thisHandle = handle
            Citizen.CreateThread(function()
                Wait(dur * 1000)
                if AirdropPtfx.handles[airdropId] == thisHandle then
                    StopParticleFxLooped(thisHandle, true)
                    AirdropPtfx.handles[airdropId] = nil
                end
            end)
        end
    end
end

local function StopAirdropPtfx(airdropId)
    local h = AirdropPtfx.handles[airdropId]
    if h and h ~= 0 then
        StopParticleFxLooped(h, true)
    end
    AirdropPtfx.handles[airdropId] = nil
end

local function StopAllAirdropPtfx()
    for id, h in pairs(AirdropPtfx.handles) do
        if h and h ~= 0 then
            StopParticleFxLooped(h, true)
        end
        AirdropPtfx.handles[id] = nil
    end
end

local function notify(text, ntype)
    if exports and exports.pNotify then
        exports.pNotify:SendNotification({ text = text, type = ntype or "info" })
    end
end

local function nuiLootProgress(show, label, duration, players, maxPlayers)
    local payload = {
        show = show and true or false,
        label = label or (Config and Config["LabelToPickingAirdrop"]) or "กำลังเปิดแอร์ดรอป",
        duration = duration or (Config and Config["TimeToPickingAirdrop"]) or 10000,
        players = players,
        maxPlayers = maxPlayers
    }

    -- Primary UI (current MJ-Airdrop html/js/progress.js)
    payload.action = "LootProgress"
    SendNUIMessage(payload)

    -- Backward/alternate compatibility (if you swap progress.js to another version)
    if show then
        SendNUIMessage({
            action = "openProgress",
            title = payload.label,
            sub = "ปล่อยปุ่ม = ยกเลิก",
            percent = 0,
            players = payload.players,
            playersMax = payload.maxPlayers
        })
    else
        SendNUIMessage({ action = "closeProgress" })
    end
end

-- =========================
-- NUI bottom hint (no 2D text)
-- - Show: "กดค้าง G เพื่อเก็บ Airdrop" at bottom-center
-- - Can also show busy state when another player is looting
-- =========================
local LootHintUI = {
    shown = false,
    airdropId = nil,
    title = "",
    sub = "",
    key = "",
    state = ""
}

local function keyLabelForControlHash(controlHash)
    if controlHash == Keys["G"] then return "G" end
    if controlHash == Keys["E"] then return "E" end
    return "G"
end

local function nuiLootHint(show, airdropId, title, sub, key, state)
    if not show then
        if not LootHintUI.shown then return end
        if airdropId ~= nil and LootHintUI.airdropId ~= airdropId then return end

        SendNUIMessage({ action = "LootHint", show = false })
        LootHintUI.shown = false
        LootHintUI.airdropId = nil
        LootHintUI.title = ""
        LootHintUI.sub = ""
        LootHintUI.key = ""
        LootHintUI.state = ""
        return
    end

    title = title or "กดค้าง G เพื่อเก็บ Airdrop"
    sub = sub or "ปล่อยปุ่ม/โดนดาเมจ = ยกเลิก"
    key = key or "G"
    state = state or "is-ready"

    if LootHintUI.shown
        and LootHintUI.airdropId == airdropId
        and LootHintUI.title == title
        and LootHintUI.sub == sub
        and LootHintUI.key == key
        and LootHintUI.state == state then
        return
    end

    LootHintUI.shown = true
    LootHintUI.airdropId = airdropId
    LootHintUI.title = title
    LootHintUI.sub = sub
    LootHintUI.key = key
    LootHintUI.state = state

    SendNUIMessage({
        action = "LootHint",
        show = true,
        title = title,
        sub = sub,
        key = key,
        state = state
    })
end

-- =========================================================
-- FAILSAFE: Prevent "stuck" LootHint UI after successful claim
--
-- Root cause of the reported issue:
--  - After Claim, server broadcasts :CL:DeleteAirdrop.
--  - Client handler previously cleared SuppressLootPrompt[id] too early.
--  - In the same frame, the main loop could re-show the hint once more
--    (player is still in range + airdrop state not fully removed yet),
--    then the airdrop entry disappears => no further hide calls => UI stays.
--
-- This watchdog hides the hint if its airdrop no longer exists (or is already
-- marked as claimed) on the client.
-- =========================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(250)

        if LootHintUI and LootHintUI.shown then
            local id = LootHintUI.airdropId
            id = tonumber(id) or id
            local v = (AirdropState and id and AirdropState[id]) or nil

            -- Airdrop removed or already claimed -> force hide
            if (not v) or (v.HaveAirdrop == false) or (not IsAirdropStarted) then
                nuiLootHint(false, nil)
            end
        end
    end
end)

local function hideTextUI()
    if exports and exports['MJ-Textui'] then
        exports['MJ-Textui']:HideTextUI()
    end
end

local function showTextUI(msg)
    if exports and exports['MJ-Textui'] then
        exports['MJ-Textui']:ShowTextUI(msg)
    end
end

local function clearLocalEntities()
    StopAllAirdropPtfx()
    for _, v in pairs(AirdropState or {}) do
        if v.MainBlip then
            RemoveBlip(v.MainBlip)
            v.MainBlip = nil
        end
        if v.RadiusBlip then
            RemoveBlip(v.RadiusBlip)
            v.RadiusBlip = nil
        end
        if v.AirdropProp and DoesEntityExist(v.AirdropProp) then
            -- Do NOT delete server-synced props from client cleanup; server will manage them.
            if not v.PropNetId then
                DeleteEntity(v.AirdropProp)
            end
            v.AirdropProp = nil
        end
    end
end

local function resetLocalState()
    hideTextUI()
    -- Always hide bottom hint on state reset (prevents stuck hint on reconnect/end)
    nuiLootHint(false, nil)
    if USE_NATIVE_LOOT_PROMPT and LootPrompt and LootPrompt.handle then
        PromptSetVisible(LootPrompt.handle, false)
        LootPrompt.shown = false
        LootPrompt.currentAirdrop = nil
        resetLootPrompt()
    end
    Loot.active = false
    Loot.airdropId = nil
    Loot.label = nil
    Loot.coords = nil
    Loot.startMs = 0
    Loot.startHP = 0
    OutZoneAi = {}
	-- Reset zone-lock punishment state for new events
	ZoneDotActive = {}
	ZonePunished = {}

    -- clear looting tags cache
    for k in pairs(LootingTag) do
        LootingTag[k] = nil
    end

    -- clear busy cache
    for k in pairs(LootBusy) do
        LootBusy[k] = nil
    end

    -- clear prompt suppression flags
    for k in pairs(SuppressLootPrompt) do
        SuppressLootPrompt[k] = nil
    end
    Radius = (Config and Config["Radius"]) or 100.0
    if USE_LOOT_PROGRESS_UI then nuiLootProgress(false) end
    resetLootPrompt()
    SendNUIMessage({ action = "LootHint", show = false })
end

local function startUnlockCountdown()
    if AirdropRemaining <= 0 then return end
    Citizen.CreateThread(function()
        while AirdropRemaining > 0 do
            local left = (AirdropRemaining - GetGameTimer()) / 1000
            if left <= 0 then
                AirdropRemaining = 0
                break
            end
            Citizen.Wait(1000)
        end
    end)
end

-- Convert milliseconds -> integer seconds (no decimals in UI, especially after reconnect)
local function msToIntSeconds(ms)
    ms = tonumber(ms) or 0
    if ms <= 0 then return 0 end
    -- ceil keeps countdown feeling fair (e.g. 12.2s => 13s)
    return math.ceil(ms / 1000)
end

local function TaskPlayAnims(active)
    if not active then return end
    RequestAnimDict('amb_work@world_human_farmer_weeding@male_a@idle_a')
    while not HasAnimDictLoaded('amb_work@world_human_farmer_weeding@male_a@idle_a') do
        Wait(50)
    end
    TaskPlayAnim(PlayerPedId(), 'amb_work@world_human_farmer_weeding@male_a@idle_a', 'idle_a', 3.0, 3.0, -1, 1, 0, false, false, false)
end

local function cancelLoot(reason)
    if not Loot.active then return end

    local id = Loot.airdropId

    -- release looting lock + stop marker + restore props (server-driven)
    if Loot.airdropId then
        TriggerServerEvent(script_name .. ":SV:ReleaseLoot", Loot.airdropId)
    end
    Loot.requesting = false
    Loot.requestId = nil

    Loot.active = false
    -- Allow prompt again if the loot was cancelled/released (crate is restored by server)
    if id then
        SuppressLootPrompt[id] = nil
    end
    if USE_LOOT_PROGRESS_UI then nuiLootProgress(false) end
    nuiLootHint(false, id)
    resetLootPrompt()
    ClearPedTasksImmediately(PlayerPedId())

    if reason and reason ~= "" then
		local now = GetGameTimer()
		-- Throttle identical cancel messages to avoid "stacked" toasts.
		if (_lastLootCancel.reason ~= reason) or (now - (_lastLootCancel.at or 0) > 1500) then
			_lastLootCancel.reason = reason
			_lastLootCancel.at = now
			notify(reason, "error")
		end
    end
end

local function startLootForAirdrop(v)
    local ped = PlayerPedId()
    if Loot.active then return end

    Loot.active = true
    Loot.airdropId = v.id
    Loot.label = v.Label
    Loot.coords = v.SpawnCoords
    Loot.startMs = GetGameTimer()
    Loot.startHP = GetEntityHealth(ped)

    -- Suppress the "press to loot" prompt for this airdrop while looting/finalizing
    -- (prevents the prompt from re-appearing for a moment after a successful hold)
    SuppressLootPrompt[v.id] = true

    -- looting lock/tag handled by server when lock is granted

    -- Clear last damage flags so old hits don't instantly cancel
    if ClearEntityLastDamageEntity then
        ClearEntityLastDamageEntity(ped)
    end

    hideTextUI()
    -- Hide bottom hint while looting
    nuiLootHint(false, v.id)
    TaskPlayAnims(true)
    resetLootPrompt()

    local players = (ZoneCount and ZoneCount[v.id]) or 0
    local maxPlayers = (Config and Config['Airdrop'] and Config['Airdrop'][v.id] and Config['Airdrop'][v.id].MaxPlayer) or 0

    if USE_LOOT_PROGRESS_UI then
        nuiLootProgress(true, Config['LabelToPickingAirdrop'], Config['TimeToPickingAirdrop'], players, maxPlayers)
    end
end

local function Outzone(zoneId)

    if (Config and Config["ZoneLockEnabled"]) then return end
    Citizen.CreateThread(function()
        while AirdropState[zoneId] and not IsEntityDead(PlayerPedId()) and not OutZoneAi[zoneId] do
            if AirdropRemaining <= 0 then
                notify("โปรดเข้าวงภายใน 1 วินาที", "error")
                Citizen.Wait(1000)
                if AirdropState[zoneId] and not IsEntityDead(PlayerPedId()) and not OutZoneAi[zoneId] and AirdropRemaining <= 0 then
                    SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) - 10)
                end
            else
                Citizen.Wait(250)
            end
        end

        -- Airdrop loop ended (deleted or desynced). Make sure the text UI is not left stuck on screen.
        hideTextUI()
    end)
end



local function ejectFromRing(center, radius)
    if not center then return end
    local ped = PlayerPedId()
    local p = GetEntityCoords(ped)
    local dx = p.x - center.x
    local dy = p.y - center.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.001 then
        dx, dy, len = 1.0, 0.0, 1.0
    end

    local buffer = (Config and Config["ZoneLockEjectBuffer"]) or 1.5
    local tx = center.x + (dx / len) * (radius + buffer)
    local ty = center.y + (dy / len) * (radius + buffer)
    SetEntityCoords(ped, tx, ty, p.z, false, false, false, true)
end

local function startZoneDot(airdropId)
    -- Normalize key so we never start multiple threads due to "1" vs 1.
    airdropId = tonumber(airdropId) or airdropId
    if not airdropId then return end

    -- If the player already died once from this punishment, do not restart DoT.
    if ZonePunished[airdropId] then return end

    if ZoneDotActive[airdropId] then return end
    ZoneDotActive[airdropId] = true

    Citizen.CreateThread(function()
        local every = (Config and Config["ZoneLeaveDamageEvery"]) or 1000
        local dmg = (Config and Config["ZoneLeaveDamage"]) or 10
        local diedFromDot = false

        while AirdropState and AirdropState[airdropId] and ZoneDotActive[airdropId] do
            Citizen.Wait(every)
            local ped = PlayerPedId()
            if IsEntityDead(ped) then
                diedFromDot = true
                break
            end

            local hp = GetEntityHealth(ped)
            -- Safety: don't underflow health.
            local newHp = hp - dmg
            SetEntityHealth(ped, newHp)
        end

        ZoneDotActive[airdropId] = nil

        -- Once the player dies, do not restart DoT after respawn ("ตายอย่างเดียว").
        if diedFromDot then
            ZonePunished[airdropId] = true
            -- Also ensure any hint/progress is not left stuck on screen after death.
            if USE_LOOT_PROGRESS_UI then nuiLootProgress(false) end
            nuiLootHint(false, airdropId)
        end
    end)
end

local function ensureNetworkProp(v)
    if not v or not v.PropNetId then return nil end

    -- Wait briefly for the network entity to exist/stream
    local ent = 0
    for _ = 1, 40 do -- up to ~2s
        ent = NetworkGetEntityFromNetworkId(v.PropNetId)
        if ent and ent ~= 0 and DoesEntityExist(ent) then
            return ent
        end
        Citizen.Wait(50)
    end
    return nil
end

local function spawnAirdrop(v)
    if not v or not v.SpawnCoords then return end
    if v.HaveAirdrop == false then return end
    -- Prop (server-synced: one shared entity for everyone)
    if not v.AirdropProp or not DoesEntityExist(v.AirdropProp) then
        local netEnt = ensureNetworkProp(v)
        if netEnt and DoesEntityExist(netEnt) then
            v.AirdropProp = netEnt
        else
            -- Fallback (only if server didn't provide a net id)
            if not v.PropNetId then
                local model = Config and Config["Prop"]
                local modelHash = (type(model) == "number" and model) or GetHashKey(tostring(model))
                RequestModel(modelHash)
                while not HasModelLoaded(modelHash) do
                    Wait(20)
                end

                local x, y, z = v.SpawnCoords.x, v.SpawnCoords.y, v.SpawnCoords.z - 1.0
                local obj = CreateObject(modelHash, x, y, z, false, true, false, false, false)
                SetEntityAsMissionEntity(obj, true, true)
                PlaceObjectOnGroundProperly(obj)
                FreezeEntityPosition(obj, true)
                v.AirdropProp = obj
            end
        end
    end

    -- PTFX (smoke/fire on crate)
    StartAirdropPtfx(v.id, v.SpawnCoords)

    -- Blips
    if not v.RadiusBlip then
        v.RadiusBlip = Citizen.InvokeNative(0x45F13B7E0A15C880, 693035517, v.SpawnCoords.x, v.SpawnCoords.y, v.SpawnCoords.z, 100.0)
    end
    if not v.MainBlip then
        v.MainBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, v.SpawnCoords.x, v.SpawnCoords.y, v.SpawnCoords.z)
        SetBlipSprite(v.MainBlip, v.Blip.sprite)
        SetBlipScale(v.MainBlip, v.Blip.scale)
        Citizen.InvokeNative(0x9CB1A1623062F402, v.MainBlip, v.Blip.text)
    end

    -- Shrink ring after unlock
    Citizen.CreateThread(function()
        while AirdropState[v.id] do
            Citizen.Wait(1000)
            if (not USE_ZONE_LOCK) and AirdropRemaining <= 0 and Radius >= 5.0 then
                Radius = Radius - 0.1
            end
        end
    end)

    -- Main loop: ring + interaction
    Citizen.CreateThread(function()
        local promptShown = false
        local lastCount = -1
        local lastInside = nil
        while AirdropState[v.id] do
            Citizen.Wait(0)

            local playerPed = PlayerPedId()
            local pcoords = GetEntityCoords(playerPed)
            local dist = Vdist(v.SpawnCoords.x, v.SpawnCoords.y, v.SpawnCoords.z, pcoords.x, pcoords.y, pcoords.z)

            -- Zone presence sync (for player count)
            local inside = (dist <= Radius)
            if lastInside == nil or inside ~= lastInside then
                lastInside = inside
                TriggerServerEvent(script_name .. ":SV:ZonePresence", v.id, inside)
            end

            -- Draw ring when near
            if dist <= 300.0 then
                Citizen.InvokeNative(0x2A32FAA57B937173, 0x94FDAE17, v.SpawnCoords.x, v.SpawnCoords.y, v.SpawnCoords.z - 10.0, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Radius * 2, Radius * 2, Radius, 255, 0, 0, 100, true, true, 2, false, false, false, false)
            end

            -- Cancel loot if airdrop already removed
            if Loot.active and Loot.airdropId == v.id and (v.HaveAirdrop == false or not AirdropState[v.id]) then
                cancelLoot("ยกเลิก: Airdrop ถูกเปิดไปแล้ว")
            end


-- Zone lock enforcement (after unlock ends): outsiders cannot enter, insiders cannot leave
local _zlHandled = false
if USE_ZONE_LOCK and (AirdropRemaining <= 0) then
    local zl = ZoneLockState[v.id]
    if zl and zl.locked then
        local center = v.SpawnCoords

        if not zl.allowed then
            _zlHandled = true

            -- Cancel any active/requesting loot
            if Loot.active and Loot.airdropId == v.id then
                cancelLoot("ยกเลิก: คุณไม่มีสิทธิ์เข้าร่วม")
            end
            if Loot.requesting and Loot.requestId == v.id then
                Loot.requesting = false
                Loot.requestId = nil
            end

            -- Prevent entering the ring
            if dist <= Radius then
                ejectFromRing(center, Radius)
            end

            -- Hide loot UI/prompt; show locked message when near
            hideTextUI()
            hideLootPromptFor(v.id)
            if USE_LOOT_PROGRESS_UI then nuiLootProgress(false) end
            local showLocked = (dist <= (Radius + 8.0))
            if showLocked then
                nuiLootHint(true, v.id,
                    (Config and Config["ZoneLockDeniedTitle"]) or "คุณไม่มีสิทธิ์เข้าร่วม",
                    (Config and Config["ZoneLockDeniedSub"]) or "",
                    "",
                    "is-locked"
                )
            else
                nuiLootHint(false, v.id)
            end
        else
            -- Allowed player: leaving the ring eliminates them (no return)
            if zl.eliminated then
                _zlHandled = true
            elseif dist > Radius then
                zl.eliminated = true
                ZoneLockState[v.id].eliminated = true
                _zlHandled = true
                TriggerServerEvent(script_name .. ":SV:MarkEliminated", v.id)
            end

            if _zlHandled and zl.eliminated then
	                -- No-return: prevent re-entering the ring
	                if (Config and Config["ZoneLeaveNoReturn"]) and dist <= Radius then
	                    ejectFromRing(center, Radius)
	                end

	                -- Cancel any loot attempt immediately
	                if Loot.active and Loot.airdropId == v.id then
	                    cancelLoot("ยกเลิก: ออกจากวง")
	                end
	                if Loot.requesting and Loot.requestId == v.id then
	                    Loot.requesting = false
	                    Loot.requestId = nil
	                end

	                hideTextUI()
	                hideLootPromptFor(v.id)
	                if USE_LOOT_PROGRESS_UI then nuiLootProgress(false) end

	                -- Apply DoT only until the player dies once. After that, never restart it.
	                if not ZonePunished[v.id] then
	                    startZoneDot(v.id)
	                end

	                -- UI: only show when near the airdrop (prevents "stuck UI" after respawn/far away)
	                local showNear = (dist <= (Radius + 25.0))
	                if showNear then
	                    if ZonePunished[v.id] then
	                        nuiLootHint(true, v.id,
	                            (Config and Config["ZoneLockDeniedTitle"]) or "คุณไม่มีสิทธิ์เข้าร่วม",
	                            (Config and Config["ZoneLockDeniedSub"]) or "",
	                            "",
	                            "is-locked"
	                        )
	                    else
	                        nuiLootHint(true, v.id, "คุณออกจากวงแล้ว", "ห้ามกลับเข้า (ตายอย่างเดียว)", "", "is-error")
	                    end
	                else
	                    nuiLootHint(false, v.id)
	                end
            end
        end
    end
end

-- In shrinking ring
if _zlHandled then
    -- handled by zone lock (skip legacy ring logic)
elseif dist <= Radius then
                if not OutZoneAi[v.id] then
                    OutZoneAi[v.id] = true
                end
                -- Loot interaction
                local lootKey = (Config and Config['LootKey']) or Keys['E']
                local lootDist = (Config and Config['LootDistance']) or 2.0

                local isActiveLoot = (Loot.active and Loot.airdropId == v.id)

                -- If someone else is looting this airdrop, hide ALL "press G" UIs for everyone inside the ring
                -- and instead show a busy state. (Requested UX)
                local inRing = (dist <= Radius)
                local busyHere = false
                if (not isActiveLoot)
                    and inRing
                    and (AirdropRemaining <= 0)
                    and v.HaveAirdrop
                    and (not SuppressLootPrompt[v.id])
                    and isSomeoneLooting(v.id)
                    and (not isMeLooting(v.id)) then
                    busyHere = true
                end

                local canLootHere = isActiveLoot or ((AirdropRemaining <= 0)
                    and v.HaveAirdrop
                    and (dist <= lootDist)
                    and (not IsEntityDead(playerPed))
                    and (not SuppressLootPrompt[v.id])
                    and (not busyHere))

                if canLootHere then
                    local players = (ZoneCount and ZoneCount[v.id]) or 0
                    local maxPlayers = (Config and Config['Airdrop'] and Config['Airdrop'][v.id] and Config['Airdrop'][v.id].MaxPlayer) or 0

                    if USE_NATIVE_LOOT_PROMPT then
                        showLootPromptFor(v.id, ("Airdrop (%d/%d)"):format(players, maxPlayers))

                        -- request server lock as soon as the player starts the hold
                        if not Loot.active and not Loot.requesting and IsControlJustPressed(0, lootKey) then
                            Loot.requesting = true
                            Loot.requestId = v.id
                            TriggerServerEvent(script_name .. ':SV:TryLoot', v.id)
                        end
                    else
                        -- NUI bottom hint (no 2D text)
                        -- Fix UX: once the player starts looting (or is waiting for the server mutex),
                        -- hide the "press/hold G" hint so it doesn't overlap with the progress UI.
                        if Loot.active and Loot.airdropId == v.id then
                            nuiLootHint(false, v.id)
                        elseif Loot.requesting and Loot.requestId == v.id then
                            nuiLootHint(false, v.id)
                        else
                            local k = keyLabelForControlHash(lootKey)
                            nuiLootHint(
                                true,
                                v.id,
                                ("กดค้าง %s เพื่อเก็บ Airdrop"):format(k),
                                ("ผู้เล่นในวง: %d/%d"):format(players, maxPlayers),
                                k,
                                "is-ready"
                            )

                            -- Request server mutex once when the player starts holding
                            if not Loot.requesting and IsControlJustPressed(0, lootKey) then
                                Loot.requesting = true
                                Loot.requestId = v.id
                                -- Hide hint immediately when the attempt starts
                                nuiLootHint(false, v.id)
                                TriggerServerEvent(script_name .. ':SV:TryLoot', v.id)
                                SendNUIMessage({ action = "LootHint", show = false })
                            end
                        end
                    end
                else
                    if USE_NATIVE_LOOT_PROMPT then
                        hideLootPromptFor(v.id)
                    else
                        if busyHere then
                            local n = select(1, getLootBusyName(v.id))
                            local title = "มีคนกำลังเปิด Airdrop อยู่"
                            if n and tostring(n) ~= "" then
                                title = ("กำลังถูกเปิดโดยผู้เล่น %s"):format(tostring(n))
                            end
                            nuiLootHint(true, v.id, title, "รอสักครู่แล้วลองใหม่", "", "is-busy")
                        else
                            nuiLootHint(false, v.id)
                        end
                    end
                end

            else
                -- Left ring
                if USE_NATIVE_LOOT_PROMPT then
                    hideLootPromptFor(v.id)
                else
                    nuiLootHint(false, v.id)
                end
                if OutZoneAi[v.id] and not IsEntityDead(PlayerPedId()) then
                    if promptShown then
                        hideTextUI()
                        promptShown = false
                    end
                    if not USE_ZONE_LOCK then
                    OutZoneAi[v.id] = false
                    Outzone(v.id)
                end

                    if Loot.active and Loot.airdropId == v.id and (Config and Config["CancelLootOnMoveAway"]) then
                        cancelLoot("ยกเลิก: ออกห่างเกินไป")
                    end
                end
            end

            -- Also cancel loot if too far (safety)
            if Loot.active and Loot.airdropId == v.id and Loot.coords then
                local ldist = Vdist(Loot.coords.x, Loot.coords.y, Loot.coords.z, pcoords.x, pcoords.y, pcoords.z)
                local lootDist = (Config and Config["LootDistance"]) or 2.0
                if (Config and Config["CancelLootOnMoveAway"]) and ldist > (lootDist + 0.6) then
                    cancelLoot("ยกเลิก: ออกห่างเกินไป")
                end
            end
        end
    end)
end

local function syncAirdrop()
    if not AirdropState or not Config then return end

    for k, v in pairs(AirdropState) do
        if v and v.SpawnCoords and v.Blip then
            spawnAirdrop(v)
        end
    end
end

-- =========================
-- Loot monitor loop (cancel rules)
-- - Cancel if release key / death / damage
-- - Complete when native prompt hold finishes
-- =========================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        -- If we're waiting for the server mutex but the player releases the key or dies,
        -- cancel the attempt so the UI never gets stuck hidden.
        if Loot.requesting then
            local ped = PlayerPedId()
            local lootKey = (Config and Config["LootKey"]) or Keys["E"]
            if IsEntityDead(ped) or (not IsControlPressed(0, lootKey)) then
                Loot.requesting = false
                Loot.requestId = nil
                -- Ensure any progress/hints are not left stuck
                if USE_LOOT_PROGRESS_UI then nuiLootProgress(false) end
                nuiLootHint(false, nil)
                resetLootPrompt()
            end
        end

        if Loot.active then
            local ped = PlayerPedId()

            -- key must be held
            local lootKey = (Config and Config["LootKey"]) or Keys["E"]
            if not IsControlPressed(0, lootKey) then
                cancelLoot("ยกเลิก")
            end

            -- death
            if Loot.active and IsEntityDead(ped) then
                cancelLoot("ยกเลิก: คุณตายแล้ว")
            end

            -- damage cancels
            if Loot.active and Config and Config["CancelLootOnDamage"] then
                local hp = GetEntityHealth(ped)
                if hp < (Loot.startHP or hp) then
                    cancelLoot("ยกเลิก: คุณได้รับความเสียหาย")
                end

                if Loot.active and (((HasEntityBeenDamagedByAnyPed) and HasEntityBeenDamagedByAnyPed(ped)) or ((HasEntityBeenDamagedByAnyObject) and HasEntityBeenDamagedByAnyObject(ped))) then
                    if ClearEntityLastDamageEntity then
                        ClearEntityLastDamageEntity(ped)
                    end
                    cancelLoot("ยกเลิก: คุณถูกโจมตี")
                end
            end

            -- completed
            -- - Native prompt: waits for PromptHasHoldModeCompleted
            -- - Screen-bottom prompt: completes after TimeToPickingAirdrop ms while key is still held
            local completed = false
            if USE_NATIVE_LOOT_PROMPT then
                completed = lootPromptCompleted()
            else
                local duration = (Config and Config["TimeToPickingAirdrop"]) or 5000
                if duration < 250 then duration = 250 end
                completed = (GetGameTimer() - (Loot.startMs or GetGameTimer())) >= duration
            end

            if Loot.active and completed then
                local airdropId = Loot.airdropId

                if airdropId then
                    SuppressLootPrompt[airdropId] = true
                    hideLootPromptFor(airdropId)
                    nuiLootHint(false, airdropId)
                end
                resetLootPrompt()

                Loot.active = false
                if USE_LOOT_PROGRESS_UI then nuiLootProgress(false) end
                ClearPedTasksImmediately(ped)

                if airdropId then
                    TriggerServerEvent(script_name .. ':SV:ClaimAirdrop', airdropId)
                end
            end
        end
    end
end)

-- =========================
-- Net events
-- =========================
MJDEV_GetEventAirdrop = function()
    -- Start broadcast
    RegisterNetEvent(script_name .. ":CL:AirdropStart")
    AddEventHandler(script_name .. ":CL:AirdropStart", function(data)
        print('Airdrop Start')
        clearLocalEntities()
        resetLocalState()

        AirdropState = {}
        for k, v in pairs(data or {}) do
            AirdropState[k] = v
            -- IMPORTANT: send integer seconds (no decimals)
            SendNUIMessage({
                action = "SyncAirdropTime",
                Airdrop = { id = k, Label = v.Label },
                Time = msToIntSeconds(Config["TimeToUnlock"] or 0)
            })

            -- show player count per airdrop card (initial)
            local maxPlayers = (Config and Config["Airdrop"] and Config["Airdrop"][k] and Config["Airdrop"][k].MaxPlayer) or 0
            SendNUIMessage({
                action = "UpdateAirdropPlayers",
                id = k,
                players = ZoneCount[k] or 0,
                maxPlayers = maxPlayers
            })
        end

        Radius = Config["Radius"]
        AirdropRemaining = GetGameTimer() + (Config["TimeToUnlock"] or 0)
        startUnlockCountdown()

        IsAirdropStarted = true
        syncAirdrop()
    end)

    -- Sync for reconnect/crash
    RegisterNetEvent(script_name .. ":CL:SyncState")
    AddEventHandler(script_name .. ":CL:SyncState", function(state, data, zoneCounts)
        if not state or not state.started then
            return
        end

        clearLocalEntities()
        resetLocalState()

        AirdropState = {}
        for k, v in pairs(data or {}) do
            AirdropState[k] = v
            -- IMPORTANT: send integer seconds (no decimals)
            SendNUIMessage({
                action = "SyncAirdropTime",
                Airdrop = { id = k, Label = v.Label },
                Time = msToIntSeconds(state.unlockRemaining or 0)
            })
        end

        -- zone counts snapshot (for reconnect)
        if type(zoneCounts) == "table" then
            for zid, zc in pairs(zoneCounts) do
                ZoneCount[tonumber(zid) or zid] = tonumber(zc) or 0
            end
        end

    -- Loot locks snapshot (for reconnect): who is currently looting
    if type(state.locks) == "table" then
        for aid, info in pairs(state.locks) do
            local airdropId = tonumber(aid) or aid
            if info and info.src then
                local sid = tonumber(info.src) or info.src
                LootBusy[airdropId] = { src = sid, name = tostring(info.name or ""), busy = true }
                LootingTag[airdropId] = LootingTag[airdropId] or {}
                LootingTag[airdropId][sid] = true
            end
        end
    end

        -- push player counts into NUI after reconnect sync
        for zid, zc in pairs(ZoneCount) do
            local maxPlayers = (Config and Config["Airdrop"] and Config["Airdrop"][zid] and Config["Airdrop"][zid].MaxPlayer) or 0
            SendNUIMessage({
                action = "UpdateAirdropPlayers",
                id = zid,
                players = zc,
                maxPlayers = maxPlayers
            })
        end

        Radius = Config["Radius"]
        if (state.unlockRemaining or 0) > 0 then
            AirdropRemaining = GetGameTimer() + state.unlockRemaining
            startUnlockCountdown()
        else
            AirdropRemaining = 0
        end

        IsAirdropStarted = true
        syncAirdrop()
    end)

    -- Zone player counts
    

-- Zone lock snapshot (after unlock ends)
RegisterNetEvent(script_name .. ":CL:ZoneLockSnapshot")
AddEventHandler(script_name .. ":CL:ZoneLockSnapshot", function(snap)
    if type(snap) ~= "table" then return end
    ZoneLockState = snap

    -- Stop legacy out-of-zone damage threads once lock starts
    for aid, info in pairs(snap) do
        local airdropId = tonumber(aid) or aid
        if info and info.locked then
            OutZoneAi[airdropId] = true
        end
    end
end)

RegisterNetEvent(script_name .. ":CL:ZoneDenied")
AddEventHandler(script_name .. ":CL:ZoneDenied", function(airdropId)
    airdropId = tonumber(airdropId) or airdropId
    -- Soft feedback only (actual enforcement is client-side)
    if airdropId then
        nuiLootHint(true, airdropId,
            (Config and Config["ZoneLockDeniedTitle"]) or "คุณไม่มีสิทธิ์เข้าร่วม",
            (Config and Config["ZoneLockDeniedSub"]) or "",
            "",
            "is-locked"
        )
    end
end)

RegisterNetEvent(script_name .. ":CL:ZoneEliminated")
AddEventHandler(script_name .. ":CL:ZoneEliminated", function(airdropId)
    airdropId = tonumber(airdropId) or airdropId
    if not airdropId then return end
    ZoneLockState[airdropId] = ZoneLockState[airdropId] or { locked = true, allowed = true }
    ZoneLockState[airdropId].eliminated = true
    startZoneDot(airdropId)
end)

RegisterNetEvent(script_name .. ":CL:ZoneCount")
    AddEventHandler(script_name .. ":CL:ZoneCount", function(airdropId, count)
        if not airdropId then return end
        ZoneCount[airdropId] = tonumber(count) or 0

        -- Update NUI card (player count per airdrop)
        local maxPlayers = (Config and Config["Airdrop"] and Config["Airdrop"][airdropId] and Config["Airdrop"][airdropId].MaxPlayer) or 0
        SendNUIMessage({
            action = "UpdateAirdropPlayers",
            id = airdropId,
            players = ZoneCount[airdropId],
            maxPlayers = maxPlayers
        })
    end)



    -- Loot lock result (server-side mutex)
    RegisterNetEvent(script_name .. ":CL:LootLockResult")
    AddEventHandler(script_name .. ":CL:LootLockResult", function(airdropId, ok, ownerSrc, reason)
        airdropId = tonumber(airdropId) or airdropId

        -- Only handle if we are waiting for this airdrop
        if not Loot.requesting or Loot.requestId ~= airdropId then
            return
        end

        Loot.requesting = false
        Loot.requestId = nil

        
if not ok then
    if reason == "no_right" then
        nuiLootHint(true, airdropId,
            (Config and Config["ZoneLockDeniedTitle"]) or "คุณไม่มีสิทธิ์เข้าร่วม",
            (Config and Config["ZoneLockDeniedSub"]) or "",
            "",
            "is-locked"
        )
    elseif reason == "eliminated" then
        nuiLootHint(true, airdropId, "คุณออกจากวงแล้ว", "ห้ามกลับเข้า (ตายอย่างเดียว)", "", "is-error")
    else
        notify("มีคนกำลังเปิด Airdrop อยู่", "error")
    end
    resetLootPrompt()
    return
end

        local v = AirdropState and AirdropState[airdropId]
        if not v or not v.HaveAirdrop then
            TriggerServerEvent(script_name .. ":SV:ReleaseLoot", airdropId)
            resetLootPrompt()
            return
        end

        local ped = PlayerPedId()
        if IsEntityDead(ped) then
            TriggerServerEvent(script_name .. ":SV:ReleaseLoot", airdropId)
            resetLootPrompt()
            return
        end

        local lootKey = (Config and Config["LootKey"]) or Keys["E"]
        if not IsControlPressed(0, lootKey) then
            TriggerServerEvent(script_name .. ":SV:ReleaseLoot", airdropId)
            resetLootPrompt()
            return
        end

        local sc = v.SpawnCoords
        if not sc then
            TriggerServerEvent(script_name .. ":SV:ReleaseLoot", airdropId)
            resetLootPrompt()
            return
        end

        local lootDist = (Config and Config["LootDistance"]) or 2.0
        local pc = GetEntityCoords(ped)
        local dist = Vdist(sc.x, sc.y, sc.z, pc.x, pc.y, pc.z)
        if dist > (lootDist + 0.6) then
            TriggerServerEvent(script_name .. ":SV:ReleaseLoot", airdropId)
            resetLootPrompt()
            return
        end

        -- Start hold-to-loot (server already set tag/lock)
        resetLootPrompt()

        startLootForAirdrop(v)
    end)

    -- Wipe all props/FX for this airdrop (called when someone starts looting)
    RegisterNetEvent(script_name .. ":CL:WipeAirdropProps")
    AddEventHandler(script_name .. ":CL:WipeAirdropProps", function(airdropId)
        airdropId = tonumber(airdropId) or airdropId
        local v = AirdropState and AirdropState[airdropId]
        if not v then return end

        StopAirdropPtfx(airdropId)

        if v.AirdropProp and DoesEntityExist(v.AirdropProp) then
            if not v.PropNetId then
                DeleteEntity(v.AirdropProp)
            end
        end
        v.AirdropProp = nil
    end)

    -- Restore props/FX when the looter cancels/releases (so others can loot later)
    local function ensureAirdropProp(v)
        if not v or not v.SpawnCoords then return end
        if v.HaveAirdrop == false then return end
        if v.AirdropProp and DoesEntityExist(v.AirdropProp) then return end

        local model = Config and Config["Prop"]
        local modelHash = (type(model) == "number" and model) or GetHashKey(tostring(model))
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(20)
        end

        local x, y, z = v.SpawnCoords.x, v.SpawnCoords.y, v.SpawnCoords.z - 1.0
        local obj = CreateObject(modelHash, x, y, z, true, true, false, false, false)
        SetEntityAsMissionEntity(obj, true, true)
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        v.AirdropProp = obj
    end

    RegisterNetEvent(script_name .. ":CL:RestoreAirdropProps")
    AddEventHandler(script_name .. ":CL:RestoreAirdropProps", function(airdropId)
        airdropId = tonumber(airdropId) or airdropId
        local v = AirdropState and AirdropState[airdropId]
        if not v then return end
        if v.HaveAirdrop == false then return end

        ensureAirdropProp(v)
        StartAirdropPtfx(airdropId, v.SpawnCoords)
    end)
    -- Looting marker sync ("AIRDROP" above the looter)
    -- Busy UI sync (bottom hint: "กำลังถูกเปิดโดยผู้เล่น X")
    RegisterNetEvent(script_name .. ":CL:LootBusy")
    AddEventHandler(script_name .. ":CL:LootBusy", function(airdropId, serverId, name, isBusy)
        if not airdropId then return end
        airdropId = tonumber(airdropId) or airdropId
        serverId = tonumber(serverId) or serverId

        if isBusy then
            LootBusy[airdropId] = {
                src = serverId,
                name = tostring(name or ""),
                busy = true
            }

            -- Seed tag cache too (important for reconnecting players)
            LootingTag[airdropId] = LootingTag[airdropId] or {}
            LootingTag[airdropId][serverId] = true
        else
            LootBusy[airdropId] = nil
        end
    end)

    RegisterNetEvent(script_name .. ":CL:LootingTag")
    AddEventHandler(script_name .. ":CL:LootingTag", function(airdropId, serverId, isLooting)
        if not airdropId or not serverId then return end
        airdropId = tonumber(airdropId) or airdropId
        serverId = tonumber(serverId) or serverId

        LootingTag[airdropId] = LootingTag[airdropId] or {}

        if isLooting then
            LootingTag[airdropId][serverId] = true
        else
            LootingTag[airdropId][serverId] = nil

            -- If the lock owner cleared, also clear busy info
            local b = LootBusy and LootBusy[airdropId]
            if b and b.src == serverId then
                LootBusy[airdropId] = nil
            end
        end
    end)

    -- Claim result feedback
    RegisterNetEvent(script_name .. ":CL:ClaimResult")
    AddEventHandler(script_name .. ":CL:ClaimResult", function(ok, msg)
        if ok then
            notify(msg or "สำเร็จ", "success")
        else
            notify(msg or "ไม่สำเร็จ", "error")
        end
    end)

    -- Delete airdrop everywhere
    RegisterNetEvent(script_name .. ":CL:DeleteAirdrop")
    AddEventHandler(script_name .. ":CL:DeleteAirdrop", function(id)
        id = tonumber(id) or id

        -- Always force-close any loot prompt/progress UI (native + nui)
        hideTextUI()
        if USE_LOOT_PROGRESS_UI then nuiLootProgress(false) end
        nuiLootHint(false, nil)
        -- Force-hide prompt (id can be nil/mismatched if state desyncs)
        hideLootPromptFor(nil)
        resetLootPrompt()
        -- Keep the prompt suppressed for this id. Clearing it here can race with
        -- the main loop and cause the hint to re-show once right before the
        -- airdrop state is removed, leaving the UI stuck for the claimer.
        SuppressLootPrompt[id] = true

        -- Always try to remove the NUI card, even if local state is already nil
        SendNUIMessage({ action = "RemoveAirdrop", id = id })

        StopAirdropPtfx(id)

        -- clear tag cache for this airdrop
        LootingTag[id] = nil
        LootBusy[id] = nil
        if Loot.active and Loot.airdropId == id then
            cancelLoot("ยกเลิก: Airdrop ถูกเปิดไปแล้ว")
        end

        if Loot.requesting and Loot.requestId == id then
            Loot.requesting = false
            Loot.requestId = nil
        end

        if AirdropState[id] then
            for _, v in pairs(AirdropState) do
                if v and v.id == id then
                    if v.MainBlip then RemoveBlip(v.MainBlip) end
                    if v.RadiusBlip then RemoveBlip(v.RadiusBlip) end
                    if v.AirdropProp and DoesEntityExist(v.AirdropProp) then
                        if not v.PropNetId then
                            DeleteEntity(v.AirdropProp)
                        end
                    end
                end
            end

            OutZoneAi[id] = nil
	            ZoneDotActive[id] = nil
	            ZonePunished[id] = nil
            AirdropState[id] = nil
        end
    end)

    -- Revive helper
    RegisterNetEvent(script_name .. ':Revive')
    AddEventHandler(script_name .. ':Revive', function(id)
        if not id then return end
        if AirdropState[id] then
            local v = AirdropState[id]
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local dist = Vdist(v.SpawnCoords.x, v.SpawnCoords.y, v.SpawnCoords.z, playerCoords.x, playerCoords.y, playerCoords.z)
            if dist <= (Config["Radius"] or 100.0) then
                if IsEntityDead(playerPed) then
                    DoScreenFadeOut(800)
                    while not IsScreenFadedOut() do
                        Citizen.Wait(50)
                    end
                    Citizen.Wait(800)
                    TriggerEvent('vorp_core:Client:OnPlayerRevive')
                    SetEntityHealth(playerPed, 600)
                    Citizen.Wait(800)
                    DoScreenFadeIn(800)
                end
            end
        end
    end)

    -- =========================
    -- Draw "AIRDROP" tag above player who is currently looting
    -- Visible only to players inside the airdrop circle
    -- =========================
    Citizen.CreateThread(function()
        while true do
            local sleep = 500

            if IsAirdropStarted and AirdropState and next(AirdropState) ~= nil then
                sleep = 0

                local myPed = PlayerPedId()
                local myCoords = GetEntityCoords(myPed)
                local ringRadius = Radius or (Config and Config["Radius"]) or 100.0

                for airdropId, set in pairs(LootingTag) do
                    if set and next(set) ~= nil then
                        local v = AirdropState[airdropId]
                        if v and v.SpawnCoords then
                            local sc = v.SpawnCoords
                            local distToZone = Vdist(sc.x, sc.y, sc.z, myCoords.x, myCoords.y, myCoords.z)

                            -- show only when YOU are inside this airdrop ring
                            if distToZone <= ringRadius then
                                for serverId in pairs(set) do
                                    local ply = GetPlayerFromServerId(tonumber(serverId) or serverId)
                                    if ply and ply ~= -1 then
                                        local ped = GetPlayerPed(ply)
                                        if ped and DoesEntityExist(ped) then
                                            local pc = GetEntityCoords(ped)
                                            local d = Vdist(pc.x, pc.y, pc.z, myCoords.x, myCoords.y, myCoords.z)

                                            -- extra distance guard for performance / readability
                                            if d <= (ringRadius + 15.0) then
                                                DrawText3D(pc.x, pc.y, pc.z + 1.15, "AIRDROP")
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            Citizen.Wait(sleep)
        end
    end)

end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if Loot.active and Loot.airdropId then
            TriggerServerEvent(script_name .. ":SV:ReleaseLoot", Loot.airdropId)
        end
        clearLocalEntities()
        hideTextUI()
        hideLootPromptFor(nil)
        nuiLootProgress(false)
        nuiLootHint(false, nil)
    end
end)