-- lp_welfarelogin / client/client.lua
-- หน้าที่: เปิด/ปิด NUI, ส่ง "คำขอเคลม" ไป server, รับ state มาอัปเดต UI
-- ไม่มี logic ตัดสินรางวัลใด ๆ ฝั่งนี้ (server-authoritative)

local latestState = nil
local uiOpen      = false

-- ── เปิด/ปิด UI ────────────────────────────────────────────────────────────
-- ขอ state สดจาก server "ทุกครั้ง" ที่เปิด (ไม่ใช่แค่ครั้งแรกที่ latestState ยังไม่มี) —
-- เดิมใช้ latestState ค้างจากตอน login ทำให้ VIP/วัน ที่เปลี่ยนไประหว่างเล่น (ได้/ทิ้ง vip_card)
-- ไม่อัปเดตจนกว่าจะมี event อื่นมา push state ให้บังเอิญ (บั๊กที่เจอ)
local function openUI()
    uiOpen = true
    SetNuiFocus(true, true)
    if latestState then
        SendNUIMessage(latestState) -- โชว์ของเก่าไปก่อนกันจอว่างระหว่างรอ (เดี๋ยว state สดตามมาอัปเดตทับ)
    end
    TriggerServerEvent('lp_welfarelogin:requestState')
end

local function closeUI()
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ── รับ state จาก server (per-player) ──────────────────────────────────────
RegisterNetEvent('lp_welfarelogin:state', function(state)
    latestState = state
    if state.popup then
        openUI()                 -- auto-popup (ถ้าเปิดใช้งาน)
    elseif uiOpen then
        SendNUIMessage(state)    -- refresh ระหว่างเปิดอยู่ (ส่งเฉพาะตอนค่าเปลี่ยน, ข้อ 7)
    end
end)

-- ── เลือกตัวละครเสร็จ → บอก server ให้โหลด cache + เช็ค auto-popup ──────────
RegisterNetEvent('vorp:SelectedCharacter')
AddEventHandler('vorp:SelectedCharacter', function()
    Wait(1500) -- ให้ inventory/character ตั้งตัวก่อน
    TriggerServerEvent('lp_welfarelogin:playerReady')
end)

-- ── เปิดด้วยคำสั่ง /welfare เท่านั้น (RegisterKeyMapping ไม่รองรับใน RedM) ──
-- lp_allmenu หมวด "ล็อคอิน" ตั้ง action = command → welfare จะมาเรียก ExecuteCommand('welfare')
RegisterCommand(Config.Command, function()
    openUI()
end, false)

-- ── NUI callbacks ──────────────────────────────────────────────────────────
RegisterNUICallback('claim', function(data, cb)
    local track = data and data.track
    local day   = data and tonumber(data.day)
    -- ส่งแค่ "คำขอ" — server ตรวจ track/day/สิทธิ์/รางวัลเองทั้งหมด
    if (track == 'free' or track == 'vip') and day then
        TriggerServerEvent('lp_welfarelogin:claim', track, day)
    end
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    closeUI()
    cb('ok')
end)

RegisterNUICallback('ready', function(_, cb)
    cb('ok')
end)

-- ── cleanup (ข้อ 7/12) ─────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
end)
