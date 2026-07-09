fx_version 'cerulean'
game 'rdr3'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'nx_minimap'
description 'Config-driven native minimap/radar position adjustment'
author 'MJ Dev / NODEX'
version '1.0.0'

shared_scripts {
    'shared/config.lua',
}

client_scripts {
    'client/client.lua',
}
