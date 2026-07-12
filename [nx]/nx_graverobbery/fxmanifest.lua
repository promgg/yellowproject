fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'nx_graverobbery'
description 'Server-authoritative VORP grave robbery with nx_cityselect village alerts'
author 'NX'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/*.lua',
    'shared/locale.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/notifications.lua',
    'client/animations.lua',
    'client/targets.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/bridges/vorp.lua',
    'server/bridges/cityselect.lua',
    'server/security.lua',
    'server/cooldowns.lua',
    'server/rewards.lua',
    'server/notifications.lua',
    'server/main.lua',
}

dependencies {
    'vorp_core',
    'vorp_inventory',
    'oxmysql',
    'ox_lib',
    'ox_target',
    'nx_cityselect',
}
