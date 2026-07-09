RegisterNetEvent('lp_itemnotify:show')
AddEventHandler('lp_itemnotify:show', function(data)
    SendNUIMessage({
        action   = 'lp_itemnotify:show',
        image    = data.image,
        name     = data.name,
        label    = data.label,
        qtyText  = data.qtyText,
        duration = data.duration,
    })
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    SendNUIMessage({ action = 'lp_itemnotify:init', imgPath = 'nui://vorp_inventory/html/img/items/' })
end)
