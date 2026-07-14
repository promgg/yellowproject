
-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 

fx_version "adamant"
games {"rdr3"}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'
this_is_a_map 'yes'
description 'lp_airdropteam : clone of MJ-Airdrop; battle zone by nx_cityselect city, entry/return by chosen NPC station'

version '1.0'
ui_page 'html/index.html'

shared_script {
    'config.lua',
}

server_scripts {
    'config.lua',
    "core/server.lua",
    "core/server_team.lua",
}

client_scripts {
    'config.lua',
    "core/client_core.lua",
    "core/client.lua",
    "core/client_team.lua",
}

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/img/*.png',
    'html/sounds/*.mp3',
    -- 'stream/*.ydr',
}

dependencies {
    'vorp_core',
    'vorp_inventory',
    'nx_cityselect',
    'lp_textui',
    'lp_progbar',
    'lp_minigame',
    'pNotify',
}
