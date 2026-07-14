fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'lp_herbs'
description 'งานเก็บสมุนไพร — spawn prop ที่ coords, กดค้าง E เก็บ (สไตล์ MJ-Mining), server-authoritative. Port แนวคิดจาก vorp_herbs.'
author 'lp_'
version '1.0.0'

shared_script 'config.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

dependencies {
    'vorp_core',
    'vorp_inventory',
    'lp_textui',
    'lp_progbar',
    'lp_rewardpanel',
    'pNotify',
}
