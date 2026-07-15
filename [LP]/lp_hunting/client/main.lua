--[[
    lp_hunting / client / main.lua

    flow (UI ของเราเอง + แอนิเมชันถลกจริงของเกม):
      1) thread เดียว สแกนหาซากสัตว์ตายแล้ว + อยู่ใน Config.SkinTiers + ในระยะ + ยังไม่ถูกถลก
         (sleep-throttled + sticky/hysteresis แบบ nx_crafting) — และ mark ซากเป็น fully-looted
         เพื่อ "ซ่อน prompt SKIN [E] ของเกม" ให้เห็นแค่ lp_textui ของเรา
      2) เข้าใกล้ -> โชว์ exports.lp_textui:TextUIHold('[E] ชำแหละ', ...) แบบปกติ (fixed bottom-center)
         ไม่ใช้ worldAnchor
      3) ค้าง [E] ครบ -> เช็ค lp_hunting:cb:canSkin กับ server ก่อน (มีมีดไหม / กระเป๋าเต็มไหม) ถ้าไม่ผ่าน:
         ไม่เริ่มถลก ซากไม่ถูกแตะต้อง (server ตั้ง despawn timer ให้ ดู Config.AbandonedCarcassDespawnMs)
         — ถ้าผ่านหมด: สวมมีดจริงก่อนเสมอผ่าน exports.vorp_inventory:useWeapon() (แค่ "เป็นเจ้าของ" มีด
         ไม่พอ — ต้องผ่าน native GiveDelayedWeaponToPed จริงๆ เกมถึงจะเล่นแอนิเมชันถลกแบบเต็ม
         ดูรายละเอียดใน server/main.lua findOwnedKnife()) แล้ว:
         ปลด fully-looted ชั่วคราว -> TASK_LOOT_ENTITY (เกมเล่นท่าถลก ANIM_SCENE จริง ครบทุกตัว:
         คุกเข่า+มีด+sync กับซาก) — เราไม่สร้างท่าเอง
      4) ดัก EVENT_LOOT_COMPLETE (เกมถลกเสร็จ) -> ลบ prop หนังออกจากมือ -> ยิง netId ให้ server แจกของ
         (ส่ง "แค่ netId" — server ตัดสิน model/ระยะ/tier/ไอเทมเองทั้งหมด ไม่เชื่อ client — เช็คกระเป๋าซ้ำ
         อีกชั้นเป็น defense-in-depth แม้ข้อ 3 ควรกันไว้แล้วก็ตาม)
]]

local VORPcore = exports.vorp_core:GetCore()

-- debounce กันซากเดิมถูกยิง event ซ้ำระหว่างรอ server ตอบ (ไม่ใช่ anti-cheat จริง — แค่กัน UX ซ้ำซ้อน
-- ฝั่ง server มี compare-and-set ของจริงอยู่แล้ว) ล้างอัตโนมัติหลัง timeout เผื่อ server ปฏิเสธ (เช่น
-- กระเป๋าเต็ม) จะได้ลองใหม่ได้โดยไม่ต้องรอ resource restart
local pendingSkins  = {} -- [netId] = GetGameTimer() ตอนส่ง
local PENDING_TTL   = 15000 -- ms — กัน re-trigger ซากเดิมระหว่างรอถลก+server (ครอบเวลาแอนิเมชันถลก+round-trip)

local function dbg(fmt, ...)
    if Config.Debug then print(('[lp_hunting:cl] ' .. fmt):format(...)) end
end

local activeCarcass = nil -- ped handle ที่กำลังโชว์ [E] ชำแหละอยู่ (ตัวเดียว ณ เวลาใดเวลาหนึ่ง)
local activeNetId   = nil
local skinningNow   = false -- true ระหว่างถลก (TaskLootEntity) กันสแกนแทรก
local lootPending   = nil   -- { ent, netId } ซากที่เพิ่งสั่งถลก รอ EVENT_LOOT_COMPLETE เพื่อแจกของ
local SUPPRESS_RADIUS = (Config.Range or 2.0) + 2.0 -- ระยะที่เริ่ม mark ซากเป็น "ถูกถลกแล้ว" ให้กว้างกว่าระยะโชว์ [E]

-- ปิด native carcass prompt (SKIN [E] / PICK UP [R] มุมขวาล่าง) แบบสะอาด: mark ซากว่า "ถูก loot หมดแล้ว"
-- ด้วย _SET_ENTITY_FULLY_LOOTED(ent, true) → เกมถือว่าไม่เหลืออะไรให้ถลก/เก็บ → prompt + action หายทั้งคู่
-- (ต่างจากบล็อก control ทีละตัวที่ได้แค่ซ่อน prompt แต่ action ยังหลุด) เป็น set ต่อ entity เรียกตอนเจอซากในสแกนพอ
local function markLooted(ent)
    if ent and ent ~= 0 then
        Citizen.InvokeNative(0x6BCF5F3D8FFE988D, ent, true) -- _SET_ENTITY_FULLY_LOOTED(entity, looted)
    end
end

-- หมายเหตุ: _IS_ANIMAL_SKINNED (0x88A5564B19C15391) เคยถูกใช้กันโชว์ [E] ซ้ำ/หาซากที่เพิ่งถลก แต่พบว่า
-- คืนค่าไม่น่าเชื่อถือ (สัตว์ใหญ่ที่เพิ่งตายสดๆ คืน true อยู่พักหนึ่งก่อนเป็น false) ทำให้ detect ช้าไปถึง ~8 วิ
-- จึงเลิกใช้ทั้งหมด — กันซ้ำใช้ pendingSkins debounce + ลบซากทันทีหลังถลกแทน (ดู EVENT_LOOT_COMPLETE ด้านล่าง)

-- หาซากที่ "เพิ่งถลกเสร็จ" (ตายแล้ว) + เป็นสัตว์ในลิสต์ + networked ใกล้ผู้เล่นสุด
-- ใช้ตอน EVENT_LOOT_COMPLETE ยิงโดยที่เราไม่ได้เป็นคนสั่ง (ผู้เล่นเผลอถลกด้วย native ในช่วงหน้าต่าง)
local function findJustSkinned()
    local pc = GetEntityCoords(PlayerPedId())
    local best, bd = nil, 3.0
    for _, e in ipairs(GetGamePool('CPed')) do
        if DoesEntityExist(e) and Config.SkinTiers[GetEntityModel(e)] and IsEntityDead(e)
            and NetworkGetEntityIsNetworked(e) then
            local dd = #(pc - GetEntityCoords(e))
            if dd < bd then best, bd = e, dd end
        end
    end
    return best
end

-- safety: ถ้ามี prop หนัง (carriable pelt) หลุดติดมือผู้เล่น (เช่น native ยิง prompt ทันก่อนถูกปิด) ลบทิ้ง
-- ปกติเมื่อ native ถูกปิดครบจะไม่มี pelt เกิดขึ้นเลย ตัวนี้เป็นตาข่ายกันพลาดตามที่ผู้เล่นสั่ง "ลบ prop หนัง"
local function deleteCarriedPelt()
    local ped     = PlayerPedId()
    local carried = Citizen.InvokeNative(0xD806CD2A4F2C2996, ped) -- _GET_FIRST_ENTITY_PED_IS_CARRYING
    if carried and carried ~= 0 and DoesEntityExist(carried) and GetIsCarriablePelt(carried) == 1 then
        SetEntityAsMissionEntity(carried, true, true)
        SetEntityAsNoLongerNeeded(carried)
        DeleteEntity(carried)
        dbg('deleteCarriedPelt: ลบ pelt ที่ติดมือ entity=%s', tostring(carried))
        return true
    end
    return false
end

-- native skin (ถ้ายังหลุดมา) จบแอนิเมชัน + สร้าง prop หนัง "หลัง" progbar ของเราจบ — ตามเก็บลบซ้ำ ~2.5 วิ
local function schedulePeltCleanup()
    CreateThread(function()
        for _ = 1, 10 do
            Wait(250)
            if deleteCarriedPelt() then break end
        end
    end)
end

local function isPendingOrExpired(netId)
    local sentAt = pendingSkins[netId]
    if not sentAt then return false end
    if (GetGameTimer() - sentAt) > PENDING_TTL then
        pendingSkins[netId] = nil
        return false
    end
    return true
end

-- UX-only (server ตัดสินจริงอีกทีเสมอ, ดู server/main.lua) — ไม่โชว์ prompt ของเราถ้าผู้เล่นอยู่ในโซน
-- ต้องห้ามตอนนี้ ทั้ง 2 ระบบ: (1) เขตเมืองของ nx_cityselect (เช็คจาก export ที่มีอยู่แล้ว GetCurrentZone,
-- local call ล้วนๆ ไม่มี network round-trip, pcall กันเคส nx_cityselect ไม่ได้รันอยู่ — fail-open) และ
-- (2) Config.ExtraBlockedZones ของ lp_hunting เอง (point-in-polygon อิสระจาก nx_cityselect ทั้งหมด)
local function isPointInPolygon(x, y, poly)
    local inside = false
    local j = #poly
    for i = 1, #poly do
        local xi, yi = poly[i].x, poly[i].y
        local xj, yj = poly[j].x, poly[j].y
        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end
    return inside
end

local function isInExtraBlockedZone(coords)
    for _, zone in ipairs(Config.ExtraBlockedZones or {}) do
        if #zone.points >= 3 and coords.z >= zone.minZ and coords.z <= zone.maxZ
            and isPointInPolygon(coords.x, coords.y, zone.points) then
            return true
        end
    end
    return false
end

local function isInCityZone()
    if not Config.BlockInCityZones then return false end
    local ok, zone = pcall(function() return exports.nx_cityselect:GetCurrentZone() end)
    return ok and zone ~= nil
end

local function isInBlockedZone()
    if isInExtraBlockedZone(GetEntityCoords(PlayerPedId())) then return true end
    return isInCityZone()
end

local function cancelActive()
    if activeCarcass then
        exports.lp_textui:CancelHold()
    end
    activeCarcass = nil
    activeNetId   = nil
end

-- ── skinning flow: hold [E] ครบ -> สั่งถลกด้วย native TASK_LOOT_ENTITY (เกมเล่นท่า ANIM_SCENE จริง
--    ครบทุกตัว: คุกเข่า+มีด+sync กับซาก+ตำแหน่งเป๊ะ) -> ดัก EVENT_LOOT_COMPLETE -> ลบหนัง + แจกของ ──
-- (เดิมเคยทำ progbar + เล่น anim เอง แต่เทียบ ANIM_SCENE ของเกมไม่ได้ — สลับมาใช้ของเกมเลย)
local function startSkinning(pedEntity, netId)
    if skinningNow then return end
    skinningNow = true
    cancelActive() -- ปิด textui ทันที

    CreateThread(function()
        -- ขอ network control ของซากก่อน (กัน task fail เพราะ control อยู่ที่ client อื่น/server)
        NetworkRequestControlOfEntity(pedEntity)
        local t = GetGameTimer()
        while not NetworkHasControlOfEntity(pedEntity) and (GetGameTimer() - t) < 800 do
            NetworkRequestControlOfEntity(pedEntity)
            Wait(0)
        end
        SetEntityInvincible(pedEntity, false)

        lootPending = { ent = pedEntity, netId = netId }
        -- TaskLootEntity ไม่ start ถ้าสัตว์ยังดิ้น/ยังไม่ตายสนิท (เราโชว์ [E] ตั้งแต่กำลังตาย) → retry สูงสุด 5 ครั้ง
        -- เช็คด้วย _GET_ENTITY_LOOTING_PED ว่า "ถลกเริ่มจริง" ไหม ถ้าเริ่มแล้วรอจนเสร็จ (ไม่ retry ทับของที่ทำงานอยู่)
        for attempt = 1, 5 do
            if not lootPending then break end -- EVENT_LOOT_COMPLETE ยิงแล้ว
            Citizen.InvokeNative(0x6BCF5F3D8FFE988D, pedEntity, false) -- _SET_ENTITY_FULLY_LOOTED(false) (เผื่อโดน mark ทับ)
            Wait(0)
            Citizen.InvokeNative(0x48FAE038401A2888, PlayerPedId(), pedEntity) -- TASK_LOOT_ENTITY(ped, entity)
            Wait(1200) -- ให้เวลา task เริ่ม

            local looter = Citizen.InvokeNative(0xEF2D9ED7CE684F08, pedEntity, Citizen.ResultAsInteger()) -- _GET_ENTITY_LOOTING_PED
            local started = (looter and looter == PlayerPedId())
            dbg('startSkinning netId=%s attempt=%d started=%s', tostring(netId), attempt, tostring(started))
            if started or not lootPending then
                while lootPending do Wait(100) end -- ถลกเริ่มแล้ว → รอ EVENT_LOOT_COMPLETE (safety timeout จะ clear ถ้าค้าง)
                break
            end
        end
    end)

    -- safety: ถ้า EVENT_LOOT_COMPLETE ไม่ยิงใน 20 วิ (retry หมดแล้วยังไม่สำเร็จ) รีเซ็ตให้ลองใหม่ได้
    SetTimeout(20000, function()
        if lootPending and lootPending.ent == pedEntity then
            dbg('startSkinning timeout netId=%s (ไม่มี LOOT_COMPLETE)', tostring(netId))
            pendingSkins[netId] = nil
            lootPending = nil
            skinningNow = false
        end
    end)
end

-- ── ดัก EVENT_LOOT_COMPLETE: เกมถลกเสร็จ (ไม่ว่าจะสั่งด้วย lp_textui/TaskLootEntity หรือผู้เล่นเผลอกด
--    native ในช่วงหน้าต่าง) -> ลบ prop หนัง + ยิง netId ให้ server แจกของเรา (server dedupe กันซ้ำเอง) ──
CreateThread(function()
    while true do
        Wait(0)
        local size = GetNumberOfEvents(0)
        for i = 0, size - 1 do
            if GetEventAtIndex(0, i) == `EVENT_LOOT_COMPLETE` then
                local viaPending = lootPending ~= nil
                local ent = viaPending and lootPending.ent or findJustSkinned()
                if ent and ent ~= 0 and DoesEntityExist(ent) and NetworkGetEntityIsNetworked(ent) then
                    local netId = viaPending and lootPending.netId or NetworkGetNetworkIdFromEntity(ent)
                    lootPending = nil
                    skinningNow = false
                    dbg('LOOT_COMPLETE → reward netId=%s%s', tostring(netId), viaPending and ' (lp_textui)' or ' (native)')
                    deleteCarriedPelt()   -- ลบ prop หนังออกจากมือ
                    schedulePeltCleanup() -- เผื่อหนังโผล่ช้ากว่า event
                    if netId and netId ~= 0 then
                        pendingSkins[netId] = GetGameTimer()
                        TriggerServerEvent('lp_hunting:sv:skin', netId)
                    end
                    if DoesEntityExist(ent) then
                        SetTimeout(800, function() if DoesEntityExist(ent) then DeleteEntity(ent) end end)
                    end
                    break
                end
                -- ถ้าไม่เจอสัตว์ในลิสต์ใกล้ๆ = loot อย่างอื่น (ศพคน/หีบ) ปล่อยผ่าน ไม่ทำอะไร
            end
        end
    end
end)

-- ── detection: สแกน GetGamePool หาซากสัตว์ตาย/กำลังตาย ในลิสต์ + ในระยะ → mark fully-looted (ปิด native
--    SKIN prompt) + โชว์ textui  (ครอบทุกขนาด — GET_PLAYER_INTERACTION_TARGET_ENTITY เห็นแค่สัตว์เล็ก
--    ไม่เห็น SKIN prompt สัตว์ใหญ่ จึงต้องใช้ scan) + sticky target กันปุ่มสั่น
-- ใช้ IsPedDeadOrDying (โชว์ตั้งแต่กำลังตาย) + scan 50ms ตอนกำลังหา (native แว่บสั้นมาก ~3 เฟรม แต่ไม่กิน
-- CPU เท่า Wait(0) ทุกเฟรม — จำนวน ped ในพื้นที่ล่าสัตว์ปกติน้อย ทำ full pool scan ทุก 50ms สบายๆ)
CreateThread(function()
    while true do
        local sleep = 50

        if not skinningNow then
            local ped    = PlayerPedId()
            local coords = GetEntityCoords(ped)

            local stillValid = false
            if activeCarcass and DoesEntityExist(activeCarcass) and IsPedDeadOrDying(activeCarcass, true)
                and #(coords - GetEntityCoords(activeCarcass)) <= (Config.Range + 0.5) then
                stillValid = true
                markLooted(activeCarcass) -- ย้ำปิด native prompt
                sleep = 150               -- มี active แล้ว ไม่ต้องสแกนถี่
            end

            if not stillValid then
                if activeCarcass then cancelActive() end

                local nearestPed, nearestDist = nil, Config.Range
                for _, ent in ipairs(GetGamePool('CPed')) do
                    if DoesEntityExist(ent) and Config.SkinTiers[GetEntityModel(ent)]
                        and IsPedDeadOrDying(ent, true) then
                        local d = #(coords - GetEntityCoords(ent))
                        if d <= SUPPRESS_RADIUS then markLooted(ent) end -- ปิด native ตั้งแต่กำลังตาย ในระยะกว้าง
                        if NetworkGetEntityIsNetworked(ent) then
                            local netId = NetworkGetNetworkIdFromEntity(ent)
                            if not isPendingOrExpired(netId) and d <= nearestDist then
                                nearestPed, nearestDist = ent, d
                            end
                        end
                    end
                end

                if nearestPed and isInBlockedZone() then
                    dbg('carcass found but suppressed: in a blocked zone')
                elseif nearestPed then
                    activeCarcass = nearestPed
                    activeNetId   = NetworkGetNetworkIdFromEntity(nearestPed)
                    local tier      = Config.SkinTiers[GetEntityModel(nearestPed)]
                    local netId     = activeNetId
                    local target    = nearestPed
                    dbg('prompt shown: %s netId=%s dist=%.2f', tier and tier.name or '?', tostring(netId), nearestDist)
                    exports.lp_textui:TextUIHold(
                        '[E] ชำแหละ' .. (tier and tier.name and (' (' .. tier.name .. ')') or ''),
                        Config.HoldMs,
                        function()
                            if activeCarcass == target and DoesEntityExist(target) and IsPedDeadOrDying(target, true) then
                                -- เช็คกระเป๋าก่อนเริ่มแอนิเมชันถลก กันเสียเวลาเล่นท่าเต็มๆ แล้วจบด้วยกระเป๋าเต็ม
                                -- (server เช็คซ้ำอีกชั้นตอนแจกจริงเสมอ อันนี้แค่ UX ไม่ใช่ anti-cheat)
                                -- ถ้าเต็ม: ไม่เริ่มถลก ไม่แตะซาก (ไม่ mark/ไม่ลบ) ปล่อยให้สแกนรอบถัดไปเจอใหม่เอง
                                local result = VORPcore.Callback.TriggerAwait('lp_hunting:cb:canSkin', netId)
                                if not result or not result.ok then
                                    local reason = result and result.reason
                                    local msg = 'กระเป๋าเต็ม ไม่สามารถชำแหละได้'
                                    if reason == 'noKnife' then
                                        msg = Config.RequireKnifeMsg or 'ต้องมีมีดในกระเป๋าถึงจะชำแหละได้'
                                    end
                                    exports.pNotify:SendNotification({ text = msg, type = 'error', timeout = 4000 })
                                    activeCarcass, activeNetId = nil, nil
                                    return
                                end

                                -- สวมมีดจริงก่อนเริ่มถลกเสมอ ผ่าน flow official ของ vorp_inventory (useWeapon)
                                -- ไม่ใช้ native ตรงๆ — "เป็นเจ้าของ" มีดในกระเป๋าอย่างเดียวไม่พอ ต้องผ่าน
                                -- native GiveDelayedWeaponToPed (เรียกอยู่ข้างใน Weapon:equipwep()) ก่อน
                                -- เกมถึงจะเห็นว่าตัวละคร "ถือมีดจริง" แล้วเล่นแอนิเมชันถลกแบบเต็ม
                                -- (เรียกซ้ำได้ปลอดภัยแม้สวมอยู่แล้ว) รอสั้นๆ ให้ native ให้อาวุธจริงก่อน
                                if result.knifeWeaponId then
                                    exports.vorp_inventory:useWeapon({ id = result.knifeWeaponId, type = 'item_weapon' })
                                    Wait(300)
                                end

                                activeCarcass, activeNetId = nil, nil
                                startSkinning(target, netId)
                            end
                        end
                        -- แบบปกติ (fixed bottom-center) แทน world-anchored — ไม่ต้องส่ง controlCode/worldAnchor
                    )
                end
            end
        else
            sleep = 300
        end

        Wait(sleep)
    end
end)

-- ── cleanup ────────────────────────────────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    exports.lp_textui:CancelHold()
end)
