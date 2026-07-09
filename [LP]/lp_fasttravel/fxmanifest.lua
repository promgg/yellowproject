fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'lp_fasttravel'
description 'Fast travel menu between bcc-train stations via lp_textui + lp_progbar'
version     '1.0.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/npc.lua',
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/css/style.css',
    'ui/js/app.js',
    'ui/copperplategothic_bold.ttf',
}

dependencies {
    'vorp_core',
    'pNotify',
    'lp_textui',
    'lp_progbar',
}
