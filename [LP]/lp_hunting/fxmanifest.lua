fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

author 'LP'
description 'lp_hunting : ชำแหละซากสัตว์ (skinning) — lp_textui E-hold + TASK_LOOT_ENTITY (แอนิเมชันเกมจริง) ดัก EVENT_LOOT_COMPLETE, reward เนื้อ/หนัง 2 ไอเทม + XP, ยิงต่อ lp_leaderboard'
version '1.0.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'vorp_core',
    'vorp_inventory',
    'lp_textui',
}
