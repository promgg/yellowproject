fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'Zudrangma (ฟอนต์ไทย) — แพ็คเป็น RedM'
description 'ฟอนต์ไทย native RDR2 — สตรีม font_lib_efigs.gfx (ฝัง glyph ไทยโดย Zudrangma) ทับฟอนต์ UI ของเกม ให้ข้อความ scaleform/native ในเกมแสดงภาษาไทยได้'
version '1.0.0'

-- ไฟล์ใน stream/ ถูก auto-stream เป็น game asset (font_lib_efigs(_pc).gfx)
-- แต่ "แค่ stream ไม่พอ" — client.lua ต้อง RegisterFontFile() ให้ engine โหลดฟอนต์จริง
client_script 'client.lua'
