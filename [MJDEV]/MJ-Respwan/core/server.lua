local Core = exports.vorp_core:GetCore()
local Inv = exports.vorp_inventory

-- ใช้แปลง hash เป็นชื่ออาวุธ/สาเหตุ
local function GetWeaponNameFromHash(hash)
    local weaponNames = {
        -- ปืนสั้น
        [`WEAPON_REVOLVER_CATTLEMAN`]         = "ปืนลูกโม่ Cattleman",
        [`WEAPON_REVOLVER_SCHOFIELD`]         = "ปืนลูกโม่ Schofield",
        [`WEAPON_REVOLVER_LEMAT`]             = "ปืนลูกโม่ LeMat",
        [`WEAPON_PISTOL_MAUSER`]              = "ปืนพก Mauser",
        [`WEAPON_PISTOL_VOLCANIC`]            = "ปืนพก Volcanic",

        -- ปืนยาว
        [`WEAPON_REPEATER_CARBINE`]           = "ปืน Repeater Carbine",
        [`WEAPON_REPEATER_HENRY`]             = "ปืน Repeater Henry",
        [`WEAPON_REPEATER_WINCHESTER`]        = "ปืน Repeater Winchester",
        [`WEAPON_RIFLE_SPRINGFIELD`]          = "ไรเฟิล Springfield",
        [`WEAPON_RIFLE_BOLTACTION`]           = "ไรเฟิล Bolt-Action",

        -- ปืนลูกซอง
        [`WEAPON_SHOTGUN_DOUBLEBARREL`]       = "ลูกซองสองลำกล้อง",
        [`WEAPON_SHOTGUN_SAWEDOFF`]           = "ลูกซองตัด",
        [`WEAPON_SHOTGUN_PUMP`]               = "ลูกซองปั๊ม",
        [`WEAPON_SHOTGUN_SEMIAUTO`]           = "ลูกซองกึ่งอัตโนมัติ",

        -- ธนู / ระเบิด
        [`WEAPON_BOW`]                        = "ธนู",
        [`WEAPON_THROWN_DYNAMITE`]            = "ไดนาไมต์",
        [`WEAPON_THROWN_THROWING_KNIVES`]     = "มีดปา",
        [`WEAPON_THROWN_TOMAHAWK`]            = "ขวาน Tomahawk",

        -- อื่นๆ
        [`WEAPON_MELEE_KNIFE`]                = "มีด",
        [`WEAPON_MELEE_HATCHET`]              = "ขวาน",
        [`WEAPON_MELEE_LANTERN`]              = "โคมไฟ",
        [`WEAPON_MELEE_LASSO`]                = "บ่วงเชือก",
        [`WEAPON_UNARMED`]                    = "หมัดเปล่า",
    }

    return weaponNames[hash] or string.format("อาวุธไม่ทราบ (hash: %s)", tostring(hash))
end

local function sendDeathLogToDiscord(playerId, coords, cause, killerId, imageUrl)
    local playerName = GetPlayerName(playerId)
    local killerName = killerId ~= 0 and GetPlayerName(killerId) or "ไม่มีข้อมูล"
    local location = string.format("X: %.2f, Y: %.2f, Z: %.2f", coords.x, coords.y, coords.z)
    local weapon = string.upper(GetWeaponNameFromHash(cause))

    local description = string.format("**%s** ตายด้วยอาวุธ `%s` โดย **%s**\n**พิกัด:** %s", playerName, weapon, killerName, location)

    local embed = {
        title = "🩸 ผู้เล่นเสียชีวิต",
        description = description,
        color = 15158332,
        footer = { text = os.date("📅 %d/%m/%Y 🕒 %H:%M:%S") }
    }

    if imageUrl then
        embed.image = { url = imageUrl }
    end

    PerformHttpRequest(Config.DISCORD_WEBHOOK, function(err, text, headers) end, "POST", json.encode({
        username = "💀 MJ Death Logs",
        embeds = { embed }
    }), { ["Content-Type"] = "application/json" })
    -- เรียก Client ถ่ายภาพหน้าจอส่ง Discord
end

-- ใช้สำหรับ log แบบง่าย (หัวข้อ/ข้อความ/สี) ต่างจาก sendDeathLogToDiscord ที่ต้องใช้พิกัด+อาวุธ+killer จริง
local function sendSimpleDiscordLog(title, description, color)
    local embed = {
        title = title,
        description = description,
        color = color,
        footer = { text = os.date("📅 %d/%m/%Y 🕒 %H:%M:%S") }
    }

    PerformHttpRequest(Config.DISCORD_WEBHOOK, function(err, text, headers) end, "POST", json.encode({
        username = "💀 MJ Death Logs",
        embeds = { embed }
    }), { ["Content-Type"] = "application/json" })
end

local function getClosestPlayer(source)
    local players<const> = GetPlayers()
    local ent<const> = GetPlayerPed(source)
    local doctorCoords<const> = GetEntityCoords(ent)

    for _, value in ipairs(players) do
        if tonumber(value) ~= source then
            local targetCoords<const> = GetEntityCoords(GetPlayerPed(value))
            local distance<const> = #(doctorCoords - targetCoords)
            if distance <= 3.0 then
                return value
            end
        end
    end
    return nil
end

-- กันกดใช้ยารัวๆ: server หัก item + ฟื้นเลือดทันทีก่อน client จะเล่น progressbar เสร็จ (progressbar
-- ฝั่ง client บล็อกแค่ "แถบ" ซ้อน แต่ไม่บล็อกการ "หัก item + heal" ที่ทำ server-side ไปแล้ว) — spam
-- คลิกเลยกินยาหมดสต็อกทั้งที่เห็นแถบเดียว บล็อกที่ต้นทาง (registerUsableItem) ด้วย cooldown ต่อคน
-- เท่ากับ duration ของท่านั้น (heal 5000 / quick 4000 / revive ~10000) กันไม่ให้ใช้ซ้ำระหว่างท่ายังเล่นอยู่
local healCooldown = {} -- [src] = GetGameTimer() ที่ใช้ยาได้อีกครั้ง

AddEventHandler('playerDropped', function()
    if source then healCooldown[source] = nil end
end)

CreateThread(function()
    for key, value in pairs(Config.Items) do
        Inv:registerUsableItem(key, function(data)
            local _source <const> = data.source

            local now = GetGameTimer()
            if healCooldown[_source] and now < healCooldown[_source] then
                return -- ยังติด cooldown จากการใช้ครั้งก่อน — ไม่หัก item ไม่ heal ไม่เล่นท่าซ้ำ
            end
            local animDef = Config.Animations[value.category]
            local cd = value.revive and 10000 or ((animDef and animDef.duration) or 5000)
            healCooldown[_source] = now + cd

            Inv:closeInventory(_source)

            local user = Core.getUser(_source).getUsedCharacter
            local name = user.firstname .. ' ' .. user.lastname

            if value.revive then
                local closestPlayer <const> = getClosestPlayer(_source)
                if not closestPlayer then return end

                local targetUser = Core.getUser(closestPlayer).getUsedCharacter
                local targetName = targetUser.firstname .. ' ' .. targetUser.lastname

                sendSimpleDiscordLog("💉 Revive Item Used", string.format(
                    "**%s** ใช้ไอเท็ม `%s` เพื่อชุบชีวิต **%s**",
                    name, key, targetName), 3066993)

                TriggerClientEvent("MJ-ReSpwan:Client:ReviveAnim", _source)
                SetTimeout(10000, function()
                    Core.Player.Revive(tonumber(closestPlayer))
                    -- ข้ามสถานะ "บาดเจ็บ"/cooldown ของ MJ-Cooldown ให้เลย เหมือนตอนแอดมินชุบ
                    -- (ไม่งั้น MJ-Cooldown จะจับ dead->alive แล้วบังคับ cooldown ต่อทันทีที่ฟื้น)
                    TriggerClientEvent('MJ-Cooldown:Stopinjured', tonumber(closestPlayer))
                    -- 🔔 แจ้ง log ฝั่ง server พร้อมเหตุผล
                    TriggerServerEvent("mj:discordReviveLog", closestPlayer, string.format("ถูกชุบชีวิตโดย %s ด้วยไอเท็ม `%s`", name, key))
                end)
            else
                sendSimpleDiscordLog("🩹 Heal Item Used", string.format(
                    "**%s** ใช้ไอเท็ม `%s` เพื่อฟื้นฟูเลือด/สตามิน่า",
                    name, key), 3447003)

                -- แนบชื่อ item จริง (key) ไปด้วย ให้ progress bar โชว์รูปไอเทมที่ใช้จริง (ดึงจาก
                -- nui://vorp_inventory/html/img/items/<key>.png — ต้องมีไฟล์รูปชื่อตรงกับ item ใน DB)
                TriggerClientEvent("MJ-ReSpwan:Client:HealAnim", _source, value.category, key)
                TriggerClientEvent("MJ-ReSpwan:Client:HealPlayer", _source, value.health, value.stamina)
            end

            Inv:subItemById(_source, data.item.id)
        end)
    end
end)


RegisterCommand("revive", function(source, args)
    local adminUser = Core.getUser(source).getUsedCharacter
    local playerGroup = adminUser.group
    if playerGroup == "admin" then
        local targetId = tonumber(args[1])
        if targetId then
            Core.Player.Revive(targetId)
            local targetName = GetPlayerName(targetId)
            sendSimpleDiscordLog("⚡ Admin Revive",
                string.format("แอดมิน **%s** ทำการชุบชีวิตผู้เล่น **%s**", GetPlayerName(source), targetName),
                15158332)
        end
    end
end)

RegisterServerEvent("mj:checkAdminPermission")
AddEventHandler("mj:checkAdminPermission", function()
    local _source = source
    local User = Core.getUser(_source).getUsedCharacter
    local group = User.group -- For example: "user", "mod", "admin", etc.

    local isAdmin = (group == "admin" or group == "mod") -- you can customize
    TriggerClientEvent("mj:returnAdminPermission", _source, isAdmin)
end)

RegisterServerEvent("mj:discordDeathLog")
AddEventHandler("mj:discordDeathLog", function(coords, cause, killerId, imageUrl)
    local src = source
    sendDeathLogToDiscord(src, coords, cause, killerId, imageUrl)
end)

RegisterServerEvent("mj:discordReviveLog")
AddEventHandler("mj:discordReviveLog", function(targetId, reason)
    local targetName = GetPlayerName(targetId)
    local coords = GetEntityCoords(GetPlayerPed(targetId))

    local message = string.format(
        "**%s** ฟื้นขึ้นมาแล้ว!\n**เหตุผล:** %s\n**ตำแหน่ง:** [%.2f, %.2f, %.2f]",
        targetName, reason, coords.x, coords.y, coords.z)

    local embed = {
        {
            ["color"] = 15844367, -- สีทอง
            ["title"] = "🧬 ผู้เล่นฟื้นคืนชีพ",
            ["description"] = message,
            ["footer"] = { ["text"] = "MJ Death System • Revive Log" },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    PerformHttpRequest(Config.DISCORD_WEBHOOK, function(err, text, headers) end, 'POST', json.encode({
        username = "Revive Logs",
        embeds = embed,
        avatar_url = "https://i.imgur.com/jW2lPjX.png"
    }), { ['Content-Type'] = 'application/json' })

    -- เรียก Client ถ่ายภาพหน้าจอส่ง Discord
    TriggerClientEvent("mj:deathScreenshot", targetId, Config.DISCORD_WEBHOOK, message)
end)

RegisterServerEvent("mj:handleScreenshotWithReason")
AddEventHandler("mj:handleScreenshotWithReason", function(imageUrl, reasonText)
    local src = source
    local coords = GetEntityCoords(GetPlayerPed(src))

    local embed = {
        {
            ["color"] = 15844367,
            ["title"] = "📸 ภาพขณะฟื้นคืนชีพ",
            ["description"] = reasonText,
            ["image"] = { url = imageUrl },
            ["footer"] = { text = "MJ Death System • Screenshot" },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    PerformHttpRequest(Config.DISCORD_WEBHOOK, function(err, text, headers) end, 'POST', json.encode({
        username = "Revive Screenshot",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end)
