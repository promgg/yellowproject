local Core   = exports.vorp_core:GetCore()
ServerItems  = {}
UsersWeapons = { default = {} }
WeaponDatabase = WeaponDatabase or {}

local sourceCharacters = {}
local sourceLoadGeneration = {}

-- temporary just to assing serial numbers to old weapons and labels will be removed eventually
MySQL.ready(function()
	DBService.queryAsync('SELECT name,id,label,serial_number FROM loadout', {},
		function(result)
			if next(result) then
				for _, db_weapon in pairs(result) do
					local label = db_weapon.label or SvUtils.GenerateWeaponLabel(db_weapon.name)
					local serialNumber = db_weapon.serial_number or SvUtils.GenerateSerialNumber(db_weapon.name)
					if not db_weapon.serial_number then
						DBService.updateAsync('UPDATE loadout SET serial_number = @serial_number WHERE id = @id', { id = db_weapon.id, serial_number = serialNumber }, function() end)
					end
					if not db_weapon.label then
						DBService.updateAsync('UPDATE loadout SET label = @label WHERE id = @id', { id = db_weapon.id, label = label }, function() end)
					end
				end
			end
		end)
end)


--- load all player weapons
---@param db_weapon table
local function loadAllWeapons(db_weapon)
	local ammo = json.decode(db_weapon.ammo)
	local comp = json.decode(db_weapon.components)

	if db_weapon.dropped == 0 then
		local label = db_weapon.custom_label or db_weapon.label
		local weight = SvUtils.GetWeaponWeight(db_weapon.name)
		local used = db_weapon.used == true or tonumber(db_weapon.used) == 1
		local used2 = db_weapon.used2 == true or tonumber(db_weapon.used2) == 1
		local weapon = Weapon:New({
			id = db_weapon.id,
			propietary = db_weapon.identifier,
			name = db_weapon.name,
			ammo = ammo,
			components = comp,
			used = used or used2,
			used2 = used2,
			charId = db_weapon.charidentifier,
			currInv = db_weapon.curr_inv,
			dropped = db_weapon.dropped,
			group = 5,
			label = label,
			serial_number = db_weapon.serial_number,
			custom_label = db_weapon.custom_label,
			custom_desc = db_weapon.custom_desc,
			weight = weight,
		})

		if not UsersWeapons[db_weapon.curr_inv] then
			UsersWeapons[db_weapon.curr_inv] = {}
		end

		UsersWeapons[db_weapon.curr_inv][weapon:getId()] = weapon
		return weapon
	else
		DBService.deleteAsync('DELETE FROM loadout WHERE id = @id', { id = db_weapon.id }, function() end)
	end

	return nil
end




--- load player default inventory weapons
---@param source number
---@param character table character table data
local function clearCharacterWeapons(charIdentifier)
	if not charIdentifier then return end

	for weaponId, weapon in pairs(UsersWeapons.default) do
		if tostring(weapon.charId) == tostring(charIdentifier) then
			UsersWeapons.default[weaponId] = nil
		end
	end
end

-- Loads the selected character's weapons and only calls back after SQL and the
-- server cache are both ready. The old flow fired this query in the background
-- while getInventory immediately read the cache, which intermittently sent an
-- empty loadout to the client.
function WeaponDatabase.LoadPlayerWeapons(source, character, callback)
	local _source = source
	local charIdentifier = character and character.charIdentifier
	if not charIdentifier then
		if callback then callback({}) end
		return
	end

	sourceCharacters[_source] = charIdentifier
	sourceLoadGeneration[_source] = (sourceLoadGeneration[_source] or 0) + 1
	local generation = sourceLoadGeneration[_source]
	DBService.queryAsync(
		"SELECT * FROM loadout WHERE charidentifier = ? AND curr_inv = 'default' AND dropped = 0",
		{ charIdentifier },
		function(result)
			if sourceLoadGeneration[_source] ~= generation or
				tostring(sourceCharacters[_source]) ~= tostring(charIdentifier) then
				return
			end

			clearCharacterWeapons(charIdentifier)
			local playerWeapons = {}

			for _, db_weapon in pairs(result or {}) do
				local weapon = loadAllWeapons(db_weapon)
				if weapon then
					playerWeapons[#playerWeapons + 1] = weapon
				end
			end

			if callback then callback(playerWeapons) end
		end
	)
end

function WeaponDatabase.ClearSource(source, fallbackCharIdentifier)
	local charIdentifier = sourceCharacters[source] or fallbackCharIdentifier
	sourceLoadGeneration[source] = (sourceLoadGeneration[source] or 0) + 1
	clearCharacterWeapons(charIdentifier)
	sourceCharacters[source] = nil
end

function WeaponDatabase.GetSourceCharacter(source)
	return sourceCharacters[source]
end


MySQL.ready(function()
	-- load all items from database
	DBService.queryAsync("SELECT * FROM items", {}, function(result)
		for _, db_item in pairs(result) do
			if db_item.id then
				local item = Item:New({
					id = db_item.id,
					item = db_item.item,
					metadata = db_item.metadata or {},
					label = db_item.label,
					limit = db_item.limit,
					type = db_item.type,
					canUse = db_item.usable,
					canRemove = db_item.can_remove,
					desc = db_item.desc,
					group = db_item.groupId,
					weight = db_item.weight,
					maxDegradation = db_item.degradation,
				})
				ServerItems[item.item] = item
			end
		end
	end)

	--load all secondary inventory weapons from database
	DBService.queryAsync("SELECT * FROM loadout", {}, function(result)
		for _, db_weapon in pairs(result) do
			if db_weapon.curr_inv ~= "default" then
				loadAllWeapons(db_weapon)
			end
		end
	end)
end)

local function cacheImages()
	-- only items from the database because items folder can contain duplicates or unused images
	local newtable = {}
	for k, v in pairs(ServerItems) do
		newtable[k] = v.item
	end
	-- all weapon images from config because items folder can contain duplicates or unused images
	for k, v in pairs(SharedData.Weapons) do
		newtable[k] = k
	end
	local packed = msgpack.pack(newtable)

	return packed
end

-- on player select character event
AddEventHandler("vorp:SelectedCharacter", function(source, char)
	local packed = cacheImages()
	TriggerClientEvent("vorp_inventory:server:CacheImages", source, packed)
end)

-- reload on script restart for testing
if Config.DevMode then
	RegisterNetEvent("DEV:loadweapons", function()
		local _source = source
		local character = Core.getUser(_source).getUsedCharacter
		WeaponDatabase.LoadPlayerWeapons(_source, character)

		local packed = cacheImages()
		TriggerClientEvent("vorp_inventory:server:CacheImages", _source, packed)
	end)
end
