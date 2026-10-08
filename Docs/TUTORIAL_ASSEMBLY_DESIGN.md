# TUTORIAL_ASSEMBLY_DESIGN.md — มินิเกม Tutorial: ประกอบคอมพิวเตอร์ (2.5D)

> **30 ก.ย. 2569: เปลี่ยนเป็น 2D ทั้งหมดแล้ว** — ภาพรวมร้าน 2D (Volcano Princess) · ในเคส 2.5D แบบภาพวาด (Lil' Guardsman) · ดู `SCENE_2D.md` · ชื่อคลาส/กล้อง/พิกัด 3 มิติในเอกสารนี้ใช้ไม่ได้แล้ว (Item2D · Socket2D · Stage2D · Phase2D แทน)

> 29 ก.ย. 2569 · Godot 4.7 · GL Compatibility · จอ 1152 × 648
> สถานะ: **มีเวอร์ชันเล่นได้แล้ว (30 ก.ย.)** — ดูหัวข้อ "สถานะโค้ด 30 ก.ย." ท้ายไฟล์ · ClickUp: [🎓 [FEAT] Tutorial: ประกอบคอมพิวเตอร์ (2.5D)](https://app.clickup.com/t/z93r0b50zc)
> เอกสารคู่กัน: `ART_25D_PLAN.md` (วิธีทำโมเดล) · `MINIGAME_PREFAB.md` (โครง prefab) · `REPAIR_FLOW.md` (S2 ถอด / S4 ประกอบกลับ ใช้ฉาก 3D ชุดเดียวกัน) · `STORYBOARD.md` หัวข้อ 0.5

---

## 1. ตำแหน่งในเกมและเป้าหมาย

```
Prologue → Tutorial พื้นฐาน (เดิน · คุย · แผนที่ — งาน ClickUp "เพิ่ม Tutorial Scene")
        → ★ Tutorial ประกอบคอม (เอกสารนี้)
        → งานซ่อมแรก: Core Part RAM → Mainboard → GPU → Front Panel → BIOS
```

| ข้อ | รายละเอียด |
|---|---|
| **ทำไมต้องมี** | ผู้เล่นยังไม่รู้จักชิ้นส่วนเลย ถ้าเริ่มที่ขัดแรมเลยจะไม่รู้ว่าแรมอยู่ตรงไหนในเครื่องและทำหน้าที่อะไร |
| **สอนอะไร** | ชื่อ + หน้าที่ + ตำแหน่งของชิ้นส่วนหลัก 9 ชิ้น · ลำดับการประกอบที่ถูก · ความปลอดภัยพื้นฐาน (ESD / ถอดปลั๊ก) |
| **ผูกกับ Core Part** | ทุกชิ้นที่ติดตั้งเสร็จจะขึ้นการ์ด "ชิ้นนี้คุณจะได้ซ่อมใน Part ___" — ปูทางให้ Part ทั้ง 5 |
| **โหมด** | Tutorial = **ไม่มีสอบตก** · ผิดแล้วปิ๊บอธิบาย ให้ทำใหม่ · มีคะแนน "ความเข้าใจ" ไว้ดูเฉย ๆ |
| **เวลาเล่น** | 6–8 นาที · เล่นซ้ำได้จากเมนู (ข้าม INTRO ได้) |
| **Player** | ไม่เกี่ยว — ฉากเดินยังเป็น 2D เหมือนเดิม มินิเกมเปิดทับเป็นซีนแยกแบบ Part RAM |

---

## 2. แนวภาพ 2.5D (ใช้กับ Core Part ทั้ง 5 ด้วย)

```
┌──────────────── แถบหัวข้อ 2D (y 0–56) ────────────────────────┐
├──────────────────────────────────────────┬─────────────────────┤
│  PLAY AREA = SubViewport 3D  860 × 420   │  INFO RAIL 2D       │
│  ┌────────────────────────────────────┐  │  • ขั้นตอน          │
│  │  เคสนอนตะแคง ฝาเปิด มุมกล้อง 3/4   │  │  • ถาดชิ้นส่วน       │
│  │  ◇ socket เรืองแสงตอนลากชิ้นเข้าใกล้ │  │    (ลากออกมาวาง)    │
│  └────────────────────────────────────┘  │  • การ์ดชิ้นส่วน     │
├──────────────────────────────────────────┴─────────────────────┤
│  แถบปิ๊บ 2D (PibHint เดิม)                        y 476–648    │
└────────────────────────────────────────────────────────────────┘
```

| เรื่อง | ตัดสินใจ | เหตุผล |
|---|---|---|
| ชั้น 3D | **เฉพาะ play area** ใน `SubViewportContainer` | UI · rail · ปิ๊บ ใช้ของ 2D เดิมได้หมด |
| ชิ้นส่วน | **กล่องบาง / แผ่นแปะ PNG** (`BoxMesh` + `StandardMaterial3D`) ไม่ปั้นโมเดล | ทีมเป็นสาย 2D · มีรูปชิ้นส่วนอยู่แล้วหลายชิ้น (ดูข้อ 8) |
| เคส | `CSGBox3D` ต่อกันเป็นกล่องเปิดด้านข้าง (placeholder) → ภายหลังเปลี่ยนเป็น `.glb` low-poly ได้ | เริ่มได้ทันทีไม่ต้องรอ asset |
| กล้อง | Perspective FOV 35° มองลง 3/4 · หมุนได้ ±25° ด้วยคลิกขวาลาก หรือปุ่ม ⟲ ⟳ ใน rail · ซูม 2 ระดับ | เห็นความลึกตอนเสียบ แต่ไม่หลงทิศ |
| แสง | `DirectionalLight3D` 1 ดวง + `WorldEnvironment` ambient · ไม่ใช้เงาแบบหนัก | GL Compatibility + export เว็บ |
| สเกล | 1 หน่วย = 10 ซม. (เคส ATX ≈ 4.5 × 2.1 × 4.3) | ค่าตัวเลขอ่านง่าย |

---

## 3. Flow

| # | enum | ชื่อ | ผู้เล่นทำอะไร | ปิ๊บสอน |
|---|---|---|---|---|
| 0 | `INTRO` | แนะนำโต๊ะ | คลิกชิ้นส่วนบนถาดทีละชิ้น (ยังไม่วาง) → ขึ้นการ์ดชื่อ/หน้าที่ | "คอมหนึ่งเครื่องมีของหลัก ๆ แค่ไม่กี่ชิ้น" |
| 1 | `SAFETY` | เตรียมตัว | ใส่สายรัดข้อมือ ESD · วางแผ่นรอง · ยืนยันว่า PSU ยังไม่เสียบปลั๊ก | ไฟฟ้าสถิต · ห้ามต่อไฟระหว่างประกอบ |
| 2 | `BUILD` | ติดตั้งชิ้นส่วน | ลากชิ้นจากถาดลง socket ตามลำดับในข้อ 4 (9 ขั้น) | ก่อน/หลังแต่ละชิ้น (ข้อ 6) |
| 3 | `CABLES` | ต่อสาย | ลากหัวสายไปเสียบ: 24-pin · CPU 8-pin · PCIe · SATA · Front panel (แบบง่าย) | สายไหนไปไหน · สาย CPU 8-pin ≠ PCIe 8-pin |
| 4 | `CLOSE` | ปิดฝา | เช็กลิสต์ 4 ข้อ (ปิ๊บอ่าน) → ลากฝาข้างปิด | ตรวจก่อนปิดเสมอ |
| 5 | `POWER_TEST` | ทดสอบ | เสียบปลั๊ก → กดเปิด → จอขึ้นโลโก้ BIOS | "เครื่องติดแล้ว ต่อไปเราจะได้ซ่อมของจริง" |
| 6 | `SUMMARY` | สรุป | การ์ด 9 ชิ้น ↔ Part ที่จะได้ซ่อม · ปุ่มไปงานแรก | ปูทางเข้า Part RAM |

> `BUILD` เป็น **phase เดียวที่วนตามข้อมูล** (data-driven) ไม่ต้องเขียน phase แยก 9 ตัว — เพิ่ม/สลับชิ้นได้ด้วยการแก้ `.tres`

---

## 4. ลำดับติดตั้ง (BUILD)

| ขั้น | ชิ้นส่วน | socket | ต้องมีก่อน | จุดที่ผิดได้ | ผูก Core Part |
|---|---|---|---|---|---|
| 1 | Standoff × 4 | รูบนแผ่นเคส | — | ลืมใส่ → ขั้น 3 วางไม่ได้ (ปิ๊บบอกว่าเมนบอร์ดจะช็อตกับเคส) | Mainboard |
| 2 | PSU | ช่องล่างหลังเคส | — | หันพัดลมผิดทาง (หมุนก่อนวาง) | GPU (สายไฟ) |
| 3 | เมนบอร์ด | บน standoff | 1 | — | Mainboard |
| 4 | CPU | socket บนเมนบอร์ด | 3 | หันผิดมุม (สามเหลี่ยมทองต้องตรง) · ลืมเปิดก้านล็อก | Mainboard |
| 5 | ซิลิโคน + ฮีตซิงก์ | บน CPU | 4 | ข้ามซิลิโคน → ปิ๊บเตือน (แบบง่าย: กดปุ่มหยด 1 ครั้ง) | Mainboard |
| 6 | RAM × 2 | สล็อต A2 / B2 | 3 | กลับด้าน (ร่องบาก) · ใส่สล็อตติดกัน → ปิ๊บบอก dual channel | RAM · Front Panel (dual channel) |
| 7 | SSD / HDD | ช่อง M.2 หรือถาด 2.5" | 3 | — | BIOS (ลง OS) |
| 8 | การ์ดจอ | สล็อต PCIe x16 บนสุด | 3 | ลืมถอดแผ่นปิดช่องหลังเคส · ใส่สล็อตล่าง | GPU |
| 9 | พัดลมเคส | หน้า/หลัง | — | หันลมผิด (ลูกศร airflow) | GPU (airflow) |

**กฎตรวจตอนปล่อยชิ้น (`Socket2D.accepts()`)**

1. ชิ้นนี้เข้ากับ socket นี้ไหม (RAM ใส่ PCIe ไม่ได้) → ไม่ → ชิ้นเด้งกลับถาด + toast บอกว่าชิ้นนี้ควรไปตรงไหน
2. ชิ้นที่ต้องมีก่อนติดตั้งแล้วหรือยัง → ยัง → ขวางไว้พร้อมเหตุผล
3. ทิศถูกไหม (`yaw` ต้องตรงกับ socket) → ผิด → ชิ้นแดงจาง วางไม่ลง
4. ผ่านทั้งหมด → snap ลง + เสียงคลิก + การ์ด "ชิ้นนี้คุณจะได้ซ่อมใน Part ___"

---

## 5. สเปกโค้ด

### 5.1 ไฟล์

```
Scene/MiniGame/PartBase/
├── part_base.tscn           (มีแล้ว)
└── part_stage_2d.tscn       🆕 SubViewportContainer + SubViewport + Camera3D + แสง + CaseRoot
Scene/MiniGame/tutorial_assembly.tscn   🆕 Inherited จาก part_base.tscn + instance part_stage_3d

Scripts/MiniGame/
├── part_minigame.gd · phase.gd · phase_ui.gd · pib_hint.gd   (มีแล้ว ใช้ต่อ)
├── stage3d/
│   ├── part_stage_3d.gd     🆕 กล้อง · ยิง ray จากเมาส์ · ลาก · snap
│   ├── socket_3d.gd         🆕 class_name Socket2D extends Area3D
│   └── part_body_3d.gd      🆕 class_name Item2D extends Node3D (ชิ้นที่ลากได้)
├── Resources/pc_part.gd     🆕 class_name PcPart extends Resource
└── tutorial_assembly/
    ├── tutorial_assembly.gd 🆕 extends PartMinigame (enum PhaseState ตามข้อ 3)
    └── phase_intro.gd · phase_safety.gd · phase_build.gd · phase_cables.gd · phase_close.gd · phase_power_test.gd · phase_summary.gd

Resources/Tutorial/Parts/*.tres   🆕 PcPart 9–12 ไฟล์
Assets/Dialog/MiniGame/Assembly_Pib.txt   🆕 บทปิ๊บแบบ @SECTION → รัน gen_constant.py ใหม่
```

### 5.2 Resource ชิ้นส่วน

```gdscript
class_name PcPart extends Resource

@export var id: StringName              # &"cpu"
@export var display_name: String        # "ซีพียู (CPU)"
@export_multiline var role: String      # "สมองของเครื่อง คิดคำนวณทุกอย่าง"
@export var icon: Texture2D             # รูปบนถาด (2D)
@export var texture: Texture2D          # แปะบนหน้า mesh ใน 3D
@export var size: Vector3               # ขนาดกล่อง (หน่วย 10 ซม.)
@export var socket_type: StringName     # &"cpu_socket"
@export var requires: Array[StringName] # [&"mainboard"]
@export var needs_orientation := false  # ต้องหมุนให้ถูกทิศก่อนวาง
@export var core_part: StringName       # &"mainboard" → การ์ด "จะได้ซ่อมใน Part ___"
@export var pib_before: String          # header ใน Assembly_Pib.txt
@export var pib_wrong_socket: String
@export var pib_wrong_order: String
@export var pib_wrong_orientation: String
```

### 5.3 การลากใน 3D (สรุปกลไก)

1. `SubViewportContainer.stretch = true` · รับ `gui_input` แล้วแปลงพิกัดเมาส์เป็นพิกัดใน SubViewport
2. `camera.project_ray_origin()` / `project_ray_normal()` → ตัดกับระนาบ y = ความสูงของ socket ที่กำลังเล็ง → ได้ตำแหน่งลาก
3. ระหว่างลาก หา `Socket2D` ที่ใกล้สุดภายใน 0.6 หน่วย → เรืองแสง (เขียว = ใส่ได้ / แดง = ผิด)
4. ปล่อย → `socket.accepts(part, installed_ids, yaw)` → คืน `OK` / `WRONG_SOCKET` / `WRONG_ORDER` / `WRONG_ORIENTATION`
5. หมุนชิ้นก่อนวาง: ปุ่ม `R` หรือปุ่ม ⟳ ใน rail ทีละ 90° (ใช้กับ CPU · PSU · พัดลม)

### 5.4 คะแนน (โหมด Tutorial)

ใช้ `mistake.emit()` เดิม แต่ **ไม่มีผ่าน/ไม่ผ่าน** — หน้าสรุปแสดงเป็น "ความเข้าใจ" 3 ดาว

| หมวด | เต็ม | หัก |
|---|---|---|
| `safety` | 30 | ข้าม ESD −10 · เสียบปลั๊กก่อนปิดฝา −20 |
| `order` | 40 | ติดตั้งผิดลำดับ −4 / ครั้ง |
| `handling` | 30 | ผิดทิศ −5 · ผิด socket −3 |

---

## 6. บทปิ๊บ (ร่าง — ใส่ `Assets/Dialog/MiniGame/Assembly_Pib.txt`)

```
@INTRO
ปิ๊บ,วันนี้ยังไม่ต้องซ่อมอะไรนะขม มาประกอบเครื่องใหม่ด้วยกันก่อน
ปิ๊บ,คอมหนึ่งเครื่องมีของหลัก ๆ แค่ไม่กี่ชิ้น ลองกดดูทีละชิ้นบนถาดสิ

@SAFETY
ปิ๊บ,ก่อนจับชิ้นส่วนใส่สายรัดข้อมือก่อน ไฟฟ้าสถิตในตัวเรามองไม่เห็นแต่ทำชิปพังได้
ปิ๊บ,แล้วอย่าเพิ่งเสียบปลั๊ก PSU จนกว่าจะปิดฝาเสร็จนะ

@BUILD_STANDOFF
ปิ๊บ,น็อตตัวเล็ก ๆ พวกนี้เรียกว่า standoff ยกเมนบอร์ดให้ลอยจากแผ่นเหล็ก ไม่งั้นช็อต

@BUILD_CPU
ปิ๊บ,ดูสามเหลี่ยมสีทองที่มุมซีพียู ต้องตรงกับมุมที่มีสามเหลี่ยมบน socket
ปิ๊บ,วางลงเบา ๆ ห้ามกด ขาเล็ก ๆ ใน socket งอง่ายมาก

@BUILD_RAM
ปิ๊บ,นี่แหละแรม ชิ้นแรกที่เราจะได้ซ่อมจริง ๆ ดูร่องบากก่อนเสียบนะ

@WRONG_ORDER
ปิ๊บ,เดี๋ยวก่อน ชิ้นนี้ต้องรอให้อีกชิ้นเข้าที่ก่อน

@POWER_TEST
ปิ๊บ,เครื่องติดแล้ว ต่อไปเวลามีคนเอาเครื่องมาซ่อม เราจะรู้แล้วว่าแต่ละชิ้นอยู่ตรงไหน
```

---

## 7. สิ่งที่ต้องแก้ในระบบเดิม

| ไฟล์ | แก้อะไร | กระทบของเดิม |
|---|---|---|
| `Resources/main.tres` | เพิ่ม QuestStep `MINIGAME` ชี้ `tutorial_assembly.tscn` **ก่อน** step ของ Part RAM | ลำดับเควสต์ |
| `Scripts/global.gd` | เพิ่ม `tutorial_assembly_done: bool` (รอ Save System) | ไม่กระทบ |
| `part_base.tscn` | ไม่แก้ — ฉาก 3D เป็น prefab แยก instance เฉพาะ Part ที่ใช้ | Part RAM เดิมไม่เปลี่ยน |
| `phase_ui.gd` | เพิ่ม `tray()` สำหรับถาดชิ้นส่วนใน rail (ใช้ซ้ำกับ Part อื่น) | เพิ่มอย่างเดียว |
| `project.godot` | ไม่ต้องเปลี่ยน renderer · ความละเอียดเดิม | — |
| Player / ฉากเดิน | **ไม่แก้** | — |

**Core Part ทั้ง 5 ใช้ `part_stage_2d.tscn` เดียวกันได้ภายหลัง** เช่น RAM phase Remove/Install · GPU เสียบ PCIe · Mainboard วาง CPU — ทำ Tutorial นี้ก่อนจะได้ระบบ 3D ที่ Part อื่นยืมใช้

---

## 8. Asset

**มีแล้ว ใช้เป็น texture ได้เลย:** `mb_mainboard` · `mb_cpu` · `mb_cooler` · `mb_standoff` · `mb_socket_open/closed` · `mb_thermal_dot` · `ram_clean` · `gpu_card` · `gpu_psu` · `gpu_pcie_slot` · `gpu_cable_24pin` · `gpu_cable_pcie` · `fp_pin_header` · `tool_esd_strap` (ภาพยังผิด) · `tool_esd_mat`

**ต้องทำเพิ่ม** (ชื่อตามกฎ `ASSET_NAMING.md` · prefix `asm_`)

| ไฟล์ | ขนาด | ใช้ |
|---|---|---|
| `asm_case_side.png` · `asm_case_floor.png` | 1024 × 1024 | ผิวเคส (แปะบน CSG) |
| `asm_ssd_m2.png` | 512 × 128 | SSD |
| `asm_case_fan.png` | 512 × 512 | พัดลมเคส + ลูกศร airflow |
| `asm_io_shield.png` | 512 × 160 | แผ่นหลังเคส |
| `asm_socket_glow.png` | 256 × 256 | วงแสงบอก socket |
| `asm_part_card.png` | 320 × 200 | การ์ดชิ้นส่วนใน rail |
| `asm_bios_logo.png` | 1152 × 648 | จอตอนเปิดติด |

---

## 9. ลำดับการทำ

| ขั้น | งาน | ทดสอบได้ |
|---|---|---|
| 1 | ✅ `Stage2D` (สร้างจากโค้ด ไม่ต้องมี .tscn) + กล้องหมุนได้ · ⬜ เคส CSG | เห็นฉาก 3D ใน play area |
| 2 | ✅ `PcPart` + `Item2D` + `Socket2D` + ลาก/snap — ต้นแบบ `Test/stage3d_ram_demo.tscn` | ลาก RAM ลงสล็อตได้ ✅ |
| 3 | `phase_build.gd` + `.tres` 9 ชิ้น + กฎ 4 ข้อ | ประกอบครบได้ |
| 4 | INTRO · SAFETY · CABLES (แบบง่าย) · CLOSE · POWER_TEST · SUMMARY | เล่นจบลูป |
| 5 | `Assembly_Pib.txt` + ต่อ `main.tres` | เล่นต่อจาก prologue ได้ |
| 6 | เปลี่ยน texture เป็นรูปจริง + เสียง | พร้อมโชว์ |

## 10. Test case

- [ ] ลาก RAM ไปที่ PCIe → เด้งกลับ + ปิ๊บบอกตำแหน่งที่ถูก
- [ ] ลากเมนบอร์ดก่อนใส่ standoff → วางไม่ได้ + เหตุผล
- [ ] CPU หันผิดมุม → แดง วางไม่ลง · หมุนแล้ววางได้
- [ ] เสียบปลั๊กก่อนปิดฝา → หัก safety แต่เกมไม่ค้าง
- [ ] หมุนกล้องสุดทั้งสองทาง → ยังลาก/วางถูกตำแหน่ง
- [ ] เล่นจบ → กลับห้อง · เควสต์เดินไป Part RAM
- [ ] export เว็บ → ฉาก 3D แสดงได้ (GL Compatibility)


---

## สถานะโค้ด 30 ก.ย. 2569 (เวอร์ชันแรกที่เล่นได้)

**เปิดเทส:** รันซีน `Scene/MiniGame/TutorialAssembly/tutorial_assembly.tscn` ตรง ๆ (F6) · **ผูกเข้าเควสต์หลักแล้ว (commit `65bddbf`)** — `Resources/main.tres` step ที่ 4 ใน 6 step (index 3 · MINIGAME, `scene_path` = ซีนนี้) ต่อจากหายางลบ และอยู่ก่อน tutorial/มินิเกมแรม · จบซีนแล้ว `tutorial_assembly.gd` ตั้ง `Global.in_minigame = false` และเรียก `EventManager.minigame_end()` · บทปิ๊บอยู่ `Assets/Dialog/MiniGame/Assembly_Pib.txt`

**ย่อ flow เหลือ 4 phase** (ตัด SAFETY / CABLES / CLOSE ไว้ทำรอบหลัง)

| # | enum | ไฟล์ | ผู้เล่นทำอะไร |
|---|---|---|---|
| 1 | `INTRO` | `phase_intro.gd` | คลิกชิ้นบนแผ่นรองครบ 7 ชิ้น → การ์ดกระดาษ ชื่อ · หน้าที่ · "จะได้ซ่อมใน Part ___" |
| 2 | `BUILD` | `phase_build.gd` | ลากชิ้นลงเคส · ผิดช่อง/ผิดลำดับ → เด้งกลับ + ปิ๊บบอกเหตุผล (ไม่หักคะแนน) · ไกด์ชี้ชิ้นถัดไป + socket เรืองแสง |
| 3 | `POWER_TEST` | `phase_power.gd` | กดปุ่มหน้าเคส → LED ติด → จอบูตผ่าน |
| 4 | `SUMMARY` | `phase_summary.gd` | ตาราง ชิ้นส่วน → Part ที่จะได้ซ่อม · ปุ่ม "ไปงานซ่อมแรก" |

**โครงโหนด** (`tutorial_assembly.tscn` สืบทอด `part_base.tscn`)
```
TutorialAssembly (tutorial_assembly.gd)
├── Background · PibHint                 (จาก part_base)
├── Stage (part_stage_2d.tscn)
│   └── SubViewport/World
│       ├── Workbench (override ขนาดโต๊ะ) · Room (workshop_room.tscn ใช้ร่วมกับ Part RAM)
│       ├── PcCase    CaseFloor/Rear/Side/Bottom/Bezel · %PowerButton · %PowerLed · PsuBay · MbStandoff (Socket2D)
│       ├── %Monitor · MonitorStand · MonitorNeck · EsdMat (แผ่นรองวางชิ้น)
│       ├── %Parts    ★ ลำดับลูก = ลำดับประกอบ: %Psu → %Mainboard → %Cpu → %Cooler → %Ram → %Ssd → %Gpu
│       │   └── Mainboard/ CpuSocket · CoolerMount · RamSlot · M2Slot · PcieSlot  (ติดไปกับบอร์ด)
│       └── Views     Overview · Tray · Build · Front · Monitor (View2D)
└── PhaseIntro · PhaseBuild · PhasePower · PhaseSummary (Control)
```

**ข้อมูล = PcPart .tres** (`Resources/Parts/Common/`) — ใหม่: `cpu` · `cpu_cooler` · `gpu` · `ssd_m2` · เพิ่ม `socket_type`/`core_part` ให้ `psu` · `pib_wrong_socket` ให้ `mainboard`
- กฎวาง = `socket_type` ต้องตรง + `requires` ต้องติดตั้งก่อน (Socket2D.check) · ข้อความผิด = `pib_wrong_order` / `pib_wrong_socket` → หัวข้อใน `Assets/Dialog/MiniGame/Assembly_Pib.txt`
- เพิ่ม/สลับชิ้น = ใส่ Item2D ใต้ `Parts` + Socket2D ที่ตรง `socket_type` (ไม่ต้องแก้โค้ด)
- ชื่อ Part บนการ์ด = `TutorialAssembly.CORE_NAME`

**ของที่แก้ในชุดกลาง:** `Stage2D` ไม่นับ socket ที่ติดมากับชิ้นในมือ · `PhaseUI.part_card()` (จางหายเองใน 3 วิ · PhaseIntro วางที่ y=450) / `hide_card()` · `Item2D.hint_flip` (ตั้ง true ที่ Psu · Mainboard · Cpu · Cooler ให้ป้ายไกด์ไปอยู่ใต้วงกลม · PhaseIntro แสดงไกด์หลังไม่ทำอะไร 3 วิ) · แยกห้องออกเป็น `workshop_room.tscn` (Part RAM ใช้ตัวเดียวกันแล้ว)

**โค้ดทดลอง 2D ของเพื่อน** (`Test/assembly.tscn`, `part.gd`, `place.gd` — HeHHeyboi) **ไม่ได้แตะ** · แนวคิด `Place.PlaceType` = `Socket2D.socket_type` ในเวอร์ชัน 2.5D นี้

**ยังไม่ทำ:** SAFETY (สายรัด ESD) · CABLES · CLOSE · หันทิศ CPU/แรม (ตอนนี้ไม่เช็กทิศ) · ซิลิโคน · รูปจริงของ SSD


## ติดตั้งแบบท่าจริง (ขั้นประกอบ) — [Claude 9 ต.ค. 2569]

วางชิ้นลงช่องแล้วชิ้นจะ **ลอยค้างเหนือช่อง** (ขยาย 7% + ยกขึ้น 10 px) เหมือน Part RAM แล้วผู้เล่นทำท่าของชิ้นนั้น 1 จังหวะ · บทฝึกไม่หักคะแนน

| ช่อง | ท่า | หมายเหตุ |
|---|---|---|
| PSU | ดันเข้าช่อง → ขันน็อต 4 ตัว | ทแยงมุม |
| เมนบอร์ด | วางตรงเสารอง → ขันน็อต 4 มุม | กดน็อตผิดคิว = ปิ๊บเตือน ไม่ขัน |
| CPU | วางลงเองเบา ๆ → กดคันล็อก | สอน "ห้ามกดซีพียู" |
| ฮีตซิงก์ | ขันน็อต 4 ตัวทแยงมุม | แรงกดเท่ากัน |
| แรม | กดค้าง QTE (`ram_press.tres`) → "คลิก! สลักล็อก" | แบบเดียวกับ Part RAM · พลาด 3 ครั้งปิ๊บช่วย |
| การ์ดจอ | กดค้าง QTE → "คลิก!" → น็อตแผ่นยึด 1 ตัว | |
| SSD M.2 | เสียบเอียง 22° → กดปลายลง → น็อต 1 ตัว | |

แก้ท่า/จุดน็อตได้ที่ `Scripts/MiniGame/TutorialAssembly/phase_build.gd` (`SEAT` · จุดน็อตเป็นสัดส่วน 0–1 ของกรอบชิ้น เรียงตามลำดับขัน) · ตัวกด `SeatTarget` (`seat_target.gd`: SCREW · LEVER · PUSH) · ทดสอบ `Test/assembly_test.tscn`

ขนาดชิ้นส่วนตามของจริง: ถาด ~0.85 px/มม. · ในเคส ~0.75 px/มม. (คิดจากส่วนที่มีภาพ ไม่นับขอบโปร่งใส)

### ภาพชุดใหม่ + "ภาพประกอบแล้ว" — [Claude 9 ต.ค. 2569]

- ภาพทั้งหมดของบทฝึกอยู่ที่ `Assets/MiniGame/TutorialAssembly/` วาดด้วยโค้ด `src/gen_asm.py` (Python + Pillow) สไตล์เวกเตอร์เส้นขอบ มองจากด้านบน ขนาดเป็นมิลลิเมตรจริง
- แผ่นรอง (มุม Tray) 0.85 px/มม. · ในเคส (มุม Build) 0.75 px/มม. · ภาพฉากวาด 2 เท่า (`bg_scale = 0.5`)
- ชิ้นที่หน้าตาต่างกันตอนเสียบแล้ว ใช้ `looks`: PSU → `asm_psu_side` · แรม → `asm_ram_edge` (look `mini`) · การ์ดจอ → `asm_gpu_edge`
- ใส่เสร็จแล้ว `TutorialAssembly.show_installed(p)` → ภาพ `asm_layer_<ชิ้น>.png` (ขนาดเท่ามุม Build) จางเข้า แล้วซ่อนชิ้นที่ลอย · ครบ 7 ชิ้น `show_cables()`
- ย้าย socket ในมุม Build ต้องแก้ `SOCK` ใน gen_asm.py แล้วสร้างภาพใหม่ (ภาพประกอบแล้ววาดตามตำแหน่ง socket) · จุดน็อต `SEAT_PTS` ต้องตรงกับ `SEAT` ใน phase_build.gd

### เปิดเครื่อง → ทำความรู้จัก ขมOS — [Claude 9 ต.ค. 2569]

เลเวลแรกเป็นงานบนจอ (LEVEL_DESIGN ข้อ 3) จึงให้รู้จัก OS ตั้งแต่บทฝึก: กดปุ่มเปิดเครื่อง → ปิ๊บ ASM_POWER_OK → **ขมOS ทับทั้งจอ** (`TutorialAssembly.open_os_tour()` · `DesktopMinigame.tour_mode`) → ปิดเครื่อง → ปิ๊บ ASM_OS_DONE → ขั้นสรุป

| ขั้น | ทำอะไร | ปิ๊บสอน |
|---|---|---|
| 1 | ดับเบิลคลิก "เอกสาร" | ไฟล์แยกเก็บเป็นโฟลเดอร์ |
| 2 | ลูกโลกที่แถบงาน | เบราว์เซอร์ · ระวังปุ่มโฆษณา |
| 3 | เฟืองที่แถบงาน | ดูพื้นที่ · ถอนโปรแกรม |
| 4 | คลิกขวา "ไฟล์ทดสอบ.doc" → ลบ | ลบแล้วไปอยู่ถังขยะ |
| 5 | ถังขยะ → ล้างถังขยะ | ไฟล์หายจริง พื้นที่กลับมา |
| 6 | ปุ่มเริ่ม → ปิดเครื่อง | — |

ทำไม่เรียงก็นับ · ยังไม่ครบปิดเครื่องไม่ได้ · ปุ่ม "ข้ามการแนะนำ" บนโน้ต · ขั้น/ข้อความแก้ที่ `TOUR` ใน `desktop_minigame.gd` · ไฟล์ในเครื่องแก้ที่ `Resources/Desktop/Free/os_tour.tres`

- [9 ต.ค.] ฮีตซิงก์วาดใหม่ให้ขอบชัด (ขอบโลหะสว่าง · ใบพัดฟ้าอ่อน · ขาจับมีแขนต่อ · เงาเข้มขึ้น) เดิมสีเทาเข้มกลืนกับบอร์ด/แผ่นรอง — ชิ้นอื่นสีเข้มที่อาจต้องทำแบบเดียวกัน: การ์ดจอ · PSU
