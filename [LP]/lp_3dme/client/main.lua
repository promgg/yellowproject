-- lp_3dme (client) — คำนวณตำแหน่งบนจอแล้วส่งให้ NUI วาด
--
-- ⚠️ ส่งเป็น "ข้อมูล" เท่านั้น ไม่ต่อ HTML ที่นี่เด็ดขาด
--    ถ้าต่อสตริง HTML แล้วยัดเข้า NUI ผู้เล่นจะพิมพ์แท็กเข้าไปรันโค้ดใน NUI ของ
--    ทุกคนที่มองเห็นได้ ฝั่ง app.js ใช้ textContent อย่างเดียว

local RESOURCE = GetCurrentResourceName()

local bubbles      = {}  -- รายการข้อความที่ยังไม่หมดอายุ { serverId, typeKey, text, expiresAt }
local descriptions = {}  -- [serverId] = ข้อความป้ายค้าง (server ส่งมาให้ทั้งชุด)
local nextId       = 0
local lastPayload  = ''  -- กันส่ง NUI ซ้ำเมื่อไม่มีอะไรเปลี่ยน

local headBone = nil     -- index กระดูกหัว resolve ครั้งแรกที่ใช้

-- ── ตำแหน่งเหนือหัว ─────────────────────────────────────────────────────────
-- 'skel_head' ยืนยันจากลิสต์กระดูกของ RDR3 (spooni_spooner/data/rdr3/bones.lua)
-- ถ้าหา bone ไม่เจอ (ped แปลกๆ) ถอยไปใช้พิกัด entity + ความสูงโดยประมาณแทน
local function headCoords(ped)
    if not headBone then
        headBone = GetEntityBoneIndexByName(ped, 'skel_head')
    end

    if headBone and headBone ~= -1 then
        local c = GetWorldPositionOfEntityBone(ped, headBone)
        if c and c.x ~= 0.0 then
            return c.x, c.y, c.z + (Config.HeightOffset or 0.35)
        end
    end

    local c = GetEntityCoords(ped)
    return c.x, c.y, c.z + 1.0 + (Config.HeightOffset or 0.35)
end

-- ── จัดการรายการข้อความ ─────────────────────────────────────────────────────
RegisterNetEvent('lp_3dme:show', function(serverId, typeKey, text)
    if not Config.Types[typeKey] then return end

    serverId = tonumber(serverId)
    if not serverId then return end

    -- คนเดียวกันพูดรัวๆ ให้ดันอันเก่าออก ไม่ให้กองสูงจนบังจอ
    local mine = {}
    for i = #bubbles, 1, -1 do
        if bubbles[i].serverId == serverId then
            mine[#mine + 1] = i
        end
    end
    while #mine >= (Config.MaxPerPlayer or 3) do
        table.remove(bubbles, mine[#mine])
        table.remove(mine, #mine)
    end

    nextId = nextId + 1
    bubbles[#bubbles + 1] = {
        id        = nextId,
        serverId  = serverId,
        typeKey   = typeKey,
        text      = tostring(text or ''),
        expiresAt = GetGameTimer() + (Config.Duration or 10000),
    }
end)

RegisterNetEvent('lp_3dme:descState', function(state)
    descriptions = state or {}
end)

-- ── ลูปวาด ──────────────────────────────────────────────────────────────────
-- วิ่งเต็มเฟรมเฉพาะตอนมีอะไรให้แสดง ไม่งั้นหลับยาว
-- ระบบแบบนี้มักเผลอวิ่งลูปถี่ๆ ตลอดเวลาแม้ไม่มีข้อความสักอัน ซึ่งกินเฟรมฟรีๆ
CreateThread(function()
    while true do
        local now      = GetGameTimer()
        local myPed    = PlayerPedId()
        local myCoords = GetEntityCoords(myPed)
        local items    = {}

        -- เก็บกวาดอันหมดอายุ (ไล่ถอยหลังเพราะลบระหว่างวน)
        for i = #bubbles, 1, -1 do
            if bubbles[i].expiresAt <= now then
                table.remove(bubbles, i)
            end
        end

        local function collect(serverId, typeKey, text, cfg, key)
            local plyIdx = GetPlayerFromServerId(serverId)
            if plyIdx == -1 or not NetworkIsPlayerActive(plyIdx) then return end

            local ped = GetPlayerPed(plyIdx)
            if not ped or ped == 0 or not DoesEntityExist(ped) then return end

            local x, y, z = headCoords(ped)

            -- กรองระยะฝั่ง client อีกชั้น: server กรองตอน "ส่ง" แต่คนเดินห่างออกไป
            -- ระหว่างที่ข้อความยังค้างอยู่ ไม่ควรเห็นต่อ
            local d = #(vector3(x, y, z) - myCoords)
            if d > cfg.range then return end

            local onScreen, sx, sy = GetScreenCoordFromWorldCoord(x, y, z)
            if not onScreen then return end

            items[#items + 1] = {
                key   = key,
                x     = sx * 100.0,
                y     = sy * 100.0,
                label = cfg.label,
                color = cfg.color,
                text  = text,
                dist  = d, -- NUI ใช้จัดลำดับซ้อน คนใกล้อยู่หน้า
            }
        end

        for i = 1, #bubbles do
            local b = bubbles[i]
            collect(b.serverId, b.typeKey, b.text, Config.Types[b.typeKey], 'b' .. b.id)
        end

        if Config.Desc.enabled then
            for serverId, text in pairs(descriptions) do
                collect(tonumber(serverId), 'desc', text, Config.Desc, 'd' .. tostring(serverId))
            end
        end

        local payload = json.encode(items)
        if payload ~= lastPayload then
            SendNUIMessage({ action = 'update', items = items })
            lastPayload = payload
        end

        if #bubbles == 0 and next(descriptions) == nil then
            Wait(500)          -- ไม่มีอะไรแสดง — ไม่ต้องกินเฟรม
        else
            Wait(0)            -- ต้องตามหัวผู้เล่นทุกเฟรม ไม่งั้นกล่องกระตุก
        end
    end
end)

-- ── lifecycle ───────────────────────────────────────────────────────────────
AddEventHandler('vorp:SelectedCharacter', function()
    Wait(1000)
    TriggerServerEvent('lp_3dme:requestDesc') -- ขอป้ายค้างของคนอื่นที่ตั้งไว้ก่อนเราเข้ามา
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= RESOURCE then return end
    SendNUIMessage({ action = 'update', items = {} })
end)

if Config.Debug then
    RegisterCommand('3dmedebug', function()
        print(('[%s] bubbles=%d desc=%d'):format(RESOURCE, #bubbles, (function()
            local n = 0; for _ in pairs(descriptions) do n = n + 1 end; return n
        end)()))
    end, false)
end
