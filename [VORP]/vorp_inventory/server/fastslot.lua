-- ============================================================================
--  Fast Slot / Hotbar (open rewrite) — แทน client/MJDevFastSlot.lua ตัวเข้ารหัส
--  server-authoritative + persist ผูก charidentifier + sync จำนวนสด
--  หมายเหตุ: อ้างอิง global InventoryService (server/services/inventoryService.lua)
--  และ export getUserInventoryItems ของ vorp_inventory เอง — เรียกตอน runtime เท่านั้น
--  จึงไม่ต้องกังวลลำดับโหลดไฟล์
-- ============================================================================

local Core = exports.vorp_core:GetCore()

local MAX_SLOTS = Config.FastSlotCount or 6

-- debug log (เปิดด้วย Config.Debug = true)
local function dbg(...)
    if Config.Debug then
        print("^3[fastslot:sv]^7", ...)
    end
end

-- auto-migrate: สร้างตารางถ้ายังไม่มี (idempotent ปลอดภัย รันซ้ำได้) — ไม่ต้อง import sql เอง
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `vorp_fastslots` (
          `charidentifier` INT(11)      NOT NULL,
          `slot`           INT(11)      NOT NULL,
          `item_name`      VARCHAR(100) NOT NULL,
          `item_type`      VARCHAR(30)  NOT NULL DEFAULT 'item_standard',
          `weapon_id`      INT(11)      DEFAULT NULL,
          `metadata`       LONGTEXT     DEFAULT NULL,
          PRIMARY KEY (`charidentifier`, `slot`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `vorp_inventory_preferences` (
          `charidentifier`  INT(11)      NOT NULL,
          `sort_mode`       VARCHAR(20)  NOT NULL DEFAULT 'category',
          `category_filter` VARCHAR(20)  NOT NULL DEFAULT 'all',
          `favorites`       LONGTEXT     DEFAULT NULL,
          PRIMARY KEY (`charidentifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    local hasWeaponId = MySQL.scalar.await([[
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'vorp_fastslots'
          AND COLUMN_NAME = 'weapon_id'
        LIMIT 1
    ]])
    if not hasWeaponId then
        MySQL.query.await("ALTER TABLE vorp_fastslots ADD COLUMN weapon_id INT(11) DEFAULT NULL AFTER item_type")
    end
end)

-- bindings[charid][slot] = { name = ..., type = ..., metadata = table|nil }
local bindings = {}
-- srcToChar[source] = charidentifier (map เร็ว + ใช้ตอน cleanup)
local srcToChar = {}
-- useCooldown[source] = GetGameTimer() ล่าสุด (กัน spam ปุ่ม)
local useCooldown = {}
-- preferenceCooldown[source] prevents a modified NUI from flooding DB writes.
local preferenceCooldown = {}
-- persistenceWorkers[charid] serializes DB rewrites so rapid drag/drop cannot persist stale slots
local persistenceWorkers = {}
local bindingLoadWaiters = {}
local inventoryPreferences = {}
local preferenceLoadWaiters = {}

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------

local function getCharId(_source)
    local user = Core.getUser(_source)
    if not user then return nil end
    local char = user.getUsedCharacter
    if not char then return nil end
    return char.charIdentifier
end

-- match แบบ "ชื่อล้วน" — hotbar ส่วนใหญ่เป็นของกิน/ยา ที่ stack รวมกัน ไม่มี metadata แยกแยะ
-- การ match metadata แบบเป๊ะทำให้หาไอเทมไม่เจอบ่อย (เช่นผ้าพันแผล) จึงใช้ชื่ออย่างเดียวเพื่อความ robust
local function matchesBinding(item, binding)
    if binding.type == "item_weapon" and binding.weaponId then
        return tonumber(item.id) == tonumber(binding.weaponId)
    end
    return item.name == binding.name
end

-- Return the player's live items and weapons. VORP exposes them separately; using only
-- getUserInventoryItems would make every weapon assignment fail server validation.
local function getInventory(_source)
    local inventory = {}
    local itemsOk, items = pcall(function()
        return exports.vorp_inventory:getUserInventoryItems(_source)
    end)
    if itemsOk and type(items) == "table" then
        for _, item in pairs(items) do inventory[#inventory + 1] = item end
    else
        dbg("getUserInventoryItems FAILED for src", _source, "ok=", itemsOk)
    end

    local weaponsOk, weapons = pcall(function()
        return exports.vorp_inventory:getUserInventoryWeapons(_source)
    end)
    if weaponsOk and type(weapons) == "table" then
        for _, weapon in pairs(weapons) do
            weapon.type = "item_weapon"
            weapon.count = 1
            weapon.metadata = type(weapon.metadata) == "table" and weapon.metadata or {
                serial_number = weapon.serial_number,
            }
            inventory[#inventory + 1] = weapon
        end
    else
        dbg("getUserInventoryWeapons FAILED for src", _source, "ok=", weaponsOk)
    end

    return inventory
end

-- หาไอเทมสดที่ตรง binding (คืน item object ตัวแรกที่ match) — id เปลี่ยนทุก session จึงต้องหาสดทุกครั้ง
local function findLiveItem(_source, binding)
    for _, item in ipairs(getInventory(_source)) do
        if matchesBinding(item, binding) then
            return item
        end
    end
    return nil
end

-- payload สำหรับ NUI: array ของ { slot, item = {name,label,count,type,metadata} }
-- นับจำนวนสดจาก inventory ปัจจุบัน ช่องที่ไอเทมหมด/ไม่มีแล้ว count = 0
local function buildSyncPayload(_source, charid)
    local slots = {}
    local charBindings = bindings[charid]
    if not charBindings then return slots end

    local inventory = getInventory(_source)
    for slot, binding in pairs(charBindings) do
        local count, label = 0, binding.name
        for _, item in ipairs(inventory) do
            if matchesBinding(item, binding) then
                count = count + (tonumber(item.count) or 0)
                label = item.label or label
            end
        end
        slots[#slots + 1] = {
            slot = slot,
            item = {
                id = binding.weaponId,
                name = binding.name,
                label = label,
                count = count,
                type = binding.type,
                metadata = binding.metadata or {},
            },
        }
    end
    return slots
end

local function pushSync(_source)
    local charid = srcToChar[_source] or getCharId(_source)
    if not charid then dbg("pushSync: no charid for src", _source); return end
    srcToChar[_source] = charid
    local payload = buildSyncPayload(_source, charid)
    dbg("pushSync -> src", _source, "charid", charid, "slots", json.encode(payload))
    TriggerClientEvent("vorp_inventory:fastslot:sync", _source, payload)
end

-- Fast slots contain at most six rows. Rewriting the character snapshot keeps persistence
-- consistent after moves and also removes legacy duplicate item rows. A per-character worker
-- serializes writes; mutations that arrive while a write is running are flushed afterwards.
local function persistBindings(charid)
    local worker = persistenceWorkers[charid]
    if not worker then
        worker = { running = false, pending = false }
        persistenceWorkers[charid] = worker
    end

    worker.pending = true
    if worker.running then return end
    worker.running = true

    local function flush()
        if not worker.pending then
            worker.running = false
            return
        end

        worker.pending = false
        local snapshot = {}
        for slot, binding in pairs(bindings[charid] or {}) do
            snapshot[#snapshot + 1] = {
                slot = slot,
                name = binding.name,
                type = binding.type,
                weaponId = binding.weaponId,
                metadata = binding.metadata and json.encode(binding.metadata) or nil,
            }
        end

        table.sort(snapshot, function(a, b) return a.slot < b.slot end)
        MySQL.update("DELETE FROM vorp_fastslots WHERE charidentifier = ?", { charid }, function()
            if #snapshot == 0 then
                flush()
                return
            end

            local remaining = #snapshot
            for _, row in ipairs(snapshot) do
                MySQL.update(
                    "INSERT INTO vorp_fastslots (charidentifier, slot, item_name, item_type, weapon_id, metadata) VALUES (?, ?, ?, ?, ?, ?)",
                    { charid, row.slot, row.name, row.type, row.weaponId, row.metadata },
                    function()
                        remaining = remaining - 1
                        if remaining == 0 then flush() end
                    end
                )
            end
        end)
    end

    flush()
end

-- ---------------------------------------------------------------------------
-- load / persist
-- ---------------------------------------------------------------------------

local function loadBindings(charid, cb)
    MySQL.query("SELECT slot, item_name, item_type, weapon_id, metadata FROM vorp_fastslots WHERE charidentifier = ? ORDER BY slot ASC", { charid }, function(rows)
        local map = {}
        local seenItems = {}
        local removedDuplicates = false
        for _, row in ipairs(rows or {}) do
            local meta = nil
            if row.metadata and row.metadata ~= "" then
                local ok, decoded = pcall(json.decode, row.metadata)
                if ok then meta = decoded end
            end

            local slot = tonumber(row.slot)
            local weaponId = tonumber(row.weapon_id)
            local itemKey = row.item_type == "item_weapon" and weaponId
                and ("weapon:%d"):format(weaponId)
                or string.lower(tostring(row.item_name or ""))
            if slot and slot >= 1 and slot <= MAX_SLOTS and itemKey ~= "" and not seenItems[itemKey] then
                seenItems[itemKey] = true
                map[slot] = { name = row.item_name, type = row.item_type, weaponId = weaponId, metadata = meta }
            else
                removedDuplicates = true
            end
        end
        bindings[charid] = map
        dbg("loadBindings: charid", charid, "loaded", #(rows or {}), "row(s)")
        if removedDuplicates then
            dbg("loadBindings: removed duplicate/invalid fast-slot rows for charid", charid)
            persistBindings(charid)
        end
        if cb then cb() end
    end)
end

local function withBindings(charid, cb)
    if bindings[charid] then
        cb(bindings[charid])
        return
    end

    if bindingLoadWaiters[charid] then
        bindingLoadWaiters[charid][#bindingLoadWaiters[charid] + 1] = cb
        return
    end

    bindingLoadWaiters[charid] = { cb }
    loadBindings(charid, function()
        local waiters = bindingLoadWaiters[charid] or {}
        bindingLoadWaiters[charid] = nil
        for _, waiter in ipairs(waiters) do
            waiter(bindings[charid] or {})
        end
    end)
end

local VALID_SORT_MODES = { category = true, name = true, count = true }
local VALID_CATEGORY_FILTERS = {
    all = true, medical = true, foods = true, weapons = true, ammo = true,
    tools = true, animals = true, documents = true, valuables = true,
    horse = true, herbs = true, other = true,
}

local function normalizeFavorites(value)
    local favorites = {}
    local count = 0
    if type(value) ~= "table" then return favorites end

    for key, entry in pairs(value) do
        local name = type(key) == "number" and entry or key
        local enabled = type(key) == "number" or entry == true
        if enabled and type(name) == "string" then
            name = string.lower(name:match("^%s*(.-)%s*$"))
            if name ~= "" and #name <= 100 and not favorites[name] and count < 300 then
                favorites[name] = true
                count = count + 1
            end
        end
    end
    return favorites
end

local function preferencesPayload(preference)
    local favorites = {}
    for name, enabled in pairs(preference.favorites or {}) do
        if enabled then favorites[#favorites + 1] = name end
    end
    table.sort(favorites)
    return {
        sortMode = preference.sortMode,
        categoryFilter = preference.categoryFilter,
        favorites = favorites,
    }
end

local function loadInventoryPreferences(charid, cb)
    MySQL.query("SELECT sort_mode, category_filter, favorites FROM vorp_inventory_preferences WHERE charidentifier = ? LIMIT 1", { charid }, function(rows)
        local row = rows and rows[1] or nil
        local decodedFavorites = {}
        if row and row.favorites and row.favorites ~= "" then
            local ok, decoded = pcall(json.decode, row.favorites)
            if ok then decodedFavorites = decoded end
        end

        inventoryPreferences[charid] = {
            sortMode = row and VALID_SORT_MODES[row.sort_mode] and row.sort_mode or "category",
            categoryFilter = row and VALID_CATEGORY_FILTERS[row.category_filter] and row.category_filter or "all",
            favorites = normalizeFavorites(decodedFavorites),
        }
        if cb then cb(inventoryPreferences[charid]) end
    end)
end

local function withInventoryPreferences(charid, cb)
    if inventoryPreferences[charid] then
        cb(inventoryPreferences[charid])
        return
    end

    if preferenceLoadWaiters[charid] then
        preferenceLoadWaiters[charid][#preferenceLoadWaiters[charid] + 1] = cb
        return
    end

    preferenceLoadWaiters[charid] = { cb }
    loadInventoryPreferences(charid, function(preference)
        local waiters = preferenceLoadWaiters[charid] or {}
        preferenceLoadWaiters[charid] = nil
        for _, waiter in ipairs(waiters) do waiter(preference) end
    end)
end

local function pushInventoryPreferences(_source, charid)
    withInventoryPreferences(charid, function(preference)
        TriggerClientEvent("vorp_inventory:preferences:sync", _source, preferencesPayload(preference))
    end)
end

-- ---------------------------------------------------------------------------
-- events
-- ---------------------------------------------------------------------------

AddEventHandler("vorp:SelectedCharacter", function(source)
    local _source = source
    local charid = getCharId(_source)
    if not charid then dbg("SelectedCharacter: no charid src", _source); return end
    srcToChar[_source] = charid
    dbg("SelectedCharacter: src", _source, "charid", charid, "-> โหลด binding")
    withBindings(charid, function()
        pushSync(_source)
    end)
    pushInventoryPreferences(_source, charid)
end)

-- client ขอ sync เอง (เผื่อ NUI พร้อมทีหลัง event เลือกตัวละคร)
RegisterServerEvent("vorp_inventory:fastslot:request", function()
    local _source = source
    local charid = srcToChar[_source] or getCharId(_source)
    if not charid then return end
    withBindings(charid, function() pushSync(_source) end)
end)

RegisterServerEvent("vorp_inventory:preferences:request", function()
    local _source = source
    local charid = srcToChar[_source] or getCharId(_source)
    if not charid then return end
    srcToChar[_source] = charid
    pushInventoryPreferences(_source, charid)
end)

RegisterServerEvent("vorp_inventory:preferences:update", function(data)
    local _source = source
    if type(data) ~= "table" then return end

    local now = GetGameTimer()
    if preferenceCooldown[_source] and (now - preferenceCooldown[_source]) < 150 then return end
    preferenceCooldown[_source] = now

    local charid = srcToChar[_source] or getCharId(_source)
    if not charid then return end
    srcToChar[_source] = charid

    withInventoryPreferences(charid, function(preference)
        preference.sortMode = VALID_SORT_MODES[data.sortMode] and data.sortMode or preference.sortMode
        preference.categoryFilter = VALID_CATEGORY_FILTERS[data.categoryFilter] and data.categoryFilter or preference.categoryFilter
        preference.favorites = normalizeFavorites(data.favorites)

        local payload = preferencesPayload(preference)
        MySQL.update(
            "REPLACE INTO vorp_inventory_preferences (charidentifier, sort_mode, category_filter, favorites) VALUES (?, ?, ?, ?)",
            { charid, preference.sortMode, preference.categoryFilter, json.encode(payload.favorites) }
        )
        TriggerClientEvent("vorp_inventory:preferences:sync", _source, payload)
    end)
end)

-- assign: ผู้เล่นลากไอเทมใส่ช่อง (มาจาก NUIAddItemToFastSlot ฝั่ง client)
RegisterServerEvent("vorp_inventory:fastslot:assign", function(slot, itemName, itemType, metadata, requestedWeaponId)
    local _source = source
    slot = tonumber(slot)
    if not slot or slot < 1 or slot > MAX_SLOTS then return end
    if type(itemName) ~= "string" or itemName == "" or #itemName > 100 then return end
    itemType = (itemType == "item_weapon") and "item_weapon" or "item_standard"
    if type(metadata) ~= "table" then metadata = nil end

    local charid = srcToChar[_source] or getCharId(_source)
    if not charid then dbg("assign: no charid for src", _source); return end
    srcToChar[_source] = charid

    -- trust boundary: ผู้เล่นต้องมีไอเทมนี้จริงถึงจะผูกได้
    requestedWeaponId = tonumber(requestedWeaponId)
    local requestedBinding = {
        name = itemName,
        type = itemType,
        weaponId = itemType == "item_weapon" and requestedWeaponId or nil,
    }
    local liveItem = findLiveItem(_source, requestedBinding)
    if not liveItem then
        dbg("assign REJECTED: src", _source, "charid", charid, "slot", slot, "item", itemName, "-> ผู้เล่นไม่มีไอเทมนี้ในกระเป๋า")
        return
    end

    -- Never trust type/metadata supplied by NUI. A modified client could otherwise label a
    -- standard item as a weapon and bypass the usable-item restriction.
    itemType = liveItem.type == "item_weapon" and "item_weapon" or "item_standard"
    metadata = type(liveItem.metadata) == "table" and liveItem.metadata or nil
    local binding = {
        name = liveItem.name,
        type = itemType,
        weaponId = itemType == "item_weapon" and tonumber(liveItem.id) or nil,
        metadata = metadata,
    }

    if itemType == "item_standard" and not UsableItemsFunctions[liveItem.name] then
        dbg("assign REJECTED: item", itemName, "is not registered as usable")
        Core.NotifyRightTip(_source, "This item cannot be used from a fast slot", 2500)
        pushSync(_source)
        return
    end

    withBindings(charid, function(charBindings)
        dbg("assign OK: src", _source, "charid", charid, "slot", slot, "item", itemName, "type", itemType)

        -- A hotbar item is unique by item name, matching findLiveItem/matchesBinding semantics.
        -- Assigning it to a new slot moves it instead of cloning it into multiple slots.
        local itemKey = itemType == "item_weapon" and binding.weaponId
            and ("weapon:%d"):format(binding.weaponId)
            or string.lower(itemName)
        local duplicateSlots = {}
        for existingSlot, existingBinding in pairs(charBindings) do
            local existingKey = existingBinding.type == "item_weapon" and existingBinding.weaponId
                and ("weapon:%d"):format(existingBinding.weaponId)
                or string.lower(tostring(existingBinding.name or ""))
            if existingSlot ~= slot and existingKey == itemKey then
                duplicateSlots[#duplicateSlots + 1] = existingSlot
            end
        end
        for _, duplicateSlot in ipairs(duplicateSlots) do
            charBindings[duplicateSlot] = nil
            dbg("assign: moved duplicate item", itemName, "from slot", duplicateSlot, "to", slot)
        end
        charBindings[slot] = binding

        persistBindings(charid)
        pushSync(_source)
    end)
end)

-- remove: เอาไอเทมออกจากช่อง
RegisterServerEvent("vorp_inventory:fastslot:remove", function(slot)
    local _source = source
    slot = tonumber(slot)
    if not slot or slot < 1 or slot > MAX_SLOTS then return end

    local charid = srcToChar[_source] or getCharId(_source)
    if not charid then return end

    withBindings(charid, function(charBindings)
        charBindings[slot] = nil
        persistBindings(charid)
        pushSync(_source)
    end)
end)

-- move/swap: client sends slot numbers only; binding data always comes from server memory
RegisterServerEvent("vorp_inventory:fastslot:move", function(fromSlot, toSlot)
    local _source = source
    fromSlot = tonumber(fromSlot)
    toSlot = tonumber(toSlot)
    if not fromSlot or not toSlot then return end
    if fromSlot < 1 or fromSlot > MAX_SLOTS or toSlot < 1 or toSlot > MAX_SLOTS then return end

    local charid = srcToChar[_source] or getCharId(_source)
    if not charid then return end

    withBindings(charid, function(charBindings)
        if not charBindings[fromSlot] then
            pushSync(_source)
            return
        end
        if fromSlot == toSlot then
            pushSync(_source)
            return
        end

        local sourceBinding = charBindings[fromSlot]
        local targetBinding = charBindings[toSlot]
        charBindings[toSlot] = sourceBinding
        charBindings[fromSlot] = targetBinding

        dbg("move: src", _source, "charid", charid, "slot", fromSlot, "->", toSlot, targetBinding and "(swap)" or "(move)")
        persistBindings(charid)
        pushSync(_source)
    end)
end)

-- use: กดปุ่มลัดเพื่อใช้ไอเทมในช่องนั้น
RegisterServerEvent("vorp_inventory:fastslot:use", function(slot)
    local _source = source
    slot = tonumber(slot)
    dbg("use: src", _source, "slot", slot)
    if not slot or slot < 1 or slot > MAX_SLOTS then dbg("use: slot ไม่ถูกต้อง"); return end

    -- rate limit ต่อผู้เล่น (กันกดรัว) — คู่กับ timerUse ฝั่ง useItem เดิมที่มีอยู่แล้ว
    local now = GetGameTimer()
    if useCooldown[_source] and (now - useCooldown[_source]) < 500 then dbg("use: cooldown"); return end
    useCooldown[_source] = now

    local charid = srcToChar[_source] or getCharId(_source)
    if not charid then dbg("use: no charid"); return end

    local binding = bindings[charid] and bindings[charid][slot]
    if not binding then dbg("use: ช่อง", slot, "ว่าง (ไม่มี binding) charid", charid); return end
    dbg("use: binding พบ ->", binding.name, "type", binding.type)

    local item = findLiveItem(_source, binding)
    if not item then
        dbg("use: หาไอเทม", binding.name, "ในกระเป๋าไม่เจอ (หมด/ไม่มี) -> sync count 0")
        pushSync(_source)
        return
    end
    dbg("use: เจอไอเทมสด id", item.id, "count", item.count, "-> เรียกใช้")

    if binding.type == "item_standard" then
        if not UsableItemsFunctions[item.name] then
            dbg("use: ^1ไอเทม", item.name, "ไม่ได้ลงทะเบียนเป็น usable item (ใช้ไม่ได้)^7")
        end
        -- ใช้ path เดิมของ inventory (InventoryService.UseItem อ่าน ambient `source` = ผู้เล่นคนนี้)
        InventoryService.UseItem({ id = item.id, item = item.name, type = "item_standard" })
        SetTimeout(150, function() pushSync(_source) end)
    else
        dbg("use: อาวุธ -> ส่งให้ client equip")
        TriggerClientEvent("vorp_inventory:fastslot:useWeapon", _source, { id = item.id, name = item.name, type = "item_weapon" })
    end
end)

-- อัปเดตจำนวนสดเมื่อมีการใช้ไอเทม (ไม่ว่าจะใช้จากช่องลัดหรือคลิกปกติ) ให้ hotbar ตรงเสมอ
AddEventHandler("vorp_inventory:Server:OnItemUse", function(arguments)
    local _source = arguments and arguments.source
    if not _source then return end
    if srcToChar[_source] and bindings[srcToChar[_source]] then
        SetTimeout(150, function() pushSync(_source) end)
    end
end)

AddEventHandler("playerDropped", function()
    local _source = source
    srcToChar[_source] = nil
    useCooldown[_source] = nil
    preferenceCooldown[_source] = nil
end)
