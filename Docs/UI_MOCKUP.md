# UI_MOCKUP.md — Mockup หน้าจอ และ asset ที่ใช้ในแต่ละช่อง

> 22 ก.ย. 2569 · จอเกม **1152 × 648** · ภาพอยู่ที่ `Docs/Mockups/`
> ประกอบจาก **asset จริงในโปรเจกต์** ช่องที่ยังไม่มีไฟล์แสดงเป็นกรอบลายทแยงพร้อมชื่อไฟล์ที่ต้องทำ
> สีในภาพ — 🟢 มีไฟล์แล้วใช้ได้เลย · 🟠 มีไฟล์แต่ต้องแก้ · 🔴 ยังไม่มี ต้องทำเพิ่ม

---

## Mockup 1 · ฉากห้องของขม (HUD ระหว่างเดินเล่น)

`ui_mock_01_room_hud.png`

| # | ไฟล์ | ตำแหน่ง (x, y, w, h) | สถานะ |
|---|---|---|---|
| 1 | `Background/RoomBG.jpg` | เต็มจอ | 🟠 1920×1080 ควรย่อเป็น 1152×648 |
| 2 | `UI/ui_quest_panel.png` | 18, 18, 300×214 | 🟢 |
| 3 | `UI/ui_time_panel.png` | 774, 18, 360×80 | 🟢 |
| 4 | `UI/ui_icon_morning.png` | 784, 28, 60×60 | 🔴 ต้องทำ 3 ไฟล์ เช้า/เที่ยง/เย็น |
| 5 | `UI/ui_marker_caution.png` | 470, 300, 120×120 | 🟢 ต้องทำเพิ่ม state hover/press |
| 6 | `MiniGame/PartRam/ram_box_normal.png` | 120, 360, 190×190 | 🟢 |
| 7 | `UI/ui_btn_map.png` | 1002, 498, 128×128 | 🔴 |
| 8 | `CharacterSprite/char_khom_normal.png` | 760, 250, 260×330 | 🟠 มีไฟล์ แต่ยังไม่ผูกเข้า `_CharacterMap` |

## Mockup 2 · หน้าบทสนทนา (DialogScene)

`ui_mock_02_dialog.png`

| # | ไฟล์ | ตำแหน่ง | สถานะ |
|---|---|---|---|
| 1 | `Background/bg_shop_open.jpg` | เต็มจอ | 🟢 1152×648 พอดี |
| 2 | `CharacterSprite/char_amnuay.png` | ซ้าย (มาร์ก Left1 ที่ −417, 78 จากกึ่งกลาง) | 🟠 ยังไม่ผูก |
| 3 | `CharacterSprite/char_khom_normal.png` | ขวา (มาร์ก Right1 ที่ +345, 78) | 🟠 ยังไม่ผูก |
| 4 | `UI/ui_dialog_box.png` | 0, 448, 1152×200 | 🟢 |
| 5 | `UI/ui_name_plate.png` | 40, 412, 340×72 | 🟢 |
| 6 | `UI/ui_btn_next.png` | 1022, 528, 96×96 | 🔴 |

> ข้อความทั้งหมดในหน้านี้เป็น `RichTextLabel` / `Label` ไม่ได้ฝังในภาพ

## Mockup 3 · มินิเกม Part RAM ขั้นเลือกอุปกรณ์ (Phase 4)

`ui_mock_03_minigame_ram.png`

| # | ไฟล์ | ตำแหน่ง | สถานะ |
|---|---|---|---|
| 1 | `MiniGame/PCCaseBG.jpg` | เต็มจอ | 🟢 1152×648 |
| 2 | `MiniGame/PartRam/ram_dirty.png` | 280, 190, 600×214 | 🟢 สลับกับ `ram_better` / `ram_clean` ขนาดเท่ากันทั้ง 3 |
| 3 | `MiniGame/PartRam/ram_eraser.png` | 620, 110, 150×150 | 🟢 |
| 4–8 | `PartRam/ram_tool_*.png` × 5 | แถวล่าง เริ่ม 52, 486 ทีละ 132 px | 🟢 มีครบ 10 ชิ้น สุ่มโชว์ 6 |
| 9 | `MiniGame/PartRam/ram_tray.png` | 30, 470, 700×165 | 🔴 ถาดถูก crop ผิด ต้องทำใหม่ |
| 10 | `MiniGame/PartRam/ui_tool_card.png` | 760, 318, 320×200 | 🔴 ที่ได้มาเป็นภาพถาดไม้ ต้องทำใหม่ |
| 11–12 | `PartRam/ram_icon_moisture.png` · `ram_icon_esd.png` | บนการ์ด 44×44 | 🟢 (อีก 2 ไอคอน `narrow` / `residue` ยังเสีย) |
| 13 | `CharacterSprite/char_pib_normal.png` | 14, 170, 170×210 | 🟠 มี 5 อารมณ์ แต่ยังไม่ผูก |

## Mockup 4 · หน้าสรุปผลงานซ่อม (S5 Handover)

`ui_mock_04_summary.png` — **หน้านี้ขาด asset มากที่สุด 8 จาก 9 ช่อง**

| # | ไฟล์ | ตำแหน่ง | สถานะ |
|---|---|---|---|
| 1 | `UI/ui_quest_panel.png` | 276, 60, 600×420 | 🟢 ใช้กรอบเดียวกับกระดานภารกิจได้ |
| 2–4 | `UI/ui_star_full.png` / `ui_star_empty.png` | 430/540/650, 110, 96×96 | 🔴 |
| 5 | `UI/ui_icon_coin.png` | 330, 260, 64×64 | 🔴 |
| 6 | `UI/ui_icon_xp.png` | 330, 340, 64×64 | 🔴 |
| 7 | `UI/ui_rank_1..5.png` | 740, 300, 64×64 | 🔴 ต้องทำ 5 ไฟล์ |
| 8 | `UI/ui_btn_normal.png` | 416, 520, 320×96 | 🟢 ใส่ข้อความด้วย `Label` ทับ |
| 9 | `UI/ui_btn_close.png` | 1010, 40, 96×96 | 🔴 |

---

# สรุป asset ที่ยังขาดจาก mockup ทั้ง 4 หน้า

## 🔴 ต้องทำใหม่ก่อน UI จะครบ (18 ไฟล์)

| ไฟล์ | ขนาด | ใช้ที่ Mockup |
|---|---|---|
| `ui_icon_morning.png` · `ui_icon_noon.png` · `ui_icon_evening.png` | 64×64 | 1 |
| `ui_btn_map.png` | 128×128 | 1 |
| `ui_marker_caution_hover.png` · `ui_marker_caution_press.png` | 250×250 | 1 |
| `ui_btn_next.png` · `ui_btn_prev.png` · `ui_btn_close.png` | 96×96 | 2, 4 |
| `ui_star_full.png` · `ui_star_empty.png` | 96×96 | 4 |
| `ui_icon_coin.png` · `ui_icon_xp.png` | 64×64 | 4 |
| `ui_rank_1.png` ถึง `ui_rank_5.png` | 64×64 | 4 |

## 🔴 ต้องทำใหม่เพราะ crop เสีย (5 ไฟล์)

`ram_tray.png` (900×220) · `ui_tool_card.png` (320×200) · `ui_meter_pip_on/off.png` (24×24) · `ram_icon_narrow.png` · `ram_icon_residue.png` (48×48)

## 🟠 มีไฟล์แล้วแต่ต้องจัดการ

| งาน | ไฟล์ |
|---|---|
| ผูกตัวละครเข้า `_CharacterMap` ใน `Scene/Global.tscn` | `char_pib_*` (5) · `char_khom_*` (4) · `char_amnuay` · `char_min_*` · NPC อื่น ๆ รวม 10 คน |
| ย่อพื้นหลังเป็น 1152×648 | `RoomBG.jpg` · `HomeBG.jpg` · `Market.jpg` · `Chapter2_bg.jpg` |
| ชื่อไฟล์ไม่ตรงกับภาพ | `tool_esd_strap` (เป็นคีม) · `tool_usb_installer` · `tool_hex_driver` · `ram_tool_vacuum` |

## 🟢 ที่พร้อมใช้แล้ว

UI 9 ไฟล์ (ปุ่ม 4 state · dialog box · name plate · quest panel · time panel · marker) · เครื่องมือทำความสะอาด 9 ชิ้น · แรม 3 สถานะ · ยางลบ · กล่องค้นหา 2 state · ไอคอนคุณสมบัติ 2 จาก 4

---

## ข้อสังเกตจากการวาง mockup

1. **`ui_quest_panel` ใช้ซ้ำได้ 2 ที่** — ทั้งกระดานภารกิจและกรอบหน้าสรุป ประหยัดไป 1 ไฟล์
2. **ปุ่ม 9-patch ต้องใส่ข้อความด้วย `Label` ทับ** ห้าม generate ตัวอักษรลงในภาพ เพราะปุ่มเดียวใช้หลายข้อความ
3. **`ui_time_panel` มีที่ว่างด้านซ้ายพอดีสำหรับไอคอนช่วงเวลา 64×64** — ตอน gen ไอคอนให้ดูขนาดนี้เป็นหลัก
4. **หน้าสรุป (Mockup 4) คือคอขวด** — ขาด 8 จาก 9 ช่อง ถ้าจะให้เล่นจบลูปได้เร็วที่สุด ควรทำชุดนี้ก่อน: ดาว 2 ไฟล์ · coin · xp · ปุ่มปิด รวม 5 ไฟล์
5. **ตัวละครยังไม่ผูกเข้า `_CharacterMap`** เป็นงานโค้ด 5 นาที แต่บล็อกทั้งบทสนทนาและบทปิ๊บทั้ง 6 ไฟล์

## ประวัติเอกสาร

| วันที่ | การเปลี่ยนแปลง |
|---|---|
| 22 ก.ย. 2569 | สร้างเอกสาร — mockup 4 หน้าจอจาก asset จริง พร้อมตารางตำแหน่งและสรุป asset ที่ยังขาด 23 ไฟล์ |
