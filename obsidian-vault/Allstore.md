# All Store Dashboard — ร้านค้าทั้งหมด

> ข้อมูลดึงจาก config จริงของ `nx_shop` ณ วันที่สร้างไฟล์นี้ — ถ้าแก้ config ทีหลัง ต้องสั่งให้ Claude สแกนใหม่เพื่ออัปเดตไฟล์นี้ (ไม่ใช่ live query)
>
> **ขอบเขต:** ตัดข้อมูล `vorp_stores` ออกตามคำขอ (ไม่ได้ใช้งาน) เหลือเฉพาะ `nx_shop`

## nx_shop — 10 สาขา

| ร้าน | ชื่อ | พิกัด | เปิด-ปิด | หมวดสินค้า |
|---|---|---|---|---|
| `general_vlt` | VALENTINE GENERAL STORE | `-324.1397, 804.4375, 117.8816` | เปิดตลอด (ไม่ผูกเวลา) | General |
| `general_rho` | RHODES GENERAL STORE | `1330.2391, -1293.4142, 78.2563` | เปิดตลอด (ไม่ผูกเวลา) | General |
| `general_anb` | ANNESBURG GENERAL STORE | `2930.8000, 1362.4426, 45.1829` | เปิดตลอด (ไม่ผูกเวลา) | General |
| `general_emr` | EMERALD RANCH GENERAL STORE | `1420.3792, 379.5956, 90.3204` | เปิดตลอด (ไม่ผูกเวลา) | General |
| `gun_vlt` | VALENTINE GUNSMITH | `-281.1246, 778.8676, 119.5040` | เปิดตลอด (ไม่ผูกเวลา) | Gun |
| `gun_rho` | RHODES GUNSMITH | `1323.2031, -1323.2544, 78.8197` | เปิดตลอด (ไม่ผูกเวลา) | Gun |
| `gun_anb` | ANNESBURG GUNSMITH | `2948.0452, 1318.7841, 46.5781` | เปิดตลอด (ไม่ผูกเวลา) | Gun |
| `doctor_vlt` | VALENTINE DOCTOR | `-288.2027, 805.0736, 119.3859` | เปิดตลอด (ไม่ผูกเวลา) | Doctor |
| `doctor_rho` | RHODES DOCTOR | `1369.7628, -1310.8749, 77.9377` | เปิดตลอด (ไม่ผูกเวลา) | Doctor |
| `doctor_anb` | ANNESBURG DOCTOR | `2926.7612, 1351.8997, 44.4271` | เปิดตลอด (ไม่ผูกเวลา) | Doctor |

### General Store (nx_shop) — ใช้ร่วมกันทุกสาขา

| ไอเทม | ชื่อ | หมวด | ราคา |
|---|---|---|---|
| `tool_shovel` | พลั่วพรวนดิน | farming | $10 |
| `tool_bucket` | ถังน้ำ | farming | $5 |
| `compost` | ปุ๋ย | farming | $1 |
| `seed_tobacco_plant` | เมล็ดยาสูบ | farming | $1 |
| `seed_cotton` | เมล็ดฝ้าย | farming | $1 |
| `seed_barley` | เมล็ดข้าวบาร์เลย์ | farming | $1 |
| `seed_opium` | เมล็ดฝิ่น | farming | $1 |
| `seed_Ginseng` | เมล็ดโสม | farming | $1 |
| `seed_mushroom` | เมล็ดเห็ดป่า | farming | $1 |
| `seed_yarrow` | เมล็ดยาร์โรว์ | farming | $1 |
| `seed_carrot` | เมล็ดแครอท | farming | $1 |
| `seed_corn` | เมล็ดข้าวโพด | farming | $1 |
| `seed_sugarcane` | เมล็ดอ้อย | farming | $1 |
| `seed_orange` | เมล็ดส้ม | farming | $1 |
| `seed_berry` | เมล็ดเบอรี่ | farming | $1 |
| `tool_pickaxe` | ที่ขุดเหมือง | work_tools | $5 |
| `tool_axe` | ขวานตัดไม้ | work_tools | $5 |
| `job_fishing_rod` | เบ็ดตกปลา | work_tools | $200 |
| `job_fishing_bait` | เหยื่อตกปลา | work_tools | $2 |
| `food_bread` | ขนมปัง | food | $5 |
| `food_sandwich` | แซนวิส | food | $10 |
| `food_canned_beans` | ถั่วกระป๋อง | food | $15 |
| `cigarette` | บุหรี่ | food | $25 |
| `water` | น้ำดื่ม | drinks | $5 |
| `food_coffee` | กาแฟ | drinks | $5 |
| `food_beer` | เบียร์ | drinks | $5 |
| `food_vodka` | วิสกี้ | drinks | $5 |
| `food_brandy` | บรั่นดี | drinks | $5 |
| `hr_grass` | หญ้าม้า | horse | $5 |
| `hr_brush` | แปลงขัดม้า | horse | $10 |
| `hr_medicine` | ยารักษาม้า | horse | $50 |

### Gunsmith (nx_shop) — ใช้ร่วมกันทุกสาขา

| ไอเทม | ชื่อ | หมวด | ราคา |
|---|---|---|---|
| `tool_binoculars` | Binoculars (กล้องส่องทางไกล) | misc | $800 |
| `tool_lantern` | Davy Lantern (ตะเกียง) | misc | $200 |
| `tool_lasso` | Lasso (เชือก) | misc | $150 |
| `weapon_knife` | Knife | melee | $250 |
| `weapon_rustic_knife` | Rustic Knife | melee | $450 |
| `weapon_cattleman_revolver` | Cattleman Revolver | revolver | $1500 |
| `weapon_varmint_rifle` | Varmint Rifle | rifle | $4500 |
| `weapon_bow_small` | Bow (ธนูเล็ก) | bow | $4000 |
| `oil_gun` | Gun Oil | gunoil | $100 |
| `ammoshotgunnormal` | Shotgun Ammo | ammo | $10 |
| `ammorevolvernormal` | Revolver Ammo | ammo | $10 |
| `ammoriflenormal` | Rifle Ammo | ammo | $10 |
| `ammovarmint` | Varmint Ammo | ammo | $10 |
| `ammopistolnormal` | Pistol Ammo | ammo | $10 |
| `ammorepeaternormal` | Repeater Ammo | ammo | $10 |
| `ammoarrownormal` | Arrow Ammo | ammo | $10 |
| `ammotomahawk` | Tomahawk Ammo | ammo | $10 |

### Doctor (nx_shop) — ใช้ร่วมกันทุกสาขา

| ไอเทม | ชื่อ | ราคา |
|---|---|---|
| `bandage_s` | ผ้าพันแผลเล็ก (+เลือด 15%) | $10 |
| `bandage_xl` | ผ้าพันแผลใหญ่ (+เลือด 30%) | $25 |
| `painkiller` | ยาแก้ปวด (+เลือด 80%) | $80 |
| `stamina` | ยาชูกำลัง (+สเตมิน่า 90%) | $60 |

---

> **ข้อจำกัด:** ตัวเลขราคาดึงตรงจาก `shared/config.lua` ของ `nx_shop` — ไม่ได้ตรวจ logic จริงใน client/server.lua ว่ามีส่วนลด/ภาษี (`vatPercent`) หรือเงื่อนไข job เพิ่มเติมที่ config ไม่ได้บอกไว้ตรงๆ หรือไม่
