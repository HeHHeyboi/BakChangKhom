# MINIGAME_PREFAB.md — โครง prefab ของมินิเกม Core Part

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
