fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

shared_scripts { 'config.lua' }
client_scripts  { 'client/main.lua' }
server_scripts  { 'server/main.lua' }

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/css/style.css',
  'html/js/script.js',
  'html/copperplategothic_bold.ttf',
  'html/assets/**',
}
