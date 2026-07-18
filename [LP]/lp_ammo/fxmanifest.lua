fx_version 'cerulean'
game 'rdr3'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

name 'lp_ammo'
author 'LP'
version '1.0.0'
description 'Server-authoritative ammo box handling for VORP inventory'

server_scripts {
    'config/config.lua',
    'server/sv_main.lua'
}

dependencies {
    'vorp_core',
    'vorp_inventory'
}
