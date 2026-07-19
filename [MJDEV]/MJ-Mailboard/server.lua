local VORPcore = exports.vorp_core:GetCore()

local function notify(src, msg, kind)
    TriggerClientEvent("pNotify:SendNotification", src, {
        text = msg, type = kind or "error", timeout = 4000, layout = "topRight" })
end

-- เวลาที่ประกาศเก่ากว่านี้ถือว่าหมดอายุ (คืน nil ถ้าตั้ง PostExpireDays = 0 คือไม่หมดอายุ)
local function expiryCutoff()
    local days = tonumber(Config.PostExpireDays) or 0
    if days <= 0 then return nil end
    return os.time() - (days * 86400)
end

-- กันสแปม: NUI เช็ค 10 วิให้แล้ว แต่ผู้เล่นยิง event ตรงข้าม NUI ได้ ต้องกันที่ server ด้วย
local postCooldown = {}
AddEventHandler('playerDropped', function() postCooldown[source] = nil end)

-- สร้างประกาศใหม่
RegisterServerEvent("mailboard:createPost")
AddEventHandler("mailboard:createPost", function(text, image)
    local src = source
    local user = VORPcore.getUser(src)
    local xPlayer = user and user.getUsedCharacter
    if not xPlayer then return end

    if type(text) ~= "string" then return end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return end

    -- เดิมไม่จำกัดความยาว ยัดข้อความเป็นล้านตัวอักษรลง DB ได้
    local maxLen = tonumber(Config.MaxPostLength) or 500
    if #text > maxLen then
        notify(src, ("ข้อความยาวเกินไป (สูงสุด %d ตัวอักษร)"):format(maxLen))
        return
    end

    image = type(image) == "string" and image or ""
    if #image > 500 then image = "" end

    local cd = tonumber(Config.PostCooldown) or 0
    if cd > 0 then
        local now = GetGameTimer()
        if postCooldown[src] and now < postCooldown[src] then
            notify(src, "กรุณารอสักครู่ก่อนลงประกาศใหม่")
            return
        end
        postCooldown[src] = now + (cd * 1000)
    end

    local price = math.floor(tonumber(Config.PostPrice) or 0)
    if price > 0 then
        -- เช็คเงินก่อนหัก ไม่งั้น removeCurrency อาจทำให้ติดลบ
        if (tonumber(xPlayer.money) or 0) < price then
            notify(src, ("เงินไม่พอ ค่าลงประกาศ $%d"):format(price))
            return
        end
        xPlayer.removeCurrency(0, price)
    end

    MySQL.Async.execute(
        'INSERT INTO mailboard_posts (identifier, charname, text, image, time) VALUES (?, ?, ?, ?, ?)',
        { xPlayer.identifier, (xPlayer.firstname or "") .. " " .. (xPlayer.lastname or ""), text, image, os.time() },
        function(affected)
            if affected and affected > 0 then
                if price > 0 then
                    notify(src, ("ลงประกาศแล้ว (หัก $%d)"):format(price), "success")
                else
                    notify(src, "ลงประกาศแล้ว", "success")
                end
            else
                -- บันทึกไม่สำเร็จแต่หักเงินไปแล้ว ต้องคืนให้ ไม่งั้นผู้เล่นเสียเงินฟรี
                if price > 0 then
                    xPlayer.addCurrency(0, price)
                    notify(src, "ลงประกาศไม่สำเร็จ คืนเงินให้แล้ว")
                else
                    notify(src, "ลงประกาศไม่สำเร็จ")
                end
                print(("^1[MJ-Mailboard]^7 INSERT ล้มเหลว ผู้เล่น %s"):format(GetPlayerName(src) or src))
            end
        end
    )
end)

-- ดึงโพสต์ทั้งหมด (ให้ client โหลด)
RegisterServerEvent("mailboard:getAll")
AddEventHandler("mailboard:getAll", function()
    local src = source
    local xPlayer = VORPcore.getUser(src).getUsedCharacter

    -- กรองประกาศหมดอายุออกตั้งแต่ตอนอ่าน ไม่ต้องรอ thread เก็บกวาดรอบถัดไป
    -- (ถ้าพึ่ง thread อย่างเดียว ประกาศที่เพิ่งหมดอายุจะยังโผล่ให้เห็นได้อีกถึง 1 ชั่วโมง)
    local cutoff = expiryCutoff()
    local sql, params
    if cutoff then
        sql, params = 'SELECT * FROM mailboard_posts WHERE time >= ? ORDER BY time DESC', { cutoff }
    else
        sql, params = 'SELECT * FROM mailboard_posts ORDER BY time DESC', {}
    end

    MySQL.Async.fetchAll(sql, params, function(posts)
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



-- ลบประกาศหมดอายุออกจาก DB (กรองตอนอ่านอย่างเดียวไม่พอ แถวเก่าจะค้างสะสมไปเรื่อยๆ)
Citizen.CreateThread(function()
    while true do
        local cutoff = expiryCutoff()
        if cutoff then
            MySQL.Async.execute('DELETE FROM mailboard_posts WHERE time < ?', { cutoff }, function(affected)
                if affected and affected > 0 then
                    print(("^3[MJ-Mailboard]^7 ลบประกาศหมดอายุ %d รายการ (เกิน %d วัน)")
                        :format(affected, Config.PostExpireDays))
                end
            end)
        end
        Citizen.Wait(3600000) -- ทุก 1 ชั่วโมง
    end
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
