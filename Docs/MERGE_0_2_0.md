# Merge / Sync 0.2.0 — Test/Beta_version1 ↔ thunder-beta-v1

> อัปเดต 15 ต.ค. 2569 · อ่านก่อน merge · ไฟล์นี้บอกว่าฝั่ง `Test/Beta_version1` เปลี่ยนอะไรไปตั้งแต่จุดที่เพื่อน merge ล่าสุด (`afbe94b`) และต้องรู้อะไรบ้างถ้าจะเขียนโค้ดต่อจากนี้

## 1. สถานะตอนนี้

| สาขา | commit ล่าสุด | หมายเหตุ |
|---|---|---|
| `origin/Test/Beta_version1` | `0fbdd85` Update Docx | 0.2.0 (เวลาแบบสัปดาห์ · ledger · บิล/เป้าเดือน · หน้าสรุปเดือน · เซฟ v2) |
| `origin/thunder-beta-v1` | `213c16d` ปุ่มลบใน Explorer | ขมOS แบบฉาก (desktop_window2 · DesktopOS · Explorer) · ย้ายเงิน/ยศไป EventManager |
| จุดแยกร่วม (merge-base) | `afbe94b` | ledger 0.2.0-C |

**ลอง merge `origin/thunder-beta-v1` เข้า `Test/Beta_version1` แล้ว (15 ต.ค.): ไม่มี conflict · เทสอัตโนมัติผ่าน 15/15** (รันบน Godot 4.7.2 headless)

ไฟล์ที่ทั้งสองฝั่งแก้ แต่ git รวมให้เองได้:

| ไฟล์ | ฝั่งเรา | ฝั่งเพื่อน | ผลรวม |
|---|---|---|---|
| `Scripts/EventManager/time_system.gd` | ปฏิทิน 2570 · HUD วันที่จริง · `shift_label()` | ลบโค้ดเงิน/ยศออก (ย้ายไป EventManager) | ✅ คนละส่วนของไฟล์ |
| `Test/power_test.gd` | ข้อความ HUD แบบใหม่ | เช็กแถบยศที่ `EventManager.rank_box` | ✅ |
| `Scene/time_system.tscn` · `Scene/event_manager.tscn` | ไม่แตะ | ย้าย `money_label` | ✅ |

## 2. วิธี merge (แนะนำ)

```
git fetch origin
git checkout Test/Beta_version1
git pull
git merge origin/thunder-beta-v1      # หรือฝั่งเพื่อน merge Test/Beta_version1 เข้า thunder-beta-v1 ก็ได้
# เปิด Godot 4.7 ให้ import ใหม่ 1 รอบ (มีฉาก/ฟอนต์ใหม่) แล้วรัน Test/*_test.tscn
```

> ⚠ บนเครื่องของหัวหน้าทีม `thunder-beta-v1` (local) แยกทางกับ origin แล้ว (ahead 7 / behind 17 เพราะฝั่ง origin ถูก force-push) → **อย่า push สาขานี้จากเครื่องนั้น** ใช้ `origin/thunder-beta-v1` เป็นหลัก

## 3. สิ่งที่เปลี่ยนตั้งแต่ `afbe94b`

| ระบบ | ไฟล์ | สรุป |
|---|---|---|
| เวลา | `time_system.gd` | **1 บท = 1 สัปดาห์ · ร้านเปิด 3 วัน จ. พ. ศ. (`OPEN_WEEKDAYS`) · 4 บท = 1 เดือน · 12 บท = 36 วัน = 4 ม.ค.–26 มี.ค. 2570** · จ.→พ. ข้าม 2 วัน ("ร้านปิด ขมไปช่วยยาย") · ศุกร์→จันทร์ข้าม ส.–อา. · HUD `พุธ 6 ม.ค.` / `บทที่ 1 · สัปดาห์ที่ 1 ของ ม.ค.` |
| ข้ามวัน | `Scene/UI/day_skip.tscn` · `calendar_page.tscn` · `Scripts/UI/day_skip.gd` | ปฏิทินฉีกทีละแผ่น + ป้าย "ผ่านไป n วัน" · ปิ๊บพูดเฉพาะเมื่อมีเรื่อง (`DayLoop.day_skip_notes`) |
| เงิน | `game_state.gd` | ledger แยกหมวด · `month_*()` · บิลรายเดือน + ค่าปรับ 10% · `month_report()` · `close_month()` · ร้านปิด (`shop_closed`) · โหมดช่วย (`help_mode`) |
| ตัวเลข | `economy_config.gd` | บิล (เช่า 1,500 · ไฟ 200/200/250 + 4/เทิร์น · น้ำ 100 · เน็ต 300) · เป้า 1,200/4,200/6,000 · กลุ่ม "ผลสิ้นเดือน" |
| UI | `Scene/UI/month_goal_bar.tscn` · `month_summary.tscn` | แถบเป้าเดือนใต้แถบยศ · หน้าสรุปเดือนแบบตาราง |
| ลูปร้าน | `day_loop.gd` · `Scene/Core/day_loop.tscn` | ชั้น UI ใหม่ใน day_loop.tscn (ข้อ 4.4) · ปิดเดือนตอน `month_ended` |
| เซฟ | `save_game.gd` | `VERSION = 2` · เซฟ v1 → เมนูขึ้น "เซฟเวอร์ชันเก่าใช้ไม่ได้ · เริ่มใหม่" |
| ฟอนต์ | `Assets/Fonts/main_font.tres` · `project.godot` | ฟอนต์หลักของโปรเจกต์ = Supermarket (สำรอง Sarabun) |
| เทส | `Test/loop_test` · `money_test` (ใหม่) · `save_test` · `power_test` | รวม 15 ชุด |

## 4. ต้องรู้ถ้าจะเขียนโค้ดต่อ (โดยเฉพาะฝั่งขมOS)

### 4.1 เงิน — เปลี่ยนเงินผ่าน `GameState.add_money()` เสมอ
```
GameState.add_money(delta: int, kind: StringName, note := "")
```
- **ห้ามแก้ `GameState.money` ตรง ๆ** ไม่งั้นรายการไม่เข้าบัญชีร้าน (หน้าสรุปเดือนจะไม่ตรงกับเงินจริง)
- หมวด (`GameState.MONEY_KINDS`): `fee` ค่าแรง · `tip` ทิป · `sell` ขายคืน · `damage` ค่าเสียหาย · `bill` บิล · `ot_power` ไฟล่วงเวลา · `buy` ซื้อของ · `invest` ลงทุน (ไม่นับในกำไร) · `other`
- ร้านออนไลน์ในขมOS (0.4.0) → ใช้ `&"buy"` · ซื้อของที่เป็นอัปเกรดร้าน → `&"invest"` (หรือเรียก `GameState.buy(item)` ที่ใส่หมวดให้แล้ว)
- สัญญาณเดิม `money_changed` · `rank_up` **ชื่อเดิม ไม่ได้เปลี่ยน** · ใหม่: `bill_paid(bill)` · `month_closed(report)`

### 4.2 เวลา — ฟังก์ชันที่ใช้ได้
| ฟังก์ชัน | คืนค่า |
|---|---|
| `ts.chapter()` / `ts.week()` | บท 1–12 (= สัปดาห์) |
| `ts.month()` · `ts.week_in_month()` | เดือน 1–3 · สัปดาห์ที่ 1–4 ของเดือน |
| `ts.calendar_date()` | `Vector2i(วัน, เดือน)` ปี 2570 |
| `ts.weekday()` · `ts.date_text()` | 0 = จ. · 2 = พ. · 4 = ศ. · `"พ. 6 ม.ค."` |
| `ts.days_since_last_play()` | 2 (จ.→พ. · พ.→ศ.) · 3 (ศุกร์→จันทร์) |
| `ts.days_left_in_month()` | วันทำการที่เหลือในเดือน |
| `TimeSystem.shift_label(s)` (static) | `"บทที่ 2 · จ. 11 ม.ค."` (s = 1–36) |

นาฬิกาในขมOS: ใช้ `EventManager.get_clock_text()` (ของเพื่อน) ได้เหมือนเดิม · ถ้าจะโชว์วันที่ในทาสก์บาร์ใช้ `ts.date_text()`

### 4.3 ฟอนต์
- ฟอนต์หลักตั้งที่ `project.godot` → ทุก Control ได้ Supermarket อัตโนมัติ · **ถ้าฉากขมOS ตั้ง theme/ฟอนต์เองจะไม่ได้ฟอนต์นี้** (ไม่ผิด แต่หน้าตาจะต่างจาก UI อื่น)
- ใน `supermarket.ttf` ตัดอักษรช่วง U+0080–00FF ออก (glyph ผิด เช่น "·" เคยขึ้นเป็น "ท") → อักษรช่วงนั้นใช้ Sarabun แทนอัตโนมัติ

### 4.4 ชั้น UI (CanvasLayer)
| ชั้น | อะไร | อยู่ที่ |
|---|---|---|
| 90 | การ์ดลูปร้าน | `DayLoop` |
| 100 | HUD เวลา/เงิน/ยศ · แถบเป้าเดือน | `TimeSystem` · `DayLoop/GoalLayer` |
| 105 | ปุ่มคลังของ | `Storage` |
| 108 | หน้าสรุปเดือน | `DayLoop/SummaryLayer` |
| 110 | ฉากข้ามวัน | `DayLoop/DaySkipLayer` |
| 128 | บทพูด | `DialogScene` |

หน้าต่างขมOS ที่เปิดเป็นมินิเกม (`Global.in_minigame = true`) → แถบเป้าซ่อนเอง

### 4.5 เซฟ
`SaveGame.VERSION = 2` · ถ้าเพิ่มข้อมูลของขมOS ที่ต้องจำข้ามวัน (ไฟล์ในถังขยะ ฯลฯ) ให้เพิ่มคีย์ใหม่ใน `save()`/`load_into()` และใส่ค่าเริ่มต้นตอน `get(..., ค่าเริ่ม)` · ไม่ต้องขึ้น VERSION ถ้าแค่เพิ่มคีย์

## 5. บั๊กที่เจอและแก้รอบ merge นี้ (ยังไม่ commit)
| บั๊ก | สาเหตุ | แก้ |
|---|---|---|
| ปิดเกมตอนการ์ดสรุปบท/สรุปเดือนยังค้าง → โหลดแล้วการ์ดหาย **และบทเนื้อเรื่องของบทถัดไปไม่เล่น** | บันทึกอัตโนมัติเกิดตอนเริ่มกะใหม่ (ก่อนกด "ไปต่อ") แต่ไม่ได้เก็บ `_pending_summary_week` | `save_game.gd` เก็บ `pending_summary` · `summary_month_end` · `last_bill` · โหลดแล้วร้านปิดก็ตั้ง `_game_over` · เทสใน `save_test` |
| เริ่มเกมใหม่หลังฉากจบแล้วข้อมูลสรุปเดือนเก่าค้าง | `_reset_run()` ไม่ล้าง `_last_month` | ล้างแล้ว |
| `Assets/Fonts/supermarket.ttf.import` · `Scripts/UI/month_summary.gd.uid` ไม่ได้ commit | Godot สร้างหลัง commit | ใส่ใน commit ถัดไป |

## 6. เช็กลิสต์หลัง merge
- [ ] เปิด Godot ให้ import ใหม่ ไม่มี error สีแดงใน Output
- [ ] รัน `Test/*_test.tscn` ครบ 15 ชุด → ทุกชุด `T DONE fails=0`
- [ ] เล่นจากเมนู → จบบทที่ 1 ได้ (เดโม 3 วัน จ. พ. ศ.) · HUD ขึ้นวันที่จริง · ฉีกปฏิทินตอนขึ้นวันใหม่
- [ ] (ทดสอบเดือน) ตั้ง `DayLoop.demo_shifts = 12` ใน `day_loop.tscn` ชั่วคราว → เล่นถึงสิ้นเดือน ม.ค. เห็นหน้าสรุปเดือน → **คืนเป็น 3 ก่อน commit**
- [ ] ขมOS ใหม่ (desktop_window2) ซื้อ/ขายอะไรให้ผ่าน `add_money(..., kind)`

## ประวัติ
| วันที่ | การเปลี่ยนแปลง |
|---|---|
| 15 ต.ค. 2569 | สร้าง — สรุป 0.2.0 สำหรับ merge กับ thunder-beta-v1 · ลอง merge แล้วไม่ conflict · เทส 15/15 |
