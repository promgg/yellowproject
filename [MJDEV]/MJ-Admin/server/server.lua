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
            layout = "topRight"
        })
        return
    end

    if #args < 3 then
        TriggerClientEvent("pNotify:SendNotification", source, {
            text = "❌ ใช้งาน: /tp <x> <y> <z>",
            type = "error",
            timeout = 3000,
            layout = "topRight"
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
            layout = "topRight"
        })
    else
        TriggerClientEvent("pNotify:SendNotification", source, {
            text = "❌ พิกัดไม่ถูกต้อง! โปรดใส่ตัวเลขที่ถูกต้อง",
            type = "error",
            timeout = 3000,
            layout = "topRight"
        })
    end
end)

RegisterNetEvent("admin:Promote")
AddEventHandler("admin:Promote", function(playerID, newgroup)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local xTarget = VORPcore.getUser(playerID).getUsedCharacter
    local NewPlayerGroup = newgroup
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
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
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
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
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanGiveWeapon then
        local ammo = { ["nothing"] = ammos }
        local components = { ["nothing"] = 0 }
		Inventory.createWeapon(tonumber(playerID), weapon, nil, tonumber(ammo), components)
        TriggerClientEvent("pNotify:SendNotification", source, {
            text = 'ให้อาวุธชื่อ ' .. weapon .. "กับไอดี " .. playerID .. " เรียบร้อย",
            type = "success",
            timeout = 5000,
            layout = "topRight",
            queue = "left"
        })
        SetDistcord("MJDev-Admin ", "Admin"," ``` แอดมิน : " .. nameplayer .. "\n ให้อาวุธชื่อ " .. weapon .. " กับผู้เล่น " .. nameTarget .. "\n " .. ide .. " ```", 0000, '')
    end
end)

RegisterNetEvent("admin:AddItem")
AddEventHandler("admin:AddItem", function(playerID, selectedItem, amount)
    -- ⚠️ ต้องเก็บ source ใส่ตัวแปรก่อนเสมอ
    -- source เป็นตัวแปรวิเศษที่ใช้ได้เฉพาะ "ก่อน yield ครั้งแรก" เท่านั้น
    -- addItem ด้านล่างวิ่งไป DB (yield) พอกลับมา source กลายเป็น nil แล้ว
    -- ทำให้ TriggerClientEvent ที่แจ้งแอดมินโยน error ทุกครั้งที่แจกของ:
    --   native 000000002f7a49e6: Argument at index 1 was null
    local src = source
    local xPlayer = VORPcore.getUser(src).getUsedCharacter
    local xTarget = VORPcore.getUser(playerID).getUsedCharacter
    local nameplayer = xPlayer.firstname .. " " .. xPlayer.lastname
    local nameTarget = xTarget.firstname .. " " .. xTarget.lastname
    local ide = xTarget.identifier
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(src) or 'user'
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanGiveItem then
        exports.vorp_inventory:addItem(playerID, selectedItem, amount)
        TriggerClientEvent("pNotify:SendNotification", playerID, {
            text = 'ให้ไอเทม ' .. selectedItem .. "กับไอดี " .. playerID .. " เรียบร้อย",
            type = "success",
            timeout = 5000,
            layout = "topRight",
            queue = "left"
        })
        -- แจ้งแอดมินยืนยันความสำเร็จด้วย (เดิมแจ้งแค่เป้าหมาย แอดมินไม่เห็นผลลัพธ์อะไรเลยแม้สำเร็จ)
        TriggerClientEvent("pNotify:SendNotification", src, {
            text = 'ให้ไอเทม ' .. selectedItem .. ' จำนวน ' .. amount .. ' กับ ' .. nameTarget .. ' เรียบร้อย',
            type = "success",
            timeout = 5000,
            layout = "topRight",
            queue = "left"
        })
        SetDistcord("MJDev-Admin ", "Admin", " ``` แอดมิน : " .. nameplayer .. "\n ให้ไอเทม " .. selectedItem .." จำนวน " .. amount .. " กับผู้เล่น " .. nameTarget .. "\n " .. ide .. " ```", 0000, '')
    end
end)

RegisterNetEvent("admin:AddItemAll")
AddEventHandler("admin:AddItemAll", function(selectedItem, amount)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    local nameplayer = xPlayer.firstname .. " " .. xPlayer.lastname
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
    local ide = xPlayer.identifier
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanGiveItem then
        for _, playerId in ipairs(GetPlayers()) do
            exports.vorp_inventory:addItem(playerId, selectedItem, amount)
        end
        TriggerClientEvent("pNotify:SendNotification", -1, {
            text = 'ให้ไอเทม ' .. selectedItem .. " จำนวน " .. amount.." เรียบร้อย",
            type = "success",
            timeout = 5000,
            layout = "topRight",
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
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanAddCash then
        local target = VORPcore.getUser(playerID).getUsedCharacter
        target.addCurrency(0, amount) -- Add money 1000 | 0 = money, 1 = gold, 2 = rol
        TriggerClientEvent("pNotify:SendNotification", playerID, {
            text = 'ผู้ดูแลได้เพิ่มเงินให้คุณจำนวน ' ..amount .. ' เหรียญ',
            type = "success",
            timeout = 5000,
            layout = "topRight",
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
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
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
			layout = "topRight",
			queue = "left"
		})
        TriggerClientEvent("pNotify:SendNotification", source, {
            text = 'ผู้ดูแลได้เพิ่มทองให้คุณจำนวน ' .. amount .. ' EA',
            type = "success",
            timeout = 5000,
            layout = "topRight",
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
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
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
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
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
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
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

    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
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
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
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
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
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
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
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

-- ป้ายประกาศเต็มจอผ่าน MJ-Announcement (soft integration — ยิง event ตรงไปที่ client ของ
-- MJ-Announcement เลย ไม่ผ่านคำสั่ง /ac เพื่อไม่ต้องพึ่งพา resource นั้นเป็น dependency ตายตัว)
-- คนละอันกับ "admin:Announcement" ด้านบนที่ยิงลงแชทธรรมดา (chat:addMessage)
RegisterNetEvent("admin:MJAnnounce")
AddEventHandler("admin:MJAnnounce", function(message)
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanMJAnnounce then
        TriggerClientEvent('JKL-annoucement_nui:annouce', -1, message)
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
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
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
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
    local temp_id = nil
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanTeleportAll then
        local playerCoords = GetEntityCoords(GetPlayerPed(source))
        TriggerClientEvent("admin_:teleport", -1, playerCoords)
		TriggerClientEvent("pNotify:SendNotification", -1, {
			text = 'ผู้ดูแลได้ดึงคุณมาหาเขา!',
			type = "success",
			timeout = 5000,
			layout = "topRight",
			queue = "left"
		})
    end
end)

RegisterNetEvent("admin:Slay")
AddEventHandler("admin:Slay", function(target)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanSlay then
        TriggerClientEvent("admin:Slay", target)
		TriggerClientEvent("pNotify:SendNotification", target, {
			text = 'ผู้ดูแลได้ฆ่าคุณ!',
			type = "success",
			timeout = 5000,
			layout = "topRight",
			queue = "left"
		})
    end
end)

RegisterNetEvent("admin:SlayAll")
AddEventHandler("admin:SlayAll", function()
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanSlayAll then
        TriggerClientEvent("admin:Slay", -1)
		TriggerClientEvent("pNotify:SendNotification", -1, {
			text = 'ผู้ดูแลได้ฆ่าคุณ!',
			type = "success",
			timeout = 5000,
			layout = "topRight",
			queue = "left"
		})
    end
end)

RegisterNetEvent("admin:loadskin")
AddEventHandler("admin:loadskin", function(target)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
    TriggerClientEvent("admin:loadskin", target)
end)

RegisterNetEvent("admin:Freeze")
AddEventHandler("admin:Freeze", function(target)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanFreeze then
        TriggerClientEvent("admin:Freeze", target)
		TriggerClientEvent("pNotify:SendNotification", target, {
			text = 'ผู้ดูแลได้แช่แข็งคุณ!',
			type = "success",
			timeout = 5000,
			layout = "topRight",
			queue = "left"
		})
    end
end)

RegisterNetEvent("admin:FreezeAll")
AddEventHandler("admin:FreezeAll", function()
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanFreezeAll then
        TriggerClientEvent("admin:Freeze", -1)
		TriggerClientEvent("pNotify:SendNotification", -1, {
			text = 'ผู้ดูแลได้แช่แข็งคุณ!',
			type = "success",
			timeout = 5000,
			layout = "topRight",
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
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanSetJob then
        xTarget.setJob(newjob)
        xTarget.setJobGrade(newgrade)
        xTarget.setJobLabel(newJobLabel)
		TriggerClientEvent("pNotify:SendNotification", target, {
            text = 'อาชีพของ ' .. nameTarget .. ' ถูกเปลี่ยนเป็น ' .. newjob .. ' ระดับ ' .. newJobLabel,
			type = "success",
			timeout = 5000,
			layout = "topRight",
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
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanRevive then
        TriggerClientEvent('MJ-Cooldown:Stopinjured', target)
		TriggerClientEvent("pNotify:SendNotification", target, {
			text = 'ผู้ดูแลได้ลบคลูดาวน์ให้คุณ',
			type = "success",
			timeout = 5000,
			layout = "topRight",
			queue = "left"
		})
    end
end)

RegisterNetEvent("admin:revivenocooldown")
AddEventHandler("admin:revivenocooldown", function(target)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanRevive then
        TriggerClientEvent('MJ-Cooldown:Stopinjured', target)
        TriggerClientEvent(Config["ambulance"]["server_revive"], target)
		TriggerClientEvent("pNotify:SendNotification", target, {
			text = 'ผู้ดูแลได้ช่วยชีวิตคุณ',
			type = "success",
			timeout = 5000,
			layout = "topRight",
			queue = "left"
		})
    end
end)

RegisterNetEvent("admin:revive")
AddEventHandler("admin:revive", function(target)
    local xPlayer = VORPcore.getUser(source).getUsedCharacter
    -- ใช้ admin.GetPlayerGroup() (normalize เป็นตัวพิมพ์เล็ก+ตัด whitespace) แทน xPlayer.group ดิบๆ
    -- เดิมอ่านค่าดิบตรงๆ ทำให้ถ้า group จริงเป็น "Admin"/มีช่องว่างเกิน จะไม่ตรงคีย์ "admin" ใน
    -- Config.Perms แล้วเช็คสิทธิ์ล้มเหลวเงียบๆ (ไม่มี error/แจ้งเตือน) ทั้งที่ผู้เล่นเป็นแอดมินจริง —
    -- guard แบบเดียวกับที่ /tp ใช้อยู่แล้ว (บรรทัดบน) เพราะ core_server.lua โหลดหลังไฟล์นี้
    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(source) or 'user'
    if Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanRevive then
        TriggerClientEvent(Config["ambulance"]["server_revive"], target)
		TriggerClientEvent("pNotify:SendNotification", target, {
			text = 'ผู้ดูแลได้ช่วยชีวิตคุณ!',
			type = "success",
			timeout = 5000,
			layout = "topRight",
			queue = "left"
		})
    end
end)

-- วาร์ปแอดมินไปหาผู้เล่นเป้าหมาย
--
-- ของเดิมพังสามชั้นพร้อมกัน:
--   1) Sildurs.GetPlayerFromId — global ของ ESX ที่ไม่มีอยู่จริงในโปรเจกต์นี้ (grep ทั้ง repo
--      ไม่เจอการประกาศเลย) เรียกปุ๊บ throw ทันที "attempt to index a nil value"
--   2) xTarget.getCoords() / xPlayer.setCoords() — เมธอดของ ESX เช่นกัน ตัวละคร VORP ไม่มี
--      ต่อให้ Sildurs มีจริงก็ยังพังอยู่ดี
--   3) ไม่เช็คสิทธิ์เลยสักบรรทัด — ผู้เล่นทั่วไปยิง event นี้เองแล้ววาร์ปไปหาใครก็ได้
--
-- ท่าที่ถูกต้องมีอยู่แล้วใน core_server.lua:112-118 (MJADMIN:TeleportSpectate)
RegisterServerEvent("admin:Spy")
AddEventHandler("admin:Spy", function(target)
    local src = source

    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(src) or 'user'
    if not (Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanTeleport) then return end

    target = tonumber(target)
    if not target or target == src then return end
    if not GetPlayerName(target) then return end -- ต้องออนไลน์อยู่จริงตอนนี้

    local targetPed = GetPlayerPed(target)
    if not targetPed or targetPed == 0 then return end

    local coords = GetEntityCoords(targetPed)
    TriggerClientEvent("MJADMIN:setCoords", src,
        { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 })
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
		layout = "topRight",
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
		layout = "topRight",
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
			layout = "topRight",
			queue = "left"
		})
    else
		TriggerClientEvent("pNotify:SendNotification", playerId, {
			text = "<b style='color:red'>แจ้งตือน </b> <b style='color:while'>: หลอดอาหารเริ่มการทำงาน </strong>",
			type = "success",
			timeout = 5000,
			layout = "topRight",
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
            layout = "topRight",
            queue = "left"
        })
    else
        TriggerClientEvent('admin:healFromAdmin', -1)
        TriggerClientEvent("pNotify:SendNotification", -1, {
            text = "<b style='color:red'>แจ้งตือน </b> <b style='color:while'>: ผู้ดูแลได้เพิ่มเลือดให้คุณ </strong>",
            type = "success",
            timeout = 5000,
            layout = "topRight",
            queue = "left"
        })
    end
end)

-- บล็อกไมค์ผู้เล่น
--
-- ของเดิมใช้ Sildurs.GetPlayerFromId + xPlayer.triggerEvent() + Sildurs.Math.Round() ซึ่งเป็น
-- ของ ESX ทั้งหมด และที่ร้ายกว่านั้นคือมัน throw ที่บรรทัด Sildurs ซึ่งอยู่ "ก่อน" MySQL.Async
-- แปลว่าไม่เคยมีแถวไหนถูกเขียนลง ban_mic เลยแม้แต่ครั้งเดียว — ระบบนี้ไม่เคยทำงานมาก่อน
RegisterServerEvent('admin:blockMic')
AddEventHandler('admin:blockMic', function(target, time, reason)
    local src = source

    local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(src) or 'user'
    if not (Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanKick) then return end

    target = tonumber(target)
    time   = tonumber(time)
    if not target or not time or time <= 0 then return end
    if not GetPlayerName(target) then return end

    local targetUser = VORPcore.getUser(target)
    if not targetUser then return end
    local xTarget = targetUser.getUsedCharacter
    if not xTarget then return end

    local license  = xTarget.identifier
    local seconds  = math.floor(time + 0.5) -- แทน Sildurs.Math.Round
    local reasonTx = tostring(reason or '-')
    local targetName = GetPlayerName(target)

    MySQL.Async.execute('INSERT INTO `ban_mic` (license, name, time, reason) VALUES (@license, @name, @time, @reason)',
        {
            ['@license'] = license,
            ['@name']    = targetName,
            ['@time']    = seconds,
            ['@reason']  = reasonTx
        }, function()
            -- ใช้ src/target ที่เก็บไว้ ไม่ใช่ source — ตรงนี้อยู่หลัง yield ของ MySQL แล้ว
            TriggerClientEvent("pNotify:SendNotification", src, {
                text = "<b style='color:green'>บล๊อคการสื่อสาร </b> <b style='color:white'>: " ..
                    targetName .. " เวลา " .. seconds .. " วินาทีแล้ว</b>",
                type = "success",
                timeout = 5000,
                layout = "topRight",
                queue = "left"
            })
            TriggerClientEvent("pNotify:SendNotification", target, {
                text = "<b style='color:red'>คุณถูกบล๊อคการสื่อสารข้อหา </b> <b style='color:white'>: " ..
                    reasonTx .. " เป็นเวลา " .. seconds .. " วินาที</b>",
                type = "error",
                timeout = 8000,
                layout = "topRight",
                queue = "left"
            })
            TriggerClientEvent('admin:SetTimeBlockMic', target, seconds)
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

-- ปลดบล็อกไมค์
--
-- มีผู้เรียก 2 ทางที่ต่างกันโดยสิ้นเชิง (client/client.lua:456 กับ :1150):
--   1) แอดมินกดปลดให้คนอื่น        -> ต้องมีสิทธิ์
--   2) นับถอยหลังครบแล้วปลดตัวเอง  -> ยิงมาพร้อม server id ของตัวเอง ต้องผ่านโดยไม่ต้องมีสิทธิ์
-- ถ้าใส่ด่านสิทธิ์แบบเหมารวม ทางที่ 2 จะพังและคนโดนบล็อกจะติดค้างตลอดไป
--
-- ของเดิมใช้ Sildurs + เมธอด ESX เหมือน blockMic จึง throw ทุกครั้ง — ประกอบกับที่ blockMic
-- ไม่เคยเขียน DB สำเร็จ ระบบนี้จึงตายทั้งวงจร ไม่มีใครเคยโดนบล็อกและไม่มีใครเคยปลดได้
RegisterServerEvent('admin:enableMic')
AddEventHandler('admin:enableMic', function(playerId)
    local src = source

    playerId = tonumber(playerId)
    if not playerId then return end

    if playerId ~= src then
        local playerGroup = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(src) or 'user'
        if not (Config["Perms"][playerGroup] and Config["Perms"][playerGroup].CanKick) then return end
    end

    if not GetPlayerName(playerId) then return end

    local targetUser = VORPcore.getUser(playerId)
    if not targetUser then return end
    local xTarget = targetUser.getUsedCharacter
    if not xTarget then return end

    MySQL.Async.execute('DELETE FROM ban_mic WHERE license = @license', {
        ['@license'] = xTarget.identifier
    }, function()
        TriggerClientEvent('admin:SetTimeBlockMic', playerId, 0)
        TriggerClientEvent("pNotify:SendNotification", playerId, {
            text = '<strong class="green-text">การสื่อสารของคุณใช้งานได้ปกติแล้ว</strong>',
            type = "success",
            timeout = 5000,
            layout = "topRight",
            queue = "left"
        })
        TriggerClientEvent('admin:ShowTextBlockMic', -1, 0, playerId)
    end)
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


-- ═══════════════════════════════════════════════════════════════════════════
--  เวลา & สภาพอากาศ — สั่งผ่าน weathersync เท่านั้น
--
--  ห้ามใช้ native (NetworkOverrideClockTime / SetWeatherType) ตรงๆ เด็ดขาด:
--  weathersync มีลูป broadcast เวลา/อากาศให้ทุก client ทุก 5 วินาที (Config.syncDelay)
--  ถ้าเราไปตั้งเองด้วย native มันจะโดนเขียนทับหายภายใน 5 วิ ดูเหมือนคำสั่งไม่ทำงาน
--
--  client callback (setTime/changeWeather/freezeTime/freezeWeather) มีอยู่ใน
--  client/client.lua ตั้งแต่แรกแล้ว แต่ไม่เคยมี handler ฝั่ง server มารับ — นี่คือส่วนที่ขาดไป
-- ═══════════════════════════════════════════════════════════════════════════

-- ชื่ออากาศที่ RDR2 รองรับจริง (weathersync/shared.lua : RDR2WeatherTypes)
-- setWeather() ของ weathersync ไม่ validate ให้ ถ้าส่งชื่อมั่วเข้าไปอากาศจะเพี้ยนทั้งเซิร์ฟ
-- เราจึงต้องกรองเองที่นี่ก่อนส่งต่อเสมอ
local VALID_WEATHER = {
    blizzard = true, clouds = true, drizzle = true, fog = true,
    groundblizzard = true, hail = true, highpressure = true, hurricane = true,
    misty = true, overcast = true, overcastdark = true, rain = true,
    sandstorm = true, shower = true, sleet = true, snow = true,
    snowlight = true, sunny = true, thunder = true, thunderstorm = true,
    whiteout = true,
}

-- weathersync ไม่มีฟังก์ชัน freeze แยก ต้องส่ง freeze ไปพร้อม setTime/setWeather
-- จึงต้องจำสถานะไว้เองว่าตอนนี้ล็อกอยู่ไหม (weathersync เก็บใน local ของมัน อ่านจากนอกไม่ได้)
local timeFrozen    = false
local weatherFrozen = false

local function notify(src, text, kind)
    TriggerClientEvent("pNotify:SendNotification", src, {
        text = text, type = kind or "success", timeout = 4000, layout = "topRight",
    })
end

local function canDo(src, flag)
    local group = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(src) or 'user'
    return Config["Perms"][group] and Config["Perms"][group][flag]
end

-- pcall กัน: ถ้า weathersync ไม่ได้ ensure อยู่ exports จะ error แล้วพา handler ตายทั้งตัว
local function wsync(fn, ...)
    local ok, err = pcall(function(...) return exports.weathersync[fn](exports.weathersync, ...) end, ...)
    if not ok then
        print(("^1[MJ-Admin]^7 เรียก weathersync:%s ไม่สำเร็จ: %s (ensure weathersync อยู่ไหม?)"):format(fn, tostring(err)))
    end
    return ok
end

-- ตั้งเวลา — client ส่งมาเป็นสตริง "HH:MM" จาก input type="time"
RegisterNetEvent("admin:Time")
AddEventHandler("admin:Time", function(input)
    local src = source
    if not canDo(src, 'CanSetTime') then return end

    local hh, mm = tostring(input or ''):match('^(%d%d?):(%d%d)$')
    hh, mm = tonumber(hh), tonumber(mm)
    if not hh or not mm or hh > 23 or mm > 59 then
        notify(src, "รูปแบบเวลาไม่ถูกต้อง ต้องเป็น HH:MM เช่น 18:30", "error")
        return
    end

    -- คงวันเดิมไว้ เปลี่ยนแค่เวลา (weathersync นับ day 0=อาทิตย์..6=เสาร์)
    local day = 0
    local ok, cur = pcall(function() return exports.weathersync:getTime() end)
    if ok and type(cur) == 'table' and cur.day then day = cur.day end

    if wsync('setTime', day, hh, mm, 0, 5000, timeFrozen) then
        notify(src, ("ตั้งเวลาเป็น %02d:%02d แล้ว"):format(hh, mm))
        print(("^3[MJ-Admin]^7 %s ตั้งเวลาเซิร์ฟเวอร์เป็น %02d:%02d"):format(GetPlayerName(src) or src, hh, mm))
    end
end)

RegisterNetEvent("admin:freezeTime")
AddEventHandler("admin:freezeTime", function()
    local src = source
    if not canDo(src, 'CanFreezeTime') then return end

    timeFrozen = not timeFrozen

    local t = { day = 0, hour = 12, minute = 0, second = 0 }
    local ok, cur = pcall(function() return exports.weathersync:getTime() end)
    if ok and type(cur) == 'table' then t = cur end

    -- ส่งเวลาปัจจุบันกลับไปพร้อมธง freeze — transition 0 เพื่อไม่ให้เวลากระโดดตอนสลับโหมด
    if wsync('setTime', t.day or 0, t.hour or 12, t.minute or 0, t.second or 0, 0, timeFrozen) then
        notify(src, timeFrozen and "หยุดเวลาแล้ว" or "ปล่อยเวลาเดินต่อแล้ว")
        print(("^3[MJ-Admin]^7 %s %s"):format(GetPlayerName(src) or src, timeFrozen and "หยุดเวลา" or "ปล่อยเวลาเดิน"))
    end
end)

-- เปลี่ยนอากาศ
RegisterNetEvent("admin:Weather")
AddEventHandler("admin:Weather", function(weather)
    local src = source
    if not canDo(src, 'CanChangeWeather') then return end

    weather = tostring(weather or ''):lower()
    if not VALID_WEATHER[weather] then
        notify(src, "ไม่รู้จักสภาพอากาศนี้", "error")
        return
    end

    -- freeze = true เสมอตอนแอดมินเลือกเอง ไม่งั้นลูป forecast ของ weathersync
    -- จะหมุนอากาศเปลี่ยนไปเองภายใน 1 ชั่วโมงในเกม (แอดมินสั่งแล้วอยู่ไม่ทน)
    weatherFrozen = true
    if wsync('setWeather', weather, 10.0, true, false) then
        notify(src, "เปลี่ยนสภาพอากาศเป็น " .. weather .. " แล้ว (ล็อกไว้)")
        print(("^3[MJ-Admin]^7 %s เปลี่ยนอากาศเป็น %s"):format(GetPlayerName(src) or src, weather))
    end
end)

-- ปลดล็อก = คืนให้ weathersync คุมเองตามพยากรณ์
RegisterNetEvent("admin:freezeWeather")
AddEventHandler("admin:freezeWeather", function()
    local src = source
    if not canDo(src, 'CanFreezeWeather') then return end

    weatherFrozen = not weatherFrozen

    if weatherFrozen then
        local cur = 'sunny'
        local ok, w = pcall(function() return exports.weathersync:getWeather() end)
        if ok and type(w) == 'string' and VALID_WEATHER[w] then cur = w end
        if wsync('setWeather', cur, 0.0, true, false) then
            notify(src, "ล็อกสภาพอากาศไว้ที่ " .. cur .. " แล้ว")
        end
    else
        if wsync('resetWeather') then
            notify(src, "ปลดล็อกอากาศแล้ว — กลับไปเปลี่ยนเองตามพยากรณ์")
        end
    end
    print(("^3[MJ-Admin]^7 %s %s"):format(GetPlayerName(src) or src, weatherFrozen and "ล็อกอากาศ" or "ปลดล็อกอากาศ"))
end)

-- คืนค่าเวลา+อากาศกลับเป็นอัตโนมัติทั้งคู่
RegisterNetEvent("admin:ResetWeatherTime")
AddEventHandler("admin:ResetWeatherTime", function()
    local src = source
    if not canDo(src, 'CanChangeWeather') then return end
    timeFrozen, weatherFrozen = false, false
    wsync('resetWeather')
    wsync('resetTime')
    notify(src, "คืนค่าเวลาและอากาศเป็นอัตโนมัติแล้ว")
    print(("^3[MJ-Admin]^7 %s คืนค่าเวลา/อากาศเป็นอัตโนมัติ"):format(GetPlayerName(src) or src))
end)


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

-- ═══════════════════════════════════════════════════════════════════════════
--  เปิดกระเป๋าผู้เล่น (ปุ่ม "เปิดกระเป๋า" ในเมนูแอดมิน)
--
--  เดิม client เรียก TriggerEvent("vorp_inventory:OpenstealInventory", ...) ตรงๆ ฝั่ง client
--  ซึ่ง "เปิดหน้าต่างเปล่า" อย่างเดียว ไม่มีขั้นตอนส่งรายการของเข้าไป จึงเห็นกระเป๋าว่างตลอด
--
--  ของจริงต้องทำ 3 อย่างเหมือนที่ MJ-LootPlayer ทำ (server/server.lua:55-108):
--    1. ตั้ง state DataSteal ให้ผู้สั่ง — syn_search:MoveTosteal/TakeFromsteal อ่านตัวนี้
--       เพื่อรู้ว่ากำลังยุ่งกับกระเป๋าของใคร ถ้าไม่ตั้งจะหยิบ/ใส่ของไม่ได้เลย
--    2. เปิดหน้าต่างด้วย OpenstealInventory
--    3. ยิงรายการของ (ไอเทม + อาวุธ + เงิน) ตามด้วย ReloadstealInventory
-- ═══════════════════════════════════════════════════════════════════════════
RegisterNetEvent('admin:OpenPlayerInventory')
AddEventHandler('admin:OpenPlayerInventory', function(targetId)
    local src = source

    local group = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(src) or 'user'
    if not (Config["Perms"][group] and Config["Perms"][group].CanOpenPlayerInventory) then return end

    targetId = tonumber(targetId)
    if not targetId then return end

    local tUser = VORPcore.getUser(targetId)
    local tChar = tUser and tUser.getUsedCharacter
    if not tChar then
        TriggerClientEvent("pNotify:SendNotification", src, {
            text = "หาผู้เล่นคนนี้ไม่เจอ", type = "error", timeout = 4000, layout = "topRight" })
        return
    end

    -- 1) DataSteal — โครงสร้างต้องมีคีย์ source เพราะ MoveTosteal อ่าน state.DataSteal.source
    Player(src).state:set('DataSteal', { source = targetId }, true)

    -- 2) เปิดหน้าต่าง (charIdentifier เป็น stealId เหมือน MJ-LootPlayer)
    TriggerClientEvent('vorp_inventory:OpenstealInventory', src,
        ('กระเป๋า: %s %s (ID %d)'):format(tChar.firstname or '', tChar.lastname or '', targetId),
        tChar.charIdentifier)

    -- 3) รวบรวมของแล้วส่งเข้าไป
    local inventory = {}

    exports.vorp_inventory:getUserInventoryItems(targetId, function(items)
        for _, v in pairs(items or {}) do
            table.insert(inventory, v)
        end

        exports.vorp_inventory:getUserInventoryWeapons(targetId, function(weapons)
            for _, v in pairs(weapons or {}) do
                v.count = 1
                v.limit = 1
                v.type  = 'item_weapon'
                table.insert(inventory, v)
            end

            -- เงินสดเป็นรายการหลอกให้เห็นยอด (แถวนี้ MJ-LootPlayer ก็ใส่เหมือนกัน)
            table.insert(inventory, {
                id = 1, group = 1, label = 'เงิน', type = 'item_money', name = 'money',
                count = tChar.money, limit = tChar.money, weight = 0,
                metadata = {}, desc = 'เงินสด', canUse = false,
            })

            TriggerClientEvent('vorp_inventory:ReloadstealInventory', src, json.encode({
                itemList = inventory,
                action   = 'setSecondInventoryItems',
            }))
        end)
    end)

    print(('^3[MJ-Admin]^7 %s เปิดกระเป๋าของ %s %s (id %d)')
        :format(GetPlayerName(src) or src, tChar.firstname or '', tChar.lastname or '', targetId))
end)

-- ── หยิบ/ใส่ของในกระเป๋าผู้เล่น ────────────────────────────────────────────────
-- syn_search:MoveTosteal   = ลากของ "จากกระเป๋าแอดมิน" ไปใส่ให้ผู้เล่น
-- syn_search:TakeFromsteal = ลากของ "จากกระเป๋าผู้เล่น" มาเข้าแอดมิน
--
-- ปกติ 2 event นี้เป็นของ MJ-LootPlayer/MJ-Police แต่ทั้งคู่ถูกปิดใน MJDEV.cfg
-- (คอมเมนต์ ensure ไว้) จึงไม่มี handler อยู่เลยทั้งเซิร์ฟ = เห็นของแต่หยิบไม่ได้
--
-- ต่างจากของ MJ-LootPlayer ตรงที่ไม่มี ItemsBlackList และไม่มี CheckLimit —
-- นั่นเป็นกติกาของ "การปล้น" ไม่ใช่ของแอดมิน แต่ใส่การเช็คสิทธิ์แทนทุกครั้ง
-- (state DataSteal อย่างเดียวไม่พอ ผู้เล่นทั่วไปยิง event นี้เองได้)

local function adminStealGuard(src)
    local group = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(src) or 'user'
    if not (Config["Perms"][group] and Config["Perms"][group].CanOpenPlayerInventory) then
        return nil
    end
    local st = Player(src).state.DataSteal
    return st and st.source or nil
end

-- ยิงรายการของใหม่หลังย้ายเสร็จ ทั้งสองฝั่งจะได้เห็นตรงกัน
local function reloadStealView(adminSrc, targetId)
    local tChar = VORPcore.getUser(targetId)
    tChar = tChar and tChar.getUsedCharacter
    if not tChar then return end

    local inventory = {}
    exports.vorp_inventory:getUserInventoryItems(targetId, function(items)
        for _, v in pairs(items or {}) do table.insert(inventory, v) end
        exports.vorp_inventory:getUserInventoryWeapons(targetId, function(weapons)
            for _, v in pairs(weapons or {}) do
                v.count, v.limit, v.type = 1, 1, 'item_weapon'
                table.insert(inventory, v)
            end
            table.insert(inventory, {
                id = 1, group = 1, label = 'เงิน', type = 'item_money', name = 'money',
                count = tChar.money, limit = tChar.money, weight = 0,
                metadata = {}, desc = 'เงินสด', canUse = false,
            })
            TriggerClientEvent('vorp_inventory:ReloadstealInventory', adminSrc, json.encode({
                itemList = inventory, action = 'setSecondInventoryItems',
            }))
        end)
    end)
end

RegisterNetEvent('syn_search:MoveTosteal')
AddEventHandler('syn_search:MoveTosteal', function(obj)
    local src = source
    local targetId = adminStealGuard(src)
    if not targetId then return end

    local data = json.decode(obj)
    if type(data) ~= 'table' or type(data.item) ~= 'table' then return end
    data.number = tonumber(data.number)
    if not data.number or data.number <= 0 then return end
    if data.number > (tonumber(data.item.count) or 0) then return end

    local aChar = VORPcore.getUser(src); aChar = aChar and aChar.getUsedCharacter
    local tChar = VORPcore.getUser(targetId); tChar = tChar and tChar.getUsedCharacter
    if not aChar or not tChar then return end

    if data.type == 'item_standard' then
        if not (exports.vorp_inventory:canCarryItems(targetId, data.number)
            and exports.vorp_inventory:canCarryItem(targetId, data.item.name, data.number)) then
            TriggerClientEvent("pNotify:SendNotification", src, {
                text = "กระเป๋าผู้เล่นเต็ม", type = "error", timeout = 4000, layout = "topRight" })
            return
        end
        exports.vorp_inventory:subItem(src, data.item.name, data.number, data.item.metadata)
        exports.vorp_inventory:addItem(targetId, data.item.name, data.number, data.item.metadata)
        print(('^3[MJ-Admin]^7 %s ใส่ %s x%d ให้ %s'):format(
            GetPlayerName(src) or src, data.item.label or data.item.name, data.number, GetPlayerName(targetId) or targetId))

    elseif data.type == 'item_money' then
        aChar.removeCurrency(0, data.number)
        tChar.addCurrency(0, data.number)
        print(('^3[MJ-Admin]^7 %s ให้เงิน %d กับ %s'):format(
            GetPlayerName(src) or src, data.number, GetPlayerName(targetId) or targetId))

    elseif data.type == 'item_weapon' then
        if not exports.vorp_inventory:canCarryWeapons(targetId, 1) then
            TriggerClientEvent("pNotify:SendNotification", src, {
                text = "ผู้เล่นถืออาวุธเต็มแล้ว", type = "error", timeout = 4000, layout = "topRight" })
            return
        end
        exports.vorp_inventory:giveWeapon(targetId, data.item.id, src)
        print(('^3[MJ-Admin]^7 %s ให้อาวุธ %s กับ %s'):format(
            GetPlayerName(src) or src, data.item.label or '?', GetPlayerName(targetId) or targetId))
    else
        return
    end

    Wait(100)
    reloadStealView(src, targetId)
end)

RegisterNetEvent('syn_search:TakeFromsteal')
AddEventHandler('syn_search:TakeFromsteal', function(obj)
    local src = source
    local targetId = adminStealGuard(src)
    if not targetId then return end

    local data = json.decode(obj)
    if type(data) ~= 'table' or type(data.item) ~= 'table' then return end
    data.number = tonumber(data.number)
    if not data.number or data.number <= 0 then return end
    if data.number > (tonumber(data.item.count) or 0) then return end

    local aChar = VORPcore.getUser(src); aChar = aChar and aChar.getUsedCharacter
    local tChar = VORPcore.getUser(targetId); tChar = tChar and tChar.getUsedCharacter
    if not aChar or not tChar then return end

    if data.type == 'item_standard' then
        if not (exports.vorp_inventory:canCarryItems(src, data.number)
            and exports.vorp_inventory:canCarryItem(src, data.item.name, data.number)) then
            TriggerClientEvent("pNotify:SendNotification", src, {
                text = "กระเป๋าคุณเต็ม", type = "error", timeout = 4000, layout = "topRight" })
            return
        end
        exports.vorp_inventory:subItem(targetId, data.item.name, data.number, data.item.metadata)
        exports.vorp_inventory:addItem(src, data.item.name, data.number, data.item.metadata)
        print(('^3[MJ-Admin]^7 %s เอา %s x%d จาก %s'):format(
            GetPlayerName(src) or src, data.item.label or data.item.name, data.number, GetPlayerName(targetId) or targetId))

    elseif data.type == 'item_money' then
        tChar.removeCurrency(0, data.number)
        aChar.addCurrency(0, data.number)
        print(('^3[MJ-Admin]^7 %s เอาเงิน %d จาก %s'):format(
            GetPlayerName(src) or src, data.number, GetPlayerName(targetId) or targetId))

    elseif data.type == 'item_weapon' then
        if not exports.vorp_inventory:canCarryWeapons(src, 1) then
            TriggerClientEvent("pNotify:SendNotification", src, {
                text = "คุณถืออาวุธเต็มแล้ว", type = "error", timeout = 4000, layout = "topRight" })
            return
        end
        exports.vorp_inventory:giveWeapon(src, data.item.id, targetId)
        print(('^3[MJ-Admin]^7 %s เอาอาวุธ %s จาก %s'):format(
            GetPlayerName(src) or src, data.item.label or '?', GetPlayerName(targetId) or targetId))
    else
        return
    end

    Wait(100)
    reloadStealView(src, targetId)
end)

-- ปิดหน้าต่างแล้วล้าง DataSteal ทิ้ง ไม่งั้นค่าค้างไว้ แล้วแอดมินไปเปิดกระเป๋าตัวเอง
-- หรือตู้อื่นทีหลัง การลากของอาจไปโผล่ที่ผู้เล่นคนเดิมโดยไม่ตั้งใจ
RegisterNetEvent('admin:ClosePlayerInventory')
AddEventHandler('admin:ClosePlayerInventory', function()
    Player(source).state:set('DataSteal', nil, true)
end)
