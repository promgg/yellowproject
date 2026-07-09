fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'
lua54 'yes'

version '1.0.0'
description 'JKL Delete Car'
author ' JKL Developer'
modifyby 'JKL Shop'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/js/*.js',
    'html/css/*.css',
    'html/img/*.png',
    'html/sounds/*.mp3',
    'html/metalmania.ttf',
}

shared_script {
    'config.lua',
}

client_scripts {
    'core/client.lua',
}

server_script {
    'core/server.lua',
}