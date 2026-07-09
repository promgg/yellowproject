--[[
    lp_test — gfx_minimap_test

    ทดสอบว่า SET_SCRIPT_GFX_ALIGN / SET_SCRIPT_GFX_ALIGN_PARAMS "ย้าย" มินิแมพได้จริงไหมใน RDR3
    (ไม่มีใครยืนยันในรีโป rdr3_discoveries — เทคนิคนี้ใช้ได้ผลกับ GTA5 แต่ radar ของ RDR3
    อาจไม่ได้วาดผ่าน per-frame script draw call แบบเดียวกัน เลยอาจไม่มีผลกับ DisplayRadar เลยก็ได้)

    ------------------------------------------------------------------
    USAGE (F8 console)
    ------------------------------------------------------------------
    /gfx_minimap_test              -- เปิด ลองย้ายไปตำแหน่งทดสอบ (0.5, 0.1 = กลางบนจอ ต่างจากตำแหน่งปกติชัดเจน)
    /gfx_minimap_test <x> <y>      -- เปิด กำหนดตำแหน่งเอง (ค่า 0.0-1.0 = สัดส่วนจอ ซ้าย/บนไปขวา/ล่าง)
    /gfx_minimap_test off          -- ปิด กลับไปตำแหน่งปกติ
    ------------------------------------------------------------------
]]

local active = false
local alignX, alignY = 0.5, 0.1

-- 'L'/'C'/'R' และ 'T'/'C'/'B' เป็นค่า ASCII ตามที่ native ตัวนี้ใช้ใน GTA5 (76/67/82 และ 84/67/66)
local ALIGN_LEFT, ALIGN_TOP = 76, 84

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if active then
            -- ห่อ DisplayRadar ไว้ในสโคป align ทุกเฟรม เผื่อ radar ต้องถูก "วาด" ใหม่ภายใต้ align ถึงจะขยับ
            pcall(function()
                SetScriptGfxAlign(ALIGN_LEFT, ALIGN_TOP)
                SetScriptGfxAlignParams(alignX, alignY, 0.0, 0.0)
                DisplayRadar(true)
                ResetScriptGfxAlign()
            end)
        end
    end
end)

RegisterCommand('gfx_minimap_test', function(_, args)
    if args[1] == 'off' then
        active = false
        DisplayRadar(true) -- คืนค่าปกติเผื่อ align ค้าง
        print('[lp_test] gfx_minimap_test: OFF (กลับตำแหน่งปกติ)')
        return
    end

    local x = tonumber(args[1]) or alignX
    local y = tonumber(args[2]) or alignY
    alignX, alignY = x, y
    active = true
    print(('[lp_test] gfx_minimap_test: ON -> x=%.2f y=%.2f (ดูมินิแมพว่าขยับไปตำแหน่งนี้ไหม — ถ้าไม่ขยับแปลว่า native นี้ไม่มีผลกับ radar ใน RDR3)'):format(x, y))
end, false)

AddEventHandler('onResourceStop', function(name)
    if GetCurrentResourceName() ~= name then return end
    active = false
    pcall(DisplayRadar, true)
end)
