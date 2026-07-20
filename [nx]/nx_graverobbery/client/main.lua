NX_GR = NX_GR or {}

RegisterNetEvent('nx_graverobbery:client:startSession', function(payload)
    NX_GR.PlayDigSession(payload)
end)

RegisterNetEvent('nx_graverobbery:client:cancelSession', function(messageKey)
    NX_GR.CleanupAnimation()
    if messageKey then
        NX_GR.Notify(NX_GR.Locale(messageKey), 'error')
    end
end)

RegisterNetEvent('nx_graverobbery:client:receiveAlert', function(payload)
    NX_GR.ReceiveAlert(payload)
end)

RegisterNetEvent('nx_graverobbery:client:syncGraveState', function(payload)
    NX_GR.ApplyGraveState(payload)
end)

RegisterNetEvent('nx_graverobbery:client:startPray', function(payload)
    NX_GR.PlayPray(payload)
end)

CreateThread(function()
    Wait(1000)
    NX_GR.RegisterTargets()
    TriggerServerEvent('nx_graverobbery:server:requestState')
end)

-- ── blip ถาวรประจำคลัสเตอร์หลุมศพ ───────────────────────────────────────────
-- คนละตัวกับ blip แจ้งเตือน sheriff ใน animations.lua (อันนั้นโผล่ชั่วคราวตอนมีคนขุด
-- แล้วหายเอง) อันนี้อยู่บนแผนที่ตลอด แยกสีตามแดน/เมือง
local clusterBlips = {}

CreateThread(function()
    local B = Config.ClusterBlip
    if not B or not B.enabled then return end

    for _, c in ipairs(Config.ClusterBlips or {}) do
        local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, c.coords.x, c.coords.y, c.coords.z)
        SetBlipSprite(blip, B.sprite)
        SetBlipScale(blip, B.scale or 0.2)

        local colorHash = GetHashKey(c.color or '')
        if colorHash ~= 0 then
            Citizen.InvokeNative(0x662D364ABF16DE2F, blip, colorHash)
        end

        Citizen.InvokeNative(0x9CB1A1623062F402, blip, CreateVarString(10, 'LITERAL_STRING', c.label or ''))
        clusterBlips[#clusterBlips + 1] = blip
    end
end)

local function cleanupClusterBlips()
    for _, blip in ipairs(clusterBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    clusterBlips = {}
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    NX_GR.CleanupAnimation()
    NX_GR.CleanupBlips()
    cleanupClusterBlips()
    NX_GR.RemoveTargets()
end)
