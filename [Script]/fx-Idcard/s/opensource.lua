local function isAllowed(src)
    return src == 0 or (FXIsAdmin and FXIsAdmin(src))
end

RegisterCommand(Config.Commands.resetAll, function(src, args)
    if not isAllowed(src) then
        return Notify({ source = src, text = Locale("noPermission"), type = "error", time = 5000 })
    end

    if tostring(args[1] or ""):lower() ~= "confirm" then
        if src == 0 then
            print(Locale("resetUsage", { command = Config.Commands.resetAll }))
        else
            Notify({
                source = src,
                text = Locale("resetUsage", { command = Config.Commands.resetAll }),
                type = "error",
                time = 7000,
            })
        end
        return
    end

    local ok = FXIDCardResetAll(src)
    local message = ok and Locale("resetSuccess") or Locale("databaseError")

    if src == 0 then
        print(message)
    else
        Notify({ source = src, text = message, type = ok and "success" or "error", time = 7000 })
    end
end, false)

RegisterCommand(Config.Commands.delete, function(src, args)
    if not isAllowed(src) then
        return Notify({ source = src, text = Locale("noPermission"), type = "error", time = 5000 })
    end

    local target = tonumber(args[1])
    if not target or not GetPlayerName(target) then
        local message = Locale("deleteUsage", { command = Config.Commands.delete })
        if src == 0 then print(message) else Notify({ source = src, text = message, type = "error", time = 5000 }) end
        return
    end

    local ok = FXIDCardDeleteTarget(src, target)
    local message = ok and Locale("deleteSuccess") or Locale("noCard")
    if src == 0 then
        print(message)
    else
        Notify({ source = src, text = message, type = ok and "success" or "error", time = 5000 })
    end
end, false)
