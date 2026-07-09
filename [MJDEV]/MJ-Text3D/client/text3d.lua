local Text3D = {}
local worldTexts = {}

function Text3D.AddWorldText(id, x, y, z, message)
    worldTexts[id] = {
        x = x,
        y = y,
        z = z + 1,
        message = Text3D.Fix(message),
    }
end

function Text3D.RemoveWorldText(id)
    worldTexts[id] = nil
end

function Text3D.Fix(str)
    str = string.gsub(str, "&", "&amp")
    str = string.gsub(str, "<", "&lt")
    str = string.gsub(str, ">", "&gt")
    str = string.gsub(str, "\"", "&quot")
    str = string.gsub(str, "'", "&#039")
    return str
end

-- แสดงข้อความ
CreateThread(function()
    local lstr = ""
    while true do
        Wait(5)
        local tick = GetGameTimer()
        local str = ""

        for id, data in pairs(worldTexts) do
            local ons, x, y = GetHudScreenPositionFromWorldPosition(data.x, data.y, data.z)
            if not ons then
                x = (x * 100)
                y = (y * 100)
                str = str .. "<p style=\"left: "..x.."%;top: "..y.."%;-webkit-transform: translate(-50%, 0%);max-width: 100%;position: fixed;text-align: center;color: #00ff00;background-color: #000000AA;border-radius:3px;\"><b> "..data.message.."⠀</b></p>"
            end
        end

        if str ~= lstr then
            SendNUIMessage({meta = "Text3D", html = str})
            lstr = str
        end
    end
end)

-- ตรวจจับระยะทางผู้เล่นทุก ๆ 500 มิลลิวินาที
CreateThread(function()
    while true do
        Wait(500)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for id, data in pairs(worldTexts) do
            local dist = #(playerCoords - vec3(data.x, data.y, data.z))
            if dist > 5.0 then
                Text3D.RemoveWorldText(id)
            end
        end
    end
end)

function GetText3D()
    return Text3D
end

return {
    GetText3D = GetText3D
}

-- local Text3D = exports["MJ-Text3D"]:GetText3D()

-- -- เรียกแสดงข้อความที่ตำแหน่งโลก
-- Text3D.AddWorldText("cake1", 200.5, -900.3, 40.7, "นี่คือเค้กของคุณ!")
