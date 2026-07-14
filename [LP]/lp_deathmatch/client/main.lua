LP_DM = LP_DM or {}

-- ── ผู้ตายรายงานการตายของตัวเอง (server ยัง verify ทุกจุดอยู่ดี ดู server/event.lua) ──
-- หมายเหตุความไม่แน่นอน: โครงสร้าง args ของ CEventNetworkEntityDamage ไม่มีเอกสารทางการที่แน่ชัดจาก
-- Rockstar/CFX ตำแหน่ง args[1]=victim, args[2]=culprit, args[4]=isDead ยืนยันแล้วจากตัวอย่างในโปรเจกต์นี้เอง
-- ([gameplay]/[examples]/ped-money-drops/client.lua) แต่ตำแหน่ง weaponHash (args[6] ด้านล่าง) เป็นค่าที่อ้างอิง
-- จาก convention ทั่วไปของ FiveM/RDR3 เท่านั้น ยังไม่ได้ทดสอบกับเกมจริง — เปิด Config.Debug แล้วดู args ที่ print
-- ออกมา ถ้าตำแหน่งไม่ตรง (นับแต้มผิดอาวุธ/ไม่นับเลย) ให้ปรับ index ตรงนี้
AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end

    local victim = args[1]
    local culprit = args[2]
    local isDead = args[4] == 1

    if not isDead or victim ~= PlayerPedId() then return end

    if Config.Debug then
        print(('[lp_deathmatch] death event args: %s'):format(json.encode(args)))
    end

    if not culprit or culprit == 0 or not DoesEntityExist(culprit) then return end
    if not IsPedAPlayer(culprit) then return end -- ฆ่าโดย NPC/สัตว์ ไม่นับแต้ม

    local playerIndex = NetworkGetPlayerIndexFromPed(culprit)
    local killerServerId = GetPlayerServerId(playerIndex)
    if not killerServerId or killerServerId <= 0 then return end

    local weaponHash = args[6]
    TriggerServerEvent('lp_deathmatch:server:reportDeath', killerServerId, weaponHash)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    LP_DM.Scoreboard.Hide()
end)
