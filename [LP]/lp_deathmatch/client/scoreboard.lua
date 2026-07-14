LP_DM = LP_DM or {}
LP_DM.Scoreboard = {}

local visible = false
local tickGen = 0 -- generation counter กัน countdown thread เก่าค้างทับอันใหม่ถ้า start ซ้อนกัน

function LP_DM.Scoreboard.Hide()
    if not visible then return end
    visible = false
    tickGen = tickGen + 1
    SendNUIMessage({ action = 'lp_deathmatch:hide' })
end

local function startCountdown(durationMs)
    tickGen = tickGen + 1
    local myGen = tickGen
    local deadline = GetGameTimer() + durationMs

    CreateThread(function()
        while visible and myGen == tickGen do
            local remaining = math.max(0, deadline - GetGameTimer())
            SendNUIMessage({ action = 'lp_deathmatch:tick', remainingMs = remaining })
            if remaining <= 0 then break end
            Wait(1000)
        end
    end)
end

RegisterNetEvent('lp_deathmatch:client:start', function(payload)
    visible = true
    SendNUIMessage({ action = 'lp_deathmatch:start', cities = payload.cities })
    startCountdown(payload.durationMs or 0)
end)

RegisterNetEvent('lp_deathmatch:client:scoreUpdate', function(payload)
    if not visible then return end
    SendNUIMessage({ action = 'lp_deathmatch:scoreUpdate', cityId = payload.cityId, score = payload.score })
end)

RegisterNetEvent('lp_deathmatch:client:end', function(payload)
    if payload.aborted then
        LP_DM.Scoreboard.Hide()
        return
    end

    SendNUIMessage({ action = 'lp_deathmatch:end', cities = payload.cities, groups = payload.groups })
    tickGen = tickGen + 1 -- หยุด countdown thread ทันที ไม่ต้องรอ tick ถัดไป

    SetTimeout(8000, function()
        LP_DM.Scoreboard.Hide()
    end)
end)

-- ขอ sync สถานะตอน resource เริ่ม เผื่อมีอีเว้นท์ทำงานอยู่แล้วตอนที่ client พึ่งต่อ/reconnect
CreateThread(function()
    Wait(1000)
    TriggerServerEvent('lp_deathmatch:server:requestState')
end)
