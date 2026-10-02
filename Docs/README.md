# Docs — สารบัญเอกสารออกแบบ BakChangKhom

อัปเดต 30 ก.ย. 2569 · อ้างอิงโค้ดที่ commit `65bddbf` (ฉากมินิเกมเป็น 2D ทั้งหมดแล้ว — ดู `SCENE_2D.md`)

## ภาพรวมระบบ

| ไฟล์ | เนื้อหา |
|---|---|
| `GAME_LOOP.md` | **ลูปเกมทั้งเกม** — 1 วัน (เช้า/เที่ยง/เย็น) → 7 วัน = 1 Chapter → 12 Chapter → ฉากจบ · เทียบกับโค้ดที่มีแล้ว + ลำดับทำให้เล่นจบลูป (2 ต.ค. 2569) |
| `REPAIR_FLOW.md` | **เริ่มอ่านที่นี่** — ลูปงานซ่อม 5 scene (ShopCounter → Workbench → PartView → Reassemble → Handover), Part 13 ชิ้น, เครื่องมือ 21 ชิ้น, สเปก Resource/Manager/Scene |
| `ASSET_RENAME.md` | ไฟล์ที่ชื่อยังไม่ตรงกฎ 38 ไฟล์ + ไฟล์ใหม่จากทีม · บอกชื่อใหม่และจุดที่โค้ดอ้างถึง |
| `ASSET_NAMING.md` | **รายชื่อไฟล์ asset ฉบับอ้างอิงเดียว** — ชื่อไฟล์ + ขนาด canvas + สถานะ ของทั้ง 142 ไฟล์ · ตั้งชื่อไฟล์ใหม่ให้ดูจากที่นี่ |
| `ASSET_GUIDE.md` | คู่มือสร้าง asset — ขนาด/ฟอร์แมต/ชื่อไฟล์/prompt/pipeline + inventory ปัจจุบัน |
| `ASSET_STATUS.md` | **ผลตรวจไฟล์จริงในโฟลเดอร์** เทียบกับเช็กลิสต์ — เพิ่มไปแล้วกี่ไฟล์ เหลืออะไร ไฟล์ไหนมีแล้วแต่ใช้ไม่ได้ |
| `ASSET_TODO.md` | เช็กลิสต์ asset ที่ต้องทำ เรียงตามลำดับ |
| `DIAGRAMS.md` + `Diagrams/` | ไดอะแกรม 9 ภาพสำหรับเล่มรายงาน (PNG 300 dpi + SVG) พร้อมคำบรรยายใต้ภาพ |
| `UI_MOCKUP.md` + `Mockups/` | mockup 4 หน้าจอประกอบจาก asset จริง — ตารางตำแหน่ง x/y/w/h ทุกช่อง + สรุป asset ที่ยังขาด 23 ไฟล์ |
| `STORYBOARD.md` | Low-fi wireframe 40 เฟรมของ Core Part ทั้ง 5 + เลย์เอาต์กลาง + prompt pack สำหรับสั่ง AI ทำ storyboard |
| `BUG_LIST.md` | บั๊กทั้งหมดที่ตรวจพบ พร้อมสถานะ |
| `Storyboard/CROP_REPORT.md` | ผลตรวจ asset ที่ crop มาจาก sheet (ผ่าน/ลบเศษ/ต้องทำใหม่) |
| `SYNC_REVIEW.md` | ผลเทียบโค้ดจริงกับดีไซน์ + วิธีแก้ทีละข้อ |

## ฉากมินิเกม 2D (ปัจจุบัน)

`SCENE_2D.md` — **เริ่มอ่านที่นี่ถ้าจะแตะฉากมินิเกม** · 30 ก.ย. แทนระบบ 3D/2.5D เดิมทั้งหมดด้วย Control 2D (`Stage2D` · `View2D` · `Item2D` · `Socket2D` · `Hotspot2D` · `Phase2D`) · รูปอยู่ `Assets/MiniGame/Scene2D/` (ต้นฉบับ SVG ใน `src/`)

## แนวภาพ 2.5D (เอกสารประวัติ)

> ⚠️ ใช้เป็นประวัติเท่านั้น — ชื่อคลาส/กล้อง/พิกัด 3D ล้าสมัยแล้ว

`ART_25D_PLAN.md` — แผน 3 ช่วง (Core Part ก่อน → ฉากนิ่ง → world แบบ HD-2D) + วิธีทำโมเดลแบบกล่องแปะรูปให้เปลือง token น้อยสุด

## เกมเพลย์ 2.5D

`RAM_3D_GAMEPLAY.md` — **Part RAM เล่นได้ครบ 8 phase** (เขียนตอนเป็น 3D · 30 ก.ย. เปลี่ยนเป็น 2D แล้ว → flow/คะแนนยังใช้ได้ ส่วนโหนดและกล้องดู `SCENE_2D.md`) · flow · node ในซีน · มุมกล้อง · asset · โครงไฟล์ใหม่

## มินิเกม Tutorial (เล่นก่อน Core Part)

| มินิเกม | ไฟล์ | ความรู้หลัก |
|---|---|---|
| ประกอบคอมพิวเตอร์ (2D) | `TUTORIAL_ASSEMBLY_DESIGN.md` | **เล่นได้แล้ว 4 phase และผูกเข้าเควสต์หลักแล้ว** (ต่อจากหายางลบ ก่อน tutorial/มินิเกมแรม) · ชื่อ/หน้าที่ชิ้นส่วน 7 ชิ้น · ลำดับประกอบ · ยังขาด SAFETY/CABLES/CLOSE |

## มินิเกม Core Part 5 ตัว

> **ตัดสินใจ 2 ต.ค. 2569:** ไม่มีทีมอาร์ตและทีมเสียง — ภาพที่ Claude วาด (SVG ต้นฉบับใน `src/` ของแต่ละ Part + PNG) **ใช้เป็นภาพจริง** ไม่ใช่ placeholder แล้ว · ภาพใหม่/แก้ภาพให้ Claude วาดต่อจาก SVG เดิม · เกมไม่มีเสียงไปก่อน

| Part | ไฟล์ | ยศ | ความรู้หลัก |
|---|---|---|---|
| RAM | `MINIGAME1_DESIGN.md` | ช่างมือใหม่ | ขาทอง · ทำความสะอาดหน้าสัมผัส · เลือกอุปกรณ์ |
| Mainboard + CPU | `PART_MAINBOARD_DESIGN.md` | ช่างฝึกหัด | standoff · ทิศ CPU · ซิลิโคน · ขันไขว้ — **เล่นได้แล้ว (2 ต.ค.) เปิดจาก Debug F1 · ยังไม่ผูกเควสต์** |
| GPU | `PART_GPU_DESIGN.md` | ช่างประจำหมู่บ้าน | PCIe · สลัก · สายไฟ PCIe vs CPU · airflow — **เล่นได้แล้ว (2 ต.ค.) เปิดจาก Debug F1 · ยังไม่ผูกเควสต์** |
| Front Panel | `PART_FRONTPANEL_DESIGN.md` | ช่างเชี่ยวชาญ | pin header · ขั้ว LED · dual channel — **เล่นได้แล้ว (2 ต.ค.) เปิดจาก Debug F1 · ยังไม่ผูกเควสต์** |
| BIOS + OS | `PART_BIOS_DESIGN.md` | ช่างระดับมือโปร | boot order · XMP · ลง OS · bottleneck — **เล่นได้แล้ว (2 ต.ค.) เปิดจาก Debug F1 · ยังไม่ผูกเควสต์** |

**โครงร่วมของทุก Part:** 8 phase · ปิ๊บสอนผ่าน `PibHint` · ระบบเลือกอุปกรณ์/ตัวเลือกที่มีทั้ง ✅ 🟡 ❌ · ผิดครั้งแรกปิ๊บห้ามทันไม่เสียหาย · คะแนนเต็ม 100 ผ่าน ≥ 60 (⭐ 60 / ⭐⭐ 80 / ⭐⭐⭐ 95)

## ลำดับที่แนะนำให้ทำ

1. แก้ที่เหลือใน `BUG_LIST.md` (ที่ยังเป็น ⬜)
2. ตัดสินใจเรื่อง Player / MainGame.tscn (BUG-15) ก่อนเริ่ม scene ใหม่
3. ทำ asset ชุด A + B ใน `ASSET_TODO.md`
4. ~~implement Core Part: RAM ให้ครบ 8 phase เป็นต้นแบบ~~ ✅ เล่นได้ครบแล้ว (2D) — เหลือภาพที่ยังขาด (Claude วาดแทน) และย้อน phase ตอน VERIFY ไม่ผ่าน
4b. ต่อยอด Tutorial ประกอบคอม (SAFETY · CABLES · CLOSE · เช็กทิศ CPU/แรม) แล้วทำ Core Part ถัดไปจากโครง `part_ram.tscn`
5. ทำ `RepairManager` + Scene S1/S2 ตาม `REPAIR_FLOW.md`
6. ~~ขยาย Core Part ที่เหลือทีละตัวด้วยโครงเดียวกัน~~ ✅ ครบ 5 ตัวแล้ว (RAM · Mainboard · GPU · Front Panel · BIOS · 2 ต.ค. 2569) — เหลือผูกเข้าเควสต์/RepairManager


## ไฟล์บทของปิ๊บ (`Assets/Dialog/MiniGame/`)

| ไฟล์ | บทพูด | section | ใช้กับ |
|---|---|---|---|
| `Ram_Pib.txt` | 57 | 32 | Core Part RAM |
| `Mainboard_Pib.txt` | 40 | 27 | Core Part Mainboard + CPU |
| `Gpu_Pib.txt` | 36 | 24 | Core Part GPU |
| `FrontPanel_Pib.txt` | 44 | 33 | Core Part Front Panel |
| `Bios_Pib.txt` | 59 | 42 | Core Part BIOS |
| `Assembly_Pib.txt` | — | — | Tutorial ประกอบคอม (ใช้งานจริงแล้ว) |
| `FindEraser.txt` | 4 | 4 | มินิเกมหายางลบ (แทน `dialog_arr` ในสคริปต์) |

### ฟอร์แมต

```
# คอมเมนต์ธรรมดา parser ข้ามให้
@SECTION_NAME          ← หัวข้อ section สำหรับ PibHint ใช้ค้นหา (ต้องขึ้นต้นด้วย @ ตัวแรกของบรรทัด ห้ามมี # นำหน้า)
ปิ๊บ,ข้อความที่จะพูด
ปิ๊บ,บรรทัดถัดไปในหัวข้อเดียวกัน
```

**กฎที่ตรวจแล้วว่าไฟล์ทั้ง 6 ผ่านครบ**

1. หนึ่งบรรทัดมี **คอมมาเดียว** เท่านั้น — `parse_text()` ใช้ `split(",")` แล้วอ่าน `body[1]` คอมมาเกินจะทำให้ข้อความขาด
2. **ห้ามมีเครื่องหมาย colon** ในบรรทัดบท — parser จะคิดว่าเป็น header ของ choice block
3. ชื่อหน้าคอมมาต้องตรงกับ key ใน `Global._CharacterMap` เป๊ะ
4. ไฟล์ต้องเป็น `.txt` และอยู่ใต้ `Assets/` (export preset กรองด้วย `include_filter="*.txt"`)
5. หัวข้อ phase ต้องเป็น `@SECTION_NAME` ล้วน ๆ — `Scripts/MiniGame/PartBase/phase_dialog_parser.gd` เช็ก `#` ก่อน `@` เสมอ ถ้าเขียน `# @SECTION_NAME` จะโดนอ่านเป็นคอมเมนต์เฉย ๆ แล้ว section นั้นหายไปทั้งก้อนแบบเงียบ ๆ

### ⚠️ ต้องทำก่อนใช้ไฟล์เหล่านี้

- [ ] เพิ่ม `"ปิ๊บ"` เข้า `_CharacterMap` ใน `Scene/Global.tscn` (sprite มีแล้ว 5 อารมณ์ที่ `Assets/CharacterSprite/char_pib_*.png`)
- [x] เขียนคอมโพเนนต์ `PibHint` (`Scripts/MiniGame/PartBase/pib_hint.gd`) + parser `PhaseDialogParser` (`Scripts/MiniGame/PartBase/phase_dialog_parser.gd`) ที่อ่านไฟล์แล้วแยกตาม `@SECTION` — `DialogScene` เดิมอ่านทั้งไฟล์รวดเดียว ใช้กับ section ไม่ได้ (ตอนนี้ผูกใช้งานจริง `Ram_Pib.txt` ผ่าน `part_ram.gd` และ `Assembly_Pib.txt` ผ่าน `tutorial_assembly.gd`; อีก 4 ไฟล์แก้ format ให้ใช้กับ parser ได้แล้วแต่ยังไม่มีสคริปต์มินิเกมเรียกใช้)
