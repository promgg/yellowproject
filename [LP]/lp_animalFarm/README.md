# AnimalFarm

สคริปเลี้ยงสัตว์สำหรับ **RedM / RDR3** ใช้ framework **VORPCore** + **oxmysql**

---

## ความต้องการ (Dependencies)

| Resource | หมายเหตุ |
|---|---|
| `vorp_core` | VORPCore framework |
| `vorp_inventory` | VORP inventory system |
| `oxmysql` | database connector |

---

## การติดตั้ง

### 1. รัน SQL

รันไฟล์ `sql/animal_farm.sql` ใน database ของเซิร์ฟเวอร์ **ก่อน** ensure resource:

```sql
-- สร้างตาราง animal_farm
CREATE TABLE IF NOT EXISTS `animal_farm` (
  `id`         INT         NOT NULL AUTO_INCREMENT,
  `char_id`    INT         NOT NULL,
  `zone_type`  VARCHAR(32) NOT NULL,
  `slot`       TINYINT     NOT NULL,
  `state`      VARCHAR(16) NOT NULL DEFAULT 'feed',
  `hp`         TINYINT     NOT NULL DEFAULT 100,
  `exp`        TINYINT     NOT NULL DEFAULT 0,
  `last_fed`   INT         NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_slot`       (`char_id`, `zone_type`, `slot`),
  INDEX  `idx_char_zone`     (`char_id`, `zone_type`),
  INDEX  `idx_state_lastfed` (`state`, `last_fed`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- เพิ่มไอเทม large_meat (ถ้ายังไม่มี)
INSERT INTO `items` (`item`, `label`, `limit`, `weight`, `can_remove`, `type`, `usable`, `groupId`, `metadata`, `desc`, `degradation`)
SELECT 'large_meat', 'Large Meat', 50, 1.0, 1, 'item_standard', 0, 1, '{}', 'Large chunk of raw meat used for feeding animals.', 0
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `item` = 'large_meat');
```

### 2. วางโฟลเดอร์

```
[Script]/
└── AnimalFarm/          ← วางที่นี่
    ├── client/
    ├── server/
    ├── assets/
    ├── sql/
    ├── config.lua
    ├── fxmanifest.lua
    ├── index.html
    ├── style.css
    └── app.js
```

### 3. รูปภาพไอเทม

คัดลอกไฟล์รูปต่อไปนี้ไปไว้ที่ `vorp_inventory/html/img/items/`:

| ไฟล์ | ต้นฉบับ (ใน items/) |
|---|---|
| `animal_bison.png` | `resource_pelt_bison.png` |
| `animal_tiger.png` | `animal_claw.png` |
| `animal_alligator.png` | มีอยู่แล้ว |
| `large_meat.png` | `large_raw_meat.png` |

### 4. เพิ่มใน server.cfg

```cfg
ensure AnimalFarm
```

> ต้อง ensure `vorp_core`, `vorp_inventory`, `oxmysql` **ก่อน** AnimalFarm

---

## โซนและพิกัด

| โซน | พิกัด (X, Y, Z, Heading) | สัตว์ | ped model |
|---|---|---|---|
| bison | -621.4697, -12.9421, 86.6219, 294.2585 | Buffalo | `a_c_buffalo_01` |
| tiger | 2985.9424, 2195.9185, 166.2030, 73.1517 | Panther | `a_c_panther_01` |
| croc | 1377.9629, -866.6765, 69.3180, 339.3852 | Alligator | `a_c_alligator_01` |

---

## กลไกการเล่น

```
เข้าโซน (radius 30m)
    ↓  กด E
เปิด UI → กด "Add Animals" เพิ่มสัตว์ (max 5 ตัว/โซน)
    ↓  รอ hpDecayTime (5 นาที)
HP ถึง 0 → สัตว์หิว → ปุ่ม FEED ใช้งานได้
    ↓  กด FEED (ใช้ไอเทมอาหาร)
EXP +20% ต่อครั้ง → ให้ครบ 5 ครั้ง → EXP 100%
    ↓
กด RECEIVE → รับของรางวัล → การ์ดหายไป
```

### กรณีสัตว์ตาย

หากไม่ได้ให้อาหารภายใน **feedWindow** (5 นาที หลัง HP = 0):
- สัตว์จะตาย (state = `dead`)
- ขึ้นแจ้งเตือนในเกม: `"Your bison animal has died!"`
- UI card เปลี่ยนเป็นสีเทา — hover ที่รูปสัตว์แล้วคลิก **DELETE** เพื่อลบ

---

## Config หลัก (`config.lua`)

```lua
Config.zoneRadius  = 30.0      -- รัศมีโซน (เมตร)
Config.hpDecayTime = 5 * 60   -- วินาทีที่ HP ลดจาก 100 → 0
Config.feedWindow  = 5 * 60   -- วินาทีที่มีให้ feed หลัง HP = 0 ก่อนสัตว์ตาย
Config.syncPed     = false     -- true = ped มองเห็นได้ทุกคน (อาจหน่วง)
```

### เพิ่ม/แก้โซน

```lua
Config.Zones['myzone'] = {
  coords        = vector4(x, y, z, heading),
  pedModel      = 'a_c_wolf_01',
  image         = 'nui://vorp_inventory/html/img/items/animal_wolf.png',
  maxSlots      = 5,
  feedsRequired = 5,              -- จำนวนครั้งที่ต้อง feed ให้ EXP เต็ม
  nameTH        = 'Feed Wolf',
  itemFeed      = { { name = 'large_meat', qty = 2 } },
  itemReward    = { { name = 'wolf_pelt',  qty = 1 } },
}
```

---

## โครงสร้างไฟล์

```
AnimalFarm/
├── fxmanifest.lua       — resource manifest
├── config.lua           — โซน, เวลา, ไอเทม (แก้ที่นี่)
├── client/
│   └── main.lua         — zone detection, UI prompt, ped spawn, NUI callbacks
├── server/
│   └── main.lua         — DB queries, item check/deduct, decay tick
├── sql/
│   └── animal_farm.sql  — DDL + INSERT item
├── index.html           — NUI layout
├── style.css            — NUI styles
├── app.js               — NUI logic (timers, card rendering)
└── assets/              — รูป, font, background
```

---

## Database Schema

```sql
animal_farm
├── id          INT AUTO_INCREMENT PRIMARY KEY
├── char_id     INT            — charIdentifier จาก VORPCore
├── zone_type   VARCHAR(32)    — 'bison' | 'tiger' | 'croc'
├── slot        TINYINT        — 1–5 (unique per char + zone)
├── state       VARCHAR(16)    — 'feed' | 'receive' | 'dead'
├── hp          TINYINT        — 0–100
├── exp         TINYINT        — 0–100
├── last_fed    INT            — unix timestamp ของการ feed ล่าสุด
└── created_at  TIMESTAMP
```

---

## คำสั่ง Debug (ใน F8 console)

```lua
-- เพิ่มไอเทม large_meat 100 ชิ้น (รัน server-side หรือ vorp admin)
TriggerServerEvent('vorp_inventory:server:addItem', 'large_meat', 100)
```
