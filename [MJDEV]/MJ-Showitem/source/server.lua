script  = GetCurrentResourceName()


function Notification(source, data)
    TriggerClientEvent(script..':Notification', source, data)
end

exports('Notification', Notification)

RegisterCommand('NotifySV', function()

    exports['MJ-Showitem']:Notification(-1, {
        position = 'middleRight',
        image ='giphy.gif',
        title ='test',
        description ='sssss',
        type ='success',
        time = 5000,
    })
    exports['MJ-Showitem']:Notification(-1, {
        position = 'middleRight',
        image ='giphy.gif',
        title ='test',
        description ='sssss',
        type ='alert',
        time = 5000,
    })
    exports['MJ-Showitem']:Notification(-1, {
        position = 'middleRight',
        image ='EXP.png',
        title ='test',
        description ='sssss',
        type ='warning',
        time = 5000,
    })
    exports['MJ-Showitem']:Notification(-1, {
        position = 'middleRight',
        image ='EXP.png',
        title ='test',
        description ='sssss',
        type ='info',
        time = 5000,
    })
end)


AddEventHandler('vorp:addMoney', function(player, typeCash, quantity)
    exports['MJ-Showitem']:Notification(player, {
        position = 'middleRight', -- เลือกตำแหน่ง topLeft, topCenter, topRight, middleLeft, middleCenter, middleRight, bottomLeft, bottomCenter, bottomRight
        image = 'money', -- ใส่ชื่อไอเทมหรือชื้อไพล์ภาพใน image ต้องมีนามสกุนไพล์ตามหลัง
        title ='คุณได้รับ เงิน', -- ข้อความแรก
        description ='+ '.. quantity, -- ข้อความสอง
        type ='success',-- type มี 4 type   success, alert, warning, info
        time = 4000, -- ใส่เวลา
    })
end)

AddEventHandler('vorp:removeMoney', function(player, typeCash, quantity)
    exports['MJ-Showitem']:Notification(player, {
		position = 'middleRight', -- เลือกตำแหน่ง topLeft, topCenter, topRight, middleLeft, middleCenter, middleRight, bottomLeft, bottomCenter, bottomRight
		image = 'money', -- ใส่ชื่อไอเทมหรือชื้อไพล์ภาพใน image ต้องมีนามสกุนไพล์ตามหลัง
		title ='คุณสูญเสีย เงิน', -- ข้อความแรก
		description ='- '.. quantity, -- ข้อความสอง
		type ='warning',-- type มี 4 type   success, alert, warning, info
		time = 4000, -- ใส่เวลา
	})
end)


Citizen.CreateThread(function()
    Citizen.Wait(5000) 
    print("##################################################")
    print("##                                              ##")
    print("##           \27[37mMJ DEV | Verify \27[32mSuccess\27[0m            ##")
    print("##           \27[36mThank You For Purchase\27[0m             ##")
    print("##           \27[34mVersion : 1.0 (Latest)\27[0m             ##")
    print("##                                              ##")
    print("##################################################")
    print("###### \27[36mDiscord: https://discord.gg/gHRNMDQKzb\27[0m ####")
end)