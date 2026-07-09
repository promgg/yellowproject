# nx_crafting Multi Recipe Fix Report

## Problem

The NUI top `RECIPE` row was rendering category/item data again. That duplicated the category tabs and did not represent crafting methods for the currently selected item.

## Root Cause

The old frontend state used a flat category recipe/item list. The top row read entries from the selected category instead of reading `selectedItem.recipe` or `selectedItem.recipes`.

## Config Structure Changes

All entries in `config_sv.lua` now use the explicit hierarchy:

`Category -> ItemEntry -> recipe[] -> RecipeEntry`.

Every previous single-recipe item in medicine, food, clothing card, mining, building materials, and tribe categories was moved into `recipe[1]`.

`WEAPON_REVOLVER_NAVY` demonstrates multiple recipes and recipe-specific fields:

- `cost`
- `blueprint`
- `toolsList`
- `failedList`
- `variantCards`
- `fail_chance`
- `success_rate`
- `max_stack`
- commented examples for `jobList`, `allowedJob`, `metadata`, `requiredLevel`, `exp`, `craftTime`, and `animation`

## Backward Compatibility Handling

Server and client normalization still convert old item-level recipe fields into `recipe[1]`. Unknown root fields that are not item metadata are moved into the first recipe so old custom config fields are preserved if another old-format item is added later.

## UI Behavior Changes

Category tabs switch categories only. The left sidebar renders items in the selected category. The top `RECIPE` row renders only recipes for the selected item.

Selecting an item resets recipe selection to the first recipe. Selecting a recipe updates materials, tools, failed returns, success/fail display, preview, and amount constraints.

## NUI Payload Changes

Craft requests now send only identity plus amount:

```json
{
  "categoryIndex": 1,
  "itemIndex": 1,
  "recipeIndex": 2,
  "amount": 1
}
```

The NUI no longer sends trusted blueprint, cost, success rate, fail chance, max stack, tools, rewards, or job restrictions for crafting.

## Client Lua Changes

Client Lua builds item payloads with nested `recipes`. It tracks `category`, `selectedItemIndex`, and `selectedRecipeIndex`, and passes those indexes to the server after local preview checks.

## Server Lua Changes

Server Lua normalizes config on startup, looks up recipes by `categoryIndex`, `itemIndex`, and `recipeIndex`, and validates the selected recipe from `ConfigSv["Category"]`.

Validation covers category/item/recipe existence, crafting table access, recipe job restrictions, tools, blueprint materials, cost, amount, max stack, and pending craft identity.

## Files Changed

- `config_sv.lua`
- `client/client.lua`
- `server/server.lua`
- `html/app.js`
- `html/style.css`
- `.codex/reports/nx-crafting-multi-recipe-fix-report.md`

## How To Configure Multiple Recipes

```lua
{
    item = "WEAPON_REVOLVER_NAVY",
    label = "Navy Revolver",
    type = "item_weapon",
    recipe = {
        [1] = {
            label = "Cheap Recipe",
            description = "Uses fewer materials but has a higher fail chance",
            fail_chance = 20,
            success_rate = 80,
            max_stack = 2,
            cost = { ["Money"] = 50 },
            blueprint = { ["iron"] = 10, ["wood"] = 4, ["mechanism"] = 1 },

            -- Required tools/items that must be present but are not consumed.
            toolsList = { ["hammer"] = 1 },

            -- Items that can be returned when crafting fails.
            failedList = { ["iron"] = 2 },

            variantCards = {
                [1] = { label = "Cheap" }
            },

            -- Optional recipe-only fields:
            -- jobList = { ["gunsmith"] = true },
            -- allowedJob = "gunsmith",
            -- metadata = {},
            -- requiredLevel = 1,
            -- exp = 10,
            -- craftTime = 5000,
            -- animation = {},
        },
        [2] = {
            label = "Standard Recipe",
            description = "Uses more materials with a better success rate",
            fail_chance = 10,
            success_rate = 90,
            max_stack = 2,
            cost = { ["Money"] = 100 },
            blueprint = { ["iron"] = 20, ["wood"] = 8, ["mechanism"] = 2 },
            toolsList = { ["hammer"] = 1, ["weapon_blueprint"] = 1 },
            failedList = { ["iron"] = 4, ["mechanism"] = 1 },
        },
    }
}
```

Single-recipe items should use the same shape:

```lua
{
    item = "bread",
    type = "item_standard",
    recipe = {
        [1] = {
            label = "Main Recipe",
            fail_chance = 0,
            success_rate = 100,
            max_stack = 10,
            cost = { ["Money"] = 0 },
            blueprint = { ["corn"] = 5 },
        },
    },
}
```

## How To Test

1. Open category `อาวุธ`.
2. Select `WEAPON_REVOLVER_NAVY`.
3. Confirm the top row shows only the Navy Revolver recipes.
4. Select recipe 1 and confirm Money 50, iron 10, wood 4, mechanism 1.
5. Select recipe 2 and confirm Money 100, iron 20, wood 8, mechanism 2.
6. Craft recipe 2 and confirm the server receives `recipeIndex = 2`.
7. Select `WEAPON_REVOLVER_SCHOFIELD` and confirm one recipe appears.
8. Select `ยา` or `อาหาร` and confirm each item has one `recipe[1]` card with its materials.
9. Temporarily add an old-format item without `recipe`; confirm it appears as `recipe[1]`.

## Remaining Risks

No live RedM server runtime was available in this shell, so validation was done by code review and static searches. The server validates money, gold, and rol using VORP currency indexes; any custom non-currency `cost` key is treated as an inventory item cost.
