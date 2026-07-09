fx_version "adamant"
games {"rdr3"}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
version '1.0'
author 'MJDev'
description 'MJDevDuty'
VorpVersion 'MJ Dev'
lua54 'yes'

ui_page('html/index.html')

server_scripts {
	'config.lua',
	'@oxmysql/lib/MySQL.lua',
	'core/server.lua'
}

client_scripts {
	'config.lua',
	'core/client.lua'
}

files {
    'html/index.html',
    'html/index.js',
    'html/index.css',
    'html/img/*.png',
    'html/sound/*.ogg',
}
