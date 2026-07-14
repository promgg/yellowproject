fx_version 'cerulean'
games { 'rdr3' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'lp_minigame'
author      'original implementation for VORPCore'
version     '1.0.0'
description 'Skill-check minigames (spacebar, WASD sequence, fishing, circle, lockpick) — client-only, blocking export API'

ui_page 'html/index.html'

client_scripts {
    'config.lua',
    'client/main.lua',
}

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
    'html/img/lockpick/collar.png',
    'html/img/lockpick/cylinder.png',
    'html/img/lockpick/driver.png',
    'html/img/lockpick/pin.png',
    'html/img/lockpick/pinTop.png',
    'html/img/lockpick/pinBott.png',
}

exports {
    'Spacebar',
    'Sequence',
    'Fishing',
    'Circle',
    'Lockpick',
    'Cancel',
}

lua54 'yes'
