fx_version 'cerulean'
game 'rdr3'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'nx_hud'
description 'Figma-inspired RedM HUD with horse status and integrated custom radar map'
author 'MJ Dev / NODEX'
version '2.0.0'

shared_scripts {
    'shared/config.lua',
}

client_scripts {
    'client/client.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
}
