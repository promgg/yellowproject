fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'nx_event'
description 'Auto Timed Treasure Hunt Event System'
version     '1.0.0'
author      'NXDev'

shared_scripts {
    'config.lua',
}

server_scripts {
    'server/sv_main.lua',
}

client_scripts {
    'client/cl_main.lua',
    'client/cl_box.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/css/style.css',
    'ui/js/app.js',
}

dependencies {
    'vorp_core',
    'nx_cityselect',
}
