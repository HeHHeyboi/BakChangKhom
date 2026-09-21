# ASSET_GUIDE.md — คู่มือสร้าง Asset สำหรับ BakChangKhom (บักช่างขม)

> อ้างอิงโค้ดจริงที่ commit `8c4db20` (`feat: add debug quest-jump menu and finish room-to-minigame dialog wiring`)
> อัปเดตล่าสุด: 16 ก.ย. 2569 · Engine: **Godot 4.7 (GL Compatibility)**
> เอกสารคู่กัน: `Docs/REPAIR_FLOW.md` (โครง scene + ลูปงานซ่อม), `Docs/MINIGAME1_DESIGN.md`, `CLAUDE.md`, GDD v1.7, ClickUp [[Project] Bak Chang Khom](https://app.clickup.com/t/86ey2e8mm)

เอกสารนี้ใช้ตอน **สร้าง asset ใหม่** (ส่วนใหญ่ generate ด้วย AI) ให้ได้ไฟล์ที่ drop เข้า Godot แล้วใช้ได้เลย
ไม่ต้องแก้ scene ตามทีหลัง — ทุกหัวข้อระบุ **ขนาด / ฟอร์แมต / path / ชื่อไฟล์ / prompt / วิธีผูกเข้าโค้ด**

---

> **21 ก.ย. 2569 — เปลี่ยนศัพท์ Tier → Part** โฟลเดอร์และชื่อไฟล์ถูก rename แล้ว:
> `Tier1Ram/mg1_*` → `PartRam/ram_*` · `Tier2Mainboard/mg2_*` → `PartMainboard/mb_*` · `Tier3Gpu/mg3_*` → `PartGpu/gpu_*` · `Tier4FrontPanel/mg4_*` → `PartFrontPanel/fp_*` · `Tier5Bios/mg5_*` → `PartBios/bios_*`
> โครงเนื้อหาใหม่ (Core Part 5 + Normal Part 8 + ลูปงานซ่อม 5 scene) อยู่ใน `Docs/REPAIR_FLOW.md`

## 0. TL;DR — กฎ 8 ข้อที่ห้ามพลาด

1. **จอเกมคือ 1152 × 648** (Godot default viewport — `project.godot` ไม่ได้ override) ไม่ใช่ 1920×1080
2. ภาพพื้นหลังเต็มจอ → **1152 × 648 JPG** (dialog BG ที่ใหญ่กว่านี้จะโดนย่อโดย `dialog_scene.gd`)
3. อะไรที่ต้องมี **พื้นโปร่ง** (ตัวละคร, ไอเทม, UI, ปุ่ม) → **PNG 32-bit**
4. **ชื่อไฟล์ ASCII ล้วน ห้ามเว้นวรรค ห้ามภาษาไทย** — ใช้ `snake_case.png`
5. `.png` / `.jpg` อยู่ใน **Git LFS** แล้ว (`.gitattributes`) — commit ไฟล์ `.import` ที่ Godot สร้างไปด้วยเสมอ
6. ชื่อตัวละครใน `_CharacterMap` (`Scene/Global.tscn`) ต้อง **ตรงกับชื่อในไฟล์ dialog เป๊ะทุกตัวอักษร** ไม่งั้นเกม crash
7. เพิ่ม path ใหม่ที่ใช้บ่อยเข้า `Scripts/constant.gd` แทนการ hardcode string
8. เกมใช้ **GL Compatibility** — ห้ามพึ่ง shader/effect ที่ต้อง Forward+ และเลี่ยง texture ใหญ่เกิน 4096 px

---

## 1. ข้อกำหนดทางเทคนิค

### 1.1 ความละเอียดและ stretch

| หัวข้อ | ค่าจริงในโปรเจกต์ | ที่มา |
|---|---|---|
| Base viewport | **1152 × 648** (16:9) | `project.godot` ไม่ได้ตั้ง `display/window/size/viewport_*` → ใช้ default ของ Godot 4 |
| Stretch mode | `canvas_items` | `project.godot [display] window/stretch/mode` |
| Renderer | `gl_compatibility` | `project.godot [rendering]` |
| BG สูงสุดใน Dialog | `Vector2(1152, 648)` | `dialog_scene.gd` → `const MaxBGSize` (ใหญ่กว่านี้จะถูก scale ลงอัตโนมัติ) |
| Window | `always_on_top = true` | `project.godot [display]` |

> **สรุป:** ออกแบบทุกอย่างบนกริด 1152 × 648 แล้ว generate ที่ 2× (2304 × 1296) ถ้าต้องการความคม
> จากนั้น **ย่อกลับเป็น 1152 × 648 ก่อน commit** เพื่อไม่ให้ไฟล์บวมและ import ช้า

### 1.2 ฟอร์แมตและขนาดไฟล์

| ประเภท | ฟอร์แมต | ขนาดเป้าหมาย | ขนาดไฟล์ที่ยอมรับ |
|---|---|---|---|
| Background เต็มจอ | `.jpg` (คุณภาพ 85) | 1152 × 648 | ≤ 300 KB |
| Tutorial slide | `.png` (หรือ `.jpg` ถ้าไม่มีพื้นโปร่ง) | **1152 × 648** | ≤ 500 KB |
| ตัวละคร dialog (ครึ่งตัว/เต็มตัว) | `.png` 32-bit | สูง 420 – 560 px | ≤ 200 KB |
| ไอเทม / ชิ้นส่วนคอม (minigame) | `.png` 32-bit | ตามสเปกในหัวข้อ 5.2 | ≤ 150 KB |
| ปุ่ม / ไอคอน UI | `.png` 32-bit | 64 / 128 / 250 px | ≤ 80 KB |
| Sprite sheet ตัวละครเดิน | `.png` 32-bit | ≤ 2048 × 2048 | ≤ 500 KB |
| BGM | `.ogg` (Vorbis) | – | ≤ 3 MB / เพลง |
| SFX | `.wav` 16-bit 44.1 kHz | – | ≤ 300 KB |

### 1.3 การตั้งชื่อ (มาตรฐานใหม่ — ใช้กับไฟล์ใหม่ทุกไฟล์)

```
<หมวด>_<ชื่อ>[_<state|variant>].<ext>

ตัวอย่าง:
  bg_shop_morning.jpg
  char_min_normal.png        char_min_happy.png
  mb_cpu.png                mb_cpu_placed.png
  ui_btn_next_normal.png     ui_btn_next_hover.png
  tut_ram_01.png             tut_ram_02.png
```

* ตัวพิมพ์เล็กล้วน, คั่นด้วย `_`
* **ห้าม** ภาษาไทย / เว้นวรรค / อักขระพิเศษ (ไฟล์ `Assets/Tutorial/BasicStart/Tutorial สอนเล่น.png` คือตัวอย่างที่ไม่ควรทำซ้ำ — export บนบาง OS มีปัญหา)
* state ใช้คำมาตรฐาน: `normal` / `hover` / `press` / `disabled` / `highlight`

### 1.4 โครงโฟลเดอร์เป้าหมาย

```
Assets/
├── Background/          # bg_*.jpg เต็มจอ 1152x648
├── CharacterSprite/     # char_*.png ตัวละครใน dialog (พื้นโปร่ง)
├── Home/                # props ฉากบ้าน (door, pc)
├── MiniGame/
│   ├── PartRam/        # แยกตาม Part ตั้งแต่ตอนนี้
│   ├── PartMainboard/
│   ├── PartGpu/
│   ├── PartFrontPanel/
│   └── PartBios/
├── Tutorial/
│   ├── BasicStart/  BasicHome/  RamCleaning/
│   ├── Motherboard/ Gpu/  FrontPanel/  Bios/
├── UI/                  # ui_*.png ปุ่ม กรอบ ไอคอน
├── Audio/
│   ├── BGM/  SFX/
├── Ending/              # ภาพ ending + credits
├── SpriteSheets/        # sprite sheet เดิน/idle
├── TileMap/
└── Dialog/              # *.txt (ห้ามเปลี่ยนนามสกุล — export preset กรอง *.txt)
```

---

## 2. Art Style (บังคับใช้ทุกชิ้น)

**Style:** 2D Hand-drawn — Don't Starve inspired แต่สดใสกว่า
**อ้างอิง:** Don't Starve (outline + hand-drawn) + Gravity Falls (สีสด) + Cartoon Network (เส้นสะอาด)

ลักษณะเด่น:
* เส้น outline หนา สีน้ำตาลเข้ม (ไม่ดำสนิทแบบ Don't Starve)
* สีสดใส warm tones — เหลือง ส้ม เขียว น้ำตาล
* ลายมือวาด มีความ imperfect นิดหน่อย
* Shadow แบบ flat 2 tone ไม่ใช้ gradient
* สัดส่วนตัวละครแบบ chibi เล็กน้อย

### 2.1 Base Style Prompt (แปะต่อท้ายทุก prompt)

```
2D hand-drawn game art, thick dark brown outlines, flat colors,
warm earthy color palette, bright and cheerful,
Don't Starve inspired but colorful, Gravity Falls art style,
clean cartoon style, expressive characters,
no gradients, cel-shaded, simple two-tone shadows
```

### 2.2 Negative Prompt (แปะต่อท้ายทุก prompt เช่นกัน)

```
photorealistic, 3D render, anime, realistic lighting, gradient shading,
text, watermark, signature, ui frame, border, drop shadow blur,
blurry, jpeg artifacts, extra limbs, deformed hands
```

### 2.3 Color Palette

| บทบาท | HEX | ใช้กับ |
|---|---|---|
| Primary warm | `#E8A854` | ไม้, ดินเผา, แสงตะเกียง, ปุ่มหลัก |
| Accent green | `#6BAF52` | ต้นไม้, ทุ่งนา, สถานะสำเร็จ |
| Accent blue | `#4A90D9` | ท้องฟ้า, หน้าจอคอม, ข้อมูล/hint |
| Outline | `#2C1810` | เส้นขอบทุกชิ้น |
| BG warm light | `#F5E6C8` | พื้นหลังอ่อน, กล่องข้อความ |
| BG warm dark | `#D4956A` | เงา, พื้นหลังชั้นหลัง |

**สีสถานะเพิ่มเติม (สำหรับ minigame/UI — เสนอใหม่ ใช้แล้วมาอัปเดตตารางนี้):**
สำเร็จ `#6BAF52` · เตือน `#E8A854` · ผิดพลาด `#C0453B` · disabled `#9A8F82`

---

## 3. Asset ที่มีอยู่แล้ว (inventory จริง ณ commit 8c4db20)

### 3.1 Background — `Assets/Background/`

| ไฟล์ | ขนาดจริง | ใช้ที่ไหน | สถานะ |
|---|---|---|---|
| `HomeBG.jpg` | 1920×1080 | `Scene/Location/Home.tscn` (BG scale 0.595) | ⚠️ ใหญ่เกิน ควรทำ 1152×648 |
| `RoomBG.jpg` | 1920×1080 | `Scene/Location/Room.tscn` | ⚠️ ใหญ่เกิน |
| `Market.jpg` | 1920×1080 | `Scene/Location/Market.tscn` | ⚠️ ใหญ่เกิน |
| `Chapter2_bg.jpg` | 1920×1080 | `Constant.CHAPTER2_BG_IMAGE` | ⚠️ ใหญ่เกิน |
| `Office.png` | 740×555 (4:3) | prologue (ฉากออฟฟิศ) | 🔴 ผิดสัดส่วน + เล็กกว่าจอ → เบลอ **ต้องทำใหม่** |
| `stargBG.jpg` | 2048×1448 (1.41:1) | start menu (เวอร์ชันเก่า) | 🔴 ผิดสัดส่วน |
| `stargBG2.jpg` | 1152×648 | start menu | ✅ ถูกต้อง |
| `settingBG.jpg` | 1152×648 | หน้า Setting | ✅ |
| `tutorial.jpg` | 1152×648 | พื้นหลัง tutorial | ✅ |
| `PCCaseBG.jpg` | 1152×648 | – | ⚠️ ซ้ำกับ `Assets/MiniGame/PCCaseBG.jpg` (ไฟล์เดียวกัน 37,085 bytes) |
| `placeholder.png` | 1152×648 | `Constant.PLACEHOLDER_IMAGE` — ใช้จริงใน prologue | ✅ |

### 3.2 ตัวละคร — `Assets/CharacterSprite/`

| ไฟล์ | ขนาด | ใช้ที่ไหน |
|---|---|---|
| `Idle.png` | 265×519 | `Global._CharacterMap["ขม"]` |
| `GrandmaNormal.png` | 235×421 | `Global._CharacterMap["ยาย"]` + `Home.tscn` |
| `GradmaHighlight.png` | 235×421 | `Home.tscn` texture_hover | *(สะกดผิด: Gradma → Grandma)* |

> ระบบ dialog ทำ highlight/fade ด้วยการ modulate สีในโค้ด (`character_sprite.gd` — `darkened(0.7)` / `lightened(1)`)
> **จึงไม่ต้องวาดเวอร์ชัน highlight แยก** สำหรับตัวละครใน dialog (ที่ต้องวาดแยกคือ prop ในฉากที่เป็น TextureButton)

### 3.3 Props ฉากบ้าน — `Assets/Home/`

| ไฟล์ | ขนาด | หมายเหตุ |
|---|---|---|
| `door.png` / `doorHighlight.png` | 594×880 / 606×844 | ⚠️ ขนาด 2 state ไม่เท่ากัน → ภาพกระตุกตอน hover **ควรทำใหม่ให้เท่ากัน** |
| `pc_up.png` / `pc_down.png` | 814×514 | ✅ เท่ากัน |

### 3.4 MiniGame Part RAM (ขัดแรม) — `Assets/MiniGame/`

| ไฟล์ | ขนาด | ผูกกับ |
|---|---|---|
| `ramDirty.png` | 597×213 | `RamStatus.DIRTY` (คลิก 0–9) |
| `ramSligtDirty.png` | 593×211 | `RamStatus.BETTER` (คลิกครบ 10) *(สะกดผิด: Sligt → Slight)* |
| `ram.png` | 589×205 | `RamStatus.CLEAN` (คลิกครบ 15) |
| `eraser.png` | 359×367 | ยางลบที่วิ่งซ้าย–ขวา |
| `caution.png` / `cautionHover.png` | 250×250 | ปุ่ม `!` เรียก event |
| `cautionPress.png` | **350×350** | 🔴 ไม่เท่ากับอีก 2 state → ปุ่มกระตุกตอนกด |
| `PCCaseBG.jpg` | 1152×648 | พื้นหลังมินิเกม |

> ⚠️ ทั้ง 3 สถานะของแรมขนาดไม่เท่ากัน (597 / 593 / 589 px) ทำให้ภาพขยับตอนสลับ texture — **asset ชุดใหม่ทุก Part ต้องขนาดเท่ากันทุก state**

### 3.5 Sprite sheet / TileMap

| ไฟล์ | ขนาด | กริด | หมายเหตุ |
|---|---|---|---|
| `SpriteSheets/Idle.png` | 2500×2000 | `hframes=5, vframes=4` (ใช้ frame 1) | สเกลในเกม 0.25 × 0.29 |
| `SpriteSheets/Walk_Khom.png` | 3500×3500 | `hframes=1, vframes=7` + region | 🔴 ใหญ่เกินจำเป็นมาก (ตัวละครจริงสูง ~130 px บนจอ) |
| `TileMap/Walk_Khom.png` | 3500×3500 | – | 🔴 **ไฟล์ซ้ำกับข้างบน** (879,092 bytes เท่ากัน) ควรลบทิ้ง 1 ไฟล์ |
| `TileMap/Tilemap_color1–3.png` | 1280×512 | – | ✅ |

### 3.6 Tutorial — `Assets/Tutorial/`

| ไฟล์ | ขนาด | ผูกกับ |
|---|---|---|
| `BasicStart/Tutorial สอนเล่น.png` | 1312×816 · 2.0 MB | `Resources/tutorial1.tres` → `TutorialState.BASIC_START` |
| `RamCleaning/Tutorial ขัดแรม.png` | 1376×768 · 1.9 MB | `Resources/ram_cleaning.tres` → `TutorialState.RAM_CLEANING` |

> 🔴 ทั้งคู่ **ไม่ใช่ 1152×648** และ `Tutorial.tscn` ตั้ง `Slide.expand_mode = 1` (ignore size) → ภาพถูกยืดผิดสัดส่วน
> 🔴 ชื่อไฟล์เป็นภาษาไทย + มีเว้นวรรค · ขนาดไฟล์ ~2 MB ต่อสไลด์ (ควร ≤ 500 KB)

### 3.7 UI ที่มีอยู่ — `Assets/ButtonStyle/`

มีแค่ `.stylebox` (StyleBox ของ Godot ไม่ใช่รูป): `base`, `baseHover`, `baseHoverPress`, `StartMenu/button_*`, `StartMenu/option_*`
**ยังไม่มี UI ที่เป็นภาพวาดเลยแม้แต่ชิ้นเดียว** → ดูหัวข้อ 5.6

### 3.8 ✨ ชุด asset รอบใหม่ (Gen batch — 84 ไฟล์, ย้ายเข้า `Assets/` แล้ว 16 ก.ย. 2569)

ไฟล์ทั้งหมดถูกย้ายจาก `Assets/Gen/Assets/**` เข้าโครงจริงแล้ว ขนาดและชื่อไฟล์ **ตรงตามสเปกในเอกสารนี้**

| หมวด | ได้ครบ | หมายเหตุ |
|---|---|---|
| Background (หัวข้อ 5.5) | **9 / 9** ✅ | ทุกไฟล์ 1152×648 · 100–166 KB · ครบตามรายการที่เสนอไว้ |
| ตัวละคร (หัวข้อ 5.3 + 5.4) | **20 ไฟล์** ✅ | 400×500 ทุกไฟล์ · ปิ๊บ 5 อารมณ์ · ขม 4 อารมณ์ · มิ้น 2 · ยาย/ลุงอำนวย/ผอ./ผู้ใหญ่บ้าน/ครู/เด็กหญิง/เด็ก/เพื่อนร่วมงาน/หัวหน้า |
| Part RAM | 4 ไฟล์ | ``ram_dirty/better/clean`` **600×214 เท่ากันทุกใบ** (แก้ปัญหาเดิม) + `ram_eraser` 256×256 |
| Part Mainboard | 10 / 12 | ขาด `mb_mainboard_ghost`, `mb_cpu_wrong` |
| Part GPU | **10 / 10** ✅ | ครบ |
| Part Front Panel | 9 ไฟล์ | ใช้ `fp_slots_overview.png` (520×240) แทนสลอตแยก 4 ไฟล์ — ถ้าจะทำ drag-drop ทีละสลอตต้องแยกไฟล์หรือใช้ region |
| Part BIOS | 6 / 7 | ขาด `bios_bottleneck_chart` |
| UI | 9 ไฟล์ | ปุ่ม 4 state (320×96), dialog box (1152×200), name plate, quest panel, time panel, marker_caution 1 state |
| Ending | 1 / 4 | มีแค่ `credits_bg.jpg` ขาดภาพ ending 3 ใบ |
| Sprite sheet เดิน | ✅ | `char_khom_walk_sheet.png` 1600×500 (4 เฟรม 400×500) + เฟรมแยกใน `SpriteSheets/Frames/` + `Resources/khom_walk.tres` (SpriteFrames พร้อมใช้) — **แทน `Walk_Khom.png` 3500×3500 ของเดิมได้เลย** |

#### ยังขาดอยู่ (หลัง Gen batch)

| ลำดับ | สิ่งที่ขาด | อ้างอิง |
|---|---|---|
| 🔴 1 | **Tutorial slides ทั้ง 7 state** — ยังไม่มีไฟล์ใหม่เลย | หัวข้อ 5.1 |
| 🔴 2 | **Asset มินิเกม 1 นอกเหนือจากขั้นขัด** — Phase 0 วินิจฉัย (6), ภาพประกอบตอนสอน (3), ขั้นตัดไฟ/ถอด/ใส่กลับ/ตรวจผล/สรุป (~12) | `MINIGAME1_DESIGN.md` หัวข้อ 11 |
| 🔴 3 | **อุปกรณ์ทำความสะอาด 10 ชิ้น + ถาด + การ์ดคุณสมบัติ** (ระบบเลือกอุปกรณ์) | `MINIGAME1_DESIGN.md` หัวข้อ 14.8 |
| 🟡 4 | **Audio ทั้งหมด** — ยังไม่มีไฟล์เสียงแม้แต่ไฟล์เดียว | หัวข้อ 5.8 |
| 🟡 5 | UI ที่เหลือ: ไอคอนช่วงเวลา 3, เงิน/XP/ยศ 7, ปุ่ม close/next/prev/map 4, marker_caution อีก 2 state | หัวข้อ 5.6 |
| 🟢 6 | ภาพ Ending 3 ใบ · `mb_mainboard_ghost` · `mb_cpu_wrong` · `bios_bottleneck_chart` | หัวข้อ 5.2, 5.7 |

#### งานที่ต้องทำกับชุด Gen ก่อนใช้จริง

1. **เปิด Godot ให้ import** — ไฟล์ทั้ง 84 ยังไม่มี `.import` (ต้อง commit `.import` ตามด้วย)
2. **ผูกเข้า `_CharacterMap`** (`Scene/Global.tscn`) — เพิ่ม `"ปิ๊บ"`, `"มิ้น"`, `"ลุงอำนวย"`, `"ผอ."`, `"ผู้ใหญ่บ้าน"`, `"ครู"`, `"เด็กหญิง"`, `"เด็ก"`, `"เพื่อนร่วมงาน"`, `"หัวหน้า"`
3. **เลือกไฟล์ที่ซ้ำซ้อนให้เหลืออันเดียว** แล้วลบของเก่า:
   * `char_khom_normal.png` / `char_khom_idle.png` ↔ `Idle.png` เดิม
   * `char_grandma_normal.png` ↔ `GrandmaNormal.png` เดิม
   * `char_pib_normal.png` ↔ `char_pib_neutral.png` (ซ้ำกันเอง — เลือก 1)
   * `ram_*.png` ↔ `ram*.png` เดิมใน `Assets/MiniGame/`
   * `char_khom_walk_sheet.png` ↔ `Walk_Khom.png` (มี 2 ที่: `SpriteSheets/` และ `TileMap/`)
4. **บีบไฟล์ที่ใหญ่เกินเพดาน** (ใช้ `pngquant` หรือ `oxipng`) — ชุด Gen กิน LFS ไป **14 MB**
   * `mb_mainboard.png` 1.47 MB · `mb_case_open.png` 1.41 MB · `gpu_cable_messy.png` 1.15 MB · `gpu_cable_tidy.png` 887 KB · `char_khom_walk_sheet.png` 622 KB
5. **ผูก `Resources/khom_walk.tres` เข้า `Player.tscn`** — เปลี่ยนจาก AnimationPlayer + region เป็น `AnimatedSprite2D` + SpriteFrames (หรือคงของเดิมแล้วปรับ region ให้ตรงชีตใหม่)

### 3.9 ✨ asset ที่เข้ามาหลังจากนั้น (commit `1c9040a`, 21 ก.ย. 2569)

| ไฟล์ | ขนาด | ใช้ที่ไหน |
|---|---|---|
| `Assets/MiniGame/box.png` | 256×256 | กล่องค้นหาใน find-item minigame (หายางลบ) |
| `Assets/MiniGame/box_on_hover.png` | 256×256 | state hover — ขนาดเท่ากัน ✅ |

**🔴 ปัญหาที่ต้องแก้ก่อนใช้ asset ชุด Part (รายละเอียดใน `Docs/SYNC_REVIEW.md` หัวข้อ 2):**

1. **`.import` ไม่ตรงกับชื่อรูป 39 คู่** — commit `1c9040a` มีรูปชื่อใหม่ (`ram_eraser.png`) กับ `.import` ชื่อเก่า (`mg1_eraser.png.import`) อยู่ด้วยกัน → ต้องลบ `.import` กำพร้าแล้วให้ Godot import ใหม่ ไม่งั้น uid ตายตอน clone ใหม่
2. **`Scene/MiniGame/find_item_minigame.tscn` ยังชี้ `Assets/MiniGame/Tier1Ram/mg1_eraser.png`** ซึ่งไม่มีแล้ว
3. `box*.png` ควรย้ายเข้า `Assets/MiniGame/PartRam/` และตั้งชื่อ `ram_box_normal.png` / `ram_box_hover.png` — ทำพร้อมรอบ reimport ทีเดียว
4. asset ชุดเก่าที่ควรลบหลังเปลี่ยนโค้ดไปใช้ชุดใหม่: `ram.png` · `ramDirty.png` · `ramSligtDirty.png` · `eraser.png` ที่ราก `Assets/MiniGame/`
5. find-item minigame ใช้ `RoomBG.jpg` (1920×1080) เป็นพื้นหลัง — ควรย่อเป็น 1152×648

---

## 4. สรุปงานแก้ asset เดิม (ทำก่อนสร้างของใหม่)

| # | ปัญหา | ไฟล์ | ความสำคัญ |
|---|---|---|---|
| 1 | Tutorial slide ผิดขนาด + ชื่อไทย + ไฟล์ 2 MB | `Assets/Tutorial/**` | 🔴 Urgent |
| 2 | `Office.png` 740×555 ผิดสัดส่วน/เบลอ | `Assets/Background/Office.png` | 🔴 Urgent |
| 3 | `cautionPress.png` 350 px ไม่เท่าอีก 2 state | `Assets/MiniGame/` | 🟡 High |
| 4 | 3 สถานะแรมขนาดไม่เท่ากัน | `Assets/MiniGame/ram*.png` | 🟡 High |
| 5 | `door.png` vs `doorHighlight.png` ขนาดต่างกัน | `Assets/Home/` | 🟡 High |
| 6 | BG 1920×1080 ทั้ง 4 ไฟล์ ควรย่อเป็น 1152×648 | `Assets/Background/` | 🟢 Normal |
| 7 | ไฟล์ซ้ำ: `Walk_Khom.png` (×2), `PCCaseBG.jpg` (×2) | LFS กินที่ฟรี ~900 KB | 🟢 Normal |
| 8 | สะกดผิด: `ramSligtDirty`, `GradmaHighlight`, `Prolouge.txt` | หลายไฟล์ | 🟢 Normal (แก้ทีเดียวพร้อม rename batch) |
| 9 | `stargBG.jpg` ผิดสัดส่วน — ถ้าไม่ใช้แล้วให้ลบ | `Assets/Background/` | 🟢 Normal |

---

## 5. Asset ที่ยังขาด (เรียงตามลำดับที่ควรทำ)

### 5.1 🔴 Tutorial Slides — ขาด 5 จาก 7 state

`Scripts/EventManager/tutorial.gd` ประกาศ
`enum TutorialState { BASIC_START, BASIC_HOME, RAM_CLEANING, MOTHERBOARD, GPU, FRONT_PANEL, BIOS }`
แต่ `Scene/TutorialScene/Tutorial.tscn` ผูกจริงแค่ key `0` (BASIC_START) และ `2` (RAM_CLEANING)

> ⚠️ **เรียก `show_tutorial()` ด้วย state ที่ไม่มีใน dict = crash ทันที** (`_slides[tutor_index]`)
> ฉะนั้นห้าม implement Core Part อีก 4 ตัว ก่อนมีสไลด์ หรือต้องใส่ guard ในโค้ดก่อน

| State | index | โฟลเดอร์ | จำนวนสไลด์ที่แนะนำ | เนื้อหา | สถานะ |
|---|---|---|---|---|---|
| `BASIC_START` | 0 | `Tutorial/BasicStart/` | 3 (`tut_start_01–03.png`) | ปุ่มเดิน WASD, กด E คุย, quest board | ⚠️ มี 1 สไลด์ ผิดขนาด |
| `BASIC_HOME` | 1 | `Tutorial/BasicHome/` | 3 | แผนที่, เวลา เช้า/เที่ยง/เย็น, ประตูเข้าห้อง | ❌ ไม่มี |
| `RAM_CLEANING` | 2 | `Tutorial/RamCleaning/` | 4 | แรมสกปรกคืออะไร, จับยางลบ, คลิกถู, เกณฑ์ผ่าน | ⚠️ มี 1 สไลด์ ผิดขนาด |
| `MOTHERBOARD` | 3 | `Tutorial/Motherboard/` | 5 | standoff, CPU socket, ทิศทางลูกศร, ซิลิโคน, ล็อกคาน | ❌ ไม่มี |
| `GPU` | 4 | `Tutorial/Gpu/` | 4 | PCIe x16, ล็อกสลัก, ต่อไฟ PCIe, airflow/cable | ❌ ไม่มี |
| `FRONT_PANEL` | 5 | `Tutorial/FrontPanel/` | 4 | pin header, POWER SW/RESET, LED มีขั้ว, dual channel สลอตสีเดียวกัน | ❌ ไม่มี |
| `BIOS` | 6 | `Tutorial/Bios/` | 4 | เข้า BIOS, boot order, XMP, ลง OS | ❌ ไม่มี |

**สเปกสไลด์:** `1152 × 648` PNG · ≤ 500 KB · ข้อความภาษาไทยในภาพต้องอ่านออกที่ขนาดจริง (ตัวอักษร ≥ 28 px)
**ชื่อไฟล์:** `tut_<state>_<01..>.png` เช่น `tut_mainboard_01.png`

**Prompt ตัวอย่าง (MOTHERBOARD สไลด์ 2 — CPU socket):**
```
Instructional game tutorial panel, 16:9 layout, showing a cartoon
motherboard from top view with an open CPU socket, a CPU chip held by
a cartoon hand above it, a big arrow pointing to the golden triangle
alignment mark on the corner of the CPU, empty speech balloon space
at the top for Thai text,
<Base Style Prompt>
```
> **สำคัญ:** ให้ AI เว้นพื้นที่ว่างไว้ใส่ข้อความไทย แล้ว **พิมพ์ข้อความไทยทับทีหลัง** (AI สร้างตัวอักษรไทยไม่ถูก)

---

### 5.2 🔴 Part Mainboard–5

ผูกกับ ClickUp: [Part Mainboard](https://app.clickup.com/t/86eyh2w16) · [Part GPU](https://app.clickup.com/t/86eyh2w5k) · [Part Front Panel](https://app.clickup.com/t/86eyh2wba) · [Part BIOS](https://app.clickup.com/t/86eyh2wfd)

**กติกาสำหรับ asset minigame ทุกชิ้น:**
* ทุก state ของชิ้นเดียวกัน **ขนาด canvas เท่ากันเป๊ะ** (เรียนจากปัญหาแรม/caution)
* มุมมอง **top-down ตรง ๆ** (สำหรับเมนบอร์ด/เคส) หรือ **ด้านข้างตรง** (สำหรับชิ้นส่วน) ไม่ perspective
* พื้นโปร่ง ไม่มีเงาทอดลงพื้นในตัวไฟล์ (ทำเงาด้วย node ในเกม)
* วาดชิ้นส่วนใหญ่กว่าที่ใช้จริง ~1.5× แล้วย่อในเกม เผื่อ zoom

#### Part Mainboard — Motherboard + CPU (`Assets/MiniGame/PartMainboard/`)

| ไฟล์ | ขนาด | คำอธิบาย |
|---|---|---|
| `mb_case_open.png` | 900 × 900 | เคสเปิดฝา มุม top-down เห็นรูสกรู standoff |
| `mb_standoff.png` | 60 × 60 | น็อตรองเมนบอร์ด |
| `mb_mainboard.png` | 800 × 760 | เมนบอร์ด ATX เปล่า เห็น socket + สลอตชัด |
| `mb_mainboard_ghost.png` | 800 × 760 | เงาโปร่ง 30% ใช้เป็นจุดวาง (drop target) |
| `mb_cpu.png` | 180 × 180 | CPU เห็นสามเหลี่ยมทองมุมซ้ายล่าง |
| `mb_cpu_wrong.png` | 180 × 180 | CPU หันผิดทิศ (มีเครื่องหมาย ✕ แดง) |
| `mb_socket_open.png` / `mb_socket_closed.png` | 220 × 220 | คานล็อกเปิด/ปิด |
| `mb_thermal_tube.png` | 200 × 90 | หลอดซิลิโคน |
| `mb_thermal_dot.png` | 80 × 80 | หยดซิลิโคนบน CPU |
| `mb_cooler.png` | 300 × 300 | ฮีตซิงก์ + พัดลม |
| `mb_screwdriver.png` | 260 × 260 | ไขควง (เคอร์เซอร์) |

```
Prompt (mb_mainboard.png):
top-down flat view of a cartoon ATX computer motherboard, clearly
readable CPU socket in the upper middle, two pairs of RAM slots on the
right, one long PCIe slot at the bottom, screw holes at the corners,
dark green PCB with warm gold traces, no text labels, transparent
background, <Base Style Prompt>
```

#### Part GPU — GPU + Cable Management (`Assets/MiniGame/PartGpu/`)

| ไฟล์ | ขนาด | คำอธิบาย |
|---|---|---|
| `gpu_card.png` | 620 × 220 | การ์ดจอ 2 พัดลม เห็นแถบทองขา PCIe |
| `gpu_pcie_slot.png` / `gpu_pcie_slot_locked.png` | 520 × 90 | สลอต + สลักล็อก |
| `gpu_psu.png` | 420 × 300 | Power supply |
| `gpu_cable_pcie.png` | 400 × 160 | สาย PCIe 8-pin |
| `gpu_cable_24pin.png` | 420 × 170 | สาย ATX 24-pin |
| `gpu_cable_tie.png` | 120 × 60 | สายรัด |
| `gpu_airflow_arrow.png` | 200 × 100 | ลูกศรทิศลม (ฟ้า `#4A90D9`) |
| `gpu_cable_messy.png` / `gpu_cable_tidy.png` | 900 × 700 | ภาพเปรียบเทียบก่อน/หลังจัดสาย |

#### Part Front Panel — Front Panel + Dual Channel (`Assets/MiniGame/PartFrontPanel/`)

| ไฟล์ | ขนาด | คำอธิบาย |
|---|---|---|
| `fp_pin_header.png` | 340 × 200 | บล็อก pin header ซูมใหญ่ เห็นแต่ละพินชัด |
| `fp_connector_power_sw.png` | 120 × 80 | หัวต่อ POWER SW |
| `fp_connector_reset_sw.png` | 120 × 80 | RESET SW |
| `fp_connector_power_led.png` | 120 × 80 | POWER LED (มีขั้ว +/-) |
| `fp_connector_hdd_led.png` | 120 × 80 | HDD LED |
| `fp_ram_stick.png` | 500 × 120 | แรม 1 แถว (ใช้ซ้ำได้ 4 ตัว) |
| `fp_slot_a1.png` … `fp_slot_b2.png` | 520 × 60 | สลอตแรม 4 ช่อง แยกสีคู่ A/B ชัดเจน |
| `fp_led_on.png` / `fp_led_off.png` | 64 × 64 | ไฟหน้าเคสติด/ดับ (feedback) |

#### Part BIOS — BIOS + OS + Upgrade (`Assets/MiniGame/PartBios/`)

| ไฟล์ | ขนาด | คำอธิบาย |
|---|---|---|
| `bios_screen.png` | 1152 × 648 | หน้าจอ BIOS สไตล์การ์ตูน (เว้นที่ใส่ข้อความไทย) |
| `bios_boot_order_item.png` | 420 × 70 | แถบรายการ boot ลากสลับได้ |
| `bios_xmp_toggle_off/on.png` | 160 × 80 | สวิตช์ XMP |
| `bios_usb_installer.png` | 200 × 90 | USB ลง OS |
| `bios_progress_bar.png` | 700 × 60 | แถบติดตั้ง |
| `bios_bottleneck_chart.png` | 600 × 400 | กราฟเปรียบเทียบ CPU/GPU แบบการ์ตูน |

---

### 5.3 🔴 มาสคอต "ปิ๊บ" (Pib) — ยังไม่มีไฟล์ใด ๆ ในรีโป

GDD ระบุให้ปิ๊บเป็นผู้นำเสนอ tutorial (Layer 2–3) แต่ในโค้ดและ asset **ยังไม่มีอะไรเลย**

| ไฟล์ | ขนาด | ใช้ตอน |
|---|---|---|
| `char_pib_normal.png` | 400 × 500 | สถานะปกติ |
| `char_pib_happy.png` | 400 × 500 | ชมเมื่อทำถูก |
| `char_pib_worry.png` | 400 × 500 | เตือนเมื่อทำผิด |
| `char_pib_point.png` | 400 × 500 | ชี้ไปที่เป้าหมาย (ใช้ใน tutorial overlay) |
| `char_pib_idle_sheet.png` | 1600 × 500 (4 เฟรม) | ลอยกระพริบเบา ๆ |

```
Prompt:
cute small cartoon mascot character for a Thai computer-repair game,
a friendly round robot made from an old PC power button and a small
screwdriver arm, big expressive eyes, warm orange body #E8A854 with
blue screen face #4A90D9, floating pose, full body, facing viewer,
transparent background, <Base Style Prompt>
```
> ทำ 4 อารมณ์จาก **ตัวเดียวกัน** (seed เดิม) เพื่อให้หน้าตาเหมือนกันทุกไฟล์

---

### 5.4 🔴 ตัวละคร dialog ที่ไฟล์บทมีแล้วแต่ยังไม่มี sprite

`Scene/Global.tscn` มี `_CharacterMap` แค่ 2 คน: `"ขม"`, `"ยาย"`
แต่ `Assets/Dialog/*.txt` เรียกชื่ออีกหลายคน — `Global.getCharacterSprite()` จะ **crash** ถ้าชื่อไม่อยู่ใน map

จำนวนบรรทัดที่พูดจริงในไฟล์บททั้งหมด:

| ชื่อ (ต้องใช้เป็น key เป๊ะ) | บรรทัด | ไฟล์ที่เสนอ | ความสำคัญ |
|---|---|---|---|
| ขม | 64+ | มีแล้ว (`Idle.png`) | ✅ |
| ยาย | 19+ | มีแล้ว (`GrandmaNormal.png`) | ✅ |
| มิ้น | 13+ | `char_min_normal.png` | 🔴 Urgent |
| ลุงอำนวย | 3 | `char_amnuay.png` | 🟡 High |
| ผอ. | 3 | `char_director.png` | 🟡 High |
| ผู้ใหญ่บ้าน | 2 | `char_headman.png` | 🟡 High |
| ครู | 2 | `char_teacher.png` | 🟡 High |
| เด็กหญิง / เด็ก | 4 | `char_girl.png`, `char_kid.png` | 🟡 High |
| เพื่อนร่วมงาน | 2 | `char_coworker.png` | 🟢 Normal |
| หัวหน้า | 1 | `char_boss.png` | 🟢 Normal |

**สเปก:** PNG พื้นโปร่ง, สูง **420–560 px**, ครึ่งตัวถึงเข่า, หันเข้าหากลางจอ, ยืนตรง ไม่มีเงาพื้น
(ตำแหน่งวางใน `Dialog_Scene.tscn` → `CharacterPos` มี 4 มาร์ก: Left1 `-417,78`, Left2 `-530,78`, Right1 `345,78`, Right2 `469,75` เทียบจุดกลางจอ `576,324`)

> **บรรทัดพิเศษที่ต้องระวัง:** ในไฟล์บทมีชื่อแบบ `ขม (ยิ้ม)`, `มิ้น (กระซิบ)`, `คำบรรยาย`, `ผู้เล่น`
> `"คำบรรยาย"` / `"ผู้เล่น"` เป็นข้อความบรรยาย **ไม่ต้องมี sprite** แต่โค้ดปัจจุบันยังไม่ได้แยกกรณีนี้
> ส่วน `ขม (ยิ้ม)` จะถูกมองเป็นคนละคนกับ `ขม` — ต้องตัดสินใจว่าจะทำ sprite แยกอารมณ์ หรือแก้ parser (แนะนำอย่างหลัง)

---

### 5.5 🟡 Background ที่ยังขาด

Chapter 3–12 มีไฟล์บทครบแล้ว (`Assets/Dialog/`) แต่ไม่มี BG ประกอบ

| ไฟล์ที่เสนอ | ใช้กับ | คำอธิบายฉาก |
|---|---|---|
| `bg_shop_empty.jpg` | Ch.3 ตกแต่งบ้าน | ห้องโล่ง ๆ ก่อนเป็นร้าน |
| `bg_shop_open.jpg` | Ch.4 เปิดร้าน | ร้านซ่อมคอมพร้อมป้าย โต๊ะซ่อม |
| `bg_shop_quiet.jpg` | Ch.5 ร้านเงียบ | ร้านเดิม แสงเย็น ไม่มีลูกค้า |
| `bg_shop_busy.jpg` | Ch.6 ร้านคึกคัก | ร้านเดิม มีลูกค้า กล่องงานซ้อน |
| `bg_school_room.jpg` | Ch.7/9 สอน/โรงเรียน | ห้องเรียนชนบท คอมเก่า |
| `bg_village_day.jpg` | Ch.10 หมู่บ้าน | ถนนดินในหมู่บ้าน |
| `bg_path_sunset.jpg` | Ch.11 เส้นทาง | ทางเดินทุ่งนา ตะวันตกดิน |
| `bg_year_after.jpg` | Ch.12 / Epilogue | ร้านหลังผ่านไป 1 ปี |
| `bg_office_new.jpg` | Prologue | **แทน `Office.png` ที่ผิดสัดส่วน** — ออฟฟิศเมืองสีเย็น ตัดกับชนบทสีอุ่น |

**สเปก:** 1152 × 648 JPG · ≤ 300 KB · **ไม่มีตัวละครในภาพ** (ตัวละครวางทับด้วย sprite) · เว้นพื้นที่ล่าง ~200 px ให้กล่องข้อความ (กล่อง dialog สูง 200 px ตาม `Dialog_Scene.tscn`)

```
Prompt (bg_shop_open.jpg):
2D game background, interior of a small rural Thai computer repair shop,
wooden workbench with an open PC case and tools, shelves of spare parts,
warm afternoon light through a window, no people, no text,
wide 16:9 composition with empty space in the lower third,
<Base Style Prompt>
```

---

### 5.6 🟡 UI Kit — [ClickUp: UI Elements](https://app.clickup.com/t/86ey2ead6)

ตอนนี้ UI ทั้งเกมเป็น StyleBox สีล้วน + ปุ่ม default ของ Godot

| กลุ่ม | ไฟล์ | ขนาด |
|---|---|---|
| ปุ่มหลัก (9-patch) | `ui_btn_normal.png` / `_hover.png` / `_press.png` / `_disabled.png` | 320 × 96 (margin 24 px ทุกด้าน) |
| กล่องข้อความ dialog | `ui_dialog_box.png` | 1152 × 200 |
| ป้ายชื่อผู้พูด | `ui_name_plate.png` | 340 × 72 |
| กรอบ Quest Board | `ui_quest_panel.png` | 420 × 300 |
| แถบเวลา | `ui_time_panel.png` | 360 × 80 |
| ไอคอนช่วงเวลา | `ui_icon_morning.png` / `_noon.png` / `_evening.png` | 64 × 64 |
| ไอคอนเงิน / XP / ยศ | `ui_icon_coin.png` / `ui_icon_xp.png` / `ui_rank_1..5.png` | 64 × 64 |
| ปุ่มปิด / ถัดไป / ย้อนกลับ | `ui_btn_close.png`, `ui_btn_next.png`, `ui_btn_prev.png` | 96 × 96 |
| เครื่องหมายเป้าหมาย | `ui_marker_caution.png` (3 state **ขนาดเท่ากัน**) | 250 × 250 |
| ปุ่มแผนที่ | `ui_btn_map.png` | 128 × 128 |

> ปุ่มที่จะใช้เป็น 9-patch ให้ generate เป็นภาพสี่เหลี่ยมมุมโค้งเรียบ ๆ **ไม่มีข้อความในภาพ** (ใส่ข้อความด้วย Label ในเกม)

---

### 5.7 🟢 Ending + Credits — [ClickUp](https://app.clickup.com/t/86ey2eaee)

| ไฟล์ | ขนาด | คำอธิบาย |
|---|---|---|
| `end_stay_village.jpg` | 1152 × 648 | Ending A: ขมอยู่ต่อ เปิดร้าน สอนเด็ก |
| `end_back_city.jpg` | 1152 × 648 | Ending B: ขมกลับเมือง มองย้อนกลับ |
| `end_expand_shop.jpg` | 1152 × 648 | Ending C: ร้านขยาย มีลูกศิษย์ |
| `credits_bg.jpg` | 1152 × 648 | พื้นหลังจาง ๆ สำหรับเลื่อนเครดิต |

> ยังไม่มีระบบ Ending ในโค้ด (`event_manager.gd` มี `EventID { NONE, MAIN }` เท่านั้น) — asset ชุดนี้ทำทีหลังได้

---

### 5.8 🟡 Audio — [ClickUp](https://app.clickup.com/t/86ey2eadn)

**ในเกมยังไม่มีไฟล์เสียงเลยแม้แต่ไฟล์เดียว** และยังไม่มี AudioStreamPlayer ใน scene ใด

| ไฟล์ | ประเภท | ความยาว | อารมณ์ |
|---|---|---|---|
| `bgm_main_menu.ogg` | BGM loop | 60–90 s | อบอุ่น ช้า เครื่องสายพื้นบ้าน |
| `bgm_home.ogg` | BGM loop | 90 s | สบาย ๆ กลางวัน |
| `bgm_shop.ogg` | BGM loop | 90 s | ขยันขันแข็ง จังหวะเบา |
| `bgm_minigame.ogg` | BGM loop | 60 s | โฟกัส เร่งเล็กน้อย |
| `bgm_emotional.ogg` | BGM loop | 60 s | เปียโนช้า สำหรับฉากซึ้ง |
| `sfx_dialog_blip.wav` | SFX | 0.1 s | เสียงตัวอักษรวิ่ง |
| `sfx_click.wav` / `sfx_hover.wav` | SFX | 0.1 s | ปุ่ม |
| `sfx_rub.wav` | SFX | 0.3 s | ถูยางลบ (Part RAM) |
| `sfx_click_in.wav` | SFX | 0.2 s | เสียบชิ้นส่วนเข้าที่ |
| `sfx_error.wav` | SFX | 0.3 s | ทำผิด |
| `sfx_success.wav` | SFX | 1.0 s | ผ่านมินิเกม |
| `sfx_rank_up.wav` | SFX | 1.5 s | เลื่อนยศ |
| `sfx_pc_boot.wav` | SFX | 2.0 s | เครื่องบูตติด (Part BIOS) |

**สเปก:** BGM = `.ogg` loop seamless, −16 LUFS · SFX = `.wav` 16-bit 44.1 kHz mono, −12 dBFS peak
**ต้องมีในโค้ดก่อน:** autoload `AudioManager` + bus `Master / BGM / SFX` (ยังไม่มี)

---

## 6. Pipeline: นำ asset เข้าเกม

### 6.1 ทุกไฟล์ภาพ
1. วางไฟล์ในโฟลเดอร์ตามหัวข้อ 1.4
2. เปิด Godot → รอ import เสร็จ → จะได้ไฟล์ `.import`
3. เลือกไฟล์ → แท็บ Import → ตั้ง **Filter = Off** สำหรับงาน pixel-crisp, **On** สำหรับภาพวาดที่ต้องย่อ/ขยาย → Reimport
4. `git add <ไฟล์> <ไฟล์>.import` (LFS จับ `.png`/`.jpg` ให้อัตโนมัติ — เช็คด้วย `git lfs ls-files`)

### 6.2 Background ที่ใช้ใน Dialog
`EventManager.show_dialog(title, file_path, bg_name, chars)` รับ **ชื่อไฟล์เปล่า ๆ** ไม่ใช่ path เต็ม
(`dialog_scene.gd` ต่อ `res://Assets/Background/` ให้เอง)

```gdscript
EventManager.show_dialog("ร้านของขม", Constant.CHAPTER3_TEXT, "bg_shop_empty.jpg", ["ขม", "มิ้น"])
```
แล้วเพิ่มค่าคงที่ใน `Scripts/constant.gd`:
```gdscript
const BG_SHOP_EMPTY = "bg_shop_empty.jpg"
```

### 6.3 ตัวละครใหม่
1. วาง PNG ที่ `Assets/CharacterSprite/`
2. เปิด `Scene/Global.tscn` → เลือก node `Global` → Inspector → `_CharacterMap` → เพิ่ม key/value
3. **key ต้องตรงกับชื่อในไฟล์ `.txt` ทุกตัวอักษร** (ระวังช่องว่างท้ายบรรทัดในบท — parser ตัด leading space ให้ แต่ต้องเช็ค)
4. ส่งชื่อนั้นเข้า `chars` ตอนเรียก `show_dialog()`

### 6.4 Tutorial slide ใหม่
1. วางภาพใน `Assets/Tutorial/<State>/` ตามลำดับ `_01`, `_02`, …
2. สร้าง Resource ใหม่: Godot → FileSystem → New Resource → `TutorialSlides` → เซฟที่ `Resources/tutorial_<state>.tres`
3. ใส่ภาพเรียงลำดับใน `ImageSlide`
4. เปิด `Scene/TutorialScene/Tutorial.tscn` → node `Tutorial` → `TutorialSlide` dict → เพิ่ม key = เลข index ของ `TutorialState` (MOTHERBOARD = 3, GPU = 4, FRONT_PANEL = 5, BIOS = 6)
5. เรียกใช้: `EventManager.show_tutorial(EventManager.TutorialState.MOTHERBOARD)`

> 🐞 **บั๊กที่ต้องแก้ควบคู่:** `tutorial_slides.gd` ไม่รีเซ็ต `curIndex` ตอน `show_tutorial()`
> → เปิด tutorial เดิมซ้ำจะเริ่มที่สไลด์สุดท้ายทันที · และ `get_cur_slide()` ยังมี `print_rich(_slides)` ค้างอยู่

### 6.5 MiniGame ใหม่
1. สร้าง scene ที่ `Scene/MiniGame/Minigame<N>.tscn`
2. เพิ่มค่าคงที่พาธใน `Scripts/constant.gd` (เช่น `const MINIGAME2_SCENE = "res://Scene/MiniGame/PartMainboard.tscn"`)
3. โหลดจาก `EventManager.trigger_step()` ด้วย `load(Constant.MINIGAME2_SCENE).instantiate()`
   *(ตั้งแต่ commit `46a5a7b` `Global.MiniGames` / `ReturnMiniGame()` ถูกลบแล้ว)*

> 🐞 **บั๊กที่ต้องแก้ก่อนทำ Part Mainboard:** `Scripts/Room/room.gd` บรรทัด 3 instantiate มินิเกมครั้งเดียวเก็บเป็นตัวแปรสมาชิก แต่ `minigame1.gd::_on_return_pressed()` เรียก `queue_free()` → เข้ามินิเกมรอบที่ 2 จะ `add_child` โนดที่ถูกปล่อยไปแล้ว

---

## 7. Definition of Done ต่อ asset 1 ชิ้น

- [ ] ขนาดตรงสเปกในตาราง (BG = 1152×648)
- [ ] ฟอร์แมตถูก (พื้นโปร่ง = PNG / เต็มจอ = JPG)
- [ ] ชื่อไฟล์ ASCII snake_case ไม่มีเว้นวรรค
- [ ] ขนาดไฟล์ไม่เกินเพดานในหัวข้อ 1.2
- [ ] ทุก state ของชิ้นเดียวกันขนาด canvas เท่ากัน
- [ ] สีอยู่ในพาเลตต์หัวข้อ 2.3 · outline `#2C1810`
- [ ] ไม่มีข้อความฝังในภาพ (ยกเว้น tutorial slide ที่พิมพ์ทับเองทีหลัง)
- [ ] import ใน Godot แล้ว และ commit `.import` ไปด้วย
- [ ] ผูกเข้าโค้ดแล้ว (Constant / `_CharacterMap` / `.tres` / scene) — ไม่ใช่แค่วางไฟล์ทิ้งไว้
- [ ] เปิดเกมดูจริงที่ 1152×648 แล้วไม่ยืด ไม่เบลอ ไม่กระตุกตอนสลับ state

---

## 8. ลำดับการทำ (แนะนำ)

| รอบ | งาน | จำนวนชิ้นโดยประมาณ |
|---|---|---|
| **1** | แก้ asset เดิมข้อ 1–5 ในหัวข้อ 4 (tutorial slide, Office, caution, ram, door) | ~10 |
| **2** | sprite `มิ้น` + มาสคอตปิ๊บ 4 อารมณ์ | 5 |
| **3** | Tutorial slides `BASIC_START` (3) + `BASIC_HOME` (3) + `RAM_CLEANING` (4) ให้ครบชุดถูกขนาด | 10 |
| **4** | UI Kit หัวข้อ 5.6 | ~20 |
| **5** | Part Mainboard + tutorial slides | ~16 |
| **6** | Audio ชุดแรก (BGM 3 + SFX 6) | 9 |
| **7** | BG Chapter 3–12 | 9 |
| **8** | Part GPU–5 + tutorial slides | ~40 |
| **9** | Ending + Credits | 4 |

---

## 9. ประวัติเอกสาร

| วันที่ | การเปลี่ยนแปลง |
|---|---|
| 21 ก.ย. 2569 | เพิ่มหัวข้อ 3.9 — asset ที่เข้ามาใหม่ (box) + ปัญหา `.import` ไม่ตรงชื่อ 39 คู่ หลัง rename Tier→Part |
| 16 ก.ย. 2569 (2) | เพิ่มหัวข้อ 3.8 — สรุปชุด asset รอบใหม่ 84 ไฟล์ที่ย้ายจาก `Assets/Gen/` เข้าโครงจริง พร้อมรายการที่ยังขาดและงานที่ต้องทำก่อนใช้ |
| 16 ก.ย. 2569 | สร้างเอกสาร — ตรวจ asset จริงทั้งหมดที่ commit `8c4db20`, เทียบกับ `TutorialState` 7 ค่า, `_CharacterMap` 2 คน, และรายชื่อตัวละครในไฟล์บททั้งหมด |
