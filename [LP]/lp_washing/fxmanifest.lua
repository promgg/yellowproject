fx_version 'cerulean'
games { 'rdr3' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'lp_washing'
author      'LP'
version     '1.0.0'
description 'ล้างตัวในแม่น้ำ + อ่างอาบน้ำในโรงแรม (ล้างคราบสกปรก/เลือด)'

shared_scripts {
    'config.lua',
}

server_scripts {
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'vorp_core',
    'lp_textui',
    'lp_progbar',
    'pNotify',
}

lua54 'yes'
