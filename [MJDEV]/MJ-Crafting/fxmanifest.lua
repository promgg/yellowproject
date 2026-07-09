fx_version "adamant"
games {'rdr3'}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'


ui_page 'html/Index.html'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
	'config_sv.lua',
	'server/server.lua',
}

client_scripts {
	'config_cl.lua',
    'client/client.lua',
}

files {
    'html/Index.html',
    'html/style.css',
    'html/script.js',
	'html/sounds/*.mp3',
}

