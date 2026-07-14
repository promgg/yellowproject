-- lp_eventnotify / client/main.lua
-- Pure display. Reads GlobalState.lp_eventnotify (server-authoritative, see
-- server/main.lua) and forwards the active-event list to the NUI. Never
-- decides anything and never fires a single TriggerServerEvent — this
-- resource has no client-writable state at all.
--
-- Event-driven, not polling: AddStateBagChangeHandler only fires the NUI push
-- when the active-event SET actually changes (start/stop/expire). The
-- per-second countdown tick happens entirely inside the NUI's own local timer
-- (html/js/app.js) — client.lua does not re-push every second.

local function dbg(msg) if Config.Debug then print(('[lp_eventnotify] %s'):format(msg)) end end

-- ── server time sync (same pattern as lp_robbery — os.time() doesn't exist
-- client-side, and the countdown shouldn't drift off the local player's clock) ──
local serverTimeOffset = 0
local function syncTimeFromState(gs)
    if gs and gs.serverTime then
        serverTimeOffset = gs.serverTime - (GetGameTimer() / 1000)
    end
end
local function nowServer()
    return math.floor((GetGameTimer() / 1000) + serverTimeOffset)
end

local function pushToNui(gs)
    if not gs or not gs.events or #gs.events == 0 then
        SendNUIMessage({ action = 'hide' })
        return
    end

    syncTimeFromState(gs)
    local now = nowServer()
    local events = {}
    for _, ev in ipairs(gs.events) do
        if ev.mode == 'progress' then
            events[#events + 1] = { id = ev.id, icon = ev.icon, label = ev.label, mode = 'progress', current = ev.current, total = ev.total }
        else
            local remaining = ev.endsAt - now
            if remaining > 0 then
                events[#events + 1] = { id = ev.id, icon = ev.icon, label = ev.label, seconds = remaining }
            end
        end
    end

    if #events == 0 then
        SendNUIMessage({ action = 'hide' })
    else
        SendNUIMessage({ action = 'show', events = events })
        dbg(('pushed %d active event(s) to NUI'):format(#events))
    end
end

-- fires only on an actual change to GlobalState.lp_eventnotify (start/stop/expire) —
-- see server/main.lua's syncState(). Empty bagFilter ('') matches the global bag.
AddStateBagChangeHandler('lp_eventnotify', '', function(_, _, value)
    pushToNui(value)
end)

-- catch up once on load/join in case events were already active before this
-- client connected or before the resource (re)started on an already-running server
CreateThread(function()
    repeat Wait(500) until LocalPlayer.state.IsInSession
    pushToNui(GlobalState.lp_eventnotify)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SendNUIMessage({ action = 'hide' })
end)
