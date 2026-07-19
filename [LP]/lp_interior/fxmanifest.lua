fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'lp_interior'
author 'original implementation for VORPCore'
description 'Interior detection: routing-bucket dimensions, notifications, and F8 debug logging'
version '1.1.0'

shared_script 'config.lua'

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'pNotify'
}
