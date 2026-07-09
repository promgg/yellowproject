MJDEV = {
    ["ServerEvent"] = RegisterServerEvent,
    ["Handler"] = AddEventHandler,
    ["Event"] = TriggerEvent,
    ["EventCl"] = TriggerClientEvent,
    ["RsName"] = GetCurrentResourceName(),
    ["RsVer"] = "0.1",
    ["CList"] = {},
    ["StartScrip"] = function()
        Core = exports.vorp_core:GetCore()
        VorpInv = exports.vorp_inventory:vorp_inventoryApi()
        MJDEV["ServerEvent"]('MJ-Crafting:GetSetupResources')
        MJDEV["Handler"]('MJ-Crafting:GetSetupResources', function()
            TriggerClientEvent("MJ-Crafting:SetConfigData", source, ConfigSv["Category"], ConfigSv["Routers"])
        end)
        ServerItems = {}

        Citizen.CreateThread(function()
            MySQL.Async.fetchAll("SELECT * FROM items", {}, function(result)
                if result and #result > 0 then
                    ServerItems = result
                    print("[ServerItems] Loaded " .. #ServerItems .. " items.")
                    -- TriggerEvent("my:itemLoaded") หรือ callback
                else
                    print("[ServerItems] No items found in database.")
                end
            end)
        end)

        Core.Callback.Register("MJ-Crafting:GetJob", function(source, cb)
            local xPlayer = Core.getUser(source).getUsedCharacter
            local job = xPlayer.job
            cb(job)
        end)

        Core.Callback.Register("MJ-Crafting:inventory", function(source, cb)
            local xPlayer = Core.getUser(source).getUsedCharacter
            if xPlayer then
                cb(VorpInv.getUserInventory(source))
            end
        end)

        Core.Callback.Register("MJ-Crafting:getDBItem", function(source, cb)
            local xPlayer = Core.getUser(source).getUsedCharacter
            if xPlayer then
                cb(ServerItems)
            end
        end)

        Core.Callback.Register('MJ-Crafting:ChackItem', function(source, cb, listitem)
            local _source = source
            local xPlayer = Core.getUser(_source).getUsedCharacter
            local Status = true
            if xPlayer then
                for k, v in pairs(listitem) do
                    local count = exports.vorp_inventory:getItemCount(_source, nil, v.name)
                    if count < v.amox then
                        Status = false
                    end
                end
            end
            cb(Status)
        end)

        MJDEV["ServerEvent"]('MJ-Crafting:CraftItem')
        MJDEV["Handler"]('MJ-Crafting:CraftItem', function(type, item, money, give, count, statuscount, failitem, custom_percent_failitem, persentremove_fail)
                local _source = source
                local xPlayer = Core.getUser(_source).getUsedCharacter
                local ChackStatus = rnd()
                local statuscount = math.format(statuscount, 2)
                print(ChackStatus)
                print(statuscount)
                if ChackStatus >= statuscount then
                    if type == "item_standard" then
                        if ConfigSv["DiscordCraftingLog"] then
                            SetDistcordItem(_source, "Success", 65280, give, count, ChackStatus, statuscount)
                        else
                            MJDEV["Event"]('MJ-Crafting:logother', _source, "Success", give, 1, ChackStatus,
                                statuscount, type)
                        end
                        MJDEV["EventCl"]('MJ-Crafting:PlayWithinDistanceCl', -1, source,
                            ConfigSv["Craft_Table_Sound_Distance"], ConfigSv["Craft_Table_Sound"]["Success"], 0.5)
                        MJDEV["EventCl"](ConfigSv["Routers"]["getNotify"], _source, {
                            type = 'success',
                            text = 'ยินดีด้วยคราฟไอเทมสำเร็จ'
                        })
                        for k, v in pairs(money) do
                            xPlayer.removeCurrency(0, v.amox * count)
                        end
                        for k, v in pairs(item) do
                            -- print(DumpTable(v.amox))
                            exports.vorp_inventory:subItem(_source, v.name, v.amox * count)
                        end
                        local count = exports.vorp_inventory:getItemCount(_source, nil, give)
                        if count > 0 then
                            exports.vorp_inventory:addItem(_source, give, count)
                        end
                    elseif type == "item_weapon" then
                        if ConfigSv["DiscordCraftingLog"] then
                            SetDistcordWeapon(_source, "Success", 9749506, string.upper(give), ChackStatus, statuscount)
                        else
                            MJDEV["Event"]('MJ-Crafting:logother', _source, "Success", string.upper(give), 1,
                                ChackStatus, statuscount, type)
                        end
                        MJDEV["EventCl"]('MJ-Crafting:PlayWithinDistanceCl', -1, source,
                            ConfigSv["Craft_Table_Sound_Distance"], ConfigSv["Craft_Table_Sound"]["Success"], 0.5)
                        MJDEV["EventCl"](ConfigSv["Routers"]["getNotify"], _source, {
                            type = 'success',
                            text = 'ยินดีด้วยคราฟไอเทมสำเร็จ'
                        })
                        for k, v in pairs(money) do
                            local count = math.floor(v.amox * count)
                            if v.name and count > 0 then
                                xPlayer.removeCurrency(0, count)
                            end
                        end
                        for k, v in pairs(item) do
                            local count = math.floor(v.amox * count)
                            if v.name and count > 0 then
                                exports.vorp_inventory:subItem(_source, v.name, count)
                            end
                        end
                        local ammo = {
                            ["nothing"] = 0
                        }
                        local components = {
                            ["nothing"] = 0
                        }
                        exports.vorp_inventory:createWeapon(_source, string.upper(give), ammo, components)
                    end
                else
                    print('failed')
                    if type == "item_standard" then
                        if ConfigSv["DiscordCraftingLog"] then
                            SetDistcordItem(_source, "Failed", 12845619, give, count, ChackStatus, statuscount)
                        else
                            MJDEV["Event"]('MJ-Crafting:logother', _source, "Failed", give, count, ChackStatus,
                                statuscount, type)
                        end
                    elseif type == "item_weapon" then
                        if ConfigSv["DiscordCraftingLog"] then
                            SetDistcordWeapon(_source, "Failed", 12845587, string.upper(give), ChackStatus, statuscount)
                        else
                            MJDEV["Event"]('MJ-Crafting:logother', _source, "Failed", string.upper(give), 1,
                                ChackStatus, statuscount, type)
                        end
                    end

                    MJDEV["EventCl"]('MJ-Crafting:PlayWithinDistanceCl', -1, source,
                        ConfigSv["Craft_Table_Sound_Distance"], ConfigSv["Craft_Table_Sound"]["Failed"], 0.8)
                    MJDEV["EventCl"](ConfigSv["Routers"]["getNotify"], _source, {
                        type = 'error',
                        text = 'เสียใจด้วยคราฟไอเทมไม่สำเร็จ'
                    })

                    for k, v in pairs(money) do
                        xPlayer.removeCurrency(0, v.amox * count)
                    end

                    for k, v in pairs(item) do
                        exports.vorp_inventory:subItem(v.name, v.amox * count)
                    end

                    if persentremove_fail ~= nil then
                        for k, v in pairs(persentremove_fail) do
                            local rsl = math.random(1, 100)
                            if v.protectfollwblackitem ~= nil then
                                local count = exports.vorp_inventory:getItemCount(_source, nil, v.protectfollwblackitem)
                                if count > 0 then
                                    MJDEV["EventCl"](ConfigSv["Routers"]["getNotify"], _source, {
                                        type = 'error',
                                        text = 'การป้องกันสำเร็จ'
                                    })
                                    exports.vorp_inventory:subItem(v.protectfollwblackitem, 1 * count)
                                    return
                                end
                            end
                            if rsl > v.persent then
                                if v.type == "item_standard" then
                                    exports.vorp_inventory:subItem(_source, v.name, 1)
                                    exports.vorp_inventory:addItem(_source, v.itrmlosblack, 1)
                                elseif v.type == "item_weapon" then
                                    exports.vorp_inventory:createWeapon(_source, string.upper(v.itrmlosblack), {})
                                    xPlayer.removeWeapon(string.upper(v.name))
                                    MJDEV["EventCl"]("MJ-Crafting:RemoveWeaponCl", _source, string.upper(v.name))
                                end
                            end
                        end
                    end

                    if failitem ~= nil then
                        local rnd = rnd()
                        local indel = 50
                        if custom_percent_failitem ~= nil then
                            indel = custom_percent_failitem
                        end
                        if rnd >= indel then
                            for k, v in pairs(failitem) do
                                exports.vorp_inventory:addItem(_source, v.name, v.amox)
                            end
                        end
                    end
                end
            end)

        function math.format(g, h)
            if h then
                local j = 10 ^ h
                return math.floor((g * j) + 0.5) / (j)
            else
                return math.floor(g + 0.5)
            end
        end

        function rnd()
            return math.format(math.random() + math.random(1, 99), 2)
        end

        function SetDistcordItem(id, status, discord_color, item, count, percentrs, percent)
            local _source = id
            local name = GetPlayerName(_source)
            local steam = GetPlayerIdentifier(_source)
            local avatar = "https://i.pinimg.com/originals/51/f6/fb/51f6fb256629fc755b8870c801092942.png"
            local webhook_name = "MJDEV Console Log  [" .. os.date("%d/%m/%Y - %X") .. "]"
            local embeds = {{
                ["title"] = 'Log Event Crafting Item [ ' .. status .. ' ]',
                ["type"] = "rich",
                ["color"] = discord_color,
                ["description"] = 'Name : ' .. name .. ' \n Steam : ' .. steam .. ' \n Item : ' ..
                    MJDEV["Core"].GetItemLabel(item) .. ' Count : ' .. count .. ' \n Percent Craftitem : ' .. percentrs ..
                    ' / ' .. percent .. ' %',
                ["footer"] = {
                    ["text"] = '🔴 ==> MJDEV Coding'
                },
                ["author"] = {
                    ["name"] = ' MJDEV Crafting ',
                    ["icon_url"] = "https://media.discordapp.net/attachments/641717879858921503/767445777303470130/shield.png"
                },
                ["thumbnail"] = {
                    ["url"] = "https://cdn.pixabay.com/photo/2012/04/11/11/55/letter-n-27733_960_720.png"
                }
            }}
            PerformHttpRequest(ConfigSv["Craft_Discord_Log"]["Item"], function(err, text, headers)
            end, 'POST', json.encode({
                username = webhook_name,
                embeds = embeds,
                avatar_url = avatar
            }), {
                ['Content-Type'] = 'application/json'
            })
        end

        function SetDistcordWeapon(id, status, discord_color, item, percentrs, percent)
            local _source = id
            local name = GetPlayerName(_source)
            local steam = GetPlayerIdentifier(_source)
            local avatar = "https://i.pinimg.com/originals/51/f6/fb/51f6fb256629fc755b8870c801092942.png"
            local webhook_name = "MJDEV Console Log  [" .. os.date("%d/%m/%Y - %X") .. "]"
            local embeds = {{
                ["title"] = 'Log Event Crafting Item [ ' .. status .. ' ]',
                ["type"] = "rich",
                ["color"] = discord_color,
                ["description"] = 'Name : ' .. name .. ' \n Steam : ' .. steam .. ' \n Weapon : ' ..
                    MJDEV["Core"].GetWeaponLabel(item) .. ' \n Percent Craftitem : ' .. percentrs .. ' / ' .. percent ..
                    ' %',
                ["footer"] = {
                    ["text"] = '🔴 ==> MJDEV Coding'
                },
                ["author"] = {
                    ["name"] = ' MJDEV Crafting ',
                    ["icon_url"] = "https://media.discordapp.net/attachments/641717879858921503/767445777303470130/shield.png"
                },
                ["thumbnail"] = {
                    ["url"] = "https://cdn.pixabay.com/photo/2012/04/11/11/55/letter-n-27733_960_720.png"
                }
            }}
            PerformHttpRequest(ConfigSv["Craft_Discord_Log"]["Weapon"], function(err, text, headers)
            end, 'POST', json.encode({
                username = webhook_name,
                embeds = embeds,
                avatar_url = avatar
            }), {
                ['Content-Type'] = 'application/json'
            })
        end

        MJDEV["ServerEvent"]('MJ-Crafting:logother')
        MJDEV["Handler"]('MJ-Crafting:logother', function(source, status, item, count, percent, percentrs, type)
            local xPlayer = Core.getUser(source).getUsedCharacter
            if ConfigSv["Other_Discord_LogEvent"] ~= nil then
                ConfigSv["Other_Discord_LogEvent"](xPlayer, source, status, item, count, percent, percentrs, type)
            end
        end)
    end
}

function DumpTable(table, nb)
    if nb == nil then
        nb = 0
    end

    if type(table) == "table" then
        local s = ""
        for _ = 1, nb + 1, 1 do
            s = s .. "    "
        end

        s = "{\n"
        for k, v in pairs(table) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end
            for _ = 1, nb, 1 do
                s = s .. "    "
            end
            s = s .. "[" .. k .. "] = " .. DumpTable(v, nb + 1) .. ",\n"
        end

        for _ = 1, nb, 1 do
            s = s .. "    "
        end

        return s .. "}"
    else
        return tostring(table)
    end
end
MJDEV["StartScrip"]()
