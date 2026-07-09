local VORPcore = exports.vorp_core:GetCore()
Config.RandomCodes = {}
local isAdminFlag = false

local function isAdmin()
    return isAdminFlag
end

RegisterNetEvent("openCodeUI")
AddEventHandler("openCodeUI", function(isAdminPlayer)
    isAdminFlag = isAdminPlayer -- <== ตั้งค่าตรงนี้

    if isAdminPlayer then
        SetNuiFocus(true, true)
        SendNUIMessage({ type = "openAdminUI" })
    else
        SetNuiFocus(true, true)
        SendNUIMessage({ type = "openPlayerUI" })
    end
end)

-- คำสั่งเปิด UI สำหรับ Player
RegisterCommand(Config.PlayerCommand, function(source, args, rawCommand)
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "openPlayerUI"
    })
end, false)

-- ฟังก์ชันรับโค้ดจาก UI และส่งไปเช็คที่ Server
RegisterNUICallback("redeemCode", function(data, cb)
    local code = data.code
    TriggerServerEvent("redeemRewardCode", code)
    cb({ success = false }) -- ไม่ปิด UI ก่อน รอผลจาก server
end)

-- รับผลจาก server แสดง notify แล้วปิด UI ถ้าสำเร็จ
RegisterNetEvent("redeemCodeResult")
AddEventHandler("redeemCodeResult", function(success, message)
    if success then
        SendNUIMessage({ type = "closePlayerUI" })
        SetNuiFocus(false, false)
        Citizen.Wait(150)
    end
    exports.pNotify:SendNotification({
        text    = message,
        type    = success and 'success' or 'error',
        timeout = 4000,
    })
end)


-- ฟังก์ชันสุ่มโค้ดจาก UI
RegisterNUICallback("getRandomCode", function(data, cb)
    if not isAdmin() then
        cb({ success = false })
        return
    end

    local code = data.newCode
    print("Received code from NUI:", code)

    if Config.RandomCodes[code] == nil then
        Config.RandomCodes[code] = true
        TriggerServerEvent("getRandomRewardCode", code)
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

-- ปิด UI เมื่อกดปุ่ม ESC
RegisterNUICallback("closeCode", function(data, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

-- ทำความสะอาดเมื่อ resource ถูกปิด
AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        SetNuiFocus(false, false)
    end
end)
