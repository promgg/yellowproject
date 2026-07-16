-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 

fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
description 'MJDev-Job for RedM'

dependencies {
    'lp_textui', -- client.lua ใช้ exports.lp_textui:TextUI/HideUI แสดง prompt ลอยเหนือกระดานจดหมาย
}

shared_scripts {
    'config.lua',
}

client_scripts { 
	"client.lua",
} 
 
server_scripts { 
	'@oxmysql/lib/MySQL.lua',
	"server.lua" 
} 

ui_page 'html/index.html'

files {
    'html/*.*',
	'html/image/*.*',
	'html/sounds/*.*',
}

lua54 'yes'