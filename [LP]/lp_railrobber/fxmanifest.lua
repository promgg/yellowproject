fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'lp_railrobber'
description 'Moving-train robbery: buy intel -> ground ambush -> board + clear train -> plant bomb -> lockpick 10 cars. Server-authoritative, buyer-owned heist.'
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
