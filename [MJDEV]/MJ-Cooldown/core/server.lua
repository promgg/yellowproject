local script = 'MJ-Cooldown'
DEAD = {}
VORPcore = {} -- core object

TriggerEvent("getCore", function(core)
    VORPcore = core
end)

AddEventHandler("vorp:SelectedCharacter", function(source)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    if DEAD[Character.identifier] then
        TriggerClientEvent(script .. "GetData", _source, true)
    else
        TriggerClientEvent(script .. "GetData", _source, false)
    end
end)

RegisterNetEvent(script .. "SaveData")
AddEventHandler(script .. "SaveData", function(isDead)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    if DEAD[Character.identifier] ~= nil then
        DEAD[Character.identifier] = 0
    end
    if isDead then
        DEAD[Character.identifier] = true
        if Config['ChangeClothes'] then
            TriggerClientEvent(script .. "GetCloth", _source, json.decode(Character.comps))
        end
    else
        DEAD[Character.identifier] = false
        if Config['ChangeClothes'] then
            TriggerClientEvent(script .. "GetCloth", _source, json.decode(Character.comps))
        end
    end
end)


if GetCurrentResourceName() ~= script then
    os.exit()
end