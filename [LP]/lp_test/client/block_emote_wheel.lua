-- block_emote_wheel.lua — บล็อกการเปิด emote wheel
--
-- อ้างอิง: femga/rdr3_discoveries — Controls/README.md
--   ไม่มี CPED_CONFIG_FLAG สำหรับปิด emote wheel โดยตรง (เช็คแล้วใน AI/CPED_CONFIG_FLAGS/README.md
--   มีแค่ PCF_IsPerformingEmote/PCF_IsPerformingWeaponEmote ซึ่งเป็นสถานะอ่านอย่างเดียว ไม่ใช่ตัวปิดกั้น)
--   วิธีที่ถูกต้องคือบล็อกที่ control ซึ่งเปิดวงล้อโดยตรง:
--     0xE2B557A3 = INPUT_OPEN_EMOTE_WHEEL       (Tab / RB — ตอนยืน/เดิน)
--     0x8B3FA65E = INPUT_OPEN_EMOTE_WHEEL_HORSE (Tab / RB — ตอนขี่ม้า)

local INPUT_OPEN_EMOTE_WHEEL       = 0xE2B557A3
local INPUT_OPEN_EMOTE_WHEEL_HORSE = 0x8B3FA65E

Citizen.CreateThread(function()
    while true do
        DisableControlAction(0, INPUT_OPEN_EMOTE_WHEEL, true)
        DisableControlAction(0, INPUT_OPEN_EMOTE_WHEEL_HORSE, true)
        Citizen.Wait(0)
    end
end)
