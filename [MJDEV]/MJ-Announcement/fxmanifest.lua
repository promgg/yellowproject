fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
author 'MJDEV'

server_script {
  'config.lua',
  'core/server.lua'
}

client_script {
  'config.lua',
  'core/client.lua'
}


ui_page 'html/index.html'
files {
  'html/index.html',
  'html/css/app.css',
  'html/images/*.png',
  'html/js/app.js'
}

lua54 'yes'