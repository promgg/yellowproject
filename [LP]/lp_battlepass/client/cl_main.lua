-- lp_battlepass / client/cl_main.lua
-- เปิด/ปิด NUI, ส่ง "คำขอเคลม" ไป server, รับ state มาอัปเดต UI
-- ไม่มี logic ตัดสินรางวัล/XP ฝั่งนี้ (server-authoritative) — ไม่มี online-XP tick (ตัดตามสเปค)

local uiOpen = false

-- lp_allmenu หมวด battlepass / คำสั่ง เรียกตัวนี้
RegisterNetEvent(Events.openBattlePass, function()
    TriggerServerEvent(Events.requestOpen)
end)

RegisterCommand(Config.Command, function()
    TriggerEvent(Events.openBattlePass)
end, false)

-- server ส่ง state เต็มมาเปิด UI
RegisterNetEvent(Events.openUI, function(payload)
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ enable = true, data = payload })
end)

-- server push อัปเดตระหว่างเปิดอยู่ (หลังเคลม/ได้ XP) — ส่งเฉพาะตอนค่าเปลี่ยน (ข้อ 7)
RegisterNetEvent(Events.pushState, function(payload)
    if not uiOpen then return end
    SendNUIMessage({ enable = true, data = payload })
end)

RegisterNetEvent(Events.noti, function(msg)
    -- เผื่อไว้ (server ส่ง pNotify ตรงอยู่แล้ว)
    if msg then
        TriggerEvent('pNotify:SendNotification', { text = msg, type = 'info', timeout = 4000 })
    end
end)

local function closeUI()
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ enable = false })
end

-- ── NUI callbacks — ส่งแค่ "คำขอ" (level) server ตรวจสิทธิ์/รางวัลเองทั้งหมด ──
RegisterNUICallback('quit', function(_, cb)
    closeUI()
    cb({ ok = true })
end)

RegisterNUICallback('reward', function(data, cb)
    local level = data and tonumber(data.level)
    if level then TriggerServerEvent(Events.reward, level) end
    cb({ ok = true })
end)

RegisterNUICallback('rewardVIP', function(data, cb)
    local level = data and tonumber(data.level)
    if level then TriggerServerEvent(Events.rewardVIP, level) end
    cb({ ok = true })
end)

RegisterNUICallback('claimAllReward', function(_, cb)
    TriggerServerEvent(Events.claimAllReward)
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    if uiOpen then TriggerServerEvent(Events.requestOpen) end
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
end)
