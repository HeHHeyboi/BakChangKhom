# ASSET_STATUS.md — ผลตรวจ asset จริงในโฟลเดอร์
> ตรวจ 29 ก.ย. 2569 · commit `47fbfd7` · สแกนไฟล์จริงเทียบ `ASSET_NAMING.md`
> **Prologue + Core เกมแรก → ดู `ASSET_CORE1.md` (30 ก.ย.)**
> เอกสารคู่กัน: `ASSET_NAMING.md` (ชื่อ+ขนาดฉบับอ้างอิง) · `ASSET_RENAME.md` (ไฟล์ที่ชื่อยังไม่ตรงกฎ) · `ASSET_TODO.md` (เช็กลิสต์งาน)

## สรุป

| | จำนวน |
|---|---|
| ✅ มีไฟล์จริงและขนาดตรงสเปกทุกไฟล์ | **43** |
| 🔴 ยังไม่มี | **99** |
| 🟠 มีไฟล์แต่ภาพในไฟล์ผิด | **0** (เดิม 7 · แก้ครบแล้วใน commit `fc660aa`) |
| 🟡 ชื่อไม่ตรงกฎ ต้องเปลี่ยน | **38** — ดู `ASSET_RENAME.md` |

## ✅ ที่ทำเสร็จแล้ว

* **ชุดเครื่องมือครบทั้งสองชุด** — `PartCommon/tool_*` 11 ไฟล์ · `PartRam/ram_tool_*` 10 ไฟล์ ขนาด 200×200 ตรงสเปกทุกไฟล์
* **ถาดและการ์ดคุณสมบัติ** — `ram_tray` 580×320 · `ui_tool_card` 290×380 · `ui_meter_pip_on/off` 24×24 · `ram_icon_*` 4 ไฟล์ 48×48
* **แรม 3 สถานะ** 600×214 เท่ากันทุกใบ · **กล่องค้นหา** 2 state 256×256
* **UI พื้นฐาน 9 ไฟล์** — ปุ่ม 4 state · dialog box · name plate · quest panel · time panel · marker
* **crop รอบใหม่แก้ปัญหากริดเลื่อน** — ของเดิมใน `PartCommon` ผิดเกือบทั้งชุด (คีมเป็นเศษ 2 ชิ้นปนกัน · มัลติมิเตอร์โดนตัด · USB เป็นแผ่นรอง ESD) ตอนนี้ถูกทุกชิ้น

## 🔴 ยังขาด 99 ไฟล์

| กลุ่ม | ขาด | ไฟล์ |
|---|---|---|
| UI ที่ต้องทำ | 18 | `ui_icon_morning.png` · `ui_icon_noon.png` · `ui_icon_evening.png` · `ui_icon_coin.png` · `ui_icon_xp.png` · `ui_rank_1.png` · … อีก 12 |
| UI ลูปงานซ่อม S1-S5 | 15 | `ui_clue_notebook.png` · `ui_clue_slot_empty.png` · `ui_clue_slot_filled.png` · `ui_patience_pip_on.png` · `ui_patience_pip_off.png` · `ui_topic_btn_normal.png` · … อีก 9 |
| S2 Workbench + Normal Part | 12 | `wb_case_closed.png` · `wb_case_open.png` · `wb_parts_tray.png` · `wb_screw_cup.png` · `part_side_panel.png` · `part_psu.png` · … อีก 6 |
| Part Mainboard | 8 | `mb_mainboard_ghost.png` · `mb_cpu_wrong.png` · `mb_paste_dot_small.png` · `mb_paste_dot_ok.png` · `mb_paste_dot_large.png` · `mb_heatsink_dusty.png` · … อีก 2 |
| Part BIOS | 8 | `bios_bottleneck_chart.png` · `bios_drive_hdd.png` · `bios_drive_ssd.png` · `bios_drive_usb.png` · `bios_btn_save.png` · `bios_btn_discard.png` · … อีก 2 |
| Phase 2-3 ตัดไฟและถอด | 7 | `ram_btn_shutdown.png` · `ram_plug_in.png` · `ram_plug_out.png` · `ram_hand_touch_case.png` · `ram_slot_empty.png` · `ram_clip_closed.png` · … อีก 1 |
| Phase 0 วินิจฉัย | 6 | `ram_pc_front.png` · `ram_screen_glitch.png` · `ram_screen_normal.png` · `ram_speaker_icon.png` · `ram_case_dusty.png` · `ram_clue_card.png` |
| สไลด์สอนขัดแรม | 4 | `tut_ram_01.png` · `tut_ram_02.png` · `tut_ram_03.png` · `tut_ram_04.png` |
| Part GPU | 4 | `gpu_cable_cpu8.png` · `gpu_connector_zoom.png` · `gpu_card_dusty.png` · `gpu_burn.png` |
| สไลด์สอนเล่นพื้นฐาน | 3 | `tut_start_01.png` · `tut_start_02.png` · `tut_start_03.png` |
| Phase 1 ภาพประกอบตอนปิ๊บสอน | 3 | `ram_diagram_ram_role.png` · `ram_diagram_gold_contact.png` · `ram_diagram_dust_block.png` |
| Phase 5-6 ใส่กลับและเอฟเฟกต์ | 3 | `ram_ghost.png` · `ram_dust_particle.png` · `ram_spark.png` |
| Part Front Panel | 3 | `fp_pin_header_zoom.png` · `fp_pin_label_overlay.png` · `fp_flashlight_beam.png` |
| ฉากจบ 3 แบบ | 3 | `end_stay_village.jpg` · `end_back_city.jpg` · `end_expand_shop.jpg` |
| พื้นหลัง scene ใหม่ | 2 | `bg_shop_counter.jpg` · `bg_workbench.jpg` |

⚡ **ทำ 5 ไฟล์นี้ก่อน** เพื่อให้เล่นจบลูปได้ 1 รอบ — `ui_star_full` · `ui_star_empty` · `ui_icon_coin` · `ui_icon_xp` · `ui_btn_close`

## 🟠 งานที่ไม่ต้องวาดใหม่ แต่ต้องทำ

| งาน | รายละเอียด |
|---|---|
| **`speaker.png` ผิดทั้งชื่อและขนาด** | ไฟล์ใหม่จากทีม ขนาด 1024×1024 · ต้องเปลี่ยนชื่อเป็น `ram_speaker_icon.png` และย่อเป็น 120×120 · อ้างอยู่ที่ `Scene/MiniGame/PartRam/part_ram.tscn` |
| **เปลี่ยนชื่อไฟล์ 38 ไฟล์** | 22 ไฟล์มีโค้ดอ้างอยู่ ต้องเปลี่ยนในหน้า FileSystem ของ Godot · 16 ไฟล์เปลี่ยนได้เลย — ดู `ASSET_RENAME.md` |
| **ผูกตัวละครเข้า `_CharacterMap`** | `Scene/Global.tscn` มีแค่ `"ขม"` กับ `"ยาย"` · sprite มี 23 ไฟล์ 13 ตัวละคร |
| **ย่อพื้นหลัง 6 ไฟล์** | `RoomBG` `HomeBG` `Market` `Chapter2_bg` (1920×1080) · `stargBG` (2048×1448) · `Office.png` (740×555 เล็กกว่าจอ) |
| **บีบไฟล์ใหญ่ 4 ไฟล์** | `mb_mainboard` 1.4 MB · `mb_case_open` 1.35 MB · `gpu_cable_messy` 1.1 MB · `gpu_cable_tidy` 866 KB |
| **สไลด์ tutorial ชื่อภาษาไทย 2 ไฟล์** | `Tutorial สอนเล่น.png` · `Tutorial ขัดแรม.png` · **ห้ามลบเฉย ๆ** เพราะ `Resources/tutorial1.tres` กับ `ram_cleaning.tres` อ้างอยู่ ต้องทำชุด `tut_*` มาแทนแล้วแก้ `.tres` ก่อน |

## ไฟล์ที่ไม่มีโค้ดอ้างและไม่อยู่ในเอกสาร

ดูรายการ 11 ไฟล์พร้อมคำตัดสินในหัวข้อท้ายของ `ASSET_NAMING.md`

## ประวัติเอกสาร

| วันที่ | การเปลี่ยนแปลง |
|---|---|
| 24 ก.ย. 2569 | สร้างเอกสาร — พบเพิ่มใหม่ 29 ไฟล์ เหลือขาด 118 และ 7 ไฟล์ที่เนื้อหาในภาพผิด |
| 29 ก.ย. 2569 | ตรวจใหม่หลัง commit `fc660aa` — ปิด 🟠 ครบทั้ง 7 ไฟล์ · มีไฟล์ใช้ได้ 43 เหลือขาด 99 · เพิ่มงาน `speaker.png` และงานเปลี่ยนชื่อ 38 ไฟล์ |
