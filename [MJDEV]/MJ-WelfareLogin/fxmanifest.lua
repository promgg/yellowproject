-- MJ DEV
-- Resource: MJ-WelfareLogin
-- ผู้พัฒนา: MJDev
-- Discord: https://discord.gg/gHRNMDQKzb
-- เวอร์ชัน: 1.1.0
fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'
author 'MJDEV: https://discord.gg/gHRNMDQKzb'
repository 'https://mj-shop-shop.tebex.io'
description 'MJ Welfare Login Reward'
version '1.1.0'
escrow_ignore { 'config.lua' }

ui_page 'html/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

dependencies {
    'vorp_core',
    'vorp_inventory'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/img/rewards/*.png',
    'data/players.json'
}

dependency '/assetpacks'
dependency '/assetpacks-redm'