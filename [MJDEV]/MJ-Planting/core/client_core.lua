local script_name = "!MJ-Planting"

Citizen.CreateThread(function()
    Wait(1500)
    TriggerServerEvent(script_name .. ":CL:GetEvent_Planting")
end)

RegisterNetEvent(script_name .. ":SV:GetEvent_Planting")
AddEventHandler(script_name .. ":SV:GetEvent_Planting", function()
    -- เดิมมีเช็ค GetCurrentResourceName() == script_name ("!MJ-Planting") ก่อนเรียกฟังก์ชันนี้
    -- แต่โฟลเดอร์จริงชื่อ "MJ-Planting" (ไม่มี "!") เงื่อนไขเลย false ตลอด ทำให้ MJDEV_GetEvent_Planting()
    -- ไม่เคยถูกเรียก -> ไม่มีการลงทะเบียน event "MJ-Planting:Start" และไม่มี blip โซนปลูกเลย (เงียบ ไม่ error)
    MJDEV_GetEvent_Planting()
end)

function StartPlantings(k)
    local zoneId = k.zoneId
    local animal = nil

    Count[zoneId] = Count[zoneId] or 0

    if Start[zoneId] then
        return -- กำลังทำรายการปลูกที่โซนนี้อยู่แล้ว (race guard เดิม)
    end

    if Count[zoneId] >= k.count then
        exports.pNotify:SendNotification({
            type = 'error',
            text = ('โซนนี้ปลูกเต็มจำนวนแล้ว (%d/%d)'):format(Count[zoneId], k.count),
            timeout = 4000,
        })
        return
    end

    -- เช็คระยะห่างจากต้นอื่นในโซนเดียวกัน (zoneId เดียวกัน) นับข้ามชนิดพืช
    -- ใช้ k.Dis จาก config แทนของเดิมที่ฮาร์ดโค้ด 1.5 (Dis ในทุก entry ตั้งไว้ 3.0 แต่ไม่เคยถูกใช้จริง)
    local minDis = k.Dis or 3.0
    for i = 1, #PLANT do
        if PLANT[i].Data.zoneId == zoneId and #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(PLANT[i].Planting)) < minDis then
            exports.pNotify:SendNotification({
                type = 'error',
                text = 'มีพืชปลูกอยู่ใกล้เกินไป กรุณาปลูกให้ห่างกว่านี้',
                timeout = 4000,
            })
            return
        end
    end

    do
        Count[zoneId] = Count[zoneId] + 1
        Start[zoneId] = true
        local cancelled = animacion()
        if cancelled then
            Count[zoneId] = Count[zoneId] - 1
            Start[zoneId] = false
            return
        end
        TriggerServerEvent("MJ-Planting:Removeitem", k.item.seed)

        Citizen.CreateThread(function()
            for i = 1, #MJDEV['Planting'] do
                if MJDEV['Planting'][i].item.seed == k.item.seed then
                    local model = MJDEV['Planting'][i].model
                    if LoadModel(model) then
                        local player = PlayerPedId()
                        local pos = GetEntityCoords(player)
                        local heading = GetEntityHeading(player)

                        animal = CreateObject(model, pos.x, pos.y, pos.z, true, true, false)
                        SetEntityAsMissionEntity(animal)
                        PlaceObjectOnGroundProperly(animal)
                        SetEntityHeading(animal, heading)
                        SetEntityCoords(animal, pos.x, pos.y, pos.z - 1.0)
                        FreezeEntityPosition(animal, true)
                        PlaySoundFrontend("CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true, 1)

                        table.insert(PLANT, {
                            Planting = animal,
                            Data = MJDEV['Planting'][i],
                            PlantMax = MJDEV['Planting'][i].plantmax,
                            Watering = MJDEV['Planting'][i].watering,
                            Hungry = 0,
                            Give = false,
                            Feed = false,
                            Starth = false,
                            Moedls = false
                        })
                    end
                    break
                end
            end
        end)

        -- อัปเดตค่าความหิวของสัตว์ทุกๆ 30 วินาที
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(1000) -- 30 วินาที
                for i, v in ipairs(PLANT) do
                    if v.Planting == animal then
                        if not v.Feed and v.Hungry < v.PlantMax then
                            v.Hungry = v.Hungry + 1
                            if v.Hungry == v.PlantMax then
                                v.Feed = false
                                v.Give = true
                                v.Moedls = false
                            end
                            -- print("Plant " .. i .. " Hunger increased to " .. v.Hungry)
                        end

                        -- ถ้าหิวถึงระดับสูงสุด ก็พัฒนาเป็นตัวใหม่
                        if v.Planting == animal and v.Hungry >= v.Watering and v.Hungry < v.PlantMax and not v.Feed and v.Starth and not v.Moedls then
                            isModelSwapping = true
                            local pos = GetEntityCoords(animal)
                            DeleteEntity(animal)
                            DeleteObject(animal)
                            animal = nil

                            local evolvedModel = v.Data.model2
                            if LoadModel(evolvedModel) then
                                animal = CreateObject(evolvedModel, pos.x, pos.y, pos.z-1.0, true, true, false)
                                SetEntityAsMissionEntity(animal)
                                PlaceObjectOnGroundProperly(animal)
                                SetEntityHeading(animal, GetEntityHeading(animal))
                                FreezeEntityPosition(animal, true)
                                PlaySoundFrontend("CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true, 1)
                                v.Planting = animal
                                v.Moedls = true
                            end
                            isModelSwapping = false
                        end                                                
                    end
                end
            end
        end)

        -- เช็คเวลาของสัตว์และลบออกเมื่อถึงเวลา
        Citizen.CreateThread(function()
            local timer = k.time_need
            while timer > 0 do
                Citizen.Wait(1000)
                timer = timer - 1000
            end

            for i, v in ipairs(PLANT) do
                if v.Planting == animal then
                    if not v.Give and v.Feed then
                        print("Deleting animal entity due to time expiration.")
                        DeleteEntity(animal)
                        table.remove(PLANT, i)
                        Count[zoneId] = Count[zoneId] - 1
                        break
                    end
                end
            end
        end)

        Start[zoneId] = false
    end
end

Citizen.CreateThread(function()
    while true do
        local sleep = 500
        if #PLANT > 0 then
            for i = 1, #PLANT, 1 do
                local PLANTCoords = GetEntityCoords(PLANT[i].Planting)
                if not GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), PLANTCoords, true) then
                    return
                end

                if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), PLANTCoords, true) < 10.0 then
                    sleep = 5
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 500 -- ลดการใช้ทรัพยากร CPU
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for i = 1, #PLANT, 1 do
            local plantCoords = GetEntityCoords(PLANT[i].Planting)
            local distance = #(playerCoords - plantCoords)
            if PLANT[i].Hungry >= PLANT[i].Watering and not PLANT[i].Starth then
                PLANT[i].Feed = true
            end
            if distance < 1.5 then
                -- ✅ ใส่อาหาร
                if PLANT[i].Hungry >= PLANT[i].Watering and not PLANT[i].Starth and PLANT[i].Feed then
                    sleep = 5
                    if IsControlPressed(0, MJDEV.Controls.EnterKey) and not isPutfeed then
                        isPutfeed = true
                        local plantIndex = i
                        -- เช็ค uses ที่เหลือในถังก่อนเริ่มอนิเมชั่น (ถังไม่ได้ถูกลบทิ้งตอนหมดแล้ว
                        -- ต้องแยกเคส "ไม่มีถังเลย" กับ "มีถังแต่ uses หมด" ให้ชัดเจน)
                        VORPcore.RpcCall('MJ-Planting:CheckWaterTank:SV', function(result)
                            if result and result.hasTank and result.uses > 0 then
                                local waterCancelled = animacion2()
                                if not waterCancelled then
                                    PLANT[plantIndex].Starth = true
                                    PLANT[plantIndex].Feed = false
                                    VORPcore.RpcCall('MJ-Planting:ConsumeWaterUse:SV', function(consumeResult)
                                        local remaining = consumeResult and consumeResult.remaining or 0
                                        if remaining > 0 then
                                            exports.pNotify:SendNotification({
                                                type = 'success',
                                                text = ('รดน้ำสำเร็จ เหลือน้ำอีก %d ครั้ง'):format(remaining),
                                                timeout = 3000,
                                            })
                                        else
                                            exports.pNotify:SendNotification({
                                                type = 'error',
                                                text = 'รดน้ำสำเร็จ แต่ถังน้ำหมดแล้ว กรุณาไปเติมน้ำก่อน',
                                                timeout = 4000,
                                            })
                                        end
                                    end)
                                    if math.random(1, 100) < PLANT[plantIndex].Data.bandits then
                                        BanditsStart()
                                    end
                                end
                            elseif result and result.hasTank then
                                exports.pNotify:SendNotification({
                                    type = 'error',
                                    text = 'ถังน้ำหมดแล้ว กรุณาไปเติมน้ำก่อน',
                                    timeout = 4000,
                                })
                            else
                                MJDEV.NoItemFeed()
                            end
                            isPutfeed = false
                        end)
                    end
                end

                -- ✅ เก็บเกี่ยว
                if PLANT[i].Feed == false and PLANT[i].Give == true and PLANT[i].Hungry == PLANT[i].PlantMax then
                    sleep = 5
                    if IsControlPressed(0, MJDEV.Controls.EnterKey) and not isPutfeed then
                        isPutfeed = true
                        FreezeEntityPosition(PLANT[i].Planting, true)

                        local harvestCancelled = runProgress({
                            duration = 8000,
                            label = 'Harvesting...',
                            controlDisables = { disableMovement = true },
                            animation = { animDict = "mech_pickup@plant@berries", anim = "base" },
                        })

                        if not harvestCancelled then
                            local harvestedZoneId = PLANT[i].Data.zoneId
                            Count[harvestedZoneId] = (Count[harvestedZoneId] or 1) - 1
                            for _, k in pairs(PLANT) do
                                if k.Planting == PLANT[i].Planting then
                                    FreezeEntityPosition(PLANT[i].Planting, false)
                                    SetEntityInvincible(PLANT[i].Planting, false)
                                    PlaySoundFrontend("CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true, 1)
                                    TriggerServerEvent("MJ-Planting:Giveitem", k.Data.item.seed)
                                    DeleteEntity(PLANT[i].Planting)
                                    PLANT[i].Planting = nil
                                    break
                                end
                            end
                        else
                            FreezeEntityPosition(PLANT[i].Planting, false)
                        end
                        isPutfeed = false
                    end
                end
            end
        end
        Citizen.Wait(sleep) -- รอเมื่อไม่ได้อยู่ใกล้พืช
    end
end)
