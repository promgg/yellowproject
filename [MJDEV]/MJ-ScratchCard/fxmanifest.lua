-- ╔═══════════════════════════════════════════════════════════════════════╗ 
-- ║    ___  ___  __    ___               ________  _______   ___      ___ ║ 
-- ║   |\  \|\  \|\  \ |\  \             |\   ___ \|\  ___ \ |\  \    /  /|║ 
-- ║   \ \  \ \  \/  /|\ \  \            \ \  \_|\ \ \   __/|\ \  \  /  / /║ 
-- ║ __ \ \  \ \   ___  \ \  \            \ \  \ \\ \ \  \_|/_\ \  \/  / / ║
-- ║|\  \\_\  \ \  \\ \  \ \  \____        \ \  \_\\ \ \  \_|\ \ \    / /  ║ 
-- ║\ \________\ \__\\ \__\ \_______\       \ \_______\ \_______\ \__/ /   ║ 
-- ║ \|________|\|__| \|__|\|_______|        \|_______|\|_______|\|__|/    ║ 
-- ╚═══════════════════════════════════════════════════════════════════════╝ 
-- discord: https://discord.gg/ubyWdF7Uf7

fx_version 'adamant'
games {'rdr3'}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

description 'MJ SHOP V1'

Author 'MJ DEVELOPMENTS'

shared_script 'config.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page{
    'html/index.html'
}
files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png',
    'html/sounds/*.mp3',
}

escrow_ignore {
    'config.lua'
}