
local VorpCore = exports.vorp_core:GetCore()

local timer = 0
local isEventStart = false
local EventName = nil
local script_name = 'MJ-Deletehorse'

-------------------------------------------------------
--- Register Commands เริ่มนับเวลาถอยหลังแจ้งเตือนลบรถอัตโนมัติ ---
-------------------------------------------------------
RegisterCommand(Config.DeleteAllVehicle.command, function(source, args, user)
    local xUser = VorpCore.getUser(source)
    if not xUser then return end

    local xPlayer = xUser.getUsedCharacter
    if Config.DeleteAllVehicle.group[xPlayer.group] then
        if args[1] ~= nil and not isEventStart then
            local minute = args[1]
            TriggerClientEvent(script_name .. ":RunNotifyDeleteHorseAndWagon", -1, minute)
            checkTimeLoad(minute, 'delcar')
        end
    end
end)

-----------------------------------------------------------
--- Register Commands ยกเลิกการนับเวลาถอยหลังแจ้งเตือนลบรถอัตโนมัติ ---
-----------------------------------------------------------
RegisterCommand(Config.CanCelDeleteAllVehicle.command, function(source, args, user)
    local xUser = VorpCore.getUser(source)
    if not xUser then return end

    local xPlayer = xUser.getUsedCharacter
    if Config.DeleteAllVehicle.group[xPlayer.group] then
        isEventStart = false
        timer = 0
        TriggerClientEvent(script_name .. ":CancelNotifyDeleteVehicle", -1)
    end
end)

------------------------------------------------------------
--- Register Commands เริ่มนับเวลาถอยหลังแจ้งเตือน restart server ---
------------------------------------------------------------
RegisterCommand(Config.RunRestartNotify.command, function(source, args, user)
    print('[rsnoti] source =', source)

    local xUser = VorpCore.getUser(source)
    print('[rsnoti] xUser =', xUser)
    if not xUser then
        print('[rsnoti] STOP: xUser is nil (ไม่พบ session ของ source นี้)')
        return
    end

    local xPlayer = xUser.getUsedCharacter
    print('[rsnoti] xPlayer =', xPlayer)
    if not xPlayer then
        print('[rsnoti] STOP: xPlayer is nil (ยังไม่ได้เลือกตัวละคร)')
        return
    end

    print('[rsnoti] xPlayer.group =', xPlayer.group)
    print('[rsnoti] Config.RunRestartNotify.group[xPlayer.group] =', Config.RunRestartNotify.group[xPlayer.group])

    if Config.RunRestartNotify.group[xPlayer.group] then
        print('[rsnoti] args[1] =', args[1])
        print('[rsnoti] isEventStart =', isEventStart)

        if args[1] ~= nil and not isEventStart then
            local minute = args[1]
            print('[rsnoti] STARTING countdown, minute =', minute)

            TriggerClientEvent(script_name .. ":RunNotifyRestartServer", -1, minute)
            checkTimeLoad(minute, 'restart')
            SendToDiscordWithTime(minute, 'restart')

            print('[rsnoti] TriggerClientEvent + checkTimeLoad + SendToDiscordWithTime called')
        else
            print('[rsnoti] STOP: args[1] is nil or isEventStart already true — ไม่ได้เริ่มนับ')
        end
    else
        print('[rsnoti] STOP: group ของ xPlayer ไม่ตรงกับที่ Config.RunRestartNotify.group อนุญาต')
    end
end)

-----------------------------------------------------------------
--- Register Commands ยกเลิกการนับเวลาถอยหลังแจ้งเตือน restart server ---
-----------------------------------------------------------------
RegisterCommand(Config.CanCelRestartNotify.command, function(source, args, user)
    local xUser = VorpCore.getUser(source)
    if not xUser then return end

    local xPlayer = xUser.getUsedCharacter
    if Config.CanCelRestartNotify.group[xPlayer.group] then
        isEventStart = false
        Citizen.Wait(2000)
        timer = 0
        TriggerClientEvent(script_name .. ":CancelNotifyRestartServer", -1)
        SendToDiscordCancel()
    end
end)

RegisterServerEvent(script_name .. ':CheckEventTime')
AddEventHandler(script_name .. ':CheckEventTime', function()
    if isEventStart then
        if EventName == 'delcar' then
            TriggerClientEvent(script_name .. ':RunNotifyDeleteHorseAndWagon', source, timer / 60)
        elseif EventName == 'restart' then
            TriggerClientEvent(script_name .. ':RunNotifyRestartServer', source, timer / 60)
        end
    end
end)

function checkTimeLoad(xTime, xEventName)
    timer = xTime * 60
    isEventStart = true
    EventName = xEventName

    Citizen.CreateThread(function()

        while isEventStart do
            Citizen.Wait(1000)
            if timer == 0 then
                if EventName == 'restart' then
                    StopServer(timer)
                end
                isEventStart = false
                EventName = nil
            end
            timer = timer - 1
        end
    end)
end

function checkTimeRunAuto()
    SetTimeout(1000, function()
        local date_local = os.date('%H:%M', os.time())
        for i = 1, #Config.Timer, 1 do
            -- re-check every iteration: if two Config.Timer entries share the same
            -- start_time (e.g. a delcar and a restart both at "14:00"), only the
            -- first one should actually start — otherwise both fire in the same tick
            -- and race each other on the client (flickering/overlapping UI)
            if isEventStart then break end

            local start_time = Config.Timer[i][1]
            if date_local == start_time then
                if Config.Timer[i][3] == 'delcar' then
                    TriggerClientEvent(script_name .. ':RunNotifyDeleteHorseAndWagon', -1, Config.Timer[i][2])
                    checkTimeLoad(Config.Timer[i][2], 'delcar')
                elseif Config.Timer[i][3] == 'restart' then
                    TriggerClientEvent(script_name .. ':RunNotifyRestartServer', -1, Config.Timer[i][2])
                    checkTimeLoad(Config.Timer[i][2])
                    SendToDiscordWithTime(Config.Timer[i][2])
					StopServer(Config.Timer[i][2])
                end
                break
            end
        end
        checkTimeRunAuto()
    end)
end
checkTimeRunAuto()


function SendToDiscordWithTime(ptime)
	local embed = {
        {	
			["title"] = Config.text1 .. ptime .. ' นาที',
			["color"] = 16759603,
            ["fields"] = {
				{
					["name"] = 'ประเทศ',
					["value"] = '``'..Config.nameserver..'``',
					["inline"] = true
				},
				{
					["name"] = 'สถานะเซิฟเวอร์',
					["value"] = '``🟢 ออนไลน์``',--..'\nIP Domain : Connect '..Config.domain..' ```',
					["inline"] = true
				},
				
			},
		}
	}
	PerformHttpRequest(Config.webhooks_Autorestart, function(err, text, headers) end, 'POST', json.encode({username = 'Autorestart', embeds = embed, avatar_url = Config.imagebot}), { ['Content-Type'] = 'application/json' })
end

function SendToDiscordCancel(ptime)
	local embed = {
        {	
			["title"] = 'ยกเลิกการรีสตาร์ทเซิฟเวอร์ !!',
			["color"] = 0xff0000,
            ["fields"] = {
				{
					["name"] = 'ประเทศ',
					["value"] = '``'..Config.nameserver..'``',
					["inline"] = true
				},
				{
					["name"] = 'สถานะเซิฟเวอร์',
					["value"] = '``🟢 ออนไลน์``',--..'\nIP Domain : Connect '..Config.domain..' ```',
					["inline"] = true
				},
				
			}
		}
	}
	PerformHttpRequest(Config.webhooks_Autorestart, function(err, text, headers) end, 'POST', json.encode({username = 'Autorestart', embeds = embed, avatar_url = Config.imagebot}), { ['Content-Type'] = 'application/json' })
end

function SendToDiscordRestart(ptime)
	local embed = {
        {	
			["title"] = Config.text2,
			["color"] = 0x00e138,
            ["fields"] = {
				{
					["name"] = 'ประเทศ',
					["value"] = '``'..Config.nameserver..'``',
					["inline"] = true
				},
				{
					["name"] = 'สถานะเซิฟเวอร์',
					["value"] = '``🔴 ออฟไลน์``',--..'\nIP Domain : Connect '..Config.domain..' ```',
					["inline"] = true
				},
				
			},
		}
	}
	PerformHttpRequest(Config.webhooks_Autorestart, function(err, text, headers) end, 'POST', json.encode({username = 'Autorestart', embeds = embed, avatar_url = Config.imagebot}), { ['Content-Type'] = 'application/json' })
end


function StopServer(ptime)
	Citizen.CreateThread(function()
		if Config.closecmd then
			Wait((ptime * 60 * 1000) + 10)
			SendToDiscordRestart()
			kickPl()
			Wait(5000)
			Wait(10000)
			io.popen(Config.cmd_name)
			Citizen.Wait(300)
			ExecuteCommand('quit')
			os.exit()
		end
	  
	end)
end

function kickPl()
    local xPlayers = GetPlayers()
    for i=1, #xPlayers, 1 do
        local xPlayer = VorpCore.getUser(xPlayers[i]).getUsedCharacter
        xPlayer.kick(Config.TextUIRestart)
    end
end


Citizen.CreateThread(function()
    Citizen.Wait(5000) 
    print("##################################################")
    print("##                                              ##")
    print("##           \27[37mMJ DEV | Verify \27[32mSuccess\27[0m            ##")
    print("##           \27[36mThank You For Purchase\27[0m             ##")
    print("##           \27[34mVersion : 1.0 (Latest)\27[0m             ##")
    print("##                                              ##")
    print("##################################################")
    print("###### \27[36mDiscord: https://discord.gg/gHRNMDQKzb\27[0m ####")
end)