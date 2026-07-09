-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 
local showingUI = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)

        if IsWaypointActive() then
            local wpCoords = GetWaypointCoords()
            if wpCoords then
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)

                -- คำนวณระยะห่าง 2D ระหว่างผู้เล่นกับ waypoint
                local dx = wpCoords.x - playerCoords.x
                local dy = wpCoords.y - playerCoords.y
                local distance = math.sqrt(dx * dx + dy * dy)

                -- มุมจากผู้เล่นไป waypoint (0-360)
                local angleToWP = math.deg(math.atan2(dy, dx))
                if angleToWP < 0 then
                    angleToWP = angleToWP + 360
                end

                -- ดึงมุมหันหน้าตัวละคร (0-360)
                local playerHeading = GetEntityHeading(playerPed)
                if playerHeading < 0 then playerHeading = playerHeading + 360 end

                -- คำนวณมุมสัมพัทธ์ลูกศร: มุม waypoint ลบ มุมตัวละคร
                local relativeHeading = (angleToWP - playerHeading + 360) % 360

                -- ส่งข้อมูลไป NUI
                SendNUIMessage({
                    action = "showCompass",
                    heading = math.floor(relativeHeading),
                    distance = math.floor(distance)
                })

                showingUI = true
            end
        else
            if showingUI then
                SendNUIMessage({ action = "hideCompass" })
                showingUI = false
            end
        end
    end
end)
