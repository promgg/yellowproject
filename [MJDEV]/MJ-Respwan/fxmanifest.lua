
fx_version 'adamant'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'
version '1.1.0'

client_scripts {
    'config.lua',
    "core/client.lua"
}

server_scripts {
    'config.lua',
	"core/server.lua"
}

ui_page "html/index.html"

files {
	'html/index.html',
	'html/js/*.js',
	'html/css/*.css',
	-- 'html/img/*.png'
}
