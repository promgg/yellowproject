# All Craft Dashboard — ระบบคราฟทั้งหมด

> ข้อมูลดึงจาก `config_sv.lua` จริงของ `nx_crafting` ณ วันที่สร้างไฟล์นี้ — ถ้าแก้ config ทีหลัง ต้องสั่งให้ Claude สแกนใหม่เพื่ออัปเดตไฟล์นี้ (ไม่ใช่ live query)
>
> **ขอบเขต:** ตกลงกันว่าไฟล์นี้ครอบคลุมเฉพาะ `nx_crafting` (23 หมวด, 157 สูตรคราฟ) ไม่รวม `MJ-Crafting`/`vorp_crafting`
> รายการที่มีมากกว่า 1 สูตร (recipe variant) ต่อไอเทม ตารางด้านล่างแสดงเฉพาะสูตรแรก/สูตรหลักเท่านั้น (2 ไอเทมมีสูตรทางเลือกเพิ่ม)

## หมวดหมู่ทั้งหมด

| หมวด | จำนวนสูตร |
|---|---|
| อาวุธ | 2 |
| ยา | 2 |
| อาหาร | 3 |
| การตีบัตรแต่งตัว | 1 |
| เหมืองแร่ | 4 |
| วัสดุก่อสร้าง | 3 |
| ชนเผ่า | 2 |
| โต๊ะคราฟทั่วไป | 4 |
| อาวุธ Tier 1 | 15 |
| อาวุธ Tier 2 | 14 |
| อาวุธ Tier 3 | 15 |
| อาวุธ Tier 4 | 15 |
| อาวุธ Tier 5 | 15 |
| อาวุธ Tier 6 | 10 |
| อาวุธ Tier 7 | 10 |
| อาวุธ Tier 8 | 8 |
| อาวุธ Tier 9 | 10 |
| อาวุธ Tier 10 | 10 |
| โต๊ะทำอาหาร Valentine | 4 |
| โต๊ะทำอาหาร Rhodes | 4 |
| โต๊ะทำอาหาร Annesburg | 4 |
| เหลาไม้ | 1 |
| ทำไม้แผ่น | 1 |

---

## อาวุธ (2 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `WEAPON_REVOLVER_NAVY` (Navy Revolver) | iron×10, wood×4, mechanism×1 | hammer×1 | $50 | 80% |
| `WEAPON_REVOLVER_SCHOFIELD` (Schofield Revolver) | gunpowder×5, shell×5 | - | $10 | 100% |

## ยา (2 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `herbal_medicine` | herbal×5, water×2 | - | $0 | 100% |
| `bandage` | herbal_medicine×2, specialherb×5, water×2 | - | $0 | 100% |

## อาหาร (3 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `bread` | corn×5 | - | $0 | 100% |
| `consumable_chickenpie` | raw_meat×2, salt×2 | - | $0 | 100% |
| `consumable_chocolatecake` | Black_Berry×2, blueberry×2, water×2 | - | $0 | 100% |

## การตีบัตรแต่งตัว (1 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `leatherpurify` | animal_skin×20 | - | $500 | 15% |

## เหมืองแร่ (4 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `tin_ore` | tin_ore_scrap×10 | - | $0 | 100% |
| `silvermineral` | silver_ore_scrap×10 | - | $0 | 100% |
| `copper_ore` | copper_ore_scrap×10 | - | $0 | 100% |
| `gold` | gold_ore_scrap×20 | - | $0 | 100% |

## วัสดุก่อสร้าง (3 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `plywood` | bark×10 | - | $0 | 100% |
| `plank` | sapwood×10 | - | $0 | 100% |
| `hardwood` | heartwood×10 | - | $0 | 100% |

## ชนเผ่า (2 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `tribal_bow` | hardwood×30, copper_ore×30, silver_coin×10, coffin_wood×10, small_bow×1 | - | $0 | 50% |
| `fire_arrow` | arrow×5, fire×2 | - | $0 | 50% |

## โต๊ะคราฟทั่วไป (4 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `misc_toolbox` (กล่องเครื่องมือ) | mat_iron×5, mat_copper×5, met_wood_planks×5 | - | $0 | 80% |
| `misc_trainbomb` (ระเบิดลากสาย) | mat_nitrate×10, mat_sulfur×10, mat_coal×10, met_resin×10 | - | $0 | 35% |
| `aed` (กล่องปฐมพยาบาล) | job_cotton×5, job_mushroom×5, job_Yarrow×5, met_resin×5, met_bark×5 | - | $0 | 30% |
| `job_animalfood` (อาหารสัตว์) | job_corn×5, job_carrot×5 | - | $0 | 100% |

## อาวุธ Tier 1 (15 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `part_mauser_frame` (Mauser Frame) | loot_necklace×7, loot_ring×10, loot_watch×6, mat_diamond×5, mat_iron×10, misc_toolbox×1 | - | $0 | 60% |
| `part_mauser_barrel` (Mauser Barrel) | loot_silver_tooth×6, loot_ring×7, loot_chinese_coin×5, mat_ruby×5, mat_copper×10, misc_toolbox×1 | - | $0 | 70% |
| `part_mauser_stock` (Mauser Stock) | loot_necklace×5, loot_earring×7, loot_chinese_coin×8, mat_emerald×5, mat_stone×10, met_wood_planks×10, misc_toolbox×1 | - | $0 | 60% |
| `part_mauser_molds` (Mauser Molds) | blueprint_low×5 | - | $0 | 60% |
| `weapon_mauser_pistol` (Mauser Pistol) | part_mauser_frame×1, part_mauser_barrel×1, part_mauser_stock×1, part_mauser_molds×1, misc_toolbox×1 | - | $0 | 100% |
| `part_schofield_frame` (Schofield Frame) | loot_chinese_coin×6, loot_ring×5, loot_earring×10, mat_diamond×5, mat_copper×10, misc_toolbox×1 | - | $0 | 60% |
| `part_schofield_barrel` (Schofield Barrel) | loot_necklace×10, loot_watch×7, loot_ring×6, mat_ruby×5, mat_coal×10, misc_toolbox×1 | - | $0 | 70% |
| `part_schofield_stock` (Schofield Stock) | loot_chinese_coin×9, loot_silver_tooth×6, loot_brooch×7, mat_emerald×5, mat_stone×10, met_wood_planks×10, misc_toolbox×1 | - | $0 | 60% |
| `part_schofield_molds` (Schofield Molds) | blueprint_low×5 | - | $0 | 60% |
| `weapon_schofield_revolver` (Schofield Revolver) | part_schofield_frame×1, part_schofield_barrel×1, part_schofield_stock×1, part_schofield_molds×1, misc_toolbox×1 | - | $0 | 100% |
| `part_carbine_frame` (Carbine Frame) | loot_watch×10, loot_necklace×8, loot_earring×9, mat_diamond×5, mat_iron×10, misc_toolbox×1 | - | $0 | 60% |
| `part_carbine_barrel` (Carbine Barrel) | loot_chinese_coin×8, loot_brooch×6, loot_ring×6, loot_silver_tooth×5, mat_ruby×5, mat_stone×10, misc_toolbox×1 | - | $0 | 70% |
| `part_carbine_stock` (Carbine Stock) | loot_necklace×5, loot_silver_tooth×9, loot_brooch×7, mat_emerald×5, mat_copper×10, met_wood_planks×10, misc_toolbox×1 | - | $0 | 60% |
| `part_carbine_molds` (Carbine Molds) | blueprint_low×8 | - | $0 | 60% |
| `weapon_carbine_repeater` (Carbine Repeater) | part_carbine_frame×1, part_carbine_barrel×1, part_carbine_stock×1, part_carbine_molds×1, misc_toolbox×1 | - | $0 | 100% |

## อาวุธ Tier 2 (14 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `part_axe_head` (Axe Head) | loot_necklace×10, loot_chinese_coin×8, loot_silver_tooth×6, mat_diamond×10, mat_iron×10, misc_toolbox×2 | - | $0 | 30% |
| `part_rivet` (Rivet (Hunter Hatchet)) | loot_watch×8, loot_brooch×9, loot_gold_tooth×8, mat_ruby×10, mat_copper×10, misc_toolbox×2 | - | $0 | 40% |
| `part_axe_handle` (Axe Handle) | loot_silver_tooth×5, loot_ring×6, loot_silver_coin×10, mat_emerald×10, mat_stone×10, met_wood_planks×10, misc_toolbox×2 | - | $0 | 30% |
| `part_hunter_hatchet_molds` (Hunter Hatchet Molds) | blueprint_low×8 | - | $0 | 40% |
| `weapon_hunter_hatchet` (Hunter Hatchet) | part_axe_head×1, part_rivet×1, part_axe_handle×1, part_hunter_hatchet_molds×1, misc_toolbox×1 | - | $0 | 100% |
| `part_arrowhead` (Arrowhead) | mat_iron×5, mat_copper×5, mat_stone×5 | - | $0 | 80% |
| `part_arrow_shaft` (Arrow Shaft) | mat_iron×5, met_wood_sharp×5, met_wood_planks×5 | - | $0 | 80% |
| `part_igniter_arrow` (Igniter arrow) | met_bark×5, met_resin×5 | - | $0 | 80% |
| `weapon_fire_arrow` (Fire Arrow (ธนูไฟ)) | part_arrowhead×1, part_arrow_shaft×1, part_igniter_arrow×1 | - | $0 | 100% |
| `part_henry_frame` (Henry Frame) | loot_brooch×6, loot_ring×10, loot_silver_tooth×9, mat_diamond×7, mat_copper×10, misc_toolbox×2 | - | $0 | 30% |
| `part_henry_barrel` (Henry Barrel) | loot_silver_coin×9, loot_chinese_coin×4, loot_watch×8, mat_ruby×8, mat_iron×10, misc_toolbox×2 | - | $0 | 30% |
| `part_henry_stock` (Henry Stock) | loot_ring×8, loot_earring×10, loot_necklace×5, mat_emerald×8, mat_stone×10, met_wood_planks×10, misc_toolbox×2 | - | $0 | 30% |
| `part_henry_molds` (Henry Molds) | blueprint_low×10 | - | $0 | 30% |
| `weapon_henry_repeater` (Litchfield Repeater Henry) | part_henry_frame×1, part_henry_barrel×1, part_henry_stock×1, part_henry_molds×1, misc_toolbox×2 | - | $0 | 100% |

## อาวุธ Tier 3 (15 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `part_bow_limb` (Bow Limb) | loot_watch×8, loot_silver_tooth×10, loot_necklace×6, mat_diamond×4, mat_iron×10, met_wood_sharp×10, misc_toolbox×3 | - | $0 | 30% |
| `part_bow_arm` (Bow Arm) | loot_hairpin×5, loot_chinese_coin×8, loot_gold_tooth×5, mat_ruby×5, mat_copper×10, misc_toolbox×3 | - | $0 | 35% |
| `part_bowstring` (Bowstring) | bear_hide×10, bear_claw×10, mat_emerald×6, met_stick×10, hide_medium×10, hide_high×10, misc_toolbox×3 | - | $0 | 30% |
| `part_bow_molds` (Bow Molds) | blueprint_low×8, blueprint_medium×6 | - | $0 | 30% |
| `weapon_bow_large` (Bow (ธนูใหญ่)) | part_bow_limb×1, part_bow_arm×1, part_bowstring×1, part_bow_molds×1, misc_toolbox×3 | - | $0 | 100% |
| `part_semi_pistol_frame` (Semi-Pistol Frame) | loot_brooch×10, loot_earring×8, loot_gold_tooth×8, mat_diamond×6, mat_copper×10, misc_toolbox×3 | - | $0 | 30% |
| `part_semi_pistol_barrel` (Semi-Pistol Barrel) | loot_ring×7, loot_silver_tooth×8, loot_silver_coin×5, mat_ruby×6, mat_iron×10, misc_toolbox×3 | - | $0 | 35% |
| `part_semi_pistol_stock` (Semi-Pistol Stock) | loot_watch×6, loot_hairpin×7, loot_necklace×5, mat_emerald×6, mat_stone×10, met_wood_planks×10, misc_toolbox×3 | - | $0 | 30% |
| `part_semi_pistol_molds` (Semi-Pistol Molds) | blueprint_low×9, blueprint_medium×7 | - | $0 | 40% |
| `weapon_semi_auto_pistol` (Semi-Automatic Pistol) | part_semi_pistol_frame×1, part_semi_pistol_barrel×1, part_semi_pistol_stock×1, part_semi_pistol_molds×1, misc_toolbox×3 | - | $0 | 100% |
| `part_winchester_frame` (Winchester Frame) | loot_hairpin×8, loot_silver_coin×9, loot_silver_tooth×10, mat_diamond×8, mat_copper×10, misc_toolbox×3 | - | $0 | 30% |
| `part_winchester_barrel` (Winchester Barrel) | loot_necklace×10, loot_watch×9, loot_gold_tooth×9, mat_ruby×5, mat_iron×10, misc_toolbox×3 | - | $0 | 30% |
| `part_winchester_stock` (Winchester Stock) | loot_chinese_coin×5, loot_earring×8, loot_silver_tooth×8, mat_emerald×6, mat_stone×10, met_wood_planks×10, misc_toolbox×3 | - | $0 | 30% |
| `part_winchester_molds` (Winchester Molds) | blueprint_low×10, blueprint_medium×8 | - | $0 | 40% |
| `weapon_winchester_repeater` (Lancaster Repeater Winchester) | part_winchester_frame×1, part_winchester_barrel×1, part_winchester_stock×1, part_winchester_molds×1, misc_toolbox×3 | - | $0 | 100% |

## อาวุธ Tier 4 (15 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `part_navy_frame` (Navy Frame) | loot_necklace×9, loot_earring×8, loot_hairpin×10, loot_silver_tooth×10, mat_diamond×7, mat_iron×10, misc_toolbox×4 | - | $0 | 20% |
| `part_navy_barrel` (Navy Barrel) | loot_ring×10, loot_watch×6, loot_gold_tooth×8, loot_chinese_coin×8, mat_ruby×7, mat_copper×10, misc_toolbox×4 | - | $0 | 30% |
| `part_navy_stock` (Navy Stock) | loot_silver_coin×9, loot_brooch×10, loot_earring×7, mat_emerald×7, mat_stone×10, met_wood_planks×10, misc_toolbox×4 | - | $0 | 25% |
| `part_navy_molds` (Navy Molds) | blueprint_low×10, blueprint_medium×8 | - | $0 | 40% |
| `weapon_navy_revolver` (Navy Revolver) | part_navy_frame×1, part_navy_barrel×1, part_navy_stock×1, part_navy_molds×1, misc_toolbox×4 | - | $0 | 100% |
| `part_double_barrel_frame` (Double Barrel Frame) | loot_gold_tooth×10, loot_silver_tooth×9, loot_earring×10, loot_watch×5, mat_diamond×8, mat_iron×10, misc_toolbox×4 | - | $0 | 25% |
| `part_double_barrel_barrel` (Double Barrel Barrel) | loot_necklace×7, loot_silver_coin×10, loot_brooch×10, loot_ring×6, mat_ruby×8, mat_copper×10, misc_toolbox×4 | - | $0 | 20% |
| `part_double_barrel_stock` (Double Barrel Stock) | loot_chinese_coin×9, loot_brooch×8, loot_hairpin×10, loot_earring×7, mat_emerald×8, mat_stone×10, met_wood_planks×10, misc_toolbox×4 | - | $0 | 25% |
| `part_double_barrel_molds` (Double Barrel Molds) | blueprint_low×10, blueprint_medium×9 | - | $0 | 40% |
| `weapon_double_barrel` (Double Barrel) | part_double_barrel_frame×1, part_double_barrel_barrel×1, part_double_barrel_stock×1, part_double_barrel_molds×1, misc_toolbox×4 | - | $0 | 100% |
| `part_machete_blade` (Machete Blade) | loot_necklace×8, loot_ring×5, loot_watch×7, loot_gold_tooth×6, mat_diamond×6, mat_iron×10, misc_toolbox×4 | - | $0 | 25% |
| `part_machete_tang` (Machete Tang) | loot_earring×7, loot_silver_tooth×9, loot_silver_coin×8, loot_hairpin×6, mat_ruby×5, mat_copper×10, misc_toolbox×4 | - | $0 | 30% |
| `part_machete_stock` (Machete Stock) | loot_brooch×8, loot_chinese_coin×7, loot_earring×10, mat_emerald×6, mat_stone×10, met_wood_planks×10, misc_toolbox×4 | - | $0 | 35% |
| `part_machete_molds` (Machete Molds) | blueprint_low×5, blueprint_medium×7 | - | $0 | 50% |
| `weapon_machete` (Machete) | part_machete_blade×1, part_machete_tang×1, part_machete_stock×1, part_machete_molds×1, misc_toolbox×4 | - | $0 | 100% |

## อาวุธ Tier 5 (15 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `part_springfield_frame` (Springfield Rifle Frame) | loot_nail×7, loot_gold_tooth×10, loot_earring×10, loot_brooch×8, mat_diamond×7, mat_iron×10, misc_toolbox×5 | - | $0 | 20% |
| `part_springfield_barrel` (Springfield Rifle Barrel) | loot_nail×5, loot_hairpin×10, loot_watch×7, loot_necklace×10, mat_ruby×7, mat_copper×10, misc_toolbox×5 | - | $0 | 20% |
| `part_springfield_stock` (Springfield Rifle Stock) | loot_silver_coin×7, loot_silver_tooth×8, loot_gold_tooth×5, loot_ring×7, mat_emerald×7, rock_salt×10, met_wood_planks×10, misc_toolbox×5 | - | $0 | 25% |
| `part_springfield_molds` (Springfield Rifle Molds) | blueprint_low×10, blueprint_medium×8, blueprint_high×5 | - | $0 | 30% |
| `weapon_springfield_rifle` (Springfield Rifle) | part_springfield_frame×1, part_springfield_barrel×1, part_springfield_stock×1, part_springfield_molds×1, misc_toolbox×5 | - | $0 | 100% |
| `part_volcanic_frame` (Volcanic Frame) | loot_ring×4, loot_silver_tooth×5, loot_earring×6, loot_chinese_coin×3, mat_diamond×7, mat_iron×10, misc_toolbox×5 | - | $0 | 30% |
| `part_volcanic_barrel` (Volcanic Barrel) | loot_nail×6, loot_brooch×5, loot_silver_tooth×8, loot_necklace×3, mat_ruby×7, mat_copper×10, misc_toolbox×5 | - | $0 | 30% |
| `part_volcanic_stock` (Volcanic Stock) | loot_nail×6, loot_hairpin×8, loot_brooch×4, loot_silver_coin×5, mat_emerald×7, mat_stone×10, met_wood_planks×10, misc_toolbox×5 | - | $0 | 30% |
| `part_volcanic_molds` (Volcanic Molds) | blueprint_low×5, blueprint_medium×6, blueprint_high×4 | - | $0 | 40% |
| `weapon_volcanic_pistol` (Volcanic Pistol) | part_volcanic_frame×1, part_volcanic_barrel×1, part_volcanic_stock×1, part_volcanic_molds×1, misc_toolbox×5 | - | $0 | 100% |
| `part_lemat_frame` (LeMat Revolver Frame) | loot_ring×7, loot_silver_tooth×5, loot_earring×6, loot_chinese_coin×3, mat_diamond×7, mat_iron×10, misc_toolbox×5 | - | $0 | 30% |
| `part_lemat_barrel` (LeMat Revolver Barrel) | loot_nail×6, loot_brooch×5, loot_silver_tooth×5, loot_necklace×3, mat_ruby×7, mat_copper×10, misc_toolbox×5 | - | $0 | 20% |
| `part_lemat_stock` (LeMat Revolver Stock) | loot_nail×6, loot_hairpin×5, loot_brooch×4, loot_silver_coin×5, mat_emerald×7, mat_stone×10, met_wood_planks×10, misc_toolbox×5 | - | $0 | 30% |
| `part_lemat_molds` (LeMat Revolver Molds) | blueprint_low×5, blueprint_medium×8, blueprint_high×6 | - | $0 | 40% |
| `weapon_lemat_revolver` (LeMat Revolver) | part_lemat_frame×1, part_lemat_barrel×1, part_lemat_stock×1, part_lemat_molds×1, misc_toolbox×5 | - | $0 | 100% |

## อาวุธ Tier 6 (10 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `part_tomahawk_head` (Tomahawk Head) | loot_nail×10, loot_hairpin×8, loot_silver_tooth×6, loot_gold_tooth×7, loot_ring×9, mat_diamond×5, mat_copper×10, misc_toolbox×6 | - | $0 | 20% |
| `part_rivet` (Rivet (Tomahawk)) | loot_nail×10, loot_necklace×5, loot_watch×8, loot_silver_coin×8, loot_brooch×7, mat_ruby×5, mat_iron×10, misc_toolbox×6 | - | $0 | 25% |
| `part_tomahawk_stock` (Tomahawk Stock) | loot_nail×10, loot_chinese_coin×7, loot_gold_tooth×5, loot_silver_coin×5, mat_emerald×7, mat_stone×10, met_wood_planks×10, misc_toolbox×6 | - | $0 | 20% |
| `part_tomahawk_molds` (Tomahawk Molds) | blueprint_low×8, blueprint_medium×6, blueprint_high×8 | - | $0 | 30% |
| `weapon_tomahawk` (Tomahawk) | part_tomahawk_head×1, part_rivet×1, part_tomahawk_stock×1, part_tomahawk_molds×1, misc_toolbox×6 | - | $0 | 100% |
| `part_repeating_frame` (RepeatingFrame) | loot_nail×10, loot_necklace×6, loot_ring×5, loot_brooch×6, mat_diamond×7, mat_iron×10, misc_toolbox×6 | - | $0 | 20% |
| `part_repeating_barrel` (Repeating Barrel) | loot_nail×10, loot_earring×7, loot_gold_tooth×8, loot_silver_tooth×5, mat_ruby×7, mat_copper×10, misc_toolbox×6 | - | $0 | 20% |
| `part_repeating_stock` (Repeating Stock) | loot_nail×10, loot_hairpin×7, loot_silver_coin×5, loot_earring×5, mat_emerald×5, mat_stone×10, met_wood_planks×10, misc_toolbox×6 | - | $0 | 20% |
| `part_repeating_molds` (Repeating Molds) | blueprint_low×7, blueprint_medium×9, blueprint_high×9 | - | $0 | 25% |
| `weapon_repeating_shotgun` (Repeating Shotgun) | part_repeating_frame×1, part_repeating_barrel×1, part_repeating_stock×1, part_repeating_molds×1, misc_toolbox×6 | - | $0 | 100% |

## อาวุธ Tier 7 (10 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `part_m1899_frame` (M1899 Frame) | loot_bangle×10, loot_gold_tooth×5, loot_silver_coin×7, loot_hairpin×6, mat_diamond×7, mat_iron×10, misc_toolbox×7 | - | $0 | 20% |
| `part_m1899_barrel` (M1899 Barrel) | loot_bangle×10, loot_nail×7, loot_necklace×7, loot_ring×8, mat_ruby×7, mat_copper×10, misc_toolbox×7 | - | $0 | 20% |
| `part_m1899_stock` (M1899 Stock) | loot_bangle×10, loot_watch×7, loot_chinese_coin×9, loot_earring×5, mat_emerald×7, mat_stone×10, met_wood_planks×10, misc_toolbox×7 | - | $0 | 20% |
| `part_m1899_molds` (M1899 Molds) | blueprint_low×5, blueprint_medium×9, blueprint_high×7, blueprint_ultra×3 | - | $0 | 30% |
| `weapon_m1899_pistol` (M1899 Pistol) | part_m1899_frame×1, part_m1899_barrel×1, part_m1899_stock×1, part_m1899_molds×1, misc_toolbox×7 | - | $0 | 100% |
| `part_evans_frame` (Evans Repeater Frame) | loot_bangle×10, loot_earring×6, loot_gold_tooth×5, loot_ring×8, mat_diamond×8, mat_iron×10, misc_toolbox×7 | - | $0 | 20% |
| `part_evans_barrel` (Evans Repeater Barrel) | loot_bangle×10, loot_necklace×9, loot_watch×8, loot_silver_coin×7, mat_ruby×8, mat_copper×10, misc_toolbox×7 | - | $0 | 20% |
| `part_evans_stock` (Evans Repeater Stock) | loot_bangle×10, loot_hairpin×8, loot_nail×9, loot_silver_tooth×6, mat_emerald×8, mat_stone×10, met_wood_planks×10, misc_toolbox×7 | - | $0 | 20% |
| `part_evans_molds` (Evans Repeater Molds) | blueprint_low×8, blueprint_medium×5, blueprint_high×7, blueprint_ultra×5 | - | $0 | 25% |
| `weapon_evans_repeater` (Evans Repeater) | part_evans_frame×1, part_evans_barrel×1, part_evans_stock×1, part_evans_molds×1, misc_toolbox×7 | - | $0 | 100% |

## อาวุธ Tier 8 (8 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `part_bolt_action_frame` (Bolt Action Rifle Frame) | loot_bangle×10, loot_brooch×7, loot_silver_tooth×8, loot_hairpin×8, mat_diamond×9, mat_iron×10, misc_toolbox×8 | - | $0 | 20% |
| `part_bolt_action_barrel` (Bolt Action Rifle Barrel) | loot_bangle×9, loot_gold_tooth×9, loot_watch×7, loot_chinese_coin×8, mat_ruby×9, mat_copper×10, misc_toolbox×8 | - | $0 | 15% |
| `part_bolt_action_stock` (Bolt Action Rifle Stock) | loot_bangle×7, loot_nail×10, loot_silver_coin×10, loot_earring×8, mat_emerald×7, mat_stone×10, met_wood_planks×10, misc_toolbox×8 | - | $0 | 20% |
| `part_bolt_action_molds` (Bolt Action Rifle Molds) | blueprint_low×9, blueprint_medium×9, blueprint_high×7, blueprint_ultra×8 | - | $0 | 20% |
| `weapon_bolt_action_rifle` (Bolt Action Rifle) | part_bolt_action_frame×1, part_bolt_action_barrel×1, part_bolt_action_stock×1, part_bolt_action_molds×1, misc_toolbox×8 | - | $0 | 100% |
| `part_bottle` (Bottle) | loot_gold_tooth×6, loot_brooch×8, loot_nail×5, mat_diamond×9, mat_emerald×8, mat_ruby×9, mat_iron×10 | - | $0 | 30% |
| `part_wick` (Wick) | loot_bangle×7, met_resin×10, mat_coal×10, mat_nitrate×10, mat_sulfur×10 | - | $0 | 30% |
| `weapon_fire_bottle` (Fire Bottle) | part_bottle×1, part_wick×1 | - | $0 | 100% |

## อาวุธ Tier 9 (10 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `part_rolling_block_frame` (Rolling Block Rifle Frame) | loot_bracelet×10, loot_mirror×10, loot_bangle×7, loot_gold_tooth×8, loot_earring×9, mat_diamond×10, mat_copper×10, misc_toolbox×9 | - | $0 | 15% |
| `part_rolling_block_barrel` (Rolling Block Rifle Barrel) | loot_bracelet×10, loot_mirror×9, loot_bangle×10, loot_nail×8, loot_silver_tooth×7, mat_ruby×10, mat_iron×10, misc_toolbox×9 | - | $0 | 15% |
| `part_rolling_block_stock` (Rolling Block Rifle Stock) | loot_bracelet×10, loot_mirror×9, loot_bangle×7, loot_hairpin×9, loot_watch×8, mat_emerald×10, mat_stone×10, met_wood_planks×10, misc_toolbox×9 | - | $0 | 10% |
| `part_rolling_block_molds` (Rolling Block Rifle Molds) | blueprint_low×10, blueprint_medium×10, blueprint_high×8, blueprint_ultra×8, blueprint_rare×6 | - | $0 | 15% |
| `weapon_rolling_block_rifle` (Rolling Block Rifle) | part_rolling_block_frame×1, part_rolling_block_barrel×1, part_rolling_block_stock×1, part_rolling_block_molds×1, misc_toolbox×9 | - | $0 | 100% |
| `part_pump_action_frame` (Pump-Action Shotgun Frame) | loot_bracelet×10, loot_mirror×10, loot_bangle×8, loot_earring×9, loot_brooch×7, mat_diamond×10, mat_copper×10, misc_toolbox×9 | - | $0 | 10% |
| `part_pump_action_barrel` (Pump-Action Shotgun Barrel) | loot_bracelet×10, loot_mirror×8, loot_bangle×9, loot_hairpin×9, loot_ring×8, mat_ruby×10, mat_iron×10, misc_toolbox×9 | - | $0 | 15% |
| `part_pump_action_stock` (Pump-Action Shotgun Stock) | loot_bracelet×10, loot_mirror×9, loot_bangle×7, loot_nail×9, loot_gold_tooth×8, mat_emerald×10, mat_stone×10, met_wood_planks×10, misc_toolbox×9 | - | $0 | 15% |
| `part_pump_action_molds` (Pump-Action Shotgun Molds) | blueprint_low×10, blueprint_medium×10, blueprint_high×8, blueprint_ultra×9, blueprint_rare×8 | - | $0 | 15% |
| `weapon_pump_action_shotgun` (Pump-Action Shotgun) | part_pump_action_frame×1, part_pump_action_barrel×1, part_pump_action_stock×1, part_pump_action_molds×1, misc_toolbox×9 | - | $0 | 100% |

## อาวุธ Tier 10 (10 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `part_sawedoff_frame` (Sawed-Off Shotgun Frame) | loot_bracelet×10, loot_mirror×10, loot_bangle×10, loot_nail×10, loot_hairpin×10, mat_diamond×10, mat_copper×10, misc_toolbox×10 | - | $0 | 10% |
| `part_sawedoff_barrel` (Sawed-Off Shotgun Barrel) | loot_bracelet×10, loot_mirror×10, loot_bangle×10, loot_earring×10, loot_brooch×10, mat_ruby×10, mat_iron×10, misc_toolbox×10 | - | $0 | 15% |
| `part_sawedoff_stock` (Sawed-Off Shotgun Stock) | loot_bracelet×10, loot_mirror×10, loot_bangle×10, loot_gold_tooth×10, loot_silver_tooth×10, mat_emerald×10, mat_stone×10, met_wood_planks×10, misc_toolbox×10 | - | $0 | 10% |
| `part_sawedoff_molds` (Sawed-Off Shotgun Molds) | blueprint_low×10, blueprint_medium×10, blueprint_high×10, blueprint_ultra×10, blueprint_rare×10 | - | $0 | 10% |
| `weapon_sawedoff_shotgun` (Sawed-Off Shotgun) | part_sawedoff_frame×1, part_sawedoff_barrel×1, part_sawedoff_stock×1, part_sawedoff_molds×1, misc_toolbox×10 | - | $0 | 100% |
| `part_semi_auto_shotgun_frame` (Semi-Auto Shotgun Frame) | loot_bracelet×10, loot_mirror×10, loot_bangle×10, loot_necklace×10, loot_silver_coin×10, mat_diamond×10, mat_iron×10, misc_toolbox×10 | - | $0 | 15% |
| `part_semi_auto_shotgun_barrel` (Semi-Auto Shotgun Barrel) | loot_bracelet×10, loot_mirror×10, loot_bangle×10, loot_silver_tooth×10, loot_hairpin×10, mat_ruby×10, mat_copper×10, misc_toolbox×10 | - | $0 | 10% |
| `part_semi_auto_shotgun_stock` (Semi-Auto Shotgun Stock) | loot_bracelet×10, loot_mirror×10, loot_bangle×10, loot_nail×10, loot_earring×10, mat_emerald×10, mat_stone×10, met_wood_planks×10, misc_toolbox×10 | - | $0 | 10% |
| `part_semi_auto_shotgun_molds` (Semi-Auto Shotgun Molds) | blueprint_low×10, blueprint_medium×10, blueprint_high×10, blueprint_ultra×10, blueprint_rare×10 | - | $0 | 10% |
| `weapon_semi_auto_shotgun` (Semi-Auto Shotgun) | part_semi_auto_shotgun_frame×1, part_semi_auto_shotgun_barrel×1, part_semi_auto_shotgun_stock×1, part_semi_auto_shotgun_molds×1, misc_toolbox×10 | - | $0 | 100% |

## โต๊ะทำอาหาร Valentine (4 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `food_sugarcane_juice` (น้ำอ้อย) | job_sugarcane×5, water×1 | - | $0 | 100% |
| `food_oxtail_soup` (ซุปหางวัว) | meat_large×2, job_Yarrow×1, job_corn×2, job_carrot×3 | - | $0 | 100% |
| `food_braised_ribs` (ตุ๋นซี่โครง) | meat_medium×2, job_corn×2, job_carrot×3 | - | $0 | 100% |
| `food_taco` (ทาโก้) | meat_small×3, job_carrot×4 | - | $0 | 100% |

## โต๊ะทำอาหาร Rhodes (4 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `food_orange_juice` (น้ำส้ม) | job_orange×5, water×1 | - | $0 | 100% |
| `food_beef_stew` (สตูเนื้อ) | meat_large×2, job_tobacco_plant×1, job_barley×2, job_cotton×3 | - | $0 | 100% |
| `food_salted_meat_stew` (เนื้อตุ๋นเกลือ) | meat_medium×2, job_barley×2, job_cotton×3 | - | $0 | 100% |
| `food_pasta_sauce` (พาสต้าซอส) | meat_small×3, job_barley×4 | - | $0 | 100% |

## โต๊ะทำอาหาร Annesburg (4 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `food_berry_juice` (น้ำเบอรี่) | job_berry×5, water×1 | - | $0 | 100% |
| `food_herb_roasted_meat` (เนื้อย่างสมุนไพร) | meat_large×2, job_mushroom×1, job_Ginseng×2, job_opium×3 | - | $0 | 100% |
| `food_mushroom_rib_soup` (ต้มซี่โครงเห็ด) | meat_medium×2, job_Ginseng×2, job_opium×3 | - | $0 | 100% |
| `food_spaghetti` (สปาเก็ตตี้) | meat_small×3, job_Ginseng×4 | - | $0 | 100% |

## เหลาไม้ (1 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `met_wood_sharp` (แท่งไม้เหลา) | met_stick×10 | - | $0 | 100% |

## ทำไม้แผ่น (1 สูตร)

| ไอเทมที่คราฟได้ | วัตถุดิบ (blueprint) | เครื่องมือที่ต้องมี | ค่าเงิน | โอกาสสำเร็จ |
|---|---|---|---|---|
| `met_wood_planks` (แผ่นไม้) | met_log×5 | - | $0 | 100% |

---

> เทียบกับ [[Alljob]] / [[Alleconomic]]: บางสูตรในหมวด "เหลาไม้" และ "ทำไม้แผ่น" ใช้วัตถุดิบที่ได้จากงานตัดไม้ (`met_log` ฯลฯ) โดยตรง — แปรรูปแล้วขายได้ราคาสูงกว่าขายไม้ดิบใน MJ-Economy ถือเป็นห่วงโซ่ workflow เดียวกัน (ตัดไม้ → คราฟ → ขาย)

> **ข้อจำกัด:** ตัวเลขวัตถุดิบ/ค่าเงิน/% สำเร็จ ดึงตรงจาก `config_sv.lua` ไม่ได้ตรวจ logic จริงใน `server/server.lua` ว่ามีเงื่อนไขเพิ่มเติม (เช่น job restriction, ระดับ skill) ที่ config ไม่ได้บอกไว้ตรงๆ หรือไม่ — บางไอเทมมีสูตรทางเลือกมากกว่า 1 แบบ ตารางนี้แสดงแค่สูตรแรกเท่านั้น
