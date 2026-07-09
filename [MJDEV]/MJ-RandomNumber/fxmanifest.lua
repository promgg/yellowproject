-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 
fx_version 'adamant'
games {'rdr3'}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
description 'MJ : Dev'
author 'JK Development' -- Your author name
description 'GiftBox System for REDM' -- Description of your script
version '1.0.0'          -- Version of your script

shared_script {
    'config.lua',        -- Shared configuration file
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',  -- MySQL connection for database interaction (if using oxmysql)
    'config.lua',              -- Configuration file loaded on server
    'core/server.lua',         -- Main server-side script for the GiftBox system
}

lua54 'yes'                 -- Specifies that the script uses Lua 5.4
