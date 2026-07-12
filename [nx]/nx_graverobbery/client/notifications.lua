NX_GR = NX_GR or {}

function NX_GR.Notify(message, notifyType, duration)
    if lib and lib.notify then
        lib.notify({
            description = message,
            type = notifyType or 'inform',
            duration = duration or 4000,
        })
        return
    end

    TriggerEvent('vorp:TipRight', message, duration or 4000)
end
