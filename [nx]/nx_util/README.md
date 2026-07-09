# nx_util

`nx_util` เป็น standalone utility resource สำหรับ RedM/RDR3 ใช้รวมระบบช่วยป้องกัน abuse และ utility อื่นในอนาคต โดย feature แรกคือ `AntiCombat` สำหรับบล็อก combat contextual animation ใกล้ผู้เล่นอื่น เช่น วิ่งชน/tackle, takedown, shove, grapple, choke, hogtie และ execute ระยะประชิด

Resource นี้ไม่ผูกกับ ESX, VORP หรือ framework ใดๆ และไม่มี server loop

## Installation

วาง resource ไว้ในโฟลเดอร์ resources แล้วเพิ่มใน config server:

```cfg
ensure nx_util
```

ถ้าวางไว้ใต้หมวดเช่น `resources/[nx]/nx_util` ยังใช้ชื่อ ensure เป็น `nx_util` เหมือนเดิม

## Config

ตั้งค่าได้ที่ `config.lua`

```lua
Config.AntiCombat = {
    Enable = true,
    ProximityRadius = 2.2,
    OnlyWhenRunning = true,
    AllowShootingWhenAiming = true,
    BlockAttackOnlyMeleeWeapon = true,
    BlockRoleplayThreatActions = false,
    Debug = false
}
```

- `Enable`: เปิด/ปิดระบบ AntiCombat
- `ProximityRadius`: ระยะที่เริ่มบล็อก contextual combat ใกล้ผู้เล่นอื่น
- `OnlyWhenRunning`: `true` = บล็อกเฉพาะตอนวิ่งหรือ sprint, `false` = บล็อกเมื่ออยู่ใกล้ผู้เล่นเสมอ
- `AllowShootingWhenAiming`: `true` = ถ้ากำลังเล็งปืน จะไม่บล็อกปุ่มยิง
- `BlockAttackOnlyMeleeWeapon`: `true` = บล็อก `INPUT_ATTACK`, `INPUT_ATTACK2` เฉพาะตอนถือ melee/unarmed
- `BlockRoleplayThreatActions`: `false` = ปล่อย animation แนว RP threat เช่น ล็อคคอ, มีดจี้, ปืนจ่อหัว
- `Debug`: เปิด log ตอนระบบเริ่มทำงาน

## What It Blocks

- วิ่งแล้วคลิกซ้ายเพื่อ tackle/takedown
- กด contextual interaction ใกล้ผู้เล่นเพื่อผลักหรือ melee interaction
- Grapple, choke, reversal และ stand switch ระยะประชิด
- Hogtie action
- Melee contextual action กลุ่ม execute/knife throat attack เมื่อถือ melee/unarmed

## Performance

ระบบทำงานฝั่ง client เท่านั้น ไม่มี event spam และไม่มี server loop

- ถ้าปิด `Enable` จะ sleep `1000ms`
- ถ้าไม่มีผู้เล่นอื่นในระยะหรือไม่เข้าเงื่อนไข จะ sleep `500ms`
- ถ้ามีผู้เล่นอื่นในระยะและเข้าเงื่อนไข จะ `Wait(0)` เพื่อ `DisableControlAction` ทุกเฟรมตามที่ RedM ต้องการ

## Recommended RP Defaults

```lua
ProximityRadius = 2.2
OnlyWhenRunning = true
AllowShootingWhenAiming = true
BlockAttackOnlyMeleeWeapon = true
BlockRoleplayThreatActions = false
```

## Notes

ถ้าตั้ง `ProximityRadius` สูงเกินไป ผู้เล่นอาจรู้สึกว่าการ combat ใกล้ผู้เล่นอื่นหน่วง หรือกดตีระยะประชิดไม่ได้บ่อยเกินไป

เพื่อไม่ให้การยิงปืนปกติเสีย ค่า default จะไม่บล็อกปุ่มยิงเมื่อผู้เล่นกำลังเล็งปืน และจะบล็อกปุ่มโจมตีหลักเฉพาะตอนถือ melee/unarmed เท่านั้น
