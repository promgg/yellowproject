fx_version "adamant"
games {'rdr3'}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'


ui_page 'html/index.html'

dependency 'vorp_inventory'
dependency 'lp_textui'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
	'config_sv.lua',
    'config_cl.lua',
	'server/server.lua',
}

client_scripts {
	'config_cl.lua',
    'client/client.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/*.png',
	'html/sounds/*.mp3',
}
