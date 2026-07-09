
VORPcore = {}
TriggerEvent("getCore",function(core)
    VORPcore = core
end)


local queue = {}

RegisterServerEvent('vorp:ImDead')
AddEventHandler('vorp:ImDead', function(a)
    if a then 
        local AmbulanceCount = 0
        local xPlayers = GetPlayers()
        for i=1, #xPlayers, 1 do
            if VORPcore.getUser(xPlayers[i]) then 
                local xPlayer = VORPcore.getUser(xPlayers[i]).getUsedCharacter
                if xPlayer.job == 'doctor' then
                    AmbulanceCount = AmbulanceCount + 1
                end
            end
    
        end
        TriggerClientEvent("MJ-Alert-Doctor:getdoctorcount",source, AmbulanceCount)
    end
end)


local function CopAlert(text, pos, alert, senderId)
    local xPlayers = GetPlayers()
	for i=1, #xPlayers, 1 do
        if VORPcore.getUser(xPlayers[i]) then 
            local xPlayer = VORPcore.getUser(xPlayers[i]).getUsedCharacter
            if xPlayer.job == 'doctor' then
               TriggerClientEvent("pNotify:SendNotification", xPlayers[i], {
                   text = text,
                   layout = Config["alert_position"],
                   queue = "doctor_alert", 
                   type = alert,
                   theme = "gta",
                   timeout = Config["duration"] * 800,
                   senderId = senderId
               })
   
               TriggerClientEvent("!MJ-Alert-Doctor:alertArea", xPlayers[i], pos, senderId)
           
           end
        end
 		
	end
end

local function InsertQueue(pos)
	local num
	for i=1, 9 do
		local v = queue[i]
		if v == nil then
			num = i
			queue[i] = {
				time = GetGameTimer() + (Config["duration"] * 800),
				pos = pos
			}
			break
		end
	end
	return num
end


RegisterServerEvent("!MJ-Alert-Doctor:accept")
AddEventHandler("!MJ-Alert-Doctor:accept", function(name)
    local xPlayers = GetPlayers()

	for i=1, #xPlayers, 1 do
        if VORPcore.getUser(xPlayers[i]) then 
            local xPlayer = VORPcore.getUser(xPlayers[i]).getUsedCharacter
            if xPlayer.job == 'doctor' then
                local nameplayer = xPlayer.firstname.." "..xPlayer.lastname
                local joblabel = 'หมอ '
		        local textaccept = '<span style=\"font-size:18px;color:white;\">'..joblabel..'</span><span style=\"font-size:18px;color:orange;\">' ..nameplayer.. ' </span><span style=\"font-size:18px;color:white;\">รับเคสแล้ว</span>'
                TriggerClientEvent("pNotify:SendNotification", xPlayers[i], {
                    text = textaccept,
                    layout = Config["alert_position"],
                    queue = "doctor_alert", 
                    type = "alert",
                    theme = "gta",
                    timeout = Config["duration"] * 800,
                })
            end
        end

	end
end)

RegisterServerEvent("!MJ-Alert-Doctor:getLocation")
AddEventHandler("!MJ-Alert-Doctor:getLocation", function(num)
	local data = queue[num]
	if data then
		TriggerClientEvent("!MJ-Alert-Doctor:sendLocation", source, data.pos)
	end
end)

local player_report = {}

RegisterServerEvent("!MJ-Alert-Doctor:defaultAlert")
AddEventHandler("!MJ-Alert-Doctor:defaultAlert", function(type, location, pos, senderId)
	if player_report[source] and player_report[source] > GetGameTimer() then	
		return
	end
	--print(type, gender, location, pos)
	local num = InsertQueue(pos)
	if not num then return end
	
	local action
	if type == "dead" then
		action = Config["translate"]["action_dead"]
		alert = Config.dead
	end
	
	player_report[source] = GetGameTimer() + (Config["duration"] * 800)
	

	local text = ''..Config["translate"]["title"]..''..string.format(Config["translate"]["text"],  action, location)..'<br><b style="color:black; font-size:12px;background:white; border-radius:3px; padding:1% 4% 1% 4%;">'..Config["base_key_text"]..'</b><b> + <b style="color:black; font-size:12px;background:white; border-radius:3px; padding:1% 4% 1% 4%;"> '..num..'</b>'..Config["translate"]["tip"]..'<br>'
	CopAlert(text, pos, alert, senderId)
end)

Citizen.CreateThread(function()
	while true do
		for i=1, 9 do
			local v = queue[i]
			if v and v.time < GetGameTimer() then
				queue[i] = nil
			end
		end
		Citizen.Wait(500)
	end
end)