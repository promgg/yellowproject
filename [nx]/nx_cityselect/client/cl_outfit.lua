-- client/cl_outfit.lua
-- Apply/remove the city-badge outfit (toggle) when a badge item is used.
--
-- RDR2 civilian clothing is NOT the classic GTA5 component/drawable/texture
-- system — it's vorp_character's MetaPed asset-hash tag. เราใช้ export กลาง
-- ของ vorp_character (SetClothingTag/GetClothingTag) ที่รับ "category" ได้
-- ตอนนี้ตั้งเป็น "Coat" เพราะบัตรควรเปลี่ยน "โค้ท" ไม่ใช่เสื้อเชิ้ตชั้นในที่โดนโค้ททับบัง

-- ใช้ category จาก config (ค่าเริ่มต้น Coat) — เปลี่ยนได้ที่ Config.OutfitCategory
local OUTFIT_CATEGORY = Config.OutfitCategory or "Coat"

-- currently-worn badge city id, or nil if wearing the player's own outfit
local wearingCityId = nil
-- snapshot of the tag the player had on before the first badge swap
local previousTag = nil

-- สลับ/ถอดโค้ทจริง — tag = nil หมายถึง "เดิมไม่ได้ใส่โค้ท" → ต้องถอด component ออก
-- ไม่ใช่ apply nil (apply nil ไม่ทำอะไร โค้ทเมืองจะค้าง = ถอดแล้วไม่กลับชุดเดิม)
local function swapCoat(tag)
    if tag then
        exports.vorp_character:SetClothingTag(OUTFIT_CATEGORY, tag)
    else
        exports.vorp_character:RemoveClothingTag(OUTFIT_CATEGORY)
    end
end

local function ApplyOutfitWithAnim(tag, notifyText)
    local ped = PlayerPedId()
    local a = Config.OutfitAnim

    -- เล่นท่าจัดเสื้อแล้วสลับโค้ทกลางท่า ให้มือบังจังหวะ swap แทนการเฟดจอดำ
    RequestAnimDict(a.dict)
    local t0 = GetGameTimer()
    while not HasAnimDictLoaded(a.dict) and (GetGameTimer() - t0) < 1000 do Wait(10) end

    if HasAnimDictLoaded(a.dict) then
        TaskPlayAnim(ped, a.dict, a.anim, 8.0, -8.0, a.duration, a.flag, 0, false, false, false)
        Wait(a.swapAt)          -- รอให้มือขยับขึ้นก่อน
        swapCoat(tag)
        Wait(a.duration - a.swapAt) -- ปล่อยท่าเล่นต่อจนจบ
        RemoveAnimDict(a.dict)
    else
        -- โหลดท่าไม่ขึ้น — สลับเลยไม่มีท่า (ยังทำงานได้ ไม่ค้าง)
        swapCoat(tag)
    end

    exports.pNotify:SendNotification({
        type    = 'success',
        text    = notifyText,
        timeout = 3000,
    })
end

-- ─────────────────────────────────────────────────────────────
--  EVENT: Server authorised outfit toggle (put on / take off)
-- ─────────────────────────────────────────────────────────────
-- เลือก tag ตามเพศของตัวละคร — โค้ทชาย/หญิงเป็นคน hash กัน ใส่ผิดเพศจะไม่ขึ้น
local function pickTag(outfitTag)
    if not outfitTag then return nil end
    -- รองรับทั้งแบบใหม่ { male=, female= } และแบบเก่า (tag เดี่ยว) เผื่อ config ยังไม่ได้แยกเพศ
    if outfitTag.male or outfitTag.female then
        return IsPedMale(PlayerPedId()) and outfitTag.male or outfitTag.female
    end
    return outfitTag
end

RegisterNetEvent("nx_cityselect:Client:ApplyOutfit")
AddEventHandler("nx_cityselect:Client:ApplyOutfit", function(outfitData)
    if not outfitData or not outfitData.outfitTag then return end

    CreateThread(function()
        if wearingCityId == outfitData.cityId then
            -- same badge used again -> take it off, restore what they had before
            ApplyOutfitWithAnim(previousTag, Lang.notify_outfit_removed or 'ถอดเสื้อประจำเมืองแล้ว')
            wearingCityId = nil
            previousTag = nil
            return
        end

        local tag = pickTag(outfitData.outfitTag)
        if not tag then return end

        if wearingCityId == nil then
            -- first swap this session -> remember the original outfit piece
            previousTag = exports.vorp_character:GetClothingTag(OUTFIT_CATEGORY)
        end

        ApplyOutfitWithAnim(tag, Lang.notify_outfit_changed:format(outfitData.label or outfitData.cityName or ""))
        wearingCityId = outfitData.cityId
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  DEBUG: เก็บค่า tag ของชิ้นที่ใส่อยู่ตอนนี้ (Config.Debug = true)
--  วิธีใช้: ใส่โค้ทที่อยากได้ในร้านตัดเสื้อ (เช่น Irwin Coat variation 9)
--  แล้วพิมพ์ /nxcapture ในเกม — จะได้บรรทัด outfitTag = {...} พร้อมวางลง config.lua
-- ─────────────────────────────────────────────────────────────
if Config.Debug then
    RegisterCommand('nxcapture', function(_, args)
        local category = args[1] or OUTFIT_CATEGORY
        local tag = exports.vorp_character:GetClothingTag(category)
        if not tag then
            print(('^1[nx_cityselect]^7 ไม่พบชิ้นในหมวด "%s" — ตอนนี้ไม่ได้ใส่อยู่'):format(category))
            return
        end
        -- ปรินต์เป็นบรรทัด male=/female= ตามเพศตัวละครตอนนี้ วางลง config ได้ตรงช่อง
        local genderKey = IsPedMale(PlayerPedId()) and "male" or "female"
        local line = ('%s = { drawable = %s, albedo = %s, normal = %s, material = %s, palette = %s, tint0 = %s, tint1 = %s, tint2 = %s },')
            :format(genderKey, tag.drawable, tag.albedo, tag.normal, tag.material, tag.palette, tag.tint0, tag.tint1, tag.tint2)
        print(('^2[nx_cityselect]^7 %s (%s) ที่ใส่อยู่:'):format(category, genderKey))
        print(line)
    end, false)
end
