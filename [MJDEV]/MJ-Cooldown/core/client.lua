local Cooldown = Config['CoolDown'] * 60
local Dead = false
local inCooldown = false
local MJDEV = 'MJ-Cooldown'
local A = Config['Animations'][1]
local G = Config['Animations'][2]
PlayerCloth = {}
NewPlayerCloth = {}
VORPcore = {} -- core object

TriggerEvent("getCore", function(core)
    VORPcore = core
end)

--------------  ตัวเทสระบบจะเช็คว่าตายแล้วเกิดรึป่าว
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1000)
		if IsPedDeadOrDying(PlayerPedId(), false) then
			if not Dead then
				Dead = true
			end
			if inCooldown then
				inCooldown = false
				Cooldown = Config['CoolDown'] * 60
			end
		else
			if Dead then
				Dead = false
				inCooldown = true
				TriggerServerEvent(MJDEV .. "SaveData", true)
			end
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1000)
		if inCooldown and not Dead then
			Cooldown = Cooldown - 1
			if Cooldown > 0 then
				SendNUIMessage({ 
					type = 'Show',
					time = Cooldown,
				})
			end
			if Cooldown <= 0 then
				Cooldown = Config['CoolDown'] * 60
				TriggerServerEvent(MJDEV .. "SaveData", false)
				ClearPedTasks(PlayerPedId())
				inCooldown = false
				Config.DisableControl(false)
				SendNUIMessage({ 
					type = 'Hide',
				})
			end
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5)
		if inCooldown and Cooldown > 0 then
			Config.DisableControl(true)
		else
			Wait(1000)
		end
	end
end)

local timesave = Config['SaveData'] * 60
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1000)
		timesave = timesave - 1
		if timesave <= 0 then
			if inCooldown then
				TriggerServerEvent(MJDEV .. "SaveData", true)
			else
				TriggerServerEvent(MJDEV .. "SaveData", false)
			end
			timesave = Config['SaveData'] * 60
		end
	end
end)

RegisterNetEvent(MJDEV..":Stopinjured")
AddEventHandler(MJDEV.. ":Stopinjured", function()
	inCooldown = false
	Cooldown = 0
	TriggerServerEvent(MJDEV .. "SaveData", false)
end)


RegisterNetEvent(MJDEV.."DeathCheck")
AddEventHandler(MJDEV.. "DeathCheck", function()
	inCooldown = true
	Cooldown = Config['CoolDown'] * 60
	TriggerServerEvent(MJDEV .. "SaveData", true)
end)

RegisterNetEvent(MJDEV .. "GetData")
AddEventHandler(MJDEV .. "GetData", function(cb)
	if cb then
		inCooldown = true
	else
		inCooldown = false
	end
end)

if Config['ChangeClothes'] then
	RegisterNetEvent(MJDEV .. "GetCloth")
	AddEventHandler(MJDEV .. "GetCloth", function(cbcom)
		NewPlayerCloth = cbcom
		if inCooldown then
			if IsPedMale(PlayerPedId()) then
				if NewPlayerCloth.Satchels ~= 2105864149 then
					NewPlayerCloth.Satchels = 2105864149
					TriggerEvent("vorpcharacter:updateCache", false, json.encode(NewPlayerCloth))
					Wait(1500)
					ExecuteCommand('rc')
				end
			else
				if NewPlayerCloth.Satchels ~= 2116878699 then
					NewPlayerCloth.Satchels = 2116878699
					TriggerEvent("vorpcharacter:updateCache", false, json.encode(NewPlayerCloth))
					Wait(1500)
					ExecuteCommand('rc')
				end
			end
		else
			if NewPlayerCloth.Satchels ~= -1 then
				NewPlayerCloth.Satchels = -1
				TriggerEvent("vorpcharacter:updateCache", false, json.encode(NewPlayerCloth))
				Wait(1500)
				ExecuteCommand('rc')
			end
		end
	end)
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(500)
		if inCooldown then
			RequestAnimDict(A)
			while not HasAnimDictLoaded(A) do
				Wait(500)
			end
			TaskPlayAnim(PlayerPedId(), A, G, 8.0, -8.0, -1, 31, 0, true, 0, false, 0, false)
			Wait(5000)
		else
			Wait(1000)
		end
	end
end)


-- ตรวจสอบการรีสคริปต์และยกเลิกแอนิเมชันที่กำลังเล่นอยู่
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
		ExecuteCommand('rc')
        ClearPedTasks(PlayerPedId()) -- ยกเลิกแอนิเมชันที่กำลังเล่นอยู่เมื่อรีสคริปต์
        inCooldown = false -- เปลี่ยนสถานะเป็นไม่อยู่ใน cooldown
    end
end)