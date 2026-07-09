-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 


fx_version 'adamant'
games {'rdr3'}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
author 'MJDev'
version '1.0'
ui_page "html/index.html"

client_scripts {
	"client/client.lua",
	"client/core_client.lua",
	"client/noclip.lua",
	"client/spectate.lua",
}

server_scripts {
	"@oxmysql/lib/MySQL.lua",
	"server/server.lua",
	"server/core_server.lua",
	"server/spectate.lua",
}

shared_script {
	"config.lua"
}

files {
    'html/index.html',
    'html/index.js',
    'html/index.css',
	'html/img/*.png',
}

lua54 'yes'
