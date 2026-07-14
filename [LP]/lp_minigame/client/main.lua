--[[
    lp_minigame — skill-check minigames, blocking export API

    exports.lp_minigame:Spacebar(opts)  -> true/false
    exports.lp_minigame:Sequence(opts)  -> true/false
    exports.lp_minigame:Fishing(opts)   -> true/false
    exports.lp_minigame:Circle(opts)    -> true/false
    exports.lp_minigame:Lockpick(opts)  -> true/false
    exports.lp_minigame:Cancel()        -- resolves the active minigame as false

    opts overrides individual fields on top of Config.Spacebar / Config.Sequence
    (see config.lua for the full field list + examples).
]]

local active   = false
local resolved = false
local result   = false

local function disableThread()
    Citizen.CreateThread(function()
        while active do
            if Config.DisableControls then
                Config.DisableControls()
            end
            Citizen.Wait(0)
        end
    end)
end

local function play(kind, base, opts)
    if active then return false end
    opts = opts or {}

    local cfg = {}
    for k, v in pairs(base) do cfg[k] = v end
    for k, v in pairs(opts) do cfg[k] = v end

    active   = true
    resolved = false
    result   = false

    SendNUIMessage({ action = 'lp_minigame:open', kind = kind, cfg = cfg })
    -- lockpick ต้องเล็งด้วยเมาส์ → เปิด cursor; ตัวอื่นใช้ focus แบบไม่มีเมาส์
    SetNuiFocus(true, cfg.cursor == true)
    disableThread()

    while not resolved do Citizen.Wait(10) end

    active = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'lp_minigame:close' })
    return result
end

exports('Spacebar', function(opts)
    return play('spacebar', Config.Spacebar, opts)
end)

exports('Sequence', function(opts)
    return play('sequence', Config.Sequence, opts)
end)

exports('Fishing', function(opts)
    return play('fishing', Config.Fishing, opts)
end)

exports('Circle', function(opts)
    return play('circle', Config.Circle, opts)
end)

exports('Lockpick', function(opts)
    return play('lockpick', Config.Lockpick, opts)
end)

exports('Cancel', function()
    if active then
        result   = false
        resolved = true
    end
end)

RegisterNUICallback('lp_minigame:finish', function(data, cb)
    result   = data.success == true
    resolved = true
    cb('ok')
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and active then
        result   = false
        resolved = true
    end
end)

-- ── Test command (F8 console) ───────────────────────────────────────────
-- /minigame_test spacebar   /minigame_test sequence   /minigame_test fishing   /minigame_test circle

RegisterCommand('minigame_test', function(_, args)
    local kind = args[1] or 'spacebar'
    Citizen.CreateThread(function()
        local ok
        if kind == 'sequence' then
            ok = exports.lp_minigame:Sequence()
        elseif kind == 'fishing' then
            ok = exports.lp_minigame:Fishing()
        elseif kind == 'circle' then
            ok = exports.lp_minigame:Circle()
        elseif kind == 'lockpick' then
            ok = exports.lp_minigame:Lockpick()
        else
            ok = exports.lp_minigame:Spacebar()
        end
        print(('[lp_minigame] %s result: %s'):format(kind, tostring(ok)))
    end)
end, false)
