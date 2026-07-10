fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

author 'LP'
description 'lp_welfarelogin : Daily Login (free/VIP) + Online-time rewards — open-source port'
version '1.0.0'

ui_page 'html/index.html'

shared_script 'config.lua'

client_script 'client/client.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
}

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
    'html/fonts/*.ttf',
    'html/assets/*.png',
}

dependencies {
    'vorp_core',
    'vorp_inventory',
    'oxmysql',
    'pNotify',
}
