--[[
    lp_rewardpanel — reward-chance drop panel (ไอคอน + % โอกาส + highlight ตอนได้ของ)

    ย้ายมาจาก MJ-AfkFishing's drop-panel แยกเป็นสคริปกลางให้สคริปเก็บของ/ล่าสัตว์อื่นเรียกใช้ซ้ำได้
    (เช่น mining, lumberjack, animal farm) — client-only, fire-and-forget (ไม่บล็อก เหมือน lp_textui)
    ตำแหน่งบนจอคงที่ตายตัวจุดเดียว (มุมซ้าย ตรงกับดีไซน์เดิม) ผู้เรียกปรับได้แค่ items/title/subtitle

    ------------------------------------------------------------------
    USAGE
    ------------------------------------------------------------------

    exports.lp_rewardpanel:Show({
        { img = 'nui://vorp_inventory/html/img/items/a_c_fishbluegil_01_sm.png', chance = 70, item = 'a_c_fishbluegil_01_sm' },
        { img = 'nui://vorp_inventory/html/img/items/legendary_bluegill.png',    chance = 6,  item = 'legendary_bluegill' },
        -- ... สูงสุด Config.SlotCount ชิ้น (เกินจะไม่โชว์)
    })

    -- title/subtitle ปรับได้ต่อผู้เรียก (ค่าเริ่มต้นมาจาก config.lua):
    exports.lp_rewardpanel:Show(items, 'โอกาสดร็อปปลาในโซน', 'Fish Drop Info')

    -- flash ช่องที่ item ตรงกัน (เรียกตอนได้ของจริง):
    exports.lp_rewardpanel:Highlight('a_c_fishbluegil_01_sm')

    exports.lp_rewardpanel:Hide()

    ------------------------------------------------------------------
    EXPORTS
      Show(items, title, subtitle)   -- title/subtitle optional
      Hide()
      Highlight(item)
    ------------------------------------------------------------------
]]

local function Show(items, title, subtitle)
    SendNUIMessage({
        action   = 'lp_rewardpanel:show',
        items    = items or {},
        title    = title or Config.DefaultTitle,
        subtitle = subtitle or Config.DefaultSubtitle,
    })
end

local function Hide()
    SendNUIMessage({ action = 'lp_rewardpanel:hide' })
end

local function Highlight(item)
    SendNUIMessage({ action = 'lp_rewardpanel:highlight', item = item })
end

exports('Show', Show)
exports('Hide', Hide)
exports('Highlight', Highlight)

-- ── Test commands (F8 console) ──────────────────────────────────────────
-- /rewardpanel_test    โชว์ panel ตัวอย่าง 4 ไอเทม แล้ว highlight ตัวที่ 2 หลัง 2 วิ
-- /rewardpanel_hide    ซ่อน panel

RegisterCommand('rewardpanel_test', function()
    Show({
        { img = 'nui://vorp_inventory/html/img/items/a_c_fishbluegil_01_sm.png',  chance = 70, item = 'a_c_fishbluegil_01_sm' },
        { img = 'nui://vorp_inventory/html/img/items/a_c_fishperch_01_sm.png',    chance = 68, item = 'a_c_fishperch_01_sm' },
        { img = 'nui://vorp_inventory/html/img/items/a_c_fishrockbass_01_sm.png', chance = 66, item = 'a_c_fishrockbass_01_sm' },
        { img = 'nui://vorp_inventory/html/img/items/legendary_bluegill.png',     chance = 6,  item = 'legendary_bluegill' },
    }, 'โอกาสดร็อปปลาในโซน', 'Fish Drop Info')
    Citizen.SetTimeout(2000, function() Highlight('a_c_fishperch_01_sm') end)
end, false)

RegisterCommand('rewardpanel_hide', function()
    Hide()
end, false)
