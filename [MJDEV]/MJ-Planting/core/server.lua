local script_name = "!MJ-Planting"
VORPcore = {}
TriggerEvent("getCore",function(core)
    VORPcore = core
end)

local Inventory = exports.vorp_inventory:vorp_inventoryApi()

-- ── anti-spam/anti-dupe (server-side) ────────────────────────────────────────
-- MJ-Planting:Giveitem เป็น RegisterServerEvent ที่ client ยิงได้ ถ้าไม่กันจะสแปมยิงตรงเพื่อดูป
-- ของ + ปั๊มอันดับ (lp_leaderboard) โดยไม่ต้องปลูก/เก็บเกี่ยวจริง — server ไม่ได้ track ต้นไม้
-- (จัดการ client) เลย validate ตรงไม่ได้ ใช้ cooldown ต่อคนแทน (harvest จริงใช้ progress 8s → 6s ปลอดภัย)
local harvestCooldowns = {}
local function checkHarvestCooldown(src, minMs)
    local t = GetGameTimer()
    if (t - (harvestCooldowns[src] or 0)) < minMs then return false end
    harvestCooldowns[src] = t
    return true
end
AddEventHandler('playerDropped', function() harvestCooldowns[source] = nil end)

RegisterServerEvent(script_name .. ":CL:GetEvent_Planting")
AddEventHandler(script_name .. ":CL:GetEvent_Planting", function(name)
    TriggerClientEvent(script_name .. ":SV:GetEvent_Planting", source)
end)


VORPcore.addRpcCallback('MJ-Planting:Getitem:SV', function(source, cb, Getitem)
    local src = source
    if not src or not Getitem then
        print("^1[ERROR] Invalid source or item name in GetitemSV callback.^0")
        cb(false)
        return
    end

    local count = Inventory.getItemCount(src, Getitem)

    if count and count > 0 then
        print(("^2[INFO] Player %s has %d of %s.^0"):format(src, count, Getitem))
        cb(true)
    else
        print(("^3[INFO] Player %s does not have %s.^0"):format(src, Getitem))
        cb(false)
    end
end)

-- เติมน้ำ: หาถัง tool_bucket ใบไหนก็ได้ที่ผู้เล่นถืออยู่ (getItemByName คืนใบแรกที่เจอ ไม่สนใจ metadata เดิม)
-- แล้วตั้ง metadata.uses ใหม่เป็นเต็มถัง (ตั้งค่าจำนวนครั้งได้ที่ MJDEV.WaterRefill.usesPerRefill ใน config.lua)
VORPcore.addRpcCallback('MJ-Planting:RefillWaterTank:SV', function(source, cb)
    local src = source
    exports.vorp_inventory:getItemByName(src, "tool_bucket", function(item)
        if not item then
            cb({ ok = false })
            return
        end

        local uses = (item.metadata and tonumber(item.metadata.uses)) or 0
        if uses >= MJDEV.WaterRefill.usesPerRefill then
            cb({ ok = false, alreadyFull = true })
            return
        end

        -- amount ต้อง = item.count เสมอ (ไม่ใช่ hardcode 1) ไม่งั้น vorp_inventory:setItemMetadata
        -- จะ "แยกกอง" (split) ชิ้นที่เหลือออกเป็น item ใหม่ เมื่อ count ของถังเดิม > amount ที่ส่งไป
        -- (ดู inventoryApiService.lua:InventoryAPI.setItemMetadata) ทำให้ tool_bucket ที่ควรมีแค่ 1 ชิ้น
        -- กลายเป็น 2 ช่องแยกกันในกระเป๋า
        exports.vorp_inventory:setItemMetadata(src, item.id, { uses = MJDEV.WaterRefill.usesPerRefill }, item.count, function(success)
            cb({ ok = success == true })
        end)
    end)
end)

-- เช็คว่าผู้เล่นมีถังน้ำไหม และเหลือ uses เท่าไร (ก่อนเริ่มอนิเมชั่นรดน้ำ)
VORPcore.addRpcCallback('MJ-Planting:CheckWaterTank:SV', function(source, cb)
    local src = source
    exports.vorp_inventory:getItemByName(src, "tool_bucket", function(item)
        if not item then
            cb({ hasTank = false, uses = 0 })
            return
        end
        local uses = (item.metadata and tonumber(item.metadata.uses)) or 0
        cb({ hasTank = true, uses = uses })
    end)
end)

-- ลด uses ในถังน้ำลง 1 หลังรดสำเร็จ (ไม่ลบถังทิ้งแม้ uses จะเหลือ 0 ก็ตาม ต้องไปเติมใหม่)
-- เปลี่ยนจาก event เฉยๆ เป็น RPC callback เพื่อส่ง uses ที่เหลือกลับไปแจ้งเตือนฝั่ง client
VORPcore.addRpcCallback('MJ-Planting:ConsumeWaterUse:SV', function(source, cb)
    local src = source
    exports.vorp_inventory:getItemByName(src, "tool_bucket", function(item)
        if not item then
            cb({ remaining = 0 })
            return
        end
        local uses = (item.metadata and tonumber(item.metadata.uses)) or 0
        uses = math.max(0, uses - 1)
        -- amount = item.count เหตุผลเดียวกับใน RefillWaterTank:SV ด้านบน (กัน stack split)
        exports.vorp_inventory:setItemMetadata(src, item.id, { uses = uses }, item.count, function()
            cb({ remaining = uses })
        end)
    end)
end)



if MJDEV and MJDEV['Planting'] then
    for i = 1, #MJDEV['Planting'], 1 do
        -- Inventory.RegisterUsableItem (wrapper) ยิง TriggerEvent("vorpCore:registerUsableItem", ...)
        -- ซึ่งไม่มี handler อยู่จริงใน vorp_inventory เลย (เช็คแล้ว) ทำให้ลงทะเบียนไม่ติด
        -- กด "ใช้" เมล็ดใน inventory เลยไม่มีอะไรเกิดขึ้น ต้องเรียก export ตรงๆ (lowercase) แบบนี้แทน
        -- (ยืนยันวิธีนี้ถูกต้องจาก vorp_metabolism/MJ-Medic ที่ใช้แบบเดียวกันแล้วทำงานได้จริง)
        local seedName = MJDEV['Planting'][i].item.seed
        exports.vorp_inventory:registerUsableItem(seedName, function(data)
            print(('[MJ-Planting][DEBUG] ใช้เมล็ด "%s" จาก source %s -> ส่ง MJ-Planting:Start ให้ client'):format(seedName, tostring(data.source)))
            TriggerClientEvent("MJ-Planting:Start", data.source, MJDEV['Planting'][i])
        end)
        print(('[MJ-Planting][DEBUG] ลงทะเบียน usable item: "%s" (index %d)'):format(seedName, i))
    end
else
    print("Error: MJDEV['Planting'] is not defined!")
end

RegisterServerEvent("MJ-Planting:Removeitem")
AddEventHandler("MJ-Planting:Removeitem", function(ITEM)
    local itemCount = exports['vorp_inventory']:getItemCount(source, nil, ITEM)
    if itemCount > 0 then
        Inventory.subItem(source, ITEM, 1)
    else
        print("Error: Player does not have enough " .. ITEM .. " to remove.")
    end
end)

RegisterServerEvent("MJ-Planting:Giveitem")
AddEventHandler("MJ-Planting:Giveitem", function(ITEM)
    local _source = source

    -- กันสแปมยิงตรง (harvest จริงมี progress 8s) — cooldown 6s ต่อคน ฝั่ง server
    if not checkHarvestCooldown(_source, 6000) then return end

    local totalGiven = 0
    for i = 1, #MJDEV['Planting'], 1 do
        if MJDEV['Planting'][i].item.seed == ITEM then
            for _, v in pairs(MJDEV['Planting'][i].giveitem) do
                if math.random(1, 100) <= v.percent then
                    if v.item then
                        exports['vorp_inventory']:addItem(_source, v.item, v.count)
                        print("Added item: " .. v.item .. " (" .. v.count .. ")")
                        totalGiven = totalGiven + (tonumber(v.count) or 0)
                    end
                end
            end
        end
    end
    -- lp_leaderboard (FARMING RANK): soft integration — ยิงเฉยๆ ไม่ต้อง depend, เงียบถ้าไม่มี resource นี้
    -- ต้องแนบ src เอง เพราะ TriggerEvent ข้าม resource ไม่รับประกัน global `source` ฝั่งผู้รับ
    if totalGiven > 0 then
        TriggerEvent('lp_leaderboard:SV:PlantHarvest', { src = _source, amount = totalGiven })
    end
end)

