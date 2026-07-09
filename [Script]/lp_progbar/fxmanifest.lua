fx_version 'cerulean'
games { 'rdr3' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'lp_progbar'
author      'original implementation for VORPCore'
version     '1.0.0'
description 'Concurrent progress bars — client-only utility (export/event API)'

ui_page 'html/index.html'

client_scripts {
    'client/main.lua'
}

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/script.js'
}

exports {
    'Progress',
    'ProgressWithStartEvent',
    'ProgressWithTickEvent',
    'ProgressWithStartAndTick',
    'CancelProgress',
    'CancelAllProgress',
    'GetActiveProgress'
}

lua54 'yes'
