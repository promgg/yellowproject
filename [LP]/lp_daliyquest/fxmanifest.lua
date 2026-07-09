fx_version 'cerulean'
game 'rdr3'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'Daliyquest'
description 'Daily Quest NUI'
version     '1.0.0'

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/css/*.css',
  'html/js/*.js',
  'html/assets/*.png',
  'html/copperplategothic_bold.ttf',
}

shared_scripts {
  'config.lua',
}

client_scripts {
  'client.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server.lua',
}

dependencies {
  'vorp_core',
  'oxmysql',
}
