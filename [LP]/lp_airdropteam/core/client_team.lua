-- core/client_team.lua
-- lp_airdropteam — จุด NPC เข้าร่วมทีมตาม Config.Team | Revive/teleport | Safe zone wall + countdown
-- native/param สำหรับ ResurrectPed ยืนยันแล้วจากของจริงในโปรเจกต์: vorp_core/client/respawnsystem.lua

local joinedTeamId  = nil -- teamId ที่เข้าร่วมอยู่ตอนนี้ (nil = ยังไม่เข้าร่วม/ออกจากรอบแล้ว)

-- global (ไม่ local) ให้ client.lua เรียกเช็คได้ข้ามไฟล์ในรีซอร์สเดียวกัน — ใช้กันระบบ ZoneLock/DoT
-- เดิมของ MJ-Airdrop (เช็คแค่ระยะห่างจากกล่อง) ลงโทษผู้เล่นที่ออกจากรอบทีมไปแล้วอย่างถูกต้อง
-- (ตายครั้งที่ 2 หรือใช้ /backapt แล้วถูกวาร์ปไปจุดเข้าร่วมที่อยู่ไกลนอก Radius)
function IsPlayerInTeamRound()
    return joinedTeamId ~= nil
end
local zoneSpawnPos  = nil -- vector3 จุดศูนย์กลาง safe zone ของทีมที่เข้าร่วม
local zoneOpened    = false
local spawnedNpcs   = {}
local spawnedBlips  = {}

local function Notify(msg, msgType)
    exports.pNotify:SendNotification({ text = msg, type = msgType or 'info', timeout = 5000 })
end

-- ─── Spawn NPC ที่จุดเข้าร่วมของแต่ละทีม (ถาวร ไม่ผูกกับ bcc-train) ───────────────
local function AddTeamNPC(team)
    local hash = joaat(Config.Team.npc.model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 3000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(0) end
    if not HasModelLoaded(hash) then return end

    local c = team.joinCoords
    local ped = CreatePed(hash, c.x, c.y, c.z - 1.0, c.w or 0.0, false, false, false, false)
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true) -- SetRandomOutfitVariation
    SetEntityCanBeDamaged(ped, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(hash)

    spawnedNpcs[team.id] = ped
end

-- ─── Blip จุดเกิดแต่ละทีม (ถาวรบนแผนที่ ไม่ผูกกับรอบอีเวนต์) ──────────────────────
-- native เดียวกับที่ MJ-Airdrop เดิมใช้จริงสำหรับ blip กล่อง (client.lua: MainBlip)
local function AddTeamBlip(team)
    local c = team.zoneSpawn
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, c.x, c.y, c.z) -- BlipAddForCoords
    SetBlipSprite(blip, Config.Team.blip.sprite)
    SetBlipScale(blip, Config.Team.blip.scale)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, team.label) -- SetBlipName

    spawnedBlips[team.id] = blip
end

CreateThread(function()
    for _, team in ipairs(Config.Team.teams) do
        AddTeamNPC(team)
        AddTeamBlip(team)
    end
end)

-- ─── วาร์ป/ชุบชีวิตตามคำสั่ง server (เกิดใหม่ในโซน หรือถูกเด้งกลับจุดเข้าร่วม) ────────
function DoTeamTeleport(coords, invincibleAfter)
    local ped = PlayerPedId()
    print(('[lp_airdropteam:client] DoTeamTeleport start target=%.2f,%.2f,%.2f isDead=%s'):format(coords.x, coords.y, coords.z, tostring(IsEntityDead(ped))))

    DoScreenFadeOut(400)
    local fadeDeadline = GetGameTimer() + 1000
    while not IsScreenFadedOut() and GetGameTimer() < fadeDeadline do Wait(0) end
    print('[lp_airdropteam:client] faded out, IsScreenFadedOut=' .. tostring(IsScreenFadedOut()))

    -- MJ-Respwan เปิด death cam ของตัวเองไว้ (RenderScriptCams true ใน StartDeathCam) แล้วไม่มี
    -- ใครสั่งปิดจนกว่า MJ-Respwan เองจะ poll เจอว่า IsPlayerDead()=false (ทุก 500ms) — ระหว่างนั้น
    -- ตัวละครอาจวาร์ปไปแล้วจริงๆ แต่กล้องยังค้างที่เดิม ทำให้ดูเหมือนไม่วาร์ป ปิดกล้อง/spectator
    -- เองก่อนเลยกันไว้ก่อน (native/param เดียวกับ vorp_core/client/respawnsystem.lua's EndDeathCam)
    NetworkSetInSpectatorMode(false, ped)
    ClearFocus()
    RenderScriptCams(false, true, 500, true, false, 0)
    DestroyAllCams(true)

    if IsEntityDead(ped) then
        ResurrectPed(ped)
        print('[lp_airdropteam:client] called ResurrectPed, isDead now=' .. tostring(IsEntityDead(ped)))
    end

    FreezeEntityPosition(ped, true)
    SetEntityCollision(ped, false, false)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, true, true, true)
    SetEntityHeading(ped, coords.w or 0.0)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))

    local afterFirstSet = GetEntityCoords(ped)
    print(('[lp_airdropteam:client] after 1st SetEntityCoords, actual pos=%.2f,%.2f,%.2f'):format(afterFirstSet.x, afterFirstSet.y, afterFirstSet.z))

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    local collisionDeadline = GetGameTimer() + 3000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < collisionDeadline do
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        Wait(0)
    end
    print('[lp_airdropteam:client] collision wait done, HasCollisionLoaded=' .. tostring(HasCollisionLoadedAroundEntity(ped)))

    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, true, true, true)
    SetEntityHeading(ped, coords.w or 0.0)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, invincibleAfter and true or false)
    DoScreenFadeIn(300)

    local final = GetEntityCoords(ped)
    print(('[lp_airdropteam:client] DoTeamTeleport DONE, final pos=%.2f,%.2f,%.2f'):format(final.x, final.y, final.z))
end

-- ─── กำแพงมองไม่เห็น: ดันกลับเข้า safe zone ถ้าพยายามเดินออกก่อนหมดเวลา ─────────────
-- ทำงานเฉพาะช่วง joinedTeamId ~= nil และ zoneOpened == false เท่านั้น (เปิดโซนแล้วออกได้อิสระ)
CreateThread(function()
    while true do
        Wait(0)

        if not joinedTeamId or zoneOpened or not zoneSpawnPos then
            Wait(500)
            goto continue
        end

        local ped  = PlayerPedId()
        local pos  = GetEntityCoords(ped)
        local dist = #(pos - zoneSpawnPos)

        -- วง marker สีแดงคลุมขอบเขต safe zone ให้เห็นชัดว่าห้ามออกไปไหน (ก่อนหน้านี้มีแต่กำแพง
        -- มองไม่เห็น ผู้เล่นไม่มีทางรู้ขอบเขตล่วงหน้าเลย) type 28 = ring แบนราบ ยืนยันแล้วว่าใช้จริง
        -- ในโปรเจกต์นี้ที่ PolyZone/CircleZone.lua
        DrawMarker(28, zoneSpawnPos.x, zoneSpawnPos.y, zoneSpawnPos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            Config.Team.safeZoneRadius, Config.Team.safeZoneRadius, Config.Team.safeZoneRadius,
            255, 0, 0, 80, false, false, 2, nil, nil, false)

        if dist > Config.Team.safeZoneRadius then
            -- ดันกลับเข้าขอบวงตรงๆ ตามทิศที่เดินออกมา (เหมือนกำแพงมองไม่เห็น)
            local dir  = (pos - zoneSpawnPos) / dist
            local edge = zoneSpawnPos + dir * (Config.Team.safeZoneRadius - 0.5)
            SetEntityCoordsNoOffset(ped, edge.x, edge.y, pos.z, true, true, true)
        end

        ::continue::
    end
end)

-- ─── นับถอยหลัง safe zone แบบลอย (lp_textui) ────────────────────────────────────
local function StartSafeZoneCountdown(remainingMs)
    CreateThread(function()
        local endAt = GetGameTimer() + remainingMs
        exports.lp_textui:TextUI(('Safe zone ปิดใน %ds'):format(math.ceil(remainingMs / 1000)))
        exports.lp_textui:StartProgress(remainingMs)

        while joinedTeamId and not zoneOpened and GetGameTimer() < endAt do
            local left = math.ceil((endAt - GetGameTimer()) / 1000)
            exports.lp_textui:TextUI(('Safe zone ปิดใน %ds'):format(math.max(left, 0)))
            Wait(1000)
        end

        if joinedTeamId then
            exports.lp_textui:HideUI()
        end
    end)
end

local function JoinTeam(team)
    VORPcore.Callback.TriggerAsync('lp_airdropteam:JoinTeam', function(result)
        if not result or not result.ok then
            local reasons = {
                no_round       = "ยังไม่มีรอบแอร์ดรอปเปิดอยู่",
                locked         = "หมดเวลาเข้าร่วมแล้ว",
                already_joined = "คุณเข้าร่วมทีมไปแล้ว",
                no_team        = "คุณยังไม่ได้เลือกเมือง เข้าร่วมทีมไม่ได้",
            }
            Notify((result and reasons[result.reason]) or 'เข้าร่วมทีมไม่สำเร็จ', 'error')
            return
        end

        joinedTeamId = result.teamId
        zoneSpawnPos = vector3(result.coords.x, result.coords.y, result.coords.z)
        zoneOpened   = false

        -- ปลอดภัยระหว่าง safe zone (invincibleAfter = true) จนกว่าจะได้ CL:ZoneOpened
        DoTeamTeleport(result.coords, true)
        Notify('เข้าร่วม ' .. result.label .. ' แล้ว รอ safe zone หมดเวลา', 'success')
        StartSafeZoneCountdown(result.remainingMs or (Config.Team.safeZoneDuration * 1000))
    end, team.id)
end

-- ─── กดค้างเข้าร่วมทีม ผ่าน lp_textui:TextUIHold ลอยติดพิกัดจุด NPC ────────────────
-- เข้าร่วมได้ที่ NPC จุดไหนก็ได้ ไม่ผูกกับเมืองของผู้เล่น — teamId ที่ join ขึ้นกับ NPC ที่กดจริง
-- (server เชื่อ teamId ที่ client ส่งมาตรงๆ) ดังนั้นจุดที่กดเข้าร่วมคือจุดที่จะถูกส่งกลับไปเสมอ
CreateThread(function()
    local heldId = nil

    while true do
        Wait(500)

        if joinedTeamId then
            if heldId then
                exports.lp_textui:CancelHold()
                heldId = nil
            end
            goto continue
        end

        local pos = GetEntityCoords(PlayerPedId())
        local nearest, nearDist = nil, Config.Team.npc.radius

        for _, team in ipairs(Config.Team.teams) do
            local c = team.joinCoords
            local d = #(pos - vector3(c.x, c.y, c.z))
            if d <= nearDist then
                nearDist = d
                nearest  = team
            end
        end

        if nearest and heldId ~= nearest.id then
            if heldId then exports.lp_textui:CancelHold() end
            heldId = nearest.id
            exports.lp_textui:TextUIHold(
                "[E] ค้างเพื่อเข้าร่วม " .. nearest.label,
                Config.Team.npc.holdTime,
                function()
                    heldId = nil
                    JoinTeam(nearest)
                end,
                nil,
                { coords = vector3(nearest.joinCoords.x, nearest.joinCoords.y, nearest.joinCoords.z), offset = vector3(0.0, 0.0, 1.0) }
            )
        elseif not nearest and heldId then
            exports.lp_textui:CancelHold()
            heldId = nil
        end

        ::continue::
    end
end)

-- ─── คำสั่งจาก server: เกิดใหม่ในโซน (eliminated=false) หรือถูกเด้งออก (eliminated=true) ──
RegisterNetEvent('lp_airdropteam:CL:ReviveAt')
AddEventHandler('lp_airdropteam:CL:ReviveAt', function(coords, eliminated)
    print(('[lp_airdropteam:client] CL:ReviveAt received eliminated=%s'):format(tostring(eliminated)))
    -- ตอนถูกเด้งกลับจุดเข้าร่วมไม่ต้องคุ้มกันแล้ว (ออกจากรอบแล้ว)
    DoTeamTeleport(coords, not eliminated)
    if eliminated then
        joinedTeamId = nil
        zoneSpawnPos = nil
        zoneOpened   = false
        exports.lp_textui:HideUI()
        Notify('คุณถูกเด้งออกจากรอบแล้ว', 'error')
    end
end)

-- ─── Safe zone หมดเวลา: ปลดล็อคดาเมจ + กำแพง ให้คนที่ยังอยู่ในรอบ ────────────────
RegisterNetEvent('lp_airdropteam:CL:ZoneOpened')
AddEventHandler('lp_airdropteam:CL:ZoneOpened', function()
    zoneOpened = true
    if joinedTeamId then
        SetEntityInvincible(PlayerPedId(), false)
        exports.lp_textui:HideUI()
        Notify('Safe zone หมดเวลาแล้ว ระวังตัว!', 'error')
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in pairs(spawnedNpcs) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    for _, blip in pairs(spawnedBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
end)
