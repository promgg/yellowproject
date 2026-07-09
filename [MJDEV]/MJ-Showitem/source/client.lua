script  = GetCurrentResourceName()

RegisterNetEvent(script..':Notification')
AddEventHandler(script..':Notification', function(data)
	Notification(data)
end)

-- RegisterNetEvent('vorpCoreClient:addItem', function(item)
--     -- print(DumpTable(item))
--     if item ~= nil then
--         exports['MJ-Showitem']:Notification({
--             position = 'middleRight',
--             image = item.name,
--             title = 'คุณได้รับ Item',
--             description = '+ '.. item.label,
--             type = 'alert',
--             time = 5000
--         })
--     end
-- end)


function Notification(data)
    SendNUIMessage(data)
end

exports('Notification', Notification)

RegisterCommand('NotifyCL', function()
    --[[
        exports['MJ-Showitem']:Notification({
            position = 'middleRight', เลือกตำแหน่ง topLeft, topCenter, topRight, middleLeft, middleCenter, middleRight, bottomLeft, bottomCenter, bottomRight
            image ='giphy.gif', ใส่ชื่อไอเทมหรือชื้อไพล์ภาพใน image ต้องมีนามสกุนไพล์ตามหลัง
            title ='test', ข้อความแรก
            description ='sssss', ข้อความสอง
            type ='success', type มี 4 type   success, alert, warning, info
            time = 5000, ใส่เวลา
        })
    ]]

    exports['MJ-Showitem']:Notification({
        position = 'middleRight',
        image ='giphy.gif',
        title ='test',
        description ='sssss',
        type ='success',
        time = 5000,
    })
    exports['MJ-Showitem']:Notification({
        position = 'middleRight',
        image ='giphy.gif',
        title ='test',
        description ='sssss',
        type ='alert',
        time = 5000,
    })
    exports['MJ-Showitem']:Notification({
        position = 'middleRight',
        image ='EXP.png',
        title ='test',
        description ='sssss',
        type ='warning',
        time = 5000,
    })
    exports['MJ-Showitem']:Notification({
        position = 'middleRight',
        image ='EXP.png',
        title ='test',
        description ='sssss',
        type ='info',
        time = 5000,
    })
end)
