-- client/cl_outfit.lua
-- Apply/remove the city-badge shirt (toggle) when a badge item is used.
--
-- RDR2 civilian clothing (Shirt category) is NOT the classic GTA5
-- component/drawable/texture/palette system — it's vorp_character's
-- MetaPed asset-hash tag, applied via exports.vorp_character:SetShirtTag
-- and read back via exports.vorp_character:GetShirtTag (thin wrappers
-- around the same natives vorp_character's own character creator uses).

-- currently-worn badge city id, or nil if wearing the player's own shirt
local wearingCityId = nil
-- snapshot of the shirt tag the player had on before the first badge swap
local previousShirtTag = nil

local function ApplyShirtWithFade(shirtTag, notifyText)
    local fadeTime = Config.OutfitFadeTime

    DoScreenFadeOut(fadeTime)
    Wait(fadeTime + 100)

    exports.vorp_character:SetShirtTag(shirtTag)

    Wait(200)
    DoScreenFadeIn(fadeTime)

    exports.pNotify:SendNotification({
        type    = 'success',
        text    = notifyText,
        timeout = 3000,
    })
end

-- ─────────────────────────────────────────────────────────────
--  EVENT: Server authorised outfit toggle (put on / take off)
-- ─────────────────────────────────────────────────────────────
RegisterNetEvent("nx_cityselect:Client:ApplyOutfit")
AddEventHandler("nx_cityselect:Client:ApplyOutfit", function(outfitData)
    if not outfitData or not outfitData.shirtTag then return end

    CreateThread(function()
        if wearingCityId == outfitData.cityId then
            -- same badge used again -> take it off, restore what they had before
            ApplyShirtWithFade(previousShirtTag, Lang.notify_outfit_removed or 'ถอดเสื้อประจำเมืองแล้ว')
            wearingCityId = nil
            previousShirtTag = nil
            return
        end

        if wearingCityId == nil then
            -- first swap this session -> remember the original shirt
            previousShirtTag = exports.vorp_character:GetShirtTag()
        end

        ApplyShirtWithFade(outfitData.shirtTag, Lang.notify_outfit_changed:format(outfitData.label or outfitData.cityName or ""))
        wearingCityId = outfitData.cityId
    end)
end)
