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

- **Valid kill methods**: firearms, melee, explosives — checked via `GetWeapontypeGroup`
  against `Config.Weapons.allowedGroups`, with `WEAPON_UNARMED` explicitly denied (fists are
  in the same native group as knives in this engine, so a plain allowlist can't exclude them
  alone). Vehicle-ramming isn't in any allowed group, so it's excluded by omission rather than
  a special case.
- **Reporting**: the *victim's* client detects its own death via `gameEventTriggered` /
  `CEventNetworkEntityDamage` and reports the killer's server id + weapon hash. The server
  still verifies everything — killer must be a currently-connected player, distance between
  the two must be plausible (`Config.Security.maxKillDistance`), weapon must be allowed, and
  a per-pair cooldown (`Config.Security.pairCooldownMinutes`, default 10) blocks two players
  from trading kills back and forth for infinite points.
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

## Known uncertainty — please verify in-game

`CEventNetworkEntityDamage`'s argument layout isn't officially documented by Rockstar/CFX.
`args[1]`=victim, `args[2]`=culprit, `args[4]`=isDead are confirmed against this project's
own `[gameplay]/[examples]/ped-money-drops/client.lua`. The weapon hash at `args[6]`
(`client/main.lua`) is a common convention **but has not been verified against this specific
RDR3 build**. Turn on `Config.Debug` and check the printed `args` array in-game; if points
aren't landing (or the wrong weapons are/aren't counting), adjust that index.

Similarly, `Config.Weapons.allowedGroups` in `server/config_server.lua` uses `GROUP_MELEE`,
`GROUP_PISTOL`, `GROUP_RIFLE`, `GROUP_SHOTGUN`, `GROUP_SNIPER`, `GROUP_THROWN`, `GROUP_HEAVY`
by name-hash convention — also not live-tested. If a valid weapon isn't scoring, log the
`weapon_not_allowed` security line (has the raw weapon hash) and add its group.

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
- [ ] A kills B by **running B over with a vehicle** → no score change (`reason=weapon_not_allowed` or the weapon check simply doesn't match an allowed group — check console).
- [ ] A punches B to death bare-fisted → no score change (`WEAPON_UNARMED` explicitly denied even though it may share `GROUP_MELEE` with knives).
- [ ] A kills B with a knife → **does** count (confirms melee-minus-unarmed distinction actually works, not just theoretical).
- [ ] A kills B from a **wildly implausible distance** (e.g. via some desync/teleport) → rejected (`reason=too_far`) — hard to force naturally, but worth a sanity check if you have any teleport/noclip admin tool.
- [ ] A kills B, then **immediately** kills B again → 2nd kill does **not** score (`reason=pair_cooldown`); confirm B killing A right after *also* doesn't score (cooldown is per unordered pair, not per direction).
- [ ] Wait out `pairCooldownMinutes` (or lower it temporarily in config for testing) → same pair can score again.
- [ ] A player with **no city assigned** (never ran nx_cityselect) kills someone → no score, no crash.

**Weapon-hash sanity (the flagged uncertainty)**
- [ ] With `Config.Debug` on, check the client console (F8) after a death for the printed `args` array — confirm `args[4]` is really 1/0 for isDead in your build, and that `args[6]` looks like a plausible weapon hash (not nil, not victim/culprit's own ped handle repeated).
- [ ] Confirm server console's `weapon_not_allowed` log (if any legit gun/knife kill gets rejected) shows the raw hash — cross-check against `GetWeapontypeGroup` expectations and adjust `Config.Weapons.allowedGroups` if needed.

**Event end / rewards**
- [ ] Let the countdown hit 0 (or `/dmforceend`) with a clear single winner → scoreboard freezes, results overlay shows correct ranking, only players from the **winning city who are online right now** get a reward + `reward_won` notify; a same-city player who logged off mid-event gets nothing.
- [ ] Force a **tie** for 1st (e.g. two cities both at the same score via repeated test kills) → both tied cities' online players get the reward, money amount is roughly halved for each, results overlay shows both city names on the `#1` row and correctly skips to `#3` for the remaining city (no `#2` row).
- [ ] Force a **0-0-0** three-way tie (force-start then immediately force-end with no kills) → all 3 split the 1st-place pool, no 2nd/3rd rows at all.
- [ ] Check `CanCarryItem`/inventory-full path: fill a winning player's inventory before event end → they get the money but not the item, no crash, check console for `inventory_full:<item>` log.

**Cleanup / edge cases**
- [ ] Disconnect a player mid-event → no server error, their rate-limit/city-cache state is cleared (`playerDropped`), rejoining mid-event still lets them score normally.
- [ ] Restart `lp_deathmatch` mid-event → all clients' scoreboards disappear cleanly (`aborted` end broadcast), no stuck NUI, no error spam in console; next day's schedule still fires normally afterward.
- [ ] `/dmforceend` when nothing is running → `not_running`, no error.
