-- cl_main.lua — Command + Zone logic (dynamic wait, กดค้าง E ผ่าน lp_textui เปิดตลาด)

local Core = exports.vorp_core:GetCore()

local inZone      = false
local currentZone = nil
local tryOpenZone -- forward-declared: OnMarketUIClosed ต้องเรียกก่อนที่ตัวจริงจะถูกนิยามด้านล่าง

-- เรียกจาก cl_nui.lua's CloseMarketUI() — ถ้ายังยืนอยู่ในโซน ต้อง arm hold hint ใหม่
-- (TextUIHold ยิงครั้งเดียวตอน enter zone เท่านั้น ไม่ auto-repeat หลัง callback ทำงานเสร็จ)
function OnMarketUIClosed()
    if inZone and currentZone then
        exports.lp_textui:TextUIHold(currentZone.textui or Config.Locale.textui_zone, Config.HoldMs, function()
            tryOpenZone(currentZone)
        end)
    end
end

-- ── Helper: check item in inventory (ใช้เฉพาะตอน CommandItem/zone.item.enabled = true) ──
local function PlayerHasItem(itemName)
    local ok, result = pcall(Core.Callback.TriggerAwait, 'lp_marketplace:hasItem', itemName)
    return ok and result == true
end

local function Notify(msg, ntype)
    exports.pNotify:SendNotification({
        text    = msg,
        type    = ntype or 'error',
        timeout = 4000,
    })
end

-- ── Ped model loader (timeout กันค้างถ้าโหลดโมเดลไม่สำเร็จ) ──────────────────
-- เดิมไม่เช็ค IsModelValid ก่อน + RequestModel เรียกแค่ 1 arg ทำให้ไม่รู้เลยว่าโมเดล invalid
-- หรือแค่โหลดช้า (เงียบ timeout ไปเฉยๆ) ปรับให้ตรงกับ pattern ที่ยืนยันแล้วว่าใช้ได้จริงใน
-- bcc-stables/nx_shop: joaat + IsModelValid guard + RequestModel(hash, false) สอง arg
local function LoadModel(model)
    local modelHash = joaat(model)
    if not IsModelValid(modelHash) then
        print('[lp_marketplace] Invalid ped model: ' .. tostring(model))
        return false
    end

    RequestModel(modelHash, false)

    local timeout = 5000
    local timer   = GetGameTimer()
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(100)
        if GetGameTimer() - timer > timeout then
            print('[lp_marketplace] Failed to load ped model: ' .. tostring(model))
            return false
        end
    end
    return true
end

-- ── Spawn/despawn ped ต่อ zone แบบ on-demand ตามระยะผู้เล่น (ไม่ค้างไว้ทั้งแมพตั้งแต่
-- resource start) ── เดิม spawn ครั้งเดียวตอน start ทั้ง top-level + onClientResourceStart
-- ทำให้ ped ซ้อนกัน 2 ตัวทุกครั้งที่ resource start ปกติ (สองจุดนั้นยิงทั้งคู่จริง ไม่ใช่ fallback
-- ที่ยิงแค่จุดเดียว) เปลี่ยนมา spawn ตอนเข้ารัศมี despawn ตอนออกรัศมีแทน กัน ped ซ้อน + ประหยัด
-- resource ตอนไม่มีใครอยู่แถวนั้นด้วย
local function spawnZonePed(zone)
    if zone.pedEntity or not (zone.ped and zone.ped.enabled) then return end
    if not LoadModel(zone.ped.model) then return end

    local hash = joaat(zone.ped.model)
    local ped = CreatePed(hash, zone.coords.x, zone.coords.y, zone.coords.z - 1.0,
        zone.ped.heading or 0.0, false, false, false, false)
    -- RDR2 ped ไม่ใส่ชุด/มองไม่เห็นถ้าไม่สั่งอันนี้ (ตัวเดียวกับบัคที่เจอใน bcc-stables/nx_shop) —
    -- SetRandomOutfitVariation (0x283978A15512B2FE) ให้ ped สุ่มชุดจริงแทนที่จะเป็น mesh เปล่า
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
    SetEntityAsMissionEntity(ped, true, true)
    PlaceEntityOnGroundProperly(ped)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityCanBeDamaged(ped, false)
    SetPedCanBeTargetted(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(hash)
    zone.pedEntity = ped
end

local function despawnZonePed(zone)
    if zone.pedEntity then
        DeleteEntity(zone.pedEntity)
        zone.pedEntity = nil
    end
end

-- ── Command ────────────────────────────────────────────────────────────────────
if Config.OpenMethod == 'command' or Config.OpenMethod == 'both' then
    RegisterCommand(Config.Command, function()
        if Config.CommandItem.enabled and not PlayerHasItem(Config.CommandItem.item) then
            Notify(Config.Locale.no_item_required, 'error')
            return
        end
        OpenMarketUI()
    end, false)
end

-- ── Zone ───────────────────────────────────────────────────────────────────────
if Config.OpenMethod == 'zone' or Config.OpenMethod == 'both' then

    -- Blip สร้างครั้งเดียวตอน start (RDR3 blip native — ต่างจาก GTA5)
    local function createBlips()
        for _, zone in ipairs(Config.Zones) do
            if zone.blip and zone.blip.enabled then
                local blip = N_0x554d9d53f696d002(1664425300, zone.coords.x, zone.coords.y, zone.coords.z)
                SetBlipSprite(blip, zone.blip.sprite or -1646261997, 1)
                SetBlipScale(blip, zone.blip.scale or 0.6)
                Citizen.InvokeNative(0x9CB1A1623062F402, blip, zone.blip.label or zone.label or 'Marketplace')
            end
        end
    end

    AddEventHandler('onClientResourceStart', function(res)
        if res ~= GetCurrentResourceName() then return end
        createBlips()
    end)
    createBlips() -- เผื่อ resource นี้ start ไปแล้วตอนสคริปต์โหลด (onClientResourceStart ไม่ยิงย้อนหลัง)

    -- กดค้าง E เพื่อเปิดตลาด — TextUIHold จัดการ control poll + progress ring ของตัวเอง
    -- (เช็คไอเทมที่ต้องมี ก่อนเปิด UI จริงในตัว callback)
    tryOpenZone = function(zone)
        local needItem = zone.item and zone.item.enabled
        if needItem and not PlayerHasItem(zone.item.item) then
            Notify(Config.Locale.no_item_required, 'error')
        else
            OpenMarketUI()
        end
    end

    -- Dynamic wait proximity thread
    -- idle 2500ms → ใกล้ 50u: 500ms → ใน zone: 250ms (แค่ตรวจ enter/exit ปุ่ม E เป็นหน้าที่ TextUIHold)
    CreateThread(function()
        while true do
            local sleep     = 2500
            local ped       = PlayerPedId()
            local pos       = GetEntityCoords(ped)
            local foundZone = nil

            for _, zone in ipairs(Config.Zones) do
                local dist = #(pos - zone.coords)
                if dist < zone.radius + 50.0 then
                    spawnZonePed(zone)
                    sleep = 500
                    if dist < zone.radius then
                        sleep     = 250
                        foundZone = zone
                    end
                else
                    despawnZonePed(zone)
                end
            end

            -- Zone enter/exit
            if foundZone and not inZone then
                inZone      = true
                currentZone = foundZone
                exports.lp_textui:TextUIHold(foundZone.textui or Config.Locale.textui_zone, Config.HoldMs, function()
                    tryOpenZone(foundZone)
                end)
            elseif not foundZone and inZone then
                inZone      = false
                currentZone = nil
                exports.lp_textui:CancelHold()
            end

            Wait(sleep)
        end
    end)

    -- ลบ ped ที่ spawn ค้างไว้ตอน resource หยุด/restart กันเหลือ entity ลอยอยู่ในโลก
    AddEventHandler('onResourceStop', function(res)
        if res ~= GetCurrentResourceName() then return end
        for _, zone in ipairs(Config.Zones) do
            despawnZonePed(zone)
        end
    end)
end
