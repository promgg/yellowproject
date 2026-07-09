local VorpCore = {}
TriggerEvent("getCore", function(core)
    VorpCore = core
end)

local VorpInv = exports.vorp_inventory:vorp_inventoryApi()
local PlayerHives = {} -- เก็บข้อมูลรังผึ้ง

-- ตรวจสอบว่าผู้เล่นสามารถวางรังได้หรือไม่
function CanPlaceHive(source)
    local maxHives = Config.ApiBeeHives.MaxHives
    if not PlayerHives[source] then
        PlayerHives[source] = 0
    end
    
    if PlayerHives[source] >= maxHives then
        TriggerClientEvent("vorp:TipBottom", source, "คุณไม่สามารถวางรังผึ้งได้แล้ว (จำนวนรังสูงสุด)", 4000)
        return false
    end    

    return true
end

-- ใช้ไอเทมเพื่อวางรังผึ้ง
for _, item in ipairs(Config.BeeHives) do
    VorpInv.RegisterUsableItem(item.name, function(data)
        if data.source then  -- ตรวจสอบว่า source มีค่าหรือไม่
            if CanPlaceHive(data.source) then
                TriggerClientEvent("MJ-Beekeeper:PlaceHive", data.source, item)
                PlayerHives[data.source] = PlayerHives[data.source] + 1 -- เพิ่มจำนวนรัง
            else
                TriggerClientEvent("vorp:TipBottom", data.source, "Have you placed the required number of beehives or is the cooldown over?!", 4000)
            end
        else
            print("Error: data.source is nil or invalid.")
        end
    end)    
end

RegisterServerEvent('MJ-Beekeeper:subItem')
AddEventHandler('MJ-Beekeeper:subItem', function(item)
    VorpInv.subItem(source, item, 1) -- ลดไอเทมที่ใช้
end)

-- การเก็บเกี่ยวรังผึ้ง
RegisterServerEvent('MJ-Beekeeper:GiveHoney')
AddEventHandler('MJ-Beekeeper:GiveHoney', function()
    local _source = source
    for _, reward in ipairs(Config.Rewards) do
        VorpInv.addItem(_source, reward.Item, reward.Amount)
    end
    if PlayerHives[_source] and PlayerHives[_source] > 0 then
        PlayerHives[_source] = PlayerHives[_source] - 1
    end
    TriggerClientEvent("vorp:TipBottom", _source, "You get honey from the hive.!", 4000)
end)

-- ลบรังผึ้ง
RegisterServerEvent('MJ-Beekeeper:Delete')
AddEventHandler('MJ-Beekeeper:Delete', function()
    local _source = source
    if PlayerHives[_source] then
        PlayerHives[_source] = 0
    end
    TriggerClientEvent("MJ-Beekeeper:RemoveOldBox", -1)
end)

-- คำสั่งสร้างรังทดสอบ (สำหรับแอดมิน)
RegisterCommand('createobject', function(source)
    TriggerClientEvent("object:RemoveOldBox", -1)
end, true)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        local _source = source
        if PlayerHives[_source] then
            PlayerHives[_source] = 0
        end
    end
end)
