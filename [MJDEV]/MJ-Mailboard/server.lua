local VORPcore = exports.vorp_core:GetCore()

-- สร้างประกาศใหม่
RegisterServerEvent("mailboard:createPost")
AddEventHandler("mailboard:createPost", function(text, image)
    local src = source
    local xPlayer = VORPcore.getUser(src).getUsedCharacter
    local time = os.time()

    if not text or text == "" then
        return -- ไม่ต้องสร้างโพสต์ว่าง
    end

    MySQL.Async.execute(
        'INSERT INTO mailboard_posts (identifier, charname, text, image, time) VALUES (?, ?, ?, ?, ?)',
        {xPlayer.identifier, xPlayer.firstname .. " " .. xPlayer.lastname, text, image or "", time}
    )
end)

-- ดึงโพสต์ทั้งหมด (ให้ client โหลด)
RegisterServerEvent("mailboard:getAll")
AddEventHandler("mailboard:getAll", function()
    local src = source
    local xPlayer = VORPcore.getUser(src).getUsedCharacter

    MySQL.Async.fetchAll('SELECT * FROM mailboard_posts ORDER BY time DESC', {}, function(posts)
        TriggerClientEvent("mailboard:receiveAll", src, posts, xPlayer.identifier)
    end)
end)

-- ลบโพสต์ (เฉพาะของตัวเอง)
RegisterServerEvent("mailboard:deletePost")
AddEventHandler("mailboard:deletePost", function(postId)
    local src = source
    local xPlayer = VORPcore.getUser(src).getUsedCharacter

    if not postId then return end

    MySQL.Async.execute(
        'DELETE FROM mailboard_posts WHERE id = ? AND identifier = ?',
        {postId, xPlayer.identifier}
    )
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
