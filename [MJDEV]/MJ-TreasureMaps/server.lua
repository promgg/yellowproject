data = {}
local RSGCore 
local RSGItems
local VorpCore
local VorpInv
local QBRItems
local id = 0
if Config.framework == "redemrp" then
    TriggerEvent("redemrp_inventory:getData",function(call)
        data = call
    end)
elseif Config.framework == "vorp" then
    TriggerEvent("getCore",function(core)
        VorpCore = core
    end)
    VorpInv = exports.vorp_inventory:vorp_inventoryApi()
elseif Config.framework == "rsg" then 
    RSGCore = exports['rsg-core']:GetCoreObject()
    RSGItems = exports['rsg-core']:GetCoreObject()
end

local TEXTS = Config.Texts
local TEXTURES = Config.Textures
local DiggedTreasures = {}
local previousIDs = {}

VorpInv.RegisterUsableItem(Config.MapItem, function(data)
    local id
    repeat
        id = math.random(1, #Config.treasures)
    until not previousIDs[id] 
    previousIDs[id] = true
    if Config.treasures[id] then
        VorpInv.subItem(data.source, Config.MapItem, 1)
        TriggerClientEvent('MJ-TreasureMaps:Showblip', data.source, id)
        TriggerClientEvent("vorp_inventory:CloseInv", data.source)
    else
        TriggerClientEvent("Notification:left_Treasure_robbery", data.source, TEXTS.TreasureRobbery, TEXTS.TreasureRobbed, 'The map is complete.', nil, 2000)   
    end
end)


RegisterServerEvent("MJ-TreasureMaps:check_shovel")
AddEventHandler("MJ-TreasureMaps:check_shovel", function(id)
    local _source = source
    if DiggedTreasures[id] == true then 
        TriggerClientEvent("Notification:left_Treasure_robbery", _source, TEXTS.TreasureRobbery, TEXTS.TreasureRobbed, TEXTURES.alert[1], TEXTURES.alert[2], 2000)
        return 
    end
    local count = 0
    if Config.framework == "redemrp" then
        local itemD = data.getItem(_source, Config.ShovelItem)
        if itemD and itemD.ItemAmount > 0 then 
            count = itemD.ItemAmount
        end
    elseif Config.framework == "vorp" then
        count = VorpInv.getItemCount(_source, Config.ShovelItem)
    elseif Config.framework == "rsg" then 
        local Player = RSGCore.Functions.GetPlayer(_source)
        local hasItem = Player.Functions.GetItemByName(Config.ShovelItem)
        if hasItem and hasItem.amount > 0 then 
            count = hasItem.amount
        end
    end
    if count and count > 0 then
        TriggerClientEvent("MJ-TreasureMaps:start_dig", _source, id)
    else
        TriggerClientEvent("Notification:left_Treasure_robbery", _source, TEXTS.TreasureRobbery, TEXTS.NoShovel, TEXTURES.alert[1], TEXTURES.alert[2], 2000)
    end
end)

RegisterServerEvent("MJ-TreasureMaps:reward")
AddEventHandler("MJ-TreasureMaps:reward", function(id)
    local _source = source
    -- Citizen.Wait(math.random(200,800))
    if DiggedTreasures[id] == true then 
        TriggerClientEvent("Notification:left_Treasure_robbery", _source, TEXTS.TreasureRobbery, TEXTS.TreasureRobbed, TEXTURES.alert[1], TEXTURES.alert[2], 2000)
        return 
    end
    DiggedTreasures[id] = true 
    local itemnr = math.random(1, #Config.Rewards)
    local item = Config.Rewards[itemnr].item
    local count = Config.Rewards[itemnr].count
    print(item)
    print(count)
    if Config.framework == "redemrp" then
        local itemD = data.getItem(_source, item)
        itemD.AddItem(count)
    elseif Config.framework == "vorp" then
        VorpInv.addItem(_source, item, count)
    elseif Config.framework == "rsg" then
        local Player = RSGCore.Functions.GetPlayer(_source)
        Player.Functions.AddItem(item, count)
    end
    TriggerClientEvent('MJ-TreasureMaps:cancel_dig', _source)
    TriggerClientEvent("Notification:left_Treasure_robbery", _source, TEXTS.TreasureRobbery, TEXTS.FoundItem.."\n+ "..item, TEXTURES.alert[1], TEXTURES.alert[2], 2000)
end)
