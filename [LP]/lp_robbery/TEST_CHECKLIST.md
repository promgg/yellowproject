# lp_robbery — เช็คลิสต์ทดสอบในเกม

ค่าที่ใช้อ้างอิง (จาก config.lua): ไอเทม `small_bomb` · ระยะกด `Config.Range=3m` · โชว์ countdown `DisplayRange=5m` · ตู้เซฟร้านปลดล็อค `RobberyDuration=2 นาที` · ห้องนิรภัยเย็นตัว `BankRobberyDuration=2 นาที` · ฟิวส์ระเบิดธนาคาร `BankFuseTime=15 วิ` · pending หมดอายุ `PendingTTL=30 วิ` · ตำรวจ `RequiredForStore/Bank=0` (ปิด)

---

## 0. เตรียม
- [ ] `ensure lp_robbery` ใน server.cfg (หลัง vorp_core, vorp_inventory, lp_textui, lp_progbar, lp_minigame, pNotify)
- [ ] `restart lp_robbery` → console ต้องไม่มี error ตอนโหลด + เห็น `[lp_robbery] GlobalState cleared on resource start` (Config.Debug=true)
- [ ] เตรียมไอเทม `small_bomb` เข้ากระเป๋าหลายชิ้น (ผ่าน admin/DB) สำหรับเทส
- [ ] จุดทดสอบ: ร้าน Valentine General `(-324.24, 804.08, 117.98)`, ธนาคาร Valentine `(-309.00, 763.63, 118.70)`

## 1. ปล้นร้าน (store) — flow ปกติ
- [ ] เดินเข้าใกล้เครื่องคิดเงินร้าน (≤3m) → เห็น hint **"[กดค้าง E] วางระเบิด"**
- [ ] กดค้าง E → เล่นมินิเกม Spacebar → **กดสำเร็จ** → progress "กำลังวางระเบิด..." (5วิ) → ได้ข้อความ "วางระเบิดสำเร็จ ตู้เซฟจะเปิดใน 2 นาที" + `small_bomb` ถูกหัก 1
- [ ] ยืนใกล้จุด → เห็น countdown **"🟠 ตู้เซฟกำลังปลดล็อค: 01:59..."** นับถอยหลัง
- [ ] ครบ 2 นาที → hint เปลี่ยนเป็น **"[กดค้าง E] เก็บของ"**
- [ ] กดค้าง E → progress "กำลังเก็บของ..." (5วิ) → ได้เงิน $100-300 + ลุ้นไอเทม (loot_ring/watch/earring/goldring/gold_tooth)
- [ ] จุดนั้นกลายเป็น **looted** → เข้าใกล้อีกครั้ง hint หายไป, กดปล้นซ้ำขึ้น "สถานที่นี้ถูกปล้นไปแล้ว"

## 2. ปล้นธนาคาร (bank) — flow ปกติ
- [ ] เข้าใกล้ห้องนิรภัย (≤3m) → hint "[กดค้าง E] วางระเบิด"
- [ ] กดค้าง E → progress "กำลังวางระเบิด..." (4วิ, **ไม่มีมินิเกม** สำหรับธนาคาร) → `small_bomb` หัก 1 → ข้อความ "หนีเร็ว! ระเบิดใน 15 วิ!"
- [ ] รอ 15 วิ → **ระเบิดจริง** (เห็น/ได้ยิน AddExplosion + กล้องสั่นถ้าอยู่ใกล้ ≤40m) + ข้อความ "ห้องนิรภัยถูกระเบิด! กำลังเย็นตัวลง..."
- [ ] countdown **"🔴 ห้องนิรภัยกำลังเย็นตัว: 01:59..."** นับถอยหลัง 2 นาที
- [ ] ครบ → "[กดค้าง E] เก็บของ" → progress 7วิ → เงิน $500-2000 + ลุ้นไอเทม (goldbar/mat_diamond/jewelry ฯลฯ) → looted

## 3. ผู้เล่นอื่นเห็นตรงกัน (GlobalState)
- [ ] ผู้เล่น A เริ่มปล้น → ผู้เล่น B เดินมาที่จุดเดียวกัน → **B เห็น countdown เดียวกัน** (นาฬิกาตรงกัน)
- [ ] ระเบิดธนาคาร → ผู้เล่นทุกคนในระยะ ~150m เห็น/ได้ยินระเบิด
- [ ] A เก็บของไปแล้ว → B กดเก็บ → "มีคนเก็บของไปแล้ว"

## 4. เงื่อนไข/edge case
- [ ] **ไม่มี small_bomb** → กดปล้น → "คุณต้องมีระเบิดลูกเล็ก" ไม่เสียอะไร
- [ ] **มินิเกมร้านพลาด** (กด Spacebar ไม่ตรง) → "ระเบิดเสียเปล่า! ของหมดแล้ว" → `small_bomb` ถูกหักไปแล้ว (ตามดีไซน์) แต่ตู้เซฟ **ไม่เริ่มปลดล็อค** (ยังปล้นใหม่ได้ด้วยลูกใหม่)
- [ ] **ยกเลิก progress** (กด X ระหว่างวางระเบิด) → "ยกเลิก" → small_bomb หักไปแล้ว, ไม่เริ่มปลดล็อค
- [ ] **เก็บของก่อนครบเวลา** (กดตอน countdown ยังไม่หมด) → "รออีก N นาที"
- [ ] กำลังปล้นอยู่จุดหนึ่ง แล้วมีคนมาปล้นซ้ำจุดเดิม → "กำลังมีการปล้นที่นี่อยู่"

## 5. Security — exploit ต้องถูกบล็อก (สำคัญสุด)
ยิง event ดิบผ่าน executor/console (ลบทิ้งหลังเทส) — ทั้งหมดต้อง**ไม่ได้ของ**และเห็น log `[lp_robbery] BLOCKED ...` ฝั่ง server:
- [ ] **ข้าม request → ยิง confirm ตรง**: `TriggerServerEvent('lp_robbery:sv:confirmStore','ValentineGeneral')` โดยไม่ได้ request ก่อน → reject `reason=invalid_pending` (ตู้เซฟไม่เริ่ม, ไม่เสียระเบิด = ปล้นฟรีไม่ได้)
- [ ] **ยิง blow ธนาคารตรง**: `TriggerServerEvent('lp_robbery:sv:confirmBankBlow','ValentineBank',1)` ไม่มี pending → reject
- [ ] **ข้ามฟิวส์**: request ธนาคารแล้วรีบยิง confirmBankBlow ภายใน <14 วิ → reject `reason=fuse_too_early`
- [ ] **ปล้นจากระยะไกล**: ยืนไกล >3m แล้วยิง `sv:requestStore` → reject `reason=out_of_range`
- [ ] **id ปลอม**: `sv:requestStore('FAKE')` → reject `reason=ไม่พบสถานที่นี้`
- [ ] **loot จุดที่ยังไม่เปิด**: `sv:loot('store','ValentineGeneral')` ตอน state=nil → reject "ไม่มีอะไรให้เก็บที่นี่"
- [ ] **สแปม request รัวๆ** → cooldown 1วิ กันไว้ (ยิงถี่ไม่ผ่าน)

## 6. แจ้งเตือนตำรวจ (job = police)
- [ ] ผู้เล่น job `police` ออนไลน์ → ตอนมีคนเริ่มปล้น → police ได้ pNotify "แจ้งเตือน: มีการปล้นที่ ..." + blip แดงบนแผนที่ (หายเองใน 5 นาที)
- [ ] ผู้เล่นที่**ไม่ใช่** police → ไม่ได้รับ alert/blip
- [ ] (ถ้าจะเปิดเงื่อนตำรวจขั้นต่ำ: ตั้ง `Config.Police.RequiredForStore/Bank > 0` แล้วเทสว่าปล้นไม่ได้ถ้าตำรวจไม่พอ → "ตำรวจในพื้นที่ไม่พอ")

## 7. Reloot cooldown (งัดซ้ำได้เอง — `Config.RelootCooldown=30 นาที`)
- [ ] ปล้น+เก็บของจุดหนึ่งเสร็จ → กลับมายืนที่จุดเดิม (≤5m) → เห็นข้อความ **"🔒 เพิ่งถูกปล้น งัดได้อีกใน MM:SS"** นับถอยหลัง
- [ ] ยิง `sv:requestStore`/`requestBank` ตอนติด cooldown → reject **"เพิ่งถูกปล้น งัดได้อีกใน N นาที"**
- [ ] ครบ 30 นาที → จุดนั้น**กลับมางัดได้เอง** (hint เปลี่ยนเป็น "[E] วางระเบิด") โดยไม่ต้อง restart
- [ ] (ลดค่า `Config.RelootCooldown` เป็น 1 นาทีชั่วคราวเพื่อเทสให้เร็ว)

## 8. Restart / persistence
- [ ] ปล้นจุดหนึ่งจน looted → `restart lp_robbery` → จุดนั้น**กลับมาปล้นได้อีกทันที** (state memory reset ตามดีไซน์ — reloot cooldown ก็หายไปด้วย)
- [ ] กำลัง countdown อยู่แล้ว restart → state หาย, จุดกลับเป็น fresh (ไม่ค้าง)
- [ ] เก็บ log: ตรวจ console เห็น `[lp_robbery][TX] ... kind=payout cash=.. items=..` ทุกครั้งที่จ่ายจริง

## 8. หลังเทสเสร็จ
- [ ] ตั้ง `Config.Debug = false` (ปิด dbg prints)
- [ ] ปรับ timer เป็นค่าจริง (ตอนนี้ 2 นาทีสำหรับเทส — production อาจ 5-10 นาที)
- [ ] ลบคำสั่ง/executor ที่ใช้ยิง event ทดสอบทิ้ง
- [ ] (ถ้าต้องการ) เปลี่ยน sprite blip แจ้งเตือนจาก placeholder `blip_ambient_hitching_post`

**จุดสังเกตด่วน**: ถ้าข้อ 5 ยิง confirm ตรงแล้ว**ได้**ปล้น/ได้ของ = ช่องโหว่ยังไม่ถูกปิด (แต่โค้ดตรวจแล้วว่าปิด — ให้เช็คว่า restart จริง); ถ้าเล่นปกติแล้ว small_bomb ไม่ถูกหัก = getItemCount/subItem ชื่อไอเทมไม่ตรง DB
