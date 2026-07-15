fx_version "cerulean"
game "rdr3"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'VORP' -- Inital Author : RobiZona#0001

description 'Bank system VORP'
lua54 'yes'

shared_scripts {
    'shared/language.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/app.js',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'logs.lua',
    'server/services.lua',
    'server/bridges/cityselect.lua',
    'server/server.lua',
}

dependencies {
    'lp_textui',
    'pNotify',
    'vorp_inventory',
}

--dont touch
version '1.9'
vorp_checker 'yes'
vorp_name '^4Resource version Check^3'
vorp_github 'https://github.com/VORPCORE/vorp_banking'
