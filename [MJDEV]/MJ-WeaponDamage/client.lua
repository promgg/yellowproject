local DAMAGE_MODIFIER = {}
local WEAPON_NAME = {}
local CRITICAL_HIT = {}
for k,v in ipairs(Config.WeaponDamage) do
    DAMAGE_MODIFIER[GetHashKey(v.Name)] = v.Damage
    WEAPON_NAME[GetHashKey(v.Name)] = v.Name
    CRITICAL_HIT[GetHashKey(v.Name)] = v.EnableCritical
end

if Config.PvPDamageOnly then
    CreateThread(function()
        while true do
            Wait(500)
            local ped = PlayerPedId()
            local _, wep = GetCurrentPedWeapon(ped)
            if DAMAGE_MODIFIER[wep] ~= nil then
                -- ตั้งค่าดาเมจให้เท่ากันทุกจุดของร่างกาย
                Citizen.InvokeNative(0xD04AD186CE8BB129, PlayerId(), wep, DAMAGE_MODIFIER[wep]) -- เปลี่ยนค่าดาเมจอาวุธ
                if Config.OneShotHeadshot then 
                    Citizen.InvokeNative(0x2F70A7A76033E58E, ped, false) -- ปิดการยิงหัวนัดเดียวตาย
                end
            else
                -- ใช้ค่าเริ่มต้นถ้าอาวุธไม่มีการตั้งค่า
                Citizen.InvokeNative(0xD04AD186CE8BB129, PlayerId(), wep, 1.0)
                if Config.OneShotHeadshot then 
                    Citizen.InvokeNative(0x2F70A7A76033E58E, ped, false) -- ปิดการยิงหัวนัดเดียวตาย
                end
            end
        end
    end)
else
    CreateThread(function()
        while true do
            Wait(500)

            local ped = PlayerPedId()
            local _, wep = GetCurrentPedWeapon(ped)

            -- SetPlayerWeaponTypeDamageModifier
            if DAMAGE_MODIFIER[wep] ~= nil then
                -- print('Set damage', WEAPON_NAME[wep], DAMAGE_MODIFIER[wep])
                Citizen.InvokeNative(0xD04AD186CE8BB129, PlayerId(), wep, DAMAGE_MODIFIER[wep])
            end
        end
    end)
end


CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local _, wep = GetCurrentPedWeapon(ped)

        if Config.PvPDamageOnly then
            for k,v in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(v)
                local noCriticalHit = CRITICAL_HIT[wep] == false
                SetPedConfigFlag(ped, 263, noCriticalHit) -- No Critical Hits
                SetPedConfigFlag(ped, 340, noCriticalHit) -- No Melee Finish
                SetPedConfigFlag(ped, 388, noCriticalHit) -- Disable Fatally Wounded Behaviour (From bullets)
            end
        else
            for k,v in ipairs(GetGamePool('CPed')) do
                local ped = v
                local noCriticalHit = CRITICAL_HIT[wep] == false
                SetPedConfigFlag(ped, 263, noCriticalHit) -- No Critical Hits
                SetPedConfigFlag(ped, 340, noCriticalHit) -- No Melee Finish
                SetPedConfigFlag(ped, 388, noCriticalHit) -- Disable Fatally Wounded Behaviour (From bullets)
            end
        end

        Wait(1000)
    end
end)

-- Reset modifiers
AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then
        local ped = PlayerPedId()
        for wep,damage in pairs(DAMAGE_MODIFIER) do
            Citizen.InvokeNative(0xD04AD186CE8BB129, PlayerId(), wep, 1.0)
            Citizen.InvokeNative(0xD77AE48611B7B10A, ped, 1.0)
            if Config.OneShotHeadshot then 
                Citizen.InvokeNative(0x2F70A7A76033E58E, ped, true) -- เปิดกลับให้ยิงหัวแรงเหมือนเดิม
            end
        end

        for k,v in ipairs(GetGamePool('CPed')) do
            SetPedConfigFlag(v, 263, false) -- No Critical Hits
            SetPedConfigFlag(v, 340, false) -- No Melee Finish
            SetPedConfigFlag(v, 388, false) -- Disable Fatally Wounded Behaviour (From bullets)
        end
    end
end)
