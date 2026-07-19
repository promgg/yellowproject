fx_version 'cerulean'
games { 'rdr3' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'lp_planting'
author      'LP'
version     '1.0.0'
description 'ระบบปลูกพืช เก็บลง DB ต้นไม่หายตอนออกเกม (แทน MJ-Planting)'

shared_scripts {
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
    'client/waterrefill.lua',
}

-- vorp_core/vorp_inventory ถูกเรียกตอนโหลดสคริปต์ ไม่ใช่ใน event handler
-- ถ้ายังโหลดไม่เสร็จจะพังทั้งไฟล์ทันที ("No such export")
dependencies {
    'vorp_core',
    'vorp_inventory',
    'lp_textui',
    'lp_progbar',
    'pNotify',
}

lua54 'yes'
