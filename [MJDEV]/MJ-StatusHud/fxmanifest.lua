fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

author 'MJDev'
description 'MJDev Statushud'
version '1.0.0'

ui_page "ui/index.html"

file 'ui/**'

client_scripts {
    'config/config.interface.lua',
    'config/config.general.lua',
    'core/client.lua',
    'core/nui.lua'
}

server_scripts {
    'config/config.general.lua',
    'config/config.interface.lua',
    -- 'core/server.lua'
}

lua54 'yes'