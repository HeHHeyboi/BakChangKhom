# ASSET_STATUS.md — ผลตรวจ asset จริงในโฟลเดอร์
> ตรวจใหม่ 6 ต.ค. 2569 · สแกนไฟล์จริงเทียบตาราง `ASSET_NAMING.md` ทั้ง 142 แถว (ตัวเลขเดิม 29 ก.ย. · commit `47fbfd7`)
> **Prologue + Core เกมแรก → ดู `ASSET_CORE1.md` (30 ก.ย.)**
> เอกสารคู่กัน: `ASSET_NAMING.md` (ชื่อ+ขนาดฉบับอ้างอิง) · `ASSET_RENAME.md` (ไฟล์ที่ชื่อยังไม่ตรงกฎ) · `ASSET_TODO.md` (เช็กลิสต์งาน)

> 🆕 9 ต.ค. 2569: เพิ่ม asset ชุด ขมOS · ฉากบ้านยาย · บทฝึกประกอบคอม (เวกเตอร์) — รายการอยู่ท้าย `ASSET_CORE1.md` (ไม่นับในตัวเลขข้างล่าง)

> ℹ️ ชุด `Assets/MiniGame/Scene2D/` (ฉากมินิเกม 2D · 30 ก.ย.) **ไม่นับ**ในตัวเลขนี้ เพราะไม่อยู่ในตาราง `ASSET_NAMING.md` · ดู `SCENE_2D.md` §3 และ `ASSET_TODO.md` ท้ายไฟล์

> 🆕 **10 ต.ค. 2569 — ตัดสินใจ: ใช้ asset ที่ Claude สร้างด้วยโค้ดเป็นหลักไปก่อน** (ดูหัวข้อ "Asset ที่สร้างด้วยโค้ด" ด้านล่าง) · ถ้าทีมวาดภาพจริงมาแทนภายหลัง ใช้ชื่อไฟล์เดิมทับได้เลย ไม่ต้องแก้โค้ด (หรือสร้างชื่อใหม่แล้วเปลี่ยนใน Inspector)

## สรุป

| | จำนวน |
|---|---|
| ✅ มีไฟล์จริงและขนาดตรงสเปกทุกไฟล์ | **57** (29 ก.ย. = 43) |
| 🔴 ยังไม่มี | **85** (29 ก.ย. = 99) |
| 🟠 มีไฟล์แต่ภาพในไฟล์ผิด | **0** (เดิม 7 · แก้ครบแล้วใน commit `fc660aa`) |
| 🟡 ชื่อไม่ตรงกฎ ต้องเปลี่ยน | **38** — ดู `ASSET_RENAME.md` (6 ต.ค. ยังไม่ได้ทำ ไฟล์เดิมเช่น `HomeBG.jpg` · `speaker.png` ยังอยู่) |

เพิ่มตั้งแต่ 29 ก.ย. (+14): สไลด์สอน 7 (`tut_start_01..03` · `tut_ram_01..04` 1152×648) · `gpu_card_dusty` · BIOS `bios_drive_*` 3 + `bios_btn_*` 3

## ✅ ที่ทำเสร็จแล้ว

* **ชุดเครื่องมือครบทั้งสองชุด** — `PartCommon/tool_*` 11 ไฟล์ · `PartRam/ram_tool_*` 10 ไฟล์ ขนาด 200×200 ตรงสเปกทุกไฟล์
* **ถาดและการ์ดคุณสมบัติ** — `ram_tray` 580×320 · `ui_tool_card` 290×380 · `ui_meter_pip_on/off` 24×24 · `ram_icon_*` 4 ไฟล์ 48×48
* **แรม 3 สถานะ** 600×214 เท่ากันทุกใบ · **กล่องค้นหา** 2 state 256×256
* **UI พื้นฐาน 9 ไฟล์** — ปุ่ม 4 state · dialog box · name plate · quest panel · time panel · marker
* **crop รอบใหม่แก้ปัญหากริดเลื่อน** — ของเดิมใน `PartCommon` ผิดเกือบทั้งชุด (คีมเป็นเศษ 2 ชิ้นปนกัน · มัลติมิเตอร์โดนตัด · USB เป็นแผ่นรอง ESD) ตอนนี้ถูกทุกชิ้น

## 🔴 ยังขาด 85 ไฟล์

| กลุ่ม | ขาด | ไฟล์ |
|---|---|---|
| UI ที่ต้องทำ | 18 | `ui_icon_morning.png` · `ui_icon_noon.png` · `ui_icon_evening.png` · `ui_icon_coin.png` · `ui_icon_xp.png` · `ui_rank_1.png` · … อีก 12 |
| UI ลูปงานซ่อม S1-S5 | 15 | `ui_clue_notebook.png` · `ui_clue_slot_empty.png` · `ui_clue_slot_filled.png` · `ui_patience_pip_on.png` · `ui_patience_pip_off.png` · `ui_topic_btn_normal.png` · … อีก 9 |
| S2 Workbench + Normal Part | 12 | `wb_case_closed.png` · `wb_case_open.png` · `wb_parts_tray.png` · `wb_screw_cup.png` · `part_side_panel.png` · `part_psu.png` · … อีก 6 |
| Part Mainboard | 8 | `mb_mainboard_ghost.png` · `mb_cpu_wrong.png` · `mb_paste_dot_small.png` · `mb_paste_dot_ok.png` · `mb_paste_dot_large.png` · `mb_heatsink_dusty.png` · … อีก 2 |
| Part BIOS | 2 | `bios_bottleneck_chart.png` · `bios_windows_desktop.png` |
| Phase 2-3 ตัดไฟและถอด | 7 | `ram_btn_shutdown.png` · `ram_plug_in.png` · `ram_plug_out.png` · `ram_hand_touch_case.png` · `ram_slot_empty.png` · `ram_clip_closed.png` · … อีก 1 |
| Phase 0 วินิจฉัย | 6 | `ram_pc_front.png` · `ram_screen_glitch.png` · `ram_screen_normal.png` · `ram_speaker_icon.png` · `ram_case_dusty.png` · `ram_clue_card.png` |
| Part GPU | 3 | `gpu_cable_cpu8.png` · `gpu_connector_zoom.png` · `gpu_burn.png` |
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
| ~~**ผูกตัวละครเข้า `_CharacterMap`**~~ ✅ | `Scene/Global.tscn` ผูกครบแล้ว 12 ตัวละคร (ขม · ยาย · ปิ๊บ · มิ้น · ผู้ใหญ่บ้าน · ครู · ลุงอำนวย · ผอ. · เด็ก · เด็กหญิง · หัวหน้า · เพื่อนร่วมงาน ฯลฯ) พร้อมสีหน้า `"ชื่อ:อารมณ์"` — ตรวจ 6 ต.ค. |
| **ย่อพื้นหลัง 6 ไฟล์** | `RoomBG` `HomeBG` `Market` `Chapter2_bg` (1920×1080) · `stargBG` (2048×1448) · `Office.png` (740×555 เล็กกว่าจอ) |
| **บีบไฟล์ใหญ่ 4 ไฟล์** | `mb_mainboard` 1.4 MB · `mb_case_open` 1.35 MB · `gpu_cable_messy` 1.1 MB · `gpu_cable_tidy` 866 KB |
| **สไลด์ tutorial ชื่อภาษาไทย 2 ไฟล์ (ลบได้แล้ว)** | `Tutorial สอนเล่น.png` · `Tutorial ขัดแรม.png` · `tutorial1.tres` / `ram_cleaning.tres` ชี้ชุด `tut_*` แล้ว ไม่มี `.tres` อ้างไฟล์เก่า (6 ต.ค.) — ไฟล์ยังค้างอยู่ในโฟลเดอร์ ลบใน Godot FileSystem ได้เลย |

## ไฟล์ที่ไม่มีโค้ดอ้างและไม่อยู่ในเอกสาร

ดูรายการ 11 ไฟล์พร้อมคำตัดสินในหัวข้อท้ายของ `ASSET_NAMING.md`

## 🖌 Asset ที่สร้างด้วยโค้ด — ใช้เป็นหลัก (10 ต.ค. 2569)

ทุกชุดมีสคริปต์ Python (PIL / numpy) อยู่ในโฟลเดอร์ `src/` ข้างไฟล์ภาพ (มี `.gdignore` Godot ไม่ import) · รันซ้ำได้ผลเหมือนเดิมทุกครั้ง · **ไม่เขียนทับไฟล์ LFS เดิม** (สร้างชื่อใหม่เสมอ)

| ชุด | ไฟล์ | สคริปต์ | ใช้ที่ |
|---|---|---|---|
| แผนที่หมู่บ้าน | `Assets/Map/map_bg.jpg` · `loc_home` · `loc_village` · `loc_shop` · `loc_market` · `loc_city` (.jpg) | `Assets/Map/src/gen_map.py` | `Scene/map.tscn` (การ์ดสถานที่ตัดจากฉากที่มีอยู่) |
| ตลาด | `Assets/Background/bg_market_day.jpg` (ถนนหน้าบ้าน + แผง 3 ร้าน) | `gen_map.py` | `Scene/Location/Market.tscn` |
| ห้องของขม | `Assets/Background/bg_khom_room.jpg` (ห้องไม้ + คอมเก่า CRT · ฟูก · โปสเตอร์) | `gen_map.py … room` | บท "ห้องของขม" (`Resources/main.tres`) · `find_item_minigame.tscn` |
| ห้องเก็บของ | `Assets/Background/bg_storeroom.jpg` | `gen_map.py` | ยังไม่ได้ใช้ (สำรอง) |
| ตรวจเครื่องเบื้องต้น | `Assets/MiniGame/PowerCheck/` power_bg · pc_back (PSU ล่าง) · fan · fan_grill · psu_sw_off/on · strip · strip_sw_off/on · plug · pc_front · power_btn(_hover) | `PowerCheck/src/gen_power.py` | `Scene/MiniGame/PowerCheck/power_check.tscn` |
| ขมOS ในจอบนโต๊ะ | `Assets/MiniGame/Desktop/os_frame_desk.png` + ไอคอน `os_icon_*` | `Desktop/src/gen_frame.py` | `desktop_window.tscn` |
| โต๊ะคอม / เมาส์มีสาย | `Assets/MiniGame/TutorialAssembly/desk_pc_2x.png` · `asm_*` | `TutorialAssembly/src/gen_desk.py` · `gen_asm.py` · `mouse_art.py` | บทฝึกประกอบคอม · Part BIOS/FrontPanel/GPU/Mainboard/RAM (bg_scale 0.5) |
| ภาพ Part อื่น ๆ | `PartBios` · `PartFrontPanel` · `PartGpu` · `PartMainboard` | `Part*/src/gen_art.py` | มินิเกม Core Part |
| สไลด์สอนเล่น | `Assets/Tutorial/BasicStart/tut_new_01–04.png` (ถ่ายจากฉากจริง) | `Assets/Tutorial/src/gen_start_slides.py` | `Resources/tutorial1.tres` (`tut_start_0x` เดิมไม่ได้แก้) |
| เพลง + เสียง | `Assets/Audio/Music/*.ogg` (เมนู · หมู่บ้าน · ทำงาน · jingle จบบท) · `Sfx/*.wav` · `Sfx/Beep/beep_*.wav` (รหัส BIOS 10 แบบ) | `Assets/Audio/src/gen_audio.py` | autoload `Audio` · ดู `AUDIO.md` |
| สีหน้าตัวละคร | `Assets/CharacterSprite/*` บางสีหน้า | `CharacterSprite/src/make_expr.py` | `_CharacterMap` |

**วิธีเปลี่ยนเป็นภาพจริงภายหลัง:** วาดขนาดเท่าเดิม (ดูขนาดจากไฟล์ปัจจุบัน) → ตั้งชื่อไฟล์ใหม่ → ลากใส่ช่อง texture ใน Inspector ของโหนดที่ใช้ (ทุกฉากด้านบนสร้างเป็นโหนด) · สำหรับ PowerCheck/แผนที่ ตำแหน่งปุ่มอ้างพิกัดในภาพ — ถ้าภาพใหม่ย้ายของ ให้ลากโหนดตามใน Inspector

## ประวัติเอกสาร

| วันที่ | การเปลี่ยนแปลง |
|---|---|
| 10 ต.ค. 2569 | ตัดสินใจใช้ asset ที่สร้างด้วยโค้ดเป็นหลัก · เพิ่มตาราง "Asset ที่สร้างด้วยโค้ด" (แผนที่ · ตลาด · ห้องของขม · ตรวจเครื่อง · ขมOS · โต๊ะคอม · สไลด์ · เสียง) |
| 24 ก.ย. 2569 | สร้างเอกสาร — พบเพิ่มใหม่ 29 ไฟล์ เหลือขาด 118 และ 7 ไฟล์ที่เนื้อหาในภาพผิด |
| 6 ต.ค. 2569 | ตรวจใหม่จากไฟล์จริง — ✅ 57 · 🔴 85 (เดิม 43 / 99) · +14 ไฟล์ (สไลด์ tutorial 7 · `gpu_card_dusty` · BIOS 6) · `_CharacterMap` ผูกครบแล้ว · สไลด์ชื่อไทยลบได้ · งานเปลี่ยนชื่อ 38 ไฟล์ + `speaker.png` ยังค้าง |
| 29 ก.ย. 2569 | ตรวจใหม่หลัง commit `fc660aa` — ปิด 🟠 ครบทั้ง 7 ไฟล์ · มีไฟล์ใช้ได้ 43 เหลือขาด 99 · เพิ่มงาน `speaker.png` และงานเปลี่ยนชื่อ 38 ไฟล์ |
