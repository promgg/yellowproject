local RESOURCE_NAME = GetCurrentResourceName()

local SET_PED_ACTION_DISABLE_FLAG = 0xB8DE69D9473B7593
local CLEAR_PED_ACTION_DISABLE_FLAG = 0x949B2F9ED2917F5D
local actionFlagsPed = 0
local appliedActionFlags = {}

local function GetConfiguredActionFlags()
    local result = {}
    local seen = {}
    local config = Config.ActionDisableFlags

    if type(config) ~= 'table' or type(config.Flags) ~= 'table' then
        return result
    end

    for i = 1, #config.Flags do
        local flag = tonumber(config.Flags[i])
        if flag and flag >= 0 and flag <= 34 and not seen[flag] then
            seen[flag] = true
            result[#result + 1] = flag
        end
    end

    return result
end

local function ClearActionDisableFlags(ped)
    if ped == 0 or not DoesEntityExist(ped) then
        appliedActionFlags = {}
        return
    end

    for i = 1, #appliedActionFlags do
        Citizen.InvokeNative(CLEAR_PED_ACTION_DISABLE_FLAG, ped, appliedActionFlags[i])
    end
    appliedActionFlags = {}
end

local function ApplyActionDisableFlags(ped, verbose)
    local flags = GetConfiguredActionFlags()
    for i = 1, #flags do
        Citizen.InvokeNative(SET_PED_ACTION_DISABLE_FLAG, ped, flags[i])
    end
    appliedActionFlags = flags

    local config = Config.ActionDisableFlags
    -- verbose only on a real ped change; the tick re-applies constantly and would
    -- otherwise spam the console twice a second when Debug is on.
    if verbose and config and config.Debug then
        print(('[%s] action disable flags applied ped=%s flags=%s')
            :format(RESOURCE_NAME, tostring(ped), json.encode(flags)))
    end
end

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

-- ⚠️ DisableControlAction ปิดที่ "ปุ่ม" ไม่ใช่ที่ "เป้าหมาย" — พอบล็อกปุ่มโจมตีตอนมีผู้เล่นอยู่ใกล้
--    ผู้เล่นจะ "ตีอะไรไม่ได้เลย" รวมถึงล่าสัตว์ที่อยู่ตรงนั้นด้วย จึงห้ามใส่ปุ่มโจมตีลงในลิสต์นี้:
--      INPUT_MELEE_ATTACK    ฟัน/ต่อย  (ยืนยันจากเทสในเกม = ตัวที่ทำให้ตีสัตว์ไม่ได้)
--      INPUT_MELEE_MODIFIER  โจมตีหนัก
--      INPUT_MELEE_BLOCK     ตั้งการ์ดป้องกัน (ปิดแล้วป้องกันตัวไม่ได้ ไม่สมเหตุผล)
--      INPUT_ATTACK / INPUT_ATTACK2  คลิกซ้าย/โจมตีรอง
--    เหลือเฉพาะท่าก่อกวนที่ไม่ใช่ "การโจมตีปกติ"
local AlwaysBlockedControls = {
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

-- ว่างไว้โดยตั้งใจ: เดิมใส่ INPUT_ATTACK/INPUT_ATTACK2 แล้วทำให้คลิกซ้ายตีสัตว์ไม่ได้
-- เมื่อมีผู้เล่นอื่นยืนอยู่ใกล้ ๆ (ดูคำอธิบายเหนือ AlwaysBlockedControls)
local ConditionalAttackControls = {}

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

-- These flags live on the ped, and the game silently resets them on death/
-- respawn, revive, ragdoll, mount transitions, scripted animations/cutscenes and
-- routing-bucket (instance) switches -- all WITHOUT handing out a new ped handle.
-- The previous "apply once, only when the ped handle changes" guard therefore
-- went permanently dormant after any of those (actionFlagsPed still matched the
-- ped and appliedActionFlags was still populated), which is why the flags
-- appeared to switch themselves off partway through a session. #appliedActionFlags
-- never reached 0 on its own either, so that half of the condition was dead code.
--
-- Re-applying is idempotent, so just do it every tick. Six natives per 500ms tick
-- (12/sec) is negligible -- the original perf note was about not doing it every
-- FRAME, which this still avoids.
CreateThread(function()
    while true do
        local config = Config.ActionDisableFlags
        local enabled = type(config) == 'table' and config.Enable == true
        local ped = PlayerPedId()

        if enabled and ped ~= 0 and DoesEntityExist(ped) then
            local pedChanged = (actionFlagsPed ~= ped)
            if pedChanged and actionFlagsPed ~= 0 then
                ClearActionDisableFlags(actionFlagsPed)
            end
            actionFlagsPed = ped
            ApplyActionDisableFlags(ped, pedChanged)
        elseif actionFlagsPed ~= 0 then
            ClearActionDisableFlags(actionFlagsPed)
            actionFlagsPed = 0
        end

        Wait(500)
    end
end)

-- Close the up-to-500ms gap right after the moments most likely to wipe the
-- flags, so a player can't shove/tackle in the instant after respawning or being
-- revived. Safe to fire spuriously: these only ever re-add restrictions.
local function ReapplyActionFlagsNow()
    local config = Config.ActionDisableFlags
    if type(config) ~= 'table' or config.Enable ~= true then return end

    local ped = PlayerPedId()
    if ped == 0 or not DoesEntityExist(ped) then return end

    actionFlagsPed = ped
    ApplyActionDisableFlags(ped, false)
end

local REAPPLY_EVENTS = {
    'vorp_core:Client:OnPlayerRespawn',
    'vorp_core:Client:OnPlayerRevive',
    'vorp:SelectedCharacter',
    'MJ-ReSpwan:Client:ReviveAnim',
    'MJ-ReSpwan:revive:DeadRedM',
    'MJ-ReSpwan:client:adminRevive',
}

for i = 1, #REAPPLY_EVENTS do
    RegisterNetEvent(REAPPLY_EVENTS[i], function()
        Wait(1000) -- let the respawn/revive finish rebuilding the ped first
        ReapplyActionFlagsNow()
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= RESOURCE_NAME then return end
    if actionFlagsPed ~= 0 then
        ClearActionDisableFlags(actionFlagsPed)
        actionFlagsPed = 0
    end
end)
