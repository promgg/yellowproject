
VORPcore = {}
TriggerEvent("getCore",function(core)
    VORPcore = core
end)


local queue = {}

local function CopAlert(text, pos, senderId)
    local xPlayers = GetPlayers()
	for i=1, #xPlayers, 1 do
        if VORPcore.getUser(xPlayers[i]) then 
            local xPlayer = VORPcore.getUser(xPlayers[i]).getUsedCharacter
            if xPlayer.job == 'police' then
               TriggerClientEvent("pNotify:SendNotification", xPlayers[i], {
                   text = text,
                   layout = Config["alert_position"],
                   queue = "police_alert", 
                   type = 'alert',
                   theme = "redm",
                   timeout = Config["duration"] * 800,
                   senderId = senderId
               })
               TriggerClientEvent("!MJ-Alert-Police:alertArea", xPlayers[i], pos, senderId)
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


RegisterServerEvent("!MJ-Alert-Police:accept")
AddEventHandler("!MJ-Alert-Police:accept", function(name)
    local xPlayers = GetPlayers()
	for i=1, #xPlayers, 1 do
        if VORPcore.getUser(xPlayers[i]) then 
            local xPlayer = VORPcore.getUser(xPlayers[i]).getUsedCharacter
            if xPlayer.job == 'police' then
                local nameplayer = xPlayer.firstname.." "..xPlayer.lastname
                local joblabel = 'ตำรวจ '
		        local textaccept = '<span style=\"font-size:18px;color:white;\">'..joblabel..'</span><span style=\"font-size:18px;color:orange;\">' ..nameplayer.. ' </span><span style=\"font-size:18px;color:white;\">รับเคสแล้ว</span>'
                TriggerClientEvent("pNotify:SendNotification", xPlayers[i], {
                    text = textaccept,
                    layout = Config["alert_position"],
                    queue = "police_alert", 
                    type = "alert",
                    theme = "gta",
                    timeout = Config["duration"] * 800,
                })
            end
        end
	end
end)

RegisterServerEvent("!MJ-Alert-Police:getLocation")
AddEventHandler("!MJ-Alert-Police:getLocation", function(num)
	local data = queue[num]
	if data then
		TriggerClientEvent("!MJ-Alert-Police:sendLocation", source, data.pos)
	end
end)

local player_report = {}

RegisterServerEvent("!MJ-Alert-Police:defaultAlert")
AddEventHandler("!MJ-Alert-Police:defaultAlert", function(type, location, pos, senderId)
	local _source = source
	if player_report[_source] and player_report[_source] > GetGameTimer() then	
		return
	end

	local num = InsertQueue(pos)
	if not num then return end
	
	local action
	if type == "blackwork" then
		action = Config["translate"]["action_blackwork"]
	end
	
	player_report[_source] = GetGameTimer() + (Config["duration"] * 800)
	

	local text = ''..Config["translate"]["title"]..''..string.format(Config["translate"]["text"],  action, location)..'<br><b style="color:black; font-size:12px;background:white; border-radius:3px; padding:1% 4% 1% 4%;">'..Config["base_key_text"]..'</b><b> + <b style="color:black; font-size:12px;background:white; border-radius:3px; padding:1% 4% 1% 4%;"> '..num..'</b>'..Config["translate"]["tip"]..'<br>'
	CopAlert(text, pos, senderId)
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