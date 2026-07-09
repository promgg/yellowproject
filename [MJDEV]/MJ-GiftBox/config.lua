Config = {}

Config['Framework'] = exports.vorp_core:GetCore()

Config['Debug'] = false -- เช็คค่าตัวแปรต่างๆ แนะนำ false ไว้

Config["Discord"] = {
    Logo = '',
    Webhook = '',
    Enable = true, -- สำหรับกำหนดใช้ Log จาก Log อื่นๆที่ใช้เช่น azael_discordlogs
    DiscordLog = function(sendToDiscord, source)
        -- TriggerEvent('azael_discordlogs:sendToDiscord', 'GIFTBOX', sendToDiscord, source, '^2')	
    end
}

-- 1. type = item = ไอเทม, money = เงินเขียว, gold = ทอง, horse = ม้า, weapon = อาวุธ
-- 2. item = ชื่อไอเทม, เงิน, ม้า
-- 3. amount = จำนวน
-- 4. percent = เปอร์เซ็นต์
-- 5. usebox = Item กล่องเพื่อกดเปิด
-- 6. remove = จำนวน Item ที่โดนลบออกจากตัวตอนเปิดกล่อง

Config['ItemBox'] = {
    [1] = { -- BoxSet #2
        usebox = 'news_box',
        remove = 1,
        GiveItem = {
            { type = 'item', item = 'lumber', amount = 100, percent = 100 }, -- 100% ได้ไม้ 100 ชิ้น
            { type = 'money', item = 'money', amount = 1000000, percent = 100 }, -- 100% ได้เงิน 1,000,000
            { type = 'gold', item = 'gold', amount = 1000000, percent = 100 }, -- 100% ได้เงินแดง 1,000,000
            { type = 'horse', item = 'a_c_horse_americanpaint_overo', name = 'MJDEV', gender = 'male', percent = 100 }, -- 100% ได้ม้า T20
            { type = 'weapon', item = 'weapon_machete', amount = 1, percent = 100 }, -- 100% ได้อาวุธ machete
        }
    },
    -- [2] = { -- BoxSet #1
    --     usebox = 'Box1',
    --     remove = 1,
    --     GiveItem = {
    --         { type = 'item', item = 'cement', amount = 100, percent = 100 }, -- 100% ได้ปูน 100 ชิ้น
    --     }
    -- },
    -- [3] = { -- BoxSet #3
    --     usebox = 'Box3',
    --     remove = 1,
    --     GiveItem = {
    --         { type = 'item', item = 'copper_wire', amount = 50, percent = 75 }, -- 75% ได้สายไฟ 50 ชิ้น
    --         { type = 'weapon', item = 'weapon_knife', amount = 1, percent = 50 }, -- 50% ได้อาวุธมีด
    --     }
    -- },
}
