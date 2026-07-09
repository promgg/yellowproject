-- ================================================
-- MJ DEV
-- Resource: MJ-Process
-- ผู้พัฒนา: MJDev
-- Discord: https://discord.gg/gHRNMDQKzb
-- เวอร์ชัน: 1.2.0
-- ================================================
fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'
author 'MJDEV: https://discord.gg/gHRNMDQKzb'
repository 'https://mjdev-studio.tebex.io'
description 'MJ SHOP'
version '1.2.0'
escrow_ignore { 'config.lua' }

ui_page 'html/index.html'
files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/sounds/*.mp3'
}

client_scripts {
    'config.lua',
    'client/main.lua'
}

server_scripts {
    'config.lua',
    'server/main.lua'
}
dependency '/assetpacks'
dependency '/assetpacks-redm'