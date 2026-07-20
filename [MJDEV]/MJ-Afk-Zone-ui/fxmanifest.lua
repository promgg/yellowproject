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
description 'MJDev AFK RedM'

shared_scripts {
    'config.lua',
}

client_scripts { 
	"client.lua",
} 
 
server_scripts { 
	"server.lua" 
} 

ui_page 'html/index.html'

files {
    'html/**.*',
	'html/image/*.*',
	'html/sounds/*.*',
	'html/fonts/*.*',
}

-- lp_interior เป็นเจ้าของ routing bucket ทั้งหมด รีซอร์สนี้แค่ขอให้มันสลับมิติให้
-- ถ้าไม่ start ระบบ AFK จะไม่ทำงานเลย (และ server จะปฏิเสธการจ่ายรางวัลทุกครั้ง)
dependencies { 'vorp_core', 'lp_textui', 'pNotify', 'lp_progbar', 'lp_interior' }

lua54 'yes'