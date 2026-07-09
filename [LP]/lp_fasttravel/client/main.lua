-- client/main.lua
-- lp_fasttravel — lp_textui:TextUIHold ต่อสถานี | NUI card grid | lp_progbar ก่อน/หลังวาร์ป

local VORPcore = nil
local menuOpen = false

CreateThread(function()
    while VORPcore == nil do
        VORPcore = exports.vorp_core:GetCore()
        Wait(200)
    end
end)

local StationsById = {}
for _, s in ipairs(Config.Stations) do
    StationsById[s.id] = s
end

local REASON_MESSAGES = {
    no_job          = 'คุณไม่มีสิทธิ์เดินทางไปสถานีนี้',
    cooldown        = 'กรุณารอสักครู่ก่อนเดินทางอีกครั้ง',
    already_here    = 'คุณอยู่ที่สถานีนี้อยู่แล้ว',
    no_money        = 'เงินสดไม่พอสำหรับค่าเดินทาง',
    invalid_station = 'ไม่พบสถานีปลายทาง',
}

local function Notify(msg, msgType)
    exports.pNotify:SendNotification({ text = msg, type = msgType or 'error', timeout = 4000 })
end

-- ─── เทเลพอร์ตจริง (ports meta_tp's WarpWithProgress -> lp_progbar) ─────────
local function DoTeleport(coords, heading)
    local ped = PlayerPedId()

    DoScreenFadeOut(400)
    local fadeDeadline = GetGameTimer() + 1000
    while not IsScreenFadedOut() and GetGameTimer() < fadeDeadline do Wait(0) end

    FreezeEntityPosition(ped, true)
    SetEntityCollision(ped, false, false)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, true, true, true)
    SetEntityHeading(ped, heading or 0.0)

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    local collisionDeadline = GetGameTimer() + 3000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < collisionDeadline do
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        Wait(0)
    end

    -- ย้ำตำแหน่งอีกครั้งหลังคอลลิชันมาแล้ว กัน Z สแน็ปผิด
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, true, true, true)
    SetEntityHeading(ped, heading or 0.0)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    DoScreenFadeIn(300)

    exports.lp_progbar:Progress({
        duration        = Config.ProgressBar.after.duration,
        label           = Config.ProgressBar.after.label,
        canCancel       = false,
        controlDisables = { disableMovement = true, disableCarMovement = true, disableCombat = true },
    }, function() end)
end

-- ─── วาร์ปพร้อมหลอดโหลดก่อน/หลัง (ports meta_tp's WarpWithProgress -> lp_progbar) ────
local function TravelWithProgress(coords, heading)
    exports.lp_progbar:Progress({
        duration        = Config.ProgressBar.before.duration,
        label           = Config.ProgressBar.before.label,
        canCancel       = false,
        controlDisables = { disableMovement = true, disableCarMovement = true, disableCombat = true },
    }, function(cancelled)
        if cancelled then return end
        DoTeleport(coords, heading)
    end)
end

-- ─── NUI open/close ──────────────────────────────────────────────────────────
local function CloseMenu()
    if not menuOpen then return end
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeMenu' })
end

local function OpenMenu()
    if menuOpen then return end
    VORPcore.Callback.TriggerAsync('lp_fasttravel:GetStations', function(result)
        if not result then return end
        menuOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            type     = 'openMenu',
            stations = result.stations,
            cooldown = result.cooldown,
        })
    end)
end

RegisterNUICallback('closeMenu', function(_, cb)
    cb('ok')
    CloseMenu()
end)

RegisterNUICallback('confirmTravel', function(data, cb)
    cb('ok')
    CloseMenu()

    VORPcore.Callback.TriggerAsync('lp_fasttravel:Travel', function(result)
        if not result or not result.ok then
            Notify((result and REASON_MESSAGES[result.reason]) or 'เดินทางไม่สำเร็จ', 'error')
            return
        end

        TravelWithProgress(result.coords, result.heading)
    end, data.stationId)
end)

-- ─── Main proximity thread: lp_textui:TextUIHold ลอยติดพิกัดสถานีที่ใกล้ที่สุด ──
CreateThread(function()
    local heldId = nil

    while true do
        Wait(500)

        if menuOpen then
            if heldId then
                exports.lp_textui:CancelHold()
                heldId = nil
            end
            goto continue
        end

        local pos = GetEntityCoords(PlayerPedId())

        local nearest, nearDist = nil, Config.TriggerRadius
        for _, station in ipairs(Config.Stations) do
            local d = #(pos - station.coords)
            if d <= nearDist then
                nearDist = d
                nearest  = station
            end
        end

        if nearest and heldId ~= nearest.id then
            if heldId then exports.lp_textui:CancelHold() end
            heldId = nearest.id
            exports.lp_textui:TextUIHold(
                "[E] ค้างเพื่อเปิด Fast Travel",
                Config.HoldTime,
                function()
                    heldId = nil
                    OpenMenu()
                end,
                Config.Key,
                { coords = nearest.coords, offset = vector3(0.0, 0.0, 1.0) }
            )
        elseif not nearest and heldId then
            exports.lp_textui:CancelHold()
            heldId = nil
        end

        ::continue::
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if menuOpen then SetNuiFocus(false, false) end
end)
