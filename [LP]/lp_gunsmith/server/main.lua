--[[
    lp_gunsmith — server (authority).

    The client only ever sends { weaponId, weaponName, slot, componentName }. Ownership,
    distance, whitelist membership, price and rate limiting are all decided here. Persistence
    piggybacks on vorp_inventory's own `loadout` table (`components` JSON array, mirrored into
    the legacy `comps` column); vorp_inventory's files are never modified.
]]

local Core = exports.vorp_core:GetCore()

-- weaponName -> componentName -> slot, built once so a component's slot is an O(1) lookup.
local ComponentSlotLookup = {}
for weaponName, slots in pairs(Config.Components) do
    ComponentSlotLookup[weaponName] = {}
    for slot, options in pairs(slots) do
        for _, comp in ipairs(options) do
            ComponentSlotLookup[weaponName][comp] = slot
        end
    end
end

local lastAction = {} -- [source] = GetGameTimer() of last accepted request
local processing = {} -- [source] = true while a DB round trip is in flight

local function logTx(source, action, weaponId, weaponName, slot, componentName, price)
    local user = Core.getUser(source)
    local char = user and user.getUsedCharacter
    print(('[lp_gunsmith] %s charid=%s weaponId=%s weapon=%s slot=%s component=%s price=%s')
        :format(action, char and char.charIdentifier or '?', tostring(weaponId), tostring(weaponName),
            tostring(slot), tostring(componentName), tostring(price)))
end

local function isRateLimited(source)
    local now = GetGameTimer()
    local last = lastAction[source]
    if last and (now - last) < Config.RateLimitMs then
        return true
    end
    lastAction[source] = now
    return false
end

local function isNearAnyStation(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end

    local coords = GetEntityCoords(ped)
    local maxDist = Config.InteractDistance + Config.ServerDistancePadding
    for _, station in ipairs(Config.Stations) do
        if #(coords - station.coords) <= maxDist then
            return true
        end
    end
    return false
end

local function getCharacter(source)
    local user = Core.getUser(source)
    if not user then return nil end
    return user.getUsedCharacter
end

-- Loads + ownership-checks a loadout row. Returns the row (with `components` decoded) or nil, msg.
local function fetchOwnedWeapon(source, weaponId, weaponName, character)
    local rows = MySQL.query.await(
        'SELECT id, name, label, custom_label, serial_number, components, comps, charidentifier FROM loadout WHERE id = @id LIMIT 1',
        { id = weaponId }
    )
    local row = rows and rows[1]
    if not row then
        return nil, Config.Text.NotOwned
    end

    if tostring(row.charidentifier) ~= tostring(character.charIdentifier) then
        return nil, Config.Text.NotOwned
    end

    if not row.name or row.name:upper() ~= weaponName:upper() then
        return nil, Config.Text.NotOwned
    end

    local ok, decoded = pcall(json.decode, row.components)
    row.components = (ok and type(decoded) == 'table') and decoded or {}

    return row
end

-- Removes any component occupying `slot`, optionally appends `newComponent`, returns the new
-- array + encoded JSON. Returns nil, msg if the result would overflow the varchar(255) column.
local function mergeComponents(weaponName, currentComponents, slot, newComponent)
    local lookup = ComponentSlotLookup[weaponName] or {}
    local merged = {}
    for _, comp in ipairs(currentComponents) do
        if lookup[comp] ~= slot then
            merged[#merged + 1] = comp
        end
    end
    if newComponent then
        merged[#merged + 1] = newComponent
    end

    local encoded = json.encode(merged)
    if #encoded > 255 then
        return nil, nil, Config.Text.Error
    end
    return merged, encoded
end

RegisterServerEvent('lp_gunsmith:sv:requestWeaponList', function()
    local source = source
    if not isNearAnyStation(source) then
        TriggerClientEvent('lp_gunsmith:client:receiveWeaponList', source, {})
        return
    end

    local character = getCharacter(source)
    if not character then return end

    MySQL.query('SELECT id, name, label, custom_label, serial_number, components FROM loadout WHERE charidentifier = @charid AND curr_inv = @curr_inv AND (dropped = 0 OR dropped IS NULL)', {
        charid = character.charIdentifier,
        curr_inv = 'default',
    }, function(rows)
        local list = {}
        for _, row in ipairs(rows or {}) do
            local weaponName = row.name and row.name:upper()
            if weaponName and Config.Components[weaponName] then
                local ok, decoded = pcall(json.decode, row.components)
                list[#list + 1] = {
                    id = row.id,
                    name = weaponName,
                    label = row.custom_label or row.label or weaponName,
                    serialNumber = row.serial_number,
                    components = (ok and type(decoded) == 'table') and decoded or {},
                }
            end
        end
        TriggerClientEvent('lp_gunsmith:client:receiveWeaponList', source, list)
    end)
end)

-- Sends this character's saved customizations so the client can re-apply them post-relog.
RegisterServerEvent('lp_gunsmith:sv:requestMyComponents', function()
    local source = source
    local character = getCharacter(source)
    if not character then return end

    MySQL.query('SELECT id, name, serial_number, components FROM loadout WHERE charidentifier = @charid AND curr_inv = @curr_inv AND (dropped = 0 OR dropped IS NULL)', {
        charid = character.charIdentifier,
        curr_inv = 'default',
    }, function(rows)
        local weapons = {}
        for _, row in ipairs(rows or {}) do
            local weaponName = row.name and row.name:upper()
            if weaponName and Config.Components[weaponName] then
                local ok, decoded = pcall(json.decode, row.components)
                local components = (ok and type(decoded) == 'table') and decoded or {}
                local weaponId = tonumber(row.id)
                weapons[#weapons + 1] = {
                    id = weaponId,
                    name = weaponName,
                    serialNumber = row.serial_number,
                    components = components,
                }

                -- Also repair vorp_inventory's live cache. This matters when
                -- lp_gunsmith was restarted while the player stayed online.
                local syncOk, synced = pcall(function()
                    return exports.vorp_inventory:syncWeaponComponents(source, weaponId, components)
                end)
                if not syncOk or not synced then
                    TriggerClientEvent('vorpInventory:syncWeaponComponents', source, weaponId, components)
                end
            end
        end
        TriggerClientEvent('lp_gunsmith:client:myComponents', source, weapons)
    end)
end)

local function finishRequest(source, ok, message, weapon)
    processing[source] = nil
    TriggerClientEvent('lp_gunsmith:client:applyResult', source, ok, message, weapon)
end

local function handleComponentChange(source, weaponId, weaponName, slot, newComponent, isRemove)
    if processing[source] then
        TriggerClientEvent('lp_gunsmith:client:applyResult', source, false, Config.Text.Busy)
        return
    end

    if isRateLimited(source) then
        TriggerClientEvent('lp_gunsmith:client:applyResult', source, false, Config.Text.Busy)
        return
    end

    weaponId = tonumber(weaponId)
    weaponName = type(weaponName) == 'string' and weaponName:upper() or nil

    if not weaponId or not weaponName or type(slot) ~= 'string' then
        return finishRequest(source, false, Config.Text.Error)
    end

    local slots = Config.Components[weaponName]
    if not slots or not slots[slot] then
        return finishRequest(source, false, Config.Text.InvalidComponent)
    end

    if not isRemove then
        local whitelisted = false
        for _, comp in ipairs(slots[slot]) do
            if comp == newComponent then
                whitelisted = true
                break
            end
        end
        if not whitelisted then
            return finishRequest(source, false, Config.Text.InvalidComponent)
        end
    end

    if not isNearAnyStation(source) then
        return finishRequest(source, false, Config.Text.NotNearStation)
    end

    local character = getCharacter(source)
    if not character then
        return finishRequest(source, false, Config.Text.Error)
    end

    processing[source] = true

    local weapon, ownErr = fetchOwnedWeapon(source, weaponId, weaponName, character)
    if not weapon then
        return finishRequest(source, false, ownErr)
    end

    local currentInSlot = nil
    local lookup = ComponentSlotLookup[weaponName] or {}
    for _, comp in ipairs(weapon.components) do
        if lookup[comp] == slot then
            currentInSlot = comp
            break
        end
    end

    if isRemove and not currentInSlot then
        return finishRequest(source, false, Config.Text.AlreadyEquipped)
    end

    if not isRemove and currentInSlot == newComponent then
        return finishRequest(source, false, Config.Text.AlreadyEquipped)
    end

    local price = isRemove and Config.RemoveComponentPrice or Config.ComponentPrice
    price = tonumber(price) or 0
    if price < 0 then price = 0 end

    -- Re-resolve หลัง await: fetchOwnedWeapon() ไป query DB มา และ getUsedCharacter คืน "สำเนา"
    -- ที่ copy money มาแบบ by-value ตัวที่ resolve ไว้ก่อน query จึงค้างยอดเงินเก่า (TOCTOU:
    -- ใช้เงินไปกับ resource อื่นระหว่างรอ query แล้วเช็คตรงนี้ยังผ่านด้วยยอดก่อนหน้า)
    character = getCharacter(source)
    if not character then
        return finishRequest(source, false, Config.Text.Error)
    end

    if price > 0 then
        if not character.money or character.money < price then
            return finishRequest(source, false, Config.Text.NoMoney)
        end
    end

    local merged, encoded, mergeErr = mergeComponents(weaponName, weapon.components, slot, not isRemove and newComponent or nil)
    if not merged then
        return finishRequest(source, false, mergeErr or Config.Text.Error)
    end

    if price > 0 then
        -- removeCurrency เขียนทะลุถึง object จริง + DB ให้แล้ว ไม่ต้องหักซ้ำ (character เป็นสำเนา
        -- การเขียน .money ใส่สำเนาจึงไม่มีผล แต่จะกลายเป็นหักเงินสองเด้งทันทีถ้าวันไหน
        -- getUsedCharacter เลิกคืนสำเนาแล้วคืน object จริง)
        character.removeCurrency(0, price)
    end

    MySQL.update('UPDATE loadout SET components = @components, comps = @comps WHERE id = @id AND charidentifier = @charid', {
        id = weaponId,
        charid = character.charIdentifier,
        components = encoded,
        comps = encoded,
    }, function(affected)
        if not affected or affected == 0 then
            if price > 0 then
                -- addCurrency คืนเงินเข้า object จริง + DB ให้แล้ว บวกกลับใส่สำเนาไม่มีผล
                -- (และจะกลายเป็นคืนเงินสองเด้งถ้าสำเนากลายเป็น object จริงในอนาคต)
                character.addCurrency(0, price)
            end
            print(('[lp_gunsmith] ERROR: loadout UPDATE affected 0 rows for weaponId=%s charid=%s, refunded $%s')
                :format(tostring(weaponId), tostring(character.charIdentifier), tostring(price)))
            return finishRequest(source, false, Config.Text.Error)
        end

        logTx(source, isRemove and 'REMOVE' or 'APPLY', weaponId, weaponName, slot, newComponent or currentInSlot, price)

        -- The DB is authoritative, but vorp_inventory also keeps a live Weapon
        -- object on both server and client. Update that exact object by ID so
        -- two guns with the same model never inherit one another's components.
        local syncOk, synced = pcall(function()
            return exports.vorp_inventory:syncWeaponComponents(source, weaponId, merged)
        end)
        if not syncOk or not synced then
            print(('[lp_gunsmith] WARNING: unable to sync live component cache for weaponId=%s: %s')
                :format(tostring(weaponId), syncOk and 'weapon cache rejected the update' or tostring(synced)))
        end

        finishRequest(source, true, isRemove and Config.Text.Removed or Config.Text.Applied, {
            id = weaponId,
            name = weaponName,
            serialNumber = weapon.serial_number,
            label = weapon.custom_label or weapon.label or weaponName,
            components = merged,
        })
    end)
end

RegisterServerEvent('lp_gunsmith:sv:applyComponent', function(weaponId, weaponName, slot, componentName)
    handleComponentChange(source, weaponId, weaponName, slot, componentName, false)
end)

RegisterServerEvent('lp_gunsmith:sv:removeComponent', function(weaponId, weaponName, slot)
    handleComponentChange(source, weaponId, weaponName, slot, nil, true)
end)

AddEventHandler('playerDropped', function()
    local source = source
    lastAction[source] = nil
    processing[source] = nil
end)
