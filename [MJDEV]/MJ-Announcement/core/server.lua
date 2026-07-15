local VorpCore = exports.vorp_core:GetCore()

local currentAnnouceID = 1

-- เปลี่ยนคำสั่ง 'ac' ให้ใช้ RegisterCommand แทน
RegisterCommand('ac', function(source, args, rawCommand)
    if source == 0 then
        -- server console / txAdmin — เชื่อถือได้อยู่แล้ว ไม่มี xPlayer ให้เช็ค group
        if #args == 0 then return end
        TriggerClientEvent('JKL-annoucement_nui:annouce', -1, table.concat(args, ' '))
        return
    end

    local xUser = VorpCore.getUser(source)
    local xPlayer = xUser and xUser.getUsedCharacter

    -- ตรวจสอบสิทธิ์ผู้ใช้
    if xPlayer and xPlayer.group == 'admin' then
        if #args == 0 then
            TriggerClientEvent('esx:showNotification', source, 'กรุณาใส่ข้อความประกาศ.')
            return
        end
        
        local message = table.concat(args, ' ')
        TriggerClientEvent('JKL-annoucement_nui:annouce', -1, message)
    else
        -- ส่งข้อความแจ้งเตือนเมื่อผู้ใช้ไม่มีสิทธิ์
        TriggerClientEvent('esx:showNotification', source, 'คุณไม่มีสิทธิ์ใช้คำสั่งนี้.')
    end
end, false)


-- คำสั่งรีสตาร์ทเซิร์ฟเวอร์
RegisterCommand('svrestart', function(source, args, rawCommand)
    if source == 0 then
        -- server console / txAdmin — เชื่อถือได้อยู่แล้ว ไม่มี xPlayer ให้เช็ค group
        if args[1] == nil then return end
        local masseg = table.concat(args, ' ')
        TriggerClientEvent('JKL-Announcement:message', -1, 'เซิฟเวอร์จะทำการรีสตาร์ทเวลา  ' .. masseg .. ' น. ขอให้ผู้เล่นดิสออกจากเซิฟเวอร์ด้วยครับ ' )
        return
    end

    local xUser = VorpCore.getUser(source)
    local xPlayer = xUser and xUser.getUsedCharacter
    if xPlayer and xPlayer.group == 'admin' then
        if args[1] == nil then
            return
        end

        local masseg = table.concat(args, ' ')
        TriggerClientEvent('JKL-Announcement:message', -1, 'เซิฟเวอร์จะทำการรีสตาร์ทเวลา  ' .. masseg .. ' น. ขอให้ผู้เล่นดิสออกจากเซิฟเวอร์ด้วยครับ ' )
    end
end, false)

function autoAnnoucement()
    if #Config.Annoucement > 0 then
        local message = Config.Annoucement[currentAnnouceID]
        TriggerClientEvent('JKL-annoucement_nui:annouce', -1, message)

        if currentAnnouceID >= #Config.Annoucement then 
            currentAnnouceID = 1 
        else
            currentAnnouceID = currentAnnouceID + 1
        end

        SetTimeout(Config.AnnouceInterval, autoAnnoucement)
    end
end

SetTimeout(Config.AnnouceInterval, autoAnnoucement)



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