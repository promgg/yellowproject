-- ============================================================
-- nx_shop : เมล็ดเพิ่มเติม (อ้อย / ส้ม / เบอรี่)
-- ใช้ชุดชื่อ seed_* ให้สอดคล้องกับระบบฟาร์มรุ่นใหม่ใน rdr_items_insert.sql
-- schema: mjdevcore_18k.items
-- (item,label,`limit`,weight,can_remove,`type`,usable,groupId,metadata,`desc`,degradation)
-- ============================================================

INSERT INTO mjdevcore_18k.items
    (item, label, `limit`, weight, can_remove, `type`, usable, groupId, metadata, `desc`, degradation)
VALUES
    ('seed_sugarcane', 'เมล็ดอ้อย',  10, 0.25, 1, 'item_standard', 1, 1, '{}', 'ใช้ปลูกผัก', 0),
    ('seed_orange',    'เมล็ดส้ม',   10, 0.25, 1, 'item_standard', 1, 1, '{}', 'ใช้ปลูกผัก', 0),
    ('seed_berry',     'เมล็ดเบอรี่', 10, 0.25, 1, 'item_standard', 1, 1, '{}', 'ใช้ปลูกผัก', 0);
