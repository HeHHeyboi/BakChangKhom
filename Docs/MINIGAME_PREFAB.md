# MINIGAME_PREFAB.md — โครง prefab ของมินิเกม Core Part

> **30 ก.ย. 2569: เปลี่ยนเป็น 2D ทั้งหมดแล้ว** — ภาพรวมร้าน 2D (Volcano Princess) · ในเคส 2.5D แบบภาพวาด (Lil' Guardsman) · ดู `SCENE_2D.md` · ชื่อคลาส/กล้อง/พิกัด 3 มิติในเอกสารนี้ใช้ไม่ได้แล้ว (Item2D · Socket2D · Stage2D · Phase2D แทน)

> ของที่ต้องใส่ในแต่ละ phase ของ Part RAM ดู `MINIGAME1_PHASE_GUIDE.md` · หักคะแนนจาก phase ใช้ `mistake.emit(&"หมวด", แต้ม)`

> 29 ก.ย. 2569 · Godot 4.7 · ใช้กับ Core Part ทั้ง 5 ตัว (RAM · Mainboard · GPU · Front Panel · BIOS) ที่มีโครง phase + ปิ๊บเหมือนกัน

## โครงไฟล์

```
Scene/MiniGame/
├── PartBase/
│   ├── part_base.tscn     ← ฐาน: Background + PibHint (script PartMinigame)
│   └── pib_hint.tscn      ← prefab ปิ๊บ (แผงบทพูด + toast + timer)
├── part_ram.tscn          ← Inherited Scene จาก part_base.tscn + phase ของ RAM
└── find_item_minigame.tscn

Scripts/MiniGame/
├── part_minigame.gd       ← class PartMinigame: ระบบ phase ทั้งหมด (ย้ายมาจาก part_ram.gd)
├── phase.gd · pib_hint.gd · phase_dialog_parser.gd · minigame_header.gd   (เหมือนเดิม)
└── part_ram/part_ram.gd   ← class PartRam extends PartMinigame: เหลือแค่ enum + รายการ phase

prototype_minigame/        ← ของเก่าที่ไม่ใช้แล้ว (Minigame1.scn) ดู README ในโฟลเดอร์
```

## อะไรอยู่ที่ไหน

| อยู่ใน `PartMinigame` (ใช้ร่วม) | อยู่ในคลาสของแต่ละ Part |
|---|---|
| `pib` · `dialog_path` · `current_phase` · `dialog_dict` · `_mistakes` | `enum PhaseState` ของ Part นั้น |
| `_ready()` — parse บท, ผูกสัญญาณ phase, เริ่ม phase แรก | `_register_phases()` — จับคู่ enum ↔ node |
| `_set_phase()` · `_advance_phase()` · `pib_toggle()` | `_first_phase()` · `_last_phase()` |
| สัญญาณ `phase_changed` · `minigame_finished` | ค่าเริ่ม `_mistakes` · `start_phase` |

## สร้าง Part ใหม่ (เช่น Mainboard)

1. FileSystem → คลิกขวา `Scene/MiniGame/PartBase/part_base.tscn` → **New Inherited Scene** → เซฟเป็น `Scene/MiniGame/part_mainboard.tscn`
2. เปลี่ยน texture ของ `Background` ถ้าฉากต่างจาก RAM
3. สร้างสคริปต์ `Scripts/MiniGame/part_mainboard/part_mainboard.gd`:

```gdscript
class_name PartMainboard extends PartMinigame

enum PhaseState { NONE, DIAGNOSIS, BRIEFING, POWER_OFF, REMOVE, CLEAN, INSTALL, VERIFY, SUMMARY }

@export var start_phase: PhaseState


func _ready() -> void:
	_mistakes = { "diagnosis": 0, "safety": 0, "handling": 0 }
	super._ready()


func _register_phases() -> Dictionary:
	return {
		PhaseState.DIAGNOSIS: $PhaseDiagnosis as Phase,
	}


func _first_phase() -> int:
	return start_phase if start_phase != PhaseState.NONE else PhaseState.DIAGNOSIS


func _last_phase() -> int:
	return PhaseState.SUMMARY
```

4. เลือก root ของซีนใหม่ → Inspector → ลากสคริปต์ใหม่ใส่ช่อง **Script** แทน `part_minigame.gd` · ตั้ง **Dialog Path** เป็นไฟล์บท เช่น `res://Assets/Dialog/MiniGame/Mainboard_Pib.txt`
5. เพิ่ม phase node (Control ที่สคริปต์ `extends Phase`) เป็นลูกของ root · ถ้า phase ต้องรอปิ๊บพูดจบ ต่อสัญญาณ `PibHint.all_lines_finished` จาก Editor แล้ว**ใส่ `if not visible: return` บรรทัดแรกของ handler เสมอ** (ดู BUG-36)
6. ใส่ `scene_path` ของ QuestStep ใน `Resources/main.tres` ชี้มาที่ซีนใหม่

## กฎ

- **แก้ปิ๊บที่ `pib_hint.tscn` ที่เดียว** ทุก Part ได้ผลเหมือนกัน (เช่นเพิ่มรูปปิ๊บตามอารมณ์ ข้อ 3.3 ใน `MINIGAME1_EARLY_PHASES.md`)
- **อย่าแก้ node `Background` / `PibHint` ในซีนลูกถ้าไม่จำเป็น** — ค่าที่แก้ในซีนลูกจะ override ฐาน และจะไม่ได้รับการแก้จากฐานในข้อนั้นอีก
- `current_phase` ใน `PartMinigame` เป็น `int` เทียบกับค่า enum ของแต่ละ Part ได้ตรง ๆ (`current_phase == PhaseState.CLEAN`)
- phase ถัดไปคำนวณจาก `current_phase + 1` — ลำดับใน enum คือลำดับการเล่น

## ที่เปลี่ยนจากโค้ดเดิม (29 ก.ย. 2569)

| เรื่อง | เดิม | ตอนนี้ |
|---|---|---|
| ระบบ phase | อยู่ใน `part_ram.gd` | ย้ายไป `part_minigame.gd` · พฤติกรรมเหมือนเดิมทุกบรรทัด |
| PibHint | node ใน `part_ram.tscn` | prefab `PartBase/pib_hint.tscn` instance อยู่ใน `part_base.tscn` |
| path บท | `@export var RAM_PIB_PATH` | `@export_file var dialog_path` ในฐาน · `PartRam.RAM_PIB_PATH` เป็น const สำรอง |
| BUG-33 | `SAY` อ่าน `dialog_dict[...]` ตรง ๆ | เช็ก `has()` ก่อนทั้ง `SAY` และ `TOAST` |
| `Minigame1.scn` | `Scene/MiniGame/` | `prototype_minigame/` |
| uid ของ `part_ram.tscn` | `uid://bbcfansu05shj` | **เหมือนเดิม** — `main.tres` ไม่ต้องแก้ |

ทดสอบด้วย Godot 4.7 headless: ไล่ Diagnosis (ตอบผิด/ถูก) → Briefing → Power Off ได้ผลเหมือนก่อน refactor ทุกขั้น

> **ถ้าเพื่อนเปิด `part_ram.tscn` ค้างใน Editor อยู่** ให้ปิดแท็บแล้วเปิดใหม่ก่อนแก้ต่อ ไม่งั้น Editor จะเซฟเวอร์ชันเก่าทับ

## ฉาก 3D สำหรับแนว 2.5D (วางแผน 29 ก.ย. 2569)

Core Part ทั้ง 5 จะเปลี่ยนเป็น 2.5D — **เฉพาะ play area** (860×420) เป็น `SubViewportContainer` ที่มีฉาก 3D ส่วนแถบหัวข้อ / info rail / ปิ๊บ ยังเป็น 2D เหมือนเดิม · Player และฉากเดินไม่เปลี่ยน

| ของใหม่ | ที่อยู่ | ใช้ทำอะไร |
|---|---|---|
| `part_stage_2d.tscn` | `Scene/MiniGame/PartBase/` | SubViewport + กล้อง 3/4 + แสง + เคส · instance เพิ่มเข้า Part ที่ต้องการ ไม่ต้องแก้ `part_base.tscn` |
| `Socket2D` · `Item2D` | `Scripts/MiniGame/PartBase/scene2d/` | จุดติดตั้ง + ชิ้นที่ลากได้ · snap ด้วย raycast |
| `PcPart` | `Scripts/Resources/pc_part.gd` | ข้อมูลชิ้นส่วน (socket · ต้องมีก่อน · ทิศ · Part ที่ผูก) |

สร้างครั้งแรกในมินิเกม Tutorial ประกอบคอม — ดูสเปกเต็มใน `TUTORIAL_ASSEMBLY_DESIGN.md` หัวข้อ 2 และ 5 · ระบบ phase / ปิ๊บ / คะแนนเดิมใช้ได้ทั้งหมด

### ✅ ชุดร่วม 3D (อัปเดต 29 ก.ย. 2569 — Part RAM ใช้จริงครบ 8 phase)

ไฟล์อยู่ที่ `Scripts/MiniGame/PartBase/scene2d/` และ `Scene/MiniGame/PartBase/part_stage_2d.tscn` · **ตัวอย่างการใช้จริงดูที่ `Scene/MiniGame/PartRam/part_ram.tscn`** (ต้นแบบ `Test/stage3d_ram_demo` ลบแล้ว)

| คลาส | หน้าที่ |
|---|---|
| `Stage2D` | ฉาก 3D · กล้องหน่วงนุ่ม (`smoothing`) · `go_to(&"มุม")` · `focus_on()` · ลาก/snap นุ่ม (`drag_smoothing`) · `allowed` (ชิ้นที่คลิกได้) · `allowed_sockets` · เรืองแสงตอนเมาส์ชี้ |
| `Item2D` (@tool) | `STATIC` / `DRAGGABLE` / `TOGGLE` / `CLICK` · `size_override` / `color_override` / `texture_override` (ใช้ .tres เดียวหลายขนาด) · `add_overlay()` ชั้นฝุ่น · `set_texture()` |
| `Socket2D` (@tool) | จุดติดตั้ง · Locks · Start Occupant |
| `View2D` (@tool) | มุมกล้องสำเร็จรูป (ตำแหน่ง = จุดโฟกัส · yaw · pitch · distance) — วางใต้ `World/Views` |
| `Phase2D` | ฐานของ phase ในฉาก 3D: `listen()` (ถอดสัญญาณเองตอนจบ) · `cam()` · `allow()` · `allow_sockets()` · `say()` · `toast()` · `rail_button()` · `finish()` |

**สัญญาณ `Stage2D`:** `part_picked` · `part_installed` · `part_removed` · `part_returned` · `drop_rejected` · `part_toggled` · `part_clicked` · `view_changed`

**ทำ Part ใหม่:** คัดลอกโครง `part_ram.tscn` → เปลี่ยนของใน `Stage/Views` + มุมใน `Views` → เขียน phase ที่ extends `Phase2D` (ดู `RAM_3D_GAMEPLAY.md` ข้อ 7)

### Stage2D — View style (30 ก.ย.)
`lock_yaw`, `fixed_yaw`, `orthographic`, `transparent_background`, `pan_limits` + ฟังก์ชัน `pan(dx)` · Item2D มี `TOON`/`OUTLINE_PX` ใช้ shader `Scripts/MiniGame/PartBase/scene2d/toon_outline.gdshader` · ถ้าเปิด `transparent_background` ให้ตั้งรูปใน `Background` ของ part_base (ดู RAM_3D_GAMEPLAY.md)

### สมุดคู่มือ + โหมดสถานี (30 ก.ย. ครั้งที่ 2)
ทุก phase ที่เรียก `PhaseUI.make_frame()` ได้ไอคอนสมุด + เป้าหมายบนหัวข้ออัตโนมัติ ไม่ต้องเขียนเพิ่ม · `Stage2D.station_mode` = กล้องตายตัวต่อสถานี · `Phase2D.SAY_MAX_LINES` = จำกัดบรรทัดที่ปิ๊บพูด (ที่เกินไปสมุด) — รายละเอียดใน RAM_3D_GAMEPLAY.md

### ห้องใช้ร่วม + การ์ดชิ้นส่วน (30 ก.ย. ครั้งที่ 3)
- `Scene/MiniGame/PartBase/workshop_room.tscn` = ห้อง diorama (พื้น ผนัง หน้าต่าง ชั้น ขาโต๊ะ) → instance ใต้ `Stage/Views` ชื่อ `Room` · Part RAM + Tutorial ประกอบใช้ตัวนี้
- `PhaseUI.part_card(phase, title, body, footer, rect = CARD_RECT, timer_enable = true)` การ์ดกระดาษ (ค่าเริ่มต้นมุมซ้ายล่าง · ส่ง `rect` เพื่อย้ายที่) · `timer_enable` = จางหายเองด้วย tween `modulate:a` หลังครบ 3 วินาที · `hide_card(phase)`
- `GuideMarker` เป็นซีน `PartBase/guide_marker.tscn` (สี `col_ring` `col_ink` `col_paper` · `text` · `radius` ปรับใน Editor ได้) สร้างด้วย `GuideMarker.create()` · `flip_below` = ลูกศร/ป้ายไปอยู่ใต้วงกลม (ตั้งจาก `Item2D.hint_flip` โดย `Phase2D.hint()`)
- Socket2D ที่เป็นลูกของชิ้นส่วน (เช่นช่องบนเมนบอร์ด) ขยับตามชิ้นได้ และไม่ถูกนับตอนถือชิ้นนั้นอยู่

### ปุ่มย้อนกลับ + สลับมุมกล้อง (30 ก.ย. ครั้งที่ 4) — `ViewNav`
- `Scripts/MiniGame/PartBase/view_nav.gd` แถบบนซ้ายของฉาก: **◀ กลับ** (ขึ้นเมื่อมีมุมก่อนหน้า) + ปุ่มมุมกล้อง · มุมที่อยู่ตอนนี้สีส้ม
- คีย์ลัดกลับ: **Esc / Backspace / ปุ่มข้างเมาส์** (ไม่ทำงานตอนสมุดคู่มือเปิด — สมุดอยู่กลุ่ม `modal`)
- ปุ่มมาจาก **`View2D.label`** — ตั้งชื่อ = มีปุ่ม · ว่าง = มุมซูมย่อย (เช่นลำโพง/สล็อตใกล้) ออกด้วย "กลับ"
  - Part RAM: ภาพรวม · จอ · ในเคส · เมนบอร์ด · ปลั๊กพ่วง · แผ่นรอง ESD
  - Tutorial ประกอบ: ภาพรวม · ชิ้นส่วน · ในเคส · หน้าเคส · จอ
- `Stage2D`: `current_view` · `can_back()` · `back()` · `clear_history()` · `nav_views()` · สัญญาณ `view_name_changed` · `go_to(view, instant, record)`
- `Phase2D.nav_enabled = false` ซ่อนแถบ (ใช้ในช่วงปิ๊บสอนแรม + หน้าสรุปทั้งสองมินิเกม) · จบ phase = ล้างประวัติมุม
- สร้างเองตอน phase เรียก `cam()` ครั้งแรก ไม่ต้องวางในซีน
