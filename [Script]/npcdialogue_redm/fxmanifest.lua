fx_version "adamant"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game "rdr3"

author 'berxt.ogg & torpak.'
description 'NP Inspired Dialogue by Nexus | https://discord.gg/j87NTfVGQX'
version '0.5.0'
lua54 "yes"

ui_page "ui/index.html"
files {
    "ui/**/**",
}

shared_scripts {
	'config.lua'
}

client_scripts {
	"client.lua"
}


