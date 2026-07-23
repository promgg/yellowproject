-- แค่วางไฟล์ใน stream/ ไม่พอให้เกมโหลดฟอนต์ — ต้อง register font lib ด้วย
-- อ้างอิง citizenfx/fivem `sfFontStuff.cpp`: RegisterFontFile(name) จะหา streaming index
-- ของ "<name>.gfx" (ที่เรา stream ไว้) แล้ว queue เข้าระบบฟอนต์ ถ้าไม่ register = ไม่โหลด
--
-- RegisterFontFile รับชื่อ "ไม่ต้องใส่ .gfx" แล้วเติมเอง → 'font_lib_efigs' -> font_lib_efigs.gfx
-- register ทั้งสองชื่อ (มี/ไม่มี _pc) เผื่อ engine ใช้ตัวไหน
CreateThread(function()
    -- รอ streaming พร้อมก่อนเล็กน้อย
    Wait(500)

    if type(RegisterFontFile) == 'function' then
        RegisterFontFile('font_lib_efigs')
        RegisterFontFile('font_lib_efigs_pc')
        print('[fontthai] RegisterFontFile: font_lib_efigs (+_pc) เรียบร้อย')
    else
        print('[fontthai] ^1RegisterFontFile ไม่มีใน build นี้^7 — RedM อาจยังไม่รองรับ native นี้')
    end
end)
