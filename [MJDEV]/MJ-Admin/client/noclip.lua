local NoClipActive = false

Citizen.CreateThread(function()
    while true do
        Wait(5)
        if IsControlJustPressed(0, 0x42385422) then
            if noclipAllow then
                if NoClipActive then
                    NoClipActive = false
                else
                    NoClipActive = true
                end
            end
        end
    end
end)

admin.Noclip = function()
    if noclipAllow then
        if NoClipActive then
            NoClipActive = false
        else
            NoClipActive = true
        end
    end
end


RegisterNetEvent("admin:NoClipActive")
AddEventHandler("admin:NoClipActive", function()
    if noclipAllow then
        if not NoClipActive then
            NoClipActive = true
        end
    end
end)

Citizen.CreateThread(function()
    local player = PlayerPedId()
    local index = 1
    local CurrentSpeed = Config.SetNoclip.Speeds[index].speed
    local FollowCamMode = true

    while true do
        while NoClipActive do

            if IsPedInAnyVehicle(PlayerPedId(), false) then
                player = GetVehiclePedIsIn(PlayerPedId(), false)
            else
                player = PlayerPedId()
            end

            local yoff = 0.0
            local zoff = 0.0

            if IsDisabledControlJustPressed(1, Config.SetNoclip.Controls.camMode) then
                timer = 2000
                FollowCamMode = not FollowCamMode
            end

            if IsDisabledControlJustPressed(1, Config.SetNoclip.Controls.changeSpeed) then
                timer = 2000
                if index ~= #Config.SetNoclip.Speeds then
                    index = index + 1
                    CurrentSpeed = Config.SetNoclip.Speeds[index].speed
                else
                    CurrentSpeed = Config.SetNoclip.Speeds[1].speed
                    index = 1
                end
                TriggerEvent("pNotify:client:SendAlert", {
                    text = 'Noclip ระดับ ' .. Config.SetNoclip.Speeds[index].label,
                    type = "error",
                    timeout = 2000
                })
            end
            if IsDisabledControlPressed(0, Config.SetNoclip.Controls.goForward) then
                if Config.SetNoclip.FrozenPosition then
                    yoff = -Config.SetNoclip.Offsets.y
                else
                    yoff = Config.SetNoclip.Offsets.y
                end
            end

            if IsDisabledControlPressed(0, Config.SetNoclip.Controls.goBackward) then
                if Config.SetNoclip.FrozenPosition then
                    yoff = Config.SetNoclip.Offsets.y
                else
                    yoff = -Config.SetNoclip.Offsets.y
                end
            end

            if not FollowCamMode and IsDisabledControlPressed(0, Config.SetNoclip.Controls.turnLeft) then
                SetEntityHeading(PlayerPedId(), GetEntityHeading(PlayerPedId()) + Config.SetNoclip.Offsets.h)
            end

            if not FollowCamMode and IsDisabledControlPressed(0, Config.SetNoclip.Controls.turnRight) then
                SetEntityHeading(PlayerPedId(), GetEntityHeading(PlayerPedId()) - Config.SetNoclip.Offsets.h)
            end

            if IsDisabledControlPressed(0, Config.SetNoclip.Controls.goUp) then
                zoff = Config.SetNoclip.Offsets.z
            end

            if IsDisabledControlPressed(0, Config.SetNoclip.Controls.goDown) then
                zoff = -Config.SetNoclip.Offsets.z
            end

            local newPos = GetOffsetFromEntityInWorldCoords(player, 0.0, yoff * (CurrentSpeed + 0.3),
                zoff * (CurrentSpeed + 0.3))
            local heading = GetEntityHeading(player)
            SetEntityVelocity(player, 0.0, 0.0, 0.0)
            if Config.SetNoclip.FrozenPosition then
                SetEntityRotation(player, 0.0, 0.0, 180.0, 0, false)
            else
                SetEntityRotation(player, 0.0, 0.0, 0.0, 0, false)
            end
            if (FollowCamMode) then
                SetEntityHeading(player, GetGameplayCamRelativeHeading())
            else
                SetEntityHeading(player, heading);
            end
            if Config.SetNoclip.FrozenPosition then
                SetEntityCoordsNoOffset(player, newPos.x, newPos.y, newPos.z, not NoClipActive, not NoClipActive,
                    not NoClipActive)
            else
                SetEntityCoordsNoOffset(player, newPos.x, newPos.y, newPos.z, NoClipActive, NoClipActive, NoClipActive)
            end

            SetEntityAlpha(player, 51, 0)
            if (player ~= PlayerPedId()) then
                SetEntityAlpha(PlayerPedId(), 100, 0)
            end

            SetEntityCollision(player, false, false)
            FreezeEntityPosition(player, true)
            SetEntityInvincible(player, true)
            SetEntityVisible(player, false, false)
            SetEveryoneIgnorePlayer(PlayerPedId(), true)
            SetPedCanBeTargetted(player, false)
            Citizen.Wait(0)

            ResetEntityAlpha(player)
            if (player ~= PlayerPedId()) then
                ResetEntityAlpha(PlayerPedId())
            end

            SetEntityCollision(player, true, true)
            FreezeEntityPosition(player, false)
            SetEntityInvincible(player, false)
            SetEntityVisible(player, true, false)
            SetEveryoneIgnorePlayer(PlayerPedId(), false)
            SetPedCanBeTargetted(player, true)
            if Config.SetNoclip.ShowControls then
                DrawText('W/A/S/D/Q/Z- Move, LShift  Change speed,  H- Relative mode', 0.5, 0.95, true)
            end
        end
        Citizen.Wait(0)
    end
end)

function DrawText(text, x, y, centred)
    SetTextScale(0.35, 0.35)
    SetTextColor(0, 0, 255, 255)
    SetTextCentre(centred)
    SetTextDropshadow(1, 1, 0, 0, 200)
    SetTextFontForCurrentCommand(22)
    DisplayText(CreateVarString(10, "LITERAL_STRING", text), x, y)
end
