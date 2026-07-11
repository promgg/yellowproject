/* MJ-AfkFishing — อัปเดต label ปลาเป็นภาษาไทย (2026-07-11)
   ใช้กับ DB ที่มีไอเทมปลาอยู่แล้ว (INSERT IGNORE ใน fish_items.sql จะไม่แก้แถวเดิม ต้องใช้ UPDATE นี้)
   *** ต้องต่อ mysql ด้วย charset utf8mb4 ไม่งั้น label ไทยจะเพี้ยนเป็น mojibake ***
   รวมเป็น UPDATE ประโยคเดียว (CASE WHEN) แทนหลายประโยคคั่น ; เพื่อให้รันได้ในเครื่องมือ SQL
   ที่ไม่รองรับ multi-statement execution ด้วย */

UPDATE `items`
SET `label` = CASE `item`
    WHEN 'fish_bluegill_small'          THEN 'ปลาบลูกิลล์'
    WHEN 'fish_perch_small'             THEN 'ปลาคอน'
    WHEN 'fish_rockbass_small'          THEN 'ปลาร็อกแบส'
    WHEN 'fish_chainpickerel_small'     THEN 'ปลาพิกเคอเรลลายโซ่'
    WHEN 'fish_redfinpickerel_small'    THEN 'ปลาพิกเคอเรลครีบแดง'
    WHEN 'fish_bullheadcat_small'       THEN 'ปลาดุกหัวกระทิง'

    WHEN 'fish_largemouthbass_medium'   THEN 'ปลาแบสปากกว้าง'
    WHEN 'fish_smallmouthbass_medium'   THEN 'ปลาแบสปากเล็ก'
    WHEN 'fish_salmonsockeye_medium'    THEN 'ปลาแซลมอนซ็อกอาย'
    WHEN 'fish_rainbowtrout_medium'     THEN 'ปลาเทราต์สตีลเฮด'

    WHEN 'fish_channelcatfish_large'    THEN 'ปลาดุกแชนแนล'
    WHEN 'fish_longnosegar_large'       THEN 'ปลาการ์จมูกยาว'
    WHEN 'fish_lakesturgeon_large'      THEN 'ปลาสเตอร์เจียนน้ำจืด'
    WHEN 'fish_muskie_large'            THEN 'ปลามัสกี้'
    WHEN 'fish_northernpike_large'      THEN 'ปลาหอกเหนือ'

    WHEN 'fish_bluegill_legendary'       THEN 'ปลาบลูกิลล์ในตำนาน'
    WHEN 'fish_perch_legendary'          THEN 'ปลาคอนในตำนาน'
    WHEN 'fish_rockbass_legendary'       THEN 'ปลาร็อกแบสในตำนาน'
    WHEN 'fish_chainpickerel_legendary'  THEN 'ปลาพิกเคอเรลลายโซ่ในตำนาน'
    WHEN 'fish_redfinpickerel_legendary' THEN 'ปลาพิกเคอเรลครีบแดงในตำนาน'
    WHEN 'fish_bullheadcat_legendary'    THEN 'ปลาดุกหัวกระทิงในตำนาน'
    WHEN 'fish_largemouthbass_legendary' THEN 'ปลาแบสปากกว้างในตำนาน'
    WHEN 'fish_smallmouthbass_legendary' THEN 'ปลาแบสปากเล็กในตำนาน'
    WHEN 'fish_salmonsockeye_legendary'  THEN 'ปลาแซลมอนซ็อกอายในตำนาน'
    WHEN 'fish_rainbowtrout_legendary'   THEN 'ปลาเทราต์สตีลเฮดในตำนาน'
    WHEN 'fish_channelcatfish_legendary' THEN 'ปลาดุกแชนแนลในตำนาน'
    WHEN 'fish_longnosegar_legendary'    THEN 'ปลาการ์จมูกยาวในตำนาน'
    WHEN 'fish_lakesturgeon_legendary'   THEN 'ปลาสเตอร์เจียนน้ำจืดในตำนาน'
    WHEN 'fish_muskie_legendary'         THEN 'ปลามัสกี้ในตำนาน'
    WHEN 'fish_northernpike_legendary'   THEN 'ปลาหอกเหนือในตำนาน'
    ELSE `label`
END
WHERE `item` IN (
    'fish_bluegill_small','fish_perch_small','fish_rockbass_small','fish_chainpickerel_small',
    'fish_redfinpickerel_small','fish_bullheadcat_small',
    'fish_largemouthbass_medium','fish_smallmouthbass_medium','fish_salmonsockeye_medium','fish_rainbowtrout_medium',
    'fish_channelcatfish_large','fish_longnosegar_large','fish_lakesturgeon_large','fish_muskie_large','fish_northernpike_large',
    'fish_bluegill_legendary','fish_perch_legendary','fish_rockbass_legendary','fish_chainpickerel_legendary',
    'fish_redfinpickerel_legendary','fish_bullheadcat_legendary','fish_largemouthbass_legendary','fish_smallmouthbass_legendary',
    'fish_salmonsockeye_legendary','fish_rainbowtrout_legendary','fish_channelcatfish_legendary','fish_longnosegar_legendary',
    'fish_lakesturgeon_legendary','fish_muskie_legendary','fish_northernpike_legendary'
);
