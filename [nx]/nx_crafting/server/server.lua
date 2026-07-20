NODEX = {
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
        NODEX["Core"] = Core
        local PendingCrafts = {}

        AddEventHandler('playerDropped', function()
            PendingCrafts[source] = nil
        end)

        NODEX["ServerEvent"]('nx_crafting:server:getSetupResources')
        NODEX["Handler"]('nx_crafting:server:getSetupResources', function()
            TriggerClientEvent("nx_crafting:client:setConfigData", source, ConfigSv["Category"], ConfigSv["Routers"])
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

        local function notifyPlayer(target, notifyType, text)
            NODEX["EventCl"](ConfigSv["Routers"]["getNotify"], target, {
                type = notifyType,
                text = text
            })
        end

        local itemMetaFields = {
            item = true,
            label = true,
            image = true,
            type = true,
            category = true,
            recipe = true,
            recipes = true
        }

        local function isWeaponName(name)
            return type(name) == "string" and string.find(string.upper(name), "WEAPON_", 1, true) ~= nil
        end

        local function shallowCopy(source)
            local copy = {}
            if type(source) ~= "table" then
                return copy
            end
            for key, value in pairs(source) do
                copy[key] = value
            end
            return copy
        end

        local function sortedNumericKeys(source)
            local keys = {}
            if type(source) ~= "table" then
                return keys
            end
            for key in pairs(source) do
                local numericKey = tonumber(key)
                if numericKey ~= nil then
                    table.insert(keys, numericKey)
                end
            end
            table.sort(keys)
            return keys
        end

        local function collectRecipeEntries(rawRecipes)
            local recipes = {}
            if type(rawRecipes) ~= "table" then
                return recipes
            end

            local hasIndexedRecipe = false
            for key, value in pairs(rawRecipes) do
                local recipeIndex = tonumber(key)
                if recipeIndex ~= nil and type(value) == "table" then
                    recipes[recipeIndex] = shallowCopy(value)
                    hasIndexedRecipe = true
                end
            end

            if not hasIndexedRecipe then
                recipes[1] = shallowCopy(rawRecipes)
            end

            return recipes
        end

        local function NormalizeCraftItem(itemEntry)
            if type(itemEntry) ~= "table" then
                return itemEntry
            end

            local recipes = collectRecipeEntries(itemEntry.recipe or itemEntry.recipes)
            if next(recipes) == nil then
                recipes[1] = {}
            end
            if recipes[1] == nil then
                recipes[1] = {}
            end

            for key, value in pairs(itemEntry) do
                if not itemMetaFields[key] then
                    if recipes[1][key] == nil then
                        recipes[1][key] = value
                    end
                    itemEntry[key] = nil
                end
            end

            itemEntry.recipe = recipes
            itemEntry.recipes = nil
            return itemEntry
        end

        local function NormalizeCraftingConfig(categories)
            if type(categories) ~= "table" then
                return {}
            end

            for _, categoryData in pairs(categories) do
                if type(categoryData) == "table" and type(categoryData.list) == "table" then
                    for _, itemEntry in pairs(categoryData.list) do
                        NormalizeCraftItem(itemEntry)
                    end
                end
            end

            return categories
        end

        local function GetRecipesForItem(categoryIndex, itemIndex)
            local categoryKey = tonumber(categoryIndex)
            local itemKey = tonumber(itemIndex)
            local categoryData = categoryKey and ConfigSv["Category"] and ConfigSv["Category"][categoryKey]
            local itemEntry = categoryData and categoryData.list and categoryData.list[itemKey]
            if not itemEntry then
                return nil, nil, nil
            end

            NormalizeCraftItem(itemEntry)
            return itemEntry.recipe or {}, itemEntry, categoryData
        end

        local function GetRecipeByIndex(categoryIndex, itemIndex, recipeIndex)
            local recipeKey = tonumber(recipeIndex) or 1
            local recipes, itemEntry, categoryData = GetRecipesForItem(categoryIndex, itemIndex)
            if not recipes then
                return nil
            end

            local recipe = recipes[recipeKey]
            if not recipe then
                return nil
            end

            return categoryData, itemEntry, recipe, tonumber(categoryIndex), tonumber(itemIndex), recipeKey
        end

        local function GetSelectedRecipeData(categoryIndex, itemIndex, recipeIndex)
            local categoryData, itemEntry, recipe, categoryKey, itemKey, recipeKey =
                GetRecipeByIndex(categoryIndex, itemIndex, recipeIndex)
            if not recipe then
                return nil
            end

            local selected = shallowCopy(recipe)
            selected.item = itemEntry.item
            selected.categoryIndex = categoryKey
            selected.itemIndex = itemKey
            selected.recipeIndex = recipeKey
            selected.categoryName = categoryData and categoryData.name
            return selected
        end

        local function amountFromRow(row)
            if type(row) ~= "table" then
                return tonumber(row) or 0
            end

            return tonumber(row.amox or row.amount or row.count or row.qty or row.quantity or row[2]) or 0
        end

        local function listFromRecipeMap(recipeMap)
            local list = {}
            if type(recipeMap) ~= "table" then
                return list
            end

            for key, value in pairs(recipeMap) do
                local row = {}
                if type(value) == "table" then
                    row.name = value.name or value.item or value.id or (type(key) == "string" and key or nil)
                    row.amox = amountFromRow(value)
                    row.status = value.status
                    row.required = value.required
                    row.label = value.label
                else
                    row.name = type(key) == "string" and key or nil
                    row.amox = amountFromRow(value)
                end

                if type(row.name) == "string" and row.amox > 0 then
                    table.insert(list, row)
                end
            end

            return list
        end

        local function optionalListFromRecipeMap(recipeMap)
            local list = listFromRecipeMap(recipeMap)
            if #list == 0 then
                return nil
            end
            return list
        end

        local function listFromToolMap(toolMap)
            local list = {}
            if type(toolMap) ~= "table" then
                return list
            end

            for key, value in pairs(toolMap) do
                local row = {}
                if type(value) == "table" then
                    row.name = value.name or value.item or value.id or (type(key) == "string" and key or nil)
                    row.amox = amountFromRow(value)
                    if row.amox <= 0 then
                        row.amox = 1
                    end
                    row.status = value.status
                    row.required = value.required
                    row.label = value.label
                else
                    row.name = type(key) == "string" and key or nil
                    row.amox = 1
                    if type(value) == "boolean" then
                        row.status = value
                    end
                end

                if type(row.name) == "string" then
                    table.insert(list, row)
                end
            end

            return list
        end

        local function recipeCost(recipe)
            return recipe and recipe.cost
        end

        local function recipeBlueprint(recipe)
            return recipe and recipe.blueprint
        end

        local function recipeTools(recipe)
            return recipe and (recipe.toolsList or recipe.equipment)
        end

        local function recipeFailedList(recipe)
            return recipe and (recipe.failedList or recipe.fail_item)
        end

        local function recipeOutputItem(itemEntry, recipe)
            if type(recipe) == "table" then
                if type(recipe.giveItem) == "string" then
                    return recipe.giveItem
                end
                if type(recipe.reward) == "string" then
                    return recipe.reward
                end
                if type(recipe.reward) == "table" then
                    return recipe.reward.item or recipe.reward.name or itemEntry.item
                end
            end

            return itemEntry and itemEntry.item
        end

        local function recipeOutputCount(recipe, amount)
            local multiplier = 1
            if type(recipe) == "table" then
                if tonumber(recipe.giveAmount) then
                    multiplier = tonumber(recipe.giveAmount)
                elseif type(recipe.reward) == "table" and tonumber(recipe.reward.amount or recipe.reward.count or recipe.reward.qty) then
                    multiplier = tonumber(recipe.reward.amount or recipe.reward.count or recipe.reward.qty)
                end
            end

            return math.max(1, math.floor(multiplier * amount))
        end

        local function recipeType(itemEntry, recipe)
            local configuredType = recipe and recipe.type or itemEntry and itemEntry.type
            if configuredType then
                return configuredType
            end

            local outputItem = recipeOutputItem(itemEntry, recipe)
            if isWeaponName(outputItem) or isWeaponName(itemEntry and itemEntry.item) then
                return "item_weapon"
            end

            return "item_standard"
        end

        ConfigSv["Category"] = NormalizeCraftingConfig(ConfigSv["Category"])

        local function tableHasCategory(categoryList, categoryId)
            if type(categoryList) ~= "table" then
                return false
            end

            for _, allowedCategory in pairs(categoryList) do
                if tonumber(allowedCategory) == tonumber(categoryId) then
                    return true
                end
            end

            return false
        end

        local function isJobAllowed(jobList, playerJob)
            if jobList == nil or jobList == 0 then
                return true
            end

            if type(jobList) == "string" then
                return jobList == playerJob
            end

            if type(jobList) == "table" then
                for allowedKey, allowedJob in pairs(jobList) do
                    if allowedJob == playerJob or (allowedJob == true and allowedKey == playerJob) then
                        return true
                    end
                end
            end

            return false
        end

        local function canUseCraftingTable(sourceId, xPlayer, categoryId)
            if not Config or type(Config["Craft_Table"]) ~= "table" then
                return false
            end

            local ped = GetPlayerPed(sourceId)
            if not ped or ped == 0 then
                return false
            end

            local coords = GetEntityCoords(ped)
            if not coords then
                return false
            end

            for _, craftTable in pairs(Config["Craft_Table"]) do
                if tableHasCategory(craftTable.Category, categoryId) and isJobAllowed(craftTable.job, xPlayer.job) then
                    local position = craftTable.Position
                    if position then
                        local dx = coords.x - position.x
                        local dy = coords.y - position.y
                        local dz = coords.z - position.z
                        local distance = math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
                        local maxDistance = (tonumber(craftTable.Max_Distance) or 2.5) + 3.0
                        if distance <= maxDistance then
                            return true
                        end
                    end
                end
            end

            return false
        end

        local function sanitizeAmount(value)
            local amount = tonumber(value)
            if amount == nil or amount ~= amount or amount == math.huge or amount == -math.huge then
                return nil
            end

            amount = math.floor(amount)
            if amount <= 0 then
                return nil
            end

            if amount > 100 then
                amount = 100
            end

            return amount
        end

        local function inventoryItemCount(sourceId, itemName)
            if not itemName then
                return 0
            end
            return exports.vorp_inventory:getItemCount(sourceId, nil, itemName) or 0
        end

        local function hasRequiredItems(sourceId, items, amount)
            for _, itemData in pairs(items or {}) do
                local required = math.floor((tonumber(itemData.amox) or 0) * amount)
                if itemData.name and required > 0 and inventoryItemCount(sourceId, itemData.name) < required then
                    return false
                end
            end

            return true
        end

        local function hasRequiredTools(sourceId, tools)
            for _, toolData in pairs(listFromToolMap(tools)) do
                if toolData.status ~= false and toolData.required ~= false then
                    local required = math.max(1, math.floor(tonumber(toolData.amox) or 1))
                    if inventoryItemCount(sourceId, toolData.name) < required then
                        return false
                    end
                end
            end

            return true
        end

        local function currencyType(name)
            local key = string.lower(tostring(name or ""))
            if key == "money" or key == "cash" or key == "dollar" or key == "dollars" then
                return 0
            end
            if key == "gold" then
                return 1
            end
            if key == "rol" or key == "role" then
                return 2
            end
            return nil
        end

        local function currencyBalance(xPlayer, currency)
            if currency == 0 then
                return tonumber(xPlayer.money) or 0
            end
            if currency == 1 then
                return tonumber(xPlayer.gold) or 0
            end
            if currency == 2 then
                return tonumber(xPlayer.rol) or 0
            end
            return 0
        end

        local function hasRequiredCost(sourceId, xPlayer, costs, amount)
            for _, costData in pairs(listFromRecipeMap(costs)) do
                local required = math.floor((tonumber(costData.amox) or 0) * amount)
                if costData.name and required > 0 then
                    local currency = currencyType(costData.name)
                    if currency ~= nil then
                        if currencyBalance(xPlayer, currency) < required then
                            return false
                        end
                    elseif inventoryItemCount(sourceId, costData.name) < required then
                        return false
                    end
                end
            end

            return true
        end

        local function removeRecipeCost(sourceId, xPlayer, costs, amount)
            for _, costData in pairs(listFromRecipeMap(costs)) do
                local removeAmount = math.floor((tonumber(costData.amox) or 0) * amount)
                if costData.name and removeAmount > 0 then
                    local currency = currencyType(costData.name)
                    if currency ~= nil then
                        xPlayer.removeCurrency(currency, removeAmount)
                    else
                        exports.vorp_inventory:subItem(sourceId, costData.name, removeAmount)
                    end
                end
            end
        end

        local function currentWeaponCount(sourceId, weaponName)
            if not weaponName then
                return 0
            end

            local ok, weapons = pcall(function()
                return VorpInv.getUserWeapons(sourceId)
            end)
            if not ok or type(weapons) ~= "table" then
                return 0
            end

            local count = 0
            local target = string.upper(weaponName)
            for _, weapon in pairs(weapons) do
                local name = type(weapon) == "table" and (weapon.name or weapon.weapon or weapon.weaponName) or weapon
                if type(name) == "string" and string.upper(name) == target then
                    count = count + 1
                end
            end

            return count
        end

        local function exceedsMaxStack(sourceId, outputType, outputItem, recipe, rewardCount)
            if ConfigSv["NoItemLimit"] then
                return false
            end

            local maxStack = tonumber(recipe and recipe.max_stack)
            if not maxStack or maxStack <= 0 then
                return false
            end

            local current = 0
            if outputType == "item_weapon" then
                current = currentWeaponCount(sourceId, outputItem)
            else
                current = inventoryItemCount(sourceId, outputItem)
            end

            return current + rewardCount > maxStack
        end

        local function recipeSuccessChance(recipe)
            local successRate = tonumber(recipe and recipe.success_rate)
            if successRate == nil then
                local failChance = tonumber(recipe and recipe.fail_chance) or 0
                successRate = 100 - failChance
            end

            if successRate < 0 then
                successRate = 0
            elseif successRate > 100 then
                successRate = 100
            end

            return successRate
        end

        local function validateSelectedRecipe(sourceId, xPlayer, categoryIndex, itemIndex, recipeIndex, amount)
            local categoryData, itemEntry, recipe, categoryKey, itemKey, recipeKey =
                GetRecipeByIndex(categoryIndex, itemIndex, recipeIndex)
            if not recipe then
                return false, 'Invalid crafting recipe'
            end

            local count = sanitizeAmount(amount)
            if not count then
                return false, 'Invalid crafting amount'
            end

            local outputItem = recipeOutputItem(itemEntry, recipe)
            if type(outputItem) ~= "string" or outputItem == "" then
                return false, 'Invalid crafting result'
            end

            local outputType = recipeType(itemEntry, recipe)
            if outputType == "item_weapon" then
                count = 1
            end

            if not canUseCraftingTable(sourceId, xPlayer, categoryKey) then
                return false, 'Crafting table access denied'
            end

            local jobRestriction = recipe.jobList or recipe.allowedJob or recipe.job
            if not isJobAllowed(jobRestriction, xPlayer.job) then
                return false, 'Job not allowed'
            end

            if not hasRequiredTools(sourceId, recipeTools(recipe)) then
                return false, 'Missing required tools'
            end

            if not hasRequiredItems(sourceId, listFromRecipeMap(recipeBlueprint(recipe)), count) then
                return false, 'Not enough crafting materials'
            end

            if not hasRequiredCost(sourceId, xPlayer, recipeCost(recipe), count) then
                return false, 'Not enough crafting cost'
            end

            local rewardCount = recipeOutputCount(recipe, count)
            if outputType == "item_weapon" then
                rewardCount = 1
            end

            if exceedsMaxStack(sourceId, outputType, outputItem, recipe, rewardCount) then
                return false, 'Crafting limit reached'
            end

            return true, {
                category = categoryKey,
                itemIndex = itemKey,
                recipeIndex = recipeKey,
                categoryData = categoryData,
                itemEntry = itemEntry,
                recipe = recipe,
                count = count,
                outputItem = outputItem,
                outputType = outputType,
                rewardCount = rewardCount
            }
        end

        Core.Callback.Register("nx_crafting:server:getJob", function(source, cb)
            local user = Core.getUser(source)
            local xPlayer = user and user.getUsedCharacter
            cb(xPlayer and xPlayer.job or nil)
        end)

        Core.Callback.Register("nx_crafting:server:getInventory", function(source, cb)
            local user = Core.getUser(source)
            local xPlayer = user and user.getUsedCharacter
            if xPlayer then
                cb(VorpInv.getUserInventory(source))
            else
                cb({})
            end
        end)

        Core.Callback.Register("nx_crafting:server:getDBItems", function(source, cb)
            local user = Core.getUser(source)
            local xPlayer = user and user.getUsedCharacter
            if xPlayer then
                cb(ServerItems)
            else
                cb({})
            end
        end)

        Core.Callback.Register('nx_crafting:server:checkItems', function(source, cb, requestedCategory, requestedItemIndex, requestedRecipeIndex, requestedAmount)
            local _source = source
            local user = Core.getUser(_source)
            local xPlayer = user and user.getUsedCharacter
            if not xPlayer then
                cb(false)
                return
            end

            local ok, selected = validateSelectedRecipe(_source, xPlayer, requestedCategory, requestedItemIndex,
                requestedRecipeIndex, requestedAmount)
            if not ok then
                -- เดิมทิ้งเหตุผลแล้ว cb(false) เปล่าๆ ส่วน client ก็ไม่มี else รองรับ
                -- (ดู client.lua "if status then ... end") ผลคือกดคราฟแล้วเงียบสนิท
                -- ไม่มีข้อความ ไม่มี log ทั้งที่ validateSelectedRecipe ปฏิเสธได้ตั้ง 9 สาเหตุ
                -- ตอนนี้บอกเหตุผลที่มันคืนมาตรงๆ ให้ผู้เล่นรู้ว่าติดตรงไหน
                notifyPlayer(_source, 'error', selected or 'คราฟไม่ได้ (ไม่ทราบสาเหตุ)')
                if ConfigSv["Debug"] then
                    print(('[nx_crafting] checkItems ปฏิเสธ src=%s cat=%s item=%s recipe=%s -> %s')
                        :format(tostring(_source), tostring(requestedCategory), tostring(requestedItemIndex),
                            tostring(requestedRecipeIndex), tostring(selected)))
                end
                cb(false)
                return
            end

            local now = os.time()
            PendingCrafts[_source] = {
                category = selected.category,
                itemIndex = selected.itemIndex,
                recipeIndex = selected.recipeIndex,
                item = selected.itemEntry.item,
                amount = selected.count,
                readyAt = now + 3,
                expiresAt = now + 20
            }
            cb(true)
        end)

        NODEX["ServerEvent"]('nx_crafting:server:cancelCraft')
        NODEX["Handler"]('nx_crafting:server:cancelCraft', function()
            PendingCrafts[source] = nil
        end)

        NODEX["ServerEvent"]('nx_crafting:server:craftItem')
        NODEX["Handler"]('nx_crafting:server:craftItem', function(requestedCategory, requestedItemIndex, requestedRecipeIndex, requestedAmount)
                local _source = source
                local user = Core.getUser(_source)
                local xPlayer = user and user.getUsedCharacter
                if not xPlayer then
                    return
                end

                local ok, selected = validateSelectedRecipe(_source, xPlayer, requestedCategory, requestedItemIndex,
                    requestedRecipeIndex, requestedAmount)
                if not ok then
                    notifyPlayer(_source, 'error', selected or 'Invalid crafting recipe')
                    return
                end

                local pendingCraft = PendingCrafts[_source]
                local now = os.time()
                if not pendingCraft or pendingCraft.expiresAt < now or pendingCraft.category ~= selected.category or
                    pendingCraft.itemIndex ~= selected.itemIndex or pendingCraft.recipeIndex ~= selected.recipeIndex or
                    pendingCraft.amount ~= selected.count then
                    PendingCrafts[_source] = nil
                    notifyPlayer(_source, 'error', 'Invalid crafting session')
                    return
                end

                if pendingCraft.readyAt > now then
                    notifyPlayer(_source, 'error', 'Crafting is not finished')
                    return
                end

                PendingCrafts[_source] = nil

                local recipe = selected.recipe
                local type = selected.outputType
                local item = listFromRecipeMap(recipeBlueprint(recipe))
                local cost = recipeCost(recipe)
                local give = selected.outputItem
                local count = selected.count
                local rewardCount = selected.rewardCount
                local statuscount = math.format(recipeSuccessChance(recipe), 2)
                local failitem = optionalListFromRecipeMap(recipeFailedList(recipe))
                local custom_percent_failitem = tonumber(recipe.custom_percent_failitem or recipe.customPercentFailItem) or 0
                local persentremove_fail = recipe.persentremove_fail or recipe.persentRemoveFail

                local ChackStatus = rnd()
                if ChackStatus <= statuscount then
                    if type == "item_standard" then
                        if ConfigSv["DiscordCraftingLog"] then
                            SetDistcordItem(_source, "Success", 65280, give, rewardCount, ChackStatus, statuscount)
                        else
                            NODEX["Event"]('nx_crafting:server:logOther', _source, "Success", give, rewardCount, ChackStatus,
                                statuscount, type)
                        end
                        NODEX["EventCl"]('nx_crafting:client:playWithinDistance', -1, source,
                            ConfigSv["Craft_Table_Sound_Distance"], ConfigSv["Craft_Table_Sound"]["Success"], 0.5)
                        NODEX["EventCl"](ConfigSv["Routers"]["getNotify"], _source, {
                            type = 'success',
                            text = 'ยินดีด้วยคราฟไอเทมสำเร็จ'
                        })
                        removeRecipeCost(_source, xPlayer, cost, count)
                        for k, v in pairs(item) do
                            -- print(DumpTable(v.amox))
                            exports.vorp_inventory:subItem(_source, v.name, v.amox * count)
                        end
                        exports.vorp_inventory:addItem(_source, give, rewardCount, recipe.metadata)
                    elseif type == "item_weapon" then
                        if ConfigSv["DiscordCraftingLog"] then
                            SetDistcordWeapon(_source, "Success", 9749506, string.upper(give), ChackStatus, statuscount)
                        else
                            NODEX["Event"]('nx_crafting:server:logOther', _source, "Success", string.upper(give), 1,
                                ChackStatus, statuscount, type)
                        end
                        NODEX["EventCl"]('nx_crafting:client:playWithinDistance', -1, source,
                            ConfigSv["Craft_Table_Sound_Distance"], ConfigSv["Craft_Table_Sound"]["Success"], 0.5)
                        NODEX["EventCl"](ConfigSv["Routers"]["getNotify"], _source, {
                            type = 'success',
                            text = 'ยินดีด้วยคราฟไอเทมสำเร็จ'
                        })
                        removeRecipeCost(_source, xPlayer, cost, count)
                        for k, v in pairs(item) do
                            local removeCount = math.floor(v.amox * count)
                            if v.name and removeCount > 0 then
                                exports.vorp_inventory:subItem(_source, v.name, removeCount)
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
                    if type == "item_standard" then
                        if ConfigSv["DiscordCraftingLog"] then
                            SetDistcordItem(_source, "Failed", 12845619, give, rewardCount, ChackStatus, statuscount)
                        else
                            NODEX["Event"]('nx_crafting:server:logOther', _source, "Failed", give, rewardCount, ChackStatus,
                                statuscount, type)
                        end
                    elseif type == "item_weapon" then
                        if ConfigSv["DiscordCraftingLog"] then
                            SetDistcordWeapon(_source, "Failed", 12845587, string.upper(give), ChackStatus, statuscount)
                        else
                            NODEX["Event"]('nx_crafting:server:logOther', _source, "Failed", string.upper(give), 1,
                                ChackStatus, statuscount, type)
                        end
                    end

                    NODEX["EventCl"]('nx_crafting:client:playWithinDistance', -1, source,
                        ConfigSv["Craft_Table_Sound_Distance"], ConfigSv["Craft_Table_Sound"]["Failed"], 0.8)
                    NODEX["EventCl"](ConfigSv["Routers"]["getNotify"], _source, {
                        type = 'error',
                        text = 'เสียใจด้วยคราฟไอเทมไม่สำเร็จ'
                    })

                    removeRecipeCost(_source, xPlayer, cost, count)

                    for k, v in pairs(item) do
                        exports.vorp_inventory:subItem(_source, v.name, v.amox * count)
                    end

                    if persentremove_fail ~= nil then
                        for k, v in pairs(persentremove_fail) do
                            local rsl = math.random(1, 100)
                            if v.protectfollwblackitem ~= nil then
                                local protectCount = exports.vorp_inventory:getItemCount(_source, nil, v.protectfollwblackitem)
                                if protectCount > 0 then
                                    NODEX["EventCl"](ConfigSv["Routers"]["getNotify"], _source, {
                                        type = 'error',
                                        text = 'การป้องกันสำเร็จ'
                                    })
                                    exports.vorp_inventory:subItem(_source, v.protectfollwblackitem, protectCount)
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
                                    NODEX["EventCl"]("nx_crafting:client:removeWeapon", _source, string.upper(v.name))
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
            local webhook_name = "NODEX Console Log  [" .. os.date("%d/%m/%Y - %X") .. "]"
            local embeds = {{
                ["title"] = 'Log Event Crafting Item [ ' .. status .. ' ]',
                ["type"] = "rich",
                ["color"] = discord_color,
                ["description"] = 'Name : ' .. name .. ' \n Steam : ' .. steam .. ' \n Item : ' ..
                    NODEX["Core"].GetItemLabel(item) .. ' Count : ' .. count .. ' \n Percent Craftitem : ' .. percentrs ..
                    ' / ' .. percent .. ' %',
                ["footer"] = {
                    ["text"] = '🔴 ==> NODEX Coding'
                },
                ["author"] = {
                    ["name"] = ' NODEX Crafting ',
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
            local webhook_name = "NODEX Console Log  [" .. os.date("%d/%m/%Y - %X") .. "]"
            local embeds = {{
                ["title"] = 'Log Event Crafting Item [ ' .. status .. ' ]',
                ["type"] = "rich",
                ["color"] = discord_color,
                ["description"] = 'Name : ' .. name .. ' \n Steam : ' .. steam .. ' \n Weapon : ' ..
                    NODEX["Core"].GetWeaponLabel(item) .. ' \n Percent Craftitem : ' .. percentrs .. ' / ' .. percent ..
                    ' %',
                ["footer"] = {
                    ["text"] = '🔴 ==> NODEX Coding'
                },
                ["author"] = {
                    ["name"] = ' NODEX Crafting ',
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

        NODEX["ServerEvent"]('nx_crafting:server:logOther')
        NODEX["Handler"]('nx_crafting:server:logOther', function(source, status, item, count, percent, percentrs, type)
            local user = Core.getUser(source)
            local xPlayer = user and user.getUsedCharacter
            if not xPlayer then
                return
            end
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
NODEX["StartScrip"]()
