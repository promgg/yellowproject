fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'lp_eventnotify'
description 'Top-right badge row with live countdowns for active server-wide events (Hot Time, Deathmatch, Golden Time, ...). Server-authoritative via GlobalState.'
author 'lp_'
version '1.0.0'

shared_script 'config.lua'
server_script 'server/main.lua'
client_script 'client/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
    'html/copperplategothic_bold.ttf',
    'html/assets/icon_hot-time.png',
    'html/assets/icon_deathmatch.png',
    'html/assets/icon_golden-time.png',
}

exports {
    'StartEvent',
    'StopEvent',
    'IsEventActive',
}
