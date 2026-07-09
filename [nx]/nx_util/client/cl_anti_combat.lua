local RESOURCE_NAME = GetCurrentResourceName()

local Controls = {
    INPUT_ATTACK = 0x07CE1E61, -- Left click / primary attack: blocks running tackle, takedown, execute when melee/unarmed.
    INPUT_ATTACK2 = 0x0283C582, -- Secondary attack: blocks alternate contextual melee follow-up.
    INPUT_CONTEXT_RT = 0x07B8BEAF, -- Context right trigger: blocks close-range contextual attack prompts.

    INPUT_MELEE_ATTACK = 0xB2F377E8, -- Melee strike: blocks punch/slash contextual melee attacks.
    INPUT_MELEE_GRAPPLE_ATTACK = 0xADEAF48C, -- Grapple attack: blocks attack while holding/grappling.
    INPUT_MELEE_GRAPPLE = 0x2277FAE9, -- Grapple start: blocks grab/tackle contextual melee.
    INPUT_MELEE_GRAPPLE_CHOKE = 0x018C47CF, -- Grapple choke: blocks choke/strangle action.
    INPUT_MELEE_GRAPPLE_REVERSAL = 0x91C9A817, -- Grapple reversal: blocks contextual reversal chain.
    INPUT_MELEE_GRAPPLE_STAND_SWITCH = 0xBE1F4699, -- Grapple stand switch: blocks stand-position grapple switching.
    INPUT_MELEE_MODIFIER = 0x1E7D7275, -- Melee modifier: blocks heavy/contextual melee modifier.
    INPUT_MELEE_BLOCK = 0xB5EEEFB7, -- Melee block: blocks melee contextual block chain.

    INPUT_HOGTIE = 0xD9C50532, -- Hogtie: blocks hogtie attempt near another player.
    INPUT_INTERACT_LOCKON_NEG = 0x26A18F47, -- Interaction lock-on negative: blocks negative/push-style interaction prompt.
    INPUT_INTERACT_LOCKON = 0xF8982F00, -- Interaction lock-on: blocks close player/NPC contextual interaction lock.
    INPUT_CONTEXT_B = 0x3B24C470, -- Context B/F-style prompt: blocks shove/push/contextual melee interaction.
    INPUT_INTERACT_HIT_CARRIABLE = 0x0522B243, -- Hit carriable interaction: blocks contextual hit/carryable melee interaction.
}

local AlwaysBlockedControls = {
    Controls.INPUT_MELEE_ATTACK,
    Controls.INPUT_MELEE_MODIFIER,
    Controls.INPUT_MELEE_BLOCK,
    Controls.INPUT_HOGTIE,
    Controls.INPUT_INTERACT_HIT_CARRIABLE,
}

local RoleplayThreatControls = {
    Controls.INPUT_MELEE_GRAPPLE, -- Needed by some choke/hold animations.
    Controls.INPUT_MELEE_GRAPPLE_ATTACK, -- Needed by some grapple threat follow-up animations.
    Controls.INPUT_MELEE_GRAPPLE_CHOKE, -- Needed for choke/strangle RP animations.
    Controls.INPUT_MELEE_GRAPPLE_REVERSAL,
    Controls.INPUT_MELEE_GRAPPLE_STAND_SWITCH,
    Controls.INPUT_INTERACT_LOCKON_NEG,
    Controls.INPUT_INTERACT_LOCKON,
    Controls.INPUT_CONTEXT_B,
    Controls.INPUT_CONTEXT_RT, -- Needed by some knife/gun threat contextual prompts.
}

local ConditionalAttackControls = {
    Controls.INPUT_ATTACK,
    Controls.INPUT_ATTACK2,
}

local MeleeWeapons = {
    [GetHashKey('WEAPON_UNARMED')] = true,
    [GetHashKey('WEAPON_MELEE_KNIFE')] = true,
    [GetHashKey('WEAPON_MELEE_KNIFE_JAWBONE')] = true,
    [GetHashKey('WEAPON_MELEE_KNIFE_MINER')] = true,
    [GetHashKey('WEAPON_MELEE_KNIFE_CIVIL_WAR')] = true,
    [GetHashKey('WEAPON_MELEE_KNIFE_VAMPIRE')] = true,
    [GetHashKey('WEAPON_MELEE_HATCHET')] = true,
    [GetHashKey('WEAPON_MELEE_HATCHET_HUNTER')] = true,
    [GetHashKey('WEAPON_MELEE_MACHETE')] = true,
    [GetHashKey('WEAPON_MELEE_CLEAVER')] = true,
    [GetHashKey('WEAPON_MELEE_TORCH')] = true,
    [GetHashKey('WEAPON_MELEE_LANTERN')] = true,
    [GetHashKey('WEAPON_MELEE_DAVY_LANTERN')] = true,
}

local function DebugPrint(message)
    if Config.AntiCombat.Debug then
        print(('[%s] %s'):format(RESOURCE_NAME, message))
    end
end

local function IsNearOtherPlayer(ped, radius)
    local players = GetActivePlayers()
    local playerId = PlayerId()
    local pedCoords = GetEntityCoords(ped)
    local radiusSq = radius * radius

    for i = 1, #players do
        local targetPlayer = players[i]

        if targetPlayer ~= playerId then
            local targetPed = GetPlayerPed(targetPlayer)

            if targetPed ~= 0 and DoesEntityExist(targetPed) and not IsEntityDead(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local dx = pedCoords.x - targetCoords.x
                local dy = pedCoords.y - targetCoords.y
                local dz = pedCoords.z - targetCoords.z

                if (dx * dx) + (dy * dy) + (dz * dz) <= radiusSq then
                    return true
                end
            end
        end
    end

    return false
end

local function IsRunningOrSprinting(ped)
    return IsPedRunning(ped) or IsPedSprinting(ped)
end

local function IsHoldingMeleeWeapon(ped)
    local hasWeapon, weaponHash = GetCurrentPedWeapon(ped, true, 0, true)

    -- RedM can return false/0 while unarmed or during weapon transitions; treat it as unarmed.
    if not hasWeapon or weaponHash == nil or weaponHash == 0 then
        return true
    end

    return MeleeWeapons[weaponHash] == true
end

local function ShouldBlockCombat(ped)
    local antiCombat = Config.AntiCombat

    if not antiCombat.Enable then
        return false
    end

    if ped == 0 or not DoesEntityExist(ped) then
        return false
    end

    if IsEntityDead(ped) or IsPedDeadOrDying(ped, true) then
        return false
    end

    if IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false) then
        return false
    end

    if antiCombat.OnlyWhenRunning and not IsRunningOrSprinting(ped) then
        return false
    end

    return IsNearOtherPlayer(ped, antiCombat.ProximityRadius or 2.2)
end

local function ShouldBlockAttackControls(ped)
    local antiCombat = Config.AntiCombat

    if antiCombat.AllowShootingWhenAiming and IsPlayerFreeAiming(PlayerId()) then
        return false
    end

    if antiCombat.BlockAttackOnlyMeleeWeapon and not IsHoldingMeleeWeapon(ped) then
        return false
    end

    return true
end

local function DisableCombatControls(ped)
    for i = 1, #AlwaysBlockedControls do
        DisableControlAction(0, AlwaysBlockedControls[i], true)
    end

    if Config.AntiCombat.BlockRoleplayThreatActions then
        for i = 1, #RoleplayThreatControls do
            DisableControlAction(0, RoleplayThreatControls[i], true)
        end
    end

    if ShouldBlockAttackControls(ped) then
        for i = 1, #ConditionalAttackControls do
            DisableControlAction(0, ConditionalAttackControls[i], true)
        end
    end
end

CreateThread(function()
    Wait(1000)
    DebugPrint('AntiCombat started')

    while true do
        local sleep = 500
        local antiCombat = Config.AntiCombat

        if antiCombat.Enable then
            local ped = PlayerPedId()

            if ShouldBlockCombat(ped) then
                DisableCombatControls(ped)
                sleep = 0
            end
        else
            sleep = 1000
        end

        Wait(sleep)
    end
end)
