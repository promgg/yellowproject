ESX = nil
DATA = {}
LOC = {}
ACTIVE = false
LOCCLOSETO = 0
NPC = {}
Items = {}
POPUP = false
Core = exports.vorp_core:GetCore()

Citizen.CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(100)
    end

    print('MJDEV Economy Ready!')
    Citizen.Wait(5000)
    -- @status Player Ready
    TriggerServerEvent('MJ-Economy:cfx:getPrices')
    -- @init environment
    InitEnvironment()
    -- @init loop
    InitLoop()
end)

function InitEnvironment()
	function CheckJob(joblist)
		local job = Core.Callback.TriggerAwait("MJ-Economy:GetJob")
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
        if joblist == 0 then return true end
        for _, v in pairs(joblist) do
            if v == LocalPlayer.state.Character.Job then return true end
        end
        return false
    end    

	function DoesPlayerExist(pServerId)
        if not pServerId or type(pServerId) ~= "number" then return false end
        return GetPlayerFromServerId(tonumber(pServerId)) ~= -1
    end    

    for k, v in pairs(Config.Locations) do
        if v.NPCModel then
            local x, y, z = table.unpack(v.Coords)
            local hashModel = GetHashKey(v.NPCModel)
            
            if IsModelValid(hashModel) then
                RequestModel(hashModel)
                while not HasModelLoaded(hashModel) do
                    Wait(100)
                end
            else
                print(v.NPCModel .. " is not valid") -- Error handling for invalid model
                return
            end
    
            -- Spawn Ped
            local npc = CreatePed(hashModel, x, y, z-1, v.heading, false, true, true, true)
            Citizen.InvokeNative(0x283978A15512B2FE, npc, true) -- SetRandomOutfitVariation
            SetEntityNoCollisionEntity(PlayerPedId(), npc, false)
            SetEntityCanBeDamaged(npc, false)
            SetEntityInvincible(npc, true)
            -- Wait(1000)
            FreezeEntityPosition(npc, true) -- NPC can't escape
            SetBlockingOfNonTemporaryEvents(npc, true) -- NPC can't be scared
            NPC[#NPC + 1] = { ped = npc }
        end
    
        -- Create Blip
        local blip = N_0x554d9d53f696d002(1664425300, v.Coords.x, v.Coords.y, v.Coords.z)
        SetBlipSprite(blip, v.Blip.Sprite, 1)
        SetBlipScale(blip, 1.0)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, v.Blip.Label)
    end
    
end

-- ระยะเข้า/ออกไม่เท่ากัน (hysteresis) กัน hint กะพริบตอนยืนอยู่ขอบระยะพอดี (~2.5) จาก idle sway เล็กน้อย
local ECONOMY_ENTER_RANGE = 2.5
local ECONOMY_EXIT_RANGE  = 2.8
local ECONOMY_HOLD_MS     = 800  -- กดค้าง E กี่ ms ถึงเปิดร้าน
local ECONOMY_KEY_E       = 0xCEFD9220 -- INPUT_CONTEXT (E)

function InitLoop()
    for k, v in pairs(Config.Locations) do
        table.insert(LOC, {
            Coords = v.Coords,
            Items = v.Items,
            NPCText = v.NPCText
        })
    end

    local hintShown = false

    local function openFromHold()
        -- lp_textui ซ่อนตัวเองไปแล้วตอนกดค้างครบ (ก่อนยิง callback) ต้องรีเซ็ต flag ฝั่งเราด้วย
        -- ไม่งั้น hintShown จะค้าง true ทั้งที่ hint จริงหายไปแล้ว กลับมาโชว์ใหม่ไม่ได้อีก
        hintShown = false
        ACTIVE = true
        OpenOrRefreshUI()
    end

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(150)

            if not ACTIVE then
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local closeTo, closeDist = 0, math.huge
                local range = hintShown and ECONOMY_EXIT_RANGE or ECONOMY_ENTER_RANGE

                -- Find closest location
                for k, v in pairs(LOC) do
                    local dist = GetDistanceBetweenCoords(coords, v.Coords, true)
                    if dist <= range and dist < closeDist then
                        closeTo, closeDist = k, dist
                    end
                end

                if closeTo ~= 0 then
                    LOCCLOSETO = closeTo
                    if not hintShown then
                        hintShown = true
                        local now = LOC[closeTo]
                        -- ลอยติดตำแหน่ง NPC (world-anchor) แทน DrawText3D เดิม
                        exports.lp_textui:TextUIHold(
                            ('[E] %s'):format(now.NPCText),
                            ECONOMY_HOLD_MS,
                            openFromHold,
                            ECONOMY_KEY_E,
                            { coords = now.Coords, offset = vector3(0.0, 0.0, 0.4) }
                        )
                    end
                elseif hintShown then
                    hintShown = false
                    exports.lp_textui:CancelHold() -- ต้องใช้ CancelHold ไม่ใช่ HideUI ไม่งั้นเธรด poll ปุ่มของ TextUIHold ค้างวิ่งต่อ
                end
            elseif hintShown then
                hintShown = false
                exports.lp_textui:CancelHold()
            end
        end
    end)
end

-- @function For Opening or refreshing ui of the window
function OpenOrRefreshUI()
    local invRaw = Core.Callback.TriggerAwait("MJ-Economy:getInventory")
    local invMap = {}
    for _, v in pairs(invRaw) do
        invMap[v.name] = (invMap[v.name] or 0) + (v.count or 0)
    end

    -- Build items array for new UI
    local itemsArr = {}
    for itemName, itemCfg in pairs(LOC[LOCCLOSETO].Items) do
        local price = (DATA[itemName] and DATA[itemName].Price) or itemCfg.Min or 0
        itemsArr[#itemsArr + 1] = {
            name    = itemName,
            label   = itemCfg.Label or itemName,
            img     = 'nui://vorp_inventory/html/img/items/' .. itemName .. '.png',
            count   = invMap[itemName] or 0,
            price   = price,
            canSell = true,
        }
    end

    -- Build ecoData array (all items in DATA for sidebar)
    local ecoArr = {}
    if next(DATA) ~= nil then
        -- DATA populated: use live prices + trend
        for itemName, d in pairs(DATA) do
            local trend = 0
            if d.Status == 'up'   then trend =  1 end
            if d.Status == 'down' then trend = -1 end
            local center = math.floor((d.Min + d.Max) / 2)
            local pct = 0
            if d.Max ~= d.Min then
                pct = math.floor(math.abs(d.Price - center) / (d.Max - d.Min) * 100)
            end
            ecoArr[#ecoArr + 1] = {
                name  = itemName,
                label = d.Label or itemName,
                img   = 'nui://vorp_inventory/html/img/items/' .. itemName .. '.png',
                price = d.Price or 0,
                trend = trend * pct,
            }
        end
    else
        -- DATA not yet received from server — show all config items with price 0
        for _, items in pairs(Config.Items) do
            for itemName, itemCfg in pairs(items) do
                ecoArr[#ecoArr + 1] = {
                    name  = itemName,
                    label = itemCfg.Label or itemName,
                    img   = 'nui://vorp_inventory/html/img/items/' .. itemName .. '.png',
                    price = 0,
                    trend = 0,
                }
            end
        end
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action  = 'openUI',
        items   = itemsArr,
        ecoData = ecoArr,
    })
end

RegisterNetEvent('MJ-Economy:setPrices')
AddEventHandler('MJ-Economy:setPrices', function(data)
    DATA = data

    SendNUIMessage({
        type = 'set-price',
        data = DATA
    })
end)

RegisterNetEvent('MJ-Economy:update')
AddEventHandler('MJ-Economy:update', function(item, data)
    DATA[item] = data
    SendNUIMessage({
        type = 'update-price',
        item = item,
        data = data
    })
end)

RegisterNUICallback('sellItem', function(data, cb)
    local item   = data.name
    local amount = tonumber(data.count) or 0
    if amount > 0 then
        TriggerServerEvent('MJ-Economy:cfx:action', item, amount)
    end
    cb('ok')
end)

RegisterNUICallback('sellAll', function(data, cb)
    local invRaw = Core.Callback.TriggerAwait("MJ-Economy:getInventory")
    local invMap = {}
    for _, v in pairs(invRaw) do
        invMap[v.name] = (invMap[v.name] or 0) + (v.count or 0)
    end
    for itemName, _ in pairs(LOC[LOCCLOSETO].Items) do
        local qty = invMap[itemName] or 0
        if qty > 0 then
            TriggerServerEvent('MJ-Economy:cfx:action', itemName, qty)
            Citizen.Wait(100)
        end
    end
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    ACTIVE = false
    cb('ok')
end)

-- @on script disable
AddEventHandler('onResourceStop', function(resource)
    if resource == 'MJ-Economy' then
        exports.lp_textui:CancelHold()
        for k, v in pairs(NPC) do
            DeletePed(v.ped)
            DeleteEntity(v.ped)
        end
    end
end)
