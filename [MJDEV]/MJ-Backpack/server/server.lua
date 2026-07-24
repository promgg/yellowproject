local VORPcore = exports.vorp_core:GetCore()

-- vorp_inventory ไม่มี re-entrancy guard ในเส้น UseItem (registerUsableItem callback ยิงทันทีทุกคลิก)
-- + callback นี้มี Wait(1000) คั่นระหว่างเช็คกับ sub/add — กดไอเทม BuyItem รัวๆ callback ยิงซ้อนกัน
-- ทั้งคู่ผ่าน canCarry, wait, แล้ว addItem BackpackItem = ได้กระเป๋าซ้ำจากไอเทมซื้อใบเดียว (ยืนยันเจอจริง)
-- กันด้วย busy flag ต่อคน ครอบช่วง Wait จนจบธุรกรรม
local activeBuy = {} -- [src] = true ระหว่างกำลังแปลง BuyItem -> BackpackItem

AddEventHandler('playerDropped', function()
    if source then activeBuy[source] = nil end
end)

-- Loop for registering usable items
for _, backpack in ipairs(Config.Backpacks) do
    exports.vorp_inventory:registerUsableItem(backpack.BuyItem, function(data)
        local src = data.source

        if activeBuy[src] then return end -- กำลังแปลงใบก่อนอยู่ กันกดซ้ำ -> ได้กระเป๋าซ้ำ

        -- เช็คว่าผู้เล่นสามารถถือ Backpack ได้ไหม
        local CanCarry = exports.vorp_inventory:canCarryItem(src, backpack.BackpackItem, 1)
        if CanCarry then
            activeBuy[src] = true

            -- re-check ว่ายังมี BuyItem จริงก่อนแปลง (กันเคสใบถูกหักไปแล้วจาก callback ที่ยิงก่อนหน้า)
            if not exports.vorp_inventory:getItem(src, backpack.BuyItem) then
                activeBuy[src] = nil
                return
            end

            local BackpackID = GetUniqueID() -- สร้าง Backpack ID ใหม่
            Wait(1000)
            -- บันทึกกระเป๋าใหม่ลง SQL
            MySQL.insert('INSERT INTO `mjdev_backpack` (backpackid, backpackmodel, inventorylimit) VALUES (?, ?, ?)',
            {BackpackID, backpack.Model, backpack.Inventory}, function() end)

            -- ลบไอเทม BuyItem ออก (เช่น Backpack_60, Backpack_100)
            exports.vorp_inventory:subItem(src, backpack.BuyItem, 1, {})

            -- เพิ่มไอเทม BackpackItem ใหม่ให้ผู้เล่น
            exports.vorp_inventory:addItem(src, backpack.BackpackItem, 1, {
                description = _U('BackPackID') .. BackpackID,
                backpackid = BackpackID
            })

            activeBuy[src] = nil
        end
    end)
end

for _, backpack in ipairs(Config.Backpacks) do
    exports.vorp_inventory:registerUsableItem(backpack.BackpackItem, function(data)
        local src = data.source
        local Character = VORPcore.getUser(src).getUsedCharacter
        local BackPack = exports.vorp_inventory:getItem(src, backpack.BackpackItem)
        
        -- ตรวจสอบว่าไอเทมมี metadata หรือไม่
        if not BackPack or not BackPack.metadata or not BackPack.metadata.backpackid then
            VORPcore.NotifyRightTip(src, _U('NoDatabaseFound'), 4000)
            return
        end

        local BackpackID = BackPack.metadata.backpackid

        -- Check if backpack data has already been retrieved in the loop
        local result = MySQL.query.await("SELECT * FROM mjdev_backpack WHERE backpackid=@backpackid", { ["backpackid"] = BackpackID })

        if #result > 0 then
            local BackpackLimit = result[1].inventorylimit
            local DataBackpackID = result[1].backpackid
            local isRegistered = exports.vorp_inventory:isCustomInventoryRegistered(DataBackpackID)

            if isRegistered then
                exports.vorp_inventory:closeInventory(src, DataBackpackID)
                exports.vorp_inventory:openInventory(src, DataBackpackID)
            else
                exports.vorp_inventory:registerInventory({
                    id = DataBackpackID,
                    name = backpack.BackpackName, -- เปลี่ยนชื่อตามต้องการ
                    limit = BackpackLimit,
                    acceptWeapons = true,
                    shared = true,
                    ignoreItemStackLimit = true,
                })
                exports.vorp_inventory:openInventory(src, DataBackpackID)
            end

            -- Logging the event if enabled in config
            if Config.Logging.EnableLogging then
                if Config.Logging.EnableDiscordLog then
                    PerformHttpRequest(Config.Logging.DiscordWebhook, function(statusCode, response, headers)
                        -- Handle Discord response if needed
                    end, 'POST', json.encode({
                        username = "MJ-Backpack",
                        content = "**" .. GetPlayerName(src) .. "** used a backpack: " .. backpack.BackpackName .. " (" .. BackpackID .. ")"
                    }), { ['Content-Type'] = 'application/json' })
                end
            end

        else
            VORPcore.NotifyRightTip(src, _U('NoDatabaseFound'), 4000)
            -- Logging for failed case
            if Config.Logging.EnableLogging then
                if Config.Logging.EnableDiscordLog then
                    PerformHttpRequest(Config.Logging.DiscordWebhook, function(statusCode, response, headers)
                        -- Handle Discord response if needed
                    end, 'POST', json.encode({
                        username = "MJ-Backpack",
                        content = "**" .. GetPlayerName(src) .. "** attempted to use an invalid backpack ID: " .. BackpackID
                    }), { ['Content-Type'] = 'application/json' })
                end
            end
        end
    end)
end

-- ===== เปิดกระเป๋าให้ผู้เล่น (ใช้ร่วมกับคีย์ลัด Alt+G) =====
-- ไล่หาไอเทมกระเป๋าที่ผู้เล่นถืออยู่ (แบบเดียวกับ CheckBackpack) แล้วเปิด custom inventory
-- ตรรกะ register/open ยกมาจาก registerUsableItem callback ด้านบน — server-authoritative
-- (ไม่เชื่อ client ว่ามีกระเป๋าไหน server หาเองจาก getItem)
local function OpenBackpack(src)
    for _, backpack in ipairs(Config.Backpacks) do
        local BackPack = exports.vorp_inventory:getItem(src, backpack.BackpackItem)
        if BackPack and BackPack.metadata and BackPack.metadata.backpackid then
            local BackpackID = BackPack.metadata.backpackid
            local result = MySQL.query.await("SELECT * FROM mjdev_backpack WHERE backpackid=@backpackid", { ["backpackid"] = BackpackID })
            if #result > 0 then
                local BackpackLimit = result[1].inventorylimit
                local DataBackpackID = result[1].backpackid
                if exports.vorp_inventory:isCustomInventoryRegistered(DataBackpackID) then
                    exports.vorp_inventory:closeInventory(src, DataBackpackID)
                    exports.vorp_inventory:openInventory(src, DataBackpackID)
                else
                    exports.vorp_inventory:registerInventory({
                        id = DataBackpackID,
                        name = backpack.BackpackName,
                        limit = BackpackLimit,
                        acceptWeapons = true,
                        shared = true,
                        ignoreItemStackLimit = true,
                    })
                    exports.vorp_inventory:openInventory(src, DataBackpackID)
                end
                return true
            end
        end
    end
    return false
end

-- คีย์ลัด Alt+G (ฝั่ง client ยิงมา) — ไม่รับพารามิเตอร์จาก client เลย กัน spoof
RegisterServerEvent('MJ-Backpack:server:OpenViaKey', function()
    local src = source
    if not OpenBackpack(src) then
        VORPcore.NotifyRightTip(src, _U('NoDatabaseFound'), 4000)
    end
end)

function GetUniqueID()
    while true do
        Wait(500)
        local BackpackID = math.random(11111, 999999)
        local result = MySQL.single.await("SELECT 1 FROM mjdev_backpack WHERE backpackid=@backpackid", { ["backpackid"] = BackpackID })
        if not result then
            return BackpackID
        end
    end
end

RegisterServerEvent('MJ-Backpack:server:CheckBackpack', function()
    local src = source
    local playerIdentifier = GetPlayerIdentifier(src, 0) -- ดึง Steam ID ของผู้เล่น
    local foundBackpack = false
    local backpackModel, inventoryLimit

    -- ตรวจสอบกระเป๋าใน Inventory
    for _, backpack in ipairs(Config.Backpacks) do
        local BackPack = exports.vorp_inventory:getItem(src, backpack.BackpackItem)

        if BackPack and BackPack.metadata and BackPack.metadata.backpackid then
            local BackpackID = BackPack.metadata.backpackid
            local result = MySQL.query.await("SELECT * FROM mjdev_backpack WHERE backpackid=@backpackid", { ["@backpackid"] = BackpackID })

            if #result > 0 then
                foundBackpack = true
                backpackModel = result[1].backpackmodel
                inventoryLimit = result[1].inventorylimit

                -- Log to console if enabled
                if Config.Logging.EnableConsoleLog then
                    print(("📢 [BACKPACK USED] Player: %s | Item: %s | Model: %s | Inventory: %d | Steam ID: %s | Timestamp: %s"):format(
                        GetPlayerName(src), backpack.BackpackItem, backpackModel, inventoryLimit, playerIdentifier, os.date("%Y-%m-%d %H:%M:%S")
                    ))
                end

                -- Send to Discord if enabled
                if Config.Logging.EnableDiscordLog then
                    SendToDiscord("🎒 Backpack Used",
                        ("**Player:** %s\n**Item:** %s\n**Model:** %s\n**Inventory:** %d slots\n**Steam ID:** %s\n**Timestamp:** %s")
                        :format(GetPlayerName(src), backpack.BackpackItem, backpackModel, inventoryLimit, playerIdentifier, os.date("%Y-%m-%d %H:%M:%S")),
                        3447003 -- Blue color
                    )
                end

                -- Open backpack for the player
                TriggerClientEvent('MJ-Backpack:client:HasBackpack', src, backpackModel)
                break
            end
        end
    end

    -- If no backpack found, notify player
    if not foundBackpack then
        TriggerClientEvent('MJ-Backpack:client:HasNoBackpack', src)
    end
end)

RegisterServerEvent('MJ-Backpack:server:LogBackpack')
AddEventHandler('MJ-Backpack:server:LogBackpack', function(BackpackModel, isEquipped)
    local src = source
    local playerIdentifier = GetPlayerIdentifier(src, 0)
    local action = isEquipped and "✅ สวมใส่" or "❌ ถอด"

    -- ✅ แจ้งเตือนใน Console
    if Config.Logging.EnableConsoleLog then
        print(("📢 [BACKPACK ACTION] Player: %s | Model: %s | Action: %s | Steam ID: %s"):format(
            GetPlayerName(src), BackpackModel, action, playerIdentifier
        ))
    end

    -- ✅ ส่งแจ้งเตือนไปที่ Discord ถ้าเปิดใช้งาน
    if Config.Logging.EnableDiscordLog then
        SendToDiscord("🎒 Backpack Update",
            ("**Player:** %s\n**Model:** %s\n**Action:** %s\n**Steam ID:** %s")
            :format(GetPlayerName(src), BackpackModel, action, playerIdentifier),
            3447003 -- สีฟ้า
        )
    end
end)

-- ✅ ฟังก์ชันส่งข้อมูลไป Discord Webhook
function SendToDiscord(title, message, color)
    if not Config.Logging.EnableDiscordLog then return end

    local embedData = {
        {
            ["title"] = title,
            ["description"] = message,
            ["color"] = color,
            ["footer"] = {
                ["text"] = "MJ-Backpack System | "..os.date("%Y-%m-%d %H:%M:%S"),
            }
        }
    }

    PerformHttpRequest(Config.Logging.DiscordWebhook, function(err, text, headers) end, "POST", json.encode({ embeds = embedData }), { ["Content-Type"] = "application/json" })
end


-- ✅ ฟังก์ชันส่งข้อมูลไป Discord Webhook
function SendToDiscord(title, message, color)
    if not Config.Logging.EnableDiscordLog then return end -- ถ้าไม่เปิดใช้งานให้หยุดฟังก์ชัน

    local embedData = {
        {
            ["title"] = title,
            ["description"] = message,
            ["color"] = color,
            ["footer"] = {
                ["text"] = "MJ-Backpack System | "..os.date("%Y-%m-%d %H:%M:%S"),
            }
        }
    }

    PerformHttpRequest(Config.Logging.DiscordWebhook, function(err, text, headers) end, "POST", json.encode({ embeds = embedData }), { ["Content-Type"] = "application/json" })
end


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