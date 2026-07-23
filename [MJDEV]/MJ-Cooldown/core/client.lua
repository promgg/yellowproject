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

-- แอดมินสั่งลบคูลดาวน์ (MJ-Admin ปุ่ม "ลบคลูดาวน์" / "ชุบ [ไม่ติดคลูดาวน์]")
--
-- ⚠️ ต้องเก็บกวาดให้ครบเหมือนตอนคูลดาวน์หมดเองตามปกติ (ดูเธรดนับถอยหลังด้านบน)
-- ของเดิมทำแค่ inCooldown = false กับ Cooldown = 0 ทำให้เกิด 3 อาการ:
--   1) หลอดนับเวลาบนจอไม่หาย — ไม่เคยยิง SendNUIMessage Hide (อาการ "กดแล้วไม่มีอะไรเกิดขึ้น")
--   2) ท่าเดินกะเผลกค้าง — ท่านี้เล่นแบบวนไม่มีจบ (duration -1, flag 31) ต้อง ClearPedTasks เอง
--   3) Cooldown = 0 ค้างไว้ พอตายรอบหน้าตัวนับเริ่มจาก 0 -> ติดลบทันที -> เข้าเงื่อนไข
--      "หมดเวลา" ในเธรดนับถอยหลังเลย = คูลดาวน์รอบถัดไปโดนข้ามทั้งรอบ
--      (ตอนตายไม่ได้รีเซ็ตค่าให้ เพราะบล็อกรีเซ็ตอยู่ใต้ `if inCooldown` ซึ่งตอนนั้น false ไปแล้ว)
RegisterNetEvent(MJDEV..":Stopinjured")
AddEventHandler(MJDEV.. ":Stopinjured", function()
	inCooldown = false
	Cooldown = Config['CoolDown'] * 60 -- รีเซ็ตเป็นเต็ม พร้อมใช้รอบหน้า (ไม่ใช่ 0)
	TriggerServerEvent(MJDEV .. "SaveData", false)
	ClearPedTasks(PlayerPedId())       -- เลิกท่าเดินกะเผลก
	Config.DisableControl(false)       -- ปลดล็อกคอนโทรล
	SendNUIMessage({ type = 'Hide' })  -- ซ่อนหลอดนับเวลา
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
			-- เช็ค inCooldown ซ้ำหลังรอโหลด dict — ระหว่างที่รออยู่ คูลดาวน์อาจถูกลบไปแล้ว
			-- (แอดมินกดลบ / หมดเวลาพอดี) ถ้าไม่เช็คจะเล่นท่ากะเผลกทับหลัง ClearPedTasks
			-- แล้วค้างวนไม่จบ เพราะรอบถัดไปเข้า else ไม่มีใครมาเคลียร์ให้อีก
			if inCooldown then
				TaskPlayAnim(PlayerPedId(), A, G, 8.0, -8.0, -1, 31, 0, true, 0, false, 0, false)
			end
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