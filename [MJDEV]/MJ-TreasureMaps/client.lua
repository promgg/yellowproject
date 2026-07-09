
local TEXTS = Config.Texts
local TEXTURES = Config.Textures

local pcoords = nil 
local isdead = nil

local praying = false
local digging = false

local shovelObject = nil

local BlipEntities

local PromptKey 
local PromptGroup = GetRandomIntInRange(0, 0xffffff)
local Bandits = {}
local prompts = {}
local DiggedTreasures = {}
local lockedProps = {} 
local MapObject = nil
local blip_id = nil
local newBlip = nil
local Id_blips = {}
local created_blips = {}

function TableNum(tbl) 
    local c = 0
    for i,v in pairs(tbl) do 
        c = c + 1
    end
    return c
end

function LoadPrompts()
    local str = TEXTS.Prompt
    PromptKey = PromptRegisterBegin()
    PromptSetControlAction(PromptKey, Config.Keys.Prompt)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(PromptKey, str)
    PromptSetEnabled(PromptKey, 1)
    PromptSetVisible(PromptKey, 1)
	PromptSetStandardMode(PromptKey,1)
	PromptSetGroup(PromptKey, PromptGroup)
	Citizen.InvokeNative(0xC5F428EE08FA7F2C,PromptKey,true)
	PromptRegisterEnd(PromptKey)
    prompts[#prompts+1] = PromptKey
end

Citizen.CreateThread(function()
    LoadPrompts()
    while true do 
        Citizen.Wait(500)
        pcoords = GetEntityCoords(PlayerPedId())
        isdead = IsEntityDead(PlayerPedId())
    end
end)

RegisterNetEvent("MJ-TreasureMaps:Showblip")
AddEventHandler("MJ-TreasureMaps:Showblip", function(id)
    if MapObject then
        DeleteObject(MapObject)
        SetEntityAsNoLongerNeeded(MapObject)
        MapObject = nil
    end
    local ped = PlayerPedId()
    local pc = GetEntityCoords(ped)
    local model = Config.Maps.map
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    MapObject = CreateObject(model, pc.x, pc.y, pc.z, true, true, true)
    local boneIndex = GetEntityBoneIndexByName(ped, Config.Maps.bone)
    local Attach = Config.Maps.pos
    local anim = Config.Maps.anim
    RequestAnimDict(anim[1])
    while not HasAnimDictLoaded(anim[1]) do 
        Wait(10)
    end
    SetCurrentPedWeapon(ped, 'WEAPON_UNARMED', true)
    TaskPlayAnim(ped, anim[1], anim[2], 1.0, 1.0, -1, 17, 0, false, false, false)
    AttachEnt(MapObject, ped, boneIndex, Attach[1], Attach[2], Attach[3], Attach[4], Attach[5], Attach[6], 0, 1, 1, 1)
    PlaySoundFrontend("CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true, 1)
    Citizen.Wait(3000)
    RemoveAnimDict(anim[1])
    StopAnimTask(ped, anim[1], anim[2], 1.0)
    ClearPedTasks(ped)
    DeleteObject(MapObject)
    SetEntityAsNoLongerNeeded(MapObject)

    local blip_hash = GetHashKey("BLIP_GOLD")
    local blip_modifier_hash = GetHashKey("BLIP_MODIFIER_MP_COLOR_2")
    blip_id = Citizen.InvokeNative(0x554D9D53F696D002, GetHashKey(Config.BlipTreasure.Blips),  Config.treasures[id].coords.x, Config.treasures[id].coords.y, Config.treasures[id].coords.z)
    -- BlipAddForRadius(693035517, Config.treasures[id].coords.x, Config.treasures[id].coords.y, Config.treasures[id].coords.z, 100.0) --693035517
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip_id, blip_modifier_hash)
    SetBlipSprite(blip_id, blip_hash, 0)
    SetBlipScale(blip_id, Config.BlipTreasure.blipScale)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip_id, Config.BlipTreasure.blipName)
    Id_blips[id] = true   -- table for removing blips if needed
    created_blips[blip_id] = true
end)


local function DrawTexture(textureStreamed,textureName,x, y, width, height,rotation,r, g, b, a, p11)
    if not HasStreamedTextureDictLoaded(textureStreamed) then
       RequestStreamedTextureDict(textureStreamed, false);
    else
        DrawSprite(textureStreamed, textureName, x, y, width, height, rotation, r, g, b, a, p11);
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(3000)
        for key, v in pairs(Bandits) do
            if v.Ped and IsEntityDead(v.Ped) then
                DeleteEntity(v.Ped)
                Citizen.Wait(3000)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        local t = 5 
        if pcoords and (isdead ~= nil and isdead == false) then 
            for i,v in pairs(Config.treasures) do 
                local dist = #(pcoords-v.coords)

                if dist < 5.0 and not digging then
                    DrawTexticon(v.coords.x, v.coords.y, v.coords.z -0.5, Config.Normal)
                    DrawText3D(v.coords.x, v.coords.y, v.coords.z, Config.Keys.DrawText3D)
                end
                if dist < 1.5 and not digging then 
                    local label  = CreateVarString(10, 'LITERAL_STRING', TEXTS.TreasureDisplay.." "..v.name)
                    PromptSetActiveGroupThisFrame(PromptGroup, label)
                    if Citizen.InvokeNative(0xC92AC953F0A982AE, PromptKey) then
                        TriggerEvent("MJ-TreasureMaps:dig", i)
                        Citizen.Wait(1000)
                    end
                end
            end
        else
            t = 1500
        end
        Citizen.Wait(t)
    end
end)


function Drawtext(str, x, y, w, h, enableShadow, col1, col2, col3, a, centre)
	local str = CreateVarString(10, "LITERAL_STRING", str, Citizen.ResultAsLong())
	SetTextScale(w, h)
	SetTextColor(math.floor(col1), math.floor(col2), math.floor(col3), math.floor(a))
	SetTextCentre(centre)
	if enableShadow then 
		SetTextDropshadow(1, 0, 0, 0, 255)
	end
	Citizen.InvokeNative(0xADA9255D, 10);
	DisplayText(str, x, y)
end
  
function DrawText3D(x, y, z, text)
	local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)
	local px,py,pz=table.unpack(GetGameplayCamCoord())  
	local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
	local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
	if onScreen then
	  SetTextScale(0.30, 0.30)
	  SetTextFontForCurrentCommand(1)
	  SetTextColor(255, 255, 255, 215)
	  SetTextCentre(1)
	  DisplayText(str,_x,_y)
	  local factor = (string.len(text)) / 225
	  DrawSprite("feeds", "hud_menu_4a", _x, _y+0.0125,0.015+ factor, 0.03, 0.1, 35, 35, 35, 190, 0)
	end
end

function DrawTexticon(x, y, z,icon)
    local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)
    local px,py,pz=table.unpack(GetGameplayCamCoord())  
    local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
    if onScreen then
        DrawTexture(icon.iconDict, icon.iconName,_x, _y-0.25, 0.06,  0.11, 0.0, icon.color.r,icon.color.g,icon.color.b,icon.color.a, true)
    end
end

function EndShovel()
    digging = false
    if shovelObject then
        DeleteObject(shovelObject)
        SetEntityAsNoLongerNeeded(shovelObject)
        shovelObject = nil
    end
    ClearPedTasks(PlayerPedId())
end

RegisterNetEvent("MJ-TreasureMaps:dig")
AddEventHandler("MJ-TreasureMaps:dig", function(id)
    if DiggedTreasures[id] == true then 
        TriggerEvent("Notification:left_Treasure_robbery", TEXTS.TreasureRobbery, TEXTS.TreasureRobbed, TEXTURES.alert[1], TEXTURES.alert[2], 2000)
        return 
    end
    if praying then 
        TriggerEvent("Notification:left_Treasure_robbery", TEXTS.TreasureRobbery, TEXTS.CantDoThat, TEXTURES.alert[1], TEXTURES.alert[2], 2000)
        return
    end
    if digging then 
        EndShovel()
    else
        TriggerServerEvent("MJ-TreasureMaps:check_shovel", id)
    end
end)

function AttachEnt(from, to, boneIndex, x, y, z, pitch, roll, yaw, useSoftPinning, collision, vertex, fixedRot)
    return AttachEntityToEntity(from, to, boneIndex, x, y, z, pitch, roll, yaw, false, useSoftPinning, collision, false, vertex, fixedRot, false, false)
end


RegisterNetEvent("MJ-TreasureMaps:start_dig")
AddEventHandler("MJ-TreasureMaps:start_dig", function(id)
    if shovelObject then
        DeleteObject(shovelObject)
        SetEntityAsNoLongerNeeded(shovelObject)
        shovelObject = nil
    end
    digging = true
    local pedp = PlayerPedId()
    local pc = GetEntityCoords(pedp)
    local model = Config.Treasure.shovel
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    shovelObject = CreateObject(model, pc.x, pc.y, pc.z, true, true, true)
    local boneIndex = GetEntityBoneIndexByName(pedp, Config.Treasure.bone)
    local Attach = Config.Treasure.pos
    local heading = Config.treasures[id].heading
    SetEntityHeading(PlayerPedId(), heading)
    local anim = Config.Treasure.anim
    RequestAnimDict(anim[1])
    while not HasAnimDictLoaded(anim[1]) do 
        Wait(10)
    end
    DiggedTreasures[id] = true 
    Config.PoliceAlert()
    FreezeEntityPosition(pedp, true)
    SetCurrentPedWeapon(pedp, 'WEAPON_UNARMED', true)
    TaskPlayAnim(pedp, anim[1], anim[2], 1.0, 1.0, -1, 1, 0, false, false, false)
    AttachEnt(shovelObject, pedp, boneIndex, Attach[1], Attach[2], Attach[3], Attach[4], Attach[5], Attach[6], 0, 1, 1, 1)
    Config.Progressbars()
    RemoveAnimDict(anim[1])
    StopAnimTask(PlayerPedId(), anim[1], anim[2], 1.0)
    SetModelAsNoLongerNeeded(model)
    if shovelObject then
        DeleteObject(shovelObject)
        SetEntityAsNoLongerNeeded(shovelObject)
        shovelObject = nil
    end
    ClearPedTasks(PlayerPedId())
    FreezeEntityPosition(pedp, false)
    local dugtreasureModel = Config.Treasure.box 
    RequestModel(dugtreasureModel)
    while not HasModelLoaded(dugtreasureModel) do
        Wait(10)
    end
    local spawnOffset = GetOffsetFromEntityInWorldCoords(pedp, 0.0, 1.0, 0.0) -- Offset the spawn position by 1.5 units in front of the player
    local dugtreasureObject = CreateObject(dugtreasureModel, spawnOffset, true)
    SetEntityHeading(dugtreasureObject, heading + 180) -- Rotate the dug treasure prop to match the orientation
    PlaceObjectOnGroundProperly(dugtreasureObject)
    FreezeEntityPosition(dugtreasureObject, true)
    SetModelAsNoLongerNeeded(dugtreasureModel) -- Unload the dug treasure model
    PlaySoundFrontend("CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true, 1) -- Add the dug treasure prop to the locked props table
    if math.random(0, 100) < Config.Bandits.percent then
        TriggerEvent('MJ-TreasureMaps:banditsStart')
    end
    if created_blips[blip_id] and DiggedTreasures[id] == Id_blips[id] then
        created_blips[blip_id] = false
        Id_blips[id] = false
        RemoveBlip(blip_id)
    end
    table.insert(lockedProps, dugtreasureObject)
    TriggerEvent("MJ-TreasureMaps:digging_timer", id)
end)

RegisterNetEvent('MJ-TreasureMaps:cancel_dig')
AddEventHandler('MJ-TreasureMaps:cancel_dig', function()
    if digging then
        for key, v in pairs(Bandits) do
            if v.Ped then
               DeleteEntity(v.Ped)
            end
        end
        ClearPedTasks(PlayerPedId())
        if shovelObject then
            DeleteObject(shovelObject)
            SetEntityAsNoLongerNeeded(shovelObject)
            shovelObject = nil
        end
        for _, prop in ipairs(lockedProps) do
            DeleteObject(prop)
            SetEntityAsNoLongerNeeded(prop)
        end
        digging = false
        lockedProps = {} -- Clear the locked props table
    end
end)

RegisterNetEvent("MJ-TreasureMaps:digging_timer")
AddEventHandler("MJ-TreasureMaps:digging_timer", function(id)
    local timer = Config.DiggingTimer
    local timer2 = 0
    while timer2 ~= timer and digging do 
        Citizen.Wait(1000)
        timer2 = timer2 + 1
        if not digging then 
            break
        end
    end
    if digging then 
        EndShovel()
        TriggerServerEvent("MJ-TreasureMaps:reward", id)
    end
end)

RegisterNetEvent("MJ-TreasureMaps:banditsStart")
AddEventHandler("MJ-TreasureMaps:banditsStart", function()
	local banditmodel = GetHashKey(Config.Bandits.model)
    local Weapon = GetHashKey(Config.Bandits.Weapon)
    RequestModel(banditmodel)
	if not HasModelLoaded(banditmodel) then RequestModel(banditmodel) end
	while not HasModelLoaded(banditmodel) do Wait(100) end
	Citizen.Wait(100)
	local mat =  math.random(Config.Bandits.random_npc[1],Config.Bandits.random_npc[1]) 
	for i = 1, mat do
		local forwardoffset = GetOffsetFromEntityInWorldCoords( PlayerPedId(),0.0,1.0,0.0)
		local npcs = CreatePed(banditmodel,  forwardoffset.x-math.random(1,20), forwardoffset.y+math.random(2,15), forwardoffset.z, true, true, true, true)
		Citizen.InvokeNative(0x283978A15512B2FE, npcs, true)
		Citizen.InvokeNative(0x23f74c2fda6e7c61, 953018525, npcs)
		GiveWeaponToPed(npcs, Weapon, 50, true, true, 1, false, 0.5, 1.0, 1.0, true, 0, 0)
		SetCurrentPedWeapon(npcs, Weapon, true)
		TaskGoToEntity(npcs,  PlayerPedId(), -1, 2.5, 4.0, 0, 0)
		Wait(500)
		TaskCombatPed(npcs, PlayerPedId())
        Bandits[i] = {
            Ped = npcs
        }
	end
end)

AddEventHandler('onResourceStop', function(resourceName)
	if (GetCurrentResourceName() ~= resourceName) then
	    return
	end
    for key, v in pairs(Bandits) do
        if v.Ped then
           DeleteEntity(v.Ped)
        end
    end
    if praying or digging then 
        EndShovel()
    end
    for i,v in pairs(prompts) do 
        PromptDelete(v)
    end
    if created_blips[blip_id] then
        created_blips[blip_id] = false
        RemoveBlip(blip_id)
    end
    if shovelObject then
        DeleteObject(shovelObject)
        SetEntityAsNoLongerNeeded(shovelObject)
        shovelObject = nil
    end
    for _, prop in ipairs(lockedProps) do
        DeleteObject(prop)
        SetEntityAsNoLongerNeeded(prop)
    end
    ClearPedTasks(PlayerPedId())
end)
----------------------------Basic Notification----------------------------

RegisterNetEvent('Notification:left_Treasure_robbery')
AddEventHandler('Notification:left_Treasure_robbery', function(t1, t2, dict, txtr, timer)
    if Config.framework == "redemrp" then
        local _dict = tostring(dict)
        if not HasStreamedTextureDictLoaded(_dict) then
            RequestStreamedTextureDict(_dict, true) 
            while not HasStreamedTextureDictLoaded(_dict) do
                Citizen.Wait(5)
            end
        end
        if txtr ~= nil then
            exports['MJ-TreasureMaps']:LeftNot(0, tostring(t1), tostring(t2), tostring(dict), tostring(txtr), tonumber(timer))
        else
            local txtr = "tick"
            exports['MJ-TreasureMaps']:LeftNot(0, tostring(t1), tostring(t2), tostring(dict), tostring(txtr), tonumber(timer))
        end
        SetStreamedTextureDictAsNoLongerNeeded(_dict)
    elseif Config.framework == "vorp" then
        TriggerEvent("vorp:TipBottom", t1.."\n"..t2, timer) 
    elseif Config.framework == "rsg" then
        RSGCore.Functions.Notify("You have found some item(s)")
        -- TriggerEvent('RSGCore:Notify', 9, t1.."\n"..t2, timer, 0, dict, txtr, 'COLOR_WHITE')
    end
end)

