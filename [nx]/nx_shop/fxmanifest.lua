fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'nx_shop'
author 'Nodex'
description 'Fast server-authoritative VORP shop with NUI cart'

ui_page 'html/index.html'

shared_scripts {
    'shared/config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/*.png',
    'html/assets/items/*.png',
    'html/assets/fonts/*.ttf'
}

dependencies {
    'vorp_core',
    'vorp_inventory',
    'lp_textui', -- client.lua ใช้ exports.lp_textui:TextUIHold/CancelHold แทน native UiPrompt
    'pNotify',   -- client.lua ใช้ exports.pNotify:SendNotification แทน Core.NotifyRightTip
}
