fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'lp_fishing'
author 'ดัดแปลงจาก vorp_fishing (VORPCORE / @blackpegasus, เดิมจาก FRP framework)'
description 'ตกปลาด้วยมินิเกมจริงของ RDR2 — ปลาที่ได้คือปลาตัวจริงในน้ำ ไม่ใช่การสุ่มจากตาราง'
version '1.0.0'

shared_scripts {
	'config/config.lua',
	'config/baits.lua',
	'config/baitsPerFish.lua',
	'config/fishData.lua',
	'translation/translation.lua'
}

client_scripts {
	'client/client_js.js',
	'client/client.lua'
}

server_script {
	'server/server.lua'
}

dependencies {
	'vorp_core',
	'vorp_inventory',
	'lp_textui',
	'lp_progbar',
	'lp_rewardpanel',
	'lp_minigame',
	'pNotify'
}

exports {
	'GET_TASK_FISHING_DATA',
	'SET_TASK_FISHING_DATA',
	'VERTICAL_PROBE'
}
