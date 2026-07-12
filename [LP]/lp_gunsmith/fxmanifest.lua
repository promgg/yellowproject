fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'lp_gunsmith'
author 'original implementation for VORPCore'
description 'Visual weapon component customization with a live camera preview'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'vorp_core',
    'vorp_inventory',
    'vorp_menu',
    'oxmysql',
    'pNotify',
    'lp_textui',
    'lp_progbar'
}
