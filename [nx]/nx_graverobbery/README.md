# nx_graverobbery

Server-authoritative grave robbery for VORP RedM with village-scoped alerts from `nx_cityselect`.

## Dependencies

- `vorp_core` 3.3 found in this project.
- `vorp_inventory` 4.1 found in this project.
- `oxmysql` found in `[standalone]`.
- `nx_cityselect` found in `[nx]`.
- `lp_textui` found in `[LP]` — floating hold-to-interact prompt (replaced `ox_target`).
- `lp_minigame` found in `[LP]` — circle skill-check for the dig sequence (replaced ox_lib's `lib.skillCheck`).
- `lp_progbar` found in `[LP]` — progress bar for digging/praying (replaced ox_lib's `lib.progressBar`).

## Installation

1. Place this folder at `resources/[nx]/nx_graverobbery`.
2. Import `sql/nx_graverobbery.sql`.
3. Ensure dependencies start before this resource.
4. Add `ensure nx_graverobbery` after the dependencies.
5. Configure graves, rewards, and alert recipients in `config.lua`.

## nx_cityselect Integration

Inspected files:

- `[nx]/nx_cityselect/server/sv_exports.lua`
- `[nx]/nx_cityselect/server/sv_city.lua`
- `[nx]/nx_cityselect/config.lua`

Found API:

- `exports.nx_cityselect:GetPlayerCity(source)`
- `exports.nx_cityselect:GetPlayerCityId(source)`
- `exports.nx_cityselect:GetAllCities()`
- `exports.nx_cityselect:GetCityCounts()`

Storage:

- Player village is stored in database table `nx_player_city`.
- Key fields are `identifier`, `charidentifier`, and `city_id`.

Roles:

- No dedicated village role table or export was found.
- `recipientMode = 'village_roles'` maps to VORP character `group`.
- `recipientMode = 'jobs'` maps to VORP character `job`.
- `recipientMode = 'all_village_members'` sends to online players in the grave owner's village.
- `recipientMode = 'custom'` uses `Config.CustomAlertRecipients(context)`.

Alerts always use the grave's `villageId`, not the robber's village.

## VORP Integration

Used APIs:

- `exports.vorp_core:GetCore()`
- `Core.getUser(source).getUsedCharacter`
- `exports.vorp_inventory:getItemCount(source, nil, item)` (callback is the 2nd param on this one export — pass nil for sync mode)
- `exports.vorp_inventory:canCarryItem(source, item, amount)`
- `exports.vorp_inventory:addItem(source, item, amount, metadata)`
- `exports.vorp_inventory:subItem(source, item, amount)`
- `character.addCurrency(currency, amount)`

Currency IDs follow this VORP version:

- `0` money
- `1` gold
- `2` rol

## Config

Add villages in `Config.Villages`. Add graves in `Config.Graves`; each grave needs:

- unique `id`
- valid `villageId`
- server-side `coords`
- cooldown
- required item
- valid `rewardPool`

Interaction is a floating `lp_textui` hold prompt (`Config.Interaction.holdMs`), not a zone/target system —
`grave.interaction.distance` is the trigger range. Dig takes priority when the grave is available; the prompt
falls back to pray otherwise. The `target` field on each grave entry is unused now (kept for reference/future use).

## Rewards

Rewards are rolled only on the server in `server/rewards.lua`.

Add items under `Config.RewardPools[poolName].items` in `server/config_server.lua` (server-only — not shipped to clients, unlike `config.lua`):

```lua
{ name = 'silver_ring', min = 1, max = 1, weight = 10 }
```

The server checks carry capacity before adding items. If inventory is full, no duplicate reward is created.

## Cooldowns

Cooldowns are cached in memory and persisted to `nx_graverobbery_graves`.

Restarting the resource keeps active cooldowns. Admin reset commands delete/update only this resource's cooldown table and do not touch `nx_cityselect`.

## Admin Commands

Permission uses ACE `nx_graverobbery.admin` or VORP user groups in `Config.Security.adminGroups`.

- `/gravecheck`
- `/graveinfo <graveId>`
- `/gravereset <graveId>`
- `/graveresetvillage <villageId>`
- `/graveresetall`

## Security Design

- Client can request start only by `graveId`.
- Client can complete only by one-time session token.
- Server owns coordinates, village id, reward pool, item requirements, cooldown, and alert recipients.
- Server validates distance at start and completion.
- Server reserves a grave before sending animation to client.
- Session token is bound to source, character id, grave id, and expiry time.
- Complete is single-use and enforces minimum duration.
- Cooldown is committed before reward delivery.
- Rate limits are applied per event.
- Alerts are emitted only from server-side grave ownership.

## Limitations

- This was not tested inside a live RedM server.
- `damageDurability` is present in config but not implemented because this VORP inventory version does not expose a clear shovel durability contract.
- `Config.AllowedTime.enabled` defaults to `false`; server-side clock native availability must be verified before enabling.
- Village roles depend on VORP character group unless you provide a custom resolver.
- Northern grave anchor coordinates are still the original placeholders (Valentine/Annesburg/Rhodes); the 10-hole
  scatter (`spreadRadius = 8.0`) uses the same Z as the anchor for every hole and hasn't been ground-checked in-game.
- Southern cluster anchors are real player-supplied coordinates but the 10-hole scatter (`spreadRadius = 12.0`)
  likewise reuses the anchor's Z for all holes — verify no hole floats/clips before going live.
- `Config.Villages.<village>.schedule` (northern only) is real-clock-based (server local time), not synced to
  in-game/RP time; verify server timezone matches expectations.

## Troubleshooting

- If no floating `[E]` prompt appears, verify `lp_textui` started before this resource.
- If digging is rejected with "not open yet" outside expected hours, check the server's local clock/timezone against `Config.Villages.<id>.schedule`.
- If alerts reach nobody, verify player `job`, `group`, and village membership.
- If nobody receives city data, verify `nx_player_city` has rows for the character.
- If rewards fail, verify item names exist in the VORP `items` table.

## In-Game Test Checklist

Prompt (lp_textui):

- Floating `[E]` prompt appears only near configured graves, within `interaction.distance`.
- Disabled graves show no prompt.
- Prompt shows dig when the grave is available, falls back to pray otherwise.
- Unconfigured global gravestones cannot be robbed.

Schedule (northern only):

- Before a village's `openHour`, digging is rejected with the "not open yet" message even on a fresh/never-dug hole.
- At/after `openHour`, previously-undug holes become diggable.
- A hole dug today stays closed until the same `openHour` tomorrow (not a short cooldown).
- Southern holes are unaffected by any schedule and only gate on their own 90-minute cooldown.

Digging:

- Player without shovel cannot start.
- Player with shovel can start.
- Cancel gives no reward.
- Death gives no reward.
- Walking away gives no reward.
- Successful completion gives a server-rolled reward.
- Same grave cannot be robbed again during cooldown.

Multiplayer:

- Two players cannot dig the same grave at the same time.
- If first player cancels, the grave becomes available.
- Disconnect releases reservation.

Village Alert:

- Robbing Valentine alerts Valentine recipients only.
- Robbing Annesburg alerts Annesburg recipients only.
- Robbing Rhodes alerts Rhodes recipients only.
- Robber from another village still alerts the grave owner village.
- Players without configured job/group do not receive alerts.
- Alert blip disappears after configured duration.
- Client cannot spam alert directly.

Persistence:

- Restart resource and verify cooldown remains.
- Restart server and verify cooldown remains.
- After cooldown expires, grave can be robbed again.

## Automated Tests

Run from this resource folder:

```powershell
lua tests\run_tests.lua
```

Latest local result:

```text
Passed: 26
Failed: 0
```
