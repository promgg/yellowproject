Config = {}

Config['CoolDown'] = 1 -- นาที (Cooldown เป็นเวลา 1 นาที)
Config['SaveData'] = 5 -- นาที (บันทึกข้อมูลทุก 5 นาที)
Config['ChangeClothes'] = false -- true = เปิดการเปลี่ยนเสื้อผ้า, false = ปิดการเปลี่ยนเสื้อผ้า
Config['Animations'] = {"mech_loco_m@generic@injured@unarmed@left_leg@idle", "idle"} -- การตั้งค่าแอนิเมชันที่ใช้

Config['DisableControl'] = function (inDisable)
    if not inDisable then
        DisableControlAction(0, 0xD9D0E1C0, false)
        DisableControlAction(0, 0x8FFC75D6, false)
        DisablePlayerFiring(PlayerPedId(), false)
        DisableControlAction(0, 0x07CE1E61, false)
        DisableControlAction(0, 0xB2F377E8, false)

        DisableControlAction(0, 1, false) -- LookLeftRight
        DisableControlAction(0, 2, false) -- LookUpDown
        DisableControlAction(0, 142, false) -- MeleeAttackAlternate
        DisableControlAction(0, 18, false) -- Enter
        DisableControlAction(0, 322, false) -- ESC
        DisableControlAction(0, 106, false) -- VehicleMouseControlOverride
    else
        SetCurrentPedWeapon(PlayerPedId(), "WEAPON_UNARMED", true)
        DisableControlAction(0, 0xD9D0E1C0, true)
        DisableControlAction(0, 0x8FFC75D6, true)
        DisablePlayerFiring(PlayerPedId(), true)
        DisableControlAction(0, 0x07CE1E61, true)
        DisableControlAction(0, 0xB2F377E8, true)

        DisableControlAction(0, 1, true) -- LookLeftRight
        DisableControlAction(0, 2, true) -- LookUpDown
        DisableControlAction(0, 142, true) -- MeleeAttackAlternate
        DisableControlAction(0, 18, true) -- Enter
        DisableControlAction(0, 322, true) -- ESC
        DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
    end
end
