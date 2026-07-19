-- ═══════════════════════════════════════════════════════════════════════════
--  รีเซ็ตผู้เล่น — ลบข้อมูลทั้งบัญชี (ทุกตัวละคร) ให้กลับไปเป็นผู้เล่นใหม่
--
--  ⚠️ ลบถาวร กู้จาก DB ไม่ได้ — จึงสำรองเป็นไฟล์ JSON ไว้ก่อนลบทุกครั้ง (ดู BackupAccount)
--
--  ทำไมต้องมีไฟล์นี้แทนที่จะเรียก DeleteCharacter ของ vorp_core:
--  DeleteCharacter (vorp_core/server/class/character.lua) ลบ "แถวเดียว" ในตาราง characters
--  และทั้ง DB นี้ไม่มี FOREIGN KEY / ON DELETE CASCADE เลยสักตัว (ตรวจแล้วทุกไฟล์ .sql)
--  ผลคือม้า/ของ/ธนาคาร/ตู้เซฟ ค้างเป็นขยะใน DB ตลอดไป ต้องไล่ลบเองทีละตาราง
-- ═══════════════════════════════════════════════════════════════════════════

local RESET = {}

-- ── ตารางที่ผูกกับ "ตัวละคร" ────────────────────────────────────────────────
-- ลบด้วย charidentifier ของทุกตัวละครในบัญชี
-- ชื่อคอลัมน์ไม่ตรงกันทุกตาราง (charidentifier / char_id / charid / characterid / seller_id)
-- และบางตารางเก็บเป็น VARCHAR ไม่ใช่ INT — oxmysql แปลงให้เอง แต่ดูข้อ jail ด้านล่าง
local CHAR_TABLES = {
    -- vorp_inventory
    { t = 'character_inventories',        c = 'character_id'  },
    { t = 'items_crafted',                c = 'character_id'  },
    { t = 'loadout',                      c = 'charidentifier' },
    { t = 'vorp_fastslots',               c = 'charidentifier' },
    { t = 'vorp_inventory_preferences',   c = 'charidentifier' },
    -- เงิน/ตู้เซฟ (ของในตู้เซฟเป็น JSON ในคอลัมน์ items ตายไปพร้อมแถว)
    { t = 'bank_users',                   c = 'charidentifier' },
    -- ม้า/เกวียน/รถไฟ
    { t = 'stables',                      c = 'charidentifier' },
    { t = 'horse_complements',            c = 'charidentifier' },
    { t = 'player_horses',                c = 'charid'         },
    { t = 'player_wagons',                c = 'charid'         },
    { t = 'bcc_player_trains',            c = 'charidentifier' },
    -- ตาราง legacy ของ bcc-stables v1 — ไม่มี .sql ไหนในโปรเจกต์สร้าง แต่ vorp_admin กับ
    -- MJ-Police ยังอ่าน/เขียนอยู่ อาจมีหรือไม่มีในเซิร์ฟจริง (TableExists จะข้ามให้เองถ้าไม่มี)
    { t = 'horses',                       c = 'charid'         },
    { t = 'wagons',                       c = 'charid'         },
    -- ชุด/บัตร/เมือง
    { t = 'outfits',                      c = 'charidentifier' },
    { t = 'fx_idcard',                    c = 'charid'         },
    { t = 'nx_player_city',               c = 'charidentifier' },
    { t = 'nx_player_heritage',           c = 'charidentifier' },
    -- กิจกรรม/อาชีพ
    { t = 'animal_farm',                  c = 'char_id'        },
    { t = 'lp_marketplace',               c = 'seller_id'      },
    { t = 'lp_leaderboard_kills',         c = 'charid'         },
    { t = 'lp_leaderboard_fish',          c = 'charid'         },
    { t = 'lp_leaderboard_mining',        c = 'charid'         },
    { t = 'lp_leaderboard_planting',      c = 'charid'         },
    { t = 'lp_leaderboard_lumber',        c = 'charid'         },
    { t = 'lp_leaderboard_hunting',       c = 'charid'         },
    -- ⚠️ jail/communityservice ประกาศ characterid เป็น VARCHAR(5) (MJ-Police/sql.sql)
    -- charIdentifier ที่เกิน 5 หลัก (>= 100000) จะเก็บไม่ครบ/เทียบไม่ตรงตั้งแต่ตอนบันทึกแล้ว
    -- ไม่ใช่บั๊กของการรีเซ็ต แต่แปลว่าแถวเก่าบางแถวอาจลบไม่โดน — แจ้งไว้ใน log
    { t = 'jail',                         c = 'characterid'    },
    { t = 'communityservice',             c = 'characterid'    },
    { t = 'nx_graverobbery_security_log', c = 'character_id'   },
    -- เจอเพิ่มตอนตรวจ DB จริง (ยังว่างทั้งหมด แต่ต้องลบด้วยเมื่อมีข้อมูล)
    { t = 'herbalists',                   c = 'charidentifier' },
    { t = 'housing',                      c = 'charidentifier' },
    { t = 'rooms',                        c = 'charidentifier' },
    { t = 'oil',                          c = 'charidentifier' },
}

-- ── ตารางที่ผูกกับ "บัญชี" (steam/license) ──────────────────────────────────
-- ลบด้วย เพราะโจทย์คือให้กลับมาเป็นผู้เล่นใหม่จริงๆ (เช็คอินรายวัน/battlepass เริ่มใหม่หมด)
local ACCOUNT_TABLES = {
    { t = 'whitelist',               c = 'identifier' },
    { t = 'lp_battlepass',           c = 'identifier' },
    { t = 'welfare_progress',        c = 'identifier' },
    { t = 'dailyquest_progress',     c = 'identifier' },
    { t = 'mailboard_posts',         c = 'identifier' },
    { t = 'favorites_animations',    c = 'identifier' },
    { t = 'ban_mic',                 c = 'license'    },
    { t = 'bcc_player_connections',  c = 'license'    },
    { t = 'bcc_leaderboard_history', c = 'player_id'  },
    -- เจอเพิ่มตอนตรวจ DB จริง — ทั้งหมดผูกกับ identifier ตรงๆ
    { t = 'login_rewards',           c = 'identifier' },
    { t = 'mj_itendate',             c = 'identifier' },
    { t = 'mjdev_battlepass',        c = 'identifier' },
    { t = 'phone_photos',            c = 'identifier' },
    { t = 'player_status',           c = 'identifier' },
    { t = 'undead',                  c = 'identifier' },
}

-- ตารางที่ "อาจ" เป็นของผู้เล่นแต่ยืนยันรูปแบบค่าไม่ได้ (ตอนตรวจ DB ยังว่างหมด)
-- ไม่ลบอัตโนมัติ เพราะเดาผิดแล้วไปลบของคนอื่น — ปล่อยให้แอดมินตัดสินใจเองทีหลัง
--   mjdev_board.user_id            varchar(50)  ไม่รู้ว่าเก็บ identifier หรือเลขโทรศัพท์
--   rf_topics/rf_replies.author_id varchar(50)  เว็บบอร์ด ลบแล้วกระทู้คนอื่นอาจเสียบริบท
--   mjdev_telegrams.recipient      varchar(255) ผูกกับเบอร์โทร ไม่ใช่ identifier
--   mjdev_saveplayertelegram       varchar(255) เหมือนกัน
--   mjdev_backpack                 ไม่มีคอลัมน์ผูกตัวละครเลย (id/backpackid/model/limit เท่านั้น)
--                                  เป้จึงค้างใน DB เสมอ แม้ก่อนมีฟีเจอร์นี้ก็ค้างอยู่แล้ว

-- ── ตารางที่มีอยู่จริงไหม ───────────────────────────────────────────────────
-- เซิร์ฟไม่ได้ลง resource ครบทุกตัว ถ้ายิง DELETE ใส่ตารางที่ไม่มีจะ error แล้วหยุดกลางคัน
-- ลบไปครึ่งเดียว = สภาพแย่กว่าไม่ลบเลย จึงเช็คก่อนทุกตาราง
local tableCache = {}
local function TableExists(name)
    if tableCache[name] ~= nil then return tableCache[name] end
    local ok, n = pcall(function()
        return MySQL.scalar.await(
            'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?',
            { name })
    end)
    tableCache[name] = ok and (tonumber(n) or 0) > 0 or false
    return tableCache[name]
end

-- ── สำรองข้อมูลก่อนลบ ───────────────────────────────────────────────────────
-- อ่านเฉพาะแถวของบัญชีนี้ (ไม่กี่ร้อยแถว) แล้วเขียนเป็น JSON — ไม่ใช่ dump ทั้ง DB
-- ไม่ล็อกตาราง ไม่หน่วงเซิร์ฟ และเป็นทางเดียวที่จะกู้คืนได้ถ้าลบผิดคน
local function BackupAccount(identifier, charIds)
    local dump = { identifier = identifier, charIds = charIds, at = os.date('%Y-%m-%d %H:%M:%S'), tables = {} }

    local function grab(tbl, col, vals)
        if not TableExists(tbl) or #vals == 0 then return end
        local ph = string.rep('?', #vals, ',')
        local ok, rows = pcall(function()
            return MySQL.query.await(('SELECT * FROM `%s` WHERE `%s` IN (%s)'):format(tbl, col, ph), vals)
        end)
        if ok and rows and #rows > 0 then dump.tables[tbl] = rows end
    end

    for _, e in ipairs(CHAR_TABLES) do grab(e.t, e.c, charIds) end
    for _, e in ipairs(ACCOUNT_TABLES) do grab(e.t, e.c, { identifier }) end
    grab('characters', 'identifier', { identifier })
    grab('users', 'identifier', { identifier })
    -- ไม่ต้อง grab ด้วย inventory_type ซ้ำ: character_id ครอบคลุมกระเป๋าม้า/ตู้เซฟ/เป้อยู่แล้ว
    -- และถ้า grab ซ้ำจะเขียนทับ dump.tables['character_inventories'] ก้อนแรกจนข้อมูลสำรองหาย

    local safeId = identifier:gsub('[^%w]', '_')
    local file = ('backups/reset_%s_%s.json'):format(safeId, os.date('%Y%m%d_%H%M%S'))
    local ok = SaveResourceFile(GetCurrentResourceName(), file, json.encode(dump), -1)
    return ok and file or nil
end

-- ── ลบจริง ──────────────────────────────────────────────────────────────────
local function delWhereIn(tbl, col, vals)
    if not TableExists(tbl) then return nil end
    if #vals == 0 then return 0 end
    local ph = string.rep('?', #vals, ',')
    local ok, n = pcall(function()
        return MySQL.update.await(('DELETE FROM `%s` WHERE `%s` IN (%s)'):format(tbl, col, ph), vals)
    end)
    if not ok then
        print(('^1[MJ-Admin/reset]^7 ลบ %s ไม่สำเร็จ: %s'):format(tbl, tostring(n)))
        return nil
    end
    return tonumber(n) or 0
end

function RESET.ResetAccount(identifier, adminName)
    local report = { identifier = identifier, deleted = {}, skipped = {}, failed = {} }

    -- 1) หา charidentifier ทุกตัวละครในบัญชี
    local rows = MySQL.query.await('SELECT charidentifier FROM characters WHERE identifier = ?', { identifier }) or {}
    local charIds = {}
    for _, r in ipairs(rows) do charIds[#charIds+1] = r.charidentifier end

    -- 2) สำรองก่อนลบ
    report.backup = BackupAccount(identifier, charIds)
    if not report.backup then
        print('^1[MJ-Admin/reset]^7 สำรองข้อมูลไม่สำเร็จ — ยกเลิกการลบทั้งหมดเพื่อความปลอดภัย')
        report.abort = 'backup_failed'
        return report
    end

    local function track(tbl, n)
        if n == nil then report.failed[#report.failed+1] = tbl
        elseif n > 0 then report.deleted[tbl] = n
        else report.skipped[#report.skipped+1] = tbl end
    end

    -- 3) ตารางระดับตัวละคร
    for _, e in ipairs(CHAR_TABLES) do track(e.t, delWhereIn(e.t, e.c, charIds)) end

    -- 5) ไม่ต้องลบด้วย inventory_type — ตรวจ DB จริงแล้วพบว่า character_inventories.character_id
    --    ถูกใส่ครบทุกแถว (0 แถวที่ว่าง) รวมกระเป๋าม้า 'horse_<id>', ตู้เซฟ
    --    'vorp_banking_<เมือง>_<charid>' และเป้ (เลข backpackid) เช่นเดียวกับ loadout.charidentifier
    --    การลบด้วย character_id/charidentifier ตัวเดียวจึงครอบคลุมหมดแล้ว
    --    เคยเขียนลบด้วย inventory_type ซ้ำอีกชั้น แต่ถอดออก เพราะถ้าม้าเคยถูกโอนให้คนอื่น
    --    แถวกระเป๋าจะเป็นของเจ้าของใหม่ แต่ inventory_type ยังเป็น horse_<id> เดิม = ไปลบของคนอื่น

    -- 4) แถวที่เป็นของ "คนอื่น" แต่อ้างถึงเรา — ห้ามลบ ให้ตัดความเชื่อมโยงแทน
    --    lp_marketplace.buyer_id อยู่ในแถวขายของผู้เล่นคนอื่น ลบทิ้ง = ไปลบประวัติขายของเขา
    if TableExists('lp_marketplace') and #charIds > 0 then
        local ph = string.rep('?', #charIds, ',')
        pcall(function()
            MySQL.update.await(('UPDATE lp_marketplace SET buyer_id = NULL WHERE buyer_id IN (%s)'):format(ph), charIds)
        end)
    end
    --    nx_graverobbery_graves เป็น world-state (คูลดาวน์หลุมศพ) ไม่ใช่ของผู้เล่น
    if TableExists('nx_graverobbery_graves') and #charIds > 0 then
        local ph = string.rep('?', #charIds, ',')
        pcall(function()
            MySQL.update.await(('UPDATE nx_graverobbery_graves SET looted_by_character = NULL WHERE looted_by_character IN (%s)'):format(ph), charIds)
        end)
    end

    -- 5) ตารางระดับบัญชี
    for _, e in ipairs(ACCOUNT_TABLES) do track(e.t, delWhereIn(e.t, e.c, { identifier })) end

    -- 6) โค้ดรับรางวัลที่เคยกด — เก็บในไฟล์ JSON ของ MJ-CodeReward ไม่ได้อยู่ใน DB
    --    SQL แตะไม่ถึง ต้องเรียก export ของมันเอง (ไม่งั้นรีเซ็ตแล้วยังกดโค้ดเดิมซ้ำไม่ได้)
    local okCode, clearedCodes = pcall(function()
        return exports['MJ-CodeReward']:ClearPlayerCodes(identifier)
    end)
    report.codesCleared = okCode and clearedCodes or false
    if not okCode then
        print('^3[MJ-Admin/reset]^7 ล้างโค้ดรับรางวัลไม่สำเร็จ (MJ-CodeReward ไม่ได้ ensure?) — โค้ดเดิมจะยังกดซ้ำไม่ได้')
    end

    -- 7) characters แล้วค่อย users (ลำดับนี้เท่านั้น)
    --    vorp_core config มี DeleteFromUsersTable = true ที่ตอนบูตจะลบแถว users ที่ไม่มี
    --    characters อยู่แล้ว — เราลบเองตรงนี้เลยจะได้ไม่ต้องรอรีสตาร์ทและได้ผลแน่นอน
    track('characters', delWhereIn('characters', 'identifier', { identifier }))
    track('users',      delWhereIn('users',      'identifier', { identifier }))

    return report
end

-- ── event จาก NUI ───────────────────────────────────────────────────────────
RegisterNetEvent('admin:ResetPlayerAccount')
AddEventHandler('admin:ResetPlayerAccount', function(targetId, typedName)
    local src = source

    local group = admin and admin.GetPlayerGroup and admin.GetPlayerGroup(src) or 'user'
    if not (Config['Perms'][group] and Config['Perms'][group].CanResetAccount) then
        TriggerClientEvent('pNotify:SendNotification', src, {
            text = 'คุณไม่มีสิทธิ์รีเซ็ตผู้เล่น', type = 'error', timeout = 4000, layout = 'topRight' })
        return
    end

    targetId = tonumber(targetId)
    if not targetId then return end

    if targetId == src then
        TriggerClientEvent('pNotify:SendNotification', src, {
            text = 'รีเซ็ตตัวเองไม่ได้', type = 'error', timeout = 4000, layout = 'topRight' })
        return
    end

    local tUser = VORPcore.getUser(targetId)
    local tChar = tUser and tUser.getUsedCharacter
    if not tUser or not tChar then
        TriggerClientEvent('pNotify:SendNotification', src, {
            text = 'หาผู้เล่นคนนี้ไม่เจอ (ออกจากเซิร์ฟไปแล้ว?)', type = 'error', timeout = 4000, layout = 'topRight' })
        return
    end

    -- ยืนยันด้วยการพิมพ์ชื่อตัวละครให้ตรงเป๊ะ — งานนี้ย้อนไม่ได้ การพิมพ์ "1" เฉยๆ
    -- อย่างคำสั่งอื่นเบาเกินไป กดพลาดทีเดียวข้อมูลผู้เล่นหายทั้งบัญชี
    local realName = ('%s %s'):format(tChar.firstname or '', tChar.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if tostring(typedName or ''):gsub('^%s+', ''):gsub('%s+$', '') ~= realName then
        TriggerClientEvent('pNotify:SendNotification', src, {
            text = 'ชื่อไม่ตรง — ยกเลิกการรีเซ็ต (ต้องพิมพ์ "' .. realName .. '")',
            type = 'error', timeout = 6000, layout = 'topRight' })
        return
    end

    local identifier = tChar.identifier or tUser.getIdentifier
    if type(identifier) == 'function' then identifier = tUser.getIdentifier() end
    if not identifier or identifier == '' then
        TriggerClientEvent('pNotify:SendNotification', src, {
            text = 'อ่าน identifier ของผู้เล่นไม่ได้ — ยกเลิก', type = 'error', timeout = 4000, layout = 'topRight' })
        return
    end

    local adminName = GetPlayerName(src) or ('src' .. src)
    print(('^1[MJ-Admin/reset]^7 %s สั่งรีเซ็ตบัญชี %s (%s)'):format(adminName, realName, identifier))

    local report = RESET.ResetAccount(identifier, adminName)

    if report.abort then
        TriggerClientEvent('pNotify:SendNotification', src, {
            text = 'รีเซ็ตไม่สำเร็จ: สำรองข้อมูลไม่ได้ (ไม่มีอะไรถูกลบ)', type = 'error', timeout = 6000, layout = 'topRight' })
        return
    end

    local total, lines = 0, {}
    for tbl, n in pairs(report.deleted) do
        total = total + n
        lines[#lines+1] = ('%s=%d'):format(tbl, n)
    end
    table.sort(lines)
    print(('^1[MJ-Admin/reset]^7 ลบรวม %d แถว | %s'):format(total, table.concat(lines, ' ')))
    if #report.failed > 0 then
        print(('^1[MJ-Admin/reset]^7 ตารางที่ลบไม่สำเร็จ: %s'):format(table.concat(report.failed, ', ')))
    end
    print(('^2[MJ-Admin/reset]^7 สำรองไว้ที่ %s/%s'):format(GetCurrentResourceName(), report.backup))

    -- ส่ง webhook เป็น '' ตามที่ทุก handler ในไฟล์นี้ทำอยู่ (โปรเจกต์ยังไม่ได้ตั้ง URL จริง)
    -- ถ้าวันหลังใส่ URL ให้ใส่ที่นี่ด้วย งานรีเซ็ตควรมีร่องรอยใน Discord มากกว่าคำสั่งอื่น
    if SetDistcord then
        pcall(SetDistcord, 'MJDev-Admin ', 'Admin',
            (' ``` [รีเซ็ตบัญชี] แอดมิน : %s\n ผู้เล่น : %s\n %s\n ลบ %d แถว | สำรอง: %s ```')
                :format(adminName, realName, identifier, total, report.backup),
            16711680, '')
    end

    -- เตะออกให้เข้าใหม่เป็นผู้เล่นใหม่ — ต้องเตะเสมอ ถ้าปล่อยค้างอยู่ในเซิร์ฟ
    -- vorp_core จะยังถือ object ตัวละครเก่าไว้ใน memory แล้วเซฟกลับลง DB ตอนออก
    -- = แถวที่เพิ่งลบไปโผล่กลับมาใหม่
    DropPlayer(targetId, 'บัญชีของคุณถูกรีเซ็ตโดยผู้ดูแล — เข้าใหม่เพื่อสร้างตัวละคร')

    TriggerClientEvent('pNotify:SendNotification', src, {
        text = ('รีเซ็ต %s เรียบร้อย (ลบ %d แถว, สำรองไว้แล้ว)'):format(realName, total),
        type = 'success', timeout = 8000, layout = 'topRight' })
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  กู้คืนจากไฟล์สำรอง — สั่งได้จาก console ของเซิร์ฟเวอร์เท่านั้น
--
--  ทำไมจำกัดแค่ console: การเขียนแถวกลับเข้า DB ตรงๆ อันตรายกว่าการลบเสียอีก
--  (ใส่ผิดไฟล์ = ยัดของคนหนึ่งเข้าอีกบัญชี) และงานนี้ไม่ต้องรีบทำกลางเกม
--
--  วิธีใช้:  mjadmin_restore reset_steam_11000010d615891_20260719_213045.json
-- ═══════════════════════════════════════════════════════════════════════════

-- users/characters ต้องเข้าก่อนเสมอ ตารางที่เหลืออ้าง charidentifier จากตรงนี้
-- (ไม่มี FOREIGN KEY บังคับ แต่ถ้าใส่สลับลำดับ ผู้เล่นจะเข้าเกมมาเจอของโดยไม่มีตัวละคร)
local RESTORE_FIRST = { 'users', 'characters' }

local function insertRows(tbl, rows)
    if not TableExists(tbl) then return nil end
    local done, failed = 0, 0
    for _, row in ipairs(rows) do
        local cols, marks, vals = {}, {}, {}
        for k, v in pairs(row) do
            -- ข้าม table/ค่าแปลกๆ ที่ json คืนมา (คอลัมน์ที่เป็น NULL จะหายไปเองตั้งแต่ตอน encode
            -- แล้วปล่อยให้ MySQL ใส่ค่า default ให้ ไม่ต้องจัดการเพิ่ม)
            if type(v) ~= 'table' then
                cols[#cols+1]  = ('`%s`'):format(k)
                marks[#marks+1] = '?'
                vals[#vals+1]  = v
            end
        end
        if #cols > 0 then
            -- INSERT IGNORE: รันซ้ำได้ไม่พัง ถ้าแถวถูกกู้ไปแล้วจะข้ามให้เอง
            local ok = pcall(function()
                MySQL.update.await(('INSERT IGNORE INTO `%s` (%s) VALUES (%s)')
                    :format(tbl, table.concat(cols, ','), table.concat(marks, ',')), vals)
            end)
            if ok then done = done + 1 else failed = failed + 1 end
        end
    end
    return done, failed
end

RegisterCommand('mjadmin_restore', function(source, args)
    -- source 0 = console เท่านั้น ผู้เล่นในเกมพิมพ์คำสั่งนี้จะไม่มีผล
    if source ~= 0 then return end

    local fileName = args[1]
    if not fileName or fileName == '' then
        print('^3[MJ-Admin/restore]^7 ใช้: mjadmin_restore <ชื่อไฟล์ใน backups/>')
        return
    end

    local raw = LoadResourceFile(GetCurrentResourceName(), 'backups/' .. fileName)
    if not raw or raw == '' then
        print(('^1[MJ-Admin/restore]^7 อ่านไฟล์ไม่ได้: backups/%s'):format(fileName))
        return
    end

    local ok, dump = pcall(json.decode, raw)
    if not ok or type(dump) ~= 'table' or type(dump.tables) ~= 'table' then
        print('^1[MJ-Admin/restore]^7 ไฟล์สำรองเสียหาย หรือไม่ใช่ไฟล์ของระบบนี้')
        return
    end

    -- ผู้เล่นออนไลน์อยู่ = vorp_core ถือตัวละครไว้ใน memory และจะเซฟทับตอนออก
    -- ของที่เพิ่งกู้กลับมาจะโดนเขียนทับหาย ต้องให้ออกจากเซิร์ฟก่อน
    for _, pid in ipairs(GetPlayers()) do
        local u = VORPcore.getUser(tonumber(pid))
        local c = u and u.getUsedCharacter
        if c and c.identifier == dump.identifier then
            print(('^1[MJ-Admin/restore]^7 %s ออนไลน์อยู่ (id %s) — ให้ออกจากเซิร์ฟก่อนแล้วสั่งใหม่')
                :format(dump.identifier, pid))
            return
        end
    end

    print(('^3[MJ-Admin/restore]^7 กำลังกู้คืน %s (สำรองเมื่อ %s)')
        :format(tostring(dump.identifier), tostring(dump.at)))

    local totalOk, totalFail, restored = 0, 0, {}

    local function run(tbl)
        local rows = dump.tables[tbl]
        if not rows or restored[tbl] then return end
        restored[tbl] = true
        local d, f = insertRows(tbl, rows)
        if d == nil then
            print(('^3[MJ-Admin/restore]^7 ข้าม %s (ไม่มีตารางนี้ใน DB)'):format(tbl))
            return
        end
        totalOk, totalFail = totalOk + d, totalFail + f
        print(('  %-32s กู้ %d/%d แถว%s'):format(tbl, d, #rows, f > 0 and (' ^1ล้มเหลว ' .. f .. '^7') or ''))
    end

    for _, t in ipairs(RESTORE_FIRST) do run(t) end
    for t in pairs(dump.tables) do run(t) end

    print(('^2[MJ-Admin/restore]^7 เสร็จ — กู้สำเร็จ %d แถว, ล้มเหลว %d แถว'):format(totalOk, totalFail))
    if totalFail > 0 then
        print('^3[MJ-Admin/restore]^7 แถวที่ล้มเหลวมักเกิดจาก id ชนกับข้อมูลใหม่ที่สร้างหลังรีเซ็ต')
    end
end, true)

-- ═══════════════════════════════════════════════════════════════════════════
--  เก็บกวาดข้อมูลกำพร้า — แถวที่เจ้าของถูกลบไปแล้วแต่ข้อมูลยังค้าง
--
--  เกิดจาก DeleteCharacter ของ vorp_core ลบแค่แถวใน characters และ DB ไม่มี
--  ON DELETE CASCADE เลย ทุกครั้งที่มีคนลบตัวละคร ของ/ม้า/ธนาคารของเขาจะค้างถาวร
--
--  วิธีใช้:  mjadmin_cleanup          -> รายงานอย่างเดียว ไม่ลบ (ค่าเริ่มต้น)
--            mjadmin_cleanup confirm  -> ลบจริง (สำรองก่อนเสมอ)
-- ═══════════════════════════════════════════════════════════════════════════

RegisterCommand('mjadmin_cleanup', function(source, args)
    if source ~= 0 then return end -- console เท่านั้น

    local doIt = (args[1] == 'confirm')

    -- ⚠️ กันหายนะ: ถ้าตาราง characters ว่าง เงื่อนไข NOT IN (ชุดว่าง) จะเป็นจริงกับทุกแถว
    -- = ลบข้อมูลผู้เล่นทั้งเซิร์ฟเวอร์ทิ้งหมด ต้องหยุดก่อนถึงจะไปต่อ
    local charCount = tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM characters')) or 0
    if charCount == 0 then
        print('^1[MJ-Admin/cleanup]^7 ตาราง characters ว่างเปล่า — หยุดทันที')
        print('^1[MJ-Admin/cleanup]^7 ถ้าปล่อยไปจะกลายเป็นลบข้อมูลผู้เล่นทั้งเซิร์ฟเวอร์')
        return
    end

    print(('^3[MJ-Admin/cleanup]^7 %s (ตัวละครที่ยังอยู่ %d ตัว)')
        :format(doIt and 'กำลังลบข้อมูลกำพร้า' or 'ตรวจอย่างเดียว ยังไม่ลบ', charCount))

    -- นับก่อนเสมอ ทั้งโหมดตรวจและโหมดลบ (โหมดลบใช้ยอดนี้ไปทำ backup ด้วย)
    local found, total = {}, 0
    for _, e in ipairs(CHAR_TABLES) do
        if TableExists(e.t) then
            local ok, n = pcall(function()
                return MySQL.scalar.await(
                    ('SELECT COUNT(*) FROM `%s` WHERE `%s` NOT IN (SELECT charidentifier FROM characters)')
                        :format(e.t, e.c))
            end)
            n = ok and (tonumber(n) or 0) or 0
            if n > 0 then
                found[#found+1] = { t = e.t, c = e.c, n = n }
                total = total + n
            end
        end
    end

    -- บัญชีที่ไม่เหลือตัวละครสักตัว (vorp_core มี DeleteFromUsersTable ทำตอนบูตอยู่แล้ว
    -- แต่ทำเฉพาะตอนรีสตาร์ท ตรงนี้เก็บให้เดี๋ยวนั้นเลย)
    local orphanUsers = tonumber(MySQL.scalar.await(
        'SELECT COUNT(*) FROM users WHERE identifier NOT IN (SELECT identifier FROM characters)')) or 0

    if total == 0 and orphanUsers == 0 then
        print('^2[MJ-Admin/cleanup]^7 สะอาดอยู่แล้ว ไม่มีข้อมูลกำพร้า')
        return
    end

    for _, f in ipairs(found) do
        print(('  %-32s %d แถว'):format(f.t, f.n))
    end
    if orphanUsers > 0 then print(('  %-32s %d แถว'):format('users (ไม่เหลือตัวละคร)', orphanUsers)) end
    print(('^3[MJ-Admin/cleanup]^7 รวม %d แถว'):format(total + orphanUsers))

    if not doIt then
        print('^3[MJ-Admin/cleanup]^7 พิมพ์ "mjadmin_cleanup confirm" เพื่อลบจริง (สำรองให้ก่อนอัตโนมัติ)')
        return
    end

    -- สำรองก่อนลบ เหมือนตอนรีเซ็ตบัญชี
    local dump = { kind = 'cleanup', at = os.date('%Y-%m-%d %H:%M:%S'), tables = {} }
    for _, f in ipairs(found) do
        local ok, rows = pcall(function()
            return MySQL.query.await(
                ('SELECT * FROM `%s` WHERE `%s` NOT IN (SELECT charidentifier FROM characters)')
                    :format(f.t, f.c))
        end)
        if ok and rows and #rows > 0 then dump.tables[f.t] = rows end
    end
    if orphanUsers > 0 then
        local ok, rows = pcall(function()
            return MySQL.query.await('SELECT * FROM users WHERE identifier NOT IN (SELECT identifier FROM characters)')
        end)
        if ok and rows then dump.tables['users'] = rows end
    end

    local file = ('backups/cleanup_%s.json'):format(os.date('%Y%m%d_%H%M%S'))
    if not SaveResourceFile(GetCurrentResourceName(), file, json.encode(dump), -1) then
        print('^1[MJ-Admin/cleanup]^7 สำรองไม่สำเร็จ — ยกเลิกการลบทั้งหมด')
        return
    end
    print(('^2[MJ-Admin/cleanup]^7 สำรองไว้ที่ %s'):format(file))

    local deleted = 0
    for _, f in ipairs(found) do
        local ok, n = pcall(function()
            return MySQL.update.await(
                ('DELETE FROM `%s` WHERE `%s` NOT IN (SELECT charidentifier FROM characters)')
                    :format(f.t, f.c))
        end)
        if ok then
            deleted = deleted + (tonumber(n) or 0)
            print(('  ลบ %-30s %s แถว'):format(f.t, tostring(n)))
        else
            print(('^1  ลบ %s ไม่สำเร็จ: %s^7'):format(f.t, tostring(n)))
        end
    end
    if orphanUsers > 0 then
        local ok, n = pcall(function()
            return MySQL.update.await('DELETE FROM users WHERE identifier NOT IN (SELECT identifier FROM characters)')
        end)
        if ok then deleted = deleted + (tonumber(n) or 0) end
    end

    print(('^2[MJ-Admin/cleanup]^7 เสร็จ — ลบไป %d แถว (กู้คืนด้วย mjadmin_restore %s)')
        :format(deleted, file:match('[^/]+$')))
end, true)
