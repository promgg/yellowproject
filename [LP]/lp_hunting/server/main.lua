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

local cooldowns      = {} -- [src] = GetGameTimer() ล่าสุดที่ชำแหละสำเร็จ (rate limit)
local handledCarcass = {} -- [netId] = true (anti-dupe compare-and-set)

local function dbg(fmt, ...)
    if Config.Debug then print(('[lp_hunting] ' .. fmt):format(...)) end
end

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

    local user = VorpCore.getUser(_source)
    if not user then return end
    local Character = user.getUsedCharacter
    if not Character then return end

    -- resolve ไอเทม: เนื้อจาก tier.meat (บังคับทุกตัว), หนังจาก tier.hide ผ่าน Config.HideRankToItemsKey
    -- (ดูคอมเมนต์ใน config.lua — Items ใช้ key ร่วมกัน small/medium/large แทนทั้ง 2 แกน)
    -- สัตว์บางชนิด (นก) ไม่มี key `hide` = แจกเฉพาะเนื้อ
    local meatBucket = Config.Items[tier.meat]
    if not meatBucket then
        dbg('reject src=%d netId=%d: bad tier config (meat=%s)', _source, netId, tostring(tier.meat))
        handledCarcass[netId] = nil -- บั๊ก config ไม่ควรเผาซากทิ้งถาวร
        return
    end
    local meatItem = meatBucket.meat

    local hideItem = nil
    if tier.hide then
        local hideKey    = Config.HideRankToItemsKey[tier.hide]
        local hideBucket = hideKey and Config.Items[hideKey]
        if not hideBucket then
            dbg('reject src=%d netId=%d: bad tier config (hide=%s)', _source, netId, tostring(tier.hide))
            handledCarcass[netId] = nil
            return
        end
        hideItem = hideBucket.hide
    end

    -- (5) canCarryItem ก่อน addItem เสมอ (mirror vorp_hunting) — หนังเช็คเฉพาะเมื่อสัตว์ตัวนี้มีหนัง
    if not exports.vorp_inventory:canCarryItem(_source, meatItem, 1)
        or (hideItem and not exports.vorp_inventory:canCarryItem(_source, hideItem, 1)) then
        TriggerClientEvent('pNotify:SendNotification', _source, {
            text = 'กระเป๋าเต็ม ไม่สามารถชำแหละได้',
            type = 'error',
            timeout = 4000,
        })
        handledCarcass[netId] = nil -- กระเป๋าเต็มไม่ใช่ความผิดของซาก ปลดล็อกให้ลองใหม่ได้หลังเคลียร์กระเป๋า
        return
    end

    -- (6) แจกของจริง — เนื้อเสมอ, หนังถ้ามี
    exports.vorp_inventory:addItem(_source, meatItem, 1)
    local granted = 1
    if hideItem then
        exports.vorp_inventory:addItem(_source, hideItem, 1)
        granted = 2
    end
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

    dbg('grant src=%d netId=%d model=%s animal=%s items=%s%s xp=%d',
        _source, netId, tostring(model), tier.name or '?', meatItem,
        hideItem and (',' .. hideItem) or '', Config.Xp or 1)
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)
