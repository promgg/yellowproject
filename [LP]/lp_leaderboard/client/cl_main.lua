-- lp_leaderboard / client/cl_main.lua
-- เปิด/ปิด NUI, ส่ง "คำขอ" ไป server (ขอดู / ขอ reset[admin]) — ไม่มี logic คะแนนฝั่งนี้

local uiOpen = false

local function requestOpen() TriggerServerEvent(Events.requestOpen) end

RegisterCommand(Config.Command, requestOpen, false)
for _, a in ipairs(Config.Aliases or {}) do RegisterCommand(a, requestOpen, false) end

RegisterNetEvent(Events.openUI, function(payload)
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = payload })
end)

RegisterNetEvent(Events.pushState, function(payload)
    if not uiOpen then return end
    SendNUIMessage({ action = 'update', data = payload })
end)

local function closeUI()
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    TriggerServerEvent(Events.close)
end

RegisterNUICallback('close', function(_, cb) closeUI(); cb({ ok = true }) end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
end)
