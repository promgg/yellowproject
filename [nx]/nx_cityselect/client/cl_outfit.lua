-- client/cl_outfit.lua
-- Apply city outfit when badge item is used

-- ─────────────────────────────────────────────────────────────
--  INTERNAL: Fade screen to black, apply outfit, fade back
-- ─────────────────────────────────────────────────────────────
local function ApplyOutfitWithFade(outfitData)
    local ped      = PlayerPedId()
    local fadeTime = Config.OutfitFadeTime

    -- Fade out
    DoScreenFadeOut(fadeTime)
    Wait(fadeTime + 100)

    -- Apply component variations
    if outfitData.outfit then
        for _, comp in ipairs(outfitData.outfit) do
            local compId    = comp[1]
            local drawable  = comp[2]
            local texture   = comp[3]
            local palette   = comp[4] or 0
            if compId >= 0 and drawable >= 0 then
                SetPedComponentVariation(ped, compId, drawable, texture, palette)
            end
        end
    end

    -- Apply prop variations
    if outfitData.outfitProps then
        for _, prop in ipairs(outfitData.outfitProps) do
            local propId   = prop[1]
            local drawable = prop[2]
            local texture  = prop[3]
            if propId >= 0 and drawable >= 0 then
                SetPedPropIndex(ped, propId, drawable, texture, true)
            end
        end
    end

    Wait(200)

    -- Fade in
    DoScreenFadeIn(fadeTime)

    -- Notify
    exports.pNotify:SendNotification({
        type    = 'success',
        text    = Lang.notify_outfit_changed:format(outfitData.label or outfitData.cityName or ""),
        timeout = 3000,
    })
end

-- ─────────────────────────────────────────────────────────────
--  EVENT: Server authorised outfit apply
-- ─────────────────────────────────────────────────────────────
RegisterNetEvent("nx_cityselect:Client:ApplyOutfit")
AddEventHandler("nx_cityselect:Client:ApplyOutfit", function(outfitData)
    if not outfitData then return end
    CreateThread(function()
        ApplyOutfitWithFade(outfitData)
    end)
end)
