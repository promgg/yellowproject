local RESOURCE = GetCurrentResourceName()
local FILE_PATH = "config/horse_tuning.json"

-- model name -> { health=, stamina=, specialability=, courage=, agility=, speed=, acceleration=, bonding= }
local Cache = {}

local function LoadCache()
    local raw = LoadResourceFile(RESOURCE, FILE_PATH)
    if raw then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == "table" then
            Cache = decoded
            return
        end
        print(("[HorsePreview] Failed to parse %s, starting with an empty tuning cache"):format(FILE_PATH))
    end
    Cache = {}
end

LoadCache()

RegisterNetEvent("vorp_horsepreview:requestTuning", function()
    TriggerClientEvent("vorp_horsepreview:receiveTuning", source, Cache)
end)

RegisterNetEvent("vorp_horsepreview:saveTuning", function(model, values)
    if type(model) ~= "string" or model == "" or type(values) ~= "table" then
        return
    end

    Cache[model] = values
    SaveResourceFile(RESOURCE, FILE_PATH, json.encode(Cache, { indent = true }), -1)
    print(("[HorsePreview] Saved tuning for %s"):format(model))
end)
