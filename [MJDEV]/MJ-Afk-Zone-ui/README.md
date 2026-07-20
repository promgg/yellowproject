# MJ-Afk-Zone-ui — ระบบพักผ่อน (AFK) ใน saloon

ผู้เล่นเข้าไปพักผ่อนในมิติแยกของ saloon เพื่อสะสมเวลาแลกเหรียญ AFK
มิติแยกทำให้คนที่นอน AFK ไม่รกร้านที่คนอื่นกำลัง RP กันอยู่

## วิธีเล่น

1. เดินเข้า saloon — `lp_interior` ย้ายมิติให้อัตโนมัติ (bucket ปกติของร้าน)
2. เดินไปหา **NPC บาร์เทนเดอร์** แล้วค้าง `E` → เข้ามิติพักผ่อน (ค้าง `E` ซ้ำ = กลับเข้าร้าน)
3. ค้าง `G` → เริ่มนอนพัก (นับเวลา)
4. ครบ 15 นาที → ได้รางวัลอัตโนมัติ แล้วเริ่มนับรอบใหม่ทันที นอนต่อได้เรื่อยๆ
5. ค้าง `X` เพื่อลุก หรือ **เดินออกนอกร้าน** = ออกจาก AFK + กลับมิติหลักเอง

## จุดที่รองรับ

| โซน | saloon | รางวัลต่อ 15 นาที |
|---|---|---|
| valentine | Saloon Valentine | 5x `afk_coin` |
| annesburg | Saloon Annesburg | 5x `afk_coin` |
| rhodes    | Saloon Rhodes    | 5x `afk_coin` |

## ความสัมพันธ์กับ lp_interior

**รีซอร์สนี้ไม่แตะ routing bucket เอง** — `lp_interior` เป็นเจ้าของคนเดียว
ถ้าสองรีซอร์สเรียก `SetPlayerRoutingBucket` ทั้งคู่ จะเขียนทับกันจนผู้เล่นหลุดมิติมั่ว

สิ่งที่ใช้จาก `lp_interior`:

| ฝั่ง | ชื่อ | ใช้ทำอะไร |
|---|---|---|
| client | `GetCurrentZone()` | รู้ว่าอยู่ saloon ไหน |
| client | `IsInAfk()` | อยู่ในมิติพักผ่อนหรือยัง |
| client | `ToggleAfk()` | สลับเข้า/ออกมิติพักผ่อน (กด E ที่ NPC) |
| client | event `lp_interior:onLeave` | เดินออกนอกร้าน → ตัด AFK ทันที |
| server | `IsPlayerInAfkBucket(src, key)` | ตรวจก่อนจ่ายรางวัล |

`zoneKey` ใน `config.lua` ของไฟล์นี้ **ต้องตรงกับ `key` ใน `lp_interior/config.lua` เป๊ะๆ**
ถ้าไม่ตรง ระบบจะหาโซนไม่เจอและ AFK จะเริ่มไม่ได้เลย

## การตรวจสอบฝั่ง server

ทั้ง `startAFK` และ `claimReward` ตรวจซ้ำทุกครั้งว่า:

- ผู้เล่นอยู่ใน **afkBucket ของร้านนั้นจริง** (ผ่าน `lp_interior`) — ปลอมไม่ได้เพราะ server เป็นคนตั้ง bucket เอง
- อยู่ในระยะ `Config.RewardDistance` (40 ม.) จาก NPC
- เวลาสะสมครบ `duration` จริง โดยนับจาก `os.time()` ฝั่ง server ไม่ใช่ตัวเลขที่ client ส่งมา

ยิง event เองจากนอกร้านจึงไม่ได้อะไร

## ตั้งค่า

`config.lua`:

- `Config.AFKZones[*].duration` — วินาทีที่ต้องนอนครบถึงได้รางวัล
- `Config.AFKZones[*].rewards` — ไอเทมที่ได้ (ใส่หลายชิ้นได้)
- `Config.AFKZones[*].npc` — พิกัด/หันหน้าของ NPC (ใส่พิกัดที่ยืนเก็บได้ตรงๆ โค้ดลบ 1.0 ให้เองตอนสร้าง ped)
- `Config.NPC.spawnRange` / `despawnRange` — ระยะสร้าง/เก็บ ped
- `Config.RewardDistance` — ระยะผ่อนผันที่ server ยอมรับตอนจ่าย

Discord log: `set mj_afkzone_discord_webhook "https://discord.com/api/webhooks/..."` ใน `server.cfg`

## หมายเหตุ

- เวลาสะสมเก็บใน `user_afk.json` (ไม่ใช่ฐานข้อมูล) แยกตาม identifier ของผู้เล่น
- NPC ใช้โมเดล `u_f_m_vhtbartender_01` และ **ต้องเรียก `SetRandomOutfitVariation` หลัง `CreatePed`**
  ไม่งั้น ped จะโผล่มาล่องหน — โมเดลนี้ไม่มีชุดติดมา
