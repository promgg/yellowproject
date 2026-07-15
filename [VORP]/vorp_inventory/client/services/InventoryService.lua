ClientItems = {}
InventoryService = {}
UserWeapons = {}
UserInventory = {}
local initialLoadPending = false
local initialItemCount = 0
local initialWeaponCount = 0
local selectedCharacter = false
local inventoryReady = false


function InventoryService.receiveItem(name, id, amount, metadata, degradation, percentage)
	if not name or not ClientItems[name] then return end

	if UserInventory[id] ~= nil then
		UserInventory[id]:addCount(amount)
	else
		UserInventory[id] = Item:New({
			id = id,
			count = amount,
			limit = ClientItems[name].limit,
			label = ClientItems[name].label,
			name = name,
			metadata = SharedUtils.MergeTables(ClientItems[name].metadata, metadata),
			type = "item_standard",
			canUse = true,
			canRemove = ClientItems[name].canRemove,
			desc = ClientItems[name].desc,
			group = ClientItems[name].group or 1,
			weight = ClientItems[name].weight or 0.25,
			degradation = degradation,
			maxDegradation = ClientItems[name].maxDegradation,
			percentage = percentage
		})
	end
	NUIService.LoadInv()
end

function InventoryService.removeItem(name, id, count)
	local item = UserInventory[id]
	if not item then return end

	item:quitCount(count)

	if item:getCount() <= 0 then
		UserInventory[id] = nil
	end

	NUIService.LoadInv()
end

function InventoryService.receiveWeapon(id, propietary, name, ammos, label, serial_number, custom_label, source, custom_desc, weight)
	local weaponAmmo = {}

	for type, amount in pairs(ammos) do
		weaponAmmo[type] = tonumber(amount)
	end

	if not UserWeapons[id] then
		local newWeapon = Weapon:New({
			id = id,
			propietary = propietary,
			name = name,
			label = custom_label or label,
			ammo = weaponAmmo,
			used = false,
			used2 = false,
			desc = custom_desc or Utils.GetWeaponDefaultDesc(name),
			group = 5,
			source = source,
			serial_number = serial_number,
			custom_label = custom_label,
			custom_desc = custom_desc,
			weight = weight,

		})
		UserWeapons[newWeapon:getId()] = newWeapon
		NUIService.LoadInv()
	end
end

function InventoryService.setWeaponCustomLabel(id, label)
	if UserWeapons[id] then
		UserWeapons[id]:setCustomLabel(label)
	end
end

function InventoryService.setWeaponCustomDesc(id, desc)
	if UserWeapons[id] then
		UserWeapons[id]:setCustomDesc(desc)
	end
end

function InventoryService.setWeaponSerialNumber(id, serial_number)
	if UserWeapons[id] then
		UserWeapons[id]:setSerialNumber(serial_number)
	end
end

-- Keep the client-side weapon instance in sync when another server resource
-- changes the persisted component list (for example lp_gunsmith). The weapon
-- ID is important here: two copies of the same model may have different parts.
function InventoryService.syncWeaponComponents(id, components)
	id = tonumber(id)
	if not id or not UserWeapons[id] or type(components) ~= "table" then return end

	local normalized = {}
	for _, component in ipairs(components) do
		if type(component) == "string" then
			normalized[#normalized + 1] = component
		end
	end

	UserWeapons[id].components = normalized
end

function InventoryService.onSelectedCharacter()
	SetNuiFocus(false, false)
	SendNUIMessage({ action = "hide" })
	UserInventory = {}
	UserWeapons = {}
	initialLoadPending = true
	selectedCharacter = true
	inventoryReady = false
	initialItemCount = 0
	initialWeaponCount = 0
	print("[vorp_inventory] loading inventory")
	TriggerServerEvent("vorpinventory:getItemsTable")
	TriggerServerEvent("vorpinventory:getInventory")
end

function InventoryService.initialLoadComplete(itemCount, weaponCount)
	if not initialLoadPending then return end

	initialItemCount = tonumber(itemCount) or 0
	initialWeaponCount = tonumber(weaponCount) or 0
	TriggerServerEvent("vorpCore:LoadAllAmmo", true)
end

function InventoryService.ammoLoadComplete()
	if not initialLoadPending then return end

	initialLoadPending = false
	inventoryReady = true
	print(("[vorp_inventory] inventory ready items=%d weapons=%d")
		:format(initialItemCount, initialWeaponCount))
	TriggerEvent("vorpinventory:loaded")
end

function InventoryService.isReady()
	return selectedCharacter and inventoryReady
end

function InventoryService.processItems(items)
	ClientItems = {}
	local data = msgpack.unpack(items)
	for _, item in pairs(data) do
		ClientItems[item.item] = Item:New(item)
	end
end

-- Load inventory weapons on client start
function InventoryService.getLoadout(loadout)
	local primaryWeapons = {}
	local secondaryWeapons = {}

	for _, weapon in ipairs(loadout) do
		local weaponAmmo = weapon.ammo or {}
		for type, amount in pairs(weaponAmmo) do
			weaponAmmo[type] = tonumber(amount)
		end

		local weaponUsed = false
		local weaponUsed2 = false

		if weapon.used == true or tonumber(weapon.used) == 1 then weaponUsed = true end
		if weapon.used2 == true or tonumber(weapon.used2) == 1 then weaponUsed2 = true end
		weaponUsed = weaponUsed or weaponUsed2

		local currentInventory = weapon.currInv or weapon.curr_inv
		if currentInventory == "default" and (weapon.dropped == nil or tonumber(weapon.dropped) == 0) then
			local newWeapon = Weapon:New({
				id = tonumber(weapon.id),
				identifier = weapon.identifier,
				label = weapon.custom_label or Utils.GetWeaponDefaultLabel(weapon.name),
				name = weapon.name,
				ammo = weaponAmmo,
				components = weapon.components,
				used = weaponUsed,
				used2 = weaponUsed2,
				desc = weapon.custom_desc or Utils.GetWeaponDefaultDesc(weapon.name),
				currInv = currentInventory,
				dropped = 0,
				group = 5,
				custom_label = weapon.custom_label,
				serial_number = weapon.serial_number,
				custom_desc = weapon.custom_desc,
				weight = weapon.weight

			})
			UserWeapons[newWeapon:getId()] = newWeapon

			if newWeapon:getUsed() then
				local restoreList = newWeapon:getUsed2() and secondaryWeapons or primaryWeapons
				restoreList[#restoreList + 1] = newWeapon
			end
		end
	end

	-- Restore normal slots before off-hand slots so dual-wield weapons are placed
	-- consistently. Components are reapplied after the weapon exists on the ped.
	local function restoreWeapon(weapon)
		Utils.useWeapon(weapon:getId())
		weapon:loadComponents()

		local weaponHash = joaat(weapon:getName())
		local stateKey = string.format("GetEquippedWeaponData_%d", weaponHash)
		LocalPlayer.state:set(stateKey, {
			weaponId = weapon:getId(),
			serialNumber = weapon:getSerialNumber(),
		}, false)
	end

	for _, weapon in ipairs(primaryWeapons) do
		restoreWeapon(weapon)
	end

	for _, weapon in ipairs(secondaryWeapons) do
		restoreWeapon(weapon)
	end
end

function InventoryService.getInventory(inventory)
	UserInventory = {}
	local inventoryItems = msgpack.unpack(inventory)

	for id, item in pairs(inventoryItems) do
		UserInventory[item.id] = Item:New(
			{
				id = item.id,
				count = item.count,
				limit = item.limit,
				label = item.label,
				name = item.name,
				metadata = item.metadata,
				type = item.type,
				canUse = item.canUse,
				canRemove = item.canRemove,
				desc = item.desc,
				owner = item.owner,
				group = item.group,
				weight = item.weight,
				degradation = item.degradation,
				maxDegradation = item.maxDegradation,
				percentage = item.percentage
			})
	end
end
