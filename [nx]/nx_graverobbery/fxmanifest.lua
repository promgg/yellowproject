fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'nx_graverobbery'
description 'Server-authoritative VORP grave robbery with nx_cityselect village alerts'
author 'NX'
version '1.0.0'

shared_scripts {
    'config.lua',
    'locales/*.lua',
    'shared/locale.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/notifications.lua',
    'client/animations.lua',
    'client/graveprops.lua',
    'client/targets.lua',
    'client/zone.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/config_server.lua',
    'server/bridges/vorp.lua',
    'server/bridges/cityselect.lua',
    'server/security.lua',
    'server/schedule.lua',
    'server/event.lua',
    'server/cooldowns.lua',
    'server/rewards.lua',
    'server/notifications.lua',
    'server/eventnotify_bridge.lua',
    'server/main.lua',
}

dependencies {
    'vorp_core',
    'vorp_inventory',
    'oxmysql',
    'lp_textui',
    'lp_minigame',
    'lp_progbar',
    'nx_cityselect',
    'pNotify',
}
