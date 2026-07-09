MJDev = GetCurrentResourceName()
local VORPcore = {} -- core object

TriggerEvent("getCore", function(core)
    VORPcore = core
end)

-- Check if the player has the required job or off-duty job
VORPcore.addRpcCallback(MJDev..'Checkjob', function(source, cb, job, offjob)
    local user = VORPcore.getUser(source)
    if not user then
        cb(false)
        return
    end
    local Character = user.getUsedCharacter
    if not Character then
        cb(false)
        return
    end
    cb(Character.job == job or Character.job == offjob)
end)


local playerDutyTimes = {}

function GetPlayerDutyTime(source)
    return playerDutyTimes[source] or 0
end

RegisterNetEvent(MJDev .. 'Dutyactive')
AddEventHandler(MJDev .. 'Dutyactive', function(id, job)
    local src = source
    if job then
        playerDutyTimes[src] = playerDutyTimes[src] or 0
        -- เริ่มนับเวลาฝั่ง server (ถ้าต้องการ)
    else
        playerDutyTimes[src] = 0
    end
end)

-- Fix getUsedCharacter calls by adding ()
RegisterNetEvent(MJDev .. 'SendTimeDiscord')
AddEventHandler(MJDev .. 'SendTimeDiscord', function(DutyTime)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    local Character = user.getUsedCharacter
    local hours, mins, secs = Showtime(DutyTime)

    for jobKey, webhook in pairs(Config.Webhook) do
        if Character.job == jobKey then
            SetDiscord(
                MJDev, 
                "ประวัติการทำงาน", 
                " คุณ " .. Character.firstname .. " หน่วยงาน " .. Character.job .. " ได้ทำงานเป็นเวลา " .. hours .. ":" .. mins .. ":" .. secs, 
                0000, 
                webhook
            )
        end
    end
end)

-- Similar fix in AdditemPayCheck:
RegisterNetEvent(MJDev .. 'AdditemPayCheck')
AddEventHandler(MJDev .. 'AdditemPayCheck', function()
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    local Character = user.getUsedCharacter

    local job = Character.job
    local jobGrade = tostring(Character.jobGrade)

    if Config['PayCheckReward'][job] and Config['PayCheckReward'][job][jobGrade] then
        local rewardData = Config['PayCheckReward'][job][jobGrade]

        -- Add money reward
        if rewardData.moneytype and rewardData.moneycount then
            local currencyType = (rewardData.moneytype == "cash") and 0 or 1
            Character.addCurrency(currencyType, rewardData.moneycount)
            TriggerClientEvent("pNotify:SendNotification", _source, {
                text = 'คุณได้รับเงินสวัสดิการ ' .. rewardData.moneycount .. '$',
                type = "success",
                timeout = 5000,
                layout = "centerLeft",
                queue = "left"
            })
        end

        -- Add item reward
        if rewardData.item then
            for item, amount in pairs(rewardData.item) do
                TriggerEvent("vorpCore:canCarryItem", _source, item, amount, function(canCarry)
                    if canCarry then
                        exports.vorp_inventory:addItem(_source, item, amount)
                    else
                        TriggerClientEvent("pNotify:SendNotification", _source, {
                            text = 'Item ชิ้นนี้ในกระเป๋าของคุณเต็ม',
                            type = "error",
                            timeout = 5000,
                            layout = "centerLeft",
                            queue = "left"
                        })
                    end
                end)
            end
        end
    end
end)

-- Thread update player duty time with user check
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        for src, time in pairs(playerDutyTimes) do
            local user = VORPcore.getUser(src)
            if user then
                playerDutyTimes[src] = time + 1
            else
                playerDutyTimes[src] = nil
            end
        end
    end
end)

function Showtime(seconds)
    local hours = string.format("%02d", math.floor(seconds / 3600))
    local mins = string.format("%02d", math.floor((seconds % 3600) / 60))
    local secs = string.format("%02d", math.floor(seconds % 60))
    return hours, mins, secs
end

local ActiveDutyPlayers = {}

RegisterNetEvent(MJDev .. 'SetDutyState')
AddEventHandler(MJDev .. 'SetDutyState', function(state, job, stationId)
    local src = source
    if state then
        ActiveDutyPlayers[src] = {
            job = job,
            station = stationId, -- ✅ เก็บ station ID ด้วย
            name = GetPlayerName(src)
        }
    else
        ActiveDutyPlayers[src] = nil
    end
end)

RegisterNetEvent(MJDev .. 'RequestDutyLocations')
AddEventHandler(MJDev .. 'RequestDutyLocations', function()
    local src = source
    local playerData = ActiveDutyPlayers[src]
    if not playerData then return end

    local srcJob = playerData.job
    local srcStation = playerData.station

    local results = {}

    for id, data in pairs(ActiveDutyPlayers) do
        if id ~= src and data.job == srcJob and data.station == srcStation then
            local ped = GetPlayerPed(id)
            if ped then
                local coords = GetEntityCoords(ped)
                table.insert(results, {
                    id = id,
                    name = data.name,
                    coords = coords
                })
            end
        end
    end

    TriggerClientEvent(MJDev .. 'ReceiveDutyLocations', src, results)
end)

-- playerDropped event fix
AddEventHandler('playerDropped', function(reason)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    local Character = user.getUsedCharacter
    if Character and Character.job then
        local jobGrade = Character.jobGrade
        for k, v in pairs(Config['Duty']) do
            if Character.job == v['Job'] then
                Character.setJob(v['offJob'])
                Character.setJobGrade(tonumber(jobGrade))
                break
            end
        end
        ActiveDutyPlayers[_source] = nil
    end
end)

-- Discord Webhook Configuration
local communityname = 'MJDev'
local communtiylogo = ""

function SetDiscord(name, message, description, color, DiscordWebHook)
    if not message or message == "Player Log #1" then return false end

    local embeds = {
        {
            ["title"] = message,
            ["type"] = "rich",
            ["color"] = color,
            ["description"] = description,
            ["footer"] = {
                ["text"] = communityname,
                ["icon_url"] = communtiylogo
            }
        }
    }

    PerformHttpRequest(DiscordWebHook, function(err, text, headers)
        if err ~= 200 then
            print("Discord Webhook Error: "..err)
        end
    end, 'POST', json.encode({ username = name, embeds = embeds }), { ['Content-Type'] = 'application/json' })
end
