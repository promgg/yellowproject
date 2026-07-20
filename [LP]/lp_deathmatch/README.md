# lp_deathmatch

Server-authoritative city-vs-city deathmatch event. Team = each player's home city from
`nx_cityselect` (same bridge pattern as `nx_graverobbery`). No arena — kills count anywhere
on the map.

Designed via a `/grill-me` session; the decisions below reflect that discussion, not
arbitrary defaults.

## Dependencies

- `vorp_core`, `vorp_inventory`, `oxmysql` found in this project.
- `nx_cityselect` found in `[nx]` — soft dependency for team assignment (falls back to a
  direct `nx_player_city` query if the resource isn't running; still requires the table to exist).
- `pNotify` found in `[Script]`.

## Lifecycle

1. **Trigger**: daily schedule (`Config.Schedule` in `server/config_server.lua`) — fires once
   per calendar day the first time the server clock passes `startHour:startMinute`.
2. **Start**: a live scoreboard appears for everyone — 3 cities at 0, countdown to end.
   Broadcast via `TriggerClientEvent` (not GlobalState) since updates are only per-kill,
   not high-frequency.
3. **During**: a kill from city A on a player from city B/C scores A +1, broadcast instantly.
4. **End**: scoreboard shows final ranking, rewards go out immediately.

## Scoring rules

- **Where deaths come from**: this resource does no death detection of its own. It listens to
  `vorp_core:Server:OnPlayerDeath`, which `vorp_core/client/respawnsystem.lua` fires after
  polling `IsPlayerDead()` and reading `GetPedSourceOfDeath` / `GetPedCauseOfDeath`. `source`
  is the victim, arg 1 is the killer's server id, arg 2 is the death-cause hash. Same event
  `lp_leaderboard` and `lp_airdropteam` already use.
- **Valid kill methods**: everything except the causes listed in `Config.DeniedDeathCauses`
  (fists, falling, drowning, fire, explosion, being run over, animals). A denylist rather than
  an allowlist — RDR3 keeps adding weapons, and listing what *isn't* a fight is shorter and
  harder to get wrong than enumerating every gun. Names that don't exist in RDR3 are harmless:
  `joaat` just produces a hash nothing matches.
- **Verification**: the killer must be a currently-connected player and not the victim,
  distance between the two must be plausible (`Config.Security.maxKillDistance`), and a
  per-pair cooldown (`Config.Security.pairCooldownMinutes`, default 10) blocks two players from
  trading kills back and forth for infinite points.
- **Duplicate deaths**: `MJ-Respwan/core/client.lua:476` fires the same event as vorp_core
  does, so one death can arrive twice. A 1-second per-victim guard drops the repeat. The pair
  cooldown would mask it too, but relying on that alone makes a doubled event indistinguishable
  from a real kill that hit the cooldown.
- Same-city or unassigned-city kills: no-op, no error shown, no cooldown consumed.
- No penalty to the victim's city — only the killer's city gains.

## Rewards

- Only players **online at the moment the event ends** whose home city placed 1st/2nd/3rd
  receive anything — not every registered citizen of that city.
- True ties **split the reward for that rank**: e.g. two cities tied for 1st each get the
  1st-place money halved (integer division) and the full 1st-place item list each (items
  don't split into fractions meaningfully, so they're given whole to every tied city). If all
  three tie at 0-0-0, all three split the 1st-place pool and no 2nd/3rd is given (there's no
  city left to occupy those rank slots).
- Reward pools live in `server/config_server.lua` → `Config.Rewards.first/second/third`.
  These are guaranteed grants, not a random loot roll — winning shouldn't be gated on top of
  already winning.

## History — the GTA5 mix-up that made v1.0 do nothing

The first version detected deaths with `AddEventHandler('gameEventTriggered', ...)` watching
for `CEventNetworkEntityDamage`, and filtered weapons with `GetWeapontypeGroup` on the server.
Both are wrong here, and together they meant the resource never scored a single point:

- `gameEventTriggered` / `CEventNetworkEntityDamage` are **GTA5** game events. They don't fire
  on RDR3, so the client handler never ran and the server never received anything — no errors,
  no logs, nothing on either side.
- The two things that looked like proof it was fine were both GTA5 code:
  `[gameplay]/[examples]/ped-money-drops` declares `game 'gta5'`, and
  `[standalone]/PolyZone/EntityZone.lua` is unported dead weight from PolyZone's GTA5 original
  that nothing in this repo references.
- `GetWeapontypeGroup` is client-only. Called from a server script the global is `nil`, so
  `pcall` returned false and every kill would have been rejected as `weapon_not_allowed` even
  if a report had arrived. Every other call to it in this repo is in a `client/` file.

Worth remembering when adding anything else: check the `game` field in the fxmanifest of
whatever you're copying from, and check that the file you're citing is actually loaded and
referenced. Prefer `vorp_core` and `vorp_inventory` as the reference for what works here.

## Admin commands

- `/dmforcestart` — start the event immediately (also marks today as already-triggered, so
  the schedule won't double-fire later the same day).
- `/dmforceend` — end the event immediately and distribute rewards based on current scores.

Both require ACE `lp_deathmatch.admin` or VORP group in `Config.Security.adminGroups`.

## Test checklist

Setup once: at least 2 test characters assigned to *different* cities via `nx_cityselect`
(e.g. one Valentine, one Rhodes), `Config.Debug = true` while testing, ideally 3 characters
(one per city) to also exercise ties/3rd place.

**Start / schedule**
- [ ] `/dmforcestart` as admin (or non-admin group) → denied with `admin_denied`, no event starts.
- [ ] `/dmforcestart` as admin → scoreboard appears for **every online player**, all 3 cities at 0, countdown ticking down.
- [ ] `/dmforcestart` again while already running → `already_running`, no reset/duplicate scoreboard.
- [ ] Reconnect (or `/dmforceend` then restart resource) while an event is active → newly-joined client still sees the scoreboard with correct current scores/remaining time (late-join sync via `requestState`).

**Scoring — the core validation chain**
- [ ] Player A (city 1) kills player B (city 2) with an allowed weapon (gun/knife/dynamite), both on foot, close range → A's city score +1 within ~1s on **everyone's** scoreboard, A gets a "kill confirmed" pNotify, score number pulses green.
- [ ] Same kill, but A and B are in the **same city** → no score change, no notify, no error (silent no-op) — check server console (`Config.Debug`) for `reason=no_op`.
- [ ] A punches B to death bare-fisted → no score change (`reason=cause_denied`).
- [ ] A kills B with a knife → **does** count (confirms the denylist isn't swallowing melee wholesale).
- [ ] B dies by falling / drowning right after A shoots at them → no score change (`reason=cause_denied`).
- [ ] A kills B from a **wildly implausible distance** (e.g. via some desync/teleport) → rejected (`reason=too_far`) — hard to force naturally, but worth a sanity check if you have any teleport/noclip admin tool.
- [ ] A kills B, then **immediately** kills B again → 2nd kill does **not** score (`reason=pair_cooldown`); confirm B killing A right after *also* doesn't score (cooldown is per unordered pair, not per direction).
- [ ] Wait out `pairCooldownMinutes` (or lower it temporarily in config for testing) → same pair can score again.
- [ ] A player with **no city assigned** (never ran nx_cityselect) kills someone → no score, no crash.

**Death event actually arrives (check this first — v1.0 failed here)**
- [ ] With `Config.Debug` on, kill someone during an active event and confirm the server console prints `[lp_deathmatch] death victim=... killer=... cause=...`. If nothing prints at all, `vorp_core:Server:OnPlayerDeath` isn't reaching this resource and nothing downstream matters.
- [ ] Confirm the printed `cause` is a plausible weapon hash and that legitimate gun kills aren't landing on `reason=cause_denied`. If a real weapon is being denied, its hash collides with a name in `Config.DeniedDeathCauses` — remove that entry.
- [ ] Kill someone twice in quick succession and confirm only one `death` line prints per actual death (the `MJ-Respwan` duplicate-event guard).

**Event end / rewards**
- [ ] Let the countdown hit 0 (or `/dmforceend`) with a clear single winner → scoreboard freezes, results overlay shows correct ranking, only players from the **winning city who are online right now** get a reward + `reward_won` notify; a same-city player who logged off mid-event gets nothing.
- [ ] Force a **tie** for 1st (e.g. two cities both at the same score via repeated test kills) → both tied cities' online players get the reward, money amount is roughly halved for each, results overlay shows both city names on the `#1` row and correctly skips to `#3` for the remaining city (no `#2` row).
- [ ] Force a **0-0-0** three-way tie (force-start then immediately force-end with no kills) → all 3 split the 1st-place pool, no 2nd/3rd rows at all.
- [ ] Check `CanCarryItem`/inventory-full path: fill a winning player's inventory before event end → they get the money but not the item, no crash, check console for `inventory_full:<item>` log.

**Cleanup / edge cases**
- [ ] Disconnect a player mid-event → no server error, their rate-limit/city-cache state is cleared (`playerDropped`), rejoining mid-event still lets them score normally.
- [ ] Restart `lp_deathmatch` mid-event → all clients' scoreboards disappear cleanly (`aborted` end broadcast), no stuck NUI, no error spam in console; next day's schedule still fires normally afterward.
- [ ] `/dmforceend` when nothing is running → `not_running`, no error.
