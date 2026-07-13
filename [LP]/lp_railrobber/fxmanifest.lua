fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'lp_railrobber'
description 'Moving-train robbery PvPvE (attack/defend King-of-the-Hill, city teams). STAGE 1 = server-authoritative PvE spine.'
author 'lp_'
version '0.1.0'

shared_script 'config.lua'
server_script 'server/main.lua'
client_script 'client/main.lua'

dependencies {
    'vorp_core',
    'vorp_inventory',
    'nx_cityselect',
    'lp_textui',
    'lp_progbar',
    'pNotify',
}
