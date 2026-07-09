-- cl_main.lua — Command + Zone logic (dynamic wait, กด E ครั้งเดียวเปิดตลาด)

local Core = exports.vorp_core:GetCore()

local inZone = false

-- ── Helper: check item in inventory (ใช้เฉพาะตอน CommandItem/zone.item.enabled = true) ──
local function PlayerHasItem(itemName)
    local ok, result = pcall(Core.Callback.TriggerAwait, 'lp_marketplace:hasItem', itemName)
    return ok and result == true
end

local function Notify(msg, ntype)
    local ok = pcall(function() exports.vorp_core:DisplayTip(msg, 4000) end)
    if not ok then print('[lp_marketplace] ' .. tostring(msg)) end
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

    -- Dynamic wait proximity thread
    -- idle 2500ms → ใกล้ 50u: 500ms → ใน zone: 0ms (จับปุ่ม E)
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
                        sleep     = 0
                        foundZone = zone
                        break
                    end
                end
            end

            -- Zone enter/exit
            if foundZone and not inZone then
                inZone = true
                SendNUIMessage({ action = 'showHint', data = { text = foundZone.textui or Config.Locale.textui_zone } })
            elseif not foundZone and inZone then
                inZone = false
                SendNUIMessage({ action = 'hideHint' })
            end

            -- กด E ครั้งเดียวเปิดตลาด (ไม่มี hold-to-interact)
            -- ใช้ IsDisabledControlJustPressed(0x17BEC168) ตาม pattern ที่ยืนยันแล้วว่าใช้ได้จริงใน build นี้ (AnimalFarm)
            if foundZone and sleep == 0 and IsDisabledControlJustPressed(0, 0x17BEC168) then
                local needItem = foundZone.item and foundZone.item.enabled
                if needItem and not PlayerHasItem(foundZone.item.item) then
                    Notify(Config.Locale.no_item_required, 'error')
                else
                    OpenMarketUI()
                end
            end

            Wait(sleep)
        end
    end)
end
