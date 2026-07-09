fx_version 'cerulean'
games { 'rdr3' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'lp_itemnotify'
author      'original implementation for VORPCore'
version     '1.0.0'
description 'Item add/remove toast notifications for vorp_inventory (replaces MJ-Itemnotify)'

ui_page 'html/index.html'

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server.lua',
}

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/script.js',
}

exports {
    'notification',
}

lua54 'yes'
