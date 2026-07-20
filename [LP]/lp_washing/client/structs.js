// TASK_MOVE_NETWORK_BY_NAME_WITH_INIT_PARAMS (0x139805C2A67C4795)
//
// native ตัวนี้รับ struct เป็นพารามิเตอร์ ซึ่งฝั่ง Lua ของ FiveM สร้างไม่ได้
// เลยต้องมาประกอบ ArrayBuffer ฝั่ง JS แทน (วิธีเดียวกับ rsg-bathing/client/structs.js)
//
// offset ในบัฟเฟอร์:
//   0   = clipset hash
//   8   = filter/type hash (ปกติส่ง `DEFAULT`)
//   240 = ชื่อ state เริ่มต้น เป็น VarString ไม่ใช่ string ธรรมดา
//
// ที่ต้องมีเพราะ: หลังฉาก intro จบ ถ้าไม่มี task ค้างท่าไว้ ตัวละครจะหลุดจาก
// ท่าอาบน้ำทันที (เด้งกลับท่ายืน) — นี่คืออาการ "อนิเมชั่นไม่ต่อเนื่อง"
on('lp_washing:TaskMoveNetworkWithInitParams', (args) => {
    const struct = new DataView(new ArrayBuffer(512));
    struct.setBigInt64(0, BigInt(args[2]), true);
    struct.setBigInt64(8, BigInt(args[3]), true);
    struct.setBigInt64(240, BigInt(CreateVarString(10, "LITERAL_STRING", args[4])), true);

    Citizen.invokeNative("0x139805C2A67C4795", args[0], args[1], struct, 1.0, 0, 0, 0);
});
