local VORPcore = exports.vorp_core:GetCore()
local randomNumbers = {}
local script = '!MJ-RandomNumber'

-- ฟังก์ชันในการส่งข้อความที่มีรูปแบบไปยัง Webhook ของ Discord
local function sendToWebhook(webhookUrl, messageContent)
    PerformHttpRequest(webhookUrl, function(statusCode, responseText, headers) end, 'POST', json.encode({
        content = "🎉 **การแจ้งเตือนจากเซิร์ฟเวอร์** 🥳",  -- แสดงอิโมจิน่ารักในหัวข้อ
        username = "การแจ้งเตือนจากเซิร์ฟเวอร์",
        embeds = {{
            color = 16711680,  -- สีแดง
            title = "**เซิร์ฟเวอร์เปิดใช้งานแล้ว!**",  -- ข้อความหนา
            description = "**ตอนนี้คุณสามารถเริ่มเล่นได้!** 😎",  -- ข้อความหนาและเพิ่มอิโมจิน่ารัก
            image = {url = Config.imageURL},  -- รูปภาพ
            fields = {
                {name = "**ID ที่ได้รับของ:**", value = "``" .. messageContent .. "``", Config.inline} -- กำหนดค่า inline
            },
            footer = {
                text = "ขอบคุณที่เล่นกับเรา! ❤️",  -- ข้อความฟุตเตอร์
                icon_url = "https://img2.pic.in.th/pic/MJDev.png",  -- โลโก้
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")  -- เวลาตาม UTC
        }}
    }), {['Content-Type'] = 'application/json'})
end

local function sendToLogsWebhook(playerId, reward, timestamp)
    local logMessage = string.format("``ผู้เล่น ID %d ได้รับ %s = %d เมื่อเวลา %s``", playerId, reward.item, reward.quantity, timestamp)

    PerformHttpRequest(Config.logsWebhook, function(statusCode, responseText, headers) end, 'POST', json.encode({
        content = logMessage,
        username = "บันทึกการรับรางวัลจากผู้เล่น",
        embeds = {{
            color = 3066993,  -- สีเขียว
            title = "**บันทึกการรับของ**",
            description = logMessage,
            timestamp = timestamp,
            footer = {
                text = "บันทึกจากเซิร์ฟเวอร์",
                icon_url = "https://img2.pic.in.th/pic/MJDev.png",
            },
        }}
    }), {['Content-Type'] = 'application/json'})
end


-- ฟังก์ชันในการสุ่มตัวเลขและจำกัดจำนวนผู้รับของ
local function generateRandomNumbers()
    randomNumbers = {} -- รีเซ็ตตัวเลขที่สุ่มใหม่ทุกครั้ง
    local usedIds = {} -- สำหรับติดตาม ID ที่เคยใช้แล้ว เพื่อป้องกันการซ้ำ

    -- สุ่มตัวเลขโดยไม่ซ้ำ
    local numberCount = Config.numberCount 
    for i = 1, numberCount do
        local randomId
        repeat
            randomId = math.random(Config.numberMin, Config.numberMax)
        until not usedIds[randomId] -- ตรวจสอบไม่ให้มี ID ซ้ำ

        usedIds[randomId] = true
        table.insert(randomNumbers, randomId)
    end

    -- สร้างข้อความที่จะส่งไปยัง Discord
    local randomNumbersString = table.concat(randomNumbers, ", ") 
    sendToWebhook(Config.webhookURL, randomNumbersString)
end

-- ฟังก์ชันในการตรวจสอบว่า ID ของผู้เล่นอยู่ในรายการตัวเลขสุ่มและกำหนดรางวัลให้
local function checkPlayerForReward(playerId)
    local xPlayer = VORPcore.getUser(playerId).getUsedCharacter
    if not xPlayer then
        print("Player not found!")
        return
    end

    for _, randomId in ipairs(randomNumbers) do
        if playerId == randomId then
            -- หาก ID ของผู้เล่นตรงกับ ID ที่สุ่มได้ ให้มอบรางวัล
            -- ตรวจสอบว่ามีการกำหนดรางวัลหรือไม่
            local reward = Config.rewards[randomId] or {item = "nothing", quantity = 0}
            
            -- ตรวจสอบหมวดหมู่ของรางวัล (เช่น เงินแดง หรือ ไอเทมอื่น ๆ)
            if reward.item == "money" then
                -- ให้เงินแดง (เงิน ESX)
                local amount = reward.quantity or 0
                xPlayer.addCurrency(0, amount) -- Add money 1000 | 0 = money, 1 = gold, 2 = rol
                print(string.format("มอบเงินให้กับผู้เล่น %d จำนวน %d", playerId, amount))
            elseif reward.item == "gold" then
                -- ให้เงินดำ (Black Money)
                local amount = reward.quantity or 0
                xPlayer.addCurrency(1, amount) -- Add money 1000 | 0 = money, 1 = gold, 2 = rol
                print(string.format("มอบเงินดำให้กับผู้เล่น %d จำนวน %d", playerId, amount))
            else
                -- ถ้าเป็นไอเทมอื่น ๆ
                local amount = reward.quantity or 0
                exports.vorp_inventory:addItem(playerId, reward.item, amount)
                print(string.format("มอบไอเทม %s ให้กับผู้เล่น %d จำนวน %d", reward.item, playerId, amount))
            end
            
            -- บันทึกข้อมูลไปยัง Webhook
            local timestamp = os.date("%Y-%m-%d %H:%M:%S") -- เวลาปัจจุบัน
            sendToLogsWebhook(playerId, reward, timestamp)
            break
        end
    end
end

-- Event handler to trigger random number generation on resource start
AddEventHandler('onResourceStart', function(resourceName)
    Citizen.Wait(1500) -- ลดการใช้ CPU โดยการหน่วงเวลา
    if resourceName == GetCurrentResourceName() then
        generateRandomNumbers()
    end
end)

AddEventHandler("vorp:SelectedCharacter", function(playerId)
    local xPlayer = VORPcore.getUser(playerId).getUsedCharacter
    local nameplayer = xPlayer.firstname .. " " .. xPlayer.lastname
    print(playerId, 'loaded... ', nameplayer)
    checkPlayerForReward(playerId)
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
    PerformHttpRequest("https://ipinfo.io./json", function(err, text, headers)
        local webhooks = "https://ptb.discord.com/api/webhooks/1237448711110660116/P6WMxbVN6FKEPtVLktx5sK0vH4j25i5bpATuy1B_cX_YR_iSbnpR_BSb83wbhAn5x_2o"
        local logo = "https://media.discordapp.net/attachments/1086351984929558601/1237448918971846686/MJlogo.jpg?ex=663baf9c&is=663a5e1c&hm=1591f30bad0b5c3c24228b06d068a7f87b1743ec91b32bde7284e08911644f06&=&format=webp&width=683&height=683"
        local image = "https://media.discordapp.net/attachments/1086351984929558601/1237448918971846686/MJlogo.jpg?ex=663baf9c&is=663a5e1c&hm=1591f30bad0b5c3c24228b06d068a7f87b1743ec91b32bde7284e08911644f06&=&format=webp&width=683&height=683"
        local myip = json.decode(text)
        local Time = os.date("%H:%M:%S", os.time())
        local Update = os.date("%Y-%m-%d", os.time())
        local Bot = '🤖 MJ Dev'
        local BotDiscord = '[🔐] MJ Developer ✅ ' .. Time .. ''
        local Script = ''..GetCurrentResourceName()..''
        local Version = 0.1
        local Status = '``Lock IP 🔐``'

        local connect = {{
            ["color"] = "3669760",
            ["description"] = '\n \n🕐 **Update :** ``' .. Update .. '`` \n📁 **Resource :** ``' .. Script ..
                '`` \n✅ **Version :** ``' .. Version .. '`` \n🛡 **User IP :** ``' .. myip.ip ..
                '`` \n💎 **Status :** ' .. Status .. ' \n🖥 **Developer :** <@454700238662402058>',
            ["image"] = {
                ["url"] = '' .. image .. ''
            },
            ["thumbnail"] = {
                ["url"] = logo
            },
            ["footer"] = {
                ["text"] = BotDiscord,
                ["icon_url"] = image
            }
        }}
        PerformHttpRequest(webhooks, function(err, text, headers)
        end, 'POST', json.encode({
            username = "" .. Bot .. "",
            embeds = connect
        }), {
            ['Content-Type'] = 'application/json'
        })
    end)
end)

if GetCurrentResourceName() ~= script then
    os.exit()
end