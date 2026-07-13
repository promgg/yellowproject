local script_name = "!MJ-Planting"
VORPcore = {}
TriggerEvent("getCore",function(core)
    VORPcore = core
end)

local Inventory = exports.vorp_inventory:vorp_inventoryApi()

local function dbg(fmt, ...)
    if MJDEV.Debug then print(('[MJ-Planting] ' .. fmt):format(...)) end
end

-- ── server-authoritative plant state ──────────────────────────────────────
-- เดิม server ไม่ track ต้นไม้เลย (Stage อยู่แค่ client) ทำให้ MJ-Planting:Giveitem ถูกยิงตรงจาก
-- client ได้ทันที (เห็นแค่ cooldown 6s กันไว้) ฟาร์มไอเทมไม่จำกัดโดยไม่ต้องปลูก/รดน้ำ/เก็บเกี่ยวจริงเลย
-- ย้าย Stage/เวลาโต/ความเป็นเจ้าของมาไว้ที่นี่ทั้งหมด — client เหลือแค่โชว์ผล (prop/anim/UI) ไม่ใช่
-- ตัวตัดสินอีกต่อไป ทุก item/reward ต้องผ่าน record นี้ก่อนเสมอ
local Plants     = {} -- [plantId] = { owner, entry, Stage, coords, heading, createdAt, waterAt }
local PlantCount = {} -- [zoneId] = จำนวนต้นที่ยังไม่เก็บเกี่ยวในโซนนั้น (server-authoritative แทน client Count)
local nextPlantId = 0

local function isPlayerNearCoords(src, coords, range)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - coords) <= range
end

-- ── anti-spam (server-side) ──────────────────────────────────────────────
local cooldowns = {}
local function checkCooldown(src, tag, minMs)
    cooldowns[src] = cooldowns[src] or {}
    local t = GetGameTimer()
    if (t - (cooldowns[src][tag] or 0)) < minMs then return false end
    cooldowns[src][tag] = t
    return true
end

AddEventHandler('playerDropped', function()
    local src = source
    cooldowns[src] = nil
    -- เคลียร์ record ต้นของคนที่ออกไปแล้ว กัน PlantCount ค้างเป็นโควตาผี (ตัว object จริงในโลก
    -- อาจค้าง/ย้าย owner ไปเอนจินคนอื่นตามกลไก networked entity ปกติ — เป็นข้อจำกัดเดิมของระบบ
    -- ไม่ใช่สโคปของรอบแก้นี้ ซึ่งโฟกัสแค่ trust boundary ของ item/money)
    for id, p in pairs(Plants) do
        if p.owner == src then
            PlantCount[p.entry.zoneId] = math.max(0, (PlantCount[p.entry.zoneId] or 1) - 1)
            Plants[id] = nil
        end
    end
end)

RegisterServerEvent(script_name .. ":CL:GetEvent_Planting")
AddEventHandler(script_name .. ":CL:GetEvent_Planting", function(name)
    TriggerClientEvent(script_name .. ":SV:GetEvent_Planting", source)
end)

-- ── pre-check เฉยๆ (ไม่หักของ) ให้ client เช็คก่อนเล่น anim กันเสียเวลาเปล่า ──
VORPcore.addRpcCallback('MJ-Planting:Getitem:SV', function(source, cb, Getitem)
    local src = source
    if not src or not Getitem then
        cb(false)
        return
    end
    cb((Inventory.getItemCount(src, Getitem) or 0) > 0)
end)

VORPcore.addRpcCallback('MJ-Planting:CheckWaterTank:SV', function(source, cb)
    local src = source
    exports.vorp_inventory:getItemByName(src, "tool_bucket", function(item)
        if not item then
            cb({ hasTank = false, uses = 0 })
            return
        end
        cb({ hasTank = true, uses = (item.metadata and tonumber(item.metadata.uses)) or 0 })
    end)
end)

-- เติมน้ำ: หาถัง tool_bucket ใบไหนก็ได้ที่ผู้เล่นถืออยู่ แล้วตั้ง metadata.uses ใหม่เป็นเต็มถัง
VORPcore.addRpcCallback('MJ-Planting:RefillWaterTank:SV', function(source, cb)
    local src = source
    if not checkCooldown(src, 'refill', 3000) then cb({ ok = false }); return end

    exports.vorp_inventory:getItemByName(src, "tool_bucket", function(item)
        if not item then
            cb({ ok = false })
            return
        end

        local uses = (item.metadata and tonumber(item.metadata.uses)) or 0
        if uses >= MJDEV.WaterRefill.usesPerRefill then
            cb({ ok = false, alreadyFull = true })
            return
        end

        -- amount ต้อง = item.count เสมอ (ไม่ใช่ hardcode 1) ไม่งั้น vorp_inventory:setItemMetadata
        -- จะ "แยกกอง" (split) ชิ้นที่เหลือออกเป็น item ใหม่ เมื่อ count ของถังเดิม > amount ที่ส่งไป
        exports.vorp_inventory:setItemMetadata(src, item.id, { uses = MJDEV.WaterRefill.usesPerRefill }, item.count, function(success)
            cb({ ok = success == true })
        end)
    end)
end)

VORPcore.addRpcCallback('MJ-Planting:GetMyPlants:SV', function(source, cb)
    local src = source
    local mine = {}
    for id, p in pairs(Plants) do
        if p.owner == src then
            mine[#mine + 1] = {
                plantId = id,
                idx = p.entry.idx,
                Stage = p.Stage,
                coords = p.coords,
                heading = p.heading,
                waterAt = p.waterAt,
            }
        end
    end
    cb(mine)
end)

-- ── STEP 1: ยืนยันการปลูกจริง (หักเมล็ด + สร้าง record) ──────────────────────
-- client ทำ ghost placement + ท่าปลูก (animPlant) เสร็จก่อนแล้วค่อยเรียกอันนี้ — ทุกอย่างที่ client
-- เคยเชื่อเอง (อยู่ในโซนไหม / ใกล้ต้นอื่นไปไหม / มีเมล็ดไหม) ตรวจซ้ำฝั่งนี้ทั้งหมด
VORPcore.addRpcCallback('MJ-Planting:ConfirmPlace:SV', function(source, cb, idx, coords, heading)
    local src = source
    local entry = idx and MJDEV['Planting'][idx]
    if not entry or type(coords) ~= 'vector3' then cb({ ok = false }); return end

    if not isPlayerNearCoords(src, entry.coords, entry.range) then
        cb({ ok = false, reason = 'notinzone' }); return
    end

    local minDis = entry.Dis or 3.0
    for _, p in pairs(Plants) do
        if p.entry.zoneId == entry.zoneId and #(p.coords - coords) < minDis then
            cb({ ok = false, reason = 'tooclose' }); return
        end
    end

    if (Inventory.getItemCount(src, entry.item.seed) or 0) <= 0 then
        cb({ ok = false, reason = 'noseed' }); return
    end

    Inventory.subItem(src, entry.item.seed, 1)

    nextPlantId = nextPlantId + 1
    local id = nextPlantId
    Plants[id] = {
        owner = src, entry = entry, Stage = 'fertilize',
        coords = coords, heading = heading or 0.0,
        createdAt = GetGameTimer(), waterAt = nil,
    }
    PlantCount[entry.zoneId] = (PlantCount[entry.zoneId] or 0) + 1

    dbg('src=%s planted entry idx=%s id=%s zone=%s', tostring(src), tostring(idx), tostring(id), tostring(entry.zoneId))
    cb({ ok = true, plantId = id })
end)

-- ── STEP 2: ใส่ปุ๋ย ──────────────────────────────────────────────────────
VORPcore.addRpcCallback('MJ-Planting:Fertilize:SV', function(source, cb, plantId)
    local src = source
    if not checkCooldown(src, 'fertilize', 3000) then cb({ ok = false }); return end
    local p = Plants[plantId]
    if not p or p.owner ~= src or p.Stage ~= 'fertilize' then cb({ ok = false }); return end
    if not isPlayerNearCoords(src, p.coords, MJDEV.InteractRange + 1.0) then cb({ ok = false, reason = 'far' }); return end
    if (Inventory.getItemCount(src, MJDEV.FertilizerItem) or 0) <= 0 then cb({ ok = false, reason = 'noitem' }); return end

    Inventory.subItem(src, MJDEV.FertilizerItem, 1)
    p.Stage = 'water'
    cb({ ok = true })
end)

-- ── STEP 3: รดน้ำ (waterAt ถูก stamp ที่นี่ — ใช้ตัดสิน "โตแล้วจริง" ตอนเก็บเกี่ยว) ──────────────
VORPcore.addRpcCallback('MJ-Planting:Water:SV', function(source, cb, plantId)
    local src = source
    if not checkCooldown(src, 'water', 3000) then cb({ ok = false }); return end
    local p = Plants[plantId]
    if not p or p.owner ~= src or p.Stage ~= 'water' then cb({ ok = false }); return end
    if not isPlayerNearCoords(src, p.coords, MJDEV.InteractRange + 1.0) then cb({ ok = false, reason = 'far' }); return end

    exports.vorp_inventory:getItemByName(src, "tool_bucket", function(item)
        local uses = item and item.metadata and tonumber(item.metadata.uses) or 0
        if not item or uses <= 0 then cb({ ok = false, reason = 'nowater' }); return end

        uses = math.max(0, uses - 1)
        exports.vorp_inventory:setItemMetadata(src, item.id, { uses = uses }, item.count, function()
            p.Stage = 'grow'
            p.waterAt = GetGameTimer()
            cb({ ok = true, remaining = uses })
        end)
    end)
end)

-- ── STEP 4: เก็บเกี่ยว — server ตัดสิน "โตแล้วจริง" จาก waterAt+plantmax เอง ไม่เชื่อ client ว่า
-- Stage='ready' (client เก็บ Stage/Hungry คู่ขนานไว้แค่โชว์ progress bar/model swap ให้เห็นเท่านั้น) ──
VORPcore.addRpcCallback('MJ-Planting:Harvest:SV', function(source, cb, plantId)
    local src = source
    if not checkCooldown(src, 'harvest', 3000) then cb({ ok = false }); return end

    local p = Plants[plantId]
    if not p or p.owner ~= src or p.Stage ~= 'grow' or not p.waterAt then cb({ ok = false }); return end
    if not isPlayerNearCoords(src, p.coords, MJDEV.InteractRange + 1.0) then cb({ ok = false, reason = 'far' }); return end
    if (GetGameTimer() - p.waterAt) < (p.entry.plantmax * 1000) then cb({ ok = false, reason = 'notready' }); return end

    local rolled = {}
    for _, v in pairs(p.entry.giveitem) do
        if math.random(1, 100) <= v.percent and v.item then
            rolled[#rolled + 1] = { item = v.item, count = v.count }
        end
    end

    for _, r in ipairs(rolled) do
        if not Inventory.canCarryItem(src, r.item, r.count) then
            cb({ ok = false, reason = 'fullinv' })
            return
        end
    end

    local totalGiven = 0
    for _, r in ipairs(rolled) do
        exports.vorp_inventory:addItem(src, r.item, r.count)
        totalGiven = totalGiven + (tonumber(r.count) or 0)
    end

    if totalGiven > 0 then
        TriggerEvent('lp_leaderboard:SV:PlantHarvest', { src = src, amount = totalGiven })
    end

    PlantCount[p.entry.zoneId] = math.max(0, (PlantCount[p.entry.zoneId] or 1) - 1)
    Plants[plantId] = nil
    cb({ ok = true })
end)

if MJDEV and MJDEV['Planting'] then
    for i = 1, #MJDEV['Planting'], 1 do
        -- Inventory.RegisterUsableItem (wrapper) ยิง TriggerEvent("vorpCore:registerUsableItem", ...)
        -- ซึ่งไม่มี handler อยู่จริงใน vorp_inventory เลย (เช็คแล้ว) ทำให้ลงทะเบียนไม่ติด
        -- ต้องเรียก export ตรงๆ (lowercase) แบบนี้แทน (ยืนยันวิธีนี้ถูกต้องจาก vorp_metabolism/MJ-Medic)
        local seedName = MJDEV['Planting'][i].item.seed
        exports.vorp_inventory:registerUsableItem(seedName, function(data)
            dbg('ใช้เมล็ด "%s" จาก source %s -> ส่ง MJ-Planting:Start ให้ client', seedName, tostring(data.source))
            TriggerClientEvent("MJ-Planting:Start", data.source, MJDEV['Planting'][i])
        end)
    end
else
    print("Error: MJDEV['Planting'] is not defined!")
end

-- ── กันต้นถูกปล่อยทิ้งร้าง (mirror ของเดิมที่ client เคยลบเองหลัง time_need — ย้าย record จริงมา
-- ลบฝั่งนี้ เพราะ Plants ตอนนี้คือ source of truth; client ก็ยังมี thread ลบ object ตัวเองคู่ขนานอยู่แล้ว) ──
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000)
        local now = GetGameTimer()
        for id, p in pairs(Plants) do
            if (now - p.createdAt) > p.entry.time_need then
                PlantCount[p.entry.zoneId] = math.max(0, (PlantCount[p.entry.zoneId] or 1) - 1)
                Plants[id] = nil
            end
        end
    end
end)
