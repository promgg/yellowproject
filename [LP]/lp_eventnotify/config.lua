-- lp_eventnotify / config.lua  (shared)
-- Top-right badge row showing active server-wide events (Hot Time, Deathmatch,
-- Golden Time, ...) with a live countdown. Server owns every active event
-- (see server/main.lua); this file is data only.

Config = {}

Config.Debug = true -- gate for dbg() prints

-- ACE permission required for /event_start /event_stop (server console always allowed)
Config.AdminAce = 'lp_eventnotify.admin'

-- Presets so callers (admin commands or other resources via exports) can pass
-- just a short id instead of repeating icon/label every time. `icon` must
-- match one of html/js/app.js's ICON_MAP keys (or be a full nui://.../path).
Config.Presets = {
    ['hot-time']    = { label = 'HOT TIME',    icon = 'hot-time' },
    ['deathmatch']  = { label = 'DEATHMATCH',  icon = 'deathmatch' },
    ['golden-time'] = { label = 'GOLDEN TIME', icon = 'golden-time' },
}

-- seconds — how often the server sweeps for naturally-expired events (client
-- ticks its own countdown locally between updates; this is just cleanup so
-- GlobalState doesn't hold onto ended events forever)
Config.ExpirySweepInterval = 10
