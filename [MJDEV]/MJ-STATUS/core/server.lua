local VORPcore = exports['vorp_core']:GetCore()

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

    local identifier = Character.identifier or Character.charIdentifier

    if not identifier then
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

    MySQL.Async.execute(
        'UPDATE characters SET status = @status WHERE identifier = @identifier',
        {
            ['@status'] = statusJSON,
            ['@identifier'] = identifier
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

        TriggerClientEvent("MJ-STATUS:setStatus", _source, s_status)

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
AddEventHandler('playerDropped', function(reason)
    local _source = source
    local User = VORPcore.getUser(_source)
    
    if not User then return end

    local Character = User.getUsedCharacter
    if not Character then return end

    local identifier = Character.identifier
    local s_status = Character.status
    -- If the status is not empty or hasn't been reset
    if s_status and s_status ~= '{}' then
        local statusData = json.decode(s_status)
        if statusData.Hunger and statusData.Thirst and statusData.Stress and Config.SavePlayersStatus then
            -- Save the status to the database before the player leaves
            MySQL.Async.execute('UPDATE characters SET status = @status WHERE identifier = @identifier', {
                ['@status'] = json.encode(statusData),
                ['@identifier'] = identifier
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    print("Successfully saved status for character: " .. identifier)
                else
                    print("Failed to save status for character: " .. identifier)
                end
            end)
        else
            -- Reset to default status if invalid
            if Config.SavePlayersStatus then
                local defaultStatus = {
                    Hunger = Config.MaxHunger or 1000,
                    Thirst = Config.MaxThirst or 1000,
                    Stress = Config.MinStress or 0
                }
                MySQL.Async.execute('UPDATE characters SET status = @status WHERE identifier = @identifier', {
                    ['@status'] = json.encode(defaultStatus),
                    ['@identifier'] = identifier
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        print("Successfully saved default status for character: " .. identifier)
                    else
                        print("Failed to save default status for character: " .. identifier)
                    end
                end)
            end
        end
    else
        -- Use default config if no status exists in the database
        if Config.SavePlayersStatus then
            local defaultStatus = {
                Hunger = Config.MaxHunger or 1000,
                Thirst = Config.MaxThirst or 1000,
                Stress = Config.MinStress or 0
            }
            -- Save default status to the database
            MySQL.Async.execute('UPDATE characters SET status = @status WHERE identifier = @identifier', {
                ['@status'] = json.encode(defaultStatus),
                ['@identifier'] = identifier
            }, function(rowsChanged)
                if identifier ~= nil then
                    if rowsChanged > 0 then
                        print("Successfully saved default status for character: " .. identifier)
                    else
                        print("Failed to save default status for character: " .. identifier)
                    end
                end
            end)
        end
    end
end)

AddEventHandler("vorp:SelectedCharacter",function(source)
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end

    local Character = User.getUsedCharacter
    local identifier = Character.identifier
    if not Character then return end

    local s_status = Character.status
    if (#s_status > 5) then
        TriggerClientEvent("MJ-STATUS:setStatus", _source, s_status)
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
