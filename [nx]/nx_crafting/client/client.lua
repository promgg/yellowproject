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
local CategoryListCl = {}
local Nametable = "โต๊ะคราฟไอเทม"
local MenuOn = false
local number = 1
local category = 1
local selectedItemIndex = 1
local selectedRecipeIndex = 1
local craftting_process = false

local Core = exports.vorp_core:GetCore()

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    TriggerServerEvent('nx_crafting:server:getSetupResources')
end)

RegisterNetEvent('nx_crafting:client:setConfigData')
AddEventHandler('nx_crafting:client:setConfigData', function(cfg, re)
    SendNUIMessage({
        image = Config["Image_Source"]
    })
    Routers = re
    CategoryListCl = cfg
    StartEvent()
    print("^7[^1CLP^7][^4" .. GetCurrentResourceName() .. "^7] - Loading resources success.")
end)

-- ── prop ของโต๊ะคราฟ: สร้าง/เก็บตามระยะ (แพตเทิร์นเดียวกับ nx_shop) ─────────────
--
-- ของเดิมสร้าง prop ของทุกโต๊ะพร้อมกันครั้งเดียวตอน resource start แล้วทิ้งไว้ตลอด
-- ปัญหา: ตอนบูตผู้เล่นยืนอยู่จุดเดียว โต๊ะที่เหลืออยู่คนละมุมแผนที่ CreateObject
-- ตรงนั้นอาจไม่ติดหรือโดนเกมเก็บทิ้ง แล้วไม่มีอะไรมาสร้างใหม่ = โต๊ะไม่มี prop ถาวร
-- (บั๊กแบบเดียวกับที่เจอใน lp_planting)
--
-- เก็บ handle ไว้บน entry ของโต๊ะเอง (v._prop) เหมือน nx_shop เก็บ store._npc
local function spawnTableProp(v)
    if v.Disable_Model ~= false or v._prop then return end

    local model = v.Model
    RequestModel(model)
    local timeout = GetGameTimer() + 3000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(10) end
    if not HasModelLoaded(model) then
        print(('[nx_crafting] โหลดโมเดลไม่สำเร็จ: %s'):format(tostring(v.Table_Name)))
        return
    end

    local obj = CreateObject(model, v.Position.x, v.Position.y, v.Position.z - 1, false, false, false)
    if not DoesEntityExist(obj) then return end

    SetEntityHeading(obj, v.Position.h)
    SetEntityVelocity(obj, 0.0, 0.0, -2.0)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(model)

    v._prop = obj
end

local function removeTableProp(v)
    if not v._prop then return end
    if DoesEntityExist(v._prop) then
        DeleteObject(v._prop)
        DeleteEntity(v._prop)
    end
    v._prop = nil
end

function StartEvent()
    -- print(DumpTable(LocalPlayer))
    local Inventorys = Core.Callback.TriggerAwait("nx_crafting:server:getDBItems")
    local function IsJobAllowed(joblist, job)
        if joblist == nil or joblist == 0 then
            return true
        end

        if type(joblist) == "string" then
            return joblist == job
        end

        if type(joblist) == "table" then
            for _, allowedJob in pairs(joblist) do
                if allowedJob == job then
                    return true
                end
            end
        end

        return false
    end

    function CheckJob(joblist)
        local job = Core.Callback.TriggerAwait("nx_crafting:server:getJob")
        return IsJobAllowed(joblist, job)
    end

    function CheckJobClient(joblist)
        local character = LocalPlayer and LocalPlayer.state and LocalPlayer.state.Character
        return IsJobAllowed(joblist, character and character.Job)
    end

    local function SanitizeAmount(value)
        local amount = tonumber(value)
        if amount == nil or amount ~= amount or amount == math.huge or amount == -math.huge then
            return 1, false
        end

        amount = math.floor(amount)
        if amount <= 0 then
            return 1, false
        end

        if amount > 100 then
            amount = 100
        end

        return amount, true
    end

    function DoesPlayerExist(pServerId)
        local playerId = GetPlayerFromServerId(tonumber(pServerId))
        if playerId ~= -1 then
            return true
        end
    end

    local function GetItemLabel(itemName)
        for _, value in pairs(Inventorys or {}) do
            if value.item == itemName or value.name == itemName then
                return value.label or itemName
            end
        end

        return itemName
    end

    local function GetWeaponLabel(weaponName)
        for _, value in pairs(Config.LsitWeapons or {}) do
            if weaponName == value.name then
                return value.label or weaponName
            end
        end

        return weaponName
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

    local function ShallowCopy(source)
        local copy = {}
        if type(source) ~= "table" then
            return copy
        end
        for key, value in pairs(source) do
            copy[key] = value
        end
        return copy
    end

    local function SortedNumericKeys(source)
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

    local function CollectRecipeEntries(rawRecipes)
        local recipes = {}
        if type(rawRecipes) ~= "table" then
            return recipes
        end

        local hasIndexedRecipe = false
        for key, value in pairs(rawRecipes) do
            local recipeIndex = tonumber(key)
            if recipeIndex ~= nil and type(value) == "table" then
                recipes[recipeIndex] = ShallowCopy(value)
                hasIndexedRecipe = true
            end
        end

        if not hasIndexedRecipe then
            recipes[1] = ShallowCopy(rawRecipes)
        end

        return recipes
    end

    local function NormalizeCraftItem(itemEntry)
        if type(itemEntry) ~= "table" then
            return itemEntry
        end

        local recipes = CollectRecipeEntries(itemEntry.recipe or itemEntry.recipes)
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

    local function AmountFromRow(row)
        if type(row) ~= "table" then
            return tonumber(row) or 0
        end

        return tonumber(row.amox or row.amount or row.count or row.qty or row.quantity or row[2]) or 0
    end

    local function CostLabel(name)
        if name == "Rol" then
            return "เน€เธเธดเธเธเธดเธ”เธเธเธซเธกเธฒเธข"
        end
        if name == "Money" or name == "Gold" then
            return "เน€เธเธดเธเธ–เธนเธเธเธเธซเธกเธฒเธข"
        end
        return GetItemLabel(name)
    end

    local function BuildAmountList(source, labelFn)
        local list = {}
        if type(source) ~= "table" then
            return list
        end

        for key, value in pairs(source) do
            local name = nil
            local amount = 0
            local label = nil
            if type(value) == "table" then
                name = value.name or value.item or value.id or (type(key) == "string" and key or nil)
                amount = AmountFromRow(value)
                label = value.label
            else
                name = type(key) == "string" and key or nil
                amount = AmountFromRow(value)
            end

            if type(name) == "string" and amount > 0 then
                table.insert(list, {
                    name = name,
                    amox = amount,
                    label = label or labelFn(name)
                })
            end
        end

        return list
    end

    local function BuildToolList(source)
        local list = {}
        if type(source) ~= "table" then
            return list
        end

        for key, value in pairs(source) do
            local name = nil
            local amount = 1
            local status = true
            local label = nil
            if type(value) == "table" then
                name = value.name or value.item or value.id or (type(key) == "string" and key or nil)
                amount = AmountFromRow(value)
                if amount <= 0 then
                    amount = 1
                end
                status = value.status
                if status == nil then
                    status = value.required
                end
                if status == nil then
                    status = true
                end
                label = value.label
            else
                name = type(key) == "string" and key or nil
                if type(value) == "boolean" then
                    status = value
                end
            end

            if type(name) == "string" then
                table.insert(list, {
                    name = name,
                    amox = amount,
                    status = status,
                    label = label or GetItemLabel(name)
                })
            end
        end

        return list
    end

    local function RecipeDisplayLabel(recipe, recipeIndex)
        if type(recipe) == "table" then
            return recipe.label or recipe.title or ("Recipe " .. tostring(recipeIndex))
        end
        return "Recipe " .. tostring(recipeIndex)
    end

    local function IsWeaponItem(itemName)
        return type(itemName) == "string" and string.find(string.upper(itemName), "WEAPON_", 1, true) ~= nil
    end

    local function BuildRecipePayload(categoryId, itemIndex, itemEntry, recipeIndex, recipeEntry, position)
        local payload = ShallowCopy(recipeEntry)
        local tools = BuildToolList(recipeEntry.toolsList or recipeEntry.equipment)
        local failed = BuildAmountList(recipeEntry.failedList or recipeEntry.fail_item, GetItemLabel)

        payload.Category = categoryId
        payload.categoryIndex = categoryId
        payload.categoryname = CategoryListCl[categoryId] and CategoryListCl[categoryId].name
        payload.position = position
        payload.id = itemIndex
        payload.itemIndex = itemIndex
        payload.recipeIndex = recipeIndex
        payload.item = itemEntry.item
        payload.recipeLabel = RecipeDisplayLabel(recipeEntry, recipeIndex)
        payload.cost = BuildAmountList(recipeEntry.cost, CostLabel)
        payload.blueprint = BuildAmountList(recipeEntry.blueprint, GetItemLabel)
        payload.toolsList = tools
        payload.equipment = tools
        payload.failedList = failed
        payload.fail_item = failed
        payload.status = false

        return payload
    end

    local function BuildCraftItemPayload(categoryId, itemIndex, itemEntry, position)
        NormalizeCraftItem(itemEntry)

        local isWeapon = IsWeaponItem(itemEntry.item)
        local itemType = itemEntry.type or (isWeapon and "item_weapon" or "item_standard")
        local itemLabel = itemEntry.label or (isWeapon and GetWeaponLabel(itemEntry.item) or GetItemLabel(itemEntry.item))
        local payload = {
            Category = categoryId,
            categoryIndex = categoryId,
            categoryname = CategoryListCl[categoryId] and CategoryListCl[categoryId].name,
            position = position,
            id = itemIndex,
            itemIndex = itemIndex,
            type = itemType,
            item = itemEntry.item,
            label = itemLabel,
            image = itemEntry.image,
            status = false,
            recipes = {}
        }

        for _, key in ipairs(SortedNumericKeys(itemEntry.recipe)) do
            local recipePayload = BuildRecipePayload(categoryId, itemIndex, itemEntry, key, itemEntry.recipe[key], position)
            recipePayload.type = recipePayload.type or itemType
            table.insert(payload.recipes, recipePayload)
        end

        return payload
    end

    local function FindCraftItem(categoryId, itemIndex)
        for _, itemEntry in pairs(CraftingTable) do
            if tonumber(itemEntry.categoryIndex or itemEntry.Category) == tonumber(categoryId) and
                tonumber(itemEntry.itemIndex or itemEntry.id) == tonumber(itemIndex) then
                return itemEntry
            end
        end
        return nil
    end

    local function FindRecipePayload(categoryId, itemIndex, recipeIndex)
        local itemEntry = FindCraftItem(categoryId, itemIndex)
        if not itemEntry then
            return nil, nil
        end

        for _, recipeEntry in pairs(itemEntry.recipes or {}) do
            if tonumber(recipeEntry.recipeIndex) == tonumber(recipeIndex) then
                return itemEntry, recipeEntry
            end
        end

        return itemEntry, nil
    end

    local function FirstItemInCategory(categoryId)
        for _, itemEntry in pairs(CraftingTable) do
            if tonumber(itemEntry.categoryIndex or itemEntry.Category) == tonumber(categoryId) then
                return itemEntry
            end
        end
        return nil
    end

    local function SetSelectedCraft(categoryId, itemIndex, recipeIndex)
        category = tonumber(categoryId) or category
        selectedItemIndex = tonumber(itemIndex) or 1
        selectedRecipeIndex = tonumber(recipeIndex) or 1

        for _, itemEntry in pairs(CraftingTable) do
            local itemActive = tonumber(itemEntry.categoryIndex or itemEntry.Category) == category and
                tonumber(itemEntry.itemIndex or itemEntry.id) == selectedItemIndex
            itemEntry.status = itemActive
            for _, recipeEntry in pairs(itemEntry.recipes or {}) do
                recipeEntry.status = itemActive and tonumber(recipeEntry.recipeIndex) == selectedRecipeIndex
            end
        end
    end

    RegisterNetEvent('nx_crafting:client:playWithinDistance')
    AddEventHandler('nx_crafting:client:playWithinDistance', function(playerNetId, maxDistance, soundFile, soundVolume)
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

    RegisterNetEvent('nx_crafting:client:removeWeapon')
    AddEventHandler('nx_crafting:client:removeWeapon', function(weapon)
        RemoveWeaponFromPed(PlayerPedId(), weapon)
    end)

    -- Display Texts
    local Texts = false
    AddEventHandler('nx_crafting:client:displayTexts', function()
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
                            -- ข้อความ 3D แยกสวิตช์จาก Disable_Model แล้ว (ดู Config.Show3DText)
                            if Config.Show3DText and v.Disable_Model == false and v.Disable_Model ~= nil then
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
                blips = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, v.Position.x, v.Position.y, v.Position.z) -- blip type คงที่สำหรับ blip พิกัด (ตรงกับ nx_shop/lp_marketplace/MJ-Economy) — เดิมใส่ hash sprite ผิดช่องมาแทน
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
    AddEventHandler('nx_crafting:client:displayMarkers', function()
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
    -- Hold-to-open (E) — เข้าใกล้โต๊ะคราฟ ลอยติดตำแหน่งโต๊ะ (v.Position) ผ่าน exports.lp_textui:TextUIHold()
    -- แทน DrawText3D + IsControlJustReleased(G) เดิม เรียก TextUIHold แค่ครั้งเดียวตอนเข้าระยะ (ไม่ใช่ทุกเฟรม)
    -- + hysteresis กันสั่นตรงขอบระยะ (เข้า < Max_Distance, ออก < Max_Distance+0.5) ตามแพทเทิร์นเดียวกับ Lumberjack/Mining/Economy
    --
    -- โต๊ะคราฟหลายตัวตั้งใกล้กันจนระยะเข้าซ้อนกัน (ยืนยันจาก debug log จริง: Weapon Crafting/Wood
    -- Whittling/Wood Plank ที่ Rhodes ห่างกันแค่ ~2-3m ขณะ Max_Distance = 2.5 ทุกตัว) lp_textui เก็บ
    -- สถานะ hold แบบ global ตัวเดียว (ดู [LP]/lp_textui/client/main.lua) — เดิมทุกโต๊ะที่ inRange ต่างเรียก
    -- TextUIHold/CancelHold ของตัวเองอิสระต่อกัน ทำให้ 2 อาการ: (1) มี 2 โต๊ะ inRange พร้อมกัน คำเรียกหลัง
    -- ตัด thread ของคำเรียกก่อนทิ้งกลางคันโดยไม่ hide UI ให้ ค้าง craftHintShown เป็น true ทั้งที่ไม่มีอะไร
    -- ขึ้นจอ (2) วิ่งผ่านโต๊ะ A ทำให้ A.craftHintShown ค้าง true ชั่วคราว พอ A หลุดระยะช้ากว่า B ที่กำลังโชว์
    -- อยู่จริง cancelCraftHint(A) ก็ไปเรียก CancelHold() แบบ global ซึ่งดับ prompt ของ B ที่ถูกต้องอยู่แล้วทิ้ง
    -- ไปด้วย ("ยืนที่ General Crafting แต่ textui ไม่ขึ้น" ทั้งที่ไม่ได้อยู่ใกล้โต๊ะไหนอื่นเลย)
    --
    -- แก้ด้วยการล็อกโต๊ะ "active" ไว้ตัวเดียวแบบ sticky ต่อครั้ง — ไม่คำนวณโต๊ะใกล้สุดใหม่ทุกติ๊ก แต่อยู่กับ
    -- โต๊ะเดิมต่อไปจนกว่าจะออกนอกระยะของโต๊ะนั้นเองจริง (ผ่าน hysteresis) แล้วค่อยหาโต๊ะใกล้สุดตัวใหม่มาแทน
    local craftHintShown = {} -- [tableIndex] = true/false (มีจริงแค่ 1 key ที่ true ในคราวเดียว = activeTableK)
    local activeTableK = nil
    local CRAFT_TEXTUI_OWNER = 'nx_crafting:table'

    local function cancelCraftHint(k)
        if craftHintShown[k] then
            craftHintShown[k] = false
            exports.lp_textui:CancelHold(CRAFT_TEXTUI_OWNER)
        end
    end

    Citizen.CreateThread(function()
        Citizen.Wait(3000)
        while true do
            Citizen.Wait(150)
            if not MenuOn then
                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)
                local distances = {}
                local debugInRangeNow = Config.Debug and {} or nil

                for k, v in pairs(Config["Craft_Table"]) do
                    local distance = GetDistanceBetweenCoords(coords, v.Position.x, v.Position.y, v.Position.z, true)
                    distances[k] = distance

                    -- สร้าง prop เมื่อเข้าใกล้ เก็บเมื่อออกไกล — ระยะเก็บมากกว่าระยะสร้าง
                    -- เพื่อไม่ให้ prop กะพริบตอนเดินไปมาตรงขอบพอดี
                    -- เช็คทุกรอบด้วย ไม่ใช่แค่ตอนข้ามเส้น: ถ้า object โดนเกมเก็บทิ้งเอง
                    -- v._prop จะยังชี้ไปที่ entity ที่ตายแล้ว รอบถัดไปจะสร้างใหม่ให้
                    local spawnDist  = tonumber(v.PropSpawnDistance) or Config.PropSpawnDistance or 60.0
                    local removeDist = tonumber(v.PropRemoveDistance) or Config.PropRemoveDistance or 80.0
                    if v.Disable_Model == false then
                        if distance <= spawnDist then
                            if not (v._prop and DoesEntityExist(v._prop)) then
                                v._prop = nil
                                spawnTableProp(v)
                            end
                        elseif distance > removeDist then
                            removeTableProp(v)
                        end
                    end

                    if distance < 10 then
                        if v.Marker == true and v.Marker ~= nil then
                            if distance < 9 and Markers == false then
                                TriggerEvent('nx_crafting:client:displayMarkers')
                            end
                        end

                        -- ไม่ต้องสตาร์ตลูปข้อความเลยถ้าปิดไว้ (ลูปนี้วิ่ง Wait(1) กินเปล่า)
                        if Config.Show3DText and v.Disable_Model == false and v.Disable_Model ~= nil then
                            if distance < 4 and Texts == false then
                                TriggerEvent('nx_crafting:client:displayTexts')
                            end
                        end
                    end

                    if debugInRangeNow and distance < (v.Max_Distance or 0) then
                        table.insert(debugInRangeNow, ('%s(k=%s,d=%.2f)'):format(v.Table_Name or '?', tostring(k), distance))
                    end
                end

                if debugInRangeNow and #debugInRangeNow > 1 then
                    print(('[nx_crafting][debug] !! %d tables in range at once (active: k=%s): %s'):format(
                        #debugInRangeNow, tostring(activeTableK), table.concat(debugInRangeNow, ' | ')))
                end

                if activeTableK and not exports.lp_textui:IsHoldActive(CRAFT_TEXTUI_OWNER) then
                    craftHintShown[activeTableK] = false
                    activeTableK = nil
                end

                local activeStillInRange = false
                if activeTableK then
                    local activeV = Config["Craft_Table"][activeTableK]
                    activeStillInRange = activeV ~= nil and (distances[activeTableK] or math.huge) < ((activeV.Max_Distance or 0) + 0.5)
                end

                if not activeStillInRange then
                    if activeTableK then
                        if Config.Debug then
                            local prevV = Config["Craft_Table"][activeTableK]
                            print(('[nx_crafting][debug] leave active: %s (k=%s) dist=%.2f'):format(
                                prevV and prevV.Table_Name or '?', tostring(activeTableK), distances[activeTableK] or -1))
                        end
                        cancelCraftHint(activeTableK)
                        activeTableK = nil
                    end

                    local nearestK, nearestV, nearestDist = nil, nil, math.huge
                    for k, v in pairs(Config["Craft_Table"]) do
                        local distance = distances[k]
                        local maxDist = v.Max_Distance or 0
                        if distance < maxDist and distance < nearestDist then
                            nearestK, nearestV, nearestDist = k, v, distance
                        end
                    end

                    if nearestK then
                        local statusjob = true
                        if nearestV.job ~= nil then
                            statusjob = CheckJob(nearestV.job)
                        end

                        if statusjob then
                            if Config.Debug then
                                print(('[nx_crafting][debug] TextUIHold -> %s (k=%s) dist=%.2f maxDist=%.2f'):format(
                                    nearestV.Table_Name or '?', tostring(nearestK), nearestDist, nearestV.Max_Distance or 0))
                            end
                            local acquired = exports.lp_textui:TextUIHold(
                                ('[E] %s'):format(nearestV.Table_Name or 'เปิดโต๊ะคราฟ'),
                                900,
                                function()
                                    craftHintShown[nearestK] = false
                                    activeTableK = nil
                                    TriggerEvent("nx_crafting:client:openMenuCraft", nearestV.Category, nearestV.Position, nearestV.Table_Name)
                                end,
                                Keys.E,
                                { coords = nearestV.Position, offset = vector3(0.0, 0.0, 0.4) },
                                CRAFT_TEXTUI_OWNER
                            )
                            if acquired == true then
                                activeTableK = nearestK
                                craftHintShown[nearestK] = true
                            end
                        else
                            ShowHelpNotification('<font face="' .. Config["Font"] ..
                                                     '">~r~ไม่สามามารถเปิดหน้าโต๊ะคราฟได้~s~</font>')
                        end
                    end
                end
            else
                if activeTableK then
                    cancelCraftHint(activeTableK)
                    activeTableK = nil
                end
            end
        end
    end)

    AddEventHandler('nx_crafting:client:openMenuCraft', function(id, position, tablename)
        if tablename == nil then
            tablename = "โต๊ะคราฟ"
        end
        local Frist = true
        Nametable = tablename
        if false then
        for s, o in pairs(id) do
            for k, v in pairs(CategoryListCl[o].list) do
                local label = GetItemLabel(v.item)
                local Weapons_label = GetWeaponLabel(v.item)
                local cost = {}
                for ks, vls in pairs(v.cost or {}) do
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
                for ks, vls in pairs(v.blueprint or {}) do
                    table.insert(blueprint, {
                        name = ks,
                        amox = vls,
                        label = GetItemLabel(ks)
                    })
                end

                local equipment = {}
                if v.equipment ~= nil then
                    for ks, vls in pairs(v.equipment) do
                        table.insert(equipment, {
                            name = ks,
                            status = vls,
                            label = GetItemLabel(ks)
                        })
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
                    for ks, vls in pairs(v.fail_item) do
                        table.insert(fail_item, {
                            name = ks,
                            amox = vls,
                            label = GetItemLabel(ks)
                        })
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
                            persentremove_fail = v.persentremove_fail,
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
                            persentremove_fail = v.persentremove_fail,
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
                            persentremove_fail = v.persentremove_fail,
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
                            persentremove_fail = v.persentremove_fail,
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
        end
        local categoriesToOpen = type(id) == "table" and id or { id }
        local firstEntry = true
        CraftingTable = {}
        CraftingType = {}
        number = 1
        selectedItemIndex = 1
        selectedRecipeIndex = 1

        for _, categoryId in pairs(categoriesToOpen) do
            local categoryData = CategoryListCl[categoryId]
            if categoryData and type(categoryData.list) == "table" then
                table.insert(CraftingType, {
                    Category = categoryId,
                    categoryIndex = categoryId,
                    categoryname = categoryData.name,
                    name = categoryData.name
                })

                for itemIndex, itemEntry in pairs(categoryData.list) do
                    local itemPayload = BuildCraftItemPayload(categoryId, itemIndex, itemEntry, position)
                    table.insert(CraftingTable, itemPayload)

                    if firstEntry then
                        category = categoryId
                        selectedItemIndex = itemIndex
                        selectedRecipeIndex = itemPayload.recipes[1] and itemPayload.recipes[1].recipeIndex or 1
                        firstEntry = false
                    end
                end
            end
        end

        SetSelectedCraft(category, selectedItemIndex, selectedRecipeIndex)
        MenuOn = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            acton = 'openmenu',
            image = Config["Image_Source"],
            nametable = tablename,
            data = CraftingTable,
            datatype = CraftingType,
            category = category,
            categoryIndex = category,
            itemIndex = selectedItemIndex,
            recipeIndex = selectedRecipeIndex,
            number = number
        })
    end)

    RegisterNUICallback('ChooseType', function(s, cb)
        s = s or {}
        category = tonumber(s.categoryIndex or s.category) or category
        local firstItem = FirstItemInCategory(category)
        if firstItem then
            selectedItemIndex = tonumber(firstItem.itemIndex or firstItem.id) or 1
            selectedRecipeIndex = firstItem.recipes and firstItem.recipes[1] and firstItem.recipes[1].recipeIndex or 1
        end
        SetSelectedCraft(category, selectedItemIndex, selectedRecipeIndex)
        SendNUIMessage({
            acton = 'openmenu',
            image = Config["Image_Source"],
            nametable = Nametable,
            slesc = 'choose',
            data = CraftingTable,
            datatype = CraftingType,
            category = category,
            categoryIndex = category,
            itemIndex = selectedItemIndex,
            recipeIndex = selectedRecipeIndex,
            number = number
        })
        cb({ ok = true })
    end)

    RegisterNUICallback('Choose', function(s, cb)
        s = s or {}
        number = SanitizeAmount(s.number)
        category = tonumber(s.categoryIndex or s.category) or category
        selectedItemIndex = tonumber(s.itemIndex or (s.data and (s.data.itemIndex or s.data.id))) or selectedItemIndex
        selectedRecipeIndex = tonumber(s.recipeIndex or (s.data and s.data.recipeIndex)) or selectedRecipeIndex
        local _, chosenRecipe = FindRecipePayload(category, selectedItemIndex, selectedRecipeIndex)
        if not chosenRecipe then
            selectedRecipeIndex = 1
        end
        SetSelectedCraft(category, selectedItemIndex, selectedRecipeIndex)
        SendNUIMessage({
            acton = 'openmenu',
            image = Config["Image_Source"],
            nametable = Nametable,
            slesc = 'choose',
            data = CraftingTable,
            datatype = CraftingType,
            category = category,
            categoryIndex = category,
            itemIndex = selectedItemIndex,
            recipeIndex = selectedRecipeIndex,
            number = number
        })
        cb({ ok = true })
    end)

    RegisterNUICallback('SetCount', function(s, cb)
        s = s or {}
        number = SanitizeAmount(s.number)
        SendNUIMessage({
            acton = 'openmenu',
            image = Config["Image_Source"],
            nametable = Nametable,
            slesc = 'choose',
            data = CraftingTable,
            datatype = CraftingType,
            category = category,
            categoryIndex = category,
            itemIndex = selectedItemIndex,
            recipeIndex = selectedRecipeIndex,
            number = number
        })
        cb({ ok = true })
    end)

    RegisterNUICallback('Crafting', function(s, cb)
        s = s or {}
		if craftting_process then
            cb({ ok = false, error = 'busy' })
            return
        end
		craftting_process = true

        local requestedCategory = tonumber(s.categoryIndex or s.category) or category
        local requestedItemIndex = tonumber(s.itemIndex) or selectedItemIndex
        local requestedRecipeIndex = tonumber(s.recipeIndex) or selectedRecipeIndex
		local count, validCount = SanitizeAmount(s.amount or s.data)
		if not validCount then
			TriggerEvent("pNotify:SendNotification", {
				text = 'จำนวนไม่ถูกต้อง',
				type = "error",
				timeout = 5000,
				layout = "topRight",
				queue = "left"
			})
			craftting_process = false
            cb({ ok = false, error = 'invalid_count' })
			return
		end

		local inventory = Core.Callback.TriggerAwait("nx_crafting:server:getInventory") or {}
        local started = false
        local itemPayload, recipePayload = FindRecipePayload(requestedCategory, requestedItemIndex, requestedRecipeIndex)

        if not itemPayload or not recipePayload then
            craftting_process = false
            cb({ ok = false, error = 'invalid_recipe' })
            return
        end

        if itemPayload.type == "item_weapon" or recipePayload.type == "item_weapon" then
            count = 1
        end

		local valid = true
		if not checkEquipment(inventory, recipePayload.toolsList or recipePayload.equipment) then
			valid = false
		end

		if not checkBlueprint(inventory, recipePayload.blueprint, count) then
			valid = false
		end

		if valid then
            category = requestedCategory
            selectedItemIndex = requestedItemIndex
            selectedRecipeIndex = requestedRecipeIndex
            SetSelectedCraft(category, selectedItemIndex, selectedRecipeIndex)
            started = true
			TriggerEvent('nx_crafting:client:crafting', requestedCategory, requestedItemIndex, requestedRecipeIndex, count, itemPayload.position)
		end

        if started then
            SetTimeout(1500, function()
                craftting_process = false
            end)
        else
            craftting_process = false
        end

        cb({ ok = started })
	end)

	function checkEquipment(inventory, equipment)
		if not equipment then return true end
		for _, eq in pairs(equipment) do
            if eq.status then
                local hasEquipment = false
                for _, invItem in pairs(inventory) do
                    if eq.name == invItem.name and (tonumber(invItem.count) or 0) > 0 then
                        hasEquipment = true
                        break
                    end
                end
                if not hasEquipment then
                    TriggerEvent("pNotify:SendNotification", {
                        text = 'ไม่พบอุปกรณ์ที่ต้องใช้',
                        type = "warning",
                        timeout = 5000,
                        layout = "topRight",
                        queue = "left"
                    })
                    return false
                end
            end
			for _, invItem in pairs(inventory) do
				if eq.name == invItem.name and eq.status and (tonumber(invItem.count) or 0) <= 0 then
					TriggerEvent("pNotify:SendNotification", {
						text = 'ไม่พบอุปกรณ์ที่ต้องใช้',
						type = "warning",
						timeout = 5000,
						layout = "topRight",
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
            local currentCount = 0
            local requiredCount = (tonumber(bp.amox) or 0) * count
            for _, invItem in pairs(inventory) do
                if bp.name == invItem.name then
                    currentCount = tonumber(invItem.count) or 0
                    break
                end
            end
            if currentCount < requiredCount then
                TriggerEvent("pNotify:SendNotification", {
                    text = 'วัสดุอุปกรณ์มีไม่เพียงพอ',
                    type = "warning",
                    timeout = 5000,
                    layout = "topRight",
                    queue = "left"
                })
                return false
            end
			for _, invItem in pairs(inventory) do
				if bp.name == invItem.name and (tonumber(invItem.count) or 0) < ((tonumber(bp.amox) or 0) * count) then
					TriggerEvent("pNotify:SendNotification", {
						text = 'วัสดุอุปกรณ์มีไม่เพียงพอ',
						type = "warning",
						timeout = 5000,
						layout = "topRight",
						queue = "left"
					})
					return false
				end
			end
		end
		return true
	end

    RegisterNUICallback('Close', function(s, cb)
        MenuOn = false
        CraftingTable = {}
        CraftingType = {}
        SetNuiFocus(false, false)
        SendNUIMessage({
            acton = 'closemenus'
        })
        cb({ ok = true })
    end)

    AddEventHandler('nx_crafting:client:notification', function(reason)
        SendNUIMessage({
            notification = 'notification',
            text = reason
        })
        TriggerEvent("pNotify:SendNotification", {
            text = reason,
            type = "warning",
            timeout = 5000,
            layout = "topRight",
            queue = "left"
        })
    end)

    AddEventHandler('nx_crafting:client:closeMenu', function()
        MenuOn = false
        CraftingTable = {}
        CraftingType = {}
        SetNuiFocus(false, false)
        SendNUIMessage({
            acton = 'closemenus'
        })
    end)

    AddEventHandler('nx_crafting:client:crafting',
        function(recipeCategory, recipeItemIndex, recipeIndex, count, position)
            local status = Core.Callback.TriggerAwait("nx_crafting:server:checkItems", recipeCategory, recipeItemIndex, recipeIndex, count)
            if status then
                SetEntityHeading(PlayerPedId(), position.h)
                TriggerEvent("nx_crafting:client:closeMenu")
                MenuOn = true
                TriggerEvent("nx_crafting:client:notificationCraft", position, function(Status)
                    if Status then
                        MenuOn = false
                        ClearPedTasks(PlayerPedId())
                        TriggerServerEvent("nx_crafting:server:craftItem", recipeCategory, recipeItemIndex, recipeIndex, count)
                    else
                        MenuOn = false
                        ClearPedTasks(PlayerPedId())
                        TriggerServerEvent("nx_crafting:server:cancelCraft")
                    end
                end)
            else
                -- เดิมไม่มี else เลย: server ปฏิเสธ = กดแล้วเงียบสนิท ไม่มีอะไรเกิดขึ้น
                -- ตอนนี้ server ส่ง pNotify บอกเหตุผลมาเองแล้ว ตรงนี้เหลือไว้กันเคสที่
                -- callback ไม่ตอบ/หมดเวลา ซึ่ง server จะไม่ได้ส่งอะไรมาให้เลย
                if Config.Debug then
                    print(('[nx_crafting] checkItems คืน false — cat=%s item=%s recipe=%s count=%s')
                        :format(tostring(recipeCategory), tostring(recipeItemIndex),
                            tostring(recipeIndex), tostring(count)))
                end
            end
        end)

    -- แถบคราฟใช้ lp_progbar แทนของเดิม (ของเดิมวนนับ persent เองแล้ววาด DrawText3D)
    --
    -- ระยะเวลาห้ามต่ำกว่า 3 วินาที: server ตั้ง PendingCrafts.readyAt = now + 3
    -- ถ้ายิง craftItem เร็วกว่านั้นจะโดนปฏิเสธด้วย "คราฟยังไม่เสร็จ"
    -- และห้ามเกิน 20 วินาที (expiresAt) ไม่งั้นเซสชันหมดอายุ
    local CRAFT_MIN_MS, CRAFT_MAX_MS = 3200, 19000

    AddEventHandler('nx_crafting:client:notificationCraft', function(position, cb)
        local ped = PlayerPedId()
        if DoesEntityExist(ped) and not IsEntityDead(ped) then
            loadAnimDict(Config["Animation"][1])
            TaskPlayAnim(ped, Config["Animation"][1], Config["Animation"][2], 3.0, 1.0, -1, 31, 0, 0, 0, 0)
        end

        local ms = tonumber(Config.CraftDurationMs) or 4000
        if ms < CRAFT_MIN_MS then ms = CRAFT_MIN_MS end
        if ms > CRAFT_MAX_MS then ms = CRAFT_MAX_MS end

        local done, cancelled = false, false
        local started = pcall(function()
            exports.lp_progbar:Progress({
                duration  = ms,
                label     = Config.CraftLabel or 'กำลังคราฟ...',
                canCancel = true,
            }, function(wasCancelled)
                cancelled = wasCancelled
                done = true
            end)
        end)

        if started then
            while not done do Wait(50) end
        else
            -- lp_progbar เรียกไม่ได้ — ห้ามค้างรอตลอดกาล รอให้ครบเวลาขั้นต่ำแล้วไปต่อ
            print('[nx_crafting] เรียก lp_progbar ไม่ได้ ใช้การรอเวลาแทน')
            Wait(ms)
        end

        ClearPedTasks(PlayerPedId())
        cb(not cancelled)
    end)

    function loadAnimDict(dict)
        while (not HasAnimDictLoaded(dict)) do
            RequestAnimDict(dict)
            Wait(5)
        end
    end

    AddEventHandler("onResourceStop", function(resource)
        if resource == GetCurrentResourceName() then
            exports.lp_textui:CancelHold(CRAFT_TEXTUI_OWNER)
            -- prop เก็บ handle ไว้บน entry ของโต๊ะเองแล้ว (v._prop) ไม่ใช่ ListObject
            -- ถ้าไม่ลบตรงนี้ prop จะค้างในโลกหลัง restart resource
            for _, v in pairs(Config["Craft_Table"] or {}) do
                removeTableProp(v)
            end
        end
    end)

    function ShowHelpNotification(msg)
        TriggerEvent("pNotify:SendNotification", {
            text = msg,
            type = "warning",
            timeout = 5000,
            layout = "topRight",
            queue = "left"
        })
    end
end
