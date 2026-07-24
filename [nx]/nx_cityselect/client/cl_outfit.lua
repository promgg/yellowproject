-- client/cl_outfit.lua
-- ใส่/ถอด "ชุดประจำเมือง" (โค้ท) — ใช้ได้ 2 ทาง:
--   1) กดใช้บัตรประจำเมือง (toggle ใส่/ถอด)
--   2) resource อื่นเรียก export ตอนเข้า/ออกโซนกิจกรรม (mj-airdrop / lp_airdropteam /
--      nx_graverobbery) ที่บังคับให้ใส่ชุดเมืองตัวเอง
--
-- RDR2 civilian clothing เป็น MetaPed asset-hash tag ของ vorp_character
-- เราใช้ export กลาง SetClothingTag/GetClothingTag/RemoveClothingTag ที่รับ category ได้
-- ตอนนี้ category = "Coat" (บัตรเปลี่ยนโค้ท ไม่ใช่เสื้อเชิ้ตชั้นในที่โดนโค้ททับบัง)

local OUTFIT_CATEGORY = Config.OutfitCategory or "Coat"

-- สถานะร่วมของทั้งไฟล์ (badge และ zone-export ใช้ตัวเดียวกัน = แหล่งความจริงเดียว):
--   wearingCityId : เมืองของชุดที่ใส่อยู่ตอนนี้ (nil = ใส่ชุดตัวเอง)
--   previousTag   : โค้ทเดิมของผู้เล่นก่อนใส่ชุดเมืองครั้งแรก (nil = เดิมไม่ได้ใส่โค้ท)
local wearingCityId = nil
local previousTag = nil

-- เลือก tag ตามเพศ — โค้ทชาย/หญิงคน hash กัน ใส่ผิดเพศจะไม่ขึ้น
local function pickTag(outfitTag)
    if not outfitTag then return nil end
    -- รองรับทั้ง { male=, female= } และ tag เดี่ยว (เผื่อ config ยังไม่แยกเพศ)
    if outfitTag.male or outfitTag.female then
        return IsPedMale(PlayerPedId()) and outfitTag.male or outfitTag.female
    end
    return outfitTag
end

-- สลับ/ถอดโค้ทจริง — tag = nil หมายถึง "เดิมไม่ได้ใส่โค้ท" → ถอด component ออก
-- ไม่ใช่ apply nil (apply nil ไม่ทำอะไร โค้ทเมืองจะค้าง = ถอดแล้วไม่กลับชุดเดิม)
local function swapCoat(tag)
    if tag then
        exports.vorp_character:SetClothingTag(OUTFIT_CATEGORY, tag)
    else
        exports.vorp_character:RemoveClothingTag(OUTFIT_CATEGORY)
    end
end

-- เล่นท่าจัดเสื้อแล้วสลับโค้ทกลางท่า ให้มือบังจังหวะ swap แทนการเฟดจอดำ
local function playSwapAnim(tag, notifyText)
    local ped = PlayerPedId()
    local a = Config.OutfitAnim

    RequestAnimDict(a.dict)
    local t0 = GetGameTimer()
    while not HasAnimDictLoaded(a.dict) and (GetGameTimer() - t0) < 1000 do Wait(10) end

    if HasAnimDictLoaded(a.dict) then
        TaskPlayAnim(ped, a.dict, a.anim, 8.0, -8.0, a.duration, a.flag, 0, false, false, false)
        Wait(a.swapAt)
        swapCoat(tag)
        Wait(a.duration - a.swapAt)
        RemoveAnimDict(a.dict)
    else
        -- โหลดท่าไม่ขึ้น — สลับเลยไม่มีท่า (ยังทำงานได้ ไม่ค้าง)
        swapCoat(tag)
    end

    if notifyText and notifyText ~= "" then
        exports.pNotify:SendNotification({ type = 'success', text = notifyText, timeout = 3000 })
    end
end

-- ── หัวใจร่วม: ใส่/ถอดชุดเมือง (idempotent) ──────────────────────────────────
-- ตั้งสถานะแบบ sync ทันที แล้วเล่นท่า/สลับใน thread เพื่อไม่ block ผู้เรียก export
-- คืน true = เริ่มใส่/ถอดแล้ว, false = ทำไม่ได้ (ไม่มีเมือง/ไม่มี tag/สถานะซ้ำ)
local function wearCity(cityId, notifyText)
    cityId = cityId or exports.nx_cityselect:GetCurrentCityId()
    if not cityId then return false end

    local city = Config.CitiesById and Config.CitiesById[cityId]
    if not city or not city.outfitTag then return false end

    if wearingCityId == cityId then return true end -- ใส่ชุดเมืองนี้อยู่แล้ว

    local tag = pickTag(city.outfitTag)
    if not tag then return false end

    -- จำโค้ทเดิมเฉพาะครั้งแรกที่เริ่มใส่ชุดเมือง (ยังไม่ได้ใส่ชุดเมืองใด ๆ)
    -- ถ้าสลับจากเมือง A ไป B ให้คง previousTag เดิมไว้ (โค้ทจริงของผู้เล่น)
    if wearingCityId == nil then
        previousTag = exports.vorp_character:GetClothingTag(OUTFIT_CATEGORY)
    end

    wearingCityId = cityId
    CreateThread(function() playSwapAnim(tag, notifyText) end)
    return true
end

local function removeCity(notifyText)
    if wearingCityId == nil then return false end -- ไม่ได้ใส่ชุดเมืองอยู่

    local tag = previousTag
    wearingCityId = nil
    previousTag = nil
    CreateThread(function() playSwapAnim(tag, notifyText) end)
    return true
end

-- ─────────────────────────────────────────────────────────────
--  EVENT: กดใช้บัตร (server ตรวจสิทธิ์แล้ว) → toggle ใส่/ถอด
-- ─────────────────────────────────────────────────────────────
RegisterNetEvent("nx_cityselect:Client:ApplyOutfit")
AddEventHandler("nx_cityselect:Client:ApplyOutfit", function(outfitData)
    if not outfitData or not outfitData.cityId then return end

    if wearingCityId == outfitData.cityId then
        removeCity(Lang.notify_outfit_removed or 'ถอดชุดประจำเมืองแล้ว')
    else
        local label = outfitData.label or outfitData.cityName or ""
        wearCity(outfitData.cityId, Lang.notify_outfit_changed:format(label))
    end
end)

-- ─────────────────────────────────────────────────────────────
--  EVENT: แอดมินย้ายเมืองให้ (จาก MJ-Admin) → ถอดโค้ทเมืองเก่าถ้าใส่ค้างอยู่
--
--  ถ้าไม่ถอด ผู้เล่นจะใส่โค้ทของเมืองที่ตัวเองไม่ได้สังกัดแล้วค้างไปเรื่อย ๆ
--  (บัตรใบเก่าถูกลบไปแล้วด้วย จึงกดถอดเองผ่านบัตรไม่ได้อีก = ค้างถาวรจนรีล็อกอิน)
--  ถอดกลับเป็นโค้ทจริงของผู้เล่นที่จำไว้ตอนใส่ชุดเมืองครั้งแรก
-- ─────────────────────────────────────────────────────────────
RegisterNetEvent("nx_cityselect:Client:CityChanged")
AddEventHandler("nx_cityselect:Client:CityChanged", function(cityId)
    if wearingCityId and wearingCityId ~= cityId then
        removeCity(Lang.notify_outfit_removed or 'ถอดชุดประจำเมืองแล้ว')
    end
end)

-- ─────────────────────────────────────────────────────────────
--  EXPORTS: ให้ resource อื่นบังคับใส่/ถอดชุดเมืองตอนเข้า/ออกโซนกิจกรรม
--
--  ตัวอย่าง (ฝั่ง client ของ mj-airdrop / lp_airdropteam / nx_graverobbery):
--    -- เข้าโซน: ใส่ชุดเมืองของผู้เล่นเอง
--    exports.nx_cityselect:WearCityOutfit()
--    -- หรือบังคับเมืองเจาะจง: exports.nx_cityselect:WearCityOutfit('valentine')
--    -- ออกโซน: คืนชุดเดิม
--    exports.nx_cityselect:RemoveCityOutfit()
--
--  ปลอดภัยต่อการเรียกซ้ำ (idempotent) — เข้าโซนซ้ำ/ออกซ้ำ ไม่เล่นท่าซ้ำ
-- ─────────────────────────────────────────────────────────────
exports('WearCityOutfit', function(cityId, notifyText)
    return wearCity(cityId, notifyText)
end)

exports('RemoveCityOutfit', function(notifyText)
    return removeCity(notifyText)
end)

-- คืน cityId ของชุดเมืองที่ใส่อยู่ (nil = ใส่ชุดตัวเอง) — ให้ผู้เรียกเช็คสถานะได้
exports('IsWearingCityOutfit', function()
    return wearingCityId
end)

-- ─────────────────────────────────────────────────────────────
--  DEBUG: เก็บค่า tag ของชิ้นที่ใส่อยู่ (Config.Debug = true)
--  ใส่โค้ทที่อยากได้ในร้านตัดเสื้อ → /nxcapture → ได้บรรทัด male=/female= วางลง config
-- ─────────────────────────────────────────────────────────────
if Config.Debug then
    -- แปลง tag เป็นบรรทัด config พร้อมก๊อป
    local function tagToLine(genderKey, tag)
        return ('%s = { drawable = %s, albedo = %s, normal = %s, material = %s, palette = %s, tint0 = %s, tint1 = %s, tint2 = %s },')
            :format(genderKey, tag.drawable, tag.albedo, tag.normal, tag.material, tag.palette,
                    tag.tint0, tag.tint1, tag.tint2)
    end

    -- /nxcapture           → ดึง "ทุกชิ้นที่ใส่อยู่" ทุกหมวด
    -- /nxcapture Coat      → ดึงเฉพาะหมวดที่ระบุ (พฤติกรรมเดิม)
    RegisterCommand('nxcapture', function(_, args)
        local genderKey = IsPedMale(PlayerPedId()) and "male" or "female"

        -- ระบุหมวดมา = ทำแบบเดิม ทีละหมวด
        if args[1] then
            local category = args[1]
            local tag = exports.vorp_character:GetClothingTag(category)
            if not tag then
                print(('^1[nx_cityselect]^7 ไม่พบชิ้นในหมวด "%s" — ตอนนี้ไม่ได้ใส่อยู่'):format(category))
                return
            end
            print(('^2[nx_cityselect]^7 %s (%s) ที่ใส่อยู่:'):format(category, genderKey))
            print(tagToLine(genderKey, tag))
            return
        end

        -- ไม่ระบุหมวด = กวาดทุกชิ้นที่ใส่อยู่
        --
        -- ⚠️ ห้ามใช้ Config.ComponentCategories ตรงๆ — Config ในไฟล์นี้เป็นของ nx_cityselect
        -- ไม่ใช่ของ vorp_character (แต่ละ resource มี Config ของตัวเอง แยกกันสิ้นเชิง)
        -- ใช้ export GetAllPlayerComponents แทน ซึ่งคืน CachedComponents ที่ key เป็นชื่อหมวด
        -- ของ "ชิ้นที่ใส่อยู่จริง" อยู่แล้ว — ตรงกว่าและไม่ต้องวนหมวดที่ไม่ได้ใส่ทิ้งเปล่า
        local ok, comps = pcall(function()
            return exports.vorp_character:GetAllPlayerComponents()
        end)
        if not ok or type(comps) ~= 'table' then
            print('^1[nx_cityselect]^7 เรียก GetAllPlayerComponents ไม่ได้ — ระบุหมวดเองเช่น /nxcapture Coat')
            return
        end

        -- เรียงชื่อหมวดให้ผลลัพธ์คงที่ทุกครั้ง (pairs ไม่การันตีลำดับ)
        local names = {}
        for name in pairs(comps) do names[#names + 1] = name end
        table.sort(names)

        print(('^2[nx_cityselect]^7 ===== ชิ้นที่ใส่อยู่ทั้งหมด (%s) ====='):format(genderKey))

        local found = 0
        for _, name in ipairs(names) do
            -- pcall กัน GetClothingTag พังกับบางหมวด (เช่นหมวดที่ไม่ใช่เสื้อผ้าอย่าง Eyes/Heads)
            -- ไม่งั้นเจอหมวดเดียวมีปัญหาแล้วหยุดทั้งลูป ไม่ได้ชิ้นที่เหลือเลย
            local ok, tag = pcall(function()
                return exports.vorp_character:GetClothingTag(name)
            end)
            if ok and type(tag) == 'table' and tag.drawable then
                found = found + 1
                print(('^3-- %s^7'):format(name))
                print(tagToLine(genderKey, tag))
            end
        end

        if found == 0 then
            print('^1[nx_cityselect]^7 ไม่พบชิ้นที่ใส่อยู่เลยสักหมวด')
        else
            print(('^2[nx_cityselect]^7 ===== รวม %d ชิ้น ====='):format(found))
        end
    end, false)
end
