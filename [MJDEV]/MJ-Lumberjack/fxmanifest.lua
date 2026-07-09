fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'MJ-Lumberjack'
description 'Lumberjack — UI via lp_progbar/lp_textui/pNotify/lp_rewardpanel'
version     '2.0.0'

shared_scripts {
  'config.lua',
  'shared/*.lua',
}
client_script 'client/client.lua'
server_script 'server/server.lua'

dependencies { 'vorp_core', 'vorp_inventory', 'lp_progbar', 'lp_textui', 'pNotify', 'lp_rewardpanel' }
