LP_DM = LP_DM or {}

-- ── ผู้ตาย (client ที่โดนฆ่า) เป็นคนรายงาน ไม่ใช่ผู้ฆ่า ──
-- gameEventTriggered เห็น entity death ของ ped ตัวเองเชื่อถือได้สุดจากฝั่งเหยื่อเอง (เห็นชัวร์ว่าตัวเองตายจริง)
-- server ยัง verify ต่อทุกจุดอยู่ดี (killerServerId ต้องออนไลน์จริง, ระยะสมเหตุสมผล, อาวุธที่อนุญาต, คูลดาวน์คู่)
RegisterNetEvent('lp_deathmatch:server:reportDeath', function(killerServerId, weaponHash)
    local victimSource = source
    if not LP_DM.Security.CheckRateLimit(victimSource, 'reportDeath') then return end

    killerServerId = tonumber(killerServerId)
    weaponHash = tonumber(weaponHash)
    if not killerServerId or not weaponHash then return end
    if killerServerId == victimSource then return end
    if not GetPlayerName(killerServerId) then return end -- ต้องเป็นผู้เล่นที่ต่ออยู่จริงตอนนี้เท่านั้น

    local ok, reason = LP_DM.Event.ReportKill(killerServerId, victimSource, weaponHash)
    if Config.Debug then
        print(('[lp_deathmatch] reportDeath victim=%s killer=%s weapon=%s ok=%s reason=%s'):format(
            victimSource, killerServerId, tostring(weaponHash), tostring(ok), tostring(reason)
        ))
    end
end)

RegisterNetEvent('lp_deathmatch:server:requestState', function()
    local requestSource = source
    if not LP_DM.Security.CheckRateLimit(requestSource, 'requestState') then return end

    local payload = LP_DM.Event.GetSyncPayload()
    if payload then
        TriggerClientEvent('lp_deathmatch:client:start', requestSource, payload)
    end
end)

local function adminReply(source, message)
    if source == 0 then
        print(('[lp_deathmatch] %s'):format(message))
    else
        LP_DM.VORP.Notify(source, message)
    end
end

local function requireAdmin(source)
    if LP_DM.VORP.IsAdmin(source) then return true end
    adminReply(source, LP_DM.Locale('admin_denied'))
    return false
end

RegisterCommand('dmforcestart', function(source)
    if not requireAdmin(source) then return end
    if LP_DM.Event.IsActive() then
        adminReply(source, LP_DM.Locale('already_running'))
        return
    end
    LP_DM.Schedule.MarkTriggeredToday()
    LP_DM.Event.Start()
    adminReply(source, LP_DM.Locale('force_started'))
end, false)

RegisterCommand('dmforceend', function(source)
    if not requireAdmin(source) then return end
    if not LP_DM.Event.IsActive() then
        adminReply(source, LP_DM.Locale('not_running'))
        return
    end
    LP_DM.Event.End()
    adminReply(source, LP_DM.Locale('force_ended'))
end, false)

AddEventHandler('playerDropped', function()
    local droppedSource = source
    LP_DM.Security.ClearPlayer(droppedSource)
    LP_DM.CitySelect.InvalidatePlayer(droppedSource)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if LP_DM.Event.IsActive() then
        TriggerClientEvent('lp_deathmatch:client:end', -1, { cities = {}, groups = {}, aborted = true })
    end
end)

CreateThread(function()
    while true do
        Wait(30000)
        if LP_DM.Schedule.ShouldStartNow() then
            LP_DM.Event.Start()
        end
    end
end)
