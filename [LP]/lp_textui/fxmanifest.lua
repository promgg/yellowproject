fx_version 'cerulean'
games { 'rdr3' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'lp_textui'
author      'original implementation for VORPCore'
version     '1.1.0'
description 'Key-prompt text UI with arc progress ring — client-only utility (export/event API)'

ui_page 'nui/index.html'

client_scripts {
    'client/main.lua'
}

files {
    'nui/index.html',
    'nui/css/style.css',
    'nui/js/script.js'
}

exports {
    'TextUI',
    'HideUI',
    'StartProgress',
    'StopProgress',
    'ResetProgress',
    'TextUIHold',
    'CancelHold',
    'IsHoldActive',
    'SetSuppressed'
}

lua54 'yes'
