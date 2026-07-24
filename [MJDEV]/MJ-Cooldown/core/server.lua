local script = 'MJ-Cooldown'

-- คีย์เป็น charIdentifier = "ต่อตัวละคร" ไม่ใช่ identifier ซึ่งเป็น "ต่อบัญชี"
-- ของเดิมใช้ Character.identifier ทำให้ทุกตัวละครในบัญชีเดียวกันใช้ช่องเดียวกัน:
--   ตัวละคร A ตาย -> สลับไปตัวละคร B -> B ติดคูลดาวน์บาดเจ็บทั้งที่ไม่เคยตาย
--   และตอน B นับครบเวลา ก็เขียนทับเป็น false = ล้างคูลดาวน์ของ A ทิ้งไปด้วย
--
-- หมายเหตุ: ตั้งใจไม่ล้างตาราง DEAD ตอน playerDropped เพราะตารางนี้คือตัวจำคูลดาวน์
-- ข้ามการออก-เข้าเกม (เข้ามาใหม่ vorp:SelectedCharacter จะอ่านค่านี้ส่งกลับให้ client)
-- ถ้าลบตอนหลุดจะกลายเป็นช่องโหว่ "relog แล้วคูลดาวน์หาย" ค่าที่ค้างเป็นแค่ boolean
-- ต่อตัวละครที่เคยตายหลังรีสตาร์ทเซิร์ฟ กินแรมน้อยมาก
DEAD = {}
VORPcore = {} -- core object

TriggerEvent("getCore", function(core)
    VORPcore = core
end)

AddEventHandler("vorp:SelectedCharacter", function(source)
    local _source = source
    local xUser = VORPcore.getUser(_source)
    local Character = xUser and xUser.getUsedCharacter
    if not (Character and Character.charIdentifier) then return end
    if DEAD[Character.charIdentifier] then
        TriggerClientEvent(script .. "GetData", _source, true)
    else
        TriggerClientEvent(script .. "GetData", _source, false)
    end
end)

RegisterNetEvent(script .. "SaveData")
AddEventHandler(script .. "SaveData", function(isDead)
    local _source = source
    local xUser = VORPcore.getUser(_source)
    local Character = xUser and xUser.getUsedCharacter
    if not (Character and Character.charIdentifier) then return end
    if DEAD[Character.charIdentifier] ~= nil then
        DEAD[Character.charIdentifier] = 0
    end
    if isDead then
        DEAD[Character.charIdentifier] = true
        if Config['ChangeClothes'] then
            TriggerClientEvent(script .. "GetCloth", _source, json.decode(Character.comps))
        end
    else
        DEAD[Character.charIdentifier] = false
        if Config['ChangeClothes'] then
            TriggerClientEvent(script .. "GetCloth", _source, json.decode(Character.comps))
        end
    end
end)


if GetCurrentResourceName() ~= script then
    os.exit()
end