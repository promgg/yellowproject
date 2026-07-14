fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'lp_deathmatch'
description 'Server-authoritative city-vs-city deathmatch event with nx_cityselect team assignment'
author 'LP'
version '1.0.0'

shared_scripts {
    'config.lua',
    'locales/*.lua',
    'shared/locale.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/scoreboard.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/config_server.lua',
    'server/bridges/vorp.lua',
    'server/bridges/cityselect.lua',
    'server/security.lua',
    'server/schedule.lua',
    'server/rewards.lua',
    'server/event.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
}

dependencies {
    'vorp_core',
    'vorp_inventory',
    'oxmysql',
    'nx_cityselect',
    'pNotify',
}
