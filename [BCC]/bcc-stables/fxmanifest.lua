fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

game 'rdr3'
lua54 'yes'
author 'BCC Team'

dependencies {
    'feather-menu', -- client/main.lua เรียก exports['feather-menu'].initiate() ตอนโหลดไฟล์ทันที ต้องรับประกันว่า feather-menu ขึ้นก่อนเสมอ
}

shared_scripts {
    'config/*.lua',
    'locale.lua',
    'languages/*.lua'
}

client_scripts {
    'client/dataview.lua',
    'client/main.lua',
    'client/horseinfo.lua',
    'client/menus/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page {
    'ui/index.html'
}

files {
    "ui/index.html",
    "ui/js/*.*",
    "ui/css/*.*",
    "ui/fonts/*.*",
    "ui/webfonts/*.*", -- Font Awesome solid webfont (ไอคอนปุ่ม/สถิติ NUI ใหม่)
    "ui/img/*.*"
}

version '1.7.5'
