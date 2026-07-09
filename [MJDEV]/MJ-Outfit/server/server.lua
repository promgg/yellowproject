local vorpInventory = exports.vorp_inventory:vorp_inventoryApi()
local Core = exports.vorp_core:GetCore()

RegisterNetEvent('MJ-Outfit:UpdatePlayercomps')
AddEventHandler('MJ-Outfit:UpdatePlayercomps', function(_source, arguments, title)
    local Character = Core.getUser(_source).getUsedCharacter
    local PlayerSex = Character.gender
    Wait(1000)

    -- แปลง arguments จาก string เป็น table
    local TableTenue = json.decode(arguments) 
    if not TableTenue then
        print("❌ Error: arguments is not a valid JSON string")
        return
    end

    -- เพิ่มข้อมูล description และ sex
    TableTenue.description = title
    TableTenue.sex = PlayerSex

    -- ดึงรายการไอเทมทั้งหมดที่มีใน inventory ของผู้เล่น
    local items = vorpInventory.getUserInventory(_source)

    -- แปลง metadata ของชุดใหม่เป็น string เพื่อเปรียบเทียบ
    local newMetadata = json.encode(TableTenue)

    -- ตรวจสอบว่าไอเทมซ้ำหรือไม่
    if items then
        for _, item in pairs(items) do
            if item.name == 'outfit' and json.encode(item.metadata) == newMetadata then
                print("❌ ไอเทมซ้ำกัน: ไม่เพิ่มเข้าไป")
                return -- หยุดทำงานทันที ไม่เพิ่มไอเทมเข้าไป
            end
        end
    end

    -- ✅ ถ้าไม่มีไอเทมซ้ำ ให้เพิ่มไอเทมเข้า inventory
    vorpInventory.addItem(_source, 'outfit', 1, TableTenue)

    -- ✅ ตรวจสอบค่า
    -- print("✅ เพิ่มชุดใหม่: ", newMetadata)
end)


exports.vorp_inventory:registerUsableItem('outfit', function(data)
    local Character = Core.getUser(data.source).getUsedCharacter
    local source = data.source
    local _source = source

    -- ดึงรายการไอเทมทั้งหมดที่มีใน inventory ของผู้เล่น
    local items = vorpInventory.getUserInventory(_source)

    if not items or #items == 0 then
        print("❌ Inventory ว่าง ไม่มีชุดให้ใช้")
        return
    end

    local currentMetadata = json.encode(data.item.metadata)
    local found = false

    for _, item in pairs(items) do
        if item.name == 'outfit' and json.encode(item.metadata) ~= currentMetadata then
            -- ใช้แค่ไอเทมแรกที่เจอที่ไม่ตรงกับ metadata ปัจจุบัน
            TriggerClientEvent('vorpcharacter_outfit:Updatecomps', _source, currentMetadata)
            TriggerClientEvent("vorpcharacter:updateCache", _source, false, currentMetadata)
            -- print("✅ ใช้งานชุดใหม่: ", json.encode(item.metadata))
            found = true
            break -- ออกจาก loop หลังจากเจอไอเทมแรก
        end
    end

    if not found then
        print("❌ ไม่มีชุดอื่นให้ใช้ (มีแต่ชุดที่ใช้อยู่)")
    end
end)

function DumpTable(table, nb)
    if nb == nil then
        nb = 0
    end

    if type(table) == "table" then
        local s = ""
        for _ = 1, nb + 1, 1 do
            s = s .. "    "
        end

        s = "{\n"
        for k, v in pairs(table) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end
            for _ = 1, nb, 1 do
                s = s .. "    "
            end
            s = s .. "[" .. k .. "] = " .. DumpTable(v, nb + 1) .. ",\n"
        end

        for _ = 1, nb, 1 do
            s = s .. "    "
        end

        return s .. "}"
    else
        return tostring(table)
    end
end