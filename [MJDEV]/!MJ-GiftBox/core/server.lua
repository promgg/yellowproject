local Core = Config['Framework']
local script_name = '!MJ-GiftBox'
-- ลงทะเบียนไอเทมที่สามาม้าใช้ได้
for boxID, boxData in pairs(Config['ItemBox']) do
    exports.vorp_inventory:registerUsableItem(boxData.usebox, function(data)
        TriggerEvent('giftbox:useBox', data.source, boxData.usebox)
    end)
end

-- ฟังก์ชันเมื่อกดใช้ไอเทมกล่อง
RegisterServerEvent('giftbox:useBox')
AddEventHandler('giftbox:useBox', function(source, boxName)
    local User = Core.getUser(source)
    if not User then return end
    local xPlayer = User.getUsedCharacter
    local boxConfig = {}

    -- ใช้ for loop เพื่อค้นหา Config ของกล่องที่ตรงกับชื่อกล่อง
    for _, box in pairs(Config['ItemBox']) do
        if box.usebox == boxName then
            boxConfig = box
            break
        end
    end

    if not boxConfig then
        if Config['Debug'] then
            print(('[DEBUG] กล่อง %s ไม่พบใน Config!'):format(boxName))
        end
        return
    end

    -- ตรวจสอบว่าผู้เล่นมีกล่องเพียงพอหรือไม่
    exports.vorp_inventory:subItem(source, boxName, 1)

    -- ใช้ for loop เพื่อประมวลผลของรางวัลในแต่ละกล่อง
    for _, reward in pairs(boxConfig.GiveItem) do
        local randomPercent = math.random(1, 100)
        if randomPercent <= reward.percent then
            if reward.type == 'item' then
                exports.vorp_inventory:addItem(source, reward.item, reward.amount)
                TriggerClientEvent("pNotify:SendNotification", source, {
                    text = ('คุณได้รับ %d %s!'):format(reward.amount, reward.item),
                    type = "success",
                    timeout = 3000,
                    layout = "topRight",
                    queue = "global"
                })
            elseif reward.type == 'money' then
                xPlayer.addCurrency(0, reward.amount)
                TriggerClientEvent("pNotify:SendNotification", source, {
                    text = ('คุณได้รับ $%d!'):format(reward.amount),
                    type = "success",
                    timeout = 3000,
                    layout = "topRight",
                    queue = "global"
                })
            elseif reward.type == 'gold' then
                xPlayer.addCurrency(1, reward.amount)
                TriggerClientEvent("pNotify:SendNotification", source, {
                    text = ('คุณได้รับ $%d เงินแดง!'):format(reward.amount),
                    type = "success",
                    timeout = 3000,
                    layout = "topRight",
                    queue = "global"
                })
            elseif reward.type == 'Horse' then
                TriggerEvent('giftbox:giveHorse', source, reward.item, reward.name, reward.gender)
                TriggerClientEvent("pNotify:SendNotification", source, {
                    text = ('คุณได้รับ ม้า %s!'):format(reward.item),
                    type = "success",
                    timeout = 3000,
                    layout = "topRight",
                    queue = "global"
                })
            elseif reward.type == 'weapon' then
                local canCarryWep = exports.vorp_inventory:canCarryWeapons(source, 1, nil, reward.item) --can carry weapons
                if not canCarryWep then
                    TriggerClientEvent("pNotify:SendNotification", source, {
                        text = ('คุณมี อาวุธ %s อยุ่แล้ว!'):format(reward.item),
                        type = "success",
                        timeout = 3000,
                        layout = "topRight",
                        queue = "global"
                    })
                    return 
                end
                exports.vorp_inventory:createWeapon(source, reward.item)
                TriggerClientEvent("pNotify:SendNotification", source, {
                    text = ('คุณได้รับ อาวุธ %s!'):format(reward.item),
                    type = "success",
                    timeout = 3000,
                    layout = "topRight",
                    queue = "global"
                })
            end
        end
    end

    -- Log ไปยัง Discord (ถ้าตั้งค่าไว้)
    if Config["Discord"].Enable then
        local logMessage = ('ผู้เล่น %s (#%d) ใช้กล่อง %s และได้รับของรางวัล'):format(xPlayer.getName(), source, boxName)
        MJDEV.DiscordLog(logMessage, source)
    else
        local logMessage = ('ผู้เล่น %s (#%d) ใช้กล่อง %s และได้รับของรางวัล'):format(xPlayer.getName(), source, boxName)
        Config["Discord"].DiscordLog(logMessage, source)
    end
    
end)

-- ฟังก์ชันสำหรับให้ม้า (ต้องเชื่อมต่อกับระบบ Garage หรือ Horse)
RegisterServerEvent('giftbox:giveHorse')
AddEventHandler('giftbox:giveHorse', function(source, model, name, gender)
    local User = Core.getUser(source)
    if not User then return end
    local xPlayer = User.getUsedCharacter
    local MJDATA = {
        NameH = name,
        ModelH = model,
        GenderH = gender
    }
    -- บันทึกม้าเข้าในฐานข้อมูล
    MJDEV.HorseSQL(source, xPlayer, MJDATA)

    -- แจ้งเตือนผู้เล่น
    if Config.Debug then
        print(('[DEBUG] ผู้เล่น %s (#%d) ได้รับม้า %s ป้ายทะเบียน %s'):format(xPlayer.getName(), source, HorseName, plate))
    end    
end)

if GetCurrentResourceName() ~= script_name then
    os.exit()
end