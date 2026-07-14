author 'Fixitfy / custom clerk-service rebuild'
description 'Server-authoritative Identity Card Clerk Service'
version '2.0.0'
fx_version "adamant"
games {"rdr3"}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

shared_scripts {
    "framework/*.lua",  
    "config.lua",       
}

client_scripts {
    'c/*.lua'  
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    's/config_server.lua',
    's/s.lua',
    's/opensource.lua'
}

ui_page 'ui/index.html'

files {
    'ui/**/*',
}

escrow_ignore {
    '**/*'
}

dependencies {
    'oxmysql',
    'lp_textui',
    'pNotify',
}
