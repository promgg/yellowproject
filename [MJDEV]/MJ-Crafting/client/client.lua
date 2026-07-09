Keys = {
    ["CAPSLOCK"] = 0xCEE12B50, -- RetVal never on Pressed
    ["PAGEDOWN"] = 0x51104035,
    ["PAGEUP"] = 0x6FED71BC,
    ["F"] = 0xD2CC4644,
    ["J"] = 0xF3830D8E,
    ["N"] = 0x4BC9DABB,
    ["BACKSPACE"] = 0x156F7119,
    ["ENTER"] = 0xC7B5340A,
    ["U"] = 0xD8F73058,
    ["B"] = 0x4CC0E2FE,
    ["Q"] = 0xCBD5B26E,
    ["X"] = 0x8CC9CD42,
    ["Z"] = 0x26E9DC00,
    ["V"] = 0x7F8D09B8,
    ["W"] = 0x8FD015D8,
    ["S"] = 0xD27782E3,
    ["A"] = 0x7065027D,
    ["D"] = 0xB4E465B4,
    ["CTRL"] = 0xDB096B85,
    ["TAB"] = 0xE6360A8E,
    ["SPACE"] = 0xD9D0E1C0,
    ["SHIFT"] = 0x8FFC75D6,
    ["LEFTCLICK"] = 0x07CE1E61,
    ["RIGHTCLICK"] = 0xF84FA74F,
    ["R"] = 0xE30CD707,
    ["E"] = 0xCEFD9220,
    ["ALT"] = 0x580C4473,
    ["H"] = 0x24978A28,
    ["C"] = 0x9959A6F0,
    ["DEL"] = 0x4AF4D473,
    ["L"] = 0x80F28E95,
    ["MouseL"] = 0xA987235F,
    ["MouseR"] = 0xD2047988,
    ["MouseUp"] = 0xC0651D40,
    ["MouseDown"] = 0x8ED92E16,
    ["MouseLeft"] = 0x08F8BC6D,
    ["MouseRight"] = 0xA1EB1353,
    ["DownArrow"] = 0x05CA7C52,
    ["UpArrow"] = 0x6319DB71,
    ["LeftArrow"] = 0xA65EBAB4,
    ["RightArrow"] = 0xDEB34313,
    ["WHEELDOWN"] = 0xD0842EDF,
    ["WHEELUP"] = 0xF78D7337,
    ["G"] = 0xA1ABB953,
    ["T"] = 0x9720FCEE,
    ["I"] = 0xC1989F95,
    ["["] = 0x430593AA,
    ["]"] = 0xA5BDCD3C
}

local Routers = nil
local CraftingTable = {}
local PlayerData = nil
local CraftingType = {}
local ListObject = {}
local CategoryListCl = {}
local Nametable = "โต๊ะคราฟไอเทม"
local MenuOn = false
local number = 1
local category = 1
local craftting_process = false

local Core = exports.vorp_core:GetCore()

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    TriggerServerEvent('MJ-Crafting:GetSetupResources')
end)

RegisterNetEvent('MJ-Crafting:SetConfigData')
AddEventHandler('MJ-Crafting:SetConfigData', function(cfg, re)
    SendNUIMessage({
        image = Config["Image_Source"]
    })
    Routers = re
    CategoryListCl = cfg
    StartEvent()
    print("^7[^1CLP^7][^4" .. GetCurrentResourceName() .. "^7] - Loading resources success.")
end)

-- Display object
Citizen.CreateThread(function()
    for k, v in pairs(Config["Craft_Table"]) do
        if v.Disable_Model == false and v.Disable_Model ~= nil then
            local model = v.Model
            local Objects = vector3(v.Position.x, v.Position.y, v.Position.z - 1)
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(10)
            end
            local obj = CreateObject(model, Objects, false, false, false)
            SetEntityHeading(obj, v.Position.h)
            SetEntityVelocity(obj, 0.0, 0.0, -2.0)
            PlaceObjectOnGroundProperly(obj)
            FreezeEntityPosition(obj, true)
            table.insert(ListObject, obj)
        end
    end
end)

function StartEvent()
    -- print(DumpTable(LocalPlayer))
    local Inventorys = Core.Callback.TriggerAwait("MJ-Crafting:getDBItem")
    function CheckJob(joblist)
        local job = Core.Callback.TriggerAwait("MJ-Crafting:GetJob")
        if joblist == 0 then
            return true
        end

        if joblist ~= 0 then
            for k, v in pairs(joblist) do
                if v == job then
                    return true
                end
            end
        end

        return false
    end

    function CheckJobClient(joblist)
        if joblist == 0 then
            return true
        end

        if joblist ~= 0 then
            for k, v in pairs(joblist) do
                if v == LocalPlayer.state.Character.Job then
                    return true
                end
            end
        end

        return false
    end

    function DoesPlayerExist(pServerId)
        local playerId = GetPlayerFromServerId(tonumber(pServerId))
        if playerId ~= -1 then
            return true
        end
    end

    RegisterNetEvent('MJ-Crafting:PlayWithinDistanceCl')
    AddEventHandler('MJ-Crafting:PlayWithinDistanceCl', function(playerNetId, maxDistance, soundFile, soundVolume)
        if not DoesPlayerExist(playerNetId) then
            return
        end
        local lCoords = GetEntityCoords(PlayerPedId())
        local eCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(playerNetId)))
        local distIs = Vdist(lCoords.x, lCoords.y, lCoords.z, eCoords.x, eCoords.y, eCoords.z)
        if (distIs <= maxDistance) then
            SendNUIMessage({
                acton = 'Sound',
                transactionType = 'playSound',
                transactionFile = soundFile,
                transactionVolume = soundVolume
            })
        end
    end)

    RegisterNetEvent('MJ-Crafting:RemoveWeaponCl')
    AddEventHandler('MJ-Crafting:RemoveWeaponCl', function(weapon)
        RemoveWeaponFromPed(PlayerPedId(), weapon)
    end)

    -- Display Texts
    local Texts = false
    AddEventHandler('MJ-Crafting:Displaytexts', function()
        Texts = true
        while Texts do
            Citizen.Wait(1)
            if not MenuOn then
                local letSleep = true
                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)
                for k, v in pairs(Config["Craft_Table"]) do
                    local distance = GetDistanceBetweenCoords(coords, v.Position.x, v.Position.y, v.Position.z, true)
                    if distance < 10 then
                        if distance < 5 then
                            if v.Disable_Model == false and v.Disable_Model ~= nil then
                                letSleep = false
                                if v.Name ~= nil then
                                    DrawText3D(v.Position.x, v.Position.y, v.Position.z + 0.65, v.Name)
                                end
                                if v.Desc ~= nil then
                                    DrawText3D(v.Position.x, v.Position.y, v.Position.z + 0.54, v.Desc)
                                end
                            end
                        else
                            Texts = false
                        end
                    end
                end
                if letSleep == true then
                    Citizen.Wait(1500)
                end
            else
                Citizen.Wait(1500)
            end
        end
    end)

    -- Display DrawText3D
    function DrawText3D(x, y, z, text)
        local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
        local px, py, pz = table.unpack(GetGameplayCamCoord())
        local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)
        local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
        if onScreen then
            SetTextScale(0.30, 0.30)
            SetTextFontForCurrentCommand(10)
            SetTextColor(255, 255, 255, 215)
            SetTextCentre(1)
            DisplayText(str, _x, _y)
            local factor = (string.len(text)) / 225
            DrawSprite("feeds", "hud_menu_4a", _x, _y + 0.0125, 0.015 + factor, 0.03, 0.1, 35, 35, 35, 190, 0)
        end
    end

    -- Display Blip
    Citizen.CreateThread(function()
        for k, v in pairs(Config["Craft_Table"]) do
            if v.Map_blip == true and v.Map_blip ~= nil then
                blips = Citizen.InvokeNative(0x554D9D53F696D002, -758970771, v.Position.x, v.Position.y, v.Position.z)
                Blip_Name = "Crafting Table"
                Blip_Scale = 0.9
                Blip_Sprite = 605
                Blip_Color = 24
                if v.Blip_scale ~= nil then
                    Blip_Scale = v.Blip_scale
                end
                if v.Blip_sprite ~= nil then
                    Blip_Sprite = v.Blip_sprite
                end
                if v.Blip_color ~= nil then
                    Blip_Color = v.Blip_color
                end
                if v.Blip_name ~= nil then
                    Blip_Name = v.Blip_name
                end
                SetBlipSprite(blips, Blip_Sprite)
                SetBlipScale(blips, Blip_Scale)
                AddTextEntry('BLIP_CRAFTING', Blip_Name)
                Citizen.InvokeNative(0x9CB1A1623062F402, blips, Blip_Name)
            end
        end
    end)

    -- Display markers
    local Markers = false
    AddEventHandler('MJ-Crafting:Displaymarkers', function()
        while Markers do
            Citizen.Wait(2)
            if not MenuOn then
                local letSleep = true
                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)
                for k, v in pairs(Config["Craft_Table"]) do
                    local distance = GetDistanceBetweenCoords(coords, v.Position.x, v.Position.y, v.Position.z, true)
                    if distance < 15 then
                        if distance < 10 then
                            if v.Marker == true and v.Marker ~= nil then
                                letSleep = false
                                Marker_Type = 1
                                Marker_Scale = {0.5, 0.5, 0.5}
                                Marker_Color = {0, 0, 0}
                                if v.Marker_Scale ~= nil then
                                    Marker_Scale = v.Marker_Scale
                                end
                                if v.Marker_Type ~= nil then
                                    Marker_Type = v.Marker_Type
                                end
                                if v.Marker_Color ~= nil then
                                    Marker_Color = v.Marker_Color
                                end
                                DrawMarker(Marker_Type, v.Position.x, v.Position.y, v.Position.z - 1, 0.0, 0.0, 0.0,
                                    0.0, 0.0, 0.0, Marker_Scale[1], Marker_Scale[2], Marker_Scale[3], Marker_Color[1],
                                    Marker_Color[2], Marker_Color[3], 100, false, true, 2, true, false, false, false)
                            end
                        else
                            Markers = false
                        end
                    end
                end
                if letSleep == true then
                    Citizen.Wait(1500)
                end
            else
                Citizen.Wait(1500)
            end
        end
    end)

    Citizen.CreateThread(function()
        while true do
            local letSleep = 1500
            if craftting_process then
                letSleep = 0
                DisableAllControlActions(0)
            end
            Citizen.Wait(letSleep)
        end
    end)

    -- Display markers
    Citizen.CreateThread(function()
        Citizen.Wait(3000)
        local GetJob = true
        while true do
            Citizen.Wait(5)
            if not MenuOn then
                local letSleep = true
                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)
                for k, v in pairs(Config["Craft_Table"]) do
                    local statusjob = false
                    local distance = GetDistanceBetweenCoords(coords, v.Position.x, v.Position.y, v.Position.z, true)
                    if distance < 10 then
                        letSleep = false
                        if v.Marker == true and v.Marker ~= nil then
                            if distance < 9 and Markers == false then
                                TriggerEvent('MJ-Crafting:Displaymarkers')
                            end
                        end

                        if v.Disable_Model == false and v.Disable_Model ~= nil then
                            if distance < 4 and Texts == false then
                                TriggerEvent('MJ-Crafting:Displaytexts')
                            end
                        end

                        if distance < v.Max_Distance then
                            if v.job ~= nil then
                                if v.job[1] ~= nil then
                                    for k, v in pairs(v.job) do
                                        -- print(CheckJob(v))
                                        if CheckJob(v) then
                                            statusjob = true
                                        end
                                    end
                                end
                            else
                                statusjob = true
                            end

                            if statusjob then
                                DrawText3D(v.Position.x, v.Position.y, v.Position.z, "Press [G] TO " .. v.Table_Name)
                                if IsControlJustReleased(0, 0xA1ABB953) then
                                    TriggerEvent("MJ-Crafting:OpenMenuCraft", v.Category, v.Position, v.Table_Name)
                                    -- TriggerScreenblurFadeIn()
                                    Citizen.Wait(1500)
                                end
                            else
                                ShowHelpNotification('<font face="' .. Config["Font"] ..
                                                         '">~r~ไม่สามามารถเปิดหน้าโต๊ะคราฟได้~s~</font>')
                            end
                        end
                    end
                end
                if letSleep then
                    Citizen.Wait(2500)
                end
            else
                Citizen.Wait(1500)
            end
        end
    end)

    AddEventHandler('MJ-Crafting:OpenMenuCraft', function(id, position, tablename)
        if tablename == nil then
            tablename = "โต๊ะคราฟ"
        end
        local Frist = true
        Nametable = tablename
        for s, o in pairs(id) do
            for k, v in pairs(CategoryListCl[o].list) do
                local label = ""
                for key, value in pairs(Inventorys) do
                    if v.item == value.item then
                        label = value.label
                    end
                end
                local Weapons_label = ""
                for key, value in pairs(Config.LsitWeapons) do
                    if v.item == value.name then
                        Weapons_label = value.label
                    end
                end
                local cost = {}
                for ks, vls in pairs(v.cost) do
                    if ks == "Rol" then
                        table.insert(cost, {
                            name = ks,
                            amox = vls,
                            label = "เงินผิดกฏหมาย"
                        })
                    end
                    if ks == "Money" then
                        table.insert(cost, {
                            name = ks,
                            amox = vls,
                            label = "เงินถูกกฏหมาย"
                        })
                    end
                    if ks == "Gold" then
                        table.insert(cost, {
                            name = ks,
                            amox = vls,
                            label = "เงินถูกกฏหมาย"
                        })
                    end
                end

                local blueprint = {}
                for key, value in pairs(Inventorys) do
                    for ks, vls in pairs(v.blueprint) do
                        if ks == value.item then
                            table.insert(blueprint, {
                                name = ks,
                                amox = vls,
                                label = value.label
                            })
                        end
                    end
                end

                local equipment = {}
                if v.equipment ~= nil then
                    for ks, vls in pairs(v.equipment) do
                        for key, value in pairs(Inventorys) do
                            if ks == value.item then
                                table.insert(equipment, {
                                    name = ks,
                                    status = vls,
                                    label = value.label
                                })
                            end
                        end
                    end
                else
                    equipment = nil
                end

                local removeweaponaftercraftcraft = false

                if v.removeweaponaftercraft ~= nil then
                    removeweaponaftercraftcraft = v.removeweaponaftercraft
                end

                local fail_item = {}
                local custom_percent_failitem = 0
                if v.fail_item ~= nil then
                    if v.custom_percent_failitem ~= nil then
                        custom_percent_failitem = v.custom_percent_failitem
                    end
                    for key, value in pairs(Inventorys) do
                        for ks, vls in pairs(v.fail_item) do
                            if ks == value.item then
                                table.insert(fail_item, {
                                    name = ks,
                                    amox = vls,
                                    label = value.label
                                })
                            end
                        end
                    end
                else
                    fail_item = nil
                end

                if Frist == true then
                    category = o
                    if string.find(v.item, "WEAPON_", 1) == nil then
                        table.insert(CraftingTable, {
                            Category = o,
                            categoryname = CategoryListCl[o].name,
                            position = position,
                            id = k,
                            type = "item_standard",
                            item = v.item,
                            label = label,
                            fail_chance = v.fail_chance,
                            fail_item = fail_item,
                            custom_percent_failitem = custom_percent_failitem,
                            cost = cost,
                            blueprint = blueprint,
                            equipment = equipment,
                            persentremove_fail = persentremove_fail,
                            status = true
                        })
                    else
                        table.insert(CraftingTable, {
                            Category = o,
                            categoryname = CategoryListCl[o].name,
                            position = position,
                            id = k,
                            type = "item_weapon",
                            item = v.item,
                            label = Weapons_label,
                            fail_chance = v.fail_chance,
                            fail_item = fail_item,
                            custom_percent_failitem = custom_percent_failitem,
                            cost = cost,
                            blueprint = blueprint,
                            equipment = equipment,
                            persentremove_fail = persentremove_fail,
                            status = true
                        })
                    end
                    Frist = false
                else
                    if string.find(v.item, "WEAPON_", 1) == nil then
                        table.insert(CraftingTable, {
                            Category = o,
                            categoryname = CategoryListCl[o].name,
                            position = position,
                            id = k,
                            type = "item_standard",
                            item = v.item,
                            label = label,
                            fail_chance = v.fail_chance,
                            fail_item = fail_item,
                            custom_percent_failitem = custom_percent_failitem,
                            cost = cost,
                            blueprint = blueprint,
                            equipment = equipment,
                            persentremove_fail = persentremove_fail,
                            status = false
                        })
                    else
                        table.insert(CraftingTable, {
                            Category = o,
                            categoryname = CategoryListCl[o].name,
                            position = position,
                            id = k,
                            type = "item_weapon",
                            item = v.item,
                            label = Weapons_label,
                            fail_chance = v.fail_chance,
                            fail_item = fail_item,
                            custom_percent_failitem = custom_percent_failitem,
                            cost = cost,
                            blueprint = blueprint,
                            equipment = equipment,
                            persentremove_fail = persentremove_fail,
                            status = false
                        })
                    end
                end
                -- print(Frist)
            end
            table.insert(CraftingType, {
                Category = o,
                categoryname = CategoryListCl[o].name
            })
        end
        MenuOn = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            acton = 'openmenu',
            image = Config["Image_Source"],
            nametable = tablename,
            data = CraftingTable,
            datatype = CraftingType,
            category = category
        })
    end)

    RegisterNUICallback('ChooseType', function(s)
        category = s.category
        local frist = true
        for k, v in pairs(CraftingTable) do
            if v.Category == s.category then
                if frist then
                    v.status = true
                    frist = false
                else
                    v.status = false
                end
            else
                v.status = false
            end
        end
        SendNUIMessage({
            acton = 'openmenu',
            image = Config["Image_Source"],
            nametable = Nametable,
            slesc = 'choose',
            data = CraftingTable,
            datatype = CraftingType,
            category = category,
            number = number
        })
    end)

    RegisterNUICallback('Choose', function(s)
        number = s.number
        for k, v in pairs(CraftingTable) do
            if v.Category == category then
                if v.id == s.data.id then
                    if v.item == s.data.item then
                        v.status = true
                    end
                else
                    v.status = false
                end
            end
        end
        SendNUIMessage({
            acton = 'openmenu',
            image = Config["Image_Source"],
            nametable = Nametable,
            slesc = 'choose',
            data = CraftingTable,
            datatype = CraftingType,
            category = category,
            number = number
        })
    end)

    RegisterNUICallback('SetCount', function(s)
        number = s.number
        SendNUIMessage({
            acton = 'openmenu',
            image = Config["Image_Source"],
            nametable = Nametable,
            slesc = 'choose',
            data = CraftingTable,
            datatype = CraftingType,
            category = category,
            number = number
        })
    end)

    RegisterNUICallback('Crafting', function(s)
		if craftting_process then return end
		craftting_process = true

		local count = tonumber(s.data) or 1
		if count <= 0 then
			TriggerEvent("pNotify:SendNotification", {
				text = 'จำนวนไม่ถูกต้อง',
				type = "error",
				timeout = 5000,
				layout = "centerLeft",
				queue = "left"
			})
			craftting_process = false
			return
		end

		local inventory = Core.Callback.TriggerAwait("MJ-Crafting:inventory")

		for _, v in pairs(CraftingTable) do
			if v.status then
				local valid = true

				if not checkEquipment(inventory, v.equipment) then
					valid = false
				end

				if not checkBlueprint(inventory, v.blueprint, count) then
					valid = false
				end

				print(valid)
				if valid then
					TriggerEvent('MJ-Crafting:Crafting', v.type, v.blueprint, v.cost, v.item, count, v.fail_chance, v.position, v.fail_item, v.custom_percent_failitem, v.persentremove_fail)
				end

				break
			end
		end

		SetTimeout(1500, function()
			craftting_process = false
		end)
	end)

	function checkEquipment(inventory, equipment)
		if not equipment then return true end
		for _, eq in pairs(equipment) do
			for _, invItem in pairs(inventory) do
				if eq.name == invItem.name and eq.status and invItem.count <= 0 then
					TriggerEvent("pNotify:SendNotification", {
						text = 'ไม่พบอุปกรณ์ที่ต้องใช้',
						type = "warning",
						timeout = 5000,
						layout = "centerLeft",
						queue = "left"
					})
					return false
				end
			end
		end
		return true
	end

	function checkBlueprint(inventory, blueprint, count)
		if not blueprint then return true end
		for _, bp in pairs(blueprint) do
			for _, invItem in pairs(inventory) do
				if bp.name == invItem.name and invItem.count < (bp.amox * count) then
					TriggerEvent("pNotify:SendNotification", {
						text = 'วัสดุอุปกรณ์มีไม่เพียงพอ',
						type = "warning",
						timeout = 5000,
						layout = "centerLeft",
						queue = "left"
					})
					return false
				end
			end
		end
		return true
	end

    RegisterNUICallback('Close', function(s)
        MenuOn = false
        CraftingTable = {}
        CraftingType = {}
        SetNuiFocus(false, false)
        SendNUIMessage({
            acton = 'closemenus'
        })
    end)

    AddEventHandler('MJ-Crafting:Notification', function(reason)
        SendNUIMessage({
            notification = 'notification',
            text = reason
        })
        TriggerEvent("pNotify:SendNotification", {
            text = reason,
            type = "warning",
            timeout = 5000,
            layout = "centerLeft",
            queue = "left"
        })
    end)

    AddEventHandler('MJ-Crafting:CloseMenu', function()
        MenuOn = false
        CraftingTable = {}
        CraftingType = {}
        SetNuiFocus(false, false)
        SendNUIMessage({
            acton = 'closemenus'
        })
    end)

    AddEventHandler('MJ-Crafting:Crafting',
        function(type, item, money, give, count, statuscount, position, failitem, custom_percent_failitem,
            persentremove_fail)
            local status = Core.Callback.TriggerAwait("MJ-Crafting:ChackItem", item)
            if status then
                SetEntityHeading(PlayerPedId(), position.h)
                TriggerEvent("MJ-Crafting:CloseMenu")
                MenuOn = true
                TriggerEvent("MJ-Crafting:NotificationCraft", position, function(Status)
                    print(Status)
                    if Status then
                        MenuOn = false
                        ClearPedTasks(PlayerPedId())
                        TriggerServerEvent("MJ-Crafting:CraftItem", type, item, money, give, count, statuscount,
                            failitem, custom_percent_failitem, persentremove_fail)
                    else
                        MenuOn = false
                        ClearPedTasks(PlayerPedId())
                    end
                end)
            end
        end)

    local CrafystatusNoft = false
    local persent = 0

    AddEventHandler('MJ-Crafting:NotificationCraft', function(position, cb)
        persent = 0
        CrafystatusNoft = true
        isAnim = false
        TriggerEvent('MJ-Crafting:NotificationCraftShow', position)
        while CrafystatusNoft do
            Citizen.Wait(5)
            if not isAnim then
                local Player = PlayerPedId()
                if (DoesEntityExist(Player) and not IsEntityDead(Player)) then
                    loadAnimDict(Config["Animation"][1])
                    TaskPlayAnim(Player, Config["Animation"][1], Config["Animation"][2], 3.0, 1.0, -1, 31, 0, 0, 0, 0)
                end
                isAnim = true
            end
            persent = persent + 0.15
            if persent >= 100 then
                CrafystatusNoft = false
                ClearPedTasks(PlayerPedId())
                cb(true)
            end
            if IsControlJustReleased(0, 0xCEFD9220) then
                CrafystatusNoft = false
                cb(false)
            end
        end
    end)

    AddEventHandler('MJ-Crafting:NotificationCraftShow', function(position)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local distance = GetDistanceBetweenCoords(coords, position.x, position.y, position.z, true)
        while CrafystatusNoft do
            Wait(5)
            if distance < 5 then
                DrawText3D(position.x, position.y, position.z + 0.1, 'Press ~g~[G] ~s~to Cancel.')
                DrawText3D(position.x, position.y, position.z + 0.5, 'Crafting items')
                DrawText3D(position.x, position.y, position.z + 0.25, string.format("%.2f", persent) .. '%')
            end
        end
    end)

    function loadAnimDict(dict)
        while (not HasAnimDictLoaded(dict)) do
            RequestAnimDict(dict)
            Wait(5)
        end
    end

    AddEventHandler("onResourceStop", function(resource)
        if resource == GetCurrentResourceName() then
            for k, v in pairs(ListObject) do
                DeleteObject(v)
                DeleteEntity(v)
            end
        end
    end)

    function ShowHelpNotification(msg)
        TriggerEvent("pNotify:SendNotification", {
            text = msg,
            type = "warning",
            timeout = 5000,
            layout = "centerLeft",
            queue = "left"
        })
    end
end
