# MINIGAME1_PHASE_GUIDE.md — คู่มือสร้าง phase ของมินิเกม Part RAM

> ⚠️ **30 ก.ย. 2569: Part RAM เป็น 2D แล้ว** — phase ทั้ง 8 อยู่ใน `Scripts/MiniGame/PartRam/` (extends `Phase2D`) เล่นได้ครบทุก phase · UI placeholder ในเอกสารนี้ถูกแทนด้วยฉาก 2D (`Stage2D`/`View2D`/`Item2D`) · ดูของปัจจุบันที่ `SCENE_2D.md` · กติกา/คะแนน/บทปิ๊บในเอกสารนี้ยังใช้ได้ · ตารางสถานะด้านล่างเป็นของ 29 ก.ย. (ตอนนี้ทุก phase ✅)

> 29 ก.ย. 2569 · ใช้คู่กับ `MINIGAME1_DESIGN.md` (กติกา/เหตุผลดีไซน์) · `MINIGAME_PREFAB.md` (โครง prefab) · `ASSET_NAMING.md` (ขนาดไฟล์)
> เอกสารนี้ตอบคำถามเดียว: **แต่ละ phase ต้องใส่อะไรลงไปบ้าง** (node · สคริปต์ · บทปิ๊บ · การหักคะแนน · รูป · เงื่อนไขจบ)

สถานะ: ✅ เล่นได้แล้ว · 🟡 มีโครงบางส่วน · ⬜ ยังเป็น stub

| # | Phase | enum | node | สคริปต์ | สถานะ |
|---|---|---|---|---|---|
| 0 | สังเกตอาการ | `DIAGNOSIS` | `PhaseDiagnosis` | `phase_diagnosis.gd` | ✅ + บท INTRO/CLUE + หักคะแนน + ใบ้ (29 ก.ย.) |
| 1 | ปิ๊บสอน | `BRIEFING` | `PhaseBriefing` | `phase_briefing.gd` | ✅ (ขาดภาพประกอบ) |
| 2 | ตัดไฟ | `POWER_OFF` | `PhasePoweroff` | `phase_poweroff.gd` | ✅ + รีเซ็ต + หักคะแนน (29 ก.ย.) |
| 3 | ถอดแรม | `REMOVE` | `PhaseRemove` | `phase_remove.gd` | 🟢 เล่นได้ · UI เบื้องต้น |
| 4 | ทำความสะอาด | `CLEAN` | `PhaseClean` | `phase_clean.gd` | 🟢 เล่นได้ · UI เบื้องต้น · อุปกรณ์ 10 `.tres` |
| 5 | ใส่กลับ | `INSTALL` | `PhaseInstall` | `phase_install.gd` | 🟢 เล่นได้ · UI เบื้องต้น |
| 6 | ตรวจผล | `VERIFY` | `PhaseVerify` | `phase_verify.gd` | 🟢 เล่นได้ · UI เบื้องต้น |
| 7 | สรุป | `SUMMARY` | `PhaseSummary` | `phase_summary.gd` | 🟢 เล่นได้ · ปิดซีน + เดินเควสต์ต่อ |

🟢 = โค้ดครบตามดีไซน์ แต่หน้าตาเป็น placeholder (กล่องสี/ปุ่มตัวหนังสือ) สร้างจากโค้ดด้วย `Scripts/MiniGame/PartBase/phase_ui.gd` ตามเลย์เอาต์ `STORYBOARD.md` หัวข้อ 0 · ภาพตัวอย่าง `Docs/Mockups/phase_placeholder_preview.png`

---

## 0. กติกากลาง — ทุก phase ต้องทำแบบนี้

1. **สคริปต์ `extends Phase`** (stub ทั้ง 5 ไฟล์แก้และผูกเข้า node ให้แล้ว 29 ก.ย.) · node ใน `part_ram.tscn` มีครบแล้วทั้ง 8 ตัว — ใส่ลูกใต้ node นั้น · node Remove–Summary ตอนนี้ขนาด 40×40 ให้กด **Layout → Full Rect** ก่อนวางของ
2. **รีเซ็ต state ทั้งหมดใน `init()`** — `init()` ถูกเรียกทุกครั้งที่เข้า phase (ต้องเล่นซ้ำได้โดยไม่ค้างค่ารอบก่อน) · ใน `init()` ให้ `show()` แล้วสั่งปิ๊บพูดบทเปิด phase
3. **จบ phase ด้วย `phase_completed.emit()` เท่านั้น** — ห้ามเรียก `_set_phase()` เอง · `PartMinigame` จะเลื่อนไป `current_phase + 1` ให้ (deferred)
4. **ปิ๊บ** — ส่งผ่านสัญญาณเท่านั้น: `pib_toggle.emit(PibHint.Data.say(MinigameHeader.X))` (คลิกไปทีละบรรทัด) หรือ `PibHint.Data.toast(MinigameHeader.X)` (ขึ้นแล้วหายเอง 3 วิ) · ใช้ const จาก `MinigameHeader` ห้ามพิมพ์สตริงเอง
5. **ถ้าต้องรอปิ๊บพูดจบ** ต่อ `PibHint.all_lines_finished` จาก Editor (แท็บ Node → Signals) แล้ว**บรรทัดแรกของ handler ต้องเป็น `if not visible: return`** (BUG-36)
6. **หักคะแนน** — `mistake.emit(&"หมวด", แต้ม)` (สัญญาณใหม่ใน `phase.gd` · `PartMinigame` สะสมใน `_mistakes` ให้) · หมวด: `diagnosis` `safety` `tools` `handling` `tidiness`
7. **ลงทะเบียน** — uncomment บรรทัดของ phase นั้นใน `_register_phases()` ของ `part_ram.gd` เมื่อพร้อมเทสต์ · ยังไม่ลงทะเบียน = จอว่างหลัง phase ก่อนหน้า (ปกติ)
8. **เทสต์เร็ว** — root `part_ram` → Inspector → **Start Phase** เลือก phase ที่กำลังทำ → F6
9. **ขนาดจอ 1152 × 648** · ข้อความบนปุ่มใส่เป็น `Label`/`text` ไม่ฝังในรูป · รูปยังไม่มีให้ใช้ `ColorRect` หรือ `Button` ตัวหนังสือแทนไปก่อน อย่ารอรูป

โครงสคริปต์ขั้นต่ำ:

```gdscript
extends Phase

func init():
	# รีเซ็ต state ของ phase นี้ตรงนี้
	show()
	pib_toggle.emit(PibHint.Data.say(MinigameHeader.REMOVE))

func _finish():
	hide()
	phase_completed.emit()
```

---

## Phase 0 · DIAGNOSIS ✅ — เหลือเก็บงาน

| ต้องเพิ่ม | ทำยังไง |
|---|---|
| บทเปิด | `init()` → `say(DIAGNOSIS_INTRO)` |
| บทต่อเบาะแส | ใน `_on_clue_*_pressed()` → `say(DIAGNOSIS_CLUE_SCREEN / _SPEAKER / _DUST)` แทนการเพิ่ม Label อังกฤษ (หรือทำทั้งคู่ แต่ Label เป็นภาษาไทย) |
| นับตอบผิด | ตอบผิดแต่ละครั้ง `mistake.emit(&"diagnosis", 10)` (ต่ำสุด 0 — SUMMARY clamp ให้) · ผิดครบ 3 ครั้ง → `say(DIAGNOSIS_HINT)` |
| ปุ่มสาเหตุ disabled จนกว่าจะดูครบ 3 เบาะแส | ตอนนี้ซ่อนไว้ด้วย `choices.hide()` ใช้ได้เหมือนกัน |

✅ แก้แล้ว — ~~`@DIAGNOSIS_HINT` ผิด~~ (อ่านไฟล์ผิดเอง ขออภัย) ที่ผิดจริงคือ `@UNSAFE_TOUCH_CASE` เขียนชื่อ `ปิ๊ป, ` → แก้เป็น `ปิ๊บ,` แล้ว

รูป: `ram_screen_glitch` · `ram_speaker_icon` · `ram_case_dusty` · `ram_pc_front` · `ui_clue_notebook` (ดู `MINIGAME1_EARLY_PHASES.md` ข้อ 3.1)

## Phase 1 · BRIEFING ✅ — เหลือภาพประกอบ

- เพิ่ม `TextureRect` ชื่อ `Diagram` กลางจอ (ภาพ 500×300) · ต่อ `PibHint.line_finished` → เปลี่ยนภาพตามบรรทัด: บรรทัด 2 `ram_diagram_ram_role` · บรรทัด 4 `ram_diagram_gold_contact` · บรรทัด 5 `ram_diagram_dust_block` (นับบรรทัดเองด้วยตัวแปร `_line` รีเซ็ตใน `init()`)
- **ปุ่มข้าม** (รอบเล่นซ้ำ) — ต้องมี Save System (`tutorial_seen`) ก่อน · ข้ามได้ตอนนี้

⚠️ **ลำดับ enum**: ตอนนี้ `DIAGNOSIS` (1) มาก่อน `BRIEFING` (2) แต่ดีไซน์ให้ปิ๊บสอนก่อน — **ตัดสินใจกับทีมก่อนเริ่ม phase 3** เพราะลำดับ enum คือลำดับการเล่น

## Phase 2 · POWER_OFF ✅ — เหลือหักคะแนน

- กดผิดลำดับ (`UNSAFE_UNPLUG` / `UNSAFE_TOUCH_CASE`) → เพิ่ม `mistake.emit(&"safety", 12)`
- `init()` ต้องรีเซ็ต `step = [Step.SHUTDOWN, Step.UNPLUGGED, Step.TOUCH_CASE]` (ตอนนี้ตั้งค่าตอนประกาศตัวแปรอย่างเดียว เล่นซ้ำจะ error `front()` บน array ว่าง)
- สลับรูปปลั๊กหลังถอด: `$Unplugged.texture_normal = preload(".../ram_plug_out.png")` (เมื่อเปลี่ยนเป็น TextureButton แล้ว)

---

## Phase 3 · REMOVE ⬜ — ถอดแรม

**เป้าหมาย:** ปลดสลักซ้าย + ขวา → ลากแรมขึ้นตรง ๆ ≥ 80 px

**Node ใต้ `PhaseRemove`**

```
PhaseRemove (Control, full rect 1152×648)
├── Slot        TextureRect   ram_slot_empty.png (560×90) — กลางจอ
├── ClipLeft    TextureButton ram_clip_closed.png (70×120) → ram_clip_open.png
├── ClipRight   TextureButton เหมือนซ้าย (flip_h = true)
└── Ram         TextureRect   ram_dirty.png (600×214) วางทับบน Slot · mouse_filter = STOP
```

**สคริปต์**

| ฟังก์ชัน | ทำอะไร |
|---|---|
| `init()` | `_left_open = false` · `_right_open = false` · วาง `Ram` กลับตำแหน่งเดิม · `say(REMOVE)` |
| `_on_clip_left_pressed()` / `_right` | ตั้ง flag + เปลี่ยน texture เป็น open |
| `_gui_input` ของ `Ram` (ต่อสัญญาณ `gui_input`) | กดเมาส์ = จำ `_drag_start` · ลาก = ขยับ `Ram.position.y` ตามเมาส์ (ล็อกแกน x) · ปล่อย = ตรวจเงื่อนไขด้านล่าง |

**เงื่อนไขตอนปล่อยเมาส์**

| กรณี | ผล | ปิ๊บ | หักคะแนน |
|---|---|---|---|
| สลักยังปิดข้างใดข้างหนึ่ง | `Ram` เด้งกลับ (Tween) + สั่นเล็กน้อย | `toast(REMOVE_FORCE)` | `handling` −5 (ครั้งแรกครั้งเดียว) |
| ลากเอียง (เมาส์เบี่ยงแกน x > 40 px ระหว่างลาก) | เด้งกลับ | `toast(REMOVE_TILTED)` | `handling` −5 (ครั้งแรกครั้งเดียว) |
| สลักเปิดทั้งคู่ + ลากขึ้น ≥ 80 px + ไม่เอียง | ✅ `_finish()` | — | — |

> ใช้ `_input` ธรรมดาได้ถ้าจับ `gui_input` ไม่ถนัด แต่ต้องเช็ก `visible` ก่อนเสมอ

## Phase 4 · CLEAN 🟡 — ทำความสะอาด (phase ใหญ่สุด)

**เป้าหมาย:** 3 ขั้นย่อย S1 ปัดฝุ่นบนแผง → S2 ขัดขาทอง → S3 ทำความสะอาดสลอต · แต่ละขั้นเลือกอุปกรณ์จากถาด 6 ชิ้น (สุ่มจาก 10)

**ต้องทำก่อน: ข้อมูลอุปกรณ์ 10 ไฟล์** — สร้าง `Resources/Parts/Ram/Tools/*.tres` (คลิกขวา → New Resource → `CleanTool`) ตามตาราง `MINIGAME1_DESIGN.md` หัวข้อ 14.4 · `icon` ใช้ `PartRam/ram_tool_*.png` ที่มีครบแล้ว · `fit_per_step` key 0/1/2 = S1/S2/S3 · value 0/1/2 = ❌/🟡/✅ · บทปิ๊บใส่ใน `line_*` หรืออ้าง header ใน `Ram_Pib.txt` (`CLEAN_S2_ERASER` · `CLEAN_SANDPAPER` · …)

**Node ใต้ `PhaseClean`** (ตาม Mockup 3 `Docs/Mockups/ui_mock_03_minigame_ram.png`)

```
PhaseClean
├── Target      TextureRect  ram_dirty → ram_better → ram_clean (600×214 เท่ากัน) · S3 เปลี่ยนเป็น ram_slot_empty
├── StepLabel   Label        "ขั้นที่ 1/3 · ปัดฝุ่นบนแผง"
├── CleanBar    ProgressBar  0–100
├── Tray        TextureRect  ram_tray.png 🔴 (ยังเสีย ใช้ Panel แทน)
│   └── Slots   HBoxContainer — สร้าง TextureButton 6 ปุ่มจาก _build_tray() ตอนรัน
└── ToolCard    Panel        ui_tool_card.png 🔴 · ชื่อ + ▮▯ ความแข็ง + ไอคอน 4 ตัว (โชว์ตอน hover ปุ่มอุปกรณ์)
```

**สคริปต์ (เติมโครงที่มีอยู่)**

| ฟังก์ชัน | ทำอะไร |
|---|---|
| `init()` | โหลด `_tools` จากโฟลเดอร์ Tools · `_step = DUST_BOARD` · `_progress = 0` · `_blocked_once.clear()` · `say(CLEAN_TRAY)` · `_show_step()` |
| `_build_tray(step)` | สุ่ม 6 ชิ้น การันตี ✅ ≥ 1 และ ❌ ≥ 2 |
| hover ปุ่ม (`mouse_entered`) | เติม `ToolCard` จากค่าใน `CleanTool` |
| `_on_tool_used(tool, step)` | ✅ → progress +34 · 🟡 → +17 และ `mistake(&"tools", 3)` · ❌ ครั้งแรก → ของกลับถาด + `mistake(&"tools", 8)` · ❌ ชิ้นเดิมครั้งที่ 2 → `mistake(&"tools", 8)` + ตั้ง `damaged = true` (ใช้ใน VERIFY) |
| ถูรัว ๆ (S2) | นับคลิก เกิน 22 → `toast(CLEAN_OVERDONE)` + `mistake(&"handling", 3)` ครั้งเดียว |
| progress ≥ 100 | ขั้นถัดไป + `_build_tray()` ใหม่ · ครบ S3 → `say(CLEAN_DONE)` → รอปิ๊บจบ → `_finish()` |

> ถ้าอยากได้ของเล่นได้เร็ว: ทำ S2 ขั้นเดียวด้วยยางลบก่อน (กลไกคลิกถูเดิม) แล้วค่อยเติมถาดทีหลัง

## Phase 5 · INSTALL ⬜ — ใส่กลับ

**Node:** `Slot` (เหมือน Phase 3) · `Ghost` TextureRect `ram_ghost.png` 🔴 (เงาโปร่งบอกจุดวาง — แทนด้วย `modulate.a = 0.3` ของ `ram_clean` ได้) · `Ram` `ram_clean.png` วางด้านบนจอ · `ClipLeft/Right` สถานะ open · ปุ่ม `Flip` (หมุนแรม 180°)

| ขั้น | ผล | ปิ๊บ / คะแนน |
|---|---|---|
| `init()` | สุ่มให้แรมเริ่ม**กลับด้าน**หรือไม่ก็ได้ (`_flipped`) · `say(INSTALL)` | — |
| ลากแรมไปใกล้ Ghost < 30 px | ถ้า `_flipped` → แรมแดงจาง (`modulate`) วางไม่ลง | `toast(INSTALL_FLIPPED)` |
| วางตรงร่อง | snap ลงตำแหน่ง Ghost | — |
| กดแรม 2 ครั้ง | สลักเปลี่ยนเป็น closed + (เสียงคลิกเมื่อมี AudioManager) → `_finish()` | — |
| กดครั้งเดียวแล้วกดไปต่อ (ถ้าทำปุ่ม "เสร็จ") | บันทึก `seated = false` | `tidiness` −10 ตอน VERIFY |

## Phase 6 · VERIFY ⬜ — ตรวจผล

**Node:** `Plug` TextureButton `ram_plug_out → ram_plug_in` · `PowerBtn` TextureButton `ram_btn_shutdown.png` (ใช้รูปเดียวกันเป็นปุ่มเปิด) · `Screen` TextureRect `ram_screen_normal` / `ram_screen_glitch` · `Timer` 2 วิ

| ขั้น | ผล |
|---|---|
| `init()` | จอดับ · ปลั๊กถอดอยู่ |
| เสียบปลั๊ก → กดเปิด → รอ 2 วิ | ถ้า CLEAN ไม่ `damaged` และ INSTALL `seated` → `ram_screen_normal` + `say(VERIFY)` → รอจบ → `_finish()` |
| ไม่ผ่าน | `ram_screen_glitch` + บอกให้กลับไปแก้ — **ย้อน phase ยังไม่มีใน PartMinigame** รอบแรกให้แค่แสดงผลแล้วไปต่อ แต่หักคะแนนไปแล้ว |

> ⚠️ `VERIFY_NO_POWER_CUT` (ลืมถอดปลั๊ก) **เกิดไม่ได้ในโค้ดตอนนี้** เพราะ Power Off บังคับลำดับไว้ — ข้ามบทนี้ได้ เว้นแต่ทีมจะเปลี่ยน Phase 2 ให้ข้ามขั้นได้
> ข้อมูลข้าม phase (`damaged` · `seated`) — เก็บไว้ที่ root: `get_parent().set_meta("ram_damaged", true)` หรือเพิ่มตัวแปรใน `part_ram.gd` แล้วอ่านด้วย `owner.ram_damaged`

## Phase 7 · SUMMARY ⬜ — สรุป

**Node:** `Card` Panel (`ui_quest_panel.png` ใช้ซ้ำได้) · `Learned` Label 3 บรรทัด · `Scores` VBox 5 แถว · `Stars` HBox 3 × TextureRect (`ui_star_full/empty` 🔴 ใช้ ★☆ ตัวอักษรไปก่อน) · `BackBtn` Button "กลับไปที่ห้อง"

**คำนวณคะแนน** (อ่าน `owner._mistakes`):

```gdscript
const FULL := { &"diagnosis": 30, &"safety": 25, &"tools": 25, &"handling": 10, &"tidiness": 10 }

func _score() -> int:
	var total := 0
	for k in FULL:
		total += max(FULL[k] - owner._mistakes.get(k, 0), 0)
	return total   # ผ่าน ≥ 60 · ดาว 1/2/3 ที่ 60 / 80 / 95
```

| ขั้น | ทำอะไร |
|---|---|
| `init()` | เติมการ์ด · `say(SUMMARY)` |
| `BackBtn` | `phase_completed.emit()` → `PartMinigame._advance_phase()` เห็นว่าเป็น `_last_phase()` → emit `minigame_finished(_mistakes)` |

> ⚠️ **ยังไม่มีใครฟัง `minigame_finished`** — ต้องต่อไปที่ `EventManager.minigame_end()` เพื่อเดินเควสต์ต่อ แล้วปิดซีนเอง แบบเดียวกับ `find_item_minigame.gd` บรรทัด 22–23 · เพิ่มใน `_ready()` ของ `part_ram.gd` ก่อน `super._ready()`:
>
> ```gdscript
> minigame_finished.connect(func(_score): EventManager.minigame_end(); call_deferred("queue_free"))
> ```

---

## ลำดับที่แนะนำ

1. ตัดสินใจลำดับ enum (Phase 1) — storyboard เรียง INSPECT → BRIEF ตรงกับ enum ตอนนี้แล้ว
2. **Phase 7 SUMMARY แบบง่าย** (แค่ปุ่มกลับ + ต่อ `minigame_finished`) → เล่นจบลูปได้ตั้งแต่ต้น แล้วค่อยเติม phase ตรงกลาง
3. Phase 3 REMOVE → Phase 5 INSTALL (กลไกลากคล้ายกัน เขียนต่อกันง่าย)
4. Phase 4 CLEAN (ทำ `.tres` 10 ไฟล์ก่อน)
5. Phase 6 VERIFY → เติมคะแนนใน SUMMARY
6. เปลี่ยน placeholder เป็นรูปจริงตาม `ASSET_NAMING.md`

## สิ่งที่แก้ในโค้ดแล้ว (29 ก.ย. 2569) เพื่อรองรับคู่มือนี้

| ไฟล์ | เปลี่ยน |
|---|---|
| `Scripts/MiniGame/PartBase/phase.gd` | เพิ่ม `signal mistake(category: StringName, points: int)` |
| `Scripts/MiniGame/PartBase/part_minigame.gd` | ต่อ `mistake` ทุก phase → `_on_mistake()` สะสมใน `_mistakes` |
| `Scripts/MiniGame/PartRam/part_ram.gd` | `_mistakes` เปลี่ยนเป็น 5 หมวดตามหัวข้อ 9 (ค่า = แต้มที่ถูกหัก) |
| `phase_remove/install/verify/summary.gd` · `phase_clean.gd` | `extends Control` + `signal phase_completed` → `extends Phase` |
| `Scene/MiniGame/PartRam/part_ram.tscn` | ผูกสคริปต์ 5 ไฟล์ข้างบนเข้า node `PhaseRemove`–`PhaseSummary` (เดิม node ไม่มีสคริปต์) |

ทดสอบ headless: uncomment ครบ 8 phase → กระโดดไป SUMMARY → กดจบ → `minigame_finished` ส่ง `_mistakes` ถูกต้อง และซีนปิดตัวเองได้ด้วยโค้ดในหัวข้อ Phase 7


---

## โค้ด phase 3–7 + UI เบื้องต้น (29 ก.ย. 2569 ครั้งที่ 3)

ทุกจุดที่แก้ในโค้ดเพื่อนมีคอมเมนต์ `# [Claude 29 ก.ย.]` กำกับ — ค้นใน Godot ด้วย Ctrl+Shift+F คำว่า `[Claude`

| ไฟล์ | ของใคร | เปลี่ยน |
|---|---|---|
| `Scripts/MiniGame/PartBase/phase_ui.gd` | ใหม่ | ตัวช่วยสร้าง UI placeholder ตาม storyboard (แถบหัวข้อ · info rail · เช็กลิสต์ · ปุ่ม · กล่องแทนรูป) |
| `PartRam/phase_remove.gd` · `phase_install.gd` · `phase_verify.gd` · `phase_summary.gd` | stub เดิม → เขียนใหม่ | โค้ดเต็มตามตารางหัวข้อ Phase 3, 5, 6, 7 ด้านบน |
| `PartRam/phase_clean.gd` | เพื่อน (โครง) | เติมฟังก์ชันที่เป็น `pass` · ชื่อ enum/signal/ฟังก์ชันเดิมคงไว้ |
| `Resources/Parts/Ram/Tools/*.tres` | ใหม่ | อุปกรณ์ 10 ชิ้นตาม `MINIGAME1_DESIGN.md` 14.4 · ไอคอน `PartRam/ram_tool_*.png` (ยางลบขาวใช้ `ram_eraser.png`) |
| `PartRam/part_ram.gd` | เพื่อน | เปิดใช้ phase 3–7 · ตัวแปร `ram_damaged` / `ram_seated` · `_on_minigame_finished()` ปิดซีนแบบ `find_item_minigame.gd` |
| `PartRam/phase_diagnosis.gd` | เพื่อน | `init()` รีเซ็ต + บท INTRO · ป้ายเบาะแสเป็นไทย + บท CLUE · ตอบผิด −10 · ผิด 3 ครั้งใบ้ |
| `PartRam/phase_poweroff.gd` | เพื่อน | `init()` รีเซ็ตลำดับ · กดผิดลำดับ −12 safety · กันกดหลังจบ |
| `Scripts/MiniGame/PartBase/pib_hint.gd` | เพื่อน | `_on_timer_timeout()` ไม่ซ่อนแผงบทพูดที่เปิดอยู่ (แก้ข้อ 5 ใน `MINIGAME1_EARLY_PHASES.md`) |
| `Assets/Dialog/MiniGame/Ram_Pib.txt` | เพื่อน | `@UNSAFE_TOUCH_CASE` ชื่อ `ปิ๊ป, ` → `ปิ๊บ,` |

**ทดสอบ (Godot 4.7 headless + ถ่ายภาพจอจริง):** เล่นครบ 8 phase — Diagnosis ตอบผิด 1 (−10) → Briefing → Power Off แตะเคสก่อน (−12) → Remove ฝืนดึงตอนสลักล็อก (−5) แล้วปลดสลักดึงผ่าน → Clean เลือก ❌ ชิ้นเดิม 2 ครั้ง (−16 + เสียหาย) แล้วทำ S1–S3 ด้วยชิ้น ✅ → Install วางถูกด้านแล้วกด "เสร็จแล้ว" ก่อนสลักดีด → Verify บูตไม่ผ่าน (−10) → Summary 47/100 ☆☆☆ → กดกลับห้อง ซีนปิดเอง

**ข้อจำกัดที่รู้อยู่**

- UI สร้างจากโค้ด ไม่เห็นใน Editor ตอนไม่รัน — จะย้ายมาเป็น node ในซีนทีหลังก็ได้ ใช้ตำแหน่งจากโค้ดเป็นแบบ
- ยังไม่มีการย้อน phase — Verify ไม่ผ่านก็ไปสรุปต่อ (หักคะแนนแล้ว)
- `CLEAN_OVERDONE` ยังไม่ใช้ (ใช้อุปกรณ์ทีละคลิก ไม่มีการถูรัว) · ปุ่ม "รอให้แห้ง" ของ IPA ยังไม่มี
- Briefing ยังไม่มีภาพประกอบ · ไม่มีเสียง (รอ AudioManager)
- ตัวอักษรสัญลักษณ์ (☐ ☑ ★ ▮) ใช้ฟอนต์ระบบ ถ้าเครื่องไหนไม่มีจะขึ้นเป็นกล่อง
