# SCENE_2D.md — ฉากมินิเกมแบบ 2D (แนว Volcano Princess + Lil' Guardsman)

> 30 ก.ย. 2569 · Godot 4.7 · แทนระบบ 3D (`stage3d/`) และ 2.5D (`stage25d/`) เดิมทั้งหมด — ลบแล้ว
> ใช้กับ Part RAM (`Scene/MiniGame/PartRam/part_ram.tscn`) และ Tutorial ประกอบคอม (`Scene/MiniGame/TutorialAssembly/tutorial_assembly.tscn`)

## 1. แนวภาพ

| มุม (View2D) | แนว | รูปพื้นหลัง |
|---|---|---|
| **Overview** ภาพรวมร้าน | 2D แนว Volcano Princess — ฉากร้าน + ป้ายจุดกด | `Scene2D/overview_shop.jpg` (จาก `bg_shop_open.jpg` + แผ่น ESD + ปลั๊กพ่วง) |
| **Monitor** โต๊ะคอม (ชื่อเก่า Front) | 2D | `Scene2D/desk_pc.png` (โต๊ะ + `Home/pc_down.png`) |
| **Rear** ปลั๊กพ่วง | 2D | `Scene2D/power_strip_view.png` |
| **Inside** ในเคส (ชื่อเก่า Speaker) | **2.5D แนว Lil' Guardsman** — มองจากบน โต๊ะไม้มีไฟส่อง | `Scene2D/inside_bg.png` (โต๊ะ + `mb_case_open.png` + `mb_mainboard.png`) |
| **Slots** สล็อตแรม (ชื่อเก่า SlotClose) | 2.5D ซูม | `Scene2D/slots_zoom.png` |
| **Mat** แผ่น ESD (ชื่อเก่า MatGold) | 2D มองจากบน | `Scene2D/esd_mat_view.png` |
| Tutorial: **Tray** ชิ้นส่วน · **Build** ประกอบในเคส | 2D / 2.5D | `esd_mat_view.png` · `Scene2D/build_bg.png` |

- สลับมุม = ภาพ crossfade + ซูมเข้า/ออกเล็กน้อย (`Stage2D.transition_time`)
- เปลี่ยนสถานะ = เปลี่ยนรูป crossfade (`Item2D.set_state`) เช่นจอ `glitch → desktop → off → boot_ok` · ปลั๊ก `"" ↔ out` · ฝากระจก `"" → open` · แรม `dirty → dusted → clean` · สลักเปิด/ปิด

## 2. โครง node (ทุกอย่างเป็น Control — ลากจัดตำแหน่งใน Editor ได้)

```
Stage (part_stage_2d.tscn · Stage2D)
├── Views
│   ├── Overview (View2D)      ← รูปพื้นหลัง + ลูก ๆ คือของในมุมนี้
│   │   ├── ToCase (Hotspot2D) ← ป้าย "ตรวจเคส" คลิกแล้วไปมุม Inside
│   ├── Inside (View2D)
│   │   ├── GlassPanel (Item2D · CLICK)   ← รูปฝากระจก / สถานะ "open" = ไม่มีรูป
│   │   ├── MiniA2 (MiniSpot2D)           ← แรมตัวเล็กบนเมนบอร์ด (โชว์เมื่อ SlotA2 มีแรม)
│   ├── Slots (View2D)
│   │   ├── SlotA2 (Socket2D · look "slot")
│   │   │   ├── ClipBack / ClipFront (Item2D · TOGGLE)
│   │   ├── RamA2 (Item2D · DRAGGABLE)
│   └── Mat (View2D) → MatSocket (Socket2D · look "mat")
└── Top   ← ชิ้นที่กำลังถือ + ToolSprite (อุปกรณ์ทำความสะอาดที่ลอยมาถู)
```

| คลาส (`Scripts/MiniGame/PartBase/scene2d/`) | หน้าที่ |
|---|---|
| `Stage2D` | จัดการมุม · คลิก · ลาก/วาง · สัญญาณเดิมทุกตัว (`part_clicked` `part_installed` `drop_rejected` ฯลฯ) · `go_to()` `back()` `allowed` `allowed_sockets` `preinstalled` `snapshot()` |
| `View2D` | มุม 1 มุม ขนาด 1152 × 420 · `background` `bg_offset` `label` (ปุ่มในแถบนำทาง) `aliases` (ชื่อเก่าที่ phase เรียก) `focus_x` (จุดที่ต้องเห็นเมื่อมีแผงข้าง) |
| `Item2D` | ชิ้น/จุดคลิก: `mode` · `texture` · `texture_on` (สลักเปิด) · `looks` · `state` · `label_text` · `mirror` · `stretch` · `hint_flip` (true = ลูกศร/ป้ายไกด์ไปอยู่ใต้วงกลม ใช้กับชิ้นที่ป้ายบนบังของอื่น) · ไม่มีรูป = จุดคลิกล่องหน |
| `Socket2D` | กรอบวางชิ้น: `socket_type` `required_yaw` (0/180) `locks` `start_occupant` `look` |
| `Hotspot2D` | ป้าย + จุดกดไปมุมอื่น · `portal` = ถือชิ้นลากมาค้างแป๊บเดียว → ไปมุมนั้นทั้งที่ยังถืออยู่ (เช่นลากแรมจากสล็อต → "→ แผ่น ESD") |
| `MiniSpot2D` | ภาพย่อของชิ้นที่อยู่ใน socket ของอีกมุม (หน้าตา `"mini"`) |
| `Phase2D` | ฐานของ phase (เหมือน Phase3D/25D เดิม) · `cam()` `allow()` `hint()` `say()` `finish()` · `hint()` สร้าง `GuideMarker` จากซีน `PartBase/guide_marker.tscn` แล้วอ่าน `Item2D.hint_flip` ของเป้า (เป้าที่ไม่ใช่ Item2D เช่น Hotspot2D ไม่ flip) |

### หน้าตาของ Item2D (`looks`)
ลำดับการหา: `บริบท@สถานะ` → `บริบท` → `@สถานะ` / `สถานะ` → `texture`
- บริบท = `look` ของ socket ที่ชิ้นเสียบอยู่ → ชิ้นเดียวหน้าตาต่างกันแต่ละมุม เช่น RamA2: `slot@dirty` (แรมยืนในสล็อต มีฝุ่น) · `mat@clean` (แรมวางบนแผ่น ESD) · `mini` (แรมเล็กบนเมนบอร์ด)
- ค่า `<empty>` = ซ่อน (ฝากระจก `open` · จอ `off`)
- แรมกลับด้าน (กด R ตอนถือ) = รูปกลับซ้าย-ขวา · สล็อตต้องการ `required_yaw = 0`

## 3. รูปที่วาดเพิ่ม (`Assets/MiniGame/Scene2D/`)

ต้นฉบับเป็น **SVG ใน `Assets/MiniGame/Scene2D/src/`** แก้ใน Inkscape แล้ว export PNG ขนาดเดิมทับไฟล์ได้เลย (โฟลเดอร์ src มี `.gdignore` Godot ไม่ import)
- `slots_zoom` · `ram_slot` / `ram_slot_dirty` (แรมยืนในสล็อต) · `clip_closed` / `clip_open` · `slot_dust` · `ram_mini`
- `case_glass` (ฝากระจกปิด) · `desk_bg` (โต๊ะแนว Lil' Guardsman) · `esd_mat_view` · `power_strip_view` · `plug_in` / `plug_out` · `ssd_m2`
- รูปที่ประกอบจาก asset เดิม: `overview_shop.jpg` · `desk_pc.png` · `inside_bg.png` · `build_bg.png` · `mb_in_case.png`
- ใช้ asset เดิมตรง ๆ: `ram_dirty` / `ram_better` / `ram_clean` · `mb_cpu` · `mb_cooler` · `gpu_card` · `gpu_psu` · `fp_led_on/off` · `ram_tex_screen_*` · `ram_tex_beep`

## 4. เพิ่มของใหม่

- **จุดคลิกใหม่**: เพิ่ม Control ลูกของ View2D → ใส่สคริปต์ `item_2d.gd` → ตั้ง `mode = CLICK` + `label_text` (ไม่ต้องใส่รูป) → phase ฟัง `stage().part_clicked`
- **ชิ้นลากได้**: `item_2d.gd` + `data` (PcPart .tres) + `mode = DRAGGABLE` + รูปของแต่ละ `look`
- **มุมใหม่**: Control ลูกของ `Stage/Views` + `view_2d.gd` + รูปพื้นหลัง 1152 × 420 + Hotspot2D จากมุมอื่นที่ชี้มา
- **Part ใหม่ (Mainboard/GPU ฯลฯ)**: คัดลอกโครง `part_ram.tscn` → เปลี่ยนมุม/ชิ้น → phase extends `Phase2D`

## 5. ทดสอบแล้ว (Godot 4.7.2)

- Part RAM เล่นต่อเนื่องจาก phase 3 → 8 ครบ: ปิดเครื่อง → ถอดปลั๊ก → แตะโครงเคส → เปิดฝากระจก → ปลดสลัก → ลากแรมผ่านประตูไปแผ่น ESD → ทำความสะอาด 3 ขั้น (รูปค่อย ๆ เปลี่ยน) → ลากกลับเข้าสล็อต (หมุนทิศ) → กดลงจนสลักล็อก → เสียบปลั๊ก → เปิดเครื่อง → จอบูตผ่าน → หน้าสรุป
- Tutorial: คลิกดูชิ้นส่วน 7 ชิ้น → ลากประกอบลงเคสครบ 7 socket → กดเปิดเครื่อง → จอบูต
- ไม่มี error ทุก phase
