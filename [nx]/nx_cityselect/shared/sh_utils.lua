-- shared/sh_utils.lua
-- Utilities available to both client and server

-- Build fast lookup table from Config
for _, city in ipairs(Config.Cities) do
    Config.CitiesById[city.id] = city
end

---Returns city config by id or nil
---@param cityId string
---@return table|nil
function GetCityById(cityId)
    return Config.CitiesById[cityId]
end

---Sanitize a string: strip non-alphanumeric/underscore chars
---@param s string
---@return string
function SanitizeCityId(s)
    if type(s) ~= "string" then return "" end
    return s:match("^[%w_]+$") and s or ""
end

---Deep-copy a table (shallow for nested tables not needed here)
---@param orig table
---@return table
function TableCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = v
    end
    return copy
end
