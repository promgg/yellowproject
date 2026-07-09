fx_version "adamant"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game "rdr3"
description 'MJ-Cooldown'

ui_page 'html/index.html'
files {
    'html/index.html',
    'html/*.css',
    'html/*.js',
}

client_scripts {
	'config.lua',
	'core/client.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'config.lua',
	'core/server.lua',
}