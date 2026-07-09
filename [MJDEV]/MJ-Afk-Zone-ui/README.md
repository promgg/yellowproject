-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 


# AFK Zone UI สำหรับ RedM (VORP Framework)

ระบบนี้ช่วยให้ผู้เล่นสามารถเข้าสู่พื้นที่ AFK เพื่อสะสมเวลาแลกรางวัล พร้อม UI ที่แสดงสถานะความคืบหน้าอย่างสวยงาม พร้อมระบบกดปุ่มเพื่อเริ่ม/ยกเลิก AFK

## ✅ คุณสมบัติหลัก

- ตรวจจับพื้นที่ AFK ด้วยตำแหน่ง (radius-based zone)
- UI แสดง progress bar สำหรับแต่ละโซน
- แจ้งเตือนเมื่อสามารถรับรางวัลได้
- ปุ่มกด `E` เพื่อเริ่มพักผ่อน, `X` เพื่อยกเลิก
- UI แสดงรายการรางวัล พร้อมปุ่มรับ
- บันทึกเวลาสะสมลงฐานข้อมูล
- รองรับหลายโซนพร้อมกัน
- ปรับแต่งง่ายผ่าน `config.js`

---

## 📦 การติดตั้ง

1. วางโฟลเดอร์ `MJ-Afk-Zone-ui` ลงใน `resources`
2. เพิ่มลงใน `server.cfg`:
   ```
   ensure MJ-Afk-Zone-ui
   ```
3. ตรวจสอบว่าเซิร์ฟเวอร์คุณใช้ VORP Framework

---

## 🛠️ การตั้งค่า

### 🔹 `config.js` (สำหรับ Frontend UI)

แก้ไข `html/config.js` เพื่อปรับแต่ง:

```js
window.AFKConfig = {
  titleText: "คุณกำลังพักผ่อนอยู่ในสถานที่อันสงบ (AFK Zone)",
  promptText: "กด <strong>E</strong> เพื่อเริ่มพักผ่อน",
  barColor: "#daa520",
  barBackground: "#333",
  rewardSound: "reward.mp3"
};
```

---

### 🔹 `config.lua` (สำหรับโซนและรางวัล)

```lua
Config.AFKZones = {
    ["valentine"] = {
        label = "แคมป์พักผ่อน Valentine",
        coords = vector3(-435.36, 509.8, 97.92),
        radius = 50.0,
        duration = 300,  -- ต้องอยู่นานเท่าไหร่ (วินาที)
        rewards = {
            { item = "apple", label = "Apple", count = 5, image = "nui://vorp_inventory/html/img/items/apple.png" },
            { item = "money", label = "Money", count = 10, image = "nui://vorp_inventory/html/img/items/money.png" }
        }
    },

    ["strawberry"] = {
        label = "แคมป์พักผ่อน Strawberry",
        coords = vector3(-1810.0, -350.0, 165.0),
        radius = 30.0,
        duration = 600,
        rewards = {
            { item = "goldbar", label = "Gold Bar", count = 1, image = "nui://vorp_inventory/html/img/items/goldbar.png" },
            { item = "cooked_meat", label = "Cooked Meat", count = 2, image = "nui://vorp_inventory/html/img/items/meat.png" }
        }
    },

    ["rhodes"] = {
        label = "แคมป์พักผ่อน Rhodes",
        coords = vector3(1345.0, -1375.0, 80.0),
        radius = 20.0,
        duration = 900,
        rewards = {
            { item = "weapon_bow", label = "Bow", count = 1, image = "nui://vorp_inventory/html/img/items/bow.png" },
            { item = "arrow", label = "Arrow", count = 10, image = "nui://vorp_inventory/html/img/items/arrow.png" }
        }
    }
}
```

---

## 🎮 วิธีใช้งาน

- เดินเข้าเขต AFK → UI จะแสดง prompt
- กด `E` → เริ่มพักผ่อน
- อยู่ครบเวลากำหนด → สามารถกด `G` เพื่อรับรางวัล
- เดินออกนอกเขต / กด `X` → ยกเลิกการพัก

## 🎨 UI Style

- Font: Kanit (รองรับภาษาไทย)
- ใช้ไอคอนจาก Font Awesome
- Responsive UI เหมาะกับ RedM NUI

---

## 📁 โครงสร้างไฟล์

```
MJ-Afk-Zone-ui/
├── fxmanifest.lua
├── client.lua
├── server.lua
├── config.lua
└── html/
    ├── index.html
    ├── script.js
    ├── config.js
    ├── style.css
    ├── images/
    │   └── goldnugget.png
    └── reward.mp3
```

---

## 📝 เครดิต

- พัฒนาโดย: [ชื่อของคุณหรือ Discord]
- ใช้ร่วมกับ: VORP Framework (RedM)

---

## ❗ หมายเหตุ

- ควรมีระบบ Inventory/Reward ที่สามารถให้ไอเท็มผ่าน Server Side
- อย่าลืม preload ไฟล์ UI ทั้งหมดใน `fxmanifest.lua`
