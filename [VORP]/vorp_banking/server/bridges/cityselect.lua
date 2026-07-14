VORP_BANK = VORP_BANK or {}
VORP_BANK.CitySelect = {}

-- cache ผลลัพธ์ต่อ source กัน export ยิงซ้ำทุกครั้งที่เปิด/อัปเกรดตู้เซฟ
-- (เมืองบ้านเกิดของตัวละครไม่เปลี่ยนกลางเซสชัน ตาม nx_cityselect ที่ล็อกเมืองถาวรต่อตัวละคร)
local playerCityCache = {}
local CACHE_TTL_SECONDS = 300

local function isResourceStarted(name)
    return GetResourceState(name) == 'started'
end

-- คืนค่า city id ตัวพิมพ์เล็กของ nx_cityselect (เช่น 'valentine') หรือ nil ถ้าไม่มี/ยังไม่เลือกเมือง
-- ถ้า nx_cityselect ไม่ได้ start เลย (ไม่ได้ติดตั้ง) จะคืน nil เสมอ — ผู้เรียกต้องเช็ค isResourceStarted
-- แยกต่างหากก่อนตัดสินใจบล็อก ไม่ให้ทั้งฟีเจอร์ตายเพราะพึ่งพา resource ที่ไม่มี
function VORP_BANK.CitySelect.GetPlayerCityId(source)
    local cached = playerCityCache[source]
    if cached and (os.time() - cached.cachedAt) < CACHE_TTL_SECONDS then
        return cached.cityId
    end

    local cityId = nil
    if isResourceStarted('nx_cityselect') then
        local ok, result = pcall(function()
            return exports.nx_cityselect:GetPlayerCityId(source)
        end)
        if ok then cityId = result end
    end

    playerCityCache[source] = { cityId = cityId, cachedAt = os.time() }
    return cityId
end

function VORP_BANK.CitySelect.IsNxCitySelectActive()
    return isResourceStarted('nx_cityselect')
end

function VORP_BANK.CitySelect.InvalidatePlayer(source)
    playerCityCache[source] = nil
end

AddEventHandler('playerDropped', function()
    VORP_BANK.CitySelect.InvalidatePlayer(source)
end)
