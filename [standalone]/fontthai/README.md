# fontthai

ฟอนต์ไทย **native RDR2** สำหรับ RedM — ทำให้ข้อความในตัวเกม (scaleform / prompt / native text)
แสดงภาษาไทยได้ ไม่ใช่แค่ NUI

## ที่มาของไฟล์
- `stream/font_lib_efigs.gfx` — RDR2 font library (`font_lib_efigs` = English/French/Italian/German/Spanish)
  ที่ **ฝัง glyph ไทยเข้าไปแล้ว** โดยมอด **"RDR2 Mod Thai - Zudrangma"** (เครดิต: Zudrangma)
- ต้นฉบับเป็นมอด singleplayer แบบ **Lenny's Mod Loader (LML)** — ตัด `dinput8.dll`, `lml/`,
  และไฟล์ `.ytd` (texture แปลเนื้อเรื่อง 354 ไฟล์) ออกหมด **เหลือแค่ไฟล์ฟอนต์** เพราะ RedM
  ใช้แค่ตัวนี้

## วิธีทำงาน
ไฟล์ใน `stream/` ถูก RedM auto-stream เป็น game asset แล้ว **override ฟอนต์ของเกมตามชื่อ**
(`font_lib_efigs.gfx`) → ตัวอักษรไทยที่เดิมเป็นกล่อง/หาย จะ render ออกมาเป็นไทย

## ติดตั้ง
เพิ่มใน `server.cfg`:
```
ensure fontthai
```
แล้วรีสตาร์ตเซิร์ฟ + เข้าเกมใหม่ (client ต้องโหลด stream asset ใหม่ — อาจต้องล้าง cache
ฝั่ง client ครั้งแรก: ลบโฟลเดอร์ `FiveM/RedM application data > data > cache > ...` หรือรอ re-download)

## เทสว่าใช้ได้ไหม
1. เปิดข้อความ native ที่เคยเป็นภาษาไทยแล้วขึ้นกล่อง — เช่น notification ของเกม, prompt ปุ่ม,
   ชื่อร้าน/ป้าย, เมนู scaleform → ควรเป็นไทยชัด
2. ถ้ายังเป็นกล่อง: ล้าง cache client แล้วลองใหม่ / ตรวจว่า `ensure fontthai` โหลดจริง

## หมายเหตุ
- **ยังไม่ได้ทดสอบในเกมจริง** — การ override scaleform frontend font ผ่าน stream ใช้ได้กับ
  RedM หลายเซิร์ฟ แต่บางเวอร์ชัน/สภาพแวดล้อมอาจต่างกัน ต้องลองจริง
- ครอบเฉพาะข้อความที่ใช้ฟอนต์ `font_lib_efigs` (ฟอนต์ UI หลักของเกม) — ถ้ามีบางจุดใช้ฟอนต์
  อื่นของเกมที่ไม่มีไทย ก็ยังขึ้นกล่องเฉพาะจุดนั้น
- เครดิตฟอนต์/งานฝังไทยเป็นของ **Zudrangma** — ใช้ในเซิร์ฟตัวเองตามเจตนาเดิมของผู้ทำ
