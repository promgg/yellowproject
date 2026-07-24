local VORPcore = exports['vorp_core']:GetCore()

-- ตัวละครที่บันทึก status ไว้ก่อนระบบความเครียดถูกเพิ่ม จะมี JSON ใน DB แบบ {"Hunger":..,"Thirst":..}
-- ที่ไม่มีคีย์ Stress เลย เดิมโค้ดเช็คแค่ความยาว string (#s_status > 5) แล้วส่งค่าดิบให้ client ตรงๆ
-- ทำให้ PlayerStatus.Stress เป็น nil ฝั่ง client แล้วพังต่อกันเป็นทอด (concat nil ที่ needs.lua,
-- หารด้วย nil ที่ client.lua, เทียบ number กับ nil) — เติมคีย์ที่ขาดให้ครบก่อนส่งเสมอ
-- ฝั่ง save มี sanitize อยู่แล้ว (ดู MJ-STATUS:saveStatus) อันนี้คือด้านขากลับที่ยังขาดไป
local function normalizeStatusJSON(raw)
    local status = nil
    if type(raw) == 'string' and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then status = decoded end
    elseif type(raw) == 'table' then
        status = raw
    end

    status = status or {}
    status.Hunger = tonumber(status.Hunger) or Config.MaxHunger or 1000
    status.Thirst = tonumber(status.Thirst) or Config.MaxThirst or 1000
    status.Stress = tonumber(status.Stress) or Config.MinStress or 0

    return json.encode(status)
end

-- กันกดกิน/ดื่มรัวๆ: server หัก item ทันทีทุกครั้งที่ callback ยิง (client ท่ากิน ~7 วิ ไม่ได้บล็อก
-- การหัก item ที่ server ทำไปแล้ว) spam คลิกเลยกินหมดสต็อกในพริบตา + ท่า/prop ซ้อนกันหลายอัน —
-- cooldown ต่อคนเท่าความยาวท่ากิน กันหักซ้ำระหว่างท่ายังเล่นอยู่
local EAT_COOLDOWN_MS = 6500 -- ~ความยาวท่ากิน/ดื่ม (PlayAnimEat/Drink รวม ~6-7 วิ)
local eatCooldown = {}       -- [src] = GetGameTimer() ที่กินได้อีกครั้ง

AddEventHandler('playerDropped', function()
    if source then eatCooldown[source] = nil end
end)

-- ฟังก์ชั่นใช้งานไอเท็มที่กินได้
local function useConsumableItem(playerId, item)
    local consumable = Config.FoodItems[item]
    if consumable then
        local now = GetGameTimer()
        if eatCooldown[playerId] and now < eatCooldown[playerId] then
            return -- ยังกินคำก่อนไม่เสร็จ — ไม่หัก item ซ้ำ ไม่ยิงท่า/prop ซ้อน
        end
        eatCooldown[playerId] = now + EAT_COOLDOWN_MS

        exports.vorp_inventory:closeInventory(playerId)
        exports.vorp_inventory:subItem(playerId, item, 1)
        local EatAnimDict = consumable.EatAnimDict
        local EatAnimName = consumable.EatAnimName

        TriggerClientEvent("MJ-STATUS:useItem", playerId, item, consumable.hunger, consumable.thirst, consumable.stress, consumable.stamina, EatAnimDict, EatAnimName)
    else
        print("Error: Item " .. item .. " not found in Config.FoodItems")
    end
end

CreateThread(function()
    for item, _ in pairs(Config.FoodItems) do
        exports.vorp_inventory:registerUsableItem(item, function(data)
            local itemLabel = data.item.label
            useConsumableItem(data.source, item)
        end)
    end
end)

-- Background check to update player status every 5 minutes
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.SaveStatusTickInterval) -- 5 minutes
        local players = GetPlayers()
        if #players > 0 then
            for _, playerId in ipairs(players) do
                local User = VORPcore.getUser(tonumber(playerId))
                if User then
                    local Character = User.getUsedCharacter
                    if Character then
                        TriggerClientEvent("MJ-STATUS:getStatus", tonumber(playerId))
                    end
                end
            end
        end
    end
end)

-- Save status
RegisterServerEvent("MJ-STATUS:saveStatus")
AddEventHandler("MJ-STATUS:saveStatus", function(status)

    local _source = tonumber(source)
    if not _source then return end

    local User = VORPcore.getUser(_source)

    if not User then
        print("^1[MJ-STATUS]^0 User not found: " .. tostring(_source))
        return
    end

    local Character = User.getUsedCharacter

    if not Character then
        print("^1[MJ-STATUS]^0 Character not found: " .. tostring(_source))
        return
    end

    -- ⚠️ ต้องใช้ "ทั้งคู่" ในการระบุแถว
    -- identifier    = steam id  -> ใช้ร่วมกันทุกตัวละครในบัญชีเดียวกัน
    -- charidentifier = id ตัวละคร -> ตัวที่ระบุแถวได้จริง
    -- เดิม WHERE identifier อย่างเดียว = status ของตัวละครที่เล่นอยู่ทับ "ทุกตัวละคร"
    -- ในบัญชีนั้น (สลับตัวละครแล้วค่าหิว/น้ำ/เครียดเพี้ยนตามตัวที่เล่นล่าสุด)
    local identifier = Character.identifier
    local charIdentifier = Character.charIdentifier

    if not identifier or not charIdentifier then
        print("^1[MJ-STATUS]^0 Identifier not found")
        return
    end

    if type(status) ~= "table" then
        print("^1[MJ-STATUS]^0 Invalid status format from: " .. tostring(_source))
        return
    end

    if not next(status) then
        return
    end

    if not Config.SavePlayersStatus then
        return
    end

    -- กัน exploit
    status.Hunger = math.min(Config.MaxHunger or 1000, math.max(0, tonumber(status.Hunger) or 0))
    status.Thirst = math.min(Config.MaxThirst or 1000, math.max(0, tonumber(status.Thirst) or 0))
    status.Stress = math.min(Config.MaxStress or 1000, math.max(Config.MinStress or 0, tonumber(status.Stress) or 0))

    local statusJSON = json.encode(status)

    -- อัปเดต "ค่าใน object ของ vorp" ด้วย ไม่ใช่แค่เขียน DB ตรงๆ
    -- ต้นตอบั๊ก "ออกเข้าใหม่รีเซ็ตเป็นเต็ม": เดิม save เขียนแค่ DB แต่ playerDropped กับ
    -- SelectedCharacter อ่านจาก Character.status (ค่าใน object) ซึ่งค้างที่ค่าตอน login
    -- ตลอดทั้ง session ตอนออก playerDropped จึงเอาค่าเก่า (มักเต็ม) เขียนทับค่าจริงใน DB
    -- อัปเดต object ทุกครั้งที่ save ค่าใน object จึงตรงกับค่าล่าสุดเสมอ
    if Character.setStatus then
        Character.setStatus(statusJSON)
    end

    MySQL.Async.execute(
        'UPDATE characters SET status = @status WHERE identifier = @identifier AND charidentifier = @charidentifier',
        {
            ['@status'] = statusJSON,
            ['@identifier'] = identifier,
            ['@charidentifier'] = charIdentifier
        },
        function(rowsChanged)

            if rowsChanged and rowsChanged > 0 then

                print("^2[MJ-STATUS]^0 Saved status: " .. tostring(identifier))

                TriggerClientEvent(
                    "MJ-STATUS:setStatus",
                    _source,
                    statusJSON
                )

            else

                print("^1[MJ-STATUS]^0 Failed to save: " .. tostring(identifier))

            end
        end
    )
end)

RegisterServerEvent("MJ-STATUS:loadStatus")
AddEventHandler("MJ-STATUS:loadStatus", function()

    local _source = tonumber(source)
    if not _source then return end

    local User = VORPcore.getUser(_source)
    if not User then return end

    local Character = User.getUsedCharacter
    if not Character then return end

    local s_status = Character.status or ""

    if type(s_status) == "string"
    and s_status ~= ""
    and s_status ~= "{}"
    and #s_status > 5 then

        -- เติมคีย์ที่ขาด (เช่น Stress ของตัวละครเก่า) ก่อนส่ง ไม่ส่งค่าดิบจาก DB ตรงๆ
        TriggerClientEvent("MJ-STATUS:setStatus", _source, normalizeStatusJSON(s_status))

    else

        local status = json.encode({
            Hunger = Config.MaxHunger or 1000,
            Thirst = Config.MaxThirst or 1000,
            Stress = Config.MinStress or 0
        })

        TriggerClientEvent("MJ-STATUS:setStatus", _source, status)
    end
end)


-- เมื่อผู้เล่นออกจากเซิร์ฟเวอร์
-- หลักการ: "ออกเท่าไหนเข้าก็เท่านั้น" — บันทึกค่าล่าสุดที่มี ห้าม reset เป็นเต็มเด็ดขาด
--
-- บั๊กเดิม: มี 3 สาขาที่เขียน default (เต็ม) ทับ DB เมื่อ Character.status ว่าง/คีย์ไม่ครบ
-- ซึ่งเกิดบ่อยเพราะ save เดิมไม่อัปเดต object (ค้างค่า login มักเต็ม) = ออกเข้าใหม่เต็มทุกครั้ง
-- ตอนนี้ save อัปเดต Character.status ให้สดแล้ว ค่านี้จึงเป็นค่าล่าสุดที่เซฟจริง
-- ถ้าค่าไม่สมบูรณ์ให้ "ไม่ทำอะไร" — ปล่อยให้ค่าที่ save รอบก่อนใน DB คงอยู่ ดีกว่าเขียนเต็มทับ
AddEventHandler('playerDropped', function(reason)
    if not Config.SavePlayersStatus then return end

    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end

    local Character = User.getUsedCharacter
    if not Character then return end

    -- ต้องระบุด้วย charidentifier ด้วย ไม่งั้นทับ status ทุกตัวละครในบัญชี (ดูคอมเมนต์ที่ saveStatus)
    local identifier = Character.identifier
    local charIdentifier = Character.charIdentifier
    local s_status = Character.status

    if not identifier or not charIdentifier then return end

    -- ไม่มีค่าจริง = ไม่แตะ DB (กันเขียนเต็มทับ) — ค่าจาก save รอบก่อนยังอยู่ครบ
    if type(s_status) ~= "string" or #s_status <= 5 then return end
    local ok, statusData = pcall(json.decode, s_status)
    if not ok or type(statusData) ~= "table" then return end
    if not (statusData.Hunger and statusData.Thirst and statusData.Stress) then return end

    MySQL.Async.execute('UPDATE characters SET status = @status WHERE identifier = @identifier AND charidentifier = @charidentifier', {
        ['@status'] = json.encode(statusData),
        ['@identifier'] = identifier,
        ['@charidentifier'] = charIdentifier
    }, function(rowsChanged)
        if rowsChanged and rowsChanged > 0 then
            print("Successfully saved status for character: " .. tostring(identifier))
        else
            print("Failed to save status for character: " .. tostring(identifier))
        end
    end)
end)

AddEventHandler("vorp:SelectedCharacter",function(source)
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end

    local Character = User.getUsedCharacter
    local identifier = Character.identifier
    if not Character then return end

    local s_status = Character.status
    if type(s_status) == "string" and #s_status > 5 then
        -- เติมคีย์ที่ขาด (เช่น Stress ของตัวละครเก่า) ก่อนส่ง ไม่ส่งค่าดิบจาก DB ตรงๆ
        TriggerClientEvent("MJ-STATUS:setStatus", _source, normalizeStatusJSON(s_status))
    else
        local status = json.encode({
            ['Hunger'] = Config.MaxHunger or 1000,
            ['Thirst'] = Config.MaxThirst or 1000,
            ['Stress'] = Config.MinStress or 0
        })
        Character.setStatus(status)
        TriggerClientEvent("MJ-STATUS:setStatus", _source, status)
    end
end)



-- ════════════════════════════════════════════════════════════════════════════
--  Admin: ตั้ง/รีเซ็ตค่า อาหาร-น้ำ-ความเครียด
--
--  ค่าจริงอยู่ฝั่ง client (PlayerStatus) — server แค่ "สั่ง" ให้ client ตั้งค่า แล้ว client
--  จะยิง MJ-STATUS:saveStatus กลับมาเอง ซึ่งเป็นเส้นทาง save เดิมที่ clamp + อัปเดต
--  Character.setStatus + เขียน DB อยู่แล้ว (มีผู้เขียนคนเดียว ไม่แตกเป็นสองทาง)
--
--  ห้ามเขียน DB ตรงนี้เอง: client ถือค่าสดอยู่ ถ้าเขียนทับฝั่ง server เฉยๆ รอบ save ถัดไป
--  ของ client จะเอาค่าเก่าทับกลับทันที (บั๊กเดิมของ MJ-Admin ที่ "เติมแล้วไม่ติด")
-- ════════════════════════════════════════════════════════════════════════════
local function pushNeeds(target, hunger, thirst, stress)
    target = tonumber(target)
    if not target or not GetPlayerName(target) then return false end -- ออฟไลน์/id ไม่มีจริง

    TriggerClientEvent("MJ-STATUS:client:applyNeeds", target, {
        Hunger = hunger,
        Thirst = thirst,
        Stress = stress,
    })
    return true
end

-- nil = ไม่แตะค่านั้น เช่น SetPlayerNeeds(src, nil, nil, 0) = รีเซ็ตแค่ความเครียด
exports('SetPlayerNeeds', function(target, hunger, thirst, stress)
    return pushNeeds(target, hunger, thirst, stress)
end)

exports('ResetPlayerNeeds', function(target)
    return pushNeeds(target, Config.MaxHunger, Config.MaxThirst, Config.MinStress)
end)

-- /resetneeds [playerId]  — ไม่ใส่ id = ตัวเอง (คอนโซลต้องใส่ id เสมอ)
-- ตรวจสิทธิ์ด้วย ACE:  add_ace group.admin MJ-STATUS.admin allow
RegisterCommand('resetneeds', function(src, args)
    local fromConsole = (src == 0)

    if not fromConsole and not IsPlayerAceAllowed(src, Config.AcePermission or 'MJ-STATUS.admin') then
        TriggerClientEvent("pNotify:SendNotification", src, {
            type = 'error', text = 'คุณไม่มีสิทธิ์ใช้คำสั่งนี้', timeout = 4000
        })
        return
    end

    local target = tonumber(args[1]) or (not fromConsole and src or nil)
    if not target then
        print('^3[MJ-STATUS]^0 ใช้: resetneeds <playerId>')
        return
    end

    if not pushNeeds(target, Config.MaxHunger, Config.MaxThirst, Config.MinStress) then
        local msg = ('ไม่พบผู้เล่น id %s'):format(tostring(target))
        if fromConsole then print('^1[MJ-STATUS]^0 ' .. msg)
        else TriggerClientEvent("pNotify:SendNotification", src, { type='error', text=msg, timeout=4000 }) end
        return
    end

    print(('^2[MJ-STATUS]^0 resetneeds: %s -> id %s'):format(
        fromConsole and 'console' or (GetPlayerName(src) or '?'), tostring(target)))

    TriggerClientEvent("pNotify:SendNotification", target, {
        type = 'success', text = 'ผู้ดูแลรีเซ็ตค่าอาหาร/น้ำ/ความเครียดให้คุณแล้ว', timeout = 4000
    })

    if not fromConsole and target ~= src then
        TriggerClientEvent("pNotify:SendNotification", src, {
            type = 'success', text = ('รีเซ็ตค่าให้ id %s แล้ว'):format(tostring(target)), timeout = 4000
        })
    end
end, false)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        MySQL.ready(function()
            print("MySQL is connected successfully.")
        end)
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
