fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

game 'rdr3'
lua54 'yes'
author 'BCC Team'

dependencies {
    'feather-menu', -- client/main.lua เรียก exports['feather-menu'].initiate() ตอนโหลดไฟล์ทันที ต้องรับประกันว่า feather-menu ขึ้นก่อนเสมอ
    'vorp_inputs', -- ใช้หน้าต่างยืนยันรับข้อเสนอโอนม้า
    'vorp_inventory', -- กระเป๋าม้าและ client export สำหรับปิด/คืน focus
    'pNotify', -- ระบบแจ้งเตือน (แทน Core.NotifyRightTip เดิม) — client+server เรียก pNotify:SendNotification
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
    "ui/js/app.js",
    "ui/css/style.css",
    "ui/css/fa-base.min.css",
    "ui/css/fa-solid.min.css",
    "ui/fonts/robotoslab.94aab39f.ttf",
    "ui/fonts/crock.7de582c0.ttf",
    "ui/fonts/HapnaSlabSerif-Medium.3007bffd.ttf",
    "ui/webfonts/*.*", -- Font Awesome solid webfont (ไอคอนปุ่ม/สถิติ NUI ใหม่)
}

version '1.7.5'
