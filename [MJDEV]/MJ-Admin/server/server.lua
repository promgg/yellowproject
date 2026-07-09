-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 

VORPcore = VORPcore or {}  -- ✅ เผื่อมีการกำหนดค่ามาก่อนจากระบบอื่น

TriggerEvent("getCore", function(core)
    VORPcore = core
end)
Inventory = exports.vorp_inventory:vorp_inventoryApi()

RegisterCommand('tp', function(source, args, rawCommand)
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
    if not (Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanTeleport) then
        TriggerClientEvent("pNotify:SendNotification", source, {
            text = "คุณไม่มีสิทธิ์ใช้คำสั่งนี้!",
            type = "error",
            timeout = 3000,
            layout = "centerLeft"
        })
        return
    end

    if #args < 3 then
        TriggerClientEvent("pNotify:SendNotification", source, {
            text = "❌ ใช้งาน: /tp <x> <y> <z>",
            type = "error",
            timeout = 3000,
            layout = "centerLeft"
        })
        return
    end

    local posx = tonumber(args[1])
    local posy = tonumber(args[2])
    local posz = tonumber(args[3])

    if posx and posy and posz then
        local ped = GetPlayerPed(source) -- ✅ Use server-side function
        SetEntityCoords(ped, posx, posy, posz)

        TriggerClientEvent("pNotify:SendNotification", source, {
            text = "✅ คุณถูกย้ายไปยังพิกัด (" .. posx .. ", " .. posy .. ", " .. posz .. ")",
            type = "success",
            timeout = 3000,
            layout = "centerLeft"
        })
    else
        TriggerClientEvent("pNotify:SendNotification", source, {
            text = "❌ พิกัดไม่ถูกต้อง! โปรดใส่ตัวเลขที่ถูกต้อง",
            type = "error",
            timeout = 3000,
            layout = "centerLeft"
        })
    end
end)

RegisterNetEvent("admin:Promote")
AddEventHandler("admin:Promote", function(playerID, newgroup)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local xTarget = VORPcore.getUser(playerID).getUsedCharacter
    local NewPlayerGroup = newgroup
    local playerGroup = xPlayer.group
    -- print(NewPlayerGroup)
    if playerGroup == 'admin' then
        xTarget.setGroup(NewPlayerGroup)
        TriggerEvent("vorp:setGroup", playerID, NewPlayerGroup)
    end
end)

RegisterNetEvent("admin:OpenInv")
AddEventHandler("admin:OpenInv", function(playerID)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local xTarget = VORPcore.getUser(playerID).getUsedCharacter
    local playerGroup = xPlayer.group
    if playerGroup == 'admin' then
        Inventory.OpenInv(source, xTarget.charIdentifier)
    end
end)

RegisterNetEvent("admin:GiveWeapon")
AddEventHandler("admin:GiveWeapon", function(playerID, weapon, ammos)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local xTarget = VORPcore.getUser(playerID).getUsedCharacter
    local nameplayer = xPlayer.firstname .. " " .. xPlayer.lastname
    local nameTarget = xTarget.firstname .. " " .. xTarget.lastname
    local ide = xTarget.identifier
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanGiveWeapon then
        local ammo = { ["nothing"] = ammos }
        local components = { ["nothing"] = 0 }
		Inventory.createWeapon(tonumber(playerID), weapon, nil, tonumber(ammo), components)
        TriggerClientEvent("pNotify:SendNotification", source, {
            text = 'ให้อาวุธชื่อ ' .. weapon .. "กับไอดี " .. playerID .. " เรียบร้อย",
            type = "success",
            timeout = 5000,
            layout = "centerLeft",
            queue = "left"
        })
        SetDistcord("MJDev-Admin ", "Admin"," ``` แอดมิน : " .. nameplayer .. "\n ให้อาวุธชื่อ " .. weapon .. " กับผู้เล่น " .. nameTarget .. "\n " .. ide .. " ```", 0000, '')
    end
end)

RegisterNetEvent("admin:AddItem")
AddEventHandler("admin:AddItem", function(playerID, selectedItem, amount)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local xTarget = VORPcore.getUser(playerID).getUsedCharacter
    local nameplayer = xPlayer.firstname .. " " .. xPlayer.lastname
    local nameTarget = xTarget.firstname .. " " .. xTarget.lastname
    local ide = xTarget.identifier
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanGiveItem then
        exports.vorp_inventory:addItem(playerID, selectedItem, amount)
        TriggerClientEvent("pNotify:SendNotification", playerID, {
            text = 'ให้ไอเทม ' .. selectedItem .. "กับไอดี " .. playerID .. " เรียบร้อย",
            type = "success",
            timeout = 5000,
            layout = "centerLeft",
            queue = "left"
        })
        SetDistcord("MJDev-Admin ", "Admin", " ``` แอดมิน : " .. nameplayer .. "\n ให้ไอเทม " .. selectedItem .." จำนวน " .. amount .. " กับผู้เล่น " .. nameTarget .. "\n " .. ide .. " ```", 0000, '')
    end
end)

RegisterNetEvent("admin:AddItemAll")
AddEventHandler("admin:AddItemAll", function(selectedItem, amount)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local nameplayer = xPlayer.firstname .. " " .. xPlayer.lastname
    local playerGroup = xPlayer.group
    local ide = xPlayer.identifier
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanGiveItem then
        for _, playerId in ipairs(GetPlayers()) do
            exports.vorp_inventory:addItem(playerId, selectedItem, amount)
        end
        TriggerClientEvent("pNotify:SendNotification", -1, {
            text = 'ให้ไอเทม ' .. selectedItem .. " จำนวน " .. amount.." เรียบร้อย",
            type = "success",
            timeout = 5000,
            layout = "centerLeft",
            queue = "left"
        })
        SetDistcord("MJDev-Admin ", "Admin",
            " ``` แอดมิน : " .. nameplayer .. "\n ให้ไอเทม " .. selectedItem ..
                " จำนวน " .. amount .. " \n " .. ide ..
                " ```", 0000, '')
    end
end)

RegisterNetEvent("admin:AddCash")
AddEventHandler("admin:AddCash", function(playerID, amount)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local xTarget = VORPcore.getUser(playerID).getUsedCharacter
    local nameplayer = xPlayer.firstname .. " " .. xPlayer.lastname
    local nameTarget = xTarget.firstname .. " " .. xTarget.lastname
    local ide = xTarget.identifier
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanAddCash then
        local target = VORPcore.getUser(playerID).getUsedCharacter
        target.addCurrency(0, amount) -- Add money 1000 | 0 = money, 1 = gold, 2 = rol
        TriggerClientEvent("pNotify:SendNotification", playerID, {
            text = 'ผู้ดูแลได้เพิ่มเงินให้คุณจำนวน ' ..amount .. ' เหรียญ',
            type = "success",
            timeout = 5000,
            layout = "centerLeft",
            queue = "left"
        })
        SetDistcord("MJDev-Admin ", "Admin", " ``` แอดมิน : " .. nameplayer .. "\n ให้เงิน จำนวน " .. amount .. " กับผู้เล่น " .. nameTarget .. "\n " .. ide .. " ```", 0000, 'https://discord.com/api/webhooks/')
    end
end)

RegisterNetEvent("admin:AddBank")
AddEventHandler("admin:AddBank", function(playerID, amount)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local xTarget = VORPcore.getUser(playerID).getUsedCharacter
    local nameplayer = xPlayer.firstname .. " " .. xPlayer.lastname
    local nameTarget = xTarget.firstname .. " " .. xTarget.lastname
    local ide = xTarget.identifier
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanAddBank then
        local target = VORPcore.getUser(playerID).getUsedCharacter
        target.addCurrency(1, amount) -- Add money 1000 | 0 = money, 1 = gold, 2 = rol
        SetDistcord("MJDev-Admin ", "Admin",
            " ``` แอดมิน : " .. nameplayer .. "\n ให้ทอง จำนวน " .. amount ..
                " กับผู้เล่น " .. nameTarget .. "\n " .. ide .. " ```", 0000,
            'https://discord.com/api/webhooks/')
		TriggerClientEvent("pNotify:SendNotification", playerID, {
			text = 'ผู้ดูแลได้เพิ่มทองให้คุณจำนวน ' .. amount .. ' EA',
			type = "success",
			timeout = 5000,
			layout = "centerLeft",
			queue = "left"
		})
        TriggerClientEvent("pNotify:SendNotification", source, {
            text = 'ผู้ดูแลได้เพิ่มทองให้คุณจำนวน ' .. amount .. ' EA',
            type = "success",
            timeout = 5000,
            layout = "centerLeft",
            queue = "left"
        })
    end
end)

RegisterNetEvent("admin:InfiAmmo")
AddEventHandler("admin:InfiAmmo", function(playerID)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local xTarget = VORPcore.getUser(playerID).getUsedCharacter
    local nameplayer = xPlayer.firstname .. " " .. xPlayer.lastname
    local nameTarget = xTarget.firstname .. " " .. xTarget.lastname
    local ide = xTarget.identifier
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].InfiAmmo then
        TriggerClientEvent("admin_:InfiAmmo", playerID)
        SetDistcord("MJDev-Admin ", "Admin", " ``` แอดมิน : " .. nameplayer ..
            "\n เช็ตกระสุนไม่จำกันให้ กับผู้เล่น " ..
            nameTarget .. "\n " .. ide .. " ```", 0000, 'https://discord.com/api/webhooks/')
    end
end)

RegisterNetEvent("admin:godmode")
AddEventHandler("admin:godmode", function(playerID)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local xTarget = VORPcore.getUser(playerID).getUsedCharacter
    local nameplayer = xPlayer.firstname .. " " .. xPlayer.lastname
    local nameTarget = xTarget.firstname .. " " .. xTarget.lastname
    local ide = xTarget.identifier
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanGodmode then
        TriggerClientEvent("admin:God", playerID)
        SetDistcord("MJDev-Admin ", "Admin",
            " ``` แอดมิน : " .. nameplayer ..
                "\n ได้เช็ต GodMode กับผู้เล่น " .. nameTarget .. "\n " .. ide ..
                " ```", 0000,
            'https://discord.com/api/webhooks/')
    end
end)


RegisterNetEvent("admin:godmodeall")
AddEventHandler("admin:godmodeall", function()
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local nameplayer = xPlayer.firstname .. " " .. xPlayer.lastname
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanGodmodeAll then
        TriggerClientEvent("admin:GodAll", -1)
        SetDistcord("MJDev-Admin ", "Admin", " ``` แอดมิน : " .. nameplayer ..
            "\n ได้เช็ต GodMode กับผู้เล่นทุกคน  ```", 0000,
            'https://discord.com/api/webhooks/')
    end
end)

RegisterNetEvent("admin:Golden")
AddEventHandler("admin:Golden", function(playerID)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local nameplayer = xPlayer.firstname .. " " .. xPlayer.lastname

    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].Golden then
        if playerID == 'all' then
            TriggerClientEvent("admin_:Golden", -1)
            SetDistcord("MJDev-Admin ", "Admin", " ``` แอดมิน : " .. nameplayer ..
                "\n ได้เช็ต เลือดเหลือง กับผู้เล่นทุกคน  ```",
                0000,
                'https://discord.com/api/webhooks/')
        else
            local xTarget = VORPcore.getUser(playerID).getUsedCharacter
            local nameTarget = xTarget.firstname .. " " .. xTarget.lastname
            local ide = xTarget.identifier
            TriggerClientEvent("admin_:Golden", playerID)
            SetDistcord("MJDev-Admin ", "Admin", " ``` แอดมิน : " .. nameplayer ..
                "\n ได้เช็ต เลือดเหลือง กับผู้เล่น " ..
                nameTarget .. "\n " .. ide .. " ```", 0000,
                'https://discord.com/api/webhooks/')
        end

    end
end)

RegisterNetEvent("admin:Kick")
AddEventHandler("admin:Kick", function(playerId, reason)
    print(playerId, reason)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local xTarget = VORPcore.getUser(playerId).getUsedCharacter
    local nameplayer = xPlayer.firstname .. " " .. xPlayer.lastname
    local nameTarget = xTarget.firstname .. " " .. xTarget.lastname
    local ide = xTarget.identifier
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanKick then
        DropPlayer(playerId, reason)
        SetDistcord("MJDev-Admin ", "Admin",
            " ``` แอดมิน : " .. nameplayer .. "\n ได้เตะผู้เล่น " .. nameTarget ..
                "\n " .. ide .. " ```", 0000,
            'https://discord.com/api/webhooks/')
    end
end)

RegisterNetEvent("admin:jail")
AddEventHandler("admin:jail", function(playerId, co)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    TriggerEvent('lawmen:JailPlayer', tonumber(playerId), tonumber(sco), '.....')
end)

RegisterNetEvent("admin:cjail")
AddEventHandler("admin:cjail", function(playerId, co)
    local sco = co * 60
    local xPlayer = VORPcore.getUser(source).getUsedCharacter

    TriggerClientEvent("lawmen:SetJail_time", playerId, sco)
    print(playerId, co)
end)

RegisterNetEvent("admin:anmall")
AddEventHandler("admin:anmall", function(text)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    TriggerClientEvent('annoucement_K1:annouce', -1, text, 'ผู้ดูแล')
end)

RegisterNetEvent("admin:anmid")
AddEventHandler("admin:anmid", function(playerId, text)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    TriggerClientEvent('annoucement_K1:annouce', playerId, text, 'ผู้ดูแล')
end)

RegisterNetEvent("admin:SetMonModel")
AddEventHandler("admin:SetMonModel", function(playerId, Model)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    TriggerClientEvent("admin_:SetMonModel", playerId, Model)
end)

RegisterNetEvent("admin:SetHorse")
AddEventHandler("admin:SetHorse", function(playerId, Model)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    TriggerClientEvent("admin_:SetHorse", playerId, Model)
end)

RegisterNetEvent("admin:KickAll")
AddEventHandler("admin:KickAll", function(reason)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local nameplayer = xPlayer.firstname .. " " .. xPlayer.lastname
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanKick then
        local xPlayers = GetPlayers()
        for k, user in pairs(xPlayers) do
            DropPlayer(user, 'MJDev : ' .. reason)
            SetDistcord("MJDev-Admin ", "Admin", " ``` แอดมิน : " .. nameplayer ..
                "\n ได้เตะผู้เล่น ทั้งเชิฟเวอร์ ```", 0000,
                'https://discord.com/api/webhooks/')
        end
    end
end)

RegisterNetEvent("admin:Announcement")
AddEventHandler("admin:Announcement", function(message)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanAnnounce then
        TriggerClientEvent("chat:addMessage", -1, {
            args = {"^1ผู้ดูแลระบบ ^7: ", message}
        })
    else
        TriggerClientEvent("chat:addMessage", source, {
            args = {"^1ระบบ",
                    " : คุณไม่มีสิทเข้าถึงเเผงควบคุมผู้ดูเเลระบบ"}
        })
    end
end)

RegisterNetEvent("admin:Notification")
AddEventHandler("admin:Notification", function(playerID, message)
    local _source = playerID
    TriggerClientEvent("chat:addMessage", _source, {
        args = {"admin ", message}
    })
end)

RegisterNetEvent("admin:Teleport")
AddEventHandler("admin:Teleport", function(targetId, action)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local playerGroup = xPlayer.group
    local temp_id = nil
    local playerCoords = nil
    local tr = nil
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanTeleport then
        if action == "bring" then
            playerCoords = GetEntityCoords(GetPlayerPed(source))
            xPlayer = VORPcore.getUser(source).getUsedCharacter
            xTarget = VORPcore.getUser(targetId).getUsedCharacter
            temp_id = source
            tr = targetId
        elseif action == "goto" then
            playerCoords = GetEntityCoords(GetPlayerPed(targetId))
            xPlayer = VORPcore.getUser(targetId).getUsedCharacter
            xTarget = VORPcore.getUser(source).getUsedCharacter
            temp_id = targetId
            tr = source
        end
        if xTarget then
            TriggerClientEvent("admin_:teleport", tr, playerCoords)
        end
    end
end)

RegisterNetEvent("admin:TeleportAll")
AddEventHandler("admin:TeleportAll", function(coords)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local playerGroup = xPlayer.group
    local temp_id = nil
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanTeleportAll then
        local playerCoords = GetEntityCoords(GetPlayerPed(source))
        TriggerClientEvent("admin_:teleport", -1, playerCoords)
		TriggerClientEvent("pNotify:SendNotification", -1, {
			text = 'ผู้ดูแลได้ดึงคุณมาหาเขา!',
			type = "success",
			timeout = 5000,
			layout = "centerLeft",
			queue = "left"
		})
    end
end)

RegisterNetEvent("admin:Slay")
AddEventHandler("admin:Slay", function(target)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanSlay then
        TriggerClientEvent("admin:Slay", target)
		TriggerClientEvent("pNotify:SendNotification", target, {
			text = 'ผู้ดูแลได้ฆ่าคุณ!',
			type = "success",
			timeout = 5000,
			layout = "centerLeft",
			queue = "left"
		})
    end
end)

RegisterNetEvent("admin:SlayAll")
AddEventHandler("admin:SlayAll", function()
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanSlayAll then
        TriggerClientEvent("admin:Slay", -1)
		TriggerClientEvent("pNotify:SendNotification", -1, {
			text = 'ผู้ดูแลได้ฆ่าคุณ!',
			type = "success",
			timeout = 5000,
			layout = "centerLeft",
			queue = "left"
		})
    end
end)

RegisterNetEvent("admin:loadskin")
AddEventHandler("admin:loadskin", function(target)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local playerGroup = xPlayer.group
    TriggerClientEvent("admin:loadskin", target)
end)

RegisterNetEvent("admin:Freeze")
AddEventHandler("admin:Freeze", function(target)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanFreeze then
        TriggerClientEvent("admin:Freeze", target)
		TriggerClientEvent("pNotify:SendNotification", target, {
			text = 'ผู้ดูแลได้แช่แข็งคุณ!',
			type = "success",
			timeout = 5000,
			layout = "centerLeft",
			queue = "left"
		})
    end
end)

RegisterNetEvent("admin:FreezeAll")
AddEventHandler("admin:FreezeAll", function()
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanFreezeAll then
        TriggerClientEvent("admin:Freeze", -1)
		TriggerClientEvent("pNotify:SendNotification", -1, {
			text = 'ผู้ดูแลได้แช่แข็งคุณ!',
			type = "success",
			timeout = 5000,
			layout = "centerLeft",
			queue = "left"
		})
    end
end)

RegisterNetEvent("admin:setJob")
AddEventHandler("admin:setJob", function(target, newjob, newgrade, newJobLabel)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local xTarget = VORPcore.getUser(target).getUsedCharacter
    local nameplayer = xPlayer.firstname .. " " .. xPlayer.lastname
    local nameTarget = xTarget.firstname .. " " .. xTarget.lastname
    local ide = xTarget.identifier
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanSetJob then
        xTarget.setJob(newjob)
        xTarget.setJobGrade(newgrade)
        xTarget.setJobLabel(newJobLabel)
		TriggerClientEvent("pNotify:SendNotification", target, {
            text = 'อาชีพของ ' .. nameTarget .. ' ถูกเปลี่ยนเป็น ' .. newjob .. ' ระดับ ' .. newJobLabel,
			type = "success",
			timeout = 5000,
			layout = "centerLeft",
			queue = "left"
		})
        SetDistcord("MJDev-Admin ", "Admin",
            " ``` แอดมิน : " .. nameplayer ..
                "\n เช็ตอาชีพของผู้เล่น " .. nameTarget .. " เป็น " .. newjob ..
                " ระดับ " .. newJobLabel .. "\n " .. ide .. " ```", 0000,
            'https://discord.com/api/webhooks/')
    end
end)

RegisterNetEvent("admin:resetcol")
AddEventHandler("admin:resetcol", function(target)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanRevive then
        TriggerClientEvent('MJ-Cooldown:Stopinjured', target)
		TriggerClientEvent("pNotify:SendNotification", target, {
			text = 'ผู้ดูแลได้ลบคลูดาวน์ให้คุณ',
			type = "success",
			timeout = 5000,
			layout = "centerLeft",
			queue = "left"
		})
    end
end)

RegisterNetEvent("admin:revivenocooldown")
AddEventHandler("admin:revivenocooldown", function(target)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanRevive then
        TriggerClientEvent('MJ-Cooldown:Stopinjured', target)
        TriggerClientEvent(Config["ambulance"]["server_revive"], target)
		TriggerClientEvent("pNotify:SendNotification", target, {
			text = 'ผู้ดูแลได้ช่วยชีวิตคุณ',
			type = "success",
			timeout = 5000,
			layout = "centerLeft",
			queue = "left"
		})
    end
end)

RegisterNetEvent("admin:revive")
AddEventHandler("admin:revive", function(target)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local playerGroup = xPlayer.group
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanRevive then
        TriggerClientEvent(Config["ambulance"]["server_revive"], target)
		TriggerClientEvent("pNotify:SendNotification", target, {
			text = 'ผู้ดูแลได้ช่วยชีวิตคุณ!',
			type = "success",
			timeout = 5000,
			layout = "centerLeft",
			queue = "left"
		})
    end
end)

RegisterServerEvent("admin:Spy")
AddEventHandler("admin:Spy", function(target)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local xTarget = Sildurs.GetPlayerFromId(target)
    local coord = xTarget.getCoords()
    xPlayer.setCoords(coord)
end)

function split(s, delimiter)
    result = {}
    for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

RegisterNetEvent("admin:addUpdateblip")
AddEventHandler("admin:addUpdateblip", function(state)
    Updateblip[source] = state
    if state then
        Updateblip_count = Updateblip_count + 1
    else
        Updateblip_count = Updateblip_count - 1
    end
end)

RegisterNetEvent("admin:delcarall")
AddEventHandler("admin:delcarall", function()
    TriggerClientEvent("admin_:delcarall", -1)
	TriggerClientEvent("pNotify:SendNotification", -1, {
		text = 'Admin ได้ทำการลบเกวียนผู้เล่นทั้งเซิร์ฟ!',
		type = "success",
		timeout = 5000,
		layout = "centerLeft",
		queue = "left"
	})
end)

RegisterNetEvent("admin:reviveall")
AddEventHandler("admin:reviveall", function()
    TriggerClientEvent(Config["ambulance"]["server_reviveall"], -1)
	TriggerClientEvent("pNotify:SendNotification", -1, {
		text = 'ผู้ดูแลได้ชุบชีวิตคุณ!',
		type = "success",
		timeout = 5000,
		layout = "centerLeft",
		queue = "left"
	})
end)


RegisterServerEvent('admin:setfoob')
AddEventHandler('admin:setfoob', function()
    local playerId = source
    local UserCharacter = VORPcore.getUser(playerId).getUsedCharacter
    local status = json.encode({
        ['Hunger'] = 100000,
        ['Thirst'] = 100000,
        ['Stress'] = 0
    })
    UserCharacter.setStatus(status)
    TriggerClientEvent("JKL-HudStamina:StartFunctions", playerId, status)
end)

RegisterServerEvent('admin:stopfood')
AddEventHandler('admin:stopfood', function(playerId)
    if not StopNeeds[playerId] then

		TriggerClientEvent("pNotify:SendNotification", playerId, {
			text = "<b style='color:red'>แจ้งตือน </b> <b style='color:while'>: หลอดอาหารหยุดการทำงาน </strong>",
			type = "success",
			timeout = 5000,
			layout = "centerLeft",
			queue = "left"
		})
    else
		TriggerClientEvent("pNotify:SendNotification", playerId, {
			text = "<b style='color:red'>แจ้งตือน </b> <b style='color:while'>: หลอดอาหารเริ่มการทำงาน </strong>",
			type = "success",
			timeout = 5000,
			layout = "centerLeft",
			queue = "left"
		})
    end
end)

RegisterServerEvent('admin:foodall')
AddEventHandler('admin:foodall', function(playerId)
    local _source = source
    local UserCharacter = VORPcore.getUser(playerId).getUsedCharacter
    local status = json.encode({
        ['Hunger'] = 1000,
        ['Thirst'] = 1000,
        ['Metabolism'] = 10000
    })
    UserCharacter.setStatus(status)
    TriggerClientEvent("vorpmetabolism:changeValue", _source, "Thirst", 1000)
    TriggerClientEvent("vorpmetabolism:changeValue", _source, "Hunger", 1000)
    TriggerClientEvent("MJ-STATUSHUD:setStatus", _source, status)
end)

RegisterServerEvent('admin:stressall')
AddEventHandler('admin:stressall', function(playerId)
    local UserCharacter = VORPcore.getUser(playerId).getUsedCharacter
    local status = json.encode({
        ['Hunger'] = 1000,
        ['Thirst'] = 1000,
        ['Metabolism'] = 10000
    })
    UserCharacter.setStatus(status)
    TriggerClientEvent("vorpmetabolism:changeValue", playerId, "Thirst", 1000)
    TriggerClientEvent("vorpmetabolism:changeValue", playerId, "Hunger", 1000)
    TriggerClientEvent("MJ-STATUSHUD:setStatus", playerId, status)
end)

RegisterServerEvent('admin:cleanall')
AddEventHandler('admin:cleanall', function(playerId)
    local UserCharacter = VORPcore.getUser(playerId).getUsedCharacter
    local status = json.encode({
        ['Hunger'] = 0,
        ['Thirst'] = 0,
        ['Metabolism'] = 0
    })
    UserCharacter.setStatus(status)
    TriggerClientEvent("vorpmetabolism:changeValue", playerId, "Thirst", 0)
    TriggerClientEvent("vorpmetabolism:changeValue", playerId, "Hunger", 0)
    TriggerClientEvent("MJ-STATUSHUD:setStatus", playerId, status)
end)

RegisterServerEvent('admin:healall')
AddEventHandler('admin:healall', function(playerId)
    if playerId then
        TriggerClientEvent('admin:healFromAdmin', playerId)
        TriggerClientEvent("pNotify:SendNotification", playerId, {
            text = "<b style='color:red'>แจ้งตือน </b> <b style='color:while'>: ผู้ดูแลได้เพิ่มเลือดให้คุณ </strong>",
            type = "success",
            timeout = 5000,
            layout = "centerLeft",
            queue = "left"
        })
    else
        TriggerClientEvent('admin:healFromAdmin', -1)
        TriggerClientEvent("pNotify:SendNotification", -1, {
            text = "<b style='color:red'>แจ้งตือน </b> <b style='color:while'>: ผู้ดูแลได้เพิ่มเลือดให้คุณ </strong>",
            type = "success",
            timeout = 5000,
            layout = "centerLeft",
            queue = "left"
        })
    end
end)

RegisterServerEvent('admin:blockMic')
AddEventHandler('admin:blockMic', function(target, time, reason)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local xTarget = Sildurs.GetPlayerFromId(target)
    MySQL.Async.execute('INSERT INTO `ban_mic` (license, name, time, reason) VALUES (@license, @name, @time, @reason)',
        {
            ['@license'] = xTarget.getIdentifier(),
            ['@name'] = GetPlayerName(target),
            ['@time'] = time,
            ['@reason'] = reason
        }, function(result)
            xPlayer.triggerEvent("pNotify:SendNotification", {
                text = "<b style='color:green'>บล๊อคการสื่อการ </b> <b style='color:while'>: " ..
                    GetPlayerName(target) .. " เวลา " .. Sildurs.Math.Round(time) ..
                    " วินาทีแล้ว</strong>",
                type = "success",
                timeout = 5000,
                layout = "centerLeft",
                queue = "left"
            })
            xTarget.triggerEvent("pNotify:SendNotification", {
                text = "<b style='color:red'>คุณถูกบล๊อคการสื่อการข้อหา </b> <b style='color:while'>: " ..
                    reason .. " เป็นเวลา" .. Sildurs.Math.Round(time) .. " วินาที</strong>",
                type = "success",
                timeout = 8000,
                layout = "centerLeft",
                queue = "left"
            })
            xTarget.triggerEvent('admin:GetTimerBlock')
        end)
end)

RegisterNetEvent('txAdmin:menu:showPlayerIDs', function(enabled)
    TriggerClientEvent('txAdmin:menu:showPlayerIDs', source, enabled)
end)

--[[ RegisterServerEvent('admin:GetTimerBlockSV')
AddEventHandler('admin:GetTimerBlockSV', function()
	local xPlayer = VORPcore.getUser(source).getUsedCharacter 
	if xPlayer then 
		MySQL.Async.fetchAll('SELECT * FROM ban_mic WHERE license = @license', {
			['@license'] = xPlayer.getIdentifier(),
	
		}, function(data)
			if data[1] == nil then
				return
			else
				local time = data[1].time
				xPlayer.triggerEvent('admin:SetTimeBlockMic', tonumber(time))
				TriggerClientEvent('admin:ShowTextBlockMic', -1, tonumber(time), xPlayer.source)
			end
		end)
	end
	
end) ]]

RegisterServerEvent('admin:enableMic')
AddEventHandler('admin:enableMic', function(playerId)
    local xPlayer = Sildurs.GetPlayerFromId(playerId)
    if xPlayer then
        MySQL.Async.execute('DELETE FROM ban_mic WHERE license = @license', {
            ['@license'] = xPlayer.getIdentifier()
        }, function(deleted)
            xPlayer.triggerEvent('admin:SetTimeBlockMic', 0)
            xPlayer.triggerEvent("pNotify:SendNotification", {
                text = '<strong class="green-text">การสื่อการ ของคุณใช้งานได้ปกติ</strong>',
                type = "success",
                timeout = 5000,
                layout = "centerLeft",
                queue = "left"
            })
            TriggerClientEvent('admin:ShowTextBlockMic', -1, 0, xPlayer.source)
        end)
    end
end)

RegisterNetEvent("MJ-attack:attack")
AddEventHandler("MJ-attack:attack", function(target, entity)
    TriggerClientEvent("MJ-attack:attack", target, source, entity)
end)

RegisterServerEvent('admin:getDataFlagWar')
AddEventHandler('admin:getDataFlagWar', function()
    TriggerEvent("MJDev-FlagWar:getisFlagWar", function(GetPlayersFlagWar)
        TriggerClientEvent("admin:showFlagWar", source, GetPlayersFlagWar)
    end)
end)

Citizen.CreateThread(function()
    while true do
        if Updateblip_count >= 1 then
            local xPlayers = GetPlayers()
            local data = {}
            for i = 1, #xPlayers, 1 do
                if VORPcore.getUser(xPlayers[i]) then
                    local xPlayer = VORPcore.getUser(xPlayers[i]).getUsedCharacter
                    if xPlayer.firstname == nil then
                        xPlayer.firstname = '/'
                    end
                    if xPlayer.lastname == nil then
                        xPlayer.lastname = '/'
                    end
                    data[i] = {
                        playerId = xPlayers[i],
                        rpname = xPlayer.firstname .. " " .. xPlayer.lastname,
                        coords = GetEntityCoords(GetPlayerPed(xPlayers[i]))
                    }
                end

            end
            for key, value in pairs(Updateblip) do
                if value then
                    TriggerClientEvent("admin:showblip", key, key, data)
                end
            end
            if #xPlayers > 256 then
                Citizen.Wait(1000 * 5)
            elseif #xPlayers > 128 then
                Citizen.Wait(1000 * 4)
            elseif #xPlayers > 96 then
                Citizen.Wait(1000 * 3)
            elseif #xPlayers > 64 then
                Citizen.Wait(1000 * 2)
            else
                Citizen.Wait(1000)
            end
        end
        Citizen.Wait(1000)
    end
end)

function SetDistcord(name, message, description, color, DiscordWebHook)

    local embeds = {{
        ["title"] = message,
        ["type"] = "rich",
        ["color"] = color,
        ["description"] = description,
        ["footer"] = {
            ["text"] = communityname,
            ["icon_url"] = communtiylogo
        }
    }}

    if message == nil or message == "Player Log #1" then
        return FALSE
    end
    PerformHttpRequest(DiscordWebHook, function(err, text, headers)
    end, 'POST', json.encode({
        username = name,
        embeds = embeds
    }), {
        ['Content-Type'] = 'application/json'
    })
end

Citizen.CreateThread(function()
    Citizen.Wait(5000) 
    print("##################################################")
    print("##                                              ##")
    print("##           \27[37mMJ DEV | Verify \27[32mSuccess\27[0m            ##")
    print("##           \27[36mThank You For Purchase\27[0m             ##")
    print("##           \27[34mVersion : 1.0 (Latest)\27[0m             ##")
    print("##                                              ##")
    print("##################################################")
    print("###### \27[36mDiscord: https://discord.gg/gHRNMDQKzb\27[0m ####")
end)
