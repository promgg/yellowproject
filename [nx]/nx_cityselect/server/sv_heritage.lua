-- server/sv_heritage.lua
-- Heritage (crafting-lineage) assignment: permanent, one per character

function HeritageManager_GetPlayerHeritage(identifier, charidentifier)
    local rows = MySQL.query.await(
        "SELECT heritage_id FROM nx_player_heritage WHERE identifier = ? AND charidentifier = ? LIMIT 1",
        { identifier, tonumber(charidentifier) }
    )
    if rows and rows[1] then
        return rows[1].heritage_id
    end
    return nil
end

-- Returns true only if THIS call actually inserted the row (won the race) —
-- same atomic compare-and-set reasoning as CityManager_AssignCity.
function HeritageManager_AssignHeritage(identifier, charidentifier, heritageId)
    local affected = MySQL.update.await(
        "INSERT IGNORE INTO nx_player_heritage (identifier, charidentifier, heritage_id) VALUES (?, ?, ?)",
        { identifier, tonumber(charidentifier), heritageId }
    )
    return (affected or 0) > 0
end
