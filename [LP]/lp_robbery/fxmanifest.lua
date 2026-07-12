fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name        'lp_robbery'
author      'LP'
description 'lp_robbery : store + bank vault robbery'
version     '1.0.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'vorp_core',
    'vorp_inventory',
    'lp_textui',
    'lp_progbar',
    'lp_minigame',
    'pNotify',
}
