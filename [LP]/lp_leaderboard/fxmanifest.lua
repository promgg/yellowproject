fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

author 'LP'
description 'lp_leaderboard : multi-category ranking (Kill PvP + City airdrop wins) — realtime, server-authoritative'
version '1.0.0'

ui_page 'nui/index.html'

shared_scripts {
    'shared/sh_events.lua', -- ต้องโหลดก่อน config.lua เพราะ Config.GatherJobs อ้าง Events.* ตอน define
    'config.lua',
}

client_scripts {
    'client/cl_main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_main.lua',
}

files {
    'nui/index.html',
    'nui/css/style.css',
    'nui/js/script.js',
    'nui/fonts/*.ttf',
    'nui/assets/**/*',
}

dependencies {
    'vorp_core',
    'oxmysql',
    'nx_cityselect',
    'pNotify',
}
