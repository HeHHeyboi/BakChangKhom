# MINIGAME1_EARLY_PHASES.md — มินิเกม Part RAM ช่วงแรก (Diagnosis → Briefing → Power Off)

> 29 ก.ย. 2569 · ตรวจจาก commit `ff2ce58` · Godot 4.7 · จอ 1152 × 648
> ขอบเขต: 3 phase แรกที่มี node ผูกจริงใน `Scene/MiniGame/PartRam/part_ram.tscn` เท่านั้น — phase อื่นยังเป็น WIP ตามที่ทีมตั้งใจ
> เอกสารคู่กัน: `BUG_LIST.md` (BUG-36) · `ASSET_NAMING.md` (ชื่อและขนาด canvas) · `UI_MOCKUP.md` · `MINIGAME1_DESIGN.md`

---

## 1. โค้ดที่แก้ไปแล้ว (แก้น้อยที่สุด 3 ไฟล์ · +7 บรรทัด)

### BUG-36 🔴 สัญญาณ `PibHint.all_lines_finished` ทำให้ phase เลื่อนผิด

**ต้นเหตุ** — ใน `part_ram.tscn` สัญญาณ `all_lines_finished` ของ `PibHint` ต่อเข้า **ทั้ง** `PhaseDiagnosis` และ `PhaseBriefing` ทุกครั้งที่ปิ๊บพูดจบ ทั้งสองตัวจะรับหมด ไม่ว่าจะเป็น phase ที่เล่นอยู่หรือไม่

| อาการ (ก่อนแก้) | เพราะ |
|---|---|
| ตอบ Diagnosis **ผิด** → ปิ๊บพูดจบ → เกมข้ามไป phase ถัดไปทั้งที่ยังไม่ถูก | `PhaseBriefing` ที่ซ่อนอยู่รับสัญญาณแล้ว `phase_completed.emit()` |
| ตอบ Diagnosis **ถูก** → ข้าม Briefing ไป Power Off ทันที | Diagnosis emit → `_advance_phase()` เปิด Briefing **ในรอบ emit เดียวกัน** → Briefing (ตอนนี้ visible แล้ว) รับสัญญาณเดียวกันต่อ แล้ว complete ทันที |

**ที่แก้**

| ไฟล์ | เปลี่ยน |
|---|---|
| `Scripts/MiniGame/PartRam/phase_diagnosis.gd` | บรรทัดแรกของ `_on_pib_hint_all_lines_finished()` ใส่ `if not visible: return` |
| `Scripts/MiniGame/PartRam/phase_briefing.gd` | เหมือนกัน |
| `Scripts/MiniGame/PartRam/part_ram.gd` | `phase_completed.connect(_advance_phase)` → `connect(_advance_phase, CONNECT_DEFERRED)` |

ต้องใช้ **ทั้งสองอย่าง** — guard อย่างเดียวไม่พอสำหรับกรณีตอบถูก เพราะ Briefing กลายเป็น visible ก่อนสัญญาณรอบนั้นจะส่งถึงมัน `CONNECT_DEFERRED` เลื่อนการเปลี่ยน phase ไปทำหลังสัญญาณรอบนั้นส่งครบแล้ว

> **ข้อควรจำสำหรับ phase ถัดไป** — ถ้า phase ใหม่ต่อ `all_lines_finished` จาก Editor ด้วย ให้ใส่ `if not visible: return` บรรทัดแรกเสมอ

> **อัปเดต 29 ก.ย. (ครั้งที่ 2)** — ระบบ phase ย้ายไป `Scripts/MiniGame/PartBase/part_minigame.gd` แล้ว บรรทัด `CONNECT_DEFERRED` อยู่ที่นั่น · BUG-33 (ตารางข้อ 2 แถว 2) แก้แล้ว · PibHint แยกเป็น `Scene/MiniGame/PartBase/pib_hint.tscn` — ข้อ 3.3 ให้เพิ่ม `PibSprite` ในไฟล์นั้นแทน · ดู `Docs/MINIGAME_PREFAB.md`

---

## 2. ที่ไม่ได้แก้ — ฝากทีมตัดสินใจ

| # | เรื่อง | ไฟล์ | ข้อเสนอ |
|---|---|---|---|
| 1 | **ลำดับ enum** `DIAGNOSIS` อยู่ก่อน `BRIEFING` แต่คอมเมนต์และ GDD บอก Briefing = phase 0 | `part_ram.gd` `enum PhaseState` | ถ้าตั้งใจให้ปิ๊บสอนก่อน สลับ 2 บรรทัด + ตั้ง `start_phase` / ค่าเริ่มใน `_ready()` เป็น `BRIEFING` · ถ้าตั้งใจให้สังเกตอาการก่อน ให้แก้คอมเมนต์และ GDD ให้ตรง |
| 2 | **BUG-33** กรณี `SAY` ใน `pib_toggle()` ยังอ่าน `dialog_dict[data.header]` ตรง ๆ | `part_ram.gd` | ใช้ `has()` ดักแบบกรณี `TOAST` · ตอนนี้หัวข้อที่ 3 phase นี้เรียกมีครบใน `Ram_Pib.txt` ทุกหัว จึงยังไม่พังจริง |
| 3 | บท `@DIAGNOSIS_INTRO` · `@DIAGNOSIS_CLUE_SCREEN/SPEAKER/DUST` · `@DIAGNOSIS_HINT` มีในไฟล์บทแต่โค้ดไม่เรียก | `phase_diagnosis.gd` | ใส่ `init()` ให้พูด INTRO · ตอนกดเบาะแสแต่ละอันให้ `toast` บท CLUE ของมัน |
| 4 | สมุดเบาะแสเพิ่ม `Label` เป็นภาษาอังกฤษ `"Screen"` `"Speaker"` `"Case"` | `phase_diagnosis.gd` | เปลี่ยนเป็นข้อความไทย (หรือใช้ภาพ `ui_clue_slot_filled` ดูข้อ 3.2) |
| 5 | `toast()` จบแล้วสั่ง `self.hide()` ทั้ง CanvasLayer — ถ้า toast ขึ้นระหว่างแผงบทพูดเปิดอยู่ แผงบทจะหายไปด้วย | `pib_hint.gd` `_on_timer_timeout()` | ซ่อนเฉพาะ `toast_text` ไม่ต้องซ่อนทั้ง layer · ใน 3 phase นี้ยังไม่ชนกัน |
| 6 | พารามิเตอร์ `mood` ถูกส่งมาแต่ไม่ได้ใช้ — ยังไม่มีรูปปิ๊บบนจอ | `pib_hint.gd` | ดูข้อ 3.3 |

---

## 3. ใส่รูปภาพตาม interface

> ⚠️ `UI_MOCKUP.md` ยังไม่มี mockup ของ phase 0–2 (Mockup 3 เป็น Phase 4 ขั้นทำความสะอาด) · ชื่อและขนาดไฟล์ด้านล่างมาจาก `ASSET_NAMING.md` ตำแหน่งให้จัดใน Editor ตาม GDD 4.2 แล้ววาด mockup เพิ่มถ้าจำเป็น

### 3.1 รูปที่ตอนนี้ใช้ของชั่วคราว → รูปที่ต้องใช้จริง

| Phase | Node ใน `part_ram.tscn` | ตอนนี้ใช้ | ต้องเป็น | canvas | สถานะ |
|---|---|---|---|---|---|
| ทุก phase | `Background` | `MiniGame/PCCaseBG.jpg` | เหมือนเดิม | 1152×648 | 🟢 |
| 0 Diagnosis | `PhaseDiagnosis/ClueScreen` | `PartBios/bios_screen.png` (ยืมของ BIOS + `scale 0.35`) | `PartRam/ram_screen_glitch.png` | 520×340 | 🔴 |
| 0 Diagnosis | `PhaseDiagnosis/ClueSpeaker` | `PartRam/speaker.png` (1024×1024) | `PartRam/ram_speaker_icon.png` | 120×120 | 🟠 เปลี่ยนชื่อ + ย่อ |
| 0 Diagnosis | `PhaseDiagnosis/ClueCase` | `PartMainboard/mb_case_open.png` (ยืมของ Mainboard) | `PartRam/ram_case_dusty.png` | 640×640 | 🔴 |
| 0 Diagnosis | (ยังไม่มี node) ตัวเครื่อง | — | `PartRam/ram_pc_front.png` | 700×800 | 🔴 |
| 0 Diagnosis | `PhaseDiagnosis/ClueNotebook` | VBox เปล่า + Label | `ui_clue_notebook.png` + `ui_clue_slot_empty/filled.png` | 360×280 · 300×70 | 🔴 |
| 1 Briefing | (ยังไม่มี node) ภาพประกอบตอนปิ๊บสอน | — | `ram_diagram_ram_role` · `_gold_contact` · `_dust_block` | 500×300 | 🔴 |
| 2 Power Off | `PhasePoweroff/Shutdown` | `Button` ตัวหนังสือ | `ram_btn_shutdown.png` | 160×160 | 🔴 |
| 2 Power Off | `PhasePoweroff/Unplugged` | `Button` ตัวหนังสือ | `ram_plug_in.png` → สลับเป็น `ram_plug_out.png` | 260×180 (เท่ากันทั้งคู่) | 🔴 |
| 2 Power Off | `PhasePoweroff/TouchCase` | `Button` ตัวหนังสือ | `ram_hand_touch_case.png` | 300×300 | 🔴 |
| ทุก phase | `PibHint` (ยังไม่มี node รูป) | — | `CharacterSprite/char_pib_normal/happy/worry/point.png` | 400×500 | 🟢 มีแล้ว ยังไม่ผูก |

**ถ้ารูปยังไม่เสร็จ** — เล่นได้ด้วยของชั่วคราวเดิม ไม่ต้องรอรูป ทำตามข้อ 3.2 ทีละไฟล์เมื่อรูปมาถึง

### 3.2 วิธีใส่รูปใน Godot (ไม่ต้องแก้โค้ด)

1. **วางไฟล์** ใน `Assets/MiniGame/PartRam/` ตามชื่อในตาราง รอ Godot import แล้ว commit ไฟล์ `.import` คู่กันทุกครั้ง (รูปอยู่ใน Git LFS)
2. **เปลี่ยนรูปของ TextureButton ที่มีอยู่** (ClueScreen / ClueCase) — เลือก node → Inspector → `Textures > Normal` ลากไฟล์ใหม่ใส่ → ตั้ง `Transform > Scale` กลับเป็น `1, 1` (ของเดิมย่อ 0.35 เพราะรูปยืมมาใหญ่เกิน) → ปรับตำแหน่ง
3. **`speaker.png`** — เปลี่ยนชื่อใน **FileSystem dock ของ Godot** (คลิกขวา → Rename) เป็น `ram_speaker_icon.png` Godot จะแก้การอ้างอิงในซีนให้เอง ห้ามเปลี่ยนชื่อใน File Explorer · จากนั้นย่อรูปเป็น 120×120 ในโปรแกรมวาดแล้วเซฟทับ
4. **ปุ่ม Power Off 3 ปุ่ม** — คลิกขวาที่ node → **Change Type** → `TextureButton` · สัญญาณ `pressed` ที่ต่อไว้ยังอยู่ครบ (เช็กในแท็บ Node → Signals) · ใส่ `Textures > Normal` · ถ้าอยากให้มีสถานะกด ใส่ `Pressed`/`Hover` (canvas ต้องเท่ากัน) · ลบ `text` ของปุ่มออก
5. **ปลั๊กเสียบ → ถอด** ต้องสลับรูปหลังกด ตรงนี้ต้องใช้โค้ด 1 บรรทัดใน `_on_unplugged_pressed()` เช่น `$Unplugged.texture_normal = preload("res://Assets/MiniGame/PartRam/ram_plug_out.png")` — **ยังไม่ได้ใส่ ฝากเจ้าของไฟล์**
6. **ภาพ Briefing 3 ภาพ** — เพิ่ม `TextureRect` ใต้ `PhaseBriefing` ได้ แต่ถ้าจะให้ภาพเปลี่ยนตามบรรทัดที่ปิ๊บพูด ต้องต่อ `PibHint.line_finished` — เป็นงานโค้ด ฝากเจ้าของไฟล์
7. กด **F6** (Run Current Scene) บน `part_ram.tscn` เพื่อเทสต์ทันทีโดยไม่ต้องเดินเควสต์ · หรือตั้ง `start_phase` ใน Inspector ของ root เพื่อกระโดดไป phase ที่ต้องการ

### 3.3 รูปปิ๊บตามอารมณ์ (ต้องแก้ `pib_hint.gd` — ยังไม่ได้แก้ เป็นข้อเสนอ)

ใน Editor: เพิ่ม `TextureRect` ชื่อ `PibSprite` ใต้ `PibHint` · ตำแหน่งตาม Mockup 3 คือ `14, 170` ขนาด `170×210` · `Expand Mode = Ignore Size` · `Stretch Mode = Keep Aspect Centered`

แล้วเพิ่มใน `pib_hint.gd`:

```gdscript
@export var mood_textures: Dictionary[Mood, Texture2D] # ผูกรูปใน Inspector
@onready var pib_sprite := $PibSprite as TextureRect

func _set_mood(m: Mood) -> void:
	if mood_textures.has(m):
		pib_sprite.texture = mood_textures[m]
		pib_sprite.show()
```

เรียก `_set_mood(mood)` บรรทัดแรกของ `say()` และ `toast()` · ใน Inspector ผูก `NORMAL → char_pib_normal` · `HAPPY → char_pib_happy` · `WORRY → char_pib_worry` · `POINT → char_pib_point` (`char_pib_neutral` ยังไม่มีอารมณ์ให้ผูก)

---

## 4. เช็กลิสต์เทสต์หลังแก้

- [ ] F6 ที่ `part_ram.tscn` → เริ่มที่ Diagnosis
- [ ] กดเบาะแสครบ 3 อัน → ตัวเลือกสาเหตุขึ้น
- [ ] ตอบผิด → ปิ๊บพูด → คลิกจนจบ → **ยังอยู่ Diagnosis** ตัวเลือกกดได้อีก
- [ ] ตอบถูก → ปิ๊บพูด → คลิกจนจบ → **ไป Briefing** ปิ๊บเริ่มสอน (ไม่ข้าม)
- [ ] Briefing จบ → ไป Power Off
- [ ] กดผิดลำดับ → toast เตือน · กดถูกครบ 3 ขั้น → จอว่าง (ปกติ — Remove ยังไม่ทำ)
- [ ] Debugger → Errors ไม่มี error แดงใหม่

---

## ประวัติเอกสาร

| วันที่ | การเปลี่ยนแปลง |
|---|---|
| 29 ก.ย. 2569 | สร้างเอกสาร · แก้ BUG-36 (3 ไฟล์) · รวมรายการรูปของ phase 0–2 จาก `ASSET_NAMING.md` เทียบกับ node จริงในซีน |
