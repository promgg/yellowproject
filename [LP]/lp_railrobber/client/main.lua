-- lp_railrobber / client/main.lua  (STAGE 1 — PvE spine)
-- The client never decides an outcome. It: shows the intel broker prompt, tells
-- the server "I entered the ambush zone", and (only when the server tells it to,
-- as the heist OWNER) spawns/moves the mission train + guard waves and reports
-- back. Natives here are the ones proven in lp_railrobber_spike.

local isOwner   = false
local myTrain   = 0
local guards    = {}     -- current wave's guard peds
local ambushBlip = nil
local myAmbush  = nil     -- { coords, heading, id } when this client is the buyer heading to the zone
local observerBlip = nil

local function dbg(m) if Config.Debug then print(('[lp_railrobber] %s'):format(m)) end end

-- Guards' own relationship group: ally to each other (no friendly fire), hostile
-- to players. These natives DO exist in RDR3 (confirmed) — earlier removal was
-- based on a wrong theory; the real "guards don't spawn" bug was an invalid
-- carriage index, not this. Set up once at resource start.
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

-- was a bare "failed to load" with no way to tell WHY (bad hash vs one car's
-- model just streaming slowly). Now logs the exact failing car/model + retries
-- once with a longer timeout before giving up, since streaming hiccups are common.
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
    -- resolve the train on ANY client (owner has myTrain; others via net id)
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

-- continuously strip carriage doors while a heist train is live (from the moment
-- it spawns / player boards — not just after it stops), so you can move through.
CreateThread(function()
    while true do
        local gs = GlobalState.lp_railrobber
        local st = gs and gs.state
        if st == Config.States.TRAIN_EN_ROUTE or st == Config.States.PVE
            or st == Config.States.BREACHING or st == Config.States.HOLD then
            deleteTrainDoors()
            Wait(2000)
        else
            Wait(1500)
        end
    end
end)

-- ── intel broker NPC ────────────────────────────────────────────────────────
-- Proximity spawn/despawn (same pattern as nx_shop's spawnNpc/removeNpc): the
-- ped only exists in the world while a player is within Config.IntelNPC.spawnDistance,
-- instead of being created once and living forever. Interaction still uses this
-- project's own lp_textui hold-E, not nx_shop's UiPrompt.
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
    Citizen.InvokeNative(0x283978A15512B2FE, brokerPed, true) -- SetRandomOutfitVariation (else invisible — same bug as the guards had)
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

-- ── intel received (buyer's whole city) — blip the ambush point ─────────────
RegisterNetEvent('lp_railrobber:cl:intelReceived', function(data)
    if ambushBlip and DoesBlipExist(ambushBlip) then RemoveBlip(ambushBlip) end
    local a = data.ambush
    ambushBlip = BlipAddForCoords(1664425300, a.coords.x, a.coords.y, a.coords.z)
    SetBlipSprite(ambushBlip, GetHashKey('blip_ambient_train'), true)
    Citizen.InvokeNative(0x9CB1A1623062F402, ambushBlip, CreateVarString(10, 'LITERAL_STRING', 'จุดซุ่มปล้นรถไฟ'))

    if data.isBuyer then
        myAmbush = a -- this client must physically reach the zone to trigger the train
        Notify('ได้ข่าวขบวนสินค้าแล้ว! ตามหมุดสีบนแผนที่ไปยังจุดซุ่ม แล้วรอขบวนที่นั่น', 'success', 6000)
    else
        Notify('เมืองของคุณซื้อข่าวปล้นรถไฟ ไปรวมพลที่หมุดจุดซุ่ม', 'info', 6000)
    end
    dbg(('intel received ambush=%s isBuyer=%s'):format(a.id, tostring(data.isBuyer)))
end)

-- buyer heads to the ambush; when inside the radius, tell the server
CreateThread(function()
    while true do
        local wait = 1000
        if myAmbush then
            local d = #(GetEntityCoords(PlayerPedId()) - vector3(myAmbush.coords.x, myAmbush.coords.y, myAmbush.coords.z))
            if d <= Config.AmbushRadius then
                TriggerServerEvent('lp_railrobber:sv:reachedAmbush')
                Notify('ถึงจุดซุ่มแล้ว — ขบวนกำลังเข้ามา เตรียมตัว!', 'alert', 5000)
                myAmbush = nil -- fire once; server drives everything after this
            else
                wait = 500
            end
        end
        Wait(wait)
    end
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
    -- connecting/side doors by walking into them. (1 kept them shut; forcing them
    -- open with SetVehicleDoorOpen risked breaking them off — let the game do it.)
    CreateThread(function()
        Wait(600) -- carriages ready
        local cars = Citizen.InvokeNative(0x635423D55CA84FC8, p.hash) or 0
        for i = 0, math.max(0, cars - 1) do
            local car = Citizen.InvokeNative(0xD0FB093A4CDB932C, myTrain, i)
            if car and car ~= 0 and DoesEntityExist(car) then
                Citizen.InvokeNative(0x96F78A6A075D55D9, car, 0) -- SET_VEHICLE_DOORS_LOCKED (0 = NONE)
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

-- ── OWNER: spawn a guard wave — but ONLY once a player gets near the guard car ─
RegisterNetEvent('lp_railrobber:cl:spawnWave', function(w)
    if not isOwner or myTrain == 0 then return end
    CreateThread(function()
        -- proximity gate: hold the wave until a player is close to the guard carriage
        -- (fixes the "guards pop in all at once the instant the train spawns" timing)
        while isOwner and myTrain ~= 0 and DoesEntityExist(myTrain) do
            local car = Citizen.InvokeNative(0xD0FB093A4CDB932C, myTrain, w.carriage)
            if not car or car == 0 then car = myTrain end
            local cc = GetEntityCoords(car)
            local near = false
            for _, pl in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(pl)
                if ped and ped ~= 0 and DoesEntityExist(ped) and #(GetEntityCoords(ped) - cc) <= Config.GuardSpawnRange then
                    near = true; break
                end
            end
            if near then break end
            Wait(400)
        end
        if not (isOwner and myTrain ~= 0 and DoesEntityExist(myTrain)) then return end

        local carriage = Citizen.InvokeNative(0xD0FB093A4CDB932C, myTrain, w.carriage)
        if not carriage or carriage == 0 then carriage = myTrain end
        if not loadModel(w.model) then return end

        -- NOT attached: the spike proved a ped standing on a moving carriage roof
        -- is carried by the vehicle's own collision (same as the player in /rrtop)
        -- with no AttachEntityToEntity needed. Attach was what froze them in place
        -- (position pinned every frame -> combat task couldn't move them at all).
        -- We spawn them at a world position derived from the carriage's own
        -- heading, so the offset is still relative to the car, just not attached.
        local ga = Config.GuardAttach
        local carCoords = GetEntityCoords(carriage)
        local carHeading = GetEntityHeading(carriage)
        local rad = math.rad(carHeading)
        local cosA, sinA = math.cos(rad), math.sin(rad)

        guards = {}
        for i = 1, w.count do
            local lx, ly = ga.x, ga.startY + (i * ga.spacingY)
            local wx = carCoords.x + (lx * cosA - ly * sinA)
            local wy = carCoords.y + (lx * sinA + ly * cosA)
            local wz = carCoords.z + ga.z

            local ped = CreatePed(w.model, wx, wy, wz, carHeading, true, true, false, false)
            Wait(0)
            Citizen.InvokeNative(0x283978A15512B2FE, ped, true) -- SetRandomOutfitVariation (else invisible)
            Wait(120)
            local net = PedToNet(ped)
            if SetNetworkIdExistsOnAllMachines then SetNetworkIdExistsOnAllMachines(net, true) end
            SetPedRelationshipGroupHash(ped, GUARD_GRP) -- ally to other guards, hostile to players
            SetEntityInvincible(ped, false)
            SetPedCanRagdoll(ped, false)
            GiveWeaponToPed(ped, w.weapon, 250, false, true)
            SetCurrentPedWeapon(ped, w.weapon, true)
            TaskCombatPed(ped, PlayerPedId(), 0, 16)
            guards[#guards + 1] = ped
        end
        dbg(('spawned guard wave %d (%d peds) — player reached the car'):format(w.wave, #guards))

        -- watch for the wave being wiped, then report it
        while true do
            Wait(1500)
            if not isOwner then return end
            local alive = 0
            for _, ped in ipairs(guards) do
                if ped and DoesEntityExist(ped) and not IsEntityDead(ped) then alive = alive + 1 end
            end
            if alive == 0 then TriggerServerEvent('lp_railrobber:sv:waveCleared', w.wave); return end
        end
    end)
end)

-- ── OWNER: stop the train (end of PvE / Stage 2 breach handoff) ──────────────
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
        -- report the MIDDLE carriage as the hold centre once it has actually slowed
        -- (train origin is the loco — a long train's rear would fall outside the radius)
        CreateThread(function()
            Wait(4000)
            if myTrain ~= 0 and DoesEntityExist(myTrain) then
                local cars = Citizen.InvokeNative(0x635423D55CA84FC8, Config.TrainHash) or 0
                local midCar = Citizen.InvokeNative(0xD0FB093A4CDB932C, myTrain, math.floor(cars / 2))
                local c = (midCar and midCar ~= 0 and DoesEntityExist(midCar)) and GetEntityCoords(midCar) or GetEntityCoords(myTrain)
                TriggerServerEvent('lp_railrobber:sv:trainStopped', { x = c.x, y = c.y, z = c.z })
            end
        end)
    end
    Notify('เคลียร์ยามครบแล้ว! ขบวนกำลังหยุด — เข้าไปงัดตู้', 'success', 6000)
    dbg('train stopping — breach phase')
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

-- ── STAGE 2: breach loot cars (any client) ─────────────────────────────────
local lootCarriages = nil
local breaching = false

RegisterNetEvent('lp_railrobber:cl:beginBreach', function(cars)
    lootCarriages = cars
    Notify('เคลียร์ยามแล้ว! เข้าไปงัดตู้สินค้า (E)', 'info', 6000)
end)

local function resolveTrain()
    local gs = GlobalState.lp_railrobber
    if not gs or not gs.trainNet or not NetworkDoesNetworkIdExist(gs.trainNet) then return 0 end
    local ent = NetworkGetEntityFromNetworkId(gs.trainNet)
    return (ent ~= 0 and DoesEntityExist(ent)) and ent or 0
end

local breachShown = false
CreateThread(function()
    while true do
        local wait = 600
        local gs = GlobalState.lp_railrobber
        if gs and gs.state == Config.States.BREACHING and lootCarriages and not breaching then
            local train = resolveTrain()
            if train ~= 0 then
                wait = 250
                local pc = GetEntityCoords(PlayerPedId())
                local nearIdx
                for _, idx in ipairs(lootCarriages) do
                    if not (gs.breached and gs.breached[idx]) then
                        local car = Citizen.InvokeNative(0xD0FB093A4CDB932C, train, idx)
                        if car and car ~= 0 and DoesEntityExist(car) and #(pc - GetEntityCoords(car)) <= Config.BreachRange then
                            nearIdx = idx; break
                        end
                    end
                end
                if nearIdx and not breachShown then
                    breachShown = true
                    exports.lp_textui:TextUIHold('[E] งัดตู้สินค้า', Config.HoldMs, function()
                        breachShown = false
                        breaching = true
                        exports.lp_progbar:Progress({
                            duration = Config.BreachDurationMs,
                            label = 'กำลังงัดตู้...',
                            controlDisables = { disableMovement = true },
                            animation = { animDict = 'script_common@jail_cell@unlock@key', anim = 'action', flags = 1 },
                        }, function(cancelled)
                            breaching = false
                            if not cancelled then TriggerServerEvent('lp_railrobber:sv:breachCar', nearIdx) end
                        end)
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

-- ── STAGE 2 (scope cut): simple countdown HUD after a successful breach ─────
-- No city-vs-city capture bar for now — just a payout countdown for the breacher.
local holdHudUp = false
CreateThread(function()
    while true do
        local gs = GlobalState.lp_railrobber
        if gs and gs.state == Config.States.HOLD then
            local rem = gs.holdRemaining or 0
            exports.lp_textui:TextUI(('🚂 งัดตู้สำเร็จ! กำลังรับรางวัลใน %02d:%02d'):format(math.floor(rem / 60), rem % 60))
            holdHudUp = true
            Wait(1000)
        else
            if holdHudUp then exports.lp_textui:HideUI(); holdHudUp = false end
            Wait(500)
        end
    end
end)

-- ── teardown (owner) ────────────────────────────────────────────────────────
local function teardown()
    isOwner = false
    for _, ped in ipairs(guards) do
        if ped and DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    guards = {}
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
    lootCarriages = nil
    breaching = false
    if breachShown then exports.lp_textui:CancelHold(); breachShown = false end
    if holdHudUp then exports.lp_textui:HideUI(); holdHudUp = false end
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
