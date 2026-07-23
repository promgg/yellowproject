local Core = exports.vorp_core:GetCore()
local Inv = exports.vorp_inventory

-- ดึง character ของผู้เล่นแบบปลอดภัย — Core.getUser คืน nil ได้ถ้า src ไม่ valid/ยังไม่โหลด
-- (ป้องกัน crash จาก Core.getUser(src).getUsedCharacter ตรงๆ)
local function getChar(src)
    local user = Core.getUser(src)
    if not user then return nil end
    return user.getUsedCharacter
end

-- แจ้งเตือนผู้เล่นผ่าน pNotify (server -> client)
local function NotifyClient(src, text, ntype, timeout)
    TriggerClientEvent('pNotify:SendNotification', src, {
        type = ntype or 'info',
        text = text,
        timeout = timeout or 3000,
    })
end

-- เช็คว่า group เป็นระดับแอดมินไหม — normalize (lower+trim) ก่อนเทียบ เพราะค่าจริงอาจมี casing/whitespace
-- ไม่ตรงกับ "admin" เป๊ะๆ (เช่น "Admin") แล้วรับหลายชื่อกลุ่มที่ใช้จริงในโปรเจกต์นี้ (ดู
-- lp_deathmatch/server/config_server.lua: adminGroups = {'admin','superadmin'})
local ADMIN_GROUPS = { admin = true, superadmin = true, mod = true }
local function isAdminGroup(rawGroup)
    if type(rawGroup) ~= 'string' then return false end
    local normalized = rawGroup:lower():gsub('^%s+', ''):gsub('%s+$', '')
    return ADMIN_GROUPS[normalized] == true
end

-- เช็คสิทธิ์แอดมินของ source — เดิม MJ-Respwan เช็คแค่ character.group (ของตัวละครที่กำลังเล่นอยู่)
-- แต่คำสั่ง /heal ของ vorp_core เอง (ที่ทดสอบแล้วใช้งานได้จริง) เช็คจาก Core.getUser(src).getGroup ซึ่ง
-- เป็น group ระดับ "user/account" คนละตัวกับ character.group (vorp_core/server/commands.lua:78) —
-- บัญชีอาจตั้ง group เป็น admin ไว้ที่ระดับ user แต่ character ปัจจุบันไม่มี/ไม่ตรง ทำให้ /heal ผ่านแต่
-- /revive (เช็คแค่ character.group) ไม่ผ่าน ตรงกับอาการที่เจอเป๊ะ — เช็คทั้งสองระดับ ผ่านอันใดอันหนึ่งพอ
local function isSourceAdmin(src)
    local user = Core.getUser(src)
    if not user then return false end

    if isAdminGroup(user.getGroup) then
        return true
    end

    local character = user.getUsedCharacter
    return isAdminGroup(character and character.group)
end

-- ยิง Discord webhook — ข้ามทันทีถ้ายังไม่ตั้ง webhook (กัน PerformHttpRequest error รัวๆ)
local function postDiscord(payload)
    if not Config.DISCORD_WEBHOOK or Config.DISCORD_WEBHOOK == '' then return end
    PerformHttpRequest(Config.DISCORD_WEBHOOK, function(err, text, headers) end, 'POST',
        json.encode(payload), { ['Content-Type'] = 'application/json' })
end

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

    postDiscord({
        username = "💀 MJ Death Logs",
        embeds = { embed }
    })
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

    postDiscord({
        username = "💀 MJ Death Logs",
        embeds = { embed }
    })
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

-- กันกดใช้ยารัวๆ: server หัก item ทันทีตอนกดใช้ (เลือดขึ้นหลัง progbar จบฝั่ง client) — ถ้าไม่มี
-- cooldown ตรงนี้ spam คลิกจะหัก item รัวๆ หมดสต็อกทั้งที่ท่ายังเล่นไม่จบ บล็อกที่ต้นทาง
-- (registerUsableItem) ด้วย cooldown ต่อคนเท่ากับ duration ของท่านั้น (heal 5000 / quick 4000 /
-- revive ~10000) กันไม่ให้ใช้ซ้ำระหว่างท่ายังเล่นอยู่
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

            local user = getChar(_source)
            if not user then return end
            local name = user.firstname .. ' ' .. user.lastname

            if value.revive then
                local closestPlayer <const> = getClosestPlayer(_source)
                if not closestPlayer then
                    NotifyClient(_source, 'ไม่มีผู้เล่นที่บาดเจ็บอยู่ใกล้คุณ', 'error', 3000)
                    return
                end

                local targetUser = getChar(closestPlayer)
                if not targetUser then return end
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

                -- แนบชื่อ item จริง (key) + ค่าเลือด/สตามิน่า ไปกับ HealAnim เลย (ไม่ยิง HealPlayer แยก
                -- แล้ว) — client จะเซ็ตเลือด "หลัง progbar เล่นจบสมบูรณ์" เท่านั้น ถ้ายกเลิกกลางคัน = ไม่ได้
                -- เลือด แต่ item ยังถูกหักไปแล้วด้านล่าง (จ่ายล่วงหน้า กันดูป/สแปม ไม่เปลี่ยน)
                TriggerClientEvent("MJ-ReSpwan:Client:HealAnim", _source, value.category, key, value.health, value.stamina)
            end

            Inv:subItemById(_source, data.item.id)
        end)
    end
end)


RegisterCommand("revive", function(source, args)
    -- source == 0 = คอนโซล/ txAdmin (เชื่อถือได้ ให้ผ่านเลย) — ผู้เล่นต้องผ่าน isSourceAdmin (เช็คทั้ง
    -- user group และ character group — ดูเหตุผลที่คอมเมนต์ isSourceAdmin ด้านบน)
    local isConsole = (source == 0)

    if isConsole or isSourceAdmin(source) then
        local targetId = tonumber(args[1])
        if not targetId then
            if not isConsole then NotifyClient(source, 'ใช้งาน: revive <player id>', 'error', 3000) end
            return
        end
        Core.Player.Revive(targetId)
        local targetName = GetPlayerName(targetId)
        sendSimpleDiscordLog("⚡ Admin Revive",
            string.format("แอดมิน **%s** ทำการชุบชีวิตผู้เล่น **%s**", GetPlayerName(source), targetName),
            15158332)
    else
        local user = Core.getUser(source)
        local character = user and user.getUsedCharacter
        print(('[MJ-Respwan][revive] ปฏิเสธคำสั่งจาก source=%s (userGroup="%s" characterGroup="%s") — ไม่เข้าเงื่อนไข admin/superadmin/mod')
            :format(tostring(source), tostring(user and user.getGroup), tostring(character and character.group)))
        NotifyClient(source, 'คุณไม่มีสิทธิ์ใช้คำสั่งนี้', 'error', 3000)
    end
end)

RegisterServerEvent("mj:checkAdminPermission")
AddEventHandler("mj:checkAdminPermission", function()
    local _source = source
    TriggerClientEvent("mj:returnAdminPermission", _source, isSourceAdmin(_source))
end)

-- ===== ขอความช่วยเหลือ (CALL FOR HELP) =====
-- client ส่งแค่ trigger — server ใช้พิกัดฝั่ง server เอง (กัน spoof พิกัด) แล้วหาผู้เล่นในรัศมี
local helpCooldownSv = {} -- [src] = GetGameTimer() ที่ขอความช่วยเหลือได้อีกครั้ง
AddEventHandler('playerDropped', function()
    if source then helpCooldownSv[source] = nil end
end)

RegisterServerEvent("MJ-ReSpwan:server:callHelp")
AddEventHandler("MJ-ReSpwan:server:callHelp", function()
    local src = source

    -- rate-limit ฝั่ง server (กัน spam event) ใช้ Config.HelpCooldown เป็นวินาที
    local now = GetGameTimer()
    local cd = (Config.HelpCooldown or 20) * 1000
    if helpCooldownSv[src] and now < helpCooldownSv[src] then
        return
    end
    helpCooldownSv[src] = now + cd

    local srcPed = GetPlayerPed(src)
    if not srcPed or srcPed == 0 then return end
    local srcCoords = GetEntityCoords(srcPed)
    local radius = Config.HelpRadius or 100.0

    for _, pid in ipairs(GetPlayers()) do
        pid = tonumber(pid)
        if pid and pid ~= src then
            local ped = GetPlayerPed(pid)
            if ped and ped ~= 0 then
                local dist = #(srcCoords - GetEntityCoords(ped))
                if dist <= radius then
                    TriggerClientEvent("MJ-ReSpwan:client:helpBlip", pid, srcCoords)
                end
            end
        end
    end
end)

RegisterServerEvent("mj:discordDeathLog")
AddEventHandler("mj:discordDeathLog", function(coords, cause, killerId, imageUrl)
    local src = source
    -- client เป็นคนยิง event นี้ — กัน payload ผิดชนิด (coords ต้องเป็น vector/table ถึงจะ format ได้)
    if type(coords) ~= 'table' and type(coords) ~= 'vector3' then return end
    sendDeathLogToDiscord(src, coords, cause, killerId, imageUrl)
end)

RegisterServerEvent("mj:discordReviveLog")
AddEventHandler("mj:discordReviveLog", function(targetId, reason)
    -- targetId ต้องเป็น server id ที่แปลงเป็นเลขได้ (client adminRevive เดิมยิงมาผิดชนิด = ตกไปตรงนี้)
    targetId = tonumber(targetId)
    if not targetId then return end
    reason = tostring(reason or 'ไม่ระบุ')

    local targetName = GetPlayerName(targetId) or 'ไม่ทราบ'
    local ped = GetPlayerPed(targetId)
    local coords = (ped and ped ~= 0) and GetEntityCoords(ped) or vector3(0.0, 0.0, 0.0)

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

    postDiscord({
        username = "Revive Logs",
        embeds = embed,
        avatar_url = "https://i.imgur.com/jW2lPjX.png"
    })

    -- เรียก Client ถ่ายภาพหน้าจอส่ง Discord
    TriggerClientEvent("mj:deathScreenshot", targetId, Config.DISCORD_WEBHOOK, message)
end)

RegisterServerEvent("mj:handleScreenshotWithReason")
AddEventHandler("mj:handleScreenshotWithReason", function(imageUrl, reasonText)
    local src = source
    -- client ยิง event นี้พร้อม url/ข้อความ — กัน payload ผิดชนิดก่อนโพสต์ลง Discord
    if type(imageUrl) ~= 'string' or type(reasonText) ~= 'string' then return end
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

    postDiscord({
        username = "Revive Screenshot",
        embeds = embed
    })
end)
