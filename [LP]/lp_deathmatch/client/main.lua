LP_DM = LP_DM or {}

-- ── ฝั่ง client ไม่ตรวจจับการตายเอง ──
--
-- เดิมไฟล์นี้ดักการตายด้วย AddEventHandler('gameEventTriggered') + 'CEventNetworkEntityDamage'
-- ซึ่งเป็น game event ของ GTA5 ไม่ยิงบน RDR3 เลย โค้ดทั้งบล็อกจึงไม่เคยทำงานแม้แต่ครั้งเดียว
-- (ไม่มี error ให้เห็นด้วย เพราะ handler แค่ไม่ถูกเรียก — ทั้งระบบเลยเงียบสนิททั้งสองฝั่ง)
--
-- ตัวอย่างที่เคยเข้าใจผิดว่าเป็นหลักฐานยืนยัน ล้วนเป็นโค้ด GTA5:
--   [gameplay]/[examples]/ped-money-drops  -> fxmanifest ระบุ game 'gta5'
--   [standalone]/PolyZone/EntityZone.lua   -> dead code ที่ยกมาจากไลบรารีต้นฉบับฝั่ง GTA5
--                                             ทั้งโปรเจกต์ไม่มีใครเรียก EntityZone เลยสักที่
--
-- ของจริงบน RDR3: vorp_core/client/respawnsystem.lua:218-236 poll IsPlayerDead() แล้วอ่าน
-- GetPedSourceOfDeath + GetPedCauseOfDeath จากนั้นยิง vorp_core:Server:OnPlayerDeath ให้เลย
-- ข้อมูลที่ได้ครบตรงกับที่ระบบนี้ต้องใช้ทุกตัว server จึงไปฟัง event นั้นตรงๆ (server/main.lua)
-- ไม่ต้องมีโค้ดตรวจจับการตายฝั่ง client อีก — และไม่ต้องเชื่อ client เรื่องว่าใครฆ่าใครด้วย
--
-- pattern เดียวกับที่ lp_leaderboard/server/sv_main.lua:247 และ
-- lp_airdropteam/core/server_team.lua:214 ใช้อยู่แล้วในโปรเจกต์นี้

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    LP_DM.Scoreboard.Hide()
end)
