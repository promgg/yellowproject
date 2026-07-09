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
local function LoadModel(model)
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)

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

-- ── Spawn ped ต่อ zone ที่ ped.enabled (ครั้งเดียวตอน resource start) ────────
local function spawnZonePeds()
    for _, zone in ipairs(Config.Zones) do
        if zone.ped and zone.ped.enabled then
            if LoadModel(zone.ped.model) then
                local hash = GetHashKey(zone.ped.model)
                local ped = CreatePed(hash, zone.coords.x, zone.coords.y, zone.coords.z - 1.0,
                    zone.ped.heading or 0.0, false, false, false, false)
                SetEntityAsMissionEntity(ped, true, true)
                PlaceEntityOnGroundProperly(ped)
                FreezeEntityPosition(ped, true)
                SetEntityInvincible(ped, true)
                SetPedCanBeTargetted(ped, false)
                SetBlockingOfNonTemporaryEvents(ped, true)
                SetModelAsNoLongerNeeded(hash)
                zone.pedEntity = ped
            end
        end
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
        spawnZonePeds()
    end)
    createBlips() -- เผื่อ resource นี้ start ไปแล้วตอนสคริปต์โหลด (onClientResourceStart ไม่ยิงย้อนหลัง)
    spawnZonePeds()

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
                    sleep = 500
                    if dist < zone.radius then
                        sleep     = 250
                        foundZone = zone
                        break
                    end
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
end
