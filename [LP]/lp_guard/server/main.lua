local RES = GetCurrentResourceName()

-- นับความยาวชื่อเป็น "ตัวอักษร" (UTF-8 codepoint) ไม่ใช่ byte
-- ภาษาไทย/ยูนิโค้ด 1 ตัว = หลาย byte ถ้านับ byte จะเตะผู้เล่นไทยที่ชื่อไม่ยาวจริง
-- utf8.len คืน nil ถ้าสตริงไม่ใช่ UTF-8 ที่ถูกต้อง -> fallback ไปนับ byte (เข้มกว่า ปลอดภัยกว่า)
local function nameLen(s)
    if type(s) ~= 'string' then return 0 end
    return utf8.len(s) or #s
end

local function log(msg)
    if Config.NameGuard and Config.NameGuard.Log then
        print(('[%s] %s'):format(RES, msg))
    end
end

-- ── กันชื่อยาวตอน connect ─────────────────────────────────────────────────
-- ใช้ deferrals ปฏิเสธ "ก่อน" ผู้เล่นเข้าเซิร์ฟ (ยังไม่ได้จองสล็อต ยังไม่โหลดตัวละคร)
-- name = ชื่อ client/Steam ที่ผู้เล่นตั้ง (ตัวเดียวกับ GetPlayerName ที่ไหลไป steamname)
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local cfg = Config.NameGuard
    if not cfg or not cfg.Enabled then return end

    deferrals.defer()
    Wait(0) -- ต้อง yield อย่างน้อย 1 ครั้งหลัง defer() ก่อนเรียก done()

    local n = name or ''
    local len = nameLen(n)

    if cfg.MinLength and cfg.MinLength > 0 and len < cfg.MinLength then
        log(('ปฏิเสธ (ชื่อสั้น %d ตัว): %q'):format(len, n))
        deferrals.done(cfg.RejectTooShort or 'Name too short')
        return
    end

    if len > (cfg.MaxLength or 32) then
        log(('ปฏิเสธ (ชื่อยาว %d ตัว): %q'):format(len, n))
        deferrals.done((cfg.RejectMessage or 'Name too long (%d/%d)'):format(len, cfg.MaxLength or 32))
        return
    end

    deferrals.done() -- ผ่าน อนุญาตให้เข้า
end)

print(('[%s] name-length guard พร้อมทำงาน (max=%s ตัว)')
    :format(RES, tostring(Config.NameGuard and Config.NameGuard.MaxLength)))
