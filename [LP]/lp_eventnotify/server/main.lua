-- lp_eventnotify / server/main.lua
-- SINGLE authority for which events are active and when they end. Mirrored
-- into GlobalState.lp_eventnotify (endsAt = absolute os.time() seconds, not a
-- decrementing "remaining" — so a late joiner or a client that reconnects
-- mid-event computes the correct remaining time on its own, no catch-up
-- event needed; GlobalState already replicates to new clients automatically).
-- This resource has NO client-writable state at all — clients never send it
-- anything. Every event is started/stopped only via an ACE-gated admin
-- command or another resource's export call.

local activeEvents = {} -- [id] = { id, icon, label, endsAt }

local function dbg(msg) if Config.Debug then print(('[lp_eventnotify] %s'):format(msg)) end end
-- always-on (not gated by Config.Debug) — admin actions that start/stop a
-- server-wide event should stay auditable even with debug prints off in prod
local function logTx(msg) print(('[lp_eventnotify][TX] %s'):format(msg)) end

local function syncState()
    local list = {}
    for _, ev in pairs(activeEvents) do
        list[#list + 1] = {
            id = ev.id, icon = ev.icon, label = ev.label,
            endsAt = ev.endsAt, mode = ev.mode, current = ev.current, total = ev.total,
        }
    end
    GlobalState.lp_eventnotify = { events = list, serverTime = os.time() }
end

-- ── core (used by both the admin commands below and the exports) ───────────
-- `who` is purely for the log line (e.g. "src=12" for a command, "export" for
-- a resource-to-resource call) — never used for any authorization decision.
local function startEvent(id, durationSec, label, icon, who)
    id = tostring(id or '')
    if id == '' then return false, 'invalid_id' end
    durationSec = tonumber(durationSec)
    if not durationSec or durationSec <= 0 then return false, 'invalid_duration' end

    local preset = Config.Presets[id]
    activeEvents[id] = {
        id    = id,
        icon  = icon or (preset and preset.icon) or id,
        label = label or (preset and preset.label) or id,
        endsAt = os.time() + math.floor(durationSec),
    }
    syncState()
    logTx(('event started id=%s duration=%ds label=%s by=%s'):format(id, durationSec, activeEvents[id].label, who or 'export'))
    return true
end

local function stopEvent(id, who)
    id = tostring(id or '')
    if not activeEvents[id] then return false, 'not_active' end
    activeEvents[id] = nil
    syncState()
    logTx(('event stopped id=%s by=%s'):format(id, who or 'export'))
    return true
end

-- ── progress-mode badges — static "[current/total]" instead of a ticking
-- countdown (e.g. a hunt/dig event with N spots left, not a timer). No endsAt,
-- so the expiry sweep below ignores these; caller owns start/update/stop explicitly. ──
local function startProgressEvent(id, label, icon, current, total, who)
    id = tostring(id or '')
    if id == '' then return false, 'invalid_id' end
    total = tonumber(total)
    if not total or total <= 0 then return false, 'invalid_total' end

    activeEvents[id] = {
        id = id,
        icon = icon or id,
        label = label or id,
        mode = 'progress',
        current = tonumber(current) or 0,
        total = total,
    }
    syncState()
    logTx(('progress event started id=%s label=%s %d/%d by=%s'):format(id, activeEvents[id].label, activeEvents[id].current, total, who or 'export'))
    return true
end

local function updateProgress(id, current, who)
    id = tostring(id or '')
    local ev = activeEvents[id]
    if not ev or ev.mode ~= 'progress' then return false, 'not_active' end
    ev.current = tonumber(current) or ev.current
    syncState()
    -- logTx(('progress event updated id=%s %d/%d by=%s'):format(id, ev.current, ev.total, who or 'export'))
    return true
end

-- ── public export API ───────────────────────────────────────────────────────
-- exports.lp_eventnotify:StartEvent(id, durationSeconds, label?, icon?) -> ok, err
--   id       string, unique key for this event (re-calling with the same id
--            while it's still active just extends/replaces it)
--   label/icon optional overrides; falls back to Config.Presets[id] if omitted
-- exports.lp_eventnotify:StopEvent(id) -> ok, err
-- exports.lp_eventnotify:IsEventActive(id) -> bool
-- exports.lp_eventnotify:StartProgressEvent(id, label, icon, current, total) -> ok, err
-- exports.lp_eventnotify:UpdateProgress(id, current) -> ok, err
exports('StartEvent', startEvent)
exports('StopEvent', stopEvent)
exports('IsEventActive', function(id) return activeEvents[tostring(id or '')] ~= nil end)
exports('StartProgressEvent', startProgressEvent)
exports('UpdateProgress', updateProgress)

-- ── admin commands (server console OR ACE-allowed players only) ────────────
local function isAdmin(src)
    return src == 0 or IsPlayerAceAllowed(src, Config.AdminAce)
end

RegisterCommand('event_start', function(src, args)
    if not isAdmin(src) then return end
    local id = args[1]
    local minutes = tonumber(args[2])
    if not id or not minutes then
        print('[lp_eventnotify] usage: /event_start <id|preset> <minutes> [label...]')
        return
    end
    local label = #args > 2 and table.concat(args, ' ', 3) or nil
    local ok, err = startEvent(id, minutes * 60, label, nil, ('src=%d'):format(src))
    if not ok then print(('[lp_eventnotify] start failed: %s'):format(err)) end
end, false)

RegisterCommand('event_stop', function(src, args)
    if not isAdmin(src) then return end
    local id = args[1]
    if not id then print('[lp_eventnotify] usage: /event_stop <id>'); return end
    local ok, err = stopEvent(id, ('src=%d'):format(src))
    if not ok then print(('[lp_eventnotify] stop failed: %s'):format(err)) end
end, false)

RegisterCommand('event_list', function(src)
    if not isAdmin(src) then return end
    local now = os.time()
    local n = 0
    for id, ev in pairs(activeEvents) do
        n = n + 1
        if ev.mode == 'progress' then
            print(('[lp_eventnotify] %s label=%s icon=%s progress=%d/%d'):format(id, ev.label, ev.icon, ev.current, ev.total))
        else
            print(('[lp_eventnotify] %s label=%s icon=%s remaining=%ds'):format(id, ev.label, ev.icon, ev.endsAt - now))
        end
    end
    if n == 0 then print('[lp_eventnotify] no active events') end
end, false)

-- ── lifecycle ────────────────────────────────────────────────────────────────
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    activeEvents = {}
    syncState()
    dbg('GlobalState reset on resource start')
end)

-- auto-expire sweep — server owns cleanup so GlobalState never holds a
-- zeroed-out event forever waiting for someone to notice
CreateThread(function()
    while true do
        Wait(Config.ExpirySweepInterval * 1000)
        local now = os.time()
        local changed = false
        for id, ev in pairs(activeEvents) do
            if ev.mode ~= 'progress' and ev.endsAt <= now then
                activeEvents[id] = nil
                changed = true
                dbg(('event auto-expired id=%s'):format(id))
            end
        end
        if changed then syncState() end
    end
end)
