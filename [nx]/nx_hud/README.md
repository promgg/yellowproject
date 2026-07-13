# nx_hud

RedM/VORP HUD based on the supplied Hud.zip layout. It includes player health,
stamina, status cores, voice state, mounted-horse status, and a circular custom
tile radar in one NUI resource.

## Radar modes

The default is configured at `Config.RadarMap.Mode`:

- `always` - show while the HUD is visible
- `horse` - show only while mounted
- `off` - hide the map

Players can switch and persist their own preference:

```text
/radarmap always
/radarmap horse
/radarmap off
```

Client API:

```lua
TriggerEvent('nx_hud:client:setRadarMode', 'horse')
exports['nx_hud']:setRadarMode('always')
local mode = exports['nx_hud']:getRadarMode()
```

Existing HUD events and exports remain available.

## Pixel-perfect layout

The layout uses the supplied 1920x1080 design as its 1:1 coordinate system.
At other game resolutions the entire HUD, including its gaps and offsets, is
scaled uniformly from the bottom-left anchor. `Config.Layout.Scale` remains an
optional user multiplier on top of that automatic resolution scale.

## Test/reload

```text
stop lp_minimapbox
ensure nx_minimap
ensure nx_hud
```

`lp_minimapbox` and `nx_minimap` are disabled in their configs because their
responsibilities are now handled inside this resource.

The custom tile radar does not automatically inherit Rockstar GPS routes,
native blips, danger arcs, or indoor floor-plan layers.
