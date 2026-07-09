-- cl_nui.lua — NUI bridge (open/close + callbacks + server→NUI relay)

local isOpen = false

-- ── Open / Close ──────────────────────────────────────────────────────────────
function OpenMarketUI()
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action       = 'open',
        theme        = Config.Theme,
        categories   = Config.Categories,
        currencies   = Config.AllowedCurrencies,
        durations    = Config.DurationOptions,
        taxRate      = Config.TaxRate,
        taxMin       = Config.TaxMin,
        itemsPerPage = Config.ItemsPerPage,
    })
end

function CloseMarketUI()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    -- ยังยืนอยู่ในโซน → arm hold hint (lp_textui) กลับมาอีกครั้ง (cl_main.lua)
    if OnMarketUIClosed then OnMarketUIClosed() end
end

-- ── NUI Callbacks (NUI → Lua) ──────────────────────────────────────────────────
RegisterNUICallback('closeUI', function(_, cb)
    CloseMarketUI(); cb('ok')
end)

RegisterNUICallback('getListings', function(data, cb)
    TriggerServerEvent('lp_marketplace:getListings', data); cb('ok')
end)

RegisterNUICallback('getMyListings', function(_, cb)
    TriggerServerEvent('lp_marketplace:getMyListings'); cb('ok')
end)

RegisterNUICallback('getItemClaims', function(_, cb)
    TriggerServerEvent('lp_marketplace:getItemClaims'); cb('ok')
end)

RegisterNUICallback('getInventory', function(_, cb)
    TriggerServerEvent('lp_marketplace:getInventory'); cb('ok')
end)

RegisterNUICallback('listItem', function(data, cb)
    TriggerServerEvent('lp_marketplace:listItem', data); cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
    TriggerServerEvent('lp_marketplace:buyItem', data.id, tonumber(data.qty) or 1); cb('ok')
end)

RegisterNUICallback('cancelListing', function(data, cb)
    TriggerServerEvent('lp_marketplace:cancelListing', data.id); cb('ok')
end)

RegisterNUICallback('claimItem', function(data, cb)
    TriggerServerEvent('lp_marketplace:claimItem', data.id); cb('ok')
end)

-- ── Server → NUI ───────────────────────────────────────────────────────────────
RegisterNetEvent('lp_marketplace:receiveListings')
AddEventHandler('lp_marketplace:receiveListings', function(data)
    if isOpen then SendNUIMessage({ action = 'receiveListings', data = data }) end
end)

RegisterNetEvent('lp_marketplace:receiveMyListings')
AddEventHandler('lp_marketplace:receiveMyListings', function(listings)
    if isOpen then SendNUIMessage({ action = 'receiveMyListings', listings = listings }) end
end)

RegisterNetEvent('lp_marketplace:receiveItemClaims')
AddEventHandler('lp_marketplace:receiveItemClaims', function(claims)
    if isOpen then SendNUIMessage({ action = 'receiveItemClaims', claims = claims }) end
end)

RegisterNetEvent('lp_marketplace:receiveInventory')
AddEventHandler('lp_marketplace:receiveInventory', function(inventory)
    if isOpen then SendNUIMessage({ action = 'receiveInventory', inventory = inventory }) end
end)

RegisterNetEvent('lp_marketplace:refreshBuy')
AddEventHandler('lp_marketplace:refreshBuy', function()
    if isOpen then SendNUIMessage({ action = 'refreshBuy' }) end
end)

RegisterNetEvent('lp_marketplace:refreshSell')
AddEventHandler('lp_marketplace:refreshSell', function()
    if isOpen then SendNUIMessage({ action = 'refreshSell' }) end
end)

RegisterNetEvent('lp_marketplace:refreshItem')
AddEventHandler('lp_marketplace:refreshItem', function()
    if isOpen then SendNUIMessage({ action = 'refreshItem' }) end
end)
