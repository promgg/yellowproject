local VorpCore = exports.vorp_core:GetCore()

local currentAnnouceID = 1

-- ── ACE permission สำหรับคำสั่งประกาศ ────────────────────────────────────────
-- เรียงลำดับตามที่ MJ-Airdrop/core/server.lua ทำ: console -> ACE -> group
-- ACE มาก่อนเพราะให้สิทธิ์เฉพาะคำสั่งนี้ได้โดยไม่ต้องยกคนขึ้นเป็น admin ทั้งระบบ
--   add_ace group.admin MJ-Announcement.admin allow   (ตั้งไว้ใน server.cfg แล้ว)
local ADMIN_ACE    = 'MJ-Announcement.admin'
local ADMIN_GROUPS = { superadmin = true, admin = true }

local function normalizeGroup(value)
    return tostring(value or ''):lower():gsub('%s+', '')
end

local function isAdmin(source)
    if source == 0 then return true end -- server console / txAdmin สั่งได้เสมอ

    if IsPlayerAceAllowed(source, ADMIN_ACE) then return true end

    local xUser = VorpCore.getUser(source)
    if not xUser then return false end

    -- VORP มี "group" อยู่สองที่คนละตารางกัน (users ระดับบัญชี / characters ระดับตัวละคร)
    -- อ่านทั้งสองที่ ตั้งไว้ที่ไหนก็ผ่าน — เดิมเช็คแค่ xPlayer.group (characters) จุดเดียว
    if ADMIN_GROUPS[normalizeGroup(xUser.getGroup)] then return true end

    local xPlayer = xUser.getUsedCharacter
    if xPlayer and ADMIN_GROUPS[normalizeGroup(xPlayer.group)] then return true end

    return false
end

-- เปลี่ยนคำสั่ง 'ac' ให้ใช้ RegisterCommand แทน
RegisterCommand('ac', function(source, args, rawCommand)
    if not isAdmin(source) then
        if source ~= 0 then
            TriggerClientEvent('esx:showNotification', source, 'คุณไม่มีสิทธิ์ใช้คำสั่งนี้.')
        end
        return
    end

    if #args == 0 then
        if source ~= 0 then
            TriggerClientEvent('esx:showNotification', source, 'กรุณาใส่ข้อความประกาศ.')
        end
        return
    end

    local message = table.concat(args, ' ')
    TriggerClientEvent('JKL-annoucement_nui:annouce', -1, message)
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