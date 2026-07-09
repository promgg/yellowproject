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

fx_version 'cerulean'
games {'rdr3'}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
description 'MJ : Dev'

version '1.0'

ui_page 'html/index.html'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
	'core/server.lua',
}

client_scripts {
    'config.lua',
    "core/client.lua"
}

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/script.js',
    'html/**.*',
    'core/used_codes.json',
}

dependencies { 'pNotify' }

lua54 'yes'