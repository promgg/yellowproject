-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 

FastKeys = {
    -- Letters
    ['A'] = 0x7065027D,
    ['B'] = 0x4CC0E2FE,
    ['C'] = 0x9959A6F0,
    ['D'] = 0xB4E465B4,
    ['E'] = 0xCEFD9220,
    ['F'] = 0xB2F377E8,
    ['G'] = 0x760A9C6F,
    ['H'] = 0x24978A28,
    ['I'] = 0xC1989F95,
    ['J'] = 0xF3830D8E,
    -- Missing K, don't know if anything is actually bound to it
    ['L'] = 0x80F28E95,
    ['M'] = 0xE31C6A41,
    ['N'] = 0x4BC9DABB, -- Push to talk key
    ['O'] = 0xF1301666,
    ['P'] = 0xD82E0BD2,
    ['Q'] = 0xDE794E3E,
    ['R'] = 0xE30CD707,
    ['S'] = 0xD27782E3,
    ['T'] = 0x9720FCEE,
    ['U'] = 0xD8F73058,
    ['V'] = 0x7F8D09B8,
    ['W'] = 0x8FD015D8,
    ['X'] = 0x8CC9CD42,
    -- Missing Y
    ['Z'] = 0x26E9DC00,

    -- Symbol Keys
    ['RIGHTBRACKET'] = 0xA5BDCD3C,
    ['LEFTBRACKET'] = 0x430593AA,
    -- Mouse buttons
    ['MOUSE1'] = 0x07CE1E61,
    ['MOUSE2'] = 0xF84FA74F,
    ['MOUSE3'] = 0xCEE12B50,
    ['MWUP'] = 0x3076E97C,
    ['MWSCROLLUP'] = 0xCC1075A7,
    ['MWSCROLLDOWN'] = 0xFD0F0C2C,
    -- Modifier Keys
    ['CTRL'] = 0xDB096B85,
    ['TAB'] = 0xB238FE0B,
    ['SHIFT'] = 0x8FFC75D6,
    ['SPACEBAR'] = 0xD9D0E1C0,
    ['ENTER'] = 0xC7B5340A,
    ['BACKSPACE'] = 0x156F7119,
    ['LALT'] = 0x8AAA0AD4,
    ['DEL'] = 0x4AF4D473,
    ['PGUP'] = 0x446258B6,
    ['PGDN'] = 0x3C3DD371,
    ['ESC'] = 0x4A903C11,
    -- Function Keys
    ['F1'] = 0xA8E3F467,
    ['F4'] = 0x1F6D95E5,
    ['F6'] = 0x3C0A40F2,
    -- Number Keys
    ['1'] = 0xE6F612E4,
    ['2'] = 0x1CE6D9EB,
    ['3'] = 0x4F49CC4C,
    ['4'] = 0x8F9F9E58,
    ['5'] = 0xAB62E997,
    ['6'] = 0xA1FDE2A6,
    ['7'] = 0xB03A913B,
    ['8'] = 0x42385422,
    -- Arrow Keys
    ['DOWN'] = 0x05CA7C52,
    ['UP'] = 0x6319DB71,
    ['LEFT'] = 0xA65EBAB4,
    ['RIGHT'] = 0xDEB34313,
    
    -- other
    ['HorseCommandFlee'] = 0x4216AF06,
    ['Loot'] = 0x41AC83D1,
    ['INPUT_CURSOR_SCROLL_DOWN'] = 0x8BDE7443,
    ['INPUT_CURSOR_SCROLL_UP'] = 0x62800C92,
}

if Config.DevMode then
    AddEventHandler('onClientResourceStart', function(resourceName)
        if (GetCurrentResourceName() ~= resourceName) then
            return
        end
        print('loading resource ^1DEV MODE IS ENABLED')
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "hide" })
        TriggerServerEvent("DEV:loadweapons")
        print("Loading Inventory")
        TriggerServerEvent("vorpinventory:getItemsTable")
        Wait(1000)
        TriggerServerEvent("vorpinventory:getInventory")
        Wait(1000)
        TriggerServerEvent("vorpCore:LoadAllAmmo")
        print("inventory loaded")
        Wait(100)
        TriggerEvent("vorpinventory:loaded")
    end)
end


CreateThread(function()
    if not Config.UseLanternPutOnBelt then
        return
    end

    repeat Wait(2000) until LocalPlayer.state.IsInSession

    local function checkLanterns(hash)
        local lanterns <const> = { "WEAPON_MELEE_LANTERN", "WEAPON_MELEE_LANTERN_HALLOWEEN", "WEAPON_MELEE_DAVY_LANTERN", "WEAPON_MELEE_LANTERN_ELECTRIC" }
        for i = 1, #lanterns do
            if hash == joaat(lanterns[i]) then
                return true
            end
        end
        return false
    end
    local lastLantern = 0
    while true do
        local weaponHeld = GetPedCurrentHeldWeapon(PlayerPedId())
        local isLantern = IsWeaponLantern(weaponHeld) == 1 or IsWeaponLantern(weaponHeld) == true
        if isLantern then
            lastLantern = weaponHeld
        end

        if lastLantern ~= 0 and not checkLanterns(weaponHeld) then
            SetCurrentPedWeapon(PlayerPedId(), lastLantern, true, 12, false, false)
            lastLantern = 0
        end
        Wait(1000)
    end
end)
