# RAM_3D_GAMEPLAY.md — เกมเพลย์ Part RAM แบบ 2.5D (ครบ 8 phase)

> **30 ก.ย. 2569: เปลี่ยนเป็น 2D ทั้งหมดแล้ว** — ภาพรวมร้าน 2D (Volcano Princess) · ในเคส 2.5D แบบภาพวาด (Lil' Guardsman) · ดู `SCENE_2D.md` · ชื่อคลาส/กล้อง/พิกัด 3 มิติในเอกสารนี้ใช้ไม่ได้แล้ว (Item2D · Socket2D · Stage2D · Phase2D แทน)

> 29 ก.ย. 2569 · Godot 4.7 · GL Compatibility · จอ 1152 × 648
> ซีน: `Scene/MiniGame/PartRam/part_ram.tscn` (uid เดิม `uid://bbcfansu05shj` — `main.tres` ไม่ต้องแก้)
> เอกสารคู่กัน: `MINIGAME1_DESIGN.md` (กติกา/คะแนน) · `MINIGAME_PREFAB.md` (ระบบฉาก 3D) · `ART_25D_PLAN.md` (แนวภาพ)
> ทดสอบ: เล่นอัตโนมัติครบ 8 phase ด้วย Godot 4.7 + ถ่ายภาพจอจริงทุก phase — ผ่าน ไม่มี error

---

## 1. ภาพรวม

```
┌──────── แถบหัวข้อ 2D ("ซ่อมแรม — ขั้นที่ n/8") ─────────────┐
├────────── ฉาก 3D (Stage 860 × 420) ─────────┬── info rail 2D ─┤
│ โต๊ะช่าง: เคสนอนตะแคง (ฝากระจก) · จอ · แผ่น ESD │ เช็กลิสต์ · ปุ่ม │
│ กล้องเลื่อนเองไปจุดที่ต้องทำ (นุ่ม ๆ)         │ ถาดเครื่องมือ    │
├──────────────────────────────────────────────┴────────────────┤
│ แถบปิ๊บ 2D (PibHint)                                          │
└───────────────────────────────────────────────────────────────┘
```

- **กล้องอัตโนมัติ** — ทุกขั้นกล้องเลื่อนไปมุมที่ต้องทำเอง (`cam(&"ชื่อมุม")`) · ผู้เล่นยังหมุนเองได้ตลอด (คลิกขวาลาก · ล้อ · Q/E · Home)
- **ของที่คลิกได้เรืองแสงฟ้าเมื่อเมาส์ชี้** · แต่ละขั้นคลิกได้เฉพาะของที่เกี่ยว (`allow([...])`)
- **ชิ้นที่ถือ + กล้อง ขยับแบบหน่วงนุ่ม** (`smoothing` / `drag_smoothing` ใน node `Stage`)

## 2. Flow 8 phase

| # | Phase | ผู้เล่นทำ | กล้อง (อัตโนมัติ) | หักคะแนน |
|---|---|---|---|---|
| 1 | DIAGNOSIS | คลิก **จอ** (ภาพค้าง) · **ลำโพงบนเมนบอร์ด** (วงเสียงบี๊บ) · **ฝากระจก** (ดูฝุ่นในเคส) → เลือกสาเหตุใน rail | Overview → Monitor / Speaker / Inside | ตอบผิด −10 · ผิด 3 ครั้งปิ๊บใบ้ |
| 2 | BRIEFING | ฟังปิ๊บ (แรมเรืองแสง) | Slots + หมุนรอบช้า ๆ | — |
| 3 | POWER_OFF | คลิก **Shut down** บนจอ → **ปลั๊กหลังเครื่อง** → **โครงเคส** | Monitor → Rear → Inside | ผิดลำดับ −12 safety |
| 4 | REMOVE | คลิก **ฝากระจก** (เลื่อนออก) → กาง **สลัก 2 ข้าง** → ลาก **แรม** ไปวางบน **ขาตั้งบนแผ่น ESD** | Inside → Slots → Carry → Mat | ดึงตอนล็อก −5 handling (ครั้งเดียว) |
| 5 | CLEAN | เลือกอุปกรณ์จากถาด 6 ชิ้นใน rail ทีละขั้น: S1 ฝุ่นบนแผง · S2 ขาทอง · S3 สล็อต | Mat → MatGold → SlotClose | 🟡 −3 · ❌ −8 · ❌ ซ้ำ = เสียหาย |
| 6 | INSTALL | ลากแรมกลับลงสล็อต (บางรอบวางกลับด้าน — R หมุน) → **คลิกแรม 2 ครั้ง** ให้สลักล็อก → หรือกด "เสร็จแล้ว" | Mat → Carry → Slots | ใส่ไม่สุด → −10 ตอน VERIFY |
| 7 | VERIFY | คลิก **ปลั๊ก** เสียบกลับ → **ปุ่มเปิดหน้าเคส** → รอ 2 วิ ดูจอ | Rear → Front → Monitor | ใส่ไม่สุด −10 tidiness |
| 8 | SUMMARY | การ์ดคะแนน 5 หมวด + ดาว → "กลับไปที่ห้อง" | Overview | — |

ผลที่เห็นในฉาก: ฝุ่นบนแรมจางลง · ขาทองจากหมองเป็นวาว · ฝุ่นในสล็อตหาย · ไฟ LED หน้าเคสดับ/ติด · ปลั๊กเลื่อนออก/เข้า · จอเปลี่ยนภาพ (ค้าง → เดสก์ท็อป → ดับ → บูตผ่าน/ค้าง)

---

## 3. โครงไฟล์ (จัดใหม่ 29 ก.ย.)

```
Scene/MiniGame/
├── PartBase/                 ← ของกลางที่ทุก Core Part ใช้
│   ├── part_base.tscn        (Background + PibHint + ระบบ phase)
│   ├── pib_hint.tscn
│   └── part_stage_2d.tscn    (ฉาก 3D: SubViewport · แสง 2 ดวง · โต๊ะ · CameraRig)
├── PartRam/part_ram.tscn     ← Part RAM (ย้ายจาก Scene/MiniGame/part_ram.tscn)
└── find_item_minigame.tscn

Scripts/MiniGame/
├── PartBase/                 ← ย้ายจาก Scripts/MiniGame/*.gd
│   ├── part_minigame.gd · phase.gd · phase_ui.gd · pib_hint.gd · phase_dialog_parser.gd · minigame_header.gd
│   └── stage3d/
│       ├── part_stage_3d.gd   Stage2D — กล้องนุ่ม · go_to() · raycast · ลาก/snap · allowed / allowed_sockets
│       ├── part_body_3d.gd    Item2D (@tool) — STATIC / DRAGGABLE / TOGGLE / CLICK · overlay ฝุ่น · hover
│       ├── socket_3d.gd       Socket2D (@tool)
│       ├── camera_point_3d.gd View2D (@tool) — มุมกล้องสำเร็จรูป 1 มุม
│       └── phase_3d.gd        Phase2D extends Phase — listen() · cam() · allow() · say() · finish()
├── PartRam/                  ← ย้ายจาก Scripts/MiniGame/part_ram/
│   └── part_ram.gd + phase_*.gd 8 ไฟล์ (extends Phase2D)
└── find_item_minigame.gd · search_box.gd

Resources/Parts/
├── Common/  mainboard · case_panel · case_glass · case_bezel · psu · power_button · power_led · power_plug · cable · monitor · monitor_stand · esd_mat · speaker · workbench
└── Ram/     ram_stick · ram_slot · ram_clip · ram_stand · Tools/*.tres (อุปกรณ์ 10 ชิ้น — ย้ายจาก Resources/MiniGame/Tools)

Assets/MiniGame/PartRam/ram_tex_*.png   ← texture ใหม่ 5 ไฟล์ (ข้อ 5)
```

**ลบแล้ว:** `Test/stage3d_ram_demo.*` (ต้นแบบ — แทนด้วย part_ram.tscn) · `Resources/Parts/Common/tray.tres` · `Scene/MiniGame/Minigame1.scn` (ตัวซ้ำ — ต้นฉบับอยู่ `prototype_minigame/`)

> ⚠️ ถ้ารัน `gen_constant.py` ใหม่ ให้ชี้ output ไปที่ `Scripts/MiniGame/PartBase/minigame_header.gd`

---

## 4. Node ในซีน (แก้ใน Editor ได้หมด)

`part_ram.tscn` → `Stage` (instance · Editable Children) → `SubViewport/World`:

| กลุ่ม | Node (ชื่อ %unique) | หมายเหตุ |
|---|---|---|
| เคส `PcCase` | CaseFloor · CaseRear · **%CaseFrame** (คลิกได้) · CaseBottom · CaseBezel · **%PowerButton** · **%PowerLed** · Psu · **%Plug** · **%GlassPanel** | เคสนอนตะแคง ฝาด้านบน · 1 หน่วย = 10 ซม. |
| เมนบอร์ด | **%Mainboard** · **%Speaker** · **%SlotBodyA1–B2** · **%SlotA1–B2** (Socket2D + ClipBack/ClipFront) · **%RamA2** | แรมเริ่มอยู่ A2 · สลักของ A2 ล็อก ช่องอื่นกางไว้ |
| โต๊ะ | MonitorStand · MonitorNeck · **%Monitor** · EsdMat · RamStand · **%MatSocket** · Cable | จอเปลี่ยนภาพด้วย `set_texture()` |
| เอฟเฟกต์ | **%BeepFx** (วงเสียง) · **%ToolSprite** (ภาพอุปกรณ์ลอยมาถู) | Sprite3D billboard |
| มุมกล้อง `Views` | Overview · Monitor · Inside · Speaker · Front · Rear · Slots · Carry · Mat · MatGold · SlotClose | `View2D` — ย้ายตำแหน่ง/ตั้ง yaw · pitch · distance ใน Inspector |

**ปรับความนุ่มของกล้อง:** node `Stage` → Smoothing (7) · Drag Smoothing (18) · Hold Lift · Snap Dist

---

## 5. Asset

### สร้างใหม่รอบนี้ (placeholder ที่สร้างจากสคริปต์ — ใช้ได้เลย เปลี่ยนเป็นงานวาดทีหลังได้โดยใช้ชื่อเดิม)

| ไฟล์ | ขนาด | ใช้ที่ |
|---|---|---|
| `ram_tex_screen_desktop.png` | 512 × 320 | จอตอน POWER_OFF (มีปุ่ม Shut down) |
| `ram_tex_screen_glitch.png` | 512 × 320 | จอค้างตอน DIAGNOSIS / VERIFY ไม่ผ่าน |
| `ram_tex_screen_boot_ok.png` | 512 × 320 | จอบูตผ่านตอน VERIFY |
| `ram_tex_dust.png` | 256 × 256 (โปร่ง) | ชั้นฝุ่นบนแรมและในสล็อต |
| `ram_tex_beep.png` | 256 × 256 (โปร่ง) | วงเสียงบี๊บเหนือลำโพง |

### โมเดล — ไม่มีไฟล์ 3D

ทุกชิ้นเป็นกล่อง/ทรงกระบอกจาก `PcPart` (.tres) · แรมและสล็อตสร้างรายละเอียดจากโค้ด (`procedural = dimm / dimm_slot`) · ผนังเคสใช้ `case_panel.tres` ไฟล์เดียวต่างขนาดด้วย `size_override`

### ใช้ของเดิม

`mb_mainboard.png` (ผิวเมนบอร์ด) · `ram_tool_*.png` + `ram_eraser.png` (ไอคอนเครื่องมือในถาด + ภาพลอยตอนถู)

### ยังอยากได้ (ไม่บล็อกการเล่น)

| ไฟล์ | ใช้ทำ |
|---|---|
| `ram_tex_case_side.png` 1024² | ผิวแผ่นเหล็กเคส (ตอนนี้สีเทาเรียบ) |
| `ram_tex_esd_mat.png` 1024 × 512 | ลายแผ่น ESD |
| `ram_diagram_*` 3 ไฟล์ | ภาพประกอบตอน BRIEFING (ใส่ใน rail) |
| `ui_star_full/empty` | ดาวหน้าสรุป (ตอนนี้ใช้ ★☆) |
| เสียง: คลิกสลัก · บี๊บ · กดปุ่มเปิด | รอ AudioManager |

---

## 6. ข้อจำกัดที่รู้

- VERIFY ไม่ผ่านยังย้อนกลับไปแก้ไม่ได้ (หักคะแนนแล้วไปสรุป) — ย้อน phase ต้องเพิ่มใน `PartMinigame`
- CLEAN ใช้อุปกรณ์เป็นครั้ง ๆ (ไม่ได้ลากถูเอง) · ยังไม่มีปุ่ม "รอให้แห้ง" ของ IPA · `CLEAN_OVERDONE` ยังไม่ใช้
- BRIEFING ยังไม่มีภาพประกอบ
- ฝากระจกเปิดแล้วไม่ปิดกลับ
- ตัวอักษร ☐ ☑ ★ ▮ ใช้ฟอนต์ระบบ

## 7. ต่อยอดไป Part อื่น

คัดลอกโครง `part_ram.tscn` → เปลี่ยนของใน `World` + มุมกล้องใน `Views` · สคริปต์ phase extends `Phase2D` แล้วใช้ `cam()` / `allow()` / `listen()` / `finish()` เหมือนกัน · เคส/จอ/แผ่น ESD ใช้ .tres ใน `Resources/Parts/Common/` ต่อได้เลย

---

## อัปเดต 30 ก.ย. — Side-view 2.5D (ให้เข้าธีมฉาก 2D)

เหตุผล: มุมกล้องหมุนรอบแบบเดิมดู "3D จ๋า" เกินไป ไม่เข้ากับพื้นหลังวาดมือ (สีเรียบ + เส้นขอบดำหนา) ของ PCCaseBG / RoomBG

| เรื่อง | เดิม | ใหม่ |
|---|---|---|
| กล้อง | perspective หมุนรอบ (orbit) | **orthographic ด้านข้าง** yaw ล็อก 0 · คลิกขวาลาก = เลื่อนซ้าย-ขวา + ก้ม/เงย · Q/E เลื่อน |
| แสง/วัสดุ | PBR ปกติ | **toon** (DIFFUSE_TOON, ไม่มี specular) + เส้นขอบดำ screen-space 5px (`toon_outline.gdshader`) |
| ฉากหลัง | สีทึบใน 3D | SubViewport โปร่งใส → เห็น `Background` ของ part_base = `Assets/MiniGame/PartCommon/part_bg_workshop_wall.png` |
| เลย์เอาต์ | กระจายรอบโต๊ะ | เรียงตามแกน X: จอ (-4.8) · เคส (0) · ปลั๊กพ่วง (3.3) · แผ่น ESD (5.8) |
| ถอด/เสียบปลั๊ก | ปลั๊กหลังเคส | ปลั๊กที่ **ปลั๊กพ่วง** (`power_strip.tres`) มีอนิเมชันยก-เลื่อน-วาง |

ตำแหน่ง View2D (yaw 0 ทุกจุด): Overview p22 d7.2 · Monitor p10 d3.2 · Inside p62 d5.2 · Speaker p62 d1.8 · Front p12 d2.6 · Rear(ปลั๊กพ่วง) p35 d2.2 · Slots p60 d2.0 · Carry p50 d8 · Mat p25 d1.8 · MatGold p10 d1.2 · SlotClose p65 d1.2
(ortho: `distance` = ขนาดภาพ `camera.size`)

ปรับเร็ว:
- ความหนาเส้นขอบ → `Item2D.OUTLINE_PX` · ปิด toon → `TOON := false`
- กลับไปหมุนได้ → ใน Stage ตั้ง `lock_yaw=false`, `orthographic=false`, `transparent_background=false`
- ช่วงเลื่อนกล้อง → `pan_limits`

---

## อัปเดต 30 ก.ย. (2) — สถานีมุมเฉียง + สมุดคู่มือ (ลดความเป็นบทเรียน)

**กล้องแบบสถานี** (`Stage2D.station_mode = true`)
- ผู้เล่นคุมกล้องเองไม่ได้ (ปิดคลิกขวาลาก · ล้อซูม · Q/E) — แต่ละ View2D คือ "หน้า" มุมเฉียง 3/4 ตายตัว
- เปลี่ยนขั้นแล้วกล้อง **หมุนไปหน้าใหม่เอง** แบบนุ่ม (ใช้ `yaw` ของจุดนั้น)
- yaw ที่ตั้งไว้: Overview 0 · Monitor 20 · Front 25 · Inside/Speaker/Slots/SlotClose 30 · Rear(ปลั๊กพ่วง) −40 · Mat/MatGold −30 · Carry 0
- ปิดโหมดนี้ → ตั้ง `station_mode = false` กลับไปใช้แบบด้านข้างเลื่อนได้

**สมุดคู่มือ (ไอคอนหนังสือมุมขวาบน)** — `PhaseUI` (`Scripts/MiniGame/PartBase/phase_ui.gd`)
- แถบหัวข้อโชว์ **เป้าหมาย ▶** = ข้อแรกในเช็กลิสต์ที่ยังไม่ติ๊ก (อัปเดตเองตอน `set_check`) · ผู้เล่นรู้ว่าต้องทำอะไรโดยไม่ต้องอ่านเยอะ
- กดหนังสือ = เปิด/ปิด Info rail (เช็กลิสต์ + "บันทึกของปิ๊บ")
- rail ที่มีปุ่ม/อุปกรณ์ให้กด (ดูอาการ · ทำความสะอาด · ใส่แรม) เปิดค้างเอง · rail ที่มีแต่ข้อความปิดไว้ก่อน
- มีของใหม่ในสมุด → หนังสือเด้ง + จุดแดง
- API ใหม่: `set_goal(phase, text)` · `note(phase, lines)` · `set_rail_open(phase, open)` · `ping_book(phase)`
- ไอคอน: `Assets/MiniGame/PartCommon/ui_icon_guidebook.png` (64×64 placeholder สร้างด้วยโค้ด)

**บทปิ๊บสั้นลง** — `Phase2D.say()` (`SAY_MAX_LINES := 2`)
- ปิ๊บพูดไม่เกิน 2 บรรทัด + "ที่เหลือจดไว้ในสมุดแล้ว" → บรรทัดที่เกินไปอยู่ใน "บันทึกของปิ๊บ"
- **ไม่ได้แก้ `Ram_Pib.txt`** (ไฟล์บทของทีม) — ตัดที่โค้ดตอนแสดงผลเท่านั้น เนื้อหาสอนยังครบ
- โดนผล: @BRIEFING (7 บรรทัด) · @INSTALL (4) · @REMOVE (3) · ตั้ง `SAY_MAX_LINES = 0` = พูดครบเหมือนเดิม

**ยังไม่ได้ทำ (ต่อได้)**: รวม 8 phase เป็น 5–6 สถานี · ใบงานลูกค้า + ตราประทับผ่าน/ไม่ผ่าน · ขยาย Stage เต็มจอตอนปิดสมุด

---

## อัปเดต 30 ก.ย. (3) — ไกด์ "คลิกตรงนี้" + สมุดคู่มือแบบหน้ากระดาษ (แนว Volcano Princess)

**ไกด์ไฮไลท์** — `GuideMarker` (`Scripts/MiniGame/PartBase/guide_marker.gd`) · เรียกผ่าน `Phase2D.hint(target, text, delay, view)` / `clear_hint()` · **30 ก.ย. (หลังสุด)** แยกเป็นซีน `guide_marker.tscn` (สี/ข้อความ/รัศมีเป็น `@export`) สร้างด้วย `GuideMarker.create()` · ป้ายกลับไปอยู่ใต้วงกลมได้ด้วย `Item2D.hint_flip`
- วงกลมกะพริบ + ลูกศรเด้ง + ป้ายข้อความ ตามชิ้น 3D (ตามกล้องได้) · ขึ้นหลังผู้เล่นไม่ทำอะไร `delay` วินาที · หายเองตอน `finish()`
- ดูอาการ: จอ (5 วิ) → ฝากระจก (4 วิ) → **ลำโพง (3 วิ, กล้องซูมไปที่ลำโพงให้เอง)**
- ตัดไฟ: Shut down → ปลั๊ก → โครงเคส (5/4/4 วิ)
- **แก้ลำโพงคลิกยาก:** `Stage2D.pick_at()` คลิกทะลุชิ้นที่กดไม่ได้ + เปิดฝาแล้วเอาฝาออกจากรายการคลิก (เดิมฝากระจกบังลำโพง)
- เพิ่ม `Stage2D.screen_pos_of(world_pos)` = แปลงตำแหน่ง 3D → จอ

**สมุดคู่มือ = หน้ากระดาษกลางจอ** (`PhaseUI.open_book(phase)`, กดไอคอนหนังสือ)
1. **ตอนนี้ต้องทำตรงนี้** — ภาพฉากตอนนั้น (snapshot) + วงกลมตรงชิ้นที่ต้องคลิก
2. **ขั้นตอน** ✔/☐
3. **ปิ๊บบอกว่า** — บทยาวที่ตัดมาจากบทพูด
- ปุ่ม "ปิด" สีส้ม / คลิกนอกหน้าเพื่อปิด · อยู่ CanvasLayer 128 (เหนือแถบปิ๊บ 120)
- สีกระดาษ/ขอบ/หัวข้อ: `COL_PAPER` `COL_EDGE` `COL_HEAD` · มุมตกแต่งยังเป็นสี่เหลี่ยม placeholder → แทนด้วยรูปได้

**เห็นเครื่องชัดสุด:** แผงข้างโชว์เฉพาะตอนมีปุ่มให้กด (ปุ่มเลือกสาเหตุ · ถาดอุปกรณ์ · ปุ่มหมุนแรม) · ไม่มี → ซ่อนแผง + **ขยายฉาก 3D เต็มกว้าง 1152** · `PhaseUI.refresh(phase)` เรียกเมื่อมีปุ่มโผล่ทีหลัง

**ยังไม่ได้ใส่ hint:** ถอดแรม · ใส่แรม · ตรวจผล (ใช้ `hint()` บรรทัดเดียวต่อขั้นได้เลย)

---

## อัปเดต 30 ก.ย. (4) — สไตล์ห้อง diorama มุมเฉียง (ยึด Volcano Princess)

**ภาพรวม:** มองจากมุมสูงเฉียง ~40° (แนว isometric) กล้อง orthographic เห็นห้องทั้งห้องเหมือนตุ๊กตาบ้าน · โทนอุ่น (ไม้ส้ม-น้ำตาล ผนังครีม) · เส้นขอบ **น้ำตาลเข้ม 3.5px** แทนดำ 5px

- **ห้อง** = node `Room` ใน `part_ram.tscn` (กล่องสีล้วนทั้งหมด ใช้ `workbench.tres` + `size_override`/`color_override`): พื้นไม้ · พรม · ผนังหลัง/ซ้าย + บัวพื้น · หน้าต่าง · บอร์ดไม้ก๊อก + โน้ต 3 แผ่น · ชั้นหนังสือ + กล่องเครื่องมือ · โปสเตอร์ · กระถางต้นไม้ · ขาโต๊ะ 4 ขา
  - ผนังมีแค่ 2 ด้าน (หลัง −Z · ซ้าย −X) → **ทุกมุมกล้องต้อง yaw ~25–50°** ไม่งั้นจะเห็นด้านที่ไม่มีผนัง
- **โต๊ะ** 13.9 × 5.4 สีไม้ (เดิมเป็นแผ่นเทาใหญ่) · ฉากหลังโปร่ง → ปิด (`transparent_background = false`) ใช้สีพื้นหลังน้ำตาลเข้มของ Stage แทน
- **แสง** (part_stage_2d.tscn, ใช้ร่วมทุก Part): ambient อุ่น 0.4 · Sun สีอุ่น 0.75 · Fill 0.3 · พื้นหลัง (0.17, 0.12, 0.11)
- **มุมกล้อง** (yaw / pitch / distance): Overview 40/34/8.2 · Monitor 28/18/3.6 · Inside·Speaker·Slots 40/60 · SlotClose 40/65/1.3 · Front 30/20/2.8 · Rear 45/45/2.4 · Carry 40/42/8 · Mat 45/45/2 · MatGold 40/15/1.2
- ไกด์ "คลิกตรงนี้" ชิดขอบบนจอ → ป้ายย้ายไปอยู่ใต้วงกลมเอง
- `part_bg_workshop_wall.png` (ผนัง 2D) ไม่ได้ใช้ในฉาก 3D แล้ว (ยังตั้งเป็น Background ของ part_base อยู่ ไม่เห็นเพราะ Stage ทึบ)

**งานอาร์ตที่แทนได้ทีหลัง:** รูปแปะหน้าต่าง/โปสเตอร์/โน้ต (ใช้ `texture_override` ของ Item2D) · โมเดล low-poly สำหรับโต๊ะ/ชั้น/ต้นไม้ (เอาไปวางแทนกล่องชื่อเดียวกัน)

**ถัดไป (Part ประกอบที่สอนครบ):** ใช้ห้อง + ชุด Phase2D/สมุด/ไกด์ชุดนี้เป็นฐานของ Part Mainboard / GPU / Front Panel / BIOS — ย้าย node `Room` ไปไว้ใน `part_stage_2d.tscn` ตอนเริ่ม Part ที่สอง ทุก Part จะได้ห้องเดียวกัน

---

## อัปเดต 30 ก.ย. (5) — ดูนุ่มขึ้น · ไม่มีเงา · จอฟ้า

- **ปิดเงา** (`part_stage_2d.tscn` Sun `shadow_enabled = false`) — ใช้ร่วมทุก Part
- **กล่องลบมุม** `Item2D.BEVEL := 0.07` (7 มม.) · ชิ้นบางกว่า `BEVEL_MIN := 0.03` ใช้กล่องเหลี่ยมเดิม · ตั้ง `BEVEL = 0` = กลับเป็นเหลี่ยม · mesh แชร์ตามขนาด (`_rounded_box`)
- **ขอบดำทะลุแผ่นบาง:** เพิ่ม `depth_bias` ใน `toon_outline.gdshader` + แผ่นรอง ESD หนาขึ้นเป็น 0.04 (ของบนแผ่นยกขึ้นตาม)
- **พื้นห้องใหญ่ขึ้น** (24 × 19) ไม่เห็นขอบดำนอกห้องแล้ว
- **จออาการ = จอฟ้า** `ram_tex_screen_glitch.png` (":(" + Stop code: MEMORY_MANAGEMENT · ชื่อไฟล์เดิม) · แก้บทปิ๊บ @DIAGNOSIS_CLUE_SCREEN บรรทัดแรกใน `Ram_Pib.txt` ให้พูดถึงจอฟ้า (มีคอมเมนต์ `[Claude 30 ก.ย.]` บอกของเดิม)

### แก้บั๊ก 30 ก.ย. — ถอดแรมไปวางบนแผ่น ESD ไม่ได้
- **สาเหตุ:** `Stage2D._update_hover()` หา socket จากระยะแกน XZ ของจุดที่ถือ (สูงกว่าพื้นโต๊ะ `hold_lift`) · พอกล้องมุมเฉียงก้ม ~40° จุดบนจอที่ผู้เล่นชี้กับจุด XZ ห่างกันเกิน `snap_dist` (1.2 ซม.) → ไม่เจอ socket → ปล่อยแล้วแรมเด้งกลับสล็อต
- **แก้:** ลากด้วยเมาส์ → เทียบ **ระยะบนจอ** ระหว่างเมาส์กับ socket (`snap_px := 48` พิกเซล) · สั่งจากโค้ด (`move_held_to`) ยังใช้ `snap_dist` แบบเดิม
- ทดสอบด้วยการจำลองเมาส์จริง: ถอดแรม → แผ่น ESD ผ่าน (ไป phase 5) · Tutorial ลาก PSU / เมนบอร์ด / CPU / แรม ลงช่องผ่านทั้งหมด
