NX_GR = NX_GR or {}

local shovelObject
local activeBlips = {}

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    local deadline = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        Wait(50)
        if GetGameTimer() > deadline then return false end
    end
    return true
end

local function loadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    RequestModel(hash)
    local deadline = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        Wait(50)
        if GetGameTimer() > deadline then return nil end
    end
    return hash
end

local function attachShovel(ped, cfg)
    local hash = loadModel(cfg.shovelModel)
    if not hash then return false end

    local coords = GetEntityCoords(ped)
    local boneIndex = GetEntityBoneIndexByName(ped, cfg.attachBone or 'SKEL_R_Hand')
    shovelObject = CreateObject(hash, coords.x, coords.y, coords.z, true, true, true)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    AttachEntityToEntity(
        shovelObject,
        ped,
        boneIndex,
        cfg.attachOffset.x,
        cfg.attachOffset.y,
        cfg.attachOffset.z,
        cfg.attachRotation.x,
        cfg.attachRotation.y,
        cfg.attachRotation.z,
        true,
        true,
        false,
        true,
        1,
        true
    )
    SetModelAsNoLongerNeeded(hash)
    return true
end

function NX_GR.CleanupAnimation()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)

    if shovelObject and DoesEntityExist(shovelObject) then
        DeleteObject(shovelObject)
    end
    shovelObject = nil

    if lib and lib.hideTextUI then
        lib.hideTextUI()
    end
end

function NX_GR.PlayDigSession(payload)
    local ped = PlayerPedId()
    local cfg = payload.animation or Config.Digging

    if not loadAnimDict(cfg.animDict) then
        TriggerServerEvent('nx_graverobbery:server:cancel', payload.token, 'anim_load_failed')
        return
    end

    if not attachShovel(ped, cfg) then
        TriggerServerEvent('nx_graverobbery:server:cancel', payload.token, 'prop_load_failed')
        return
    end

    FreezeEntityPosition(ped, true)
    TaskPlayAnim(ped, cfg.animDict, cfg.animName, 3.0, 3.0, -1, 1, 0, false, false, false)

    local progressOk = lib.progressBar({
        duration = payload.durationMs or Config.Digging.durationMs,
        label = NX_GR.Locale('digging'),
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, car = true },
    })

    NX_GR.CleanupAnimation()

    if not progressOk then
        TriggerServerEvent('nx_graverobbery:server:cancel', payload.token, 'progress_cancelled')
        NX_GR.Notify(NX_GR.Locale('cancelled'), 'warning')
        return
    end

    local skillOk = true
    if payload.skillCheck and payload.skillCheck.enabled then
        skillOk = lib.skillCheck(payload.skillCheck.difficulty, payload.skillCheck.keys)
    end

    if not skillOk then
        TriggerServerEvent('nx_graverobbery:server:cancel', payload.token, 'skill_failed')
        NX_GR.Notify(NX_GR.Locale('failed'), 'error')
        return
    end

    TriggerServerEvent('nx_graverobbery:server:complete', payload.token)
end

function NX_GR.PlayPray(payload)
    local ped = PlayerPedId()
    local anims = Config.Pray.animations
    local anim = anims[math.random(#anims)]

    if not loadAnimDict(anim.dict) then return end

    TaskPlayAnim(ped, anim.dict, anim.name, 3.0, 3.0, payload.durationMs or 8000, 1, 0, false, false, false)
    if lib and lib.progressBar then
        lib.progressBar({
            duration = payload.durationMs or 8000,
            label = NX_GR.Locale('praying'),
            useWhileDead = false,
            canCancel = true,
            disable = { move = false, combat = true, car = true },
        })
    else
        Wait(payload.durationMs or 8000)
    end
    ClearPedTasks(ped)
end

function NX_GR.ReceiveAlert(payload)
    NX_GR.Notify(NX_GR.Locale('alert_message'), 'error', 10000)

    local coords = payload.coords
    if not coords then return end

    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, coords.x, coords.y, coords.z)
    Citizen.InvokeNative(0x74F74D3207ED525C, blip, 1702671897, true)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, CreateVarString(10, 'LITERAL_STRING', NX_GR.Locale('alert_blip')))
    activeBlips[#activeBlips + 1] = blip

    if payload.routeEnabled then
        StartGpsMultiRoute(GetHashKey('COLOR_RED'), true, true)
        AddPointToGpsMultiRoute(coords.x, coords.y, coords.z)
        SetGpsMultiRouteRender(true)
    end

    SetTimeout((payload.blipDuration or 60) * 1000, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
        ClearGpsMultiRoute()
    end)
end

function NX_GR.CleanupBlips()
    for _, blip in ipairs(activeBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    activeBlips = {}
    ClearGpsMultiRoute()
end
