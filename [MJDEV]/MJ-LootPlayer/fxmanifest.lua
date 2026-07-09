
version '1.0'
description 'MJ-LootPlayer | updated by cl3i550n'

fx_version "adamant"
lua54 "on"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

game "rdr3"

shared_scripts {
	'config.lua',
	'shared/translation.lua',
}

client_scripts {
	'client/client.lua',
}

server_scripts {
	'server/server.lua',
}
