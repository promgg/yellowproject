fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name    'MJ-AfkFishing'
version '1.0.0'

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/css/*.css',
  'html/js/*.js',
  'html/image/*.*',
  'html/sounds/*.*',
  'html/copperplategothic_bold.ttf',
}

shared_scripts { 'config.lua' }
client_script  'client.lua'
server_script  'server.lua'

dependencies { 'vorp_core', 'vorp_inventory', 'lp_textui', 'lp_progbar', 'lp_minigame', 'lp_rewardpanel', 'pNotify' }

lua54 'yes'
