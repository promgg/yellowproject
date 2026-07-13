-- server/sv_city.lua
-- City slot management: counting, availability, and cycle reset

local Core = exports.vorp_core:GetCore()
local Inv  = exports.nx_inventory

-- ─────────────────────────────────────────────────────────────
--  Internal: fetch all city slot counts from DB, cached until the
--  next write (CityManager_IncrementCity/ResetAllSlots invalidate
--  it) — the availability check always reads a value no staler
--  than the last actual write, so it's safe to cache.
-- ─────────────────────────────────────────────────────────────
local slotCountsCache = nil

local function InvalidateSlotCache()
    slotCountsCache = nil
end

local function FetchSlotCounts()
    if slotCountsCache then return slotCountsCache end

    local rows = MySQL.query.await(
        "SELECT city_id, current_count FROM nx_city_slots",
        {}
    )
    local counts = {}
    if rows then
        for _, row in ipairs(rows) do
            counts[row.city_id] = tonumber(row.current_count) or 0
        end
    end
    slotCountsCache = counts
    return counts
end

-- ─────────────────────────────────────────────────────────────
--  Internal: ensure all configured cities have a slot row
-- ─────────────────────────────────────────────────────────────
local function EnsureSlotRows()
    for _, city in ipairs(Config.Cities) do
        MySQL.query.await(
            "INSERT IGNORE INTO nx_city_slots (city_id, current_count) VALUES (?, 0)",
            { city.id }
        )
    end
end

-- ─────────────────────────────────────────────────────────────
--  Internal: reset all slot counts (new cycle)
-- ─────────────────────────────────────────────────────────────
local function ResetAllSlots()
    MySQL.query.await(
        "UPDATE nx_city_slots SET current_count = 0",
        {}
    )
    InvalidateSlotCache()
    if Config.Debug then
        print("^3[nx_cityselect]^7 All city slots reset — new registration cycle started.")
    end
end

-- ─────────────────────────────────────────────────────────────
--  Internal: check whether all cities are at max and reset
-- ─────────────────────────────────────────────────────────────
local function CheckAndResetIfAllFull(counts)
    local allFull = true
    for _, city in ipairs(Config.Cities) do
        local count = counts[city.id] or 0
        if count < Config.MaxPlayersPerCity then
            allFull = false
            break
        end
    end
    if allFull then
        ResetAllSlots()
        return true
    end
    return false
end

-- ─────────────────────────────────────────────────────────────
--  PUBLIC: Get city counts enriched with availability flag
--  Returns table: { cityId = { count, available } }
-- ─────────────────────────────────────────────────────────────
function CityManager_GetCounts()
    local counts = FetchSlotCounts()

    -- If all full, treat as reset (all available)
    local allFull = true
    for _, city in ipairs(Config.Cities) do
        if (counts[city.id] or 0) < Config.MaxPlayersPerCity then
            allFull = false
            break
        end
    end

    local result = {}
    for _, city in ipairs(Config.Cities) do
        local count = counts[city.id] or 0
        result[city.id] = {
            count     = count,
            available = allFull or (count < Config.MaxPlayersPerCity),
        }
    end
    return result
end

-- ─────────────────────────────────────────────────────────────
--  PUBLIC: Check if a specific city is still available
-- ─────────────────────────────────────────────────────────────
function CityManager_IsCityAvailable(cityId)
    local counts = CityManager_GetCounts()
    local entry  = counts[cityId]
    return entry and entry.available or false
end

-- ─────────────────────────────────────────────────────────────
--  PUBLIC: Increment city count and check for cycle reset
--  Returns true on success
-- ─────────────────────────────────────────────────────────────
function CityManager_IncrementCity(cityId)
    MySQL.query.await(
        "UPDATE nx_city_slots SET current_count = current_count + 1 WHERE city_id = ?",
        { cityId }
    )
    InvalidateSlotCache()
    local counts = FetchSlotCounts()
    CheckAndResetIfAllFull(counts)
    return true
end

-- ─────────────────────────────────────────────────────────────
--  PUBLIC: Get a player's assigned city record
--  Returns { city_id } or nil
-- ─────────────────────────────────────────────────────────────
function CityManager_GetPlayerCity(identifier, charidentifier)
    local rows = MySQL.query.await(
        "SELECT city_id FROM nx_player_city WHERE identifier = ? AND charidentifier = ? LIMIT 1",
        { identifier, tonumber(charidentifier) }
    )
    if rows and rows[1] then
        return rows[1].city_id
    end
    return nil
end

-- ─────────────────────────────────────────────────────────────
--  PUBLIC: Assign city to player (permanent record)
--  Returns true only if THIS call actually inserted the row (won
--  the race) — the PRIMARY KEY + INSERT IGNORE + affected-rows
--  check together are the atomic compare-and-set: a concurrent
--  double-fire for the same character can only ever have one
--  winner, so callers must gate slot-increment/badge-give on this.
-- ─────────────────────────────────────────────────────────────
function CityManager_AssignCity(identifier, charidentifier, cityId)
    local affected = MySQL.update.await(
        "INSERT IGNORE INTO nx_player_city (identifier, charidentifier, city_id) VALUES (?, ?, ?)",
        { identifier, tonumber(charidentifier), cityId }
    )
    return (affected or 0) > 0
end

-- ─────────────────────────────────────────────────────────────
--  Init: ensure rows exist on resource start
-- ─────────────────────────────────────────────────────────────
AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    EnsureSlotRows()
    if Config.Debug then
        print("^2[nx_cityselect]^7 City slot rows verified.")
    end
end)
