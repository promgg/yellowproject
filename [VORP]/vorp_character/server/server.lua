local T = Translation.Langs[Lang]
local random = math.random(1, #Config.SpawnPosition)
local Core = exports.vorp_core:GetCore()

-- ตัวละครที่ถูกเลือกแล้วต่อ session — ต้องประกาศบนสุด เพราะทั้ง saveCharacter,
-- deleteCharacter และ vorp_CharSelectedCharacter ด้านล่างต้องอ่านค่านี้
-- (เดิมประกาศไว้กลางไฟล์ ทำให้ handler ที่อยู่เหนือมันมองไม่เห็น = เป็น nil global)
--
-- ⚠️ ต้องล้างตอน playerDropped ด้วย: key เป็น source ซึ่ง FiveM เอากลับมาใช้ซ้ำได้
-- ถ้าไม่ล้าง ผู้เล่นใหม่ที่ได้ source เดิมจะโดนปฏิเสธการเลือกตัวละครเงียบๆ
-- (setUsedCharacter ไม่เคยรัน -> getUsedCharacter คืน nil -> ไม่เซฟอะไรเลยทั้ง session)
local charSelected = {}


local function ConvertTable(comps, compTints)
	local NewComps = {}

	for k, comp in pairs(comps) do
		NewComps[k] = { comp = comp, tint0 = 0, tint1 = 0, tint2 = 0, palette = 0 }

		if compTints and compTints[k] and compTints[k][tostring(comp)] then
			local compTint = compTints[k][tostring(comp)]
			NewComps[k].tint0 = compTint.tint0 or 0
			NewComps[k].tint1 = compTint.tint1 or 0
			NewComps[k].tint2 = compTint.tint2 or 0
			NewComps[k].palette = compTint.palette or 0
			-- jo_clothingstore integration: ส่ง state ต่อไปด้วย (เสื้อผ้าบางชิ้นมีสถานะ เช่น พับแขน/เปิดปก)
			-- ไม่งั้น jo_libs อ่านสถานะชิ้นนั้นไม่ได้ ชุดที่ใส่จะเพี้ยนตอน sync
			NewComps[k].state = compTint.state or nil
		end
	end

	return NewComps
end

local function Checkmissingkeys(data, key)
	local switch = false
	if key == "skin" then
		for k, v in pairs(PlayerSkin) do
			if data[k] == nil then
				switch = true
				data[k] = v
			end
			if data.Eyes == 0 then
				switch = true
				if data.sex == "mp_male" then
					data.Eyes = 612262189
				else
					data.Eyes = 928002221
				end
			end
		end
		return data, switch
	end
	if key == "comps" then
		for k, v in pairs(PlayerClothing) do
			if data[k] == nil then
				data[k] = v.comp
			end
		end
		return data, switch
	end
end

local function UpdateDatabase(character)
	local json_skin = json.decode(character.skin)
	local json_comps = json.decode(character.comps)
	local compTints = json.decode(character.compTints)
	local skin, updateSkin = Checkmissingkeys(json_skin, "skin")
	local comps, updateComp = Checkmissingkeys(json_comps, "comps")

	if updateSkin then
		character.updateSkin((json.encode(skin)))
	end

	if updateComp then
		character.updateComps(json.encode(comps))
	end

	local NewComps = ConvertTable(comps, compTints)

	return skin, NewComps
end

local function GetPlayerData(source)
	local User = Core.getUser(source)

	if not User then
		return false
	end
	local Characters = User.getUserCharacters


	local userCharacters = {}
	for _, characters in pairs(Characters) do
		local skin, comps = UpdateDatabase(characters)
		local userChars = {
			charIdentifier = characters.charIdentifier,
			money = characters.money,
			gold = characters.gold,
			firstname = characters.firstname,
			lastname = characters.lastname,
			skin = skin,
			components = comps,
			coords = json.decode(characters.coords),
			isDead = characters.isdead,
			job = characters.jobLabel or "Unemployed",
			grade = characters.jobGrade or "",
			group = characters.group or "",
			age = characters.age or "",
			nickname = characters.nickname or "",
			gender = characters.gender or "",
			charDesc = characters.charDescription or "",
		}
		userCharacters[#userCharacters + 1] = userChars
	end
	return userCharacters
end

AddEventHandler("vorp_CreateNewCharacter", function(source)
	TriggerClientEvent("vorpcharacter:startCharacterCreator", source)
end)

local function iniSpawn()
	local numSpawns = #Config.SpawnCoords
	if numSpawns == 0 then return print("update config file") end

	local randomIndex = math.random(1, numSpawns)
	local selectedSpawn = Config.SpawnCoords[randomIndex]

	return selectedSpawn.position, selectedSpawn.heading
end

RegisterServerEvent("vorpcharacter:saveCharacter", function(data)
	local _source = source

	-- ── กันสร้างตัวละครกลาง session ────────────────────────────────────────
	-- 🔒 ช่องโหว่เดิม: event นี้ไม่มี guard เลยสักชั้น (ไม่เช็ค user, ไม่เช็คว่าอยู่ในเกมแล้ว,
	-- ไม่เช็คลิมิตจำนวนตัวละคร) ผู้เล่นที่กำลังเล่นอยู่ยิง event นี้ได้ตลอดเวลา
	-- addCharacter() จะ INSERT ตัวละครใหม่ค่าเริ่มต้น แล้ว "สลับตัวละครที่ใช้อยู่" ไปเป็นตัวใหม่
	-- ผลคือตัวจริงหยุดถูกเซฟทันที — ทุกอย่างตั้งแต่ login (เงิน/xp/ของ/พิกัด) หายตอนออก
	-- และยังทะลุ Config.MaxCharacters ไปด้วย
	local user = Core.getUser(_source)
	if not user then return end

	-- อยู่ในเกมแล้ว (เลือกตัวละครไปแล้ว) = ไม่ใช่ขั้นตอนสร้างตัว ปฏิเสธ
	if charSelected[_source] then
		print(("^1[vorp_character] saveCharacter: src %s อยู่ในเกมแล้ว ปฏิเสธการสร้างตัวละคร^0"):format(tostring(_source)))
		return
	end

	-- ลิมิตจำนวนตัวละครต่อบัญชี — เดิมบังคับแค่ฝั่ง client (client.lua:654 วนตาม MaxCharacters)
	-- ใช้ API ตัวเดียวกับที่ selectCharacter ในไฟล์นี้ใช้อยู่ (GetPlayerData / Core.maxCharacters)
	local existing = GetPlayerData(_source)
	local maxChars = Core.maxCharacters(_source)
	if existing and maxChars and #existing >= maxChars then
		print(("^1[vorp_character] saveCharacter: src %s มีตัวละครครบลิมิตแล้ว (%d)^0")
			:format(tostring(_source), maxChars))
		return
	end

	user.addCharacter(data)
	Wait(600)
	local iniPos, iniHead = iniSpawn()
	TriggerClientEvent("vorp:initCharacter", _source, iniPos, iniHead, false)
	SetTimeout(3000, function()
		TriggerEvent("vorp_NewCharacter", _source)
	end)
end)

RegisterServerEvent("vorpcharacter:deleteCharacter", function(selectedChar)
	local _source = source
	local user = Core.getUser(_source)
	if user then
		local charid = selectedChar and selectedChar.charIdentifier
		if not charid then return end

		-- ── กันลบตัวละครที่กำลังเล่นอยู่ ─────────────────────────────────────
		-- 🔒 เดิม event นี้ยิงได้ตลอดเวลารวมถึงตอนอยู่ในเกม = DELETE แถวตัวละครที่ใช้อยู่
		-- ตัว object ในหน่วยความจำยังอยู่ แล้ว SaveCharacterInDb ก็ยิง UPDATE ไปที่แถวที่หายแล้ว
		-- (0 rows affected เงียบๆ) — ข้อมูลทั้ง session หายและกู้ไม่ได้
		if charSelected[_source] then
			print(("^1[vorp_character] deleteCharacter: src %s อยู่ในเกมแล้ว ปฏิเสธการลบ^0"):format(tostring(_source)))
			return
		end

		-- ต้องเป็นตัวละครของบัญชีตัวเองเท่านั้น — เดิมเชื่อ charIdentifier จาก client ตรงๆ
		-- จึงลบตัวละครของคนอื่นได้ถ้ารู้/เดา charIdentifier
		local owns = false
		for _, c in pairs(user.getUserCharacters or {}) do
			if tonumber(c.charIdentifier) == tonumber(charid) then owns = true break end
		end
		if not owns then
			print(("^1[vorp_character] deleteCharacter: src %s ไม่ได้เป็นเจ้าของ charid %s ปฏิเสธ^0")
				:format(tostring(_source), tostring(charid)))
			return
		end
		local SteamName = GetPlayerName(_source)
		local SteamId = GetPlayerIdentifiers(_source)[1]
		local description = "SteamID : " .. SteamId .. "\n" .. "Steam Name : " .. SteamName .. "\n" ..
			"Playername : " .. selectedChar.firstname .. " " .. selectedChar.lastname .. "\n" .. "Character Description : " ..
			selectedChar.charDesc
		Core.AddWebhook(Logs.DeleteCharacterWebhhok.Title, Logs.WebhookUrl, description, Logs.color, Logs.DeleteCharacterWebhhok.WebhookName, Logs.logo, Logs.footerlogo, Logs.avatar)
		user.removeCharacter(charid)
	end
end)

RegisterServerEvent("vorp_CharSelectedCharacter", function(charid)
	local _source = source
	if charSelected[_source] then return print("player has already selected a character") end

	-- player exists
	local user <const> = Core.getUser(_source)
	if user then
		charSelected[_source] = true
		user.setUsedCharacter(charid)
	end
end)

-- ── ล้าง state ต่อ session ตอนผู้เล่นออก ──────────────────────────────────────
-- 🔒 ทั้ง resource นี้ "ไม่มี playerDropped เลยสักตัว" มาก่อน ทำให้ charSelected โตขึ้น
-- เรื่อยๆ ไม่มีวันถูกล้าง และเนื่องจาก key เป็น source ที่ FiveM เอากลับมาใช้ซ้ำได้
-- ผู้เล่นใหม่ที่ได้ source เดิมจะโดน "player has already selected a character" ปฏิเสธ
-- -> setUsedCharacter ไม่เคยรัน -> getUsedCharacter คืน nil ทั้ง session
-- -> savePlayer ตอนออกไม่เซฟอะไรเลย (ผู้เล่นเป็น "ผี" อยู่ในเกมแต่ไม่มีตัวละครฝั่ง server)
AddEventHandler('playerDropped', function()
	charSelected[source] = nil
end)



RegisterNetEvent("vorpcharacter:setPlayerCompChange", function(skinValues, compsValues)
	local _source = source
	local user = Core.getUser(_source)
	if user then
		local character = user.getUsedCharacter
		if compsValues then
			character.updateComps(json.encode(compsValues))
		end

		if skinValues then
			character.updateSkin(json.encode(skinValues))
		end
	end
end)


AddEventHandler("vorp_character:server:SpawnUniqueCharacter", function(source)
	local userCharacters = GetPlayerData(source)
	if not userCharacters then
		return
	end
	TriggerClientEvent("vorpcharacter:spawnUniqueCharacter", source, userCharacters)
end)

if Config.DevMode then
	RegisterServerEvent("vorp_character:server:GoToSelectionMenu")
end

AddEventHandler("vorp_character:server:GoToSelectionMenu", function(src)
	local _source = Config.DevMode and source or src

	if not Config.DevMode then
		if Player(_source).state.IsInSession then
			return print("player is past selection")
		end
	end

	local UserCharacters = GetPlayerData(_source)

	if not UserCharacters then
		return
	end

	local MaxCharacters = Core.maxCharacters(_source)
	if not MaxCharacters then
		return
	end

	TriggerClientEvent("vorpcharacter:selectCharacter", _source, UserCharacters, MaxCharacters, random)
end)


Core.Callback.Register("vorp_characters:getMaxCharacters", function(source, cb)
	local MaxCharacters = Core.maxCharacters(source)

	if not MaxCharacters then
		return
	end

	cb(#MaxCharacters)
end)

Core.Callback.Register("vorp_character:callback:PayToShop", function(source, callback, arguments)
	local user = Core.getUser(source)
	if not user then
		return callback(false)
	end
	local character = user.getUsedCharacter
	local money = character.money

	-- ── ตรวจจำนวนเงินที่ client ส่งมา ────────────────────────────────────────
	-- 🔒 ช่องโหว่เดิม: amountToPay มาจาก client ตรงๆ ไม่ตรวจอะไรเลย
	-- ส่งค่าติดลบมา -> เงื่อนไข "money < -1000000" เป็นเท็จ = ผ่านด่านเช็คเงินพอ
	-- -> removeCurrency(0, -1000000) ทำ money - (-1000000) = เพิ่มเงินหนึ่งล้าน
	-- และ SaveCurrency() เขียนลง DB ทันที = เงินไม่จำกัด ทำซ้ำได้ไม่มี cooldown
	--
	-- callback นี้ client ยิงถึงจริง: Core.Callback ถูก dispatch จาก
	-- RegisterNetEvent("vorp:TriggerServerCallback") ไม่ใช่ server-only
	-- (vorp_core มี guard ซ้ำอีกชั้นแล้ว แต่ต้องกันที่นี่ด้วย ไม่งั้นด่าน "เงินพอ" ยังพลิกได้)
	local amountToPay = tonumber(arguments and arguments.amount)
	if not amountToPay or amountToPay ~= amountToPay          -- nil / NaN
		or amountToPay == math.huge or amountToPay == -math.huge -- inf
		or amountToPay < 0 then
		print(("^1[vorp_character] PayToShop: จำนวนเงินไม่ถูกต้อง (%s) จาก src %s^0")
			:format(tostring(arguments and arguments.amount), tostring(source)))
		return callback(false)
	end

	if money < amountToPay then
		SetTimeout(5000, function()
			Core.NotifyRightTip(source, string.format(T.PayToShop.DontMoney, amountToPay), 6000)
		end)
		return callback(false)
	end

	SetTimeout(5000, function()
		Core.NotifyRightTip(source, string.format(T.PayToShop.Youpaid, amountToPay), 6000)
	end)

	character.removeCurrency(0, amountToPay)

	if arguments.skin then
		character.updateSkin((json.encode(arguments.skin)))
	end

	if arguments.comps then
		character.updateComps(json.encode(arguments.comps))
	end

	if arguments.compTints then
		character.updateCompTints(json.encode(arguments.compTints))
	end

	if arguments.Result and arguments.Result ~= '' then
		local Parameters = { character.identifier, character.charIdentifier, arguments.Result, json.encode(arguments.comps), json.encode(arguments.compTints) }

		---@diagnostic disable-next-line: undefined-global
		MySQL.insert("INSERT INTO outfits (identifier, charidentifier, title, comps, compTints) VALUES (?, ?, ? ,?, ?)", Parameters)
	end

	return callback(true)
end)

local function CanProcceed(user, source)
	local character = user.getUsedCharacter
	local money = ConfigShops.SecondChanceCurrency == 0 and character.money or ConfigShops.SecondChanceCurrency == 1 and character.gold or ConfigShops.SecondChanceCurrency == 2 and character.rol
	local amountToPay = ConfigShops.SecondChancePrice
	local moneyType = ConfigShops.SecondChanceCurrency == 0 and "money" or ConfigShops.SecondChanceCurrency == 1 and "gold" or ConfigShops.SecondChanceCurrency == 2 and "rol"

	if money < amountToPay then
		Core.NotifyRightTip(source, string.format(T.PayToShop.notenoughtMoney, moneyType, ConfigShops.SecondChancePrice), 6000)
		return false
	end

	return true
end

Core.Callback.Register("vorp_character:callback:CanPayForSecondChance", function(source, callback)
	local user = Core.getUser(source)

	if not user then
		return callback(false)
	end

	if not CanProcceed(user, source) then
		return callback(false)
	end

	return callback(true)
end)

Core.Callback.Register("vorp_character:callback:PayForSecondChance", function(source, callback, data)
	local user = Core.getUser(source)

	if not user then
		return callback(false)
	end
	local character = user.getUsedCharacter

	if not CanProcceed(user, source) then
		return callback(false)
	end

	if data.comps then
		character.updateComps(json.encode(data.comps))
	end

	if data.skin then
		character.updateSkin(json.encode(data.skin))
	end

	if data.compTints then
		character.updateCompTints(json.encode(data.compTints))
	end

	character.removeCurrency(ConfigShops.SecondChanceCurrency, ConfigShops.SecondChancePrice)

	return callback(true)
end)

Core.Callback.Register("vorp_character:callback:GetOutfits", function(source, callback)
	local character = Core.getUser(source).getUsedCharacter

	MySQL.query("SELECT * FROM outfits WHERE `charidentifier` = ?", { character.charIdentifier }, function(Outfits)
		return callback(Outfits)
	end)
end)

Core.Callback.Register("vorp_character:callback:SetOutfit", function(source, callback, arguments)
	local user = Core.getUser(source)
	if not user then return callback(false) end

	local character = user.getUsedCharacter
	local unpacked = msgpack.unpack(arguments.Outfit)
	arguments.Outfit = unpacked

	if type(arguments.Outfit.comps) ~= "string" then
		arguments.Outfit.comps = json.encode(arguments.Outfit.comps)
	end

	if type(arguments.Outfit.compTints) ~= "string" then
		arguments.Outfit.compTints = json.encode(arguments.Outfit.compTints)
	end

	character.updateComps(arguments.Outfit.comps or '{}')
	character.updateCompTints(arguments.Outfit.compTints or '{}')

	return callback(true)
end)

Core.Callback.Register("vorp_character:callback:DeleteOutfit", function(source, callback, arguments)
	local user = Core.getUser(source)
	if not user then return callback(false) end

	local character = user.getUsedCharacter
	-- why is it using steam? each character should have its own set of outfits
	MySQL.query.await("DELETE FROM outfits WHERE charidentifier = ? AND id = ?", { character.charIdentifier, arguments.id })

	return callback(true)
end)

-- EXPORT TO OPEN MENU THROUGH OTHER SCRIPTS
exports("OpenOutfitsMenu", function(source)
	local user = Core.getUser(source)
	if not user then return end
	local character = user.getUsedCharacter

	local result = MySQL.query.await("SELECT id, title, comps, compTints FROM outfits WHERE `charidentifier` = ?", { character.charIdentifier })
	if not result then return end

	local packed = msgpack.pack(result)
	TriggerClientEvent("vorp_character:Client:OpenOutfitsMenu", source, packed)
	return true
end)
