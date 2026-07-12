# nx_graverobbery

Server-authoritative grave robbery for VORP RedM with village-scoped alerts from `nx_cityselect`.

## Dependencies

- `vorp_core` 3.3 found in this project.
- `vorp_inventory` 4.1 found in this project.
- `oxmysql` found in `[standalone]`.
- `ox_lib` 3.33.1 found in `[standalone]`.
- `nx_cityselect` found in `[nx]`.
- `ox_target` is required by `fxmanifest.lua`, but was not found in this resource tree during implementation.

Install a RedM-compatible `ox_target` before starting this resource.

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
- `exports.vorp_inventory:getItemCount(source, item)`
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

Target modes:

- `target = { type = 'sphere' }`
- `target = { type = 'box', size = vec3(...), rotation = ... }`
- `target = { type = 'model', models = { ... }, modelRadius = 4.0 }`

The default is location-based sphere targets. It does not register every gravestone model globally.

## Rewards

Rewards are rolled only on the server in `server/rewards.lua`.

Add items under `Config.RewardPools[poolName].items`:

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
- `ox_target` was not present in the project, so target registration needs in-game verification after installing it.
- `damageDurability` is present in config but not implemented because this VORP inventory version does not expose a clear shovel durability contract.
- `Config.AllowedTime.enabled` defaults to `false`; server-side clock native availability must be verified before enabling.
- Village roles depend on VORP character group unless you provide a custom resolver.

## Troubleshooting

- If the resource will not start, install/start `ox_target` first.
- If no targets appear, verify `ox_target` API compatibility for RedM.
- If alerts reach nobody, verify player `job`, `group`, and village membership.
- If nobody receives city data, verify `nx_player_city` has rows for the character.
- If rewards fail, verify item names exist in the VORP `items` table.

## In-Game Test Checklist

Target:

- Target appears only on configured graves.
- Disabled graves do not show target.
- Unconfigured global gravestones cannot be robbed.

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
