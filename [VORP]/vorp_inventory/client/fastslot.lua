-- ============================================================================
--  Fast Slot / Hotbar (open rewrite) — แทน client/MJDevFastSlot.lua ตัวเข้ารหัส
--  - ปุ่ม 1-6 ทำงาน "เฉพาะตอนเปิดกระเป๋า" เท่านั้น: ตอนกระเป๋าเปิด NUI ถือ keyboard focus
--    อยู่แล้ว JS ใน html/app.js จึงเป็นคนดักปุ่มเอง แล้วยิง NUI callback UseFastSlot กลับมา
--    ตอนกระเป๋าปิด เราไม่แตะ control ของเกมเลย ปุ่ม 1-6 จึงเป็นการเลือกอาวุธปกติของเกม
--    (เดิมใช้ control-hash poll + DisableControlAction ตลอดเวลา ทำให้เลือกอาวุธไม่ได้เลย)
--  - กดปุ่ม -> ส่งแค่ "หมายเลขช่อง" ให้ server ตัดสิน (server-authoritative)
--  - รับ sync จาก server มาแสดงผ่าน NUI (จำนวนสด)
--  โหลดก่อน controllers/* เพื่อให้ global NUIAddItemToFastSlot/NUIRemoveItemFromFastSlot
--  ถูกนิยามก่อน NUIController.lua ไป RegisterNUICallback
-- ============================================================================

local MAX_SLOTS = Config.FastSlotCount or 6

-- debug log (เปิดด้วย Config.Debug = true)
local function dbg(...)
    if Config.Debug then
        print("^2[fastslot:cl]^7", ...)
    end
end

-- ---------------------------------------------------------------------------
-- NUI callbacks (globals ที่ controllers/NUIController.lua เรียกใช้)
-- ---------------------------------------------------------------------------

-- ผู้เล่นลากไอเทมใส่ช่อง — app.js ส่ง { slot, item = normalized, id, type, name }
function NUIAddItemToFastSlot(data, cb)
    if type(data) == "table" and data.slot then
        local item = data.item or {}
        local metadata = (type(item.metadata) == "table") and item.metadata or nil
        local name = data.name or item.name
        dbg("NUIAddItemToFastSlot: slot", data.slot, "name", name, "type", data.type or item.type)
        TriggerServerEvent("vorp_inventory:fastslot:assign",
            tonumber(data.slot),
            name,
            data.type or item.type or "item_standard",
            metadata,
            tonumber(data.id or item.id))
    else
        dbg("NUIAddItemToFastSlot: ^1data ไม่ถูกต้อง^7", json.encode(data or {}))
    end
    if cb then cb("ok") end
end

-- ผู้เล่นเอาไอเทมออกจากช่อง — app.js ส่ง { slot }
function NUIRemoveItemFromFastSlot(data, cb)
    if type(data) == "table" and data.slot then
        dbg("NUIRemoveItemFromFastSlot: slot", data.slot)
        TriggerServerEvent("vorp_inventory:fastslot:remove", tonumber(data.slot))
    end
    if cb then cb("ok") end
end

-- ลาก Fast Slot ไปอีกช่อง: server เป็นผู้สลับ/ย้าย binding ตามเลขช่องเท่านั้น
function NUIMoveFastSlot(data, cb)
    local fromSlot = type(data) == "table" and tonumber(data.fromSlot) or nil
    local toSlot = type(data) == "table" and tonumber(data.toSlot) or nil

    if fromSlot and toSlot then
        dbg("NUIMoveFastSlot:", fromSlot, "->", toSlot)
        TriggerServerEvent("vorp_inventory:fastslot:move", fromSlot, toSlot)
    else
        dbg("NUIMoveFastSlot: ^1data ไม่ถูกต้อง^7", json.encode(data or {}))
    end

    if cb then cb("ok") end
end

function NUISetInventoryPreferences(data, cb)
    if type(data) == "table" then
        TriggerServerEvent("vorp_inventory:preferences:update", data)
    end
    if cb then cb("ok") end
end

function NUIRequestInventoryPreferences(_, cb)
    TriggerServerEvent("vorp_inventory:preferences:request")
    if cb then cb("ok") end
end

-- ---------------------------------------------------------------------------
-- sync จาก server -> NUI
-- ---------------------------------------------------------------------------

RegisterNetEvent("vorp_inventory:fastslot:sync", function(slots)
    dbg("รับ sync จาก server:", json.encode(slots or {}))
    SendNUIMessage({ action = "setFastSlots", slots = slots or {} })
end)

RegisterNetEvent("vorp_inventory:preferences:sync", function(preferences)
    SendNUIMessage({ action = "inventoryPreferences", preferences = preferences or {} })
end)

-- อาวุธ: server สั่งให้ client ใช้ผ่าน export useWeapon เดิม (ยังเป็น best-effort — จูนเพิ่ม Phase ถัดไป)
RegisterNetEvent("vorp_inventory:fastslot:useWeapon", function(data)
    pcall(function()
        exports.vorp_inventory:useWeapon(data)
    end)
end)

-- ขอ sync เริ่มต้นเมื่อเลือกตัวละครเสร็จ (เผื่อ NUI พร้อมหลัง event ฝั่ง server)
AddEventHandler("vorp:SelectedCharacter", function()
    Citizen.SetTimeout(2000, function()
        TriggerServerEvent("vorp_inventory:fastslot:request")
        TriggerServerEvent("vorp_inventory:preferences:request")
    end)
end)

-- inventory โหลดเสร็จจริง (server ส่งของครบแล้ว) -> ขอ fastslot sync อีกรอบ
-- เดิมพึ่งแค่ SetTimeout(2000) หลัง SelectedCharacter ซึ่ง race กับตอน inventory ยังโหลดไม่เสร็จ
-- (DB หนัก/ของเยอะ โหลดช้ากว่า 2 วิ) ทำให้ตอน reconnect buildSyncPayload ฝั่ง server หาไอเทมไม่เจอ
-- fastslot เลยโชว์ count 0 + ชื่อ internal จนกว่าผู้เล่นจะ refresh เอง (ใช้/ลากของ) — ยิง sync ตรงจุดที่
-- inventory พร้อมจริงแทน กัน race ถาวร
AddEventHandler("vorpinventory:loaded", function()
    TriggerServerEvent("vorp_inventory:fastslot:request")
end)

-- รองรับ restart vorp_inventory ขณะผู้เล่นออนไลน์ โดยไม่ต้องเลือกตัวละครใหม่
AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Citizen.SetTimeout(1500, function()
        TriggerServerEvent("vorp_inventory:fastslot:request")
        TriggerServerEvent("vorp_inventory:preferences:request")
    end)
end)

-- ---------------------------------------------------------------------------
-- commands — คำสั่งทดสอบแต่ละช่องผ่าน F8
-- ---------------------------------------------------------------------------

-- ตัวใช้จริงร่วมกันของคำสั่ง F8 และ control-hash poll
local function useFastSlot(slot)
    dbg("กดปุ่มช่อง", slot)
    if IsPauseMenuActive() then dbg("บล็อก: pause menu เปิดอยู่"); return end
    dbg("ส่ง event use ช่อง", slot, "-> server")
    TriggerServerEvent("vorp_inventory:fastslot:use", slot)
end

-- ลงทะเบียนคำสั่งสำหรับทดสอบ pipeline ตรงๆ ผ่านคอนโซล F8: vorpfastslot1
-- (ทางเดินจริงตอนเล่นคือ NUI callback UseFastSlot ด้านล่าง ไม่ผ่านคำสั่งพวกนี้)
for i = 1, MAX_SLOTS do
    local cmd = ("vorpfastslot%d"):format(i)
    local slot = i
    RegisterCommand(cmd, function() useFastSlot(slot) end, false)
    dbg("ลงทะเบียนคำสั่งช่อง", i, "(cmd:", cmd .. ")")
end

-- ปุ่ม 1-6 ที่ผู้เล่นกดตอนเปิดกระเป๋า — app.js เป็นคนดักและยิงมาที่นี่
-- (ไม่มี control-hash poll / DisableControlAction แล้ว: ตอนกระเป๋าปิด เกมจึงคุมปุ่ม 1-6 เองเต็มที่)
function NUIUseFastSlot(data, cb)
    local slot = type(data) == "table" and tonumber(data.slot) or nil
    if slot and slot >= 1 and slot <= MAX_SLOTS then
        useFastSlot(slot)
    else
        dbg("NUIUseFastSlot: ^1slot ไม่ถูกต้อง^7", json.encode(data or {}))
    end
    if cb then cb("ok") end
end
