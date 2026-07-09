fx_version 'adamant'
game      'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
author    'AnimalFarm'
version   '1.0.0'

shared_script  'config.lua'
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
client_scripts { 'client/main.lua' }

ui_page 'index.html'

files {
  'index.html',
  'style.css',
  'app.js',
  'assets/*.png',
  'assets/*.ttf',
}

dependencies { 'lp_rewardpanel', 'lp_textui', 'pNotify' }

lua54 'yes'
