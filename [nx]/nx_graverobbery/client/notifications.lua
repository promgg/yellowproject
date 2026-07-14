NX_GR = NX_GR or {}

function NX_GR.Notify(message, notifyType, duration)
    exports.pNotify:SendNotification({
        type = notifyType or 'info',
        text = message,
        timeout = duration or 4000,
    })
end
