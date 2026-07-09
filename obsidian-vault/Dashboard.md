# RedM Project Dashboard

> Dashboard นี้ใช้ [Dataview](https://blacksmithgu.github.io/obsidian-dataview/) query ดึงข้อมูลสด ๆ จาก [[RedM-Todo]] — ต้องเปิดไฟล์นี้ใน **Obsidian ที่ติดตั้ง Dataview plugin แล้ว** เท่านั้นถึงจะเห็นตัวเลข/ตารางจริง ถ้าเปิดนอก Obsidian จะเห็นแค่ code block เฉย ๆ
>
> query ด้านล่างเป็น `dataviewjs` (best-effort) — ถ้า render แล้ว error หรือรูปแบบไม่ตรง ให้บอก Claude เพื่อแก้ syntax ให้ตรงกับ Dataview เวอร์ชันที่ใช้อยู่

## สรุปจำนวนงานแต่ละสถานะ

```dataviewjs
const statuses = [
  { tag: "#status/not-started", label: "🔴 ยังไม่เริ่ม" },
  { tag: "#status/in-progress", label: "🟡 กำลังเขียน" },
  { tag: "#status/awaiting-test", label: "🔵 เขียนเสร็จ รอเทส" },
  { tag: "#status/tested", label: "🟢 เทสผ่านแล้ว" },
];

const page = dv.page("RedM-Todo");
const tasks = page.file.tasks;

let rows = [];
let total = 0;
let doneCount = 0;
for (const s of statuses) {
  const count = tasks.filter(t => t.tags.includes(s.tag)).length;
  rows.push([s.label, count]);
  total += count;
  if (s.tag === "#status/tested") doneCount = count;
}

dv.table(["สถานะ", "จำนวน"], rows);
dv.paragraph(`**รวมทั้งหมด:** ${total} resources`);
dv.paragraph(`**ความคืบหน้ารวม (เทสผ่านแล้ว / ทั้งหมด):** ${total > 0 ? ((doneCount / total) * 100).toFixed(1) : 0}%`);
```

## Dependency ที่ยังขาด

```dataviewjs
const page = dv.page("RedM-Todo");
const blocked = page.file.lists.filter(l => l.tags && l.tags.includes("#status/blocked"));
if (blocked.length === 0) {
  dv.paragraph("ไม่พบ dependency ที่ขาด 🎉");
} else {
  dv.list(blocked.map(l => l.text.replace(/\s*#status\/blocked\s*$/, "")));
}
```

---

> สร้างจากการสแกน 179 resources ใน `resources/` — ดูรายละเอียดเต็มที่ [[RedM-Todo]]
