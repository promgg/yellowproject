--[[
    lp_test — block_grapple

    เป้าหมาย: จับคน (grab/human shield ด้วยแตะ E) ได้ปกติ แต่ "ฆ่าปิดฉาก" (execute — เชือดคอ
    ตอนถือมีด/บีบคอ/ตี) ระหว่างจับ ไม่ได้

    ประวัติที่ลองมา (ไม่ได้ผลทั้งหมด):
      v1/v2  ped config flag 169 (PCF_DisableGrappleByPlayer) — ไม่ใช่ตัวคุมกลไกนี้
      v3     DisableControlAction ทุก grapple control — ได้ผลแต่กันการจับ (E) ด้วย เกินสโคป
      v4     บล็อกแค่ INPUT_MELEE_GRAPPLE_CHOKE — execute ด้วยมีดยังทำได้ (คนละ input)
      v5     flag 137/340 (takedown-disable) ฝั่งเป้าหมาย — ยังเชือดได้อยู่ ไม่ใช่ตัวนี้

    v6 (ตัวนี้) — วิธีที่ทนทานสุด: เลิกเดา input ทีละตัว ใช้ native ตรวจ "สถานะกำลังจับคนอยู่จริง"
    แล้วบล็อก input ฝั่งฆ่า "เฉพาะตอนนั้น" เท่านั้น (ไม่กระทบยิงปืน/ต่อยปกติเลย ไม่ว่า execute จะ
    ผูก input ตัวไหนก็โดนกันหมดเพราะบล็อกทุกปุ่มโจมตีระหว่าง grapple)

    native (ยืนยัน hash + signature จาก VORPCORE/RDR3natives DB):
      GET_PED_IS_GRAPPLING   0x0E99E3BF11BB6367 (ped) -> BOOL   กำลังจับคนอื่นอยู่ไหม
      GET_PED_GRAPPLE_STATE  0x2311F15D971AA680 (ped) -> int    สถานะ grapple (debug ไว้ดูค่า)

    ยังไม่ยืนยันด้วยการเทสในเกมจริง — debug ไว้ให้ดูว่า native ตรวจสถานะได้จริงไหม และค่า state
    เปลี่ยนยังไงตอนจับ/ตอนกดฆ่า ถ้า GET_PED_IS_GRAPPLING ไม่เคยเป็น true = native marshalling
    เพี้ยน (จะสลับไปใช้ Citizen.ResultAsInteger); ถ้าเป็น true แต่ยังเชือดได้ = ต้องบล็อก input
    เพิ่ม (ดูจากค่า state ว่าเฟสฆ่าคือ state ไหน แล้วเจาะเฉพาะเฟสนั้น)
]]

-- input ฝั่ง "ฆ่า/ทำร้าย" ที่จะบล็อกเฉพาะตอนกำลังจับคนอยู่ (ไม่รวม INPUT_MELEE_GRAPPLE ตัวจับ
-- และไม่รวม BREAKOUT/REVERSAL เพื่อให้ปล่อย/ดิ้นหลุดได้ปกติ)
local KILL_CONTROLS = {
    0x07CE1E61, -- INPUT_ATTACK             (คลิกซ้าย — เชือดคอตอนถือมีด)
    0xB2F377E8, -- INPUT_MELEE_ATTACK
    0xADEAF48C, -- INPUT_MELEE_GRAPPLE_ATTACK (F — ตี)
    0x018C47CF, -- INPUT_MELEE_GRAPPLE_CHOKE  (กด E ค้าง — บีบคอ)
    0xD9C50532, -- INPUT_HOGTIE               (F — มัด)
}

local GET_PED_IS_GRAPPLING  = 0x0E99E3BF11BB6367
local GET_PED_GRAPPLE_STATE = 0x2311F15D971AA680

local DEBUG_GRAPPLE_BLOCK = true
local lastState = nil

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        local raw = Citizen.InvokeNative(GET_PED_IS_GRAPPLING, ped)
        local isGrappling = (raw == true or raw == 1)

        if isGrappling then
            for _, hash in ipairs(KILL_CONTROLS) do
                DisableControlAction(0, hash, true)
            end
        end

        if DEBUG_GRAPPLE_BLOCK then
            -- log เฉพาะตอนสถานะเปลี่ยน (กันสแปมทุกเฟรม)
            local state = Citizen.InvokeNative(GET_PED_GRAPPLE_STATE, ped, Citizen.ResultAsInteger())
            local key = tostring(isGrappling) .. ':' .. tostring(state)
            if key ~= lastState then
                lastState = key
                print(('[lp_test:grappleblock] isGrappling=%s (raw=%s) grappleState=%s')
                    :format(tostring(isGrappling), tostring(raw), tostring(state)))
            end
        end
    end
end)
