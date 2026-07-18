local Core = exports.vorp_core:GetCore()
local Inventory = exports.vorp_inventory
local resourceName = GetCurrentResourceName()
local activeUse = {}

local function debugLog(message, ...)
    if not Config.Debug then
        return
    end

    print(('[%s] %s'):format(resourceName, message:format(...)))
end

local function notify(source, message)
    Core.NotifyObjective(source, message, Config.NotifyDuration)
end

local function isValidAmmoConfig(ammoConfig)
    return type(ammoConfig) == 'table'
        and type(ammoConfig.ammoType) == 'string'
        and ammoConfig.ammoType ~= ''
        and type(ammoConfig.amount) == 'number'
        and ammoConfig.amount > 0
        and type(ammoConfig.max) == 'number'
        and ammoConfig.max > 0
        and ammoConfig.amount <= ammoConfig.max
end

local function useAmmoBox(itemName, ammoConfig, data)
    local source = tonumber(data and data.source)
    local item = data and data.item
    local itemId = tonumber(item and item.id)

    if not source or source <= 0 or not itemId or itemId <= 0 or item.name ~= itemName then
        return
    end

    if activeUse[source] then
        return
    end

    activeUse[source] = true

    local success, err = xpcall(function()
        local ammo = Inventory:getUserAmmo(source)
        if type(ammo) ~= 'table' then
            notify(source, Config.Locale.useFailed)
            return
        end

        local current = tonumber(ammo[ammoConfig.ammoType]) or 0
        if current >= ammoConfig.max or current + ammoConfig.amount > ammoConfig.max then
            notify(source, Config.Locale.ammoFull)
            return
        end

        -- Remove the exact server-validated inventory instance first. Both inventory
        -- mutations are synchronous in-memory operations, so no other use can interleave.
        local removed = Inventory:subItemById(source, itemId)
        if removed ~= true then
            notify(source, Config.Locale.useFailed)
            return
        end

        local added = Inventory:addBullets(source, ammoConfig.ammoType, ammoConfig.amount)
        if added ~= true then
            local restored = Inventory:addItem(source, itemName, 1, item.metadata or {})
            if restored ~= true then
                print(('^1[%s] Failed to restore ammo item %s for source %s after addBullets failed.^7')
                    :format(resourceName, itemName, source))
            end
            notify(source, Config.Locale.useFailed)
            return
        end

        debugLog('source=%d used %s; ammo=%s +%d', source, itemName, ammoConfig.ammoType, ammoConfig.amount)
    end, debug.traceback)

    activeUse[source] = nil

    if not success then
        print(('^1[%s] Ammo item callback failed for %s: %s^7'):format(resourceName, itemName, err))
        notify(source, Config.Locale.useFailed)
    end
end

local function registerAmmoItems()
    local registered = 0

    for itemName, ammoConfig in pairs(Config.AmmoItems) do
        if isValidAmmoConfig(ammoConfig) then
            local registeredItem = itemName
            local registeredAmmo = ammoConfig

            Inventory:registerUsableItem(registeredItem, function(data)
                useAmmoBox(registeredItem, registeredAmmo, data)
            end, resourceName)
            registered = registered + 1
        else
            print(('^1[%s] Invalid ammo configuration for item %s; item was not registered.^7')
                :format(resourceName, tostring(itemName)))
        end
    end

    print(('^2[%s] Registered %d usable ammo items.^7'):format(resourceName, registered))
end

registerAmmoItems()

-- vorp_inventory owns the usable-item callback table. Re-register after an
-- inventory resource restart so ammo boxes do not silently lose their handler.
AddEventHandler('onResourceStart', function(startedResource)
    if startedResource ~= 'vorp_inventory' then
        return
    end

    SetTimeout(250, registerAmmoItems)
end)

AddEventHandler('playerDropped', function()
    activeUse[source] = nil
end)

AddEventHandler('onResourceStop', function(stoppedResource)
    if stoppedResource ~= resourceName then
        return
    end

    for itemName in pairs(Config.AmmoItems) do
        Inventory:unRegisterUsableItem(itemName)
    end
end)
