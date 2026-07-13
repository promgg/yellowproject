-- shared/sh_utils.lua
-- Utilities available to both client and server

-- Build fast lookup table from Config
for _, city in ipairs(Config.Cities) do
    Config.CitiesById[city.id] = city
end

for _, heritage in ipairs(Config.Heritages) do
    Config.HeritagesById[heritage.id] = heritage
end

---Returns city config by id or nil
---@param cityId string
---@return table|nil
function GetCityById(cityId)
    return Config.CitiesById[cityId]
end

---Returns heritage config by id or nil
---@param heritageId string
---@return table|nil
function GetHeritageById(heritageId)
    return Config.HeritagesById[heritageId]
end

---Sanitize a string: strip non-alphanumeric/underscore chars
---@param s string
---@return string
function SanitizeId(s)
    if type(s) ~= "string" then return "" end
    return s:match("^[%w_]+$") and s or ""
end

---Sanitize a string: strip non-alphanumeric/underscore chars
---@param s string
---@return string
function SanitizeCityId(s)
    return SanitizeId(s)
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
