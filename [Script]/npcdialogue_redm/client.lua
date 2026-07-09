local npcs = {}

function GetOffsetFromCoordsAndHeading(coords, heading, offsetX, offsetY, offsetZ)
    local headingRad = math.rad(heading)
    local x = offsetX * math.cos(headingRad) - offsetY * math.sin(headingRad)
    local y = offsetX * math.sin(headingRad) + offsetY * math.cos(headingRad)
    local z = offsetZ

    local worldCoords = vector4(
        coords.x + x,
        coords.y + y,
        coords.z + z,
        heading
    )
    
    return worldCoords
end

function CamCreate(npc)
	cam = CreateCam('DEFAULT_SCRIPTED_CAMERA')
	local coordsCam = GetOffsetFromCoordsAndHeading(npc, npc.w, 0.0, 0.6, 1.60)
	local coordsPly = npc
	SetCamCoord(cam, coordsCam)
	PointCamAtCoord(cam, coordsPly['x'], coordsPly['y'], coordsPly['z']+1.60)
	SetCamActive(cam, true)
	RenderScriptCams(true, true, 500, true, true)

end

function DestroyCamera()
    RenderScriptCams(false, true, 500, 1, 0)
    DestroyCam(cam, false)
end

-- NPC'leri spawn et
Citizen.CreateThread(function()
    for i, npc in ipairs(Config.npcs) do
        RequestModel(GetHashKey(npc.ped))
        while not HasModelLoaded(GetHashKey(npc.ped)) do
            Wait(500)
        end

        local npcPed = CreatePed(GetHashKey(npc.ped), npc.coords.x, npc.coords.y, npc.coords.z, npc.coords.w, false, false)
        Citizen.InvokeNative(0x283978A15512B2FE, npcPed, true)
        Citizen.InvokeNative(0x77FF8D35EEC6BBC4, npcPed, npc.preset)
        while not Citizen.InvokeNative(0xA0BC8FAED8CFEB3C,npcPed) do
            Citizen.Wait(0)
        end
        Citizen.InvokeNative(0x704C908E9C405136, npcPed)
        Citizen.InvokeNative(0xAAB86462966168CE, npcPed, 1)
        FreezeEntityPosition(npcPed, true)
        SetEntityInvincible(npcPed, true)
        SetPedPromptName(npcPed, npc.name)
        SetBlockingOfNonTemporaryEvents(npcPed, true)
        npcs[i] = npcPed
    end
end)

RegisterNetEvent("npc-menu:showMenu", function(npc)
    SendNUIMessage({
        type = "dialog",
        options = npc.options,
        name = npc.name,
        text = npc.text,
        job = npc.job
    })
    CamCreate(npc.coords)
end)


RegisterNUICallback("npc-menu:hideMenu", function()
    SetNuiFocus(false, false)
    DestroyCamera()
end)

RegisterNUICallback("npc-menu:process", function(data)

    SetNuiFocus(false, false)
    if data.type == 'client' then
        TriggerEvent(data.event, data.args)
    elseif data.type == 'server' then
        TriggerServerEvent(data.event, data.args)
    elseif data.type == 'command' then
        ExecuteCommand(data.event, data.args)
    end
    DestroyCamera()
end)

local PromptKey
local PromptGroup = GetRandomIntInRange(0, 0xffffff)

Citizen.CreateThread(function()
    local str = "Talk"
    local a = PromptRegisterBegin()
    PromptSetControlAction(a, 0xDFF812F9) -- ใช้ปุ่ม E
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(a, str)
    PromptSetEnabled(a, true)
    PromptSetVisible(a, true)
    PromptSetStandardMode(a, true)
    PromptSetGroup(a, PromptGroup)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, a, true) -- Hold mode
    PromptRegisterEnd(a)
    PromptKey = a

    while true do
        Citizen.Wait(5)
        if not IsNuiFocused() then 
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed, false)

            for _, npc in ipairs(Config.npcs) do
                local npcCoords = vec3(npc.coords.x, npc.coords.y, npc.coords.z)
                local distance = #(coords - npcCoords)

                -- ตรวจสอบระยะทาง
                local maxDistance = npc.distance ~= nil and npc.distance or 1.5

                if distance < maxDistance then
                    local label = CreateVarString(10, 'LITERAL_STRING', npc.name)
                    PromptSetActiveGroupThisFrame(PromptGroup, label)

                    if Citizen.InvokeNative(0xC92AC953F0A982AE, PromptKey) then
                        TriggerEvent("npc-menu:showMenu", npc)
                        SetNuiFocus(true, true)
                        Citizen.Wait(500) -- ลดเวลาเพื่อให้ตอบสนองไวขึ้น
                    end
                end
            end
        end
    end
end)


--------------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("npc_event", function(id)
    print("event triggered, param is: "..id[1])
end)

AddEventHandler('onResourceStop', function(resourceName)
    if cam then 
        DestroyCamera()
    end
    for i,v in pairs(npcs) do 
        DeleteEntity(v)
    end
end)