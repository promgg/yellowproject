fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'lp_interior'
author 'original implementation for VORPCore'
description 'Debug: print to F8 when the player enters/leaves an interior, with coords'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    'client/main.lua'
}
