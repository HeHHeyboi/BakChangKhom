# ASSET_NAMING.md — รายชื่อไฟล์ asset ฉบับอ้างอิงเดียว
> ตรวจไฟล์จริง 28 ก.ย. 2569 · **ตั้งชื่อไฟล์ตามเอกสารนี้เท่านั้น**
> ขนาดในตารางคือ **ขนาด canvas ของไฟล์** ไม่ใช่ขนาดที่แสดงบนจอ — ตัวเลขใน `UI_MOCKUP.md` เป็นตำแหน่ง/ขนาดตอนวางในฉาก อย่าเอาไปตั้งขนาดไฟล์
> สถานะ: ✅ มีแล้วใช้ได้ · 🟠 มีไฟล์แต่ภาพในไฟล์ผิด ต้องทำใหม่ · 🔴 ยังไม่มี

> **แก้สเปก 28 ก.ย. 2569** — `ram_tray` เปลี่ยนจาก 900×220 เป็น **580×320** และ `ui_tool_card` จาก 320×200 เป็น **290×380** เพราะภาพที่ gen มาจริงเป็นถาด 5×2 ช่อง (สัดส่วน 1.8:1) และการ์ดแนวตั้ง ไม่ใช่ถาดยาวแบนกับการ์ดแนวนอนอย่างที่สเปกเดิมสมมติไว้

## กฎตั้งชื่อ
1. ASCII `snake_case` ห้ามเว้นวรรค ห้ามภาษาไทย ห้ามตัวพิมพ์ใหญ่
2. ขึ้นต้นด้วยคำนำหน้าของโฟลเดอร์ — `ram_` · `mb_` · `gpu_` · `fp_` · `bios_` · `tool_` · `ui_` · `wb_` · `part_` · `tut_` · `bg_` · `end_`
3. state ของชิ้นเดียวกันลงท้าย `_normal` / `_hover` / `_press` / `_disabled` และต้องมี canvas เท่ากันเป๊ะ
4. คู่เปรียบเทียบ (สะอาด-สกปรก · เปิด-ปิด · ล็อก-ปลดล็อก) ต้อง canvas เท่ากัน ไม่งั้นภาพกระโดดตอนสลับ
5. พื้นโปร่ง = `.png` · ภาพเต็มจอ = `.jpg`

## `Assets/Tutorial/BasicStart/`
| ไฟล์ | canvas | สถานะ | ใช้ที่ |
|---|---|---|---|
| `tut_start_01.png` | 1152×648 | 🔴 ยังไม่มี | สไลด์สอนเล่นพื้นฐาน |
| `tut_start_02.png` | 1152×648 | 🔴 ยังไม่มี | สไลด์สอนเล่นพื้นฐาน |
| `tut_start_03.png` | 1152×648 | 🔴 ยังไม่มี | สไลด์สอนเล่นพื้นฐาน |

## `Assets/Tutorial/RamCleaning/`
| ไฟล์ | canvas | สถานะ | ใช้ที่ |
|---|---|---|---|
| `tut_ram_01.png` | 1152×648 | 🔴 ยังไม่มี | สไลด์สอนขัดแรม |
| `tut_ram_02.png` | 1152×648 | 🔴 ยังไม่มี | สไลด์สอนขัดแรม |
| `tut_ram_03.png` | 1152×648 | 🔴 ยังไม่มี | สไลด์สอนขัดแรม |
| `tut_ram_04.png` | 1152×648 | 🔴 ยังไม่มี | สไลด์สอนขัดแรม |

## `Assets/MiniGame/PartRam/`
| ไฟล์ | canvas | สถานะ | ใช้ที่ |
|---|---|---|---|
| `ram_eraser.png` | 200×200 | ✅ | Phase 4 ระบบเลือกอุปกรณ์ |
| `ram_tool_brush.png` | 200×200 | ✅ | Phase 4 ระบบเลือกอุปกรณ์ |
| `ram_tool_blower.png` | 200×200 | ✅ | Phase 4 ระบบเลือกอุปกรณ์ |
| `ram_tool_cloth.png` | 200×200 | ✅ | Phase 4 ระบบเลือกอุปกรณ์ |
| `ram_tool_ipa_swab.png` | 200×200 | ✅ | Phase 4 ระบบเลือกอุปกรณ์ |
| `ram_tool_eraser_red.png` | 200×200 | ✅ | Phase 4 ระบบเลือกอุปกรณ์ |
| `ram_tool_sandpaper.png` | 200×200 | ✅ | Phase 4 ระบบเลือกอุปกรณ์ |
| `ram_tool_wet_cloth.png` | 200×200 | ✅ | Phase 4 ระบบเลือกอุปกรณ์ |
| `ram_tool_hairdryer.png` | 200×200 | ✅ | Phase 4 ระบบเลือกอุปกรณ์ |
| `ram_tool_vacuum.png` | 200×200 | ✅ | Phase 4 ระบบเลือกอุปกรณ์ |
| `ram_tray.png` | 580×320 | ✅ | ถาดและการ์ดคุณสมบัติ |
| `ui_tool_card.png` | 290×380 | ✅ | ถาดและการ์ดคุณสมบัติ |
| `ui_meter_pip_on.png` | 24×24 | ✅ | ถาดและการ์ดคุณสมบัติ |
| `ui_meter_pip_off.png` | 24×24 | ✅ | ถาดและการ์ดคุณสมบัติ |
| `ram_icon_moisture.png` | 48×48 | ✅ | ถาดและการ์ดคุณสมบัติ |
| `ram_icon_esd.png` | 48×48 | ✅ | ถาดและการ์ดคุณสมบัติ |
| `ram_icon_residue.png` | 48×48 | ✅ | ถาดและการ์ดคุณสมบัติ |
| `ram_icon_narrow.png` | 48×48 | ✅ | ถาดและการ์ดคุณสมบัติ |
| `ram_dirty.png` | 600×214 | ✅ | แรม 3 สถานะ + กล่องค้นหา |
| `ram_better.png` | 600×214 | ✅ | แรม 3 สถานะ + กล่องค้นหา |
| `ram_clean.png` | 600×214 | ✅ | แรม 3 สถานะ + กล่องค้นหา |
| `ram_box_normal.png` | 256×256 | ✅ | แรม 3 สถานะ + กล่องค้นหา |
| `ram_box_hover.png` | 256×256 | ✅ | แรม 3 สถานะ + กล่องค้นหา |
| `ram_pc_front.png` | 700×800 | 🔴 ยังไม่มี | Phase 0 วินิจฉัย |
| `ram_screen_glitch.png` | 520×340 | 🔴 ยังไม่มี | Phase 0 วินิจฉัย |
| `ram_screen_normal.png` | 520×340 | 🔴 ยังไม่มี | Phase 0 วินิจฉัย |
| `ram_speaker_icon.png` | 120×120 | 🔴 ยังไม่มี | Phase 0 วินิจฉัย |
| `ram_case_dusty.png` | 640×640 | 🔴 ยังไม่มี | Phase 0 วินิจฉัย |
| `ram_clue_card.png` | 300×90 | 🔴 ยังไม่มี | Phase 0 วินิจฉัย |
| `ram_diagram_ram_role.png` | 500×300 | 🔴 ยังไม่มี | Phase 1 ภาพประกอบตอนปิ๊บสอน |
| `ram_diagram_gold_contact.png` | 500×300 | 🔴 ยังไม่มี | Phase 1 ภาพประกอบตอนปิ๊บสอน |
| `ram_diagram_dust_block.png` | 500×300 | 🔴 ยังไม่มี | Phase 1 ภาพประกอบตอนปิ๊บสอน |
| `ram_btn_shutdown.png` | 160×160 | 🔴 ยังไม่มี | Phase 2-3 ตัดไฟและถอด |
| `ram_plug_in.png` | 260×180 | 🔴 ยังไม่มี | Phase 2-3 ตัดไฟและถอด |
| `ram_plug_out.png` | 260×180 | 🔴 ยังไม่มี | Phase 2-3 ตัดไฟและถอด |
| `ram_hand_touch_case.png` | 300×300 | 🔴 ยังไม่มี | Phase 2-3 ตัดไฟและถอด |
| `ram_slot_empty.png` | 560×90 | 🔴 ยังไม่มี | Phase 2-3 ตัดไฟและถอด |
| `ram_clip_closed.png` | 70×120 | 🔴 ยังไม่มี | Phase 2-3 ตัดไฟและถอด |
| `ram_clip_open.png` | 70×120 | 🔴 ยังไม่มี | Phase 2-3 ตัดไฟและถอด |
| `ram_ghost.png` | 600×214 | 🔴 ยังไม่มี | Phase 5-6 ใส่กลับและเอฟเฟกต์ |
| `ram_dust_particle.png` | 32×32 | 🔴 ยังไม่มี | Phase 5-6 ใส่กลับและเอฟเฟกต์ |
| `ram_spark.png` | 200×200 | 🔴 ยังไม่มี | Phase 5-6 ใส่กลับและเอฟเฟกต์ |

## `Assets/MiniGame/PartCommon/`
| ไฟล์ | canvas | สถานะ | ใช้ที่ |
|---|---|---|---|
| `tool_screwdriver_flat.png` | 200×200 | ✅ | ToolBelt |
| `tool_hex_driver.png` | 200×200 | ✅ | ToolBelt |
| `tool_pliers.png` | 200×200 | ✅ | ToolBelt |
| `tool_esd_strap.png` | 200×200 | ✅ | ToolBelt |
| `tool_esd_mat.png` | 200×200 | ✅ | ToolBelt |
| `tool_flashlight.png` | 200×200 | ✅ | ToolBelt |
| `tool_multimeter.png` | 200×200 | ✅ | ToolBelt |
| `tool_psu_tester.png` | 200×200 | ✅ | ToolBelt |
| `tool_usb_installer.png` | 200×200 | ✅ | ToolBelt |
| `tool_thermal_paste.png` | 200×200 | ✅ | ToolBelt |
| `tool_cable_tie.png` | 200×200 | ✅ | ToolBelt |
| `wb_case_closed.png` | 700×820 | 🔴 ยังไม่มี | S2 Workbench + Normal Part |
| `wb_case_open.png` | 700×820 | 🔴 ยังไม่มี | S2 Workbench + Normal Part |
| `wb_parts_tray.png` | 900×260 | 🔴 ยังไม่มี | S2 Workbench + Normal Part |
| `wb_screw_cup.png` | 160×160 | 🔴 ยังไม่มี | S2 Workbench + Normal Part |
| `part_side_panel.png` | 600×700 | 🔴 ยังไม่มี | S2 Workbench + Normal Part |
| `part_psu.png` | 420×300 | 🔴 ยังไม่มี | S2 Workbench + Normal Part |
| `part_case_fan.png` | 300×300 | 🔴 ยังไม่มี | S2 Workbench + Normal Part |
| `part_cpu_cooler.png` | 350×350 | 🔴 ยังไม่มี | S2 Workbench + Normal Part |
| `part_storage_hdd.png` | 400×260 | 🔴 ยังไม่มี | S2 Workbench + Normal Part |
| `part_cmos_battery.png` | 120×120 | 🔴 ยังไม่มี | S2 Workbench + Normal Part |
| `part_cable_sata.png` | 400×120 | 🔴 ยังไม่มี | S2 Workbench + Normal Part |
| `part_dust_overlay.png` | 700×820 | 🔴 ยังไม่มี | S2 Workbench + Normal Part |

## `Assets/MiniGame/PartMainboard/`
| ไฟล์ | canvas | สถานะ | ใช้ที่ |
|---|---|---|---|
| `mb_mainboard_ghost.png` | 800×760 | 🔴 ยังไม่มี | Part Mainboard |
| `mb_cpu_wrong.png` | 180×180 | 🔴 ยังไม่มี | Part Mainboard |
| `mb_paste_dot_small.png` | 200×200 | 🔴 ยังไม่มี | Part Mainboard |
| `mb_paste_dot_ok.png` | 200×200 | 🔴 ยังไม่มี | Part Mainboard |
| `mb_paste_dot_large.png` | 200×200 | 🔴 ยังไม่มี | Part Mainboard |
| `mb_heatsink_dusty.png` | = mb_cooler.png | 🔴 ยังไม่มี | Part Mainboard |
| `mb_pins_bent.png` | = mb_socket_open.png | 🔴 ยังไม่มี | Part Mainboard |
| `mb_temp_gauge.png` | 300×300 | 🔴 ยังไม่มี | Part Mainboard |

## `Assets/MiniGame/PartGpu/`
| ไฟล์ | canvas | สถานะ | ใช้ที่ |
|---|---|---|---|
| `gpu_cable_cpu8.png` | = gpu_cable_pcie.png | 🔴 ยังไม่มี | Part GPU |
| `gpu_connector_zoom.png` | 500×300 | 🔴 ยังไม่มี | Part GPU |
| `gpu_card_dusty.png` | = gpu_card.png | 🔴 ยังไม่มี | Part GPU |
| `gpu_burn.png` | = gpu_card.png | 🔴 ยังไม่มี | Part GPU |

## `Assets/MiniGame/PartFrontPanel/`
| ไฟล์ | canvas | สถานะ | ใช้ที่ |
|---|---|---|---|
| `fp_pin_header_zoom.png` | 600×400 | 🔴 ยังไม่มี | Part Front Panel |
| `fp_pin_label_overlay.png` | 600×400 | 🔴 ยังไม่มี | Part Front Panel |
| `fp_flashlight_beam.png` | 400×400 | 🔴 ยังไม่มี | Part Front Panel |

## `Assets/MiniGame/PartBios/`
| ไฟล์ | canvas | สถานะ | ใช้ที่ |
|---|---|---|---|
| `bios_bottleneck_chart.png` | 600×400 | 🔴 ยังไม่มี | Part BIOS |
| `bios_drive_hdd.png` | 120×120 | 🔴 ยังไม่มี | Part BIOS |
| `bios_drive_ssd.png` | 120×120 | 🔴 ยังไม่มี | Part BIOS |
| `bios_drive_usb.png` | 120×120 | 🔴 ยังไม่มี | Part BIOS |
| `bios_btn_save.png` | 200×64 | 🔴 ยังไม่มี | Part BIOS |
| `bios_btn_discard.png` | 200×64 | 🔴 ยังไม่มี | Part BIOS |
| `bios_btn_default.png` | 200×64 | 🔴 ยังไม่มี | Part BIOS |
| `bios_windows_desktop.png` | 1152×648 | 🔴 ยังไม่มี | Part BIOS |

## `Assets/UI/`
| ไฟล์ | canvas | สถานะ | ใช้ที่ |
|---|---|---|---|
| `ui_btn_normal.png` | 320×96 | ✅ | UI ที่มีแล้ว |
| `ui_btn_hover.png` | 320×96 | ✅ | UI ที่มีแล้ว |
| `ui_btn_press.png` | 320×96 | ✅ | UI ที่มีแล้ว |
| `ui_btn_disabled.png` | 320×96 | ✅ | UI ที่มีแล้ว |
| `ui_dialog_box.png` | 1152×200 | ✅ | UI ที่มีแล้ว |
| `ui_name_plate.png` | 340×72 | ✅ | UI ที่มีแล้ว |
| `ui_quest_panel.png` | 420×300 | ✅ | UI ที่มีแล้ว |
| `ui_time_panel.png` | 360×80 | ✅ | UI ที่มีแล้ว |
| `ui_marker_caution.png` | 250×250 | ✅ | UI ที่มีแล้ว |
| `ui_icon_morning.png` | 64×64 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_icon_noon.png` | 64×64 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_icon_evening.png` | 64×64 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_icon_coin.png` | 64×64 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_icon_xp.png` | 64×64 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_rank_1.png` | 64×64 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_rank_2.png` | 64×64 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_rank_3.png` | 64×64 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_rank_4.png` | 64×64 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_rank_5.png` | 64×64 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_btn_close.png` | 96×96 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_btn_next.png` | 96×96 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_btn_prev.png` | 96×96 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_btn_map.png` | 128×128 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_marker_caution_hover.png` | 250×250 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_marker_caution_press.png` | 250×250 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_star_full.png` | 96×96 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_star_empty.png` | 96×96 | 🔴 ยังไม่มี | UI ที่ต้องทำ |
| `ui_clue_notebook.png` | 360×280 | 🔴 ยังไม่มี | UI ลูปงานซ่อม S1-S5 |
| `ui_clue_slot_empty.png` | 300×70 | 🔴 ยังไม่มี | UI ลูปงานซ่อม S1-S5 |
| `ui_clue_slot_filled.png` | 300×70 | 🔴 ยังไม่มี | UI ลูปงานซ่อม S1-S5 |
| `ui_patience_pip_on.png` | 32×32 | 🔴 ยังไม่มี | UI ลูปงานซ่อม S1-S5 |
| `ui_patience_pip_off.png` | 32×32 | 🔴 ยังไม่มี | UI ลูปงานซ่อม S1-S5 |
| `ui_topic_btn_normal.png` | 260×72 | 🔴 ยังไม่มี | UI ลูปงานซ่อม S1-S5 |
| `ui_topic_btn_hover.png` | 260×72 | 🔴 ยังไม่มี | UI ลูปงานซ่อม S1-S5 |
| `ui_topic_btn_press.png` | 260×72 | 🔴 ยังไม่มี | UI ลูปงานซ่อม S1-S5 |
| `wb_hotspot_normal.png` | 96×96 | 🔴 ยังไม่มี | UI ลูปงานซ่อม S1-S5 |
| `wb_hotspot_hover.png` | 96×96 | 🔴 ยังไม่มี | UI ลูปงานซ่อม S1-S5 |
| `wb_hotspot_locked.png` | 96×96 | 🔴 ยังไม่มี | UI ลูปงานซ่อม S1-S5 |
| `ui_checklist_row.png` | 520×64 | 🔴 ยังไม่มี | UI ลูปงานซ่อม S1-S5 |
| `ui_bench_test_pass.png` | 400×400 | 🔴 ยังไม่มี | UI ลูปงานซ่อม S1-S5 |
| `ui_bench_test_fail.png` | 400×400 | 🔴 ยังไม่มี | UI ลูปงานซ่อม S1-S5 |
| `ui_invoice.png` | 520×700 | 🔴 ยังไม่มี | UI ลูปงานซ่อม S1-S5 |

## `Assets/Background/`
| ไฟล์ | canvas | สถานะ | ใช้ที่ |
|---|---|---|---|
| `bg_shop_counter.jpg` | 1152×648 | 🔴 ยังไม่มี | พื้นหลัง scene ใหม่ |
| `bg_workbench.jpg` | 1152×648 | 🔴 ยังไม่มี | พื้นหลัง scene ใหม่ |

## `Assets/Ending/`
| ไฟล์ | canvas | สถานะ | ใช้ที่ |
|---|---|---|---|
| `end_stay_village.jpg` | 1152×648 | 🔴 ยังไม่มี | ฉากจบ 3 แบบ |
| `end_back_city.jpg` | 1152×648 | 🔴 ยังไม่มี | ฉากจบ 3 แบบ |
| `end_expand_shop.jpg` | 1152×648 | 🔴 ยังไม่มี | ฉากจบ 3 แบบ |

## สรุป

| | จำนวน |
|---|---|
| ✅ มีแล้วใช้ได้ | 36 |
| 🟠 มีไฟล์แต่ต้องทำใหม่ | 7 |
| 🔴 ยังไม่มี | 99 |
| **รวมในเอกสารนี้** | **142** |

> ไฟล์เสียง 19 ไฟล์ไม่ได้อยู่ในตารางนี้ เพราะต้องมี `AudioManager` autoload ก่อน ดูรายชื่อใน `ASSET_TODO.md` ชุด I

## ประวัติเอกสาร

| วันที่ | การเปลี่ยนแปลง |
|---|---|
| 28 ก.ย. 2569 | สร้างเอกสาร — รวมชื่อไฟล์จากทุก MD ให้เป็นรายการเดียว ตรวจกับไฟล์จริง และแยกขนาด canvas ออกจากขนาดตอนวางในฉาก |
| 28 ก.ย. 2569 | เปลี่ยน asset ตัวใหม่ 23 ไฟล์ที่ crop ใหม่จาก sheet ต้นฉบับ (PartCommon 11 · PartRam 12) ทุกไฟล์ที่เคยเป็น 🟠 กลายเป็น ✅ แล้ว |
