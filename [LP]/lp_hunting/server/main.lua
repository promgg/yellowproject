--[[
    lp_hunting / server / main.lua

    ผู้ตัดสินใจตัวจริงเรื่องรางวัลทั้งหมด — client ส่งมาแค่ netId ของซากที่อ้างว่าชำแหละเสร็จแล้ว
    ทุกอย่างอื่น (โมเดล/ตายจริงไหม/ระยะ/tier/ไอเทม/จำนวน) server ตรวจ+ตัดสินเองทั้งหมด ไม่เชื่อ client

    ลำดับการตรวจใน RegisterServerEvent('lp_hunting:sv:skin', ...):
      1) compare-and-set บนซาก (handledCarcass[netId]) กันซากเดิมโดนรางวัลซ้ำจาก event ซ้ำ/replay
         (ล็อกไว้ก่อนเช็คอย่างอื่นทั้งหมด — ปลดล็อกคืนเฉพาะกรณี "กระเป๋าเต็ม" ที่แก้ไขแล้วลองใหม่ได้จริง
         กรณีอื่น (ของปลอม/นอกระยะ/สแปม) ปล่อยให้ล็อกค้างถาวร ไม่มีประโยชน์อะไรที่จะให้ลองซ้ำกับ netId เดิม)
      2) rate limit ต่อคน — ห้ามชำแหละถี่กว่า Config.RateLimitMs (ปกติแอนิเมชันถลกกินเวลามากกว่าอยู่แล้ว)
      3) resolve entity จาก netId + ตรวจว่ายังอยู่จริง + โมเดลอยู่ใน Config.SkinTiers (IsEntityDead เรียก server ไม่ได้ใน RedM)
      4) ตรวจระยะผู้เล่น<->ซาก ด้วยพิกัดที่ server รู้เอง (ไม่เชื่อระยะที่ client อ้าง)
      5) canCarryItem ทั้งเนื้อและหนังก่อน addItem เสมอ (mirror vorp_hunting/server/main.lua giveReward)
      6) แจกไอเทม + addXp + ลบซาก + แจ้งเตือน + ยิงต่อ lp_leaderboard (soft integration)
]]

local VorpCore = exports.vorp_core:GetCore()

local cooldowns       = {} -- [src] = GetGameTimer() ล่าสุดที่ชำแหละสำเร็จ (rate limit)
local handledCarcass  = {} -- [netId] = true (anti-dupe compare-and-set)
local scheduledDespawn = {} -- [netId] = true — กันตั้ง despawn timer ซ้ำถ้าซากตัวเดียวโดน reject หลายรอบ

local function dbg(fmt, ...)
    if Config.Debug then print(('[lp_hunting] ' .. fmt):format(...)) end
end

-- ── point-in-polygon (ray casting) — สำหรับ Config.ExtraBlockedZones เท่านั้น (อิสระจาก
-- nx_cityselect ทั้งหมด ไม่ผ่าน export ของมันเลย ตามที่สั่ง) ────────────────────────────
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

local function getExtraBlockedZoneAt(coords)
    for _, zone in ipairs(Config.ExtraBlockedZones or {}) do
        if #zone.points >= 3 and coords.z >= zone.minZ and coords.z <= zone.maxZ
            and isPointInPolygon(coords.x, coords.y, zone.points) then
            return zone
        end
    end
    return nil
end

-- resolve entity + tier + ไอเทมที่ต้องเช็ค จาก netId เดียว (ใช้ร่วมกันทั้ง pre-check callback ด้านล่าง
-- และ event แจกรางวัลจริง) คืน nil ถ้า resolve ไม่ผ่านจุดใดจุดหนึ่ง (ไม่ dbg เหตุผลตรงนี้ — ผู้เรียกที่
-- รู้ context ว่ากำลังทำอะไรอยู่จะ dbg เอง)
-- ของที่กลุ่มนี้ "มีโอกาส" ได้ทั้งหมด (ยังไม่สุ่ม) — ใช้เช็คกระเป๋าล่วงหน้าก่อนเริ่มถลก
-- เช็คแบบเผื่อไว้เต็มที่: ถ้าที่ว่างไม่พอสำหรับทุกอย่างที่อาจดรอป ก็ยังไม่ให้เริ่ม
-- (ดีกว่าปล่อยให้ถลกจนจบแล้วของหล่นหายเพราะกระเป๋าเต็ม)
local function possibleItemsForGroup(group)
    local loot = Config.GroupLoot[group] or Config.GroupLoot.other
    if not loot then return {} end

    local out = {}
    for _, item in ipairs(loot.always or {}) do out[#out + 1] = item end
    for _, item in ipairs(loot.pickOne or {}) do out[#out + 1] = item end
    for _, roll in ipairs(loot.rolls or {}) do out[#out + 1] = roll.item end
    return out
end

-- สุ่มของจริงตอนถลกเสร็จ — คืนลิสต์ไอเทมที่ได้ (อาจว่างเปล่าได้ถ้ากลุ่มนั้นเป็น rolls ล้วนแล้วพลาดหมด)
local function rollLootForGroup(group)
    local loot = Config.GroupLoot[group] or Config.GroupLoot.other
    if not loot then return {} end

    local out = {}
    for _, item in ipairs(loot.always or {}) do out[#out + 1] = item end

    local pick = loot.pickOne
    if pick and #pick > 0 then
        out[#out + 1] = pick[math.random(#pick)]
    end

    -- แต่ละ roll อิสระต่อกัน — ได้หลายอย่างพร้อมกันได้ (เช่นหมี: เนื้อ+หนัง+เล็บ ครบทั้ง 3)
    for _, roll in ipairs(loot.rolls or {}) do
        if math.random(100) <= (roll.chance or 0) then
            out[#out + 1] = roll.item
        end
    end

    return out
end

local function resolveCarcass(netId)
    local ent = NetworkGetEntityFromNetworkId(netId)
    if not ent or ent == 0 or not DoesEntityExist(ent) then return nil end

    local model = GetEntityModel(ent)
    local tier  = Config.SkinTiers[model]
    if not tier then return nil end

    local group = tier.group or 'other'
    return ent, tier, group, possibleItemsForGroup(group)
end

-- คืน id (แถวอาวุธจริงใน vorp_inventory) ของมีดชนิดใดชนิดหนึ่งที่ผู้เล่นเป็นเจ้าของ หรือ nil ถ้าไม่มีเลย
--
-- หมายเหตุสำคัญ: แค่ "เป็นเจ้าของ" มีดในฐานข้อมูล vorp_inventory ไม่พอ — ตรวจโค้ด
-- [VORP]/vorp_inventory/client/models/WeaponClass.lua (Weapon:equipwep()) แล้วพบว่ามีดจะ "มีจริง"
-- ในสายตาเกม (ให้ผลกับ native TASK_LOOT_ENTITY) ก็ต่อเมื่อผ่าน native GiveDelayedWeaponToPed แล้ว
-- เท่านั้น ซึ่งเกิดขึ้นเฉพาะตอนผู้เล่น "สวม/equip" มีดผ่าน flow ของ vorp_inventory เอง (กด Use ใน
-- กระเป๋า) เท่านั้น — id ที่คืนจากฟังก์ชันนี้เอาไปให้ client เรียก
-- (เดิม client เอา id นี้ไปสวมมีดให้อัตโนมัติ ตอนนี้เอาออกแล้ว — ผู้เล่นต้องถือมีดเอง)
-- (เรียกซ้ำได้ปลอดภัยแม้สวมอยู่แล้ว ไม่ใช่การเดา state)
local function findOwnedKnife(source)
    local ok, weapons = pcall(function() return exports.vorp_inventory:getUserInventoryWeapons(source) end)
    if not ok or type(weapons) ~= 'table' then return nil end
    for _, w in pairs(weapons) do
        for _, knifeName in ipairs(Config.KnifeWeapons or {}) do
            if w.name == knifeName then return w.id end
        end
    end
    return nil
end

-- ตั้ง despawn timer ให้ซากตัวนี้ครั้งเดียว (กันตั้งซ้ำถ้าถูก reject หลายรอบ) — ลบทิ้งถ้ายัง
-- ไม่ถูกถลกสำเร็จภายในเวลานี้ (กันซากค้างแผนที่ไม่รู้จบตอนกระเป๋าเต็มแล้วไม่มีใครกลับมาเก็บ)
-- ถ้าถลกสำเร็จไปแล้วก่อนถึงเวลานี้ ent จะถูกลบไปแล้วจาก path แจกรางวัลจริง -> DoesEntityExist เช็คพอ
local function scheduleAbandonedDespawn(netId, ent)
    if scheduledDespawn[netId] then return end
    scheduledDespawn[netId] = true
    SetTimeout(Config.AbandonedCarcassDespawnMs or 300000, function()
        scheduledDespawn[netId] = nil
        if ent and DoesEntityExist(ent) then
            dbg('abandoned carcass despawn (never collected): netId=%d', netId)
            DeleteEntity(ent)
        end
    end)
end

-- pre-check ก่อนเริ่มแอนิเมชันถลก (client เรียกตอนกด [E] ค้างครบ ก่อน TASK_LOOT_ENTITY) — กันเสียเวลา
-- เล่นท่าถลกเต็มๆ แล้วจบด้วยกระเป๋าเต็ม ซากยังไม่ถูกแตะต้อง (ไม่ mark/ลบ) แค่ตอบว่าถลกได้ไหมเฉยๆ
-- server ยังเช็ค canCarryItem ซ้ำอีกชั้นตอนแจกจริงเสมอ (ใน lp_hunting:sv:skin) อันนี้เป็นแค่ UX
-- คืน { ok = true } หรือ { ok = false, reason = 'noKnife'|'full'|'invalid' } ให้ client โชว์ข้อความที่ตรงเหตุ
VorpCore.Callback.Register('lp_hunting:cb:canSkin', function(source, cb, netId)
    netId = tonumber(netId)
    if not netId then return cb({ ok = false, reason = 'invalid' }) end

    local ent, _, _, possible = resolveCarcass(netId)
    if not ent then return cb({ ok = false, reason = 'invalid' }) end

    -- ยังเช็คว่า "เป็นเจ้าของมีด" ฝั่ง server ไว้เป็นด่านล่างสุด (client เช็ค "ถืออยู่ในมือ" อีกชั้น
    -- ก่อนเรียกมาถึงตรงนี้) — server มองไม่เห็นว่าอะไรอยู่ในมือจริง เลยยืนยันได้แค่ความเป็นเจ้าของ
    if not findOwnedKnife(source) then
        dbg('pre-check reject src=%d netId=%d: no knife', source, netId)
        return cb({ ok = false, reason = 'noKnife' })
    end

    -- เช็คที่ว่างสำหรับ "ทุกอย่างที่มีโอกาสดรอป" ไม่ใช่แค่ที่จะได้จริง — ยังไม่สุ่มตอนนี้
    -- (สุ่มตอนถลกเสร็จใน lp_hunting:sv:skin) กันเคสถลกจบแล้วของหล่นหายเพราะไม่มีที่
    local canCarry = true
    for _, item in ipairs(possible) do
        if not exports.vorp_inventory:canCarryItem(source, item, 1) then
            canCarry = false
            break
        end
    end

    if not canCarry then
        dbg('pre-check reject src=%d netId=%d: inventory full', source, netId)
        scheduleAbandonedDespawn(netId, ent) -- ซากยังอยู่ แต่ตั้งเวลาลบถ้าไม่มีใครกลับมาเก็บ
        return cb({ ok = false, reason = 'full' })
    end

    return cb({ ok = true })
end)

RegisterServerEvent('lp_hunting:sv:skin', function(netId)
    local _source = source
    netId = tonumber(netId)
    if not netId then return end

    -- (1) compare-and-set ก่อนเช็คอื่นใด — กัน race จาก event ซ้ำ/replay กับซากเดิม
    if handledCarcass[netId] then
        dbg('reject src=%d netId=%d: already handled', _source, netId)
        return
    end
    handledCarcass[netId] = true
    -- ล้าง lock อัตโนมัติหลัง TTL: netId ถูก engine รีไซเคิลหลังลบ entity ถ้าไม่ล้าง (ก) ตารางโตไม่จำกัด
    -- ตาม uptime (ข) ซากตัวใหม่ที่บังเอิญได้ netId เดิมจะโดนปฏิเสธถาวร ชำแหละไม่ได้ — 60 วิ นานพอกัน
    -- replay/event ซ้ำ แต่สั้นพอให้ netId ที่รีไซเคิลกลับมาใช้ได้ (การแจกจริงเกิดครั้งเดียวก่อนถึง timeout อยู่แล้ว)
    SetTimeout(60000, function() handledCarcass[netId] = nil end)

    -- (2) rate limit ต่อคน
    local now  = GetGameTimer()
    local last = cooldowns[_source]
    if last and (now - last) < (Config.RateLimitMs or 3000) then
        dbg('reject src=%d netId=%d: rate-limited', _source, netId)
        return
    end

    -- (3) resolve + ตรวจ entity
    local ent = NetworkGetEntityFromNetworkId(netId)
    if not ent or ent == 0 or not DoesEntityExist(ent) then
        dbg('reject src=%d netId=%d: entity not found', _source, netId)
        return
    end
    -- หมายเหตุ: IsEntityDead เป็น native ฝั่ง client เท่านั้น — เรียกฝั่ง server ใน RedM ไม่ได้
    -- (จะ error: attempt to call a nil value) การเช็ค "ตายจริง" จึงทำฝั่ง client แล้ว 2 ชั้น
    -- (prompt โผล่เฉพาะซากที่ IsEntityDead + เช็คซ้ำก่อนยิง server) การชำแหละสัตว์ที่ยังไม่ตาย
    -- ไม่ใช่ช่องโหว่เศรษฐกิจ (ได้ของเท่าเดิมกับที่ต้องฆ่าก่อนอยู่ดี) ส่วนเช็คที่กันโกงจริง
    -- (โมเดลอยู่ใน config / ระยะ / กัน dupe / rate limit) ยังอยู่ฝั่ง server ครบ
    local model = GetEntityModel(ent)
    local tier  = Config.SkinTiers[model]
    if not tier then
        dbg('reject src=%d netId=%d: model=%s not in SkinTiers', _source, netId, tostring(model))
        return
    end

    -- (4) ระยะฝั่ง server เอง
    local ped = GetPlayerPed(_source)
    if not ped or ped == 0 then return end
    local dist = #(GetEntityCoords(ped) - GetEntityCoords(ent))
    if dist > ((Config.Range or 2.0) + 1.0) then
        dbg('reject src=%d netId=%d: too far (%.2fm)', _source, netId, dist)
        return
    end

    -- (4.4) โซนห้ามชำแหละเพิ่มเติมของ lp_hunting เอง (Config.ExtraBlockedZones) — อิสระจาก nx_cityselect
    -- ทั้งหมด (ไม่ผ่าน export เลย) ใช้พิกัดซากจริงเช็คด้วย point-in-polygon ในไฟล์นี้เอง
    local extraZone = getExtraBlockedZoneAt(GetEntityCoords(ent))
    if extraZone then
        dbg('reject src=%d netId=%d: inside extra blocked zone (%s)', _source, netId, extraZone.id)
        TriggerClientEvent('pNotify:SendNotification', _source, {
            text = ('ห้ามชำแหละสัตว์ในเขต %s'):format(extraZone.label or extraZone.id),
            type = 'error',
            timeout = 4000,
        })
        return
    end

    -- (4.5) ห้ามชำแหละถ้าซากอยู่ในเขตเมือง (nx_cityselect ตัดสินฝั่ง server เอง ไม่เชื่อ client)
    -- ตำแหน่งซาก+ผู้เล่นอยู่ห่างกันไม่เกิน Config.Range อยู่แล้วจากข้อ (4) เลยเช็คจากซากตัวเดียวพอ
    -- ถ้า nx_cityselect ไม่ได้รันอยู่ (export ไม่มี) fail-open — ไม่บล็อคระบบล่าสัตว์ทั้งหมดเพราะ
    -- resource อื่นมีปัญหา แต่ dbg แจ้งไว้ให้เห็นใน console
    if Config.BlockInCityZones then
        local ok, result = pcall(function()
            return exports.nx_cityselect:GetCityAtCoords(GetEntityCoords(ent))
        end)
        if ok and result then
            dbg('reject src=%d netId=%d: inside city zone (%s)', _source, netId, tostring(result))
            TriggerClientEvent('pNotify:SendNotification', _source, {
                text = Config.CityZoneBlockedMsg or 'ห้ามชำแหละสัตว์ในเขตเมือง',
                type = 'error',
                timeout = 4000,
            })
            return
        elseif not ok then
            dbg('city-zone check failed (nx_cityselect not running?) -> fail-open, allowing skin. err=%s', tostring(result))
        end
    end

    -- (4.6) ต้องมีมีดถึงจะถลกได้จริง (ปกติ client เช็คผ่าน lp_hunting:cb:canSkin ก่อนเริ่มแอนิเมชันไปแล้ว —
    -- จุดนี้เป็น defense-in-depth เผื่อ client ถูกแก้ให้ยิง event นี้ตรงๆ ข้ามการเช็คก่อน)
    if not findOwnedKnife(_source) then
        dbg('reject src=%d netId=%d: no knife', _source, netId)
        TriggerClientEvent('pNotify:SendNotification', _source, {
            text = Config.RequireKnifeMsg or 'ต้องมีมีดในกระเป๋าถึงจะชำแหละได้',
            type = 'error',
            timeout = 4000,
        })
        handledCarcass[netId] = nil -- ไม่มีมีดไม่ใช่ความผิดของซาก ปลดล็อกให้ลองใหม่ได้หลังหามีดมา
        scheduleAbandonedDespawn(netId, ent)
        return
    end

    local user = VorpCore.getUser(_source)
    if not user then return end
    local Character = user.getUsedCharacter
    if not Character then return end

    -- (5) สุ่มของจริงตามกลุ่มสัตว์ (ดู Config.GroupLoot) — server สุ่มเองทั้งหมด client ไม่มีสิทธิ์
    local group = tier.group or 'other'
    local rolled = rollLootForGroup(group)

    -- กลุ่มที่เป็น rolls ล้วน (หมี) มีโอกาสพลาดครบทุกอย่าง = ไม่ได้อะไรเลย
    -- ถือว่าถลกสำเร็จตามปกติ (ซากหายไป ได้ XP) แค่ไม่มีของติดมือ
    if #rolled == 0 then
        Character.addXp(Config.Xp or 1)
        cooldowns[_source] = now
        DeleteEntity(ent)
        TriggerClientEvent('pNotify:SendNotification', _source, {
            text = ('ชำแหละ%sสำเร็จ แต่ไม่ได้ของติดมือ (+%d XP)'):format(
                tier.name and (tier.name .. ' ') or '', Config.Xp or 1),
            type = 'info',
            timeout = 4000,
        })
        TriggerEvent('lp_leaderboard:SV:HuntSkin', { src = _source, amount = 0 })
        dbg('grant src=%d netId=%d model=%s animal=%s group=%s items=(none) xp=%d',
            _source, netId, tostring(model), tier.name or '?', group, Config.Xp or 1)
        return
    end

    -- canCarryItem ก่อน addItem เสมอ (mirror vorp_hunting) — เช็คเฉพาะของที่สุ่มได้จริงรอบนี้
    -- ปกติ client เช็คผ่าน lp_hunting:cb:canSkin ก่อนเริ่มแอนิเมชันไปแล้ว (ไม่ควรมาถึงตรงนี้ถ้าเต็ม)
    -- จุดนี้เป็น defense-in-depth เผื่อ client เก่า/ถูกแก้ข้ามการเช็คก่อน
    for _, item in ipairs(rolled) do
        if not exports.vorp_inventory:canCarryItem(_source, item, 1) then
            TriggerClientEvent('pNotify:SendNotification', _source, {
                text = 'กระเป๋าเต็ม ไม่สามารถชำแหละได้',
                type = 'error',
                timeout = 4000,
            })
            handledCarcass[netId] = nil -- กระเป๋าเต็มไม่ใช่ความผิดของซาก ปลดล็อกให้ลองใหม่ได้หลังเคลียร์กระเป๋า
            scheduleAbandonedDespawn(netId, ent) -- ซากยังอยู่ แต่ตั้งเวลาลบถ้าไม่มีใครกลับมาเก็บ
            return
        end
    end

    -- (6) แจกของจริง
    for _, item in ipairs(rolled) do
        exports.vorp_inventory:addItem(_source, item, 1)
    end
    local granted = #rolled
    Character.addXp(Config.Xp or 1)
    cooldowns[_source] = now

    DeleteEntity(ent) -- ลบซากทิ้ง sync ทุก client

    TriggerClientEvent('pNotify:SendNotification', _source, {
        text = ('ชำแหละ%sสำเร็จ ได้รับของ %d ชิ้น (+%d XP)'):format(
            tier.name and (tier.name .. ' ') or '', granted, Config.Xp or 1),
        type = 'success',
        timeout = 4000,
    })

    -- ยิงต่อ lp_leaderboard (หมวด HUNTING RANK) — soft integration ไม่ depend ตรง เงียบถ้าไม่มี resource นี้
    -- ชื่อ event ต้องตรงกับ Events.huntSkin ใน [LP]/lp_leaderboard/shared/sh_events.lua
    -- (lp_hunting มองไม่เห็นตาราง Events ของ lp_leaderboard ข้าม resource เลยต้องใช้ literal string ตรงนี้)
    -- amount = จำนวนไอเทมจริงที่แจก (นก = 1, สัตว์มีหนัง = 2)
    TriggerEvent('lp_leaderboard:SV:HuntSkin', { src = _source, amount = granted })

    dbg('grant src=%d netId=%d model=%s animal=%s group=%s items=%s xp=%d',
        _source, netId, tostring(model), tier.name or '?', group,
        table.concat(rolled, ','), Config.Xp or 1)
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)
