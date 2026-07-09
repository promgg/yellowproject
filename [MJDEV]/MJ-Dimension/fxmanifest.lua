fx_version "adamant"
games {"rdr3"}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
author "MJDEV"
description 'MJ Dimension Bucket System'
version "1.0"

shared_scripts {
    "config.lua",
}

client_scripts {
    '@PolyZone/client.lua',
    "client/*.lua",
}
server_scripts {
    "server/*.lua",
}

lua54 'yes'

escrow_ignore {
    '**/*',
}