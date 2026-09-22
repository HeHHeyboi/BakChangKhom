# Asset Crop + Interface UI Filename List

## Crop ทำได้พอดีไหม

ทำได้ครับ แต่ต้องแยกความหมายของคำว่า “พอดี” ออกเป็น 2 แบบ:

1. **พอดีตามขนาดไฟล์** — ทำได้แน่นอน เช่น `200x200`, `64x64`, `320x96`
2. **พอดีตามขอบวัตถุแบบ pixel-perfect** — ต้องเผื่อ safe margin ตอน generate และตรวจภาพหลัง crop อีกครั้ง เพราะ AI อาจวางวัตถุไม่ตรงกลางหรือชิดขอบเล็กน้อย

ไฟล์ที่ทำไปแล้วใช้วิธี crop จาก grid แล้ว resize ตามขนาด Asset Guide พร้อมพื้นโปร่ง แต่ก่อนใช้จริงใน Godot ควรเปิดดู 1 รอบเพื่อเช็กว่าไม่มีส่วนของวัตถุถูกตัด

## กฎ crop สำหรับภาพที่ generate เป็น sheet

- ใช้ grid ที่กำหนดแน่นอน เช่น 2×2, 4×2 หรือ 4×3
- วัตถุแต่ละช่องต้องไม่ล้ำเส้นช่องข้างเคียง
- เผื่อขอบใสอย่างน้อย 8–12% รอบวัตถุ
- crop เป็น PNG `RGBA` และรักษาพื้นโปร่ง
- resize หลัง crop เท่านั้น ไม่ resize sheet ทั้งแผ่นก่อน crop
- ห้ามใส่ข้อความจริงในภาพ UI; ใช้ Label ใน Godot
- state ของ asset เดียวกันต้องใช้ canvas เท่ากันทุกไฟล์

## Interface UI — รายชื่อหลักทั้งหมด

โฟลเดอร์: `Assets/UI/`

| Filename | Size | ใช้สำหรับ |
|---|---:|---|
| `ui_btn_normal.png` | 320×96 | ปุ่มหลัก 9-patch ปกติ |
| `ui_btn_hover.png` | 320×96 | ปุ่มหลักตอน hover |
| `ui_btn_press.png` | 320×96 | ปุ่มหลักตอนกด |
| `ui_btn_disabled.png` | 320×96 | ปุ่มหลัก disabled |
| `ui_dialog_box.png` | 1152×200 | กล่องบทสนทนาด้านล่าง |
| `ui_name_plate.png` | 340×72 | ป้ายชื่อผู้พูด |
| `ui_quest_panel.png` | 420×300 | กรอบ Quest Board |
| `ui_time_panel.png` | 360×80 | แถบเวลา |
| `ui_icon_morning.png` | 64×64 | ช่วงเช้า |
| `ui_icon_noon.png` | 64×64 | ช่วงเที่ยง |
| `ui_icon_evening.png` | 64×64 | ช่วงเย็น |
| `ui_icon_coin.png` | 64×64 | เงิน |
| `ui_icon_xp.png` | 64×64 | XP |
| `ui_rank_1.png` | 64×64 | ยศระดับ 1 |
| `ui_rank_2.png` | 64×64 | ยศระดับ 2 |
| `ui_rank_3.png` | 64×64 | ยศระดับ 3 |
| `ui_rank_4.png` | 64×64 | ยศระดับ 4 |
| `ui_rank_5.png` | 64×64 | ยศระดับ 5 |
| `ui_btn_close.png` | 96×96 | ปุ่มปิด |
| `ui_btn_next.png` | 96×96 | ปุ่มถัดไป |
| `ui_btn_prev.png` | 96×96 | ปุ่มย้อนกลับ |
| `ui_marker_caution.png` | 250×250 | marker ปกติ |
| `ui_marker_caution_hover.png` | 250×250 | marker ตอน hover |
| `ui_marker_caution_press.png` | 250×250 | marker ตอนกด |
| `ui_btn_map.png` | 128×128 | ปุ่มแผนที่ |

## UI ที่ควรทำก่อน

ลำดับประหยัดสำหรับการทำให้เกมเล่นได้ก่อน:

1. `ui_btn_normal.png`, `ui_btn_hover.png`, `ui_btn_press.png`, `ui_btn_disabled.png`
2. `ui_dialog_box.png`, `ui_name_plate.png`
3. `ui_time_panel.png` และ icon ช่วงเวลา 3 ไฟล์
4. `ui_quest_panel.png`
5. `ui_btn_close.png`, `ui_btn_next.png`, `ui_btn_prev.png`, `ui_btn_map.png`
6. coin, XP, rank และ caution marker

## Prompt กลางสำหรับ Interface UI

```text
2D hand-drawn game UI asset for BakChangKhom, clean imperfect dark-brown outline #2C1810, warm vivid palette, flat two-tone shading, transparent PNG, reusable game interface component, no baked-in text, no logo, no watermark, no signature, no photorealism, no 3D, no gradient. Preserve the exact requested canvas size and leave safe transparent margins for 9-patch or state switching.
```

## หมายเหตุสำหรับ 9-patch

ปุ่ม `ui_btn_*` ต้องมีขอบและมุมที่สม่ำเสมอ เพราะจะนำไป stretch ใน Godot ส่วนข้อความให้ใส่ด้วย `Label` ภายหลัง ไม่ควร generate ข้อความลงในภาพ
