
local VorpCore = exports.vorp_core:GetCore()
local script_name = 'MJ-Deletehorse'

local isCountDownDeleteHorseAndWagon = false
local isCountDownRestartServer = false
local lastTimePlaySound = nil
local endSound = nil

-- ตรวจสอบว่าเป็นเขตเมืองหรือไม่ (วางไว้ก่อนฟังก์ชันอื่นๆ)
local function IsTownZone(hTownZone)
    local TownZones = {
        [459833523] = true,    -- Valentine
        [2046780049] = true,   -- Rhodes
        [-765540529] = true,   -- Saint Denis
        [427683330] = true,    -- Strawberry
        [1053078005] = true,   -- Blackwater
        [-744494798] = true,   -- Armadillo
        [-1524959147] = true,  -- Tumbleweed
        [7359335] = true,      -- Annesburg
        [2126321341] = true,   -- Van Horn
        [201158410] = true,    -- Manicato
        [1463094051] = true    -- Manzanita Post
    }

    return TownZones[hTownZone] or false
end

-- ตรวจสอบว่าม้าอยู่ในเมืองหรือไม่
local function LocationUiCheckTowns(vPlayerCoords)
    local hTownZone = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, 1)
    return IsTownZone(hTownZone)
end

local function DeleteHorseAuto()
    for _, entity in pairs(GetGamePool("CPed")) do
        if DoesEntityExist(entity) and not IsPedAPlayer(entity) then
            local model = GetEntityModel(entity)

            if IsThisModelAHorse(model)and IsImportantNPC(entity) then
                local horseCoords = GetEntityCoords(entity)
                if LocationUiCheckTowns(horseCoords) then
                    if not IsHorseMountedByPlayer(entity) then
                        print('Removed Horse: '..entity)
                        Citizen.Wait(10000)
                        DeleteEntity(entity)
                    end
                end
            end
        end
    end
end

-- เริ่มต้นฟังก์ชันหลัก
RegisterNetEvent('vorp:SelectedCharacter', function(charId)
    TriggerServerEvent(script_name .. ':CheckEventTime')
    DeleteHorseAuto()
end)

RegisterNetEvent(script_name .. ':CancelNotifyDeleteVehicle')
AddEventHandler(script_name .. ':CancelNotifyDeleteVehicle', function()
    isCountDownDeleteHorseAndWagon = false
    SendNUIMessage({ ShowMenu = false, })
    PlaySoundFrontend("SELECT", "RDRO_Character_Creator_Sounds", true, 0)

    SendNUIMessage({
        transactionType = 'stopSound',
    })
end)

RegisterNetEvent(script_name .. ':CancelNotifyRestartServer')
AddEventHandler(script_name .. ':CancelNotifyRestartServer', function()
    isCountDownRestartServer = false
    SendNUIMessage({ ShowMenu = false, })
    PlaySoundFrontend("BACK", "RDRO_Character_Creator_Sounds", true, 0)

    SendNUIMessage({
        transactionType = 'stopSound',
    })
end)

function playSound(soundNotify)
    SendNUIMessage({
        transactionType = 'playSound',
        transactionFile = soundNotify.file,
        transactionVolume = soundNotify.volume
    })
end

RegisterNetEvent(script_name .. ':RunNotifyRestartServer')
AddEventHandler(script_name .. ':RunNotifyRestartServer', function(_times)
    print('[MJ-Deletehorse][restart] event received, _times =', _times, type(_times))
    isCountDownRestartServer = true

    PlaySoundFrontend(-1, "QUIT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)

    local times = _times * 60
    local matchTime = math.floor(times)
    print('[MJ-Deletehorse][restart] matchTime =', matchTime, '(if this is <= 0, the loop below never runs and the UI never shows)')
    Citizen.CreateThread(function()
        while matchTime > 0 and isCountDownRestartServer do
            Citizen.Wait(1000)
            if matchTime > 0 then
                matchTime = matchTime - 1
            end

            local txtMin = ('%s'):format(minToClock(matchTime))
            local txtSec = ('%s'):format(secToClock(matchTime))

            local min = tonumber(txtMin) + 1
            if lastTimePlaySound ~= tonumber(min) then
                lastTimePlaySound = min
                for k, v in pairs(Config.SoundNotifyRestartServer) do
                    if min == v.time then
                        playSound(v)
                    end
                end
            end

            if isCountDownRestartServer then
                print(('[MJ-Deletehorse][restart] SendNUIMessage mode=restart txtMin=%s txtSec=%s IsPauseMenuActive=%s'):format(txtMin, txtSec, tostring(IsPauseMenuActive())))
                SendNUIMessage({
                    display = true,
                    IsPauseMenuActive = IsPauseMenuActive(),
                    mode = 'restart',
                    txtMin = txtMin,
                    txtSec = txtSec,
                })

                if matchTime == 0 then
                    -- ค้นหาเสียงสุดท้ายตอนนับเวลาจบว่ามีหรือไม่
                    for k, v in pairs(Config.SoundNotifyRestartServer) do
                        if v.time == 0 then
                            endSound = v
                            break
                        end
                    end

                    if endSound ~= nil then
                        playSound(endSound)
                    end
                    isCountDownRestartServer = false
                    lastTimePlaySound = nil
                    SendNUIMessage({ display = false, })
                end
            end
        end
    end)
end)


RegisterNetEvent(script_name .. ':RunNotifyDeleteHorseAndWagon')
AddEventHandler(script_name .. ':RunNotifyDeleteHorseAndWagon', function(_times)
    local times = tonumber(_times * 60) -- แปลงเวลาจากนาทีเป็นวินาที
    if times > 0 then
        PlaySoundFrontend("SELECT", "RDRO_Character_Creator_Sounds", true, 0)
        isCountDownDeleteHorseAndWagon = true
        local matchTime = math.floor(times)
        local totalTime = times
        Citizen.CreateThread(function()
            while matchTime > 0 and isCountDownDeleteHorseAndWagon do
                Citizen.Wait(1000)
                if matchTime > 0 then
                    matchTime = matchTime - 1
                end

                -- ส่งข้อมูลเวลาที่เหลือให้กับ client
                local txtMin = string.format('%02d', math.floor(matchTime / 60))
                local txtSec = string.format('%02d', matchTime % 60)

                -- ส่งข้อมูลไปยัง UI
                if isCountDownDeleteHorseAndWagon then
                    SendNUIMessage({
                        display = true,
                        IsPauseMenuActive = IsPauseMenuActive(),
                        mode = 'delcar',
                        txtMin = txtMin,
                        txtSec = txtSec,
                    })

                    -- เมื่อเวลาหมด
                    if matchTime == 0 then
                        local endSound = nil
                        -- ค้นหาเสียงสุดท้ายตอนนับเวลาจบว่ามีหรือไม่
                        for k, v in pairs(Config.SoundNotifyDeleteHorseAndWagon) do
                            if v.time == 0 then
                                endSound = v
                                break
                            end
                        end

                        -- เล่นเสียงถ้ามี
                        if endSound then
                            playSound(endSound)
                        end

                        -- ซ่อน UI ทันทีตอนนับครบ 0 — อย่ารอ DeleteHorseAuto() ก่อน เพราะข้างในมี
                        -- Citizen.Wait(10000) ต่อม้า 1 ตัว ถ้ามีหลายตัวในเมือง UI จะค้างที่ 00:00
                        -- นานหลายสิบวินาทีกว่าจะซ่อน
                        isCountDownDeleteHorseAndWagon = false
                        lastTimePlaySound = nil
                        SendNUIMessage({ display = false })

                        -- ตรวจสอบเกวียน (หากต้องการ)
                        local playerPed = PlayerPedId()
                        local playerHorse = GetMount(playerPed) -- รับม้าที่ติดอยู่กับผู้เล่น
                        local playerWagon = GetVehiclePedIsIn(playerPed, false)  -- เกวียนที่ผู้เล่นอยู่ ถ้าไม่มีจะได้ 0 หรือ nil

                        for _, entity in pairs(GetGamePool("CVehicle")) do
                            if DoesEntityExist(entity) and not IsPedAPlayer(entity) then
                                local model = GetEntityModel(entity)
                                -- เช็คว่าเป็นเกวียน (แทนที่ชื่อโมเดลด้วยโมเดลของเกวียนที่ต้องการ)
                                if IsThisModelADraftVehicle(model) then
                                    if not IsHorseMountedByPlayer(entity) and entity ~= playerWagon then
                                        -- print('Removed Wagon: ' .. entity)
                                        DeleteEntity(entity)
                                    end
                                end
                            end
                        end
                        DeleteHorseAuto()
                    end
                end
            end
        end)
        PlaySoundFrontend(-1, "QUIT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
end)

function GetLastMount(ped)
    return Citizen.InvokeNative(0x4C8B59171957BCF7, ped)
end

function GetRiderOfMount(mount, p1)
    return Citizen.InvokeNative(0xB676EFDA03DADA52, mount, p1)
end

function SetPedAsSaddleHorseForPlayer(player, mount)
    return Citizen.InvokeNative(0xD2CB0FB0FDCB473D, player, mount)
end


-- ฟังก์ชันแปลงเวลาเป็นรูปแบบนาฬิกา
function minToClock(seconds)
    local minutes = math.floor(seconds / 60)
    return string.format("%02d", minutes)
end

function secToClock(seconds)
    local seconds = seconds % 60
    return string.format("%02d", seconds)
end

-- ตรวจสอบว่าม้านี้มีผู้เล่นขี่อยู่หรือไม่
function IsHorseMountedByPlayer(horseEntity)
    if DoesEntityExist(horseEntity) then
        local rider = GetPedInVehicleSeat(horseEntity, -1)
        return DoesEntityExist(rider) and IsPedAPlayer(rider)
    end
    return false
end

-- ยกเว้น NPC พิเศษ (สามารถเพิ่มเงื่อนไขหรือตัว NPC ได้ตามต้องการ)
function IsImportantNPC(entity)
    local pedType = GetPedType(entity)
    return pedType == 28 -- PedType 28 มักจะเป็น NPC สำคัญ
end
