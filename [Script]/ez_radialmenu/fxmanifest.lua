fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description '[STANDALONE] A radial menu for RedM'
author 'Rayaan Uddin'
version '1.0'
name "ez_radialmenu"

lua54 'yes'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
}

files {
    'html/index.html',
    'html/css/main.css',
    'html/js/main.js',
    'html/js/RadialMenu.js',
    'html/js/img/*.*',
}
