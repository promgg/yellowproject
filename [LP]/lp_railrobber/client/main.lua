-- lp_railrobber / client/main.lua
-- The client never decides an outcome. It: shows the intel broker prompt, tells
-- the server "I entered the ambush zone" / "ambush cleared" / "carriage cleared"
-- / plant+confirm the bomb / "I picked car N", and (only when the server tells
-- it to, as the heist OWNER = the buyer) spawns/moves the mission train + NPC
-- batches and reports back. Natives here are the ones proven in lp_railrobber_spike.

local isOwner   = false
local myTrain   = 0
local ambushPeds    = {} -- phase 2: ground ambush batch
local carriagePeds  = {} -- phase 3: carriage batch
local perimeterPeds = {} -- phase 4: exterior pressure spawns
local ambushBlip = nil
local myAmbush  = nil     -- { coords, heading, id } when this client is the buyer heading to the zone
local observerBlip = nil
local isBusy    = false   -- true while a plant or lockpick attempt is in flight (blocks re-entry)

local function dbg(m) if Config.Debug then print(('[lp_railrobber] %s'):format(m)) end end

-- Guards' own relationship group: ally to each other (no friendly fire), hostile
-- to players. Set up once at resource start; reused by ambush + carriage + perimeter batches.
local GUARD_GRP = GetHashKey('LP_RR_GUARDS')
CreateThread(function()
    AddRelationshipGroup('LP_RR_GUARDS')
    SetRelationshipBetweenGroups(1, GUARD_GRP, GUARD_GRP)                  -- 1 = respect/ally
    SetRelationshipBetweenGroups(5, GUARD_GRP, GetHashKey('PLAYER'))       -- 5 = hate
    SetRelationshipBetweenGroups(5, GetHashKey('PLAYER'), GUARD_GRP)
end)

-- pNotify wrapper with a guaranteed fallback (VORP tip) so the player ALWAYS
-- sees feedback even if pNotify errors; logs once if pNotify is the problem.
local pNotifyOk = true
local TYPE_MAP = { alert = 'warning' } -- pNotify core types: success/error/warning/info
local function Notify(text, kind, timeout)
    kind = TYPE_MAP[kind] or kind or 'info'
    timeout = timeout or 4000
    if pNotifyOk then
        local ok = pcall(function()
            exports.pNotify:SendNotification({ text = text, type = kind, timeout = timeout })
        end)
        if ok then return end
        pNotifyOk = false
        print('^3[lp_railrobber] pNotify export failed — using vorp tip fallback^7')
    end
    TriggerEvent('vorp:TipRight', text, timeout) -- always-works fallback
end

-- server-driven notifications (errors, gating, flow)
RegisterNetEvent('lp_railrobber:cl:notify', function(text, kind, timeout)
    Notify(text, kind, timeout)
end)

-- ── model / train helpers (from the spike, proven) ──────────────────────────
local function loadModel(model, timeoutMs)
    RequestModel(model, false)
    local t = GetGameTimer() + (timeoutMs or 5000)
    while not HasModelLoaded(model) do Wait(10); if GetGameTimer() > t then return false end end
    return true
end

local function loadTrainCars(hash)
    local cars = Citizen.InvokeNative(0x635423D55CA84FC8, hash) -- GetNumCarsFromTrainConfig
    if cars == 0 then
        print(('^1[lp_railrobber] train hash %s -> 0 cars (bad/unknown hash)^7'):format(tostring(hash)))
        return false
    end
    for i = 0, cars - 1 do
        local m = Citizen.InvokeNative(0x8DF5F6A19F99F0D5, hash, i) -- GetTrainModelFromTrainConfigByCarIndex
        if m ~= 0 then
            if not loadModel(m, 5000) then
                print(('^3[lp_railrobber] car %d model %s slow to stream — retrying (10s)^7'):format(i, tostring(m)))
                if not loadModel(m, 10000) then
                    print(('^1[lp_railrobber] car %d model %s FAILED to load after retry^7'):format(i, tostring(m)))
                    return false
                end
            end
        end
    end
    return true
end

-- delete carriage door props near the train so players can walk through the
-- openings (these connecting doors can't be reliably opened via natives on a
-- moving mission train — just remove them).
local DOOR_MODELS = {
    GetHashKey('p_door_northpassenger01x'),
    GetHashKey('p_door_northpassenger02x'),
    GetHashKey('p_door_northpassenger03x'),
}
local function deleteTrainDoors()
    local train = myTrain
    if train == 0 then
        local gs = GlobalState.lp_railrobber
        if gs and gs.trainNet and NetworkDoesNetworkIdExist(gs.trainNet) then
            train = NetworkGetEntityFromNetworkId(gs.trainNet)
        end
    end
    if not train or train == 0 or not DoesEntityExist(train) then return end
    local tc = GetEntityCoords(train) -- require a centre — never nuke doors map-wide
    for _, obj in ipairs(GetGamePool('CObject')) do
        if DoesEntityExist(obj) and #(GetEntityCoords(obj) - tc) < 250.0 then
            local m = GetEntityModel(obj)
            for _, dm in ipairs(DOOR_MODELS) do
                if m == dm then
                    SetEntityAsMissionEntity(obj, true, true)
                    DeleteEntity(obj)
                    break
                end
            end
        end
    end
end

-- continuously strip carriage doors while a heist train is live, so you can move through.
CreateThread(function()
    while true do
        local gs = GlobalState.lp_railrobber
        local st = gs and gs.state
        if st == Config.States.TRAIN_EN_ROUTE or st == Config.States.PVE
            or st == Config.States.PLANT or st == Config.States.LOOTING then
            deleteTrainDoors()
            Wait(2000)
        else
            Wait(1500)
        end
    end
end)

-- ── intel broker NPC ────────────────────────────────────────────────────────
-- Proximity spawn/despawn (same pattern as nx_shop's spawnNpc/removeNpc).
local brokerPed = 0
local brokerModelLoaded = false

local function spawnBroker()
    if brokerPed ~= 0 then return end
    local m = Config.IntelNPC.model
    if not brokerModelLoaded then
        if not loadModel(m) then
            print('^1[lp_railrobber] intel broker model failed to load — check Config.IntelNPC.model^7')
            return
        end
        brokerModelLoaded = true
    end
    local c = Config.IntelNPC.coords
    brokerPed = CreatePed(m, c.x, c.y, c.z - 1.0, Config.IntelNPC.heading, false, false, false, false)
    local t = GetGameTimer() + 3000
    while not DoesEntityExist(brokerPed) and GetGameTimer() < t do Wait(50) end
    if not DoesEntityExist(brokerPed) then brokerPed = 0; return end
    Citizen.InvokeNative(0x283978A15512B2FE, brokerPed, true) -- SetRandomOutfitVariation (else invisible)
    PlaceEntityOnGroundProperly(brokerPed)
    SetEntityInvincible(brokerPed, true)
    FreezeEntityPosition(brokerPed, true)
    SetBlockingOfNonTemporaryEvents(brokerPed, true)
    dbg(('intel broker spawned at %.1f,%.1f,%.1f'):format(c.x, c.y, c.z))
end

local function removeBroker()
    if brokerPed ~= 0 then
        if DoesEntityExist(brokerPed) then DeleteEntity(brokerPed) end
        brokerPed = 0
    end
end

-- proximity poll: spawn/despawn the broker + show the hold-E prompt when close
local showingPrompt = false
CreateThread(function()
    repeat Wait(1000) until LocalPlayer.state.IsInSession
    while true do
        local wait = 1000
        local d = #(GetEntityCoords(PlayerPedId()) - Config.IntelNPC.coords)

        if d <= Config.IntelNPC.spawnDistance then
            spawnBroker()
            if d <= Config.InteractRange then
                wait = 0
                if not showingPrompt then
                    showingPrompt = true
                    exports.lp_textui:TextUIHold('[E] ' .. Config.IntelNPC.prompt, Config.HoldMs, function()
                        showingPrompt = false
                        TriggerServerEvent('lp_railrobber:sv:buyIntel')
                    end, Config.KEY_E)
                end
            elseif showingPrompt then
                showingPrompt = false
                exports.lp_textui:CancelHold()
            end
        else
            removeBroker()
            if showingPrompt then
                showingPrompt = false
                exports.lp_textui:CancelHold()
            end
        end
        Wait(wait)
    end
end)

-- ── intel received (buyer-exclusive — server only ever targets the buyer) ───
RegisterNetEvent('lp_railrobber:cl:intelReceived', function(data)
    if ambushBlip and DoesBlipExist(ambushBlip) then RemoveBlip(ambushBlip) end
    local a = data.ambush
    ambushBlip = BlipAddForCoords(1664425300, a.coords.x, a.coords.y, a.coords.z)
    SetBlipSprite(ambushBlip, GetHashKey('blip_ambient_train'), true)
    Citizen.InvokeNative(0x9CB1A1623062F402, ambushBlip, CreateVarString(10, 'LITERAL_STRING', 'จุดซุ่มปล้นรถไฟ'))

    myAmbush = a -- this client must physically reach the zone to trigger the ambush
    Notify('ได้ข่าวขบวนสินค้าแล้ว! ตามหมุดสีบนแผนที่ไปยังจุดซุ่ม แล้วรอที่นั่น', 'success', 6000)
    dbg(('intel received ambush=%s'):format(a.id))
end)

-- buyer heads to the ambush; when inside the radius, tell the server
CreateThread(function()
    while true do
        local wait = 1000
        if myAmbush then
            local d = #(GetEntityCoords(PlayerPedId()) - vector3(myAmbush.coords.x, myAmbush.coords.y, myAmbush.coords.z))
            if d <= Config.AmbushRadius then
                TriggerServerEvent('lp_railrobber:sv:reachedAmbush')
                Notify('ถึงจุดซุ่มแล้ว! ระวังตัว!', 'alert', 5000)
                myAmbush = nil -- fire once; server drives everything after this
            else
                wait = 500
            end
        end
        Wait(wait)
    end
end)

-- ── ground ambush batch (phase 2) — kill-agnostic clear, corpse-cleanup on death ──
RegisterNetEvent('lp_railrobber:cl:spawnAmbush', function(p)
    if not loadModel(p.model) then return end
    ambushPeds = {}
    for i = 1, p.count do
        local ang = (i / p.count) * 2 * math.pi
        local wx = p.coords.x + math.cos(ang) * 4.0
        local wy = p.coords.y + math.sin(ang) * 4.0
        local ped = CreatePed(p.model, wx, wy, p.coords.z, p.heading, true, true, false, false)
        Wait(0)
        Citizen.InvokeNative(0x283978A15512B2FE, ped, true) -- outfit (else invisible)
        Wait(120)
        local net = PedToNet(ped)
        if SetNetworkIdExistsOnAllMachines then SetNetworkIdExistsOnAllMachines(net, true) end
        SetPedRelationshipGroupHash(ped, GUARD_GRP)
        SetEntityInvincible(ped, false)
        SetPedCanRagdoll(ped, false)
        GiveWeaponToPed(ped, p.weapon, 250, false, true)
        SetCurrentPedWeapon(ped, p.weapon, true)
        TaskCombatPed(ped, PlayerPedId(), 0, 16)
        ambushPeds[#ambushPeds + 1] = ped
    end
    Notify('มีคนเฝ้าจุดซุ่ม! กำจัดให้หมด', 'alert', 5000)
    dbg(('spawned %d ambush NPCs'):format(#ambushPeds))

    -- combined thread: delete corpses the instant they die + report all-clear
    CreateThread(function()
        while true do
            Wait(1500)
            local alive = 0
            for _, ped in ipairs(ambushPeds) do
                if ped and DoesEntityExist(ped) then
                    if IsEntityDead(ped) then DeleteEntity(ped)
                    else alive = alive + 1 end
                end
            end
            if alive == 0 then TriggerServerEvent('lp_railrobber:sv:ambushCleared'); return end
        end
    end)
end)

-- ── OWNER: spawn the approaching mission train, report its net id ────────────
RegisterNetEvent('lp_railrobber:cl:spawnTrain', function(p)
    if not loadTrainCars(p.hash) then dbg('train cars failed to load'); return end
    myTrain = CreateMissionTrain(p.hash, p.spawn.x, p.spawn.y, p.spawn.z, false, false, true, false)
    if myTrain == 0 then dbg('CreateMissionTrain returned 0'); return end
    isOwner = true

    local net = NetworkGetNetworkIdFromEntity(myTrain)
    if SetNetworkIdExistsOnAllMachines then SetNetworkIdExistsOnAllMachines(net, true) end
    SetTrainCruiseSpeed(myTrain, p.cruise)
    SetTrainSpeed(myTrain, p.cruise)

    TriggerServerEvent('lp_railrobber:sv:trainSpawned', net)
    dbg(('spawned + owning train net=%d, cruising @ %.1f'):format(net, p.cruise))

    -- Lock state 0 = NONE (fully normal) so the base-game ped can auto-open the
    -- connecting/side doors by walking into them — EXCEPT the locomotive (car 0),
    -- which stays LOCKED for the whole heist so no player can climb in and drive
    -- it off script (the mission-train natives already own its speed/route).
    CreateThread(function()
        Wait(600) -- carriages ready
        local cars = Citizen.InvokeNative(0x635423D55CA84FC8, p.hash) or 0
        for i = 0, math.max(0, cars - 1) do
            local car = Citizen.InvokeNative(0xD0FB093A4CDB932C, myTrain, i)
            if car and car ~= 0 and DoesEntityExist(car) then
                Citizen.InvokeNative(0x96F78A6A075D55D9, car, i == 0 and 2 or 0) -- SET_VEHICLE_DOORS_LOCKED (2=LOCKED, 0=NONE)
            end
        end
    end)

    -- keep the cruise speed asserted while we own an active heist
    CreateThread(function()
        while isOwner and myTrain ~= 0 and DoesEntityExist(myTrain) do
            local gs = GlobalState.lp_railrobber
            if gs and gs.state == Config.States.PVE or (gs and gs.state == Config.States.TRAIN_EN_ROUTE) then
                SetTrainCruiseSpeed(myTrain, p.cruise)
            end
            Wait(2000)
        end
    end)
end)

-- ── OWNER: carriage NPC batch (phase 3) — spawn PER CARRIAGE on approach ─────
-- Spawning the whole batch the instant the train exists races the carriage
-- entities still streaming in (far cars aren't queryable yet — confirmed live:
-- idx=8 kept failing while nearer indices worked fine). Fix: queue the
-- assignment, don't touch any carriage entity until the buyer is physically
-- near it — by then it's guaranteed loaded, since nearby entities always
-- stream in first. Also reads better as a heist: guards ambush car-by-car as
-- you walk the train, not all at once the moment you board.
local carriageQueue    = {}   -- [carIndex] = NPC count still waiting to spawn there
local carriageSpawned  = {}   -- [carIndex] = true once that carriage's NPCs are up
local carriageModel, carriageWeapon = nil, nil

RegisterNetEvent('lp_railrobber:cl:spawnCarriageBatch', function(p)
    if not isOwner or myTrain == 0 then dbg('spawnCarriageBatch: not owner / no train — skipped'); return end
    if not loadModel(p.model) then dbg('spawnCarriageBatch: guard model failed to load'); return end

    carriagePeds = {}
    carriageQueue = {}
    carriageSpawned = {}
    carriageModel, carriageWeapon = p.model, p.weapon
    local total = 0
    for _, idx in ipairs(p.assignments) do
        carriageQueue[idx] = (carriageQueue[idx] or 0) + 1
        total = total + 1
    end
    Notify('ยามกำลังตรวจตราขบวนรถไฟ! ระวังตัวเมื่อเข้าใกล้แต่ละโบกี้', 'alert', 5000)
    dbg(('carriage batch queued: %d NPCs across %d carriage(s) — spawning on approach'):format(total, #p.assignments))
end)

-- spawns ALL seats queued for one carriage at once (group, so spacingY offsets
-- still spread them like before) — returns false if the carriage still isn't
-- queryable yet (caller just leaves it queued and retries next tick)
local function spawnCarriageGroup(idx, count)
    local carriage = Citizen.InvokeNative(0xD0FB093A4CDB932C, myTrain, idx)
    if not carriage or carriage == 0 or not DoesEntityExist(carriage) then return false end

    local ga = Config.GuardAttach
    local cc, ch = GetEntityCoords(carriage), GetEntityHeading(carriage)
    local rad = math.rad(ch)
    local cosA, sinA = math.cos(rad), math.sin(rad)
    for seat = 1, count do
        local lx, ly = ga.x, ga.startY + (seat * ga.spacingY)
        local wx = cc.x + (lx * cosA - ly * sinA)
        local wy = cc.y + (lx * sinA + ly * cosA)
        local wz = cc.z + ga.z

        -- NOT attached: a ped standing on a moving carriage roof is carried by
        -- the vehicle's own collision, same as the spike proved — attach freezes
        -- them in place (position pinned every frame breaks combat movement).
        local ped = CreatePed(carriageModel, wx, wy, wz, ch, true, true, false, false)
        Wait(0)
        Citizen.InvokeNative(0x283978A15512B2FE, ped, true) -- outfit (else invisible)
        Wait(80)
        local net = PedToNet(ped)
        if SetNetworkIdExistsOnAllMachines then SetNetworkIdExistsOnAllMachines(net, true) end
        SetPedRelationshipGroupHash(ped, GUARD_GRP)
        SetEntityInvincible(ped, false)
        SetPedCanRagdoll(ped, false)
        GiveWeaponToPed(ped, carriageWeapon, 250, false, true)
        SetCurrentPedWeapon(ped, carriageWeapon, true)
        TaskCombatPed(ped, PlayerPedId(), 0, 16)
        carriagePeds[#carriagePeds + 1] = ped
    end
    dbg(('spawned %d NPC(s) on carriage idx=%d (proximity trigger)'):format(count, idx))
    return true
end

-- persistent thread: spawn queued carriages as the buyer walks up to them,
-- clean up corpses, and report all-clear only once EVERY queued carriage has
-- both been visited (spawned) AND had its NPCs killed — a carriage nobody
-- ever walked to never silently counts as "cleared".
CreateThread(function()
    while true do
        local wait = 1000
        if isOwner and myTrain ~= 0 and DoesEntityExist(myTrain) and next(carriageQueue) ~= nil then
            wait = 500
            local pc = GetEntityCoords(PlayerPedId())
            local allVisited = true
            for idx, count in pairs(carriageQueue) do
                if not carriageSpawned[idx] then
                    local carriage = Citizen.InvokeNative(0xD0FB093A4CDB932C, myTrain, idx)
                    if carriage and carriage ~= 0 and DoesEntityExist(carriage)
                        and #(pc - GetEntityCoords(carriage)) <= Config.GuardSpawnRange then
                        if spawnCarriageGroup(idx, count) then carriageSpawned[idx] = true end
                    end
                    if not carriageSpawned[idx] then allVisited = false end
                end
            end

            local alive = 0
            for _, ped in ipairs(carriagePeds) do
                if ped and DoesEntityExist(ped) then
                    if IsEntityDead(ped) then DeleteEntity(ped)
                    else alive = alive + 1 end
                end
            end

            if allVisited and alive == 0 then
                dbg('all carriages visited + cleared -> reporting to server')
                TriggerServerEvent('lp_railrobber:sv:carriageCleared')
                carriageQueue = {} -- stop this branch from re-firing
            end
        end
        Wait(wait)
    end
end)

-- ── OWNER: perimeter NPCs during looting (phase 4 pressure) — no clear-report ──
RegisterNetEvent('lp_railrobber:cl:spawnPerimeter', function(p)
    if not isOwner or myTrain == 0 then return end
    if not loadModel(Config.GuardModel) then return end
    local tc = GetEntityCoords(myTrain)
    local batch = {}
    for i = 1, p.count do
        local ang = math.random() * 2 * math.pi
        local rad = Config.LootPerimeterRadius[1] + math.random() * (Config.LootPerimeterRadius[2] - Config.LootPerimeterRadius[1])
        local wx = tc.x + math.cos(ang) * rad
        local wy = tc.y + math.sin(ang) * rad
        local ped = CreatePed(Config.GuardModel, wx, wy, tc.z, math.random(0, 359), true, true, false, false)
        Wait(0)
        Citizen.InvokeNative(0x283978A15512B2FE, ped, true) -- outfit
        Wait(80)
        local net = PedToNet(ped)
        if SetNetworkIdExistsOnAllMachines then SetNetworkIdExistsOnAllMachines(net, true) end
        SetPedRelationshipGroupHash(ped, GUARD_GRP)
        SetEntityInvincible(ped, false)
        SetPedCanRagdoll(ped, false)
        GiveWeaponToPed(ped, Config.GuardWeapon, 250, false, true)
        SetCurrentPedWeapon(ped, Config.GuardWeapon, true)
        TaskCombatPed(ped, PlayerPedId(), 0, 16)
        batch[#batch + 1] = ped
        perimeterPeds[#perimeterPeds + 1] = ped
    end
    dbg(('spawned %d perimeter NPCs (pressure during looting)'):format(#batch))

    -- flavor pressure only — just delete corpses on death, no phase gate to report
    CreateThread(function()
        while true do
            Wait(1500)
            local anyAlive = false
            for _, ped in ipairs(batch) do
                if ped and DoesEntityExist(ped) then
                    if IsEntityDead(ped) then DeleteEntity(ped)
                    else anyAlive = true end
                end
            end
            if not anyAlive then return end
        end
    end)
end)

-- ── OWNER: stop the train (bomb confirmed / breach handoff) ──────────────────
RegisterNetEvent('lp_railrobber:cl:stopTrain', function()
    if myTrain ~= 0 and DoesEntityExist(myTrain) then
        SetTrainCruiseSpeed(myTrain, 0.0)
        SetTrainSpeed(myTrain, 0.0)
        -- unlock + DELETE the connecting door props (can't reliably open them on a
        -- moving mission train — remove so players walk through). Loop a few passes
        -- since carriage props stream in late.
        CreateThread(function()
            Wait(4500)
            local cars = Citizen.InvokeNative(0x635423D55CA84FC8, Config.TrainHash) or 0
            for i = 0, math.max(0, cars - 1) do
                local car = Citizen.InvokeNative(0xD0FB093A4CDB932C, myTrain, i)
                if car and car ~= 0 and DoesEntityExist(car) then
                    Citizen.InvokeNative(0x96F78A6A075D55D9, car, i == 0 and 2 or 0) -- loco(0)=LOCKED (no player driving), rest=NONE
                end
            end
        end)
    end
    Notify('รถไฟหยุดแล้ว — เข้าไปงัดตู้', 'success', 6000)
    dbg('train stopped — looting phase')
end)

-- ── ALL clients: resolve the train so everyone sees it (bcc-train pattern) ──
RegisterNetEvent('lp_railrobber:cl:trainSync', function(trainNet)
    CreateThread(function()
        local t = GetGameTimer() + 8000
        while GetGameTimer() < t do
            if NetworkDoesNetworkIdExist(trainNet) then
                local ent = NetworkGetEntityFromNetworkId(trainNet)
                if ent ~= 0 and DoesEntityExist(ent) then
                    if observerBlip and DoesBlipExist(observerBlip) then RemoveBlip(observerBlip) end
                    observerBlip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, -1749618580, ent) -- BlipAddForEntity
                    return
                end
            end
            Wait(200)
        end
    end)
end)

-- ── Hand prop builder (ported from lp_robbery) ───────────────────────────────
-- Config.Props เก็บ bone เป็น "ชื่อ" — resolve เป็น index ตรงนี้ แล้วส่งเป็น field
-- `prop` ให้ lp_progbar สร้าง/แปะ/ลบเองครบทุกทาง.
local function buildProp(def)
    if not def or not def.model then return nil end
    return {
        model    = def.model,
        bone     = GetEntityBoneIndexByName(PlayerPedId(), def.bone or 'SKEL_R_Hand'),
        coords   = def.coords,
        rotation = def.rotation,
    }
end

-- ── bomb plant at the locomotive (ported from lp_robbery's startBank) ────────
local lastPlantResult = nil
RegisterNetEvent('lp_railrobber:cl:plantRequestResult', function(ok) lastPlantResult = ok end)

local function startPlant()
    if isBusy then return end
    isBusy = true
    lastPlantResult = nil
    TriggerServerEvent('lp_railrobber:sv:requestPlant')

    CreateThread(function()
        local deadline = GetGameTimer() + 5000
        while lastPlantResult == nil and GetGameTimer() < deadline do Wait(0) end
        local ok = lastPlantResult
        lastPlantResult = nil

        if not ok then isBusy = false; return end

        exports.lp_progbar:Progress({
            duration = Config.PlantDuration,
            label = 'กำลังวางระเบิด...',
            controlDisables = { disableMovement = true },
            animation = { task = 'WORLD_HUMAN_CROUCH_INSPECT' },
            prop = buildProp(Config.Props and Config.Props.plant),
        }, function(cancelled)
            if cancelled then
                Notify('ยกเลิก', 'error', 3000)
                TriggerServerEvent('lp_railrobber:sv:cancelPlant')
                isBusy = false
                return
            end

            Notify('หนีเร็ว! ระเบิดใน 15 วิ!', 'error', Config.BombFuseTime * 1000)
            CreateThread(function()
                Wait(Config.BombFuseTime * 1000)
                TriggerServerEvent('lp_railrobber:sv:confirmPlantBlow')
                isBusy = false
            end)
        end)
    end)
end

RegisterNetEvent('lp_railrobber:cl:syncExplosion', function(pos)
    if not pos then return end
    local pc = GetEntityCoords(PlayerPedId())
    local epos = vector3(pos.x, pos.y, pos.z)
    if #(pc - epos) > 150.0 then return end -- everyone near renders/hears it; far clients skip the FX
    AddExplosion(pos.x, pos.y, pos.z, Config.Explosion.type, Config.Explosion.radius, true, false, 1.0)
    if #(pc - epos) <= 40.0 then
        ShakeGameplayCam(Config.Explosion.cameraShake, Config.Explosion.shake)
    end
end)

-- proximity poll for the plant prompt — locomotive is always carriage index 0,
-- every nearby player may plant; the server serializes the single active planter
local plantShown = false
local sawPlantState = false  -- debug: did the client ever observe state==PLANT at all
local lastPlantDbg = 0       -- debug: throttle the distance print
CreateThread(function()
    while true do
        local wait = 600
        local gs = GlobalState.lp_railrobber
        if gs and gs.state == Config.States.PLANT then
            if not sawPlantState then
                sawPlantState = true
                dbg(('plant-prompt: state=PLANT observed. gs.buyerSrc=%s myServerId=%s match=%s')
                    :format(tostring(gs.buyerSrc), tostring(GetPlayerServerId(PlayerId())), tostring(gs.buyerSrc == GetPlayerServerId(PlayerId()))))
            end
        else
            sawPlantState = false
        end

        if gs and gs.state == Config.States.PLANT and not gs.plantingSrc and not isBusy then
            local train = myTrain
            if train == 0 then
                if gs.trainNet and NetworkDoesNetworkIdExist(gs.trainNet) then
                    train = NetworkGetEntityFromNetworkId(gs.trainNet)
                end
            end
            if train ~= 0 and DoesEntityExist(train) then
                local loco = Citizen.InvokeNative(0xD0FB093A4CDB932C, train, 0)
                if not loco or loco == 0 then loco = train end
                local pc = GetEntityCoords(PlayerPedId())
                local d = #(pc - GetEntityCoords(loco))
                if GetGameTimer() - lastPlantDbg > 2000 then
                    lastPlantDbg = GetGameTimer()
                    dbg(('plant-prompt: loco=%s dist=%.1f range=%.1f'):format(tostring(loco), d, Config.PlantBreachRange))
                end
                if d <= Config.PlantBreachRange then
                    wait = 0
                    if not plantShown then
                        plantShown = true
                        exports.lp_textui:TextUIHold('[E] วางระเบิด', Config.HoldMs, function()
                            plantShown = false
                            startPlant()
                        end, Config.KEY_E)
                    end
                elseif plantShown then
                    plantShown = false
                    exports.lp_textui:CancelHold()
                end
            elseif GetGameTimer() - lastPlantDbg > 2000 then
                lastPlantDbg = GetGameTimer()
                dbg(('plant-prompt: no resolvable train entity (myTrain=%d trainNet=%s)'):format(myTrain, tostring(gs.trainNet)))
            end
        elseif plantShown then
            plantShown = false
            exports.lp_textui:CancelHold()
        end
        Wait(wait)
    end
end)

-- ── looting: all nearby players may pick any available car ───────────────────
RegisterNetEvent('lp_railrobber:cl:beginLooting', function()
    Notify('เคลียร์ยามแล้ว! เข้าไปงัดตู้สินค้า (E)', 'info', 6000)
end)

local function resolveTrain()
    local gs = GlobalState.lp_railrobber
    if not gs or not gs.trainNet or not NetworkDoesNetworkIdExist(gs.trainNet) then return 0 end
    local ent = NetworkGetEntityFromNetworkId(gs.trainNet)
    return (ent ~= 0 and DoesEntityExist(ent)) and ent or 0
end

-- ตรวจไอเทมก่อนเล่นมินิเกม (ไม่ใช่งัดไปแล้วถึงมาบอกว่าไม่มีของ) — sync export ที่มีอยู่
-- แล้วในโปรเจกต์นี้ (ดูตัวอย่างการใช้ใน MJ-Respwan/MJ-Mailbox), อ่านจาก cache ฝั่ง client
-- เอง ไม่ใช่ round-trip ไปเซิร์ฟเวอร์ — ใช้เป็น early feedback เท่านั้น เซิร์ฟเวอร์ยัง
-- เช็ค+หักของจริงเองอีกที (sv:lockpickAttempt) ไม่ไว้ใจ client
local function hasLockpickItem()
    local item = exports.vorp_inventory:getInventoryItem(Config.LockpickItem)
    return item and (item.count or 0) > 0
end

-- ผลจาก sv:lockpickAttempt — แค่บอกว่า "ไปเล่น progbar ต่อได้" เท่านั้น ยังไม่ใช่รางวัล
-- (item หักไปแล้วตั้งแต่ตรงนี้ที่เซิร์ฟเวอร์ ไม่ว่าจะพลาดหรือสำเร็จ) รางวัลจริงมาจาก
-- sv:confirmCarLoot ซึ่งยิงก็ต่อเมื่อ progbar เล่นจบแบบไม่ถูกยกเลิกเท่านั้น
local lastLockpickResult = nil -- { carIndex, ok }
RegisterNetEvent('lp_railrobber:cl:lockpickAttemptResult', function(carIndex, ok)
    lastLockpickResult = { carIndex = carIndex, ok = ok }
end)

local function startCarPick(carIndex)
    if isBusy then return end
    if not hasLockpickItem() then
        Notify('คุณต้องมีชุดงัดกุญแจ', 'error', 3000)
        return
    end
    isBusy = true

    local picked = exports.lp_minigame:Lockpick(Config.CarLockpick)
    -- item consumed EVERY attempt regardless of outcome — server does the actual
    -- subItem (never trust the client for economy-affecting state)
    lastLockpickResult = nil
    TriggerServerEvent('lp_railrobber:sv:lockpickAttempt', carIndex, picked)

    if not picked then
        isBusy = false
        return -- instant retry allowed, no cooldown — cost is the item, not a timer
    end

    CreateThread(function()
        local deadline = GetGameTimer() + 3000
        while not lastLockpickResult and GetGameTimer() < deadline do Wait(0) end
        local res = lastLockpickResult
        lastLockpickResult = nil

        if not res or res.carIndex ~= carIndex or not res.ok then
            isBusy = false
            return
        end

        exports.lp_progbar:Progress({
            duration = Config.CarProgDuration,
            label = 'กำลังงัดตู้...',
            controlDisables = { disableMovement = true },
            animation = { animDict = 'script_common@jail_cell@unlock@key', anim = 'action', flags = 1 },
        }, function(cancelled)
            isBusy = false
            if cancelled then
                Notify('ยกเลิก', 'error', 3000)
                TriggerServerEvent('lp_railrobber:sv:cancelCarLoot', carIndex)
                return
            end
            -- รางวัลจริงเกิดตรงนี้ (ฝั่งเซิร์ฟเวอร์) — เล่น progbar จบไม่ถูกยกเลิกเท่านั้นถึงได้
            TriggerServerEvent('lp_railrobber:sv:confirmCarLoot', carIndex)
        end)
    end)
end

local breachShown = false
CreateThread(function()
    while true do
        local wait = 600
        local gs = GlobalState.lp_railrobber
        if gs and gs.state == Config.States.LOOTING and not isBusy then
            local train = resolveTrain()
            if train ~= 0 then
                wait = 250
                local pc = GetEntityCoords(PlayerPedId())
                local nearIdx
                for idx = Config.LootCarriageRange[1], Config.LootCarriageRange[2] do
                    if not (gs.breached and gs.breached[idx]) then
                        local car = Citizen.InvokeNative(0xD0FB093A4CDB932C, train, idx)
                        if car and car ~= 0 and DoesEntityExist(car) and #(pc - GetEntityCoords(car)) <= Config.CarBreachRange then
                            nearIdx = idx; break
                        end
                    end
                end
                if nearIdx and not breachShown then
                    breachShown = true
                    exports.lp_textui:TextUIHold('[E] งัดตู้สินค้า', Config.HoldMs, function()
                        breachShown = false
                        startCarPick(nearIdx)
                    end, Config.KEY_E)
                elseif not nearIdx and breachShown then
                    breachShown = false
                    exports.lp_textui:CancelHold()
                end
            end
        elseif breachShown then
            breachShown = false
            exports.lp_textui:CancelHold()
        end
        Wait(wait)
    end
end)

-- ── teardown (owner) ────────────────────────────────────────────────────────
local function deletePedList(list)
    for _, ped in ipairs(list) do
        if ped and DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end

local function teardown()
    isOwner = false
    deletePedList(ambushPeds); ambushPeds = {}
    deletePedList(carriagePeds); carriagePeds = {}
    deletePedList(perimeterPeds); perimeterPeds = {}
    carriageQueue = {}
    carriageSpawned = {}
    if myTrain ~= 0 then
        local cars = Citizen.InvokeNative(0x635423D55CA84FC8, Config.TrainHash) or 0
        for i = 0, math.max(0, cars - 1) do
            local car = Citizen.InvokeNative(0xD0FB093A4CDB932C, myTrain, i)
            if car and car ~= 0 and DoesEntityExist(car) then SetEntityAsMissionEntity(car, true, true); DeleteEntity(car) end
        end
        if DoesEntityExist(myTrain) then SetEntityAsMissionEntity(myTrain, true, true); DeleteEntity(myTrain) end
        myTrain = 0
    end
    if ambushBlip and DoesBlipExist(ambushBlip) then RemoveBlip(ambushBlip); ambushBlip = nil end
    if observerBlip and DoesBlipExist(observerBlip) then RemoveBlip(observerBlip); observerBlip = nil end
    myAmbush = nil
    isBusy = false
    if plantShown then exports.lp_textui:CancelHold(); plantShown = false end
    if breachShown then exports.lp_textui:CancelHold(); breachShown = false end
end

RegisterNetEvent('lp_railrobber:cl:teardown', teardown)

-- /rr_cars — while a heist train is up, print every carriage index + its model
-- so you can map a car you can see (e.g. northpassenger03x) to a config index.
RegisterCommand('rr_cars', function()
    local train = myTrain
    if train == 0 then
        local gs = GlobalState.lp_railrobber
        if gs and gs.trainNet and NetworkDoesNetworkIdExist(gs.trainNet) then
            train = NetworkGetEntityFromNetworkId(gs.trainNet)
        end
    end
    if not train or train == 0 or not DoesEntityExist(train) then print('[lp_railrobber] no active heist train nearby'); return end
    local cars = Citizen.InvokeNative(0x635423D55CA84FC8, Config.TrainHash) or 0
    local target = GetHashKey('northpassenger03x')
    print(('[lp_railrobber] --- %d carriages (northpassenger03x hash=%d) ---'):format(cars, target))
    for i = 0, cars - 1 do
        local car = Citizen.InvokeNative(0xD0FB093A4CDB932C, train, i)
        local model = (car and car ~= 0 and DoesEntityExist(car)) and GetEntityModel(car) or 0
        print(('[lp_railrobber] carriage %d -> model %d %s'):format(i, model, model == target and '  <== northpassenger03x' or ''))
    end
end, false)

-- ── train picker (debug) ────────────────────────────────────────────────────
-- /rr_testtrain 0x0392C83A  -> spawn that train in front of you (stopped, doors
-- unlocked) + print each carriage model, so you can eyeball which train has open
-- cars / no connecting doors. /rr_testclean removes it.
local testTrain = 0
RegisterCommand('rr_testtrain', function(_, args)
    local hash = tonumber(args[1])
    if not hash then print('[lp_railrobber] usage: /rr_testtrain 0x0392C83A'); return end
    if testTrain ~= 0 and DoesEntityExist(testTrain) then SetEntityAsMissionEntity(testTrain, true, true); DeleteEntity(testTrain) end
    testTrain = 0

    local cars = Citizen.InvokeNative(0x635423D55CA84FC8, hash)
    if not cars or cars == 0 then print('[lp_railrobber] bad hash (0 cars)'); return end
    for i = 0, cars - 1 do
        local mdl = Citizen.InvokeNative(0x8DF5F6A19F99F0D5, hash, i)
        if mdl ~= 0 then RequestModel(mdl, false); local t = GetGameTimer() + 5000
            while not HasModelLoaded(mdl) do Wait(10); if GetGameTimer() > t then break end end
        end
    end

    local p = GetEntityCoords(PlayerPedId())
    local f = GetEntityForwardVector(PlayerPedId())
    testTrain = CreateMissionTrain(hash, p.x + f.x * 40, p.y + f.y * 40, p.z, false, false, true, false)
    if testTrain == 0 then print('[lp_railrobber] CreateMissionTrain failed'); return end
    SetTrainCruiseSpeed(testTrain, 0.0); SetTrainSpeed(testTrain, 0.0)

    print(('[lp_railrobber] === train %s -> %d cars ==='):format(tostring(args[1]), cars))
    for i = 0, cars - 1 do
        local car = Citizen.InvokeNative(0xD0FB093A4CDB932C, testTrain, i)
        if car and car ~= 0 and DoesEntityExist(car) then
            Citizen.InvokeNative(0x96F78A6A075D55D9, car, 0) -- unlock
            print(('[lp_railrobber] car %d -> model %d'):format(i, GetEntityModel(car)))
        end
    end
end, false)

-- /rr_testguard <carIdx> [z]  -> attach 3 test guards to that carriage of the
-- test train + print their world coords, so you can find an index/z where they
-- DON'T sink into the ground. e.g. /rr_testguard 2 2.6
local testGuards = {}
RegisterCommand('rr_testguard', function(_, args)
    if testTrain == 0 or not DoesEntityExist(testTrain) then print('[lp_railrobber] spawn a test train first: /rr_testtrain <hash>'); return end
    local idx = tonumber(args[1]) or 2
    local z   = tonumber(args[2]) or 2.6
    local carriage = Citizen.InvokeNative(0xD0FB093A4CDB932C, testTrain, idx)
    if not carriage or carriage == 0 then print('[lp_railrobber] no carriage at index ' .. idx); return end

    local m = Config.GuardModel
    RequestModel(m, false); local t = GetGameTimer() + 5000
    while not HasModelLoaded(m) do Wait(10); if GetGameTimer() > t then break end end

    for i = 1, 3 do
        local ped = CreatePed(m, 0.0, 0.0, 0.0, 0.0, false, true, false, false)
        Wait(0)
        Citizen.InvokeNative(0x283978A15512B2FE, ped, true) -- outfit (else invisible)
        Wait(120)
        SetEntityInvincible(ped, true) -- test only
        AttachEntityToEntity(ped, carriage, 0, 0.0, -2.5 + (i * 1.6), z, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        testGuards[#testGuards + 1] = ped
        local gc = GetEntityCoords(ped)
        print(('[lp_railrobber] testguard %d idx=%d z=%.1f -> %.1f,%.1f,%.1f'):format(i, idx, z, gc.x, gc.y, gc.z))
    end
end, false)

local function cleanTestGuards()
    for _, ped in ipairs(testGuards) do if ped and DoesEntityExist(ped) then DeleteEntity(ped) end end
    testGuards = {}
end

RegisterCommand('rr_testclean', function()
    cleanTestGuards()
    if testTrain ~= 0 then
        if DoesEntityExist(testTrain) then SetEntityAsMissionEntity(testTrain, true, true); DeleteEntity(testTrain) end
        testTrain = 0
    end
    print('[lp_railrobber] test train + guards cleaned')
end, false)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    teardown()
    cleanTestGuards()
    if testTrain ~= 0 and DoesEntityExist(testTrain) then DeleteEntity(testTrain) end
    removeBroker()
    if showingPrompt then exports.lp_textui:CancelHold() end
end)
