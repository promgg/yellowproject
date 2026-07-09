fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'internal debug tool'
name 'VORP Horse Preview'
description 'Dev menu to preview every horse model and print its name/hash for debugging'
lua54 'yes'

client_scripts {
    'client/horses.lua',
    'client/main.lua',
}

server_script 'server/main.lua'

-- requires vorp_menu and vorp_inputs to already be started (ensure both above this in server.cfg)
