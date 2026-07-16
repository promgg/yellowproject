fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'nx_cityselect'
description 'City Selection System — VORP RedM'
author      'MJ Dev'
version     '1.0.0'

shared_scripts {
    'config.lua',
    'shared/sh_utils.lua',
    'locales/th.lua',
}

client_scripts {
    '@PolyZone/client.lua',
    'client/cl_zone.lua',
    'client/cl_outfit.lua',
    'client/cl_main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_city.lua',
    'server/sv_heritage.lua',
    'server/sv_main.lua',
    'server/sv_exports.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/css/style.css',
    'ui/js/app.js',
    'ui/img/mainbg.png',
}

dependencies {
    'oxmysql',
    'vorp_core',
    'vorp_character', -- cl_outfit.lua ใช้ exports.vorp_character:GetShirtTag/SetShirtTag
    'PolyZone',
    'pNotify',
}
