fx_version 'cerulean'
games { 'rdr3' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'lp_test'
author      'original implementation for VORPCore'
version     '1.0.0'
description 'Scratch resource for one-off native/technique experiments (not for production)'

client_scripts {
    'client/gfx_minimap_test.lua',
    'client/block_emote_wheel.lua',
}

lua54 'yes'
