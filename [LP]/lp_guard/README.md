# lp_guard

ตัวกันเซิร์ฟเวอร์ (anti-exploit) ของ LP — ออกแบบให้เพิ่มโมดูลใหม่ได้เรื่อยๆ

## โมดูลปัจจุบัน

### 1. NameGuard — กันชื่อยาว (อุด long-name money-dupe)

**บั๊กที่อุด:** `vorp_core` `SaveCharacterInDb` เซฟ `money`/`gold` พร้อมกับ
`firstname`/`lastname`/`steamname` ในคิวรี UPDATE เดียว ถ้าชื่อ (โดยเฉพาะชื่อ
client/Steam จาก `GetPlayerName`) ยาวเกินขนาดคอลัมน์ DB → MySQL ปฏิเสธ UPDATE
ทั้งก้อน → **เงินสดไม่เคยถูกเซฟ** ในขณะที่ยอดแบงก์ (`bank_users`) เซฟผ่านตลอด
→ ฝากเงินเข้าแบงก์แล้วออกเกม = เงินสดโรลแบคกลับค่าเดิม + แบงก์เก็บยอดฝาก = **ปั๊มเงิน**

**วิธีกัน:** เด้งผู้เล่นที่ชื่อยาวเกิน `Config.NameGuard.MaxLength` (ตัวอักษร UTF-8)
ตั้งแต่ตอน `playerConnecting` ก่อนเข้าเซิร์ฟ

**ตั้งค่า:** `config.lua` → `Config.NameGuard`
- `MaxLength` (ค่าเริ่ม 32) — Steam persona สูงสุด ~32 จึงไม่เตะผู้เล่นชื่อปกติ
- `MinLength`, ข้อความปฏิเสธ, เปิด/ปิด log

## การติดตั้ง

เพิ่มใน `server.cfg` (ควรโหลดก่อนหรือพร้อม vorp_core ก็ได้ — `playerConnecting` ทำงานไม่ขึ้นกับลำดับ):

```
ensure lp_guard
```

## หมายเหตุ: มี backstop อีกชั้นใน vorp_core

NameGuard กันชื่อ client/Steam แต่ยังมี vector ชื่อ `firstname`/`lastname` (ตั้งตอน
สร้างตัวละคร เก็บคนละที่) เลยมี backstop เพิ่มใน `vorp_core` `SaveCharacterInDb`
ที่ clamp ฟิลด์ชื่อทุกตัวให้พอดีคอลัมน์ก่อน UPDATE — การันตีว่า money เซฟผ่านเสมอ
ไม่ว่าชื่อจะมาจากทางไหน (ดู commit ของ vorp_core)
