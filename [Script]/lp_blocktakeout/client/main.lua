-- lp_blocktakeout — ป้องกัน exploit "one-hit kill" ผ่าน SetPedConfigFlag
--
-- อ้างอิง: femga/rdr3_discoveries — AI/CPED_CONFIG_FLAGS/README.md
--   flag 138 = PCF_OneShotWillKillPed        โดนโจมตี 1 ครั้งตายทันที ไม่ว่าเลือดเหลือเท่าไหร่
--   flag  21 = PCF_ForceControlledKnockout   เอกสารระบุตรงๆ ว่า "this ped will be killed by any strong hit"
--
-- ทั้งสอง flag ปกติเป็น false สำหรับ player ped อยู่แล้ว ถ้ามีอะไรไปสั่ง true ใส่ ped ของเรา
-- (cheat/exploit/สคริปบั๊ก) เราจะตายจากการโดนตีแค่ครั้งเดียว — thread นี้รีเซ็ตกลับเป็น false
-- ให้ ped ของตัวเองตลอดเวลา (client-side self-protection เท่านั้น ไม่แตะ ped ผู้เล่นคนอื่น)

local FLAG_ONE_SHOT_KILL        = 138 -- PCF_OneShotWillKillPed
local FLAG_FORCE_CTRL_KNOCKOUT  = 21  -- PCF_ForceControlledKnockout

Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        SetPedConfigFlag(ped, FLAG_ONE_SHOT_KILL, false)
        SetPedConfigFlag(ped, FLAG_FORCE_CTRL_KNOCKOUT, false)
        Citizen.Wait(0)
    end
end)
