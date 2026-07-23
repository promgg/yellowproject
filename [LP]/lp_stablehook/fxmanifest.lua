fx_version 'adamant'
game 'rdr3'
lua54 'yes'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'MJDEV'
description 'ปรับเมนู kd_stable ผ่าน hook filter — เฟสแรก: dump โครงสร้าง item เพื่อหาปุ่ม bequeath (มอบม้า)'
version '0.1.0'

shared_script 'config.lua'
client_script 'client/main.lua'

-- kd_stable เป็นเจ้าของ export registerFilter — ต้องขึ้นก่อนตัวนี้เสมอ
dependencies {
    'kd_stable',
}
