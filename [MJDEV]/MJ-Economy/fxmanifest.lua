
fx_version 'adamant'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'
version 'v1.1.0'
author "MJDEV Economy"

ui_page 'html/index.html'
shared_script 'config.lua'
client_script 'client/main.lua'
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}
files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
    'html/img/*.png'
}
dependencies { 'lp_textui' }