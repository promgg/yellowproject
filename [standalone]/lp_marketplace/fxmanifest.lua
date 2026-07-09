fx_version 'cerulean'
games { 'rdr3' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'lp_marketplace'
author      'ported for VORPCore'
version     '1.0.0'
description 'Player Marketplace — VORPCore + vorp_inventory'

shared_scripts {
    'config/config.lua',
    'config/config_items.lua',
    'config/config_locale.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_bridge.lua',
    'server/sv_log.lua',
    'server/sv_anticheat.lua',
    'server/sv_marketplace.lua',
    'server/sv_main.lua',
}

client_scripts {
    'client/cl_nui.lua',
    'client/cl_main.lua',
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/css/style.css',
    'nui/css/fa-base.min.css',
    'nui/css/fa-solid.min.css',
    'nui/webfonts/fa-solid-900.woff2',
    'nui/webfonts/fa-solid-900.ttf',
    'nui/fonts/*.ttf',
    'nui/assets/*.png',
    'nui/js/nui.js',
    'nui/js/app.js',
}

lua54 'yes'
