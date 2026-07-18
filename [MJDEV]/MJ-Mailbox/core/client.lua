local VORPcore = exports.vorp_core:GetCore()
local mailboxOpen = false
local targetBlip = nil
local targetCoords = nil
local blipThreadRunning = false

RegisterCommand("openmailbox", function()
    mailboxOpen = not mailboxOpen
    SetNuiFocus(mailboxOpen, mailboxOpen) -- เปิดหรือปิดโฟกัสเมาส์และคีย์บอร์ด
    SendNUIMessage({
        action = "showUI",
        show = mailboxOpen
    })
    if mailboxOpen then
        -- เรียกขอข้อมูลจาก server
        TriggerServerEvent("mailbox:getUserInfo")
        TriggerServerEvent("mailbox:loadMessages") 
        TriggerServerEvent("mailbox:getMyContacts")
    end
end)

RegisterNUICallback("addContact", function(data, cb)
    local name = data.name
    local contactId = data.contactId

    TriggerServerEvent("mailbox:saveContact", name, contactId)
    cb({ status = "ok" })
end)


RegisterNUICallback("getPlayerCoords", function(_, cb)
    local ped = PlayerPedId()
    if ped and ped ~= 0 then
        local coords = GetEntityCoords(ped)
        local formatted = string.format("X:%.2f Y:%.2f Z:%.2f", coords.x, coords.y, coords.z)
        SendNUIMessage({
            action = "setCoords",
            coords = formatted
        })
    else
        SendNUIMessage({
            action = "setCoords",
            coords = "ไม่พบตำแหน่ง"
        })
    end
    cb("ok")
end)

RegisterNUICallback("getPlayerItems", function(_, cb)
    local inventory = exports.vorp_inventory:getInventoryItems()
    local items = {}
    for _, item in pairs(inventory) do
        table.insert(items, {
            name = item.name,
            label = item.label,
            count = item.count
        })
    end

    SendNUIMessage({
        action = "showItems",
        items = items
    })
    cb("ok")
end)

RegisterNUICallback("sendMessage", function(data, cb)
    local receiverId = data.receiverId
    local receiverName = data.receiverName
    local message = data.message

    if (not receiverId or receiverId == "") and (not receiverName or receiverName == "") then
        cb({
            status = "error",
            error = "กรุณากรอก ID หรือ ชื่อผู้รับ"
        })
        return
    end

    if not message or message == "" then
        cb({
            status = "error",
            error = "กรุณากรอกข้อความ"
        })
        return
    end

    -- ส่งข้อมูลดิบๆ ไปให้ server จัดการ
    TriggerServerEvent("mailbox:sendMessage", {
        receiverId = receiverId,
        receiverName = receiverName,
        message = message,
        mailID = receiverId or "",
        subject = data.subject or "",
        coords = data.coords,
        item = data.item
    })

    TriggerServerEvent("mailbox:loadMessages") 
    cb({
        status = "ok"
    })
end)

RegisterNUICallback("markAsRead", function(data, cb)
    local messageId = data.messageId
    local unreadCount = data.unreadCount
    -- TriggerServerEvent("mailbox:markAsRead", messageId)
    TriggerServerEvent("mailbox:markAsRead", messageId, unreadCount)

    cb({ status = true })
end)

RegisterNUICallback("deleteMessage", function(data, cb)
    local id = data.id
    TriggerServerEvent("mailbox:deleteMessage", id)
    cb({
        status = "ok"
    })
end)

RegisterNUICallback("sendCoords", function(data, cb)
    local coords = data.coords
    if not coords or not coords.x or not coords.y or not coords.z then
        print("Invalid coordinates")
        cb({ success = false, message = "Invalid coordinates" })
        return
    end

    -- ลบ blip เดิม (ถ้ามี)
    if targetBlip then
        RemoveBlip(targetBlip)
        targetBlip = nil
    end

    -- ตั้ง blip ใหม่
    targetBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, coords.x, coords.y, coords.z)
    SetBlipSprite(targetBlip, 1001245999, true)
    SetBlipScale(targetBlip, 0.1)
    Citizen.InvokeNative(0x9CB1A1623062F402, targetBlip, 'My Friend')

    -- ตั้ง waypoint
    StartGpsMultiRoute(GetHashKey("COLOR_RED"), true, true)
    MJDEV = AddPointToGpsMultiRoute(coords.x, coords.y, coords.z)
    SetGpsMultiRouteRender(true)
    -- เก็บค่าพิกัดเพื่อใช้ตรวจสอบ
    targetCoords = coords

    -- เริ่มเธรดเช็คระยะ
    if not blipThreadRunning then
        blipThreadRunning = true
        Citizen.CreateThread(function()
            while targetBlip do
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)

                local distance = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, targetCoords.x, targetCoords.y,
                    targetCoords.z)

                if distance < 10.0 then -- ระยะที่ถือว่า "ถึง"
                    if blipThreadRunning then
                        RemoveBlip(targetBlip)
                        SetGpsMultiRouteRender(false)
                        targetBlip = nil
                        targetCoords = nil
                        blipThreadRunning = false
                    end
                    break
                end

                Wait(1000) -- เช็คทุก 1 วินาที
            end
            blipThreadRunning = false
        end)
    end
    if coords then
        TriggerEvent("pNotify:SendNotification", {
            text = "ตั้ง waypoint ที่: " .. coords.x .. ", " .. coords.y,
            type = "success",
            timeout = 2000,
            layout = "topRight"
        })
    else
        TriggerEvent("pNotify:SendNotification", {
            text = "ได้รับจดหมายใหม่!",
            type = "success",
            timeout = 2000,
            layout = "topRight"
        })
    end
    cb({
        success = true
    })
end)

-- รับข้อมูลรายชื่อจาก Server และส่งให้ UI
RegisterNetEvent("mailbox:sendMyContacts")
AddEventHandler("mailbox:sendMyContacts", function(contacts)
    SendNUIMessage({
        action = "loadContacts",
        contacts = contacts
    })
end)

RegisterNetEvent("mailbox:receiveUserInfo")
AddEventHandler("mailbox:receiveUserInfo", function(data)
    SendNUIMessage({
        action = "receiveUserInfo",
        firstname = data.firstname,
        mailCode = data.mailCode
    })
end)

RegisterNetEvent("mailbox:loadMessagesResult")
AddEventHandler("mailbox:loadMessagesResult", function(messages)
    -- ส่งข้อความแบบแบน ๆ (array ของ messages)
    -- print(DumpTable(messages))
    SendNUIMessage({
        action = "loadMessages",
        messages = messages
    })

end)

RegisterNetEvent("mailbox:newMailNotify")
AddEventHandler("mailbox:newMailNotify", function(count)
    print(count)
    SendNUIMessage({
        action = "showMailIcon",
        count = count
    })
end)

RegisterNetEvent("mailbox:notify")
AddEventHandler("mailbox:notify", function(message)
    TriggerEvent("pNotify:SendNotification", {
        text = message,
        type = "success",
        timeout = 2000,
        layout = "topRight"
    })
end)


RegisterNUICallback("closeUI", function(data, cb)
    mailboxOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "showUI",
        show = false
    })
    cb("ok")
end)

-- ทำความสะอาดเมื่อ resource ถูกปิด
AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        SetNuiFocus(false, false)
        RemoveBlip(targetBlip)
        SetGpsMultiRouteRender(false)
        mailboxOpen = false
        targetBlip = nil
        targetCoords = nil
    end
end)

function DumpTable(tbl, depth)
    depth = depth or 0
    if depth > 5 then
        return "{...}"
    end -- Prevent infinite recursion

    if type(tbl) == "table" then
        local s = "{\n"
        local indent = string.rep("    ", depth + 1)

        for k, v in pairs(tbl) do
            local key = type(k) == "number" and k or '"' .. tostring(k) .. '"'
            s = s .. indent .. "[" .. key .. "] = " .. DumpTable(v, depth + 1) .. ",\n"
        end

        return s .. string.rep("    ", depth) .. "}"
    else
        return tostring(tbl)
    end
end
