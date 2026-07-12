local MenuData = exports.vorp_menu:GetMenuData()
local hasTextUI = GetResourceState('lp_textui') == 'started'
local RESOURCE = GetCurrentResourceName()

local nearStation = nil
local promptShown = false
local uiOpen = false

local previewCam = nil
local previewObj = nil
local previewWeaponName = nil
local previewActive = false
local previewDesired = nil
local previewHeading = 90.0
local previewSpawn = nil
local previewComps = nil
local previewShownKey = nil
local shownSlotComp = {}

local requestBusy = false
local sessionDirty = false
local customized = {}
local pendingPick = nil

local myComponents = {}
local lastAppliedHash = nil

local function notify(msg, msgType)
    exports.pNotify:SendNotification({ type = msgType or 'error', text = msg, timeout = 4000 })
end

local function findNearestStation(coords)
    local nearest, nearestDist = nil, Config.InteractDistance
    for _, station in ipairs(Config.Stations) do
        local dist = #(coords - station.coords)
        if dist <= nearestDist then
            nearest, nearestDist = station, dist
        end
    end
    return nearest
end

local function showPrompt()
    if promptShown or not nearStation then return end
    promptShown = true
    if hasTextUI then
        local station = nearStation
        exports.lp_textui:TextUIHold('[E] ปรับแต่งอาวุธ', Config.HoldMs, function()
            promptShown = false
            sessionDirty = false
            customized = {}
            pendingPick = nil
            TriggerEvent(RESOURCE .. ':openWeaponMenu')
        end, nil, { coords = station.coords, offset = vector3(0.0, 0.0, 0.3) })
    end
end

local function hidePrompt()
    if not promptShown then return end
    promptShown = false
    if hasTextUI then
        exports.lp_textui:CancelHold()
        exports.lp_textui:HideUI()
    end
end

local function loadComponentModel(compHash)
    local mdl = GetWeaponComponentTypeModel(compHash)
    if mdl and mdl ~= 0 then
        RequestModel(mdl)
        local t = GetGameTimer()
        while not HasModelLoaded(mdl) and (GetGameTimer() - t) < 1000 do Wait(0) end
        SetModelAsNoLongerNeeded(mdl)
    end
end

-- Re-applies a weapon's saved components to the ped's held weapon and renders them
-- (GiveWeaponComponentToPed only registers a part; ApplyShopItemToPed is what draws it).
-- Yields; run in a thread.
local function refreshHeldWeapon(weaponName, components)
    local ped = PlayerPedId()
    local wHash = joaat(weaponName)
    components = components or {}

    Citizen.InvokeNative(0xADF692B254977C0C, ped, wHash, true, false, false, false) -- SET_CURRENT_PED_WEAPON
    Wait(250)

    local _, held = GetCurrentPedWeapon(ped, true, 0, true)
    if held ~= wHash then return end

    local slots = Config.Components[weaponName]
    if slots then
        for slot, options in pairs(slots) do
            if not Config.EssentialSlots[slot] then
                for _, comp in ipairs(options) do
                    Citizen.InvokeNative(0x19F70C4D80494FF8, ped, joaat(comp), wHash) -- RemoveWeaponComponentFromPed
                end
            end
        end
    end

    for _, comp in ipairs(components) do
        local compHash = joaat(comp)
        local mdl = GetWeaponComponentTypeModel(compHash)
        if mdl and mdl ~= 0 then
            RequestModel(mdl)
            local t = GetGameTimer()
            while not HasModelLoaded(mdl) and (GetGameTimer() - t) < 5000 do Wait(0) end
        end
        Citizen.InvokeNative(0x74C9090FDD1BB48E, ped, compHash, wHash, true) -- GiveWeaponComponentToPed
        ApplyShopItemToPed(ped, compHash, true, true, true)
        if mdl and mdl ~= 0 then SetModelAsNoLongerNeeded(mdl) end
    end

    Citizen.InvokeNative(0x76A18844E743BF91, ped) -- refresh ped weapon visual
end

local function freezePlayer(state)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, state)
    SetEntityInvincible(ped, state)
    SetBlockingOfNonTemporaryEvents(ped, state)
end

local function stopPreviewCam()
    if not previewActive then return end
    previewActive = false

    RenderScriptCams(false, true, 300, true, true)
    if previewCam and DoesCamExist(previewCam) then
        DestroyCam(previewCam, false)
    end
    previewCam = nil

    if previewObj and DoesEntityExist(previewObj) then
        SetEntityAsMissionEntity(previewObj, true, true)
        DeleteObject(previewObj)
        DeleteEntity(previewObj)
    end
    previewObj = nil
    previewWeaponName = nil

    ClearFocus()
    freezePlayer(false)
end

local function deriveSlotMap(weaponName, comps)
    local map = {}
    local slots = Config.Components[weaponName]
    if not slots or not comps then return map end
    local has = {}
    for _, c in pairs(comps) do has[c] = true end
    for slot, options in pairs(slots) do
        for _, c in ipairs(options) do
            if has[c] then map[slot] = c break end
        end
    end
    return map
end

-- Builds the floating weapon object at `spawn` with the given components. Does not touch the
-- camera/focus/turntable (owned by startPreviewForWeapon). Yields; caller is serialized.
local function spawnPreviewObject(weapon, spawn, comps)
    local weaponHash = joaat(weapon.name)
    comps = comps or weapon.activeComponents

    RequestWeaponAsset(weaponHash, 31, 0)
    local t = GetGameTimer()
    while not HasWeaponAssetLoaded(weaponHash) and (GetGameTimer() - t) < 5000 do Wait(0) end

    local obj
    for _ = 1, 2 do
        obj = Citizen.InvokeNative(0x9888652B8BA77F73, weaponHash, 0, spawn.x, spawn.y, spawn.z, true, 1.0) -- CreateWeaponObject
        if obj and DoesEntityExist(obj) then break end
        Wait(250)
    end
    if not obj or not DoesEntityExist(obj) then return nil end

    SetEntityCollision(obj, false, false)
    FreezeEntityPosition(obj, true)
    SetEntityCoordsNoOffset(obj, spawn.x, spawn.y, spawn.z, false, false, false)
    SetEntityHeading(obj, previewHeading)
    SetEntityVisible(obj, true, false)

    if comps then
        for _, comp in pairs(comps) do
            local compHash = joaat(comp)
            loadComponentModel(compHash)
            Citizen.InvokeNative(0x74C9090FDD1BB48E, obj, compHash, weaponHash, true) -- GiveWeaponComponentToWeaponObject
        end
    end
    shownSlotComp = deriveSlotMap(weapon.name, comps)
    return obj
end

local function deletePreviewEntity(obj)
    if obj and DoesEntityExist(obj) then
        SetEntityAsMissionEntity(obj, true, true)
        DeleteObject(obj)
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
end

-- First-time preview setup for a weapon: spawns the object and builds the camera + turntable
-- once. Later weapon/component changes go through swapPreviewObject.
local function startPreviewForWeapon(weapon, comps)
    stopPreviewCam()
    previewActive = true
    previewWeaponName = weapon.name
    previewHeading = 90.0

    local anchor = (nearStation and nearStation.anchor) or Config.Stations[1].anchor
    local lane = (GetPlayerServerId(PlayerId()) % 64) * Config.Camera.laneSpacing
    previewSpawn = vector3(anchor.x + lane, anchor.y, anchor.z)

    SetFocusPosAndVel(previewSpawn.x, previewSpawn.y, previewSpawn.z, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(previewSpawn.x, previewSpawn.y, previewSpawn.z)
    freezePlayer(true)
    Wait(250)

    local obj = spawnPreviewObject(weapon, previewSpawn, comps)

    if previewDesired == nil or previewDesired.name ~= weapon.name then
        deletePreviewEntity(obj)
        stopPreviewCam()
        return
    end
    if not obj then
        stopPreviewCam()
        return
    end
    previewObj = obj

    local fwd, right, up, origin = table.unpack({ GetEntityMatrix(previewObj) })
    local camPos = origin - fwd * Config.Camera.distBack + right * Config.Camera.distSide + up * Config.Camera.distUp
    previewCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camPos.x, camPos.y, camPos.z, 0.0, 0.0, 0.0, Config.Camera.fov, false, 0)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 300, true, false)
    PointCamAtCoord(previewCam, origin.x, origin.y, origin.z + 0.05)

    CreateThread(function()
        while previewActive and previewObj and DoesEntityExist(previewObj) do
            previewHeading = (previewHeading + Config.Camera.turntableDegPerSec * GetFrameTime()) % 360.0
            SetEntityHeading(previewObj, previewHeading)
            Wait(0)
        end
    end)
    return true
end

-- Swaps the floating object (new weapon or component set) without rebuilding the camera:
-- build the new object first, then delete the old (no empty frame).
local function swapPreviewObject(weapon, comps)
    if not previewActive or not previewSpawn then
        return startPreviewForWeapon(weapon, comps)
    end
    previewWeaponName = weapon.name

    local newObj = spawnPreviewObject(weapon, previewSpawn, comps)
    if not newObj then return false end

    if not previewActive or previewDesired == nil then
        deletePreviewEntity(newObj)
        return false
    end

    local oldObj = previewObj
    previewObj = newObj
    deletePreviewEntity(oldObj)
    return true
end

local function warmWeaponAssets(weapons)
    CreateThread(function()
        for _, w in ipairs(weapons) do
            RequestWeaponAsset(joaat(w.name), 31, 0)
        end
    end)
end

local function previewKeyOf(weapon, comps)
    comps = comps or (weapon and weapon.activeComponents) or {}
    local arr = {}
    for _, c in pairs(comps) do arr[#arr + 1] = c end
    table.sort(arr)
    return (weapon and weapon.name or '') .. '|' .. table.concat(arr, ',')
end

local function requestPreview(weapon)
    previewDesired = weapon or nil
    previewComps = nil
end

local function requestPreviewComps(comps)
    previewComps = comps
end

local function clearPreview()
    previewDesired = nil
    previewComps = nil
    previewShownKey = nil
    shownSlotComp = {}
    stopPreviewCam()
end

-- Sole owner of the floating object: reconciles the desired weapon + component set once it has
-- settled (debounces fast scrolling). Being the only caller of start/swap avoids spawn races.
CreateThread(function()
    local stableKey, stableSince = nil, 0
    while true do
        Wait(50)
        local want = previewDesired
        if want then
            local key = previewKeyOf(want, previewComps)
            if key ~= stableKey then
                stableKey = key
                stableSince = GetGameTimer()
            elseif key ~= previewShownKey and (GetGameTimer() - stableSince) >= 90 then
                local ok
                if previewActive then
                    ok = swapPreviewObject(want, previewComps)
                else
                    ok = startPreviewForWeapon(want, previewComps)
                end
                if ok then previewShownKey = key end
            end
        else
            stableKey = nil
        end
    end
end)

local function closeAll()
    MenuData.CloseAll(true, true, true)
    clearPreview()
    uiOpen = false
end

local function slotCompList(weapon, slot, chosenComp)
    local list = {}
    for s, comp in pairs(weapon.activeComponents or {}) do
        if s ~= slot then list[#list + 1] = comp end
    end
    if chosenComp and chosenComp ~= '__remove' then
        list[#list + 1] = chosenComp
    elseif chosenComp == '__remove' and Config.EssentialSlots[slot] then
        local keep = weapon.activeComponents and weapon.activeComponents[slot]
        if keep then list[#list + 1] = keep end
    end
    return list
end

local function revertSlotPreview()
    requestPreviewComps(nil)
end

-- In-place component swap on the current object: remove the part the slot shows now, give the
-- new one (the give re-renders it). No rebuild, so the object stays put. Real components only;
-- a pure remove goes through requestPreviewComps (a rebuild) since a lone remove doesn't render.
local function previewComponentInPlace(weapon, slot, picked)
    local comps = slotCompList(weapon, slot, picked)
    previewComps = comps
    previewShownKey = previewKeyOf(weapon, comps)

    if not previewObj or not DoesEntityExist(previewObj) then
        previewShownKey = nil
        return
    end

    local wHash = joaat(weapon.name)
    local prev = shownSlotComp[slot]
    if prev then
        Citizen.InvokeNative(0x4899CB088EDF59B8, previewObj, joaat(prev)) -- RemoveWeaponComponentFromWeaponObject
    end
    local ch = joaat(picked)
    loadComponentModel(ch)
    Citizen.InvokeNative(0x74C9090FDD1BB48E, previewObj, ch, wHash, true) -- GiveWeaponComponentToWeaponObject
    shownSlotComp[slot] = picked
end

-- Leaves the gunsmith. If anything changed this visit, plays one progress bar (with a work
-- animation) then snaps the real weapon(s) to their new look. vorp_inventory is never modified.
local function exitGunsmith()
    closeAll()

    if not sessionDirty then return end
    sessionDirty = false
    local pending = customized
    customized = {}
    for _, entry in pairs(pending) do
        myComponents[entry.name] = entry.components
    end

    freezePlayer(true)
    exports.lp_progbar:Progress({
        duration = Config.ApplyProgress.duration,
        label = Config.ApplyProgress.label,
        canCancel = false,
        controlDisables = { disableMovement = true, disableCombat = true },
        animation = Config.ApplyProgress.animation,
    }, function()
        CreateThread(function()
            for _, entry in pairs(pending) do
                refreshHeldWeapon(entry.name, entry.components)
            end
            lastAppliedHash = false
            freezePlayer(false)
        end)
    end)
end

local function openComponentMenu(weapon, slot, options)
    MenuData.CloseAll(true, true, true)

    local elements = {}
    for _, componentName in ipairs(options) do
        elements[#elements + 1] = {
            label = componentName:gsub('^COMPONENT_', ''):gsub('_', ' '),
            value = componentName,
            desc = ('ราคา $%.2f'):format(Config.ComponentPrice),
        }
    end
    if not Config.EssentialSlots[slot] then
        elements[#elements + 1] = { label = 'ถอดชิ้นส่วนนี้ออก', value = '__remove', desc = ('ราคา $%.2f'):format(Config.RemoveComponentPrice) }
    end
    elements[#elements + 1] = { label = 'ย้อนกลับ', value = '__back' }

    MenuData.Open('default', RESOURCE, 'GunsmithComponents', {
        title = Config.SlotLabels[slot] or slot,
        subtext = weapon.label,
        align = 'top-left',
        elements = elements,
    }, function(data, menu)
        local picked = data.current and data.current.value
        if not picked then return end

        if picked == '__back' then
            revertSlotPreview()
            return TriggerEvent(RESOURCE .. ':openSlotMenu', weapon)
        end

        if requestBusy then
            notify(Config.Text.Busy, 'info')
            return openComponentMenu(weapon, slot, options)
        end
        requestBusy = true

        if picked == '__remove' then
            pendingPick = { weapon = weapon, slot = slot, options = options, isRemove = true }
            TriggerServerEvent('lp_gunsmith:sv:removeComponent', weapon.id, weapon.name, slot)
        else
            pendingPick = { weapon = weapon, slot = slot, options = options, component = picked }
            TriggerServerEvent('lp_gunsmith:sv:applyComponent', weapon.id, weapon.name, slot, picked)
        end

        openComponentMenu(weapon, slot, options)
    end, function(data, menu)
        menu.close(true, true, true)
        revertSlotPreview()
        TriggerEvent(RESOURCE .. ':openSlotMenu', weapon)
    end, function(data, menu)
        local picked = data.current and data.current.value
        if not picked or picked == '__back' then return end
        if picked == '__remove' then
            requestPreviewComps(slotCompList(weapon, slot, '__remove'))
        else
            previewComponentInPlace(weapon, slot, picked)
        end
    end)
end

-- weapon.components (raw component name array from loadout.components) -> activeComponents[slot].
local function buildActiveComponents(weapon)
    local slots = Config.Components[weapon.name]
    weapon.activeComponents = {}
    if not slots or not weapon.components then return weapon end

    local lookup = {}
    for _, comp in ipairs(weapon.components) do
        lookup[comp] = true
    end

    for slot, options in pairs(slots) do
        for _, comp in ipairs(options) do
            if lookup[comp] then
                weapon.activeComponents[slot] = comp
                break
            end
        end
    end

    return weapon
end

local function openSlotMenu(weapon)
    MenuData.CloseAll(true, true, true)
    local slots = Config.Components[weapon.name]
    if not slots then
        notify(Config.Text.InvalidComponent)
        return closeAll()
    end

    requestPreview(weapon)

    local elements = {}
    for slot, options in pairs(slots) do
        elements[#elements + 1] = {
            label = Config.SlotLabels[slot] or slot,
            value = slot,
            desc = ('%d ตัวเลือก'):format(#options),
        }
    end
    table.sort(elements, function(a, b) return a.label < b.label end)
    elements[#elements + 1] = { label = 'ย้อนกลับ', value = '__back' }

    MenuData.Open('default', RESOURCE, 'GunsmithSlots', {
        title = weapon.label,
        subtext = 'เลือกส่วนที่ต้องการปรับแต่ง',
        align = 'top-left',
        elements = elements,
    }, function(data, menu)
        local picked = data.current and data.current.value
        if not picked then return end
        if picked == '__back' then
            return TriggerEvent(RESOURCE .. ':openWeaponMenu')
        end
        openComponentMenu(weapon, picked, slots[picked])
    end, function(data, menu)
        menu.close(true, true, true)
        exitGunsmith()
    end)
end

RegisterNetEvent(RESOURCE .. ':openSlotMenu', function(weapon)
    openSlotMenu(weapon)
end)

local function openWeaponMenu()
    if not nearStation then return end

    uiOpen = true
    freezePlayer(true)
    TriggerServerEvent('lp_gunsmith:sv:requestWeaponList')
end

RegisterNetEvent(RESOURCE .. ':openWeaponMenu', openWeaponMenu)

RegisterNetEvent('lp_gunsmith:client:receiveWeaponList', function(weapons)
    if not weapons or #weapons == 0 then
        notify(Config.Text.NoWeapon)
        uiOpen = false
        freezePlayer(false)
        return
    end

    local elements = {}
    for _, w in ipairs(weapons) do
        buildActiveComponents(w)
        elements[#elements + 1] = {
            label = w.label,
            value = tostring(w.id),
            desc = w.name,
            weapon = w,
        }
    end

    MenuData.CloseAll(true, true, true)

    warmWeaponAssets(weapons)
    requestPreview(weapons[1])

    MenuData.Open('default', RESOURCE, 'GunsmithWeapons', {
        title = 'ช่างปืน',
        subtext = 'เลือกอาวุธที่ต้องการปรับแต่ง',
        align = 'top-left',
        elements = elements,
    }, function(data, menu)
        local current = data.current
        if not current or not current.weapon then return end
        openSlotMenu(current.weapon)
    end, function(data, menu)
        menu.close(true, true, true)
        exitGunsmith()
    end, function(data, menu)
        if data.current and data.current.weapon then
            requestPreview(data.current.weapon)
        end
    end)
end)

-- Per-pick server result: the server already validated/charged/wrote the DB. We only record the
-- change (applied once on exit), keep the open menu in sync, toast, and revert the preview on fail.
RegisterNetEvent('lp_gunsmith:client:applyResult', function(ok, message, weapon)
    requestBusy = false
    local pick = pendingPick
    pendingPick = nil

    if ok and weapon then
        sessionDirty = true
        customized[weapon.id] = { name = weapon.name, components = weapon.components }

        if pick and pick.weapon then
            pick.weapon.components = weapon.components
            buildActiveComponents(pick.weapon)
        end
        requestPreviewComps(nil)

        if pick and pick.isRemove then
            notify(('ถอดชิ้นส่วน (-$%.0f)'):format(Config.RemoveComponentPrice), 'success')
        elseif pick and pick.component then
            local nice = pick.component:gsub('^COMPONENT_', ''):gsub('_', ' ')
            notify(('ติดตั้ง %s (-$%.0f)'):format(nice, Config.ComponentPrice), 'success')
        else
            notify(message, 'success')
        end
    else
        local soft = (message == Config.Text.AlreadyEquipped) or (message == Config.Text.Busy)
        notify(message, soft and 'info' or 'error')
        revertSlotPreview()
    end
end)

-- Post-relog persistence: fetch this character's saved customizations on spawn, then re-apply
-- them each time a saved weapon becomes the one in hand (vorp_inventory stores them but doesn't
-- redraw). vorp:SelectedCharacter is a server-fired event, so it MUST be a RegisterNetEvent.
RegisterNetEvent('lp_gunsmith:client:myComponents', function(map)
    myComponents = map or {}
end)

RegisterNetEvent('vorp:SelectedCharacter', function()
    myComponents = {}
    lastAppliedHash = nil
    Wait(4000)
    TriggerServerEvent('lp_gunsmith:sv:requestMyComponents')
end)

CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        local _, curHash = GetCurrentPedWeapon(ped, true, 0, true)
        if curHash ~= lastAppliedHash then
            lastAppliedHash = curHash
            if curHash and curHash ~= `WEAPON_UNARMED` and next(myComponents) then
                for name, comps in pairs(myComponents) do
                    if joaat(name) == curHash and comps and #comps > 0 then
                        CreateThread(function() refreshHeldWeapon(name, comps) end)
                        break
                    end
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local station = findNearestStation(coords)

        if station then
            sleep = 500
            nearStation = station
            if not uiOpen then
                showPrompt()
            end
        else
            nearStation = nil
            hidePrompt()
        end

        Wait(sleep)
    end
end)

-- Sweeps stray preview weapon objects from each station's anchor lane (e.g. left by a crash),
-- with tight bounds so it never touches real props.
local function sweepPreviewOrphans()
    local maxLane = 64 * (Config.Camera.laneSpacing or 6)
    for _, obj in ipairs(GetGamePool('CObject')) do
        if DoesEntityExist(obj) then
            local oc = GetEntityCoords(obj)
            for _, station in ipairs(Config.Stations) do
                local a = station.anchor
                if math.abs(oc.z - a.z) < 2.0 and math.abs(oc.y - a.y) < 2.0
                    and (oc.x - a.x) > -2.0 and (oc.x - a.x) < (maxLane + 2.0) then
                    SetEntityAsMissionEntity(obj, true, true)
                    DeleteObject(obj)
                    if DoesEntityExist(obj) then DeleteEntity(obj) end
                    break
                end
            end
        end
    end
end

AddEventHandler('onResourceStart', function(res)
    if res ~= RESOURCE then return end
    sweepPreviewOrphans()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= RESOURCE then return end
    hidePrompt()
    clearPreview()
    sweepPreviewOrphans()
    MenuData.CloseAll(false, false, false)
end)
