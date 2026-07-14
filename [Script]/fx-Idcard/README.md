# FX Identity Card — Clerk Service

ระบบบัตรประจำตัวสำหรับ RedM รองรับ VORP และ RSG โดยใช้เจ้าหน้าที่จุดเดียวต่อสำนักงาน ไม่มีระบบกล้อง ช่างภาพ หรือไอเท็มรูปถ่าย

## Gameplay

1. ติดต่อเจ้าหน้าที่ที่ Valentine, Rhodes หรือ Annesburg ระหว่าง 08:00–21:00
2. หากยังไม่มีบัตร ระบบดึงข้อมูลตัวละครและ Steam avatar มาเป็นค่าเริ่มต้น
3. ผู้เล่นตรวจข้อมูลราชการที่ถูกล็อก และเปลี่ยน URL รูปได้ถ้าต้องการ
4. ยืนยันและชำระ $50 เพื่อรับ `man_idcard` หรือ `woman_idcard`
5. ผู้ที่มีบัตรแล้วเลือกเปลี่ยนรูป ($25) หรือออกบัตรทดแทน ($50)
6. เมื่อใช้ไอเท็ม บัตรจะแสดงแก่เจ้าของและผู้เล่นในระยะ 1.5 เมตร

บัตรทุกสำเนาเก็บเพียงหมายเลขอ้างอิงและอ่านข้อมูลล่าสุดจาก `fx_idcard` ทุกครั้ง รูปที่เปลี่ยนจึงอัปเดตทุกสำเนา และบัตรเก่าจะใช้ไม่ได้ทันทีเมื่อข้อมูลในฐานถูกลบ

## Installation

1. Import `fx_idcard.sql`.
2. Import `vorp-items.sql` for VORP หรือเพิ่มรายการจาก `RSGV2-ITEMS.md` สำหรับ RSG.
3. ตรวจว่า `steam_webApiKey` ถูกตั้งใน `server.cfg` เพื่อใช้ Steam avatar เป็นค่าเริ่มต้น.
4. ตั้ง `set fx_idcard_webhook "WEBHOOK_URL"` ใน `server.cfg` หรือ `Config.DiscordWebhook` ใน `s/config_server.lua` (server-only ไม่หลุดไปฝั่ง client) หากต้องการ Discord log — ไม่ว่าจะตั้งหรือไม่ก็ตาม action สำคัญ (สร้าง/เปลี่ยน/ลบ/รีเซ็ตบัตร) จะถูก print ไว้ใน console เสมอ
5. Start resource หลัง framework, inventory และ oxmysql.

## Commands

- `/deleteidcard [server id]` — ยกเลิกบัตรของตัวละครออนไลน์ ผู้ใช้ต้องเป็นแอดมิน
- `/resetallidcards confirm` — ล้างและสร้างตารางบัตรใหม่ บัตรเดิมทุกใบจะใช้ไม่ได้ ผู้ใช้ต้องเป็นแอดมินหรือ console

## Image URL rules

- รับเฉพาะ `https://`
- จำกัดความยาว 1024 ตัวอักษร
- ปฏิเสธ localhost, private IPv4, `.local`, `.internal`, URL ที่มี credentials และ IPv6 literal
- หาก URL ว่างหรือโหลดไม่ได้ NUI จะแสดงรูปมาตรฐาน

## Security model

- Server เป็นผู้กำหนดราคา เมือง ข้อมูลตัวละคร และ action ของ session
- Server ตรวจระยะห่างจากสำนักงานก่อนเริ่มและก่อนยืนยัน
- Client ส่งได้เฉพาะ token, ประเภทบริการจากเมนู และ URL รูป
- รายชื่อผู้เห็นบัตรคำนวณฝั่ง server โดยตรวจระยะและ routing bucket
