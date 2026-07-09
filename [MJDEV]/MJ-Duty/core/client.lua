MJDev = GetCurrentResourceName()
local VORPcore = {}
local VORPutils = {}
local SquadBlips = {}
local InDuty = false
local DutyTime = 0
local Entry = {}
local TableDelete = {}
local CoolDownPayCheck = Config.PayCheckTime * 60
local CurrentDutyStationId = nil

TriggerEvent("getCore", function(core)
    VORPcore = core
end)

TriggerEvent("getUtils", function(utils)
    VORPutils = utils
end)

Citizen.CreateThread(function()
    for key, value in pairs(Config['Duty']) do
        local blip = N_0x554d9d53f696d002(1664425300, value['coords'].x, value['coords'].y, value['coords'].z)
        SetBlipSprite(blip, -1656531561, 1)
        SetBlipScale(blip, 0.2)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, 'DutyJobs')
    end
end)

local function applyPosfx()
    if Config.UseFilter then
        AnimpostfxPlay("OJDominoBlur")
        AnimpostfxSetStrength("OJDominoBlur", 0.5)
    end
end

local function getPlayerJob()
    local character = LocalPlayer.state.Character
    if not character or not character.Job then
        return nil
    end -- ป้องกันข้อผิดพลาดถ้า Character หรือ Job เป็น nil

    -- ตรวจสอบใน Config['Duty']
    for k, v in pairs(Config['Duty']) do
        if v.Job == character.Job then
            return v.Job -- คืนค่า Job ถ้าพบ
        elseif v.offJob == character.Job then
            return v.offJob -- คืนค่า offJob ถ้าพบ
        end
    end

    return nil -- คืนค่า nil ถ้าไม่พบ Job ใน Config['Duty']
end

Citizen.CreateThread(function()
    while true do
        Wait(5)
        local PlayerPed = PlayerPedId()
        local coords = GetEntityCoords(PlayerPed)
        local sleep = true
        for k, v in pairs(Config['Duty']) do
            local dist = Vdist(coords, vector3(v['coords'].x, v['coords'].y, v['coords'].z))
            local dis = v['Distance'] + 0.0
            if dist < dis then
                sleep = false
                if not InDuty then
                    DrawText3D(v['coords'].x, v['coords'].y, v['coords'].z + 0.4, 'Press ~g~[G] ~s~ to enter work.')
                    -- exports['MJ-Textui']:ShowTextUI('กด G เพื่อเข้างาน')
                else
                    DrawText3D(v['coords'].x, v['coords'].y, v['coords'].z + 0.4, 'Press ~g~[G] ~r~ to leave work.')
                    -- exports['MJ-Textui']:ShowTextUI('กด G เพื่อออกงาน')
                end
                if IsControlJustPressed(0, 0x760A9C6F) then
                    local hasJob = getPlayerJob()
                    print(hasJob)
                    if hasJob == v.Job or hasJob == v.offJob then
                        applyPosfx()
                        SendNUIMessage({
                            action = 'open',
                            id = k,
                            img = v.img,
                            text = v.Text,
                            injob = v.Job,
                            offjob = v.offJob,
                            induty = InDuty -- เพิ่มสถานะว่าอยู่ในเวรหรือไม่
                        })
                        SetNuiFocus(true, true)
                    else
                        if Config.UseFilter then
                            AnimpostfxStop("OJDominoBlur")
                        end
                        SetNuiFocus(false, false)
                        TriggerEvent("pNotify:SendNotification", {
                            text = 'คุณไม่ใช่หน่วยงานที่กำหนด',
                            type = "success",
                            timeout = 5000,
                            layout = "centerLeft",
                            queue = "left"
                        })
                    end
                end
                if not Entry[k] then
                    Entry[k] = true
                end
            else
                if Entry[k] then
                    sleep = true
                    Entry[k] = false
                end
            end
        end
        if sleep then
            Wait(1000)
        end
    end
end)

RegisterNUICallback("close", function(data, cb)
    SetNuiFocus(false, false)
    if Config.UseFilter then
        AnimpostfxStop("OJDominoBlur")
    end
    cb('ok')
end)

RegisterNUICallback('checktime', function(data, cb)
    local hours, mins, secs = Showtime(DutyTime)

    if DutyTime > 0 and InDuty then
        cb({
            hours = hours,
            minutes = mins,
            seconds = secs
        })
    else
        cb({})
    end
end)

RegisterNUICallback("joinduty", function(v, cb)
    InDuty = true
    CurrentDutyStationId = v.id -- ✅ เก็บ ID จุดเวร
    CoolDownPayCheck = Config.PayCheckTime * 60
    TriggerServerEvent(MJDev .. 'Dutyactive', v.id, v.Job)
    TriggerServerEvent(MJDev .. 'SetDutyState', true, v.Job, v.id) -- ✅ ส่ง ID จุดเวรไปด้วย
    TriggerEvent("pNotify:SendNotification", {
        text = 'คุณได้ทำการเข้าเวรแล้ว',
        type = "success",
        timeout = 3000,
        layout = "centerLeft",
        queue = "left"
    })
    cb('ok')
end)

RegisterNUICallback("offduty", function(v, cb)
    InDuty = false
    CurrentDutyStationId = nil
    TriggerServerEvent(MJDev .. 'Dutyactive', v.id, v.offjob)
    TriggerServerEvent(MJDev .. 'SetDutyState', false)
    TriggerServerEvent(MJDev .. 'SendTimeDiscord', DutyTime)
    TriggerEvent("pNotify:SendNotification", {
        text = 'คุณได้ทำการออกเวรแล้ว',
        type = "success",
        timeout = 3000,
        layout = "centerLeft",
        queue = "left"
    })
    cb('ok')
end)

Citizen.CreateThread(function()
    while true do

        if InDuty then
            DutyTime = (DutyTime or 0) + 1
            CoolDownPayCheck = (CoolDownPayCheck or Config.PayCheckTime * 60) - 1

            if CoolDownPayCheck <= 0 then
                local hasJob = getPlayerJob()
                CoolDownPayCheck = Config.PayCheckTime * 60
                if hasJob then
                    TriggerServerEvent(MJDev .. 'AdditemPayCheck')
                end
            end

            Citizen.Wait(1000) -- รอ 1 วินาทีเหมือนเดิม
        else
            DutyTime = 0
            CoolDownPayCheck = Config.PayCheckTime * 60
            Citizen.Wait(1000) -- ลดโหลดของระบบโดยรอ 5 วินาทีถ้าไม่ได้อยู่ในเวร
        end
    end
end)

function Showtime(seconds)
    if seconds <= 0 then
        return "00", "00", "00"
    else
        local hours = math.floor(seconds / 3600)
        local mins = math.floor((seconds % 3600) / 60)
        local secs = seconds % 60

        return string.format("%02d", hours), string.format("%02d", mins), string.format("%02d", secs)
    end
end

Citizen.CreateThread(function()
    for key, value in pairs(Config['Duty']) do
        local model = value['Model']
        local ped = VORPutils.Peds:Create(model, value['coords'].x, value['coords'].y, value['coords'].z - 1,
            value['coords'].h, 'world', false)
        ped:Freeze(true)
        ped:CanBeDamaged()
        ped:Invincible()
        ped:AddPedToGroup(GetPedGroupIndex(PlayerPedId()))
        TableDelete[#TableDelete + 1] = {
            ped = ped:GetPed()
        }
    end
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoord())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)
    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    SetTextScale(0.30, 0.30)
    SetTextFontForCurrentCommand(1)
    SetTextColor(255, 255, 255, 215)
    SetTextCentre(1)
    DisplayText(str, _x, _y)
    local factor = (string.len(text)) / 225
    DrawSprite("feeds", "hud_menu_4a", _x, _y + 0.0125, 0.015 + factor, 0.03, 0.1, 5, 5, 5, 190, 0)
end

function ClearSquadBlips()
    for _, blip in pairs(SquadBlips) do
        RemoveBlip(blip)
    end
    SquadBlips = {}
end

RegisterNetEvent(MJDev .. 'ReceiveDutyLocations')
AddEventHandler(MJDev .. 'ReceiveDutyLocations', function(data)
    ClearSquadBlips()

    for _, player in ipairs(data) do
        if InDuty then
            -- local blip = AddBlipForEntity(GetPlayerPed(player.id))
            local blip = N_0x554d9d53f696d002(1664425300, player.coords.x, player.coords.y, player.coords.z)
            SetBlipSprite(blip, -1596758107, 1)
            SetBlipScale(blip, 0.2)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, "Colleague: " .. player.name)
            table.insert(SquadBlips, blip)
        end
    end
end)

-- ขอข้อมูลตำแหน่งทุก 10 วินาทีเมื่อเข้าเวร
Citizen.CreateThread(function()
    while true do
        Wait(10000)
        if InDuty then
            TriggerServerEvent(MJDev .. 'RequestDutyLocations')
        else
            ClearSquadBlips()
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        SetNuiFocus(false, false)
        for key, value in pairs(TableDelete) do
            if value.ped then
                DeleteEntity(value.ped)
            end
        end
    end
end)
