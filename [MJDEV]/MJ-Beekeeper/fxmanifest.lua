version '1.0'
author 'MJDEV'
description 'Custom objects: Bee MJDEV'
fx_version "adamant"
games {"rdr3"}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

server_scripts {
	'config.lua',
	'core/server.lua'
}

client_scripts {
	'config.lua',
	'core/client.lua'
}

files {
	'stream/*.ydr',
	'stream/bee_house_gk_ytyp.ytyp'
}

data_file 'DLC_ITYP_REQUEST' 'stream/bee_house_gk_ytyp.ytyp'

escrow_ignore {
    'stream/*/*.ydr',
    'config.lua'
}