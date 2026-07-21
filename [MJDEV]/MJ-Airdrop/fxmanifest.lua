
-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 

fx_version "adamant"
games {"rdr3"}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'
this_is_a_map 'yes'
description 'MJDev : https://discord.gg/gHRNMDQKzb'

version '1.0'
ui_page 'html/index.html'

shared_script {
    'config.lua',
}

server_scripts {
    'config.lua',
	"core/server.lua"
}

client_scripts {
    'config.lua',
    "core/client_core.lua",
    "core/client.lua"
}

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/img/*.png',
    'html/sounds/*.mp3',
    -- 'stream/*.ydr',
}

dependencies {
    'lp_textui',   -- core/client.lua ใช้ exports.lp_textui:TextUIHold/CancelHold/TextUI/HideUI แทน MJ-Textui (ปิดใช้งานแล้ว) และ native prompt
    'lp_progbar',  -- core/client.lua ใช้ exports.lp_progbar:Progress/CancelProgress สำหรับ phase 2 (แถบเปิดกล่อง)
    'lp_minigame', -- core/client.lua ใช้ exports.lp_minigame:Lockpick สำหรับ minigame ก่อนเปิดกล่อง
    'nx_cityselect', -- core/client.lua ใช้ exports.nx_cityselect:WearCityOutfit/RemoveCityOutfit ตอนเข้า/ออกวง
}
