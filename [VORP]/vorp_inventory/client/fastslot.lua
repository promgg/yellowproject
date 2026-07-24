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

-- ทางที่ 1: NUI keydown — app.js ดักปุ่มตอนหน้าเว็บได้รับ key แล้วยิงมาที่นี่
function NUIUseFastSlot(data, cb)
    local slot = type(data) == "table" and tonumber(data.slot) or nil
    if slot and slot >= 1 and slot <= MAX_SLOTS then
        useFastSlot(slot)
    else
        dbg("NUIUseFastSlot: ^1slot ไม่ถูกต้อง^7", json.encode(data or {}))
    end
    if cb then cb("ok") end
end

-- ทางที่ 2: control poll ฝั่ง Lua — "รันเฉพาะตอนกระเป๋าเปิด" เท่านั้น
--
-- ทำไมต้องมี 2 ทาง: SetNuiFocus(true, true) ควรส่ง keydown ให้หน้าเว็บ แต่ในทางปฏิบัติ RedM/CEF
-- ไม่ได้ส่งปุ่มเลขมาถึง app.js เสมอไป (เกมยังกินปุ่มไว้เอง) ทางนี้จึงเป็นตัวรับประกันว่ากดแล้วติด
-- server มี cooldown 500ms ต่อคนอยู่แล้ว ถ้าทั้งสองทางยิงพร้อมกันจะถูกกรองเหลือครั้งเดียวเอง
--
-- InInventory เป็น global ของ NUIService (true ทั้งกระเป๋าหลักและตู้เก็บของ) — อ่านตอน runtime
-- จึงไม่ต้องกังวลว่า services/ โหลดหลังไฟล์นี้ (ค่าเริ่มต้น nil -> เทียบ == true ได้ปลอดภัย)
--
-- DisableControlAction ทำเฉพาะตอนกระเป๋าเปิด: กันกดเลขแล้วเกมแอบสลับอาวุธอยู่หลังเมนู
-- ตอนกระเป๋าปิด thread นี้ไม่แตะ control ใดๆ เลย ปุ่ม 1-6 จึงเป็นการเลือกอาวุธปกติของเกมเต็มที่
CreateThread(function()
    while true do
        if InInventory == true and Config.FastSlot then
            for i = 1, MAX_SLOTS do
                local kc = Config.FastSlot[i]
                if kc and kc.key then
                    DisableControlAction(0, kc.key, true)
                    if IsDisabledControlJustPressed(0, kc.key) or IsControlJustPressed(0, kc.key) then
                        useFastSlot(i)
                    end
                end
            end
            Wait(0)
        else
            Wait(250) -- กระเป๋าปิด: ไม่ต้องเช็คถี่ ไม่กิน resmon
        end
    end
end)

-- ทางที่ 3: global hotkey  Alt + 1..6  — ใช้ fast-slot ได้ "ทุกเมื่อ" ไม่ต้องเปิดกระเป๋า
--
-- ใช้ native RegisterRawKeymap (event-driven) แบบเดียวกับ jo_libs/jo_radial ที่ทำงานได้จริง
--   (เดิมลอง poll IsRawKeyDown/IsRawKeyPressed แล้ว "ไม่จับ Alt" บน build นี้ — เปลี่ยนมา event)
--   RegisterRawKeymap(name, onKeyDown, onKeyUp, vkCode, canBeDisabled)
-- ไม่แตะ control ของเกมเลย: ปุ่ม 1-6 เปล่า ๆ ยังสลับอาวุธปกติ / Alt+1..6 = fast-slot (เกมไม่ได้ผูก Alt+เลข)
-- useFastSlot() มี guard pause-menu + server cooldown 500ms อยู่แล้ว
if Config.FastSlotGlobalHotkey ~= false then
    local resName = GetCurrentResourceName()
    local MOD_VK = Config.FastSlotHotkeyModifierVK or 0x12 -- 0x12 = MENU (Alt)
    local modHeld = false

    -- peek hotbar: กด Alt ค้าง -> โชว์แถบ fast-slot เฟดขึ้น / ปล่อย -> เฟดหาย (NUI ทำ transition เอง)
    local function sendPeek(show)
        if Config.FastSlotPeek == false then return end
        SendNUIMessage({ action = "fastslotPeek", show = show })
    end

    local function setMod(state)
        modHeld = state
        dbg("modifier", state and "^2DOWN^7" or "^1UP^7")
        if state then
            -- กระเป๋าเปิดอยู่แล้วโชว์ fast-panel เต็ม ไม่ต้อง peek ซ้อน
            if InInventory == true then return end
            sendPeek(true)
        else
            sendPeek(false)
        end
    end

    -- modifier: ดัก MENU (0x12) + เผื่อ build ที่ส่งเป็น LMENU(0xA4)/RMENU(0xA5) แยก
    RegisterRawKeymap(resName .. ":fastslot:mod",  function() setMod(true) end, function() setMod(false) end, MOD_VK, true)
    if MOD_VK == 0x12 then
        RegisterRawKeymap(resName .. ":fastslot:modL", function() setMod(true) end, function() setMod(false) end, 0xA4, true)
        RegisterRawKeymap(resName .. ":fastslot:modR", function() setMod(true) end, function() setMod(false) end, 0xA5, true)
    end

    -- เลข 1..MAX_SLOTS: ตอน "กดลง" ถ้า Alt ค้างอยู่ -> ใช้ fast-slot ช่องนั้น
    for i = 1, math.min(MAX_SLOTS, 9) do
        local slot = i
        local vk = 0x30 + i -- VK_1..VK_9 = 0x31..0x39
        RegisterRawKeymap(resName .. ":fastslot:num" .. i, function()
            dbg(("กดเลข %d (Alt ค้าง=%s)"):format(slot, tostring(modHeld)))
            -- fallback: เช็ค IsRawKeyDown เผื่อ event modifier พลาด (build บางตัวไม่ยิง up/down ครบ)
            if modHeld or IsRawKeyDown(MOD_VK) or IsRawKeyDown(0xA4) or IsRawKeyDown(0xA5) then
                dbg("^2Alt+" .. slot .. " -> ใช้ fast-slot^7")
                useFastSlot(slot)
            end
        end, function() end, vk, true)
    end
    dbg("ลงทะเบียน global hotkey Alt+1.." .. math.min(MAX_SLOTS, 9) .. " (RegisterRawKeymap) เรียบร้อย")

    -- Alt+X: ปิด peek ทันที "แม้ยังกด Alt ค้างอยู่" (ปล่อย Alt ก็ปิดเองผ่าน setMod อยู่แล้ว)
    -- 0x58 = VK_X — เช็คว่า Alt ค้างจริงก่อน ไม่งั้นกด X เปล่าๆ จะไปสั่งปิด peek ที่ไม่ได้เปิด
    if Config.FastSlotPeek ~= false then
        RegisterRawKeymap(resName .. ":fastslot:peekHide", function()
            if modHeld or IsRawKeyDown(MOD_VK) or IsRawKeyDown(0xA4) or IsRawKeyDown(0xA5) then
                dbg("Alt+X -> ปิด peek")
                sendPeek(false)
            end
        end, function() end, 0x58, true)
    end
end
