# Docs — สารบัญเอกสารออกแบบ BakChangKhom

อัปเดต 22 ก.ย. 2569 · อ้างอิงโค้ดที่ commit `1c9040a`

## ภาพรวมระบบ

| ไฟล์ | เนื้อหา |
|---|---|
| `REPAIR_FLOW.md` | **เริ่มอ่านที่นี่** — ลูปงานซ่อม 5 scene (ShopCounter → Workbench → PartView → Reassemble → Handover), Part 13 ชิ้น, เครื่องมือ 21 ชิ้น, สเปก Resource/Manager/Scene |
| `ASSET_GUIDE.md` | คู่มือสร้าง asset — ขนาด/ฟอร์แมต/ชื่อไฟล์/prompt/pipeline + inventory ปัจจุบัน |
| `ASSET_TODO.md` | เช็กลิสต์ asset ที่ต้องทำ เรียงตามลำดับ |
| `DIAGRAMS.md` + `Diagrams/` | ไดอะแกรม 9 ภาพสำหรับเล่มรายงาน (PNG 300 dpi + SVG) พร้อมคำบรรยายใต้ภาพ |
| `STORYBOARD.md` | Low-fi wireframe 40 เฟรมของ Core Part ทั้ง 5 + เลย์เอาต์กลาง + prompt pack สำหรับสั่ง AI ทำ storyboard |
| `BUG_LIST.md` | บั๊กทั้งหมดที่ตรวจพบ พร้อมสถานะ |
| `SYNC_REVIEW.md` | ผลเทียบโค้ดจริงกับดีไซน์ + วิธีแก้ทีละข้อ |

## มินิเกม Core Part 5 ตัว

| Part | ไฟล์ | ยศ | ความรู้หลัก |
|---|---|---|---|
| RAM | `MINIGAME1_DESIGN.md` | ช่างมือใหม่ | ขาทอง · ทำความสะอาดหน้าสัมผัส · เลือกอุปกรณ์ |
| Mainboard + CPU | `PART_MAINBOARD_DESIGN.md` | ช่างฝึกหัด | standoff · ทิศ CPU · ซิลิโคน · ขันไขว้ |
| GPU | `PART_GPU_DESIGN.md` | ช่างประจำหมู่บ้าน | PCIe · สลัก · สายไฟ PCIe vs CPU · airflow |
| Front Panel | `PART_FRONTPANEL_DESIGN.md` | ช่างเชี่ยวชาญ | pin header · ขั้ว LED · dual channel |
| BIOS + OS | `PART_BIOS_DESIGN.md` | ช่างระดับมือโปร | boot order · XMP · ลง OS · bottleneck |

**โครงร่วมของทุก Part:** 8 phase · ปิ๊บสอนผ่าน `PibHint` · ระบบเลือกอุปกรณ์/ตัวเลือกที่มีทั้ง ✅ 🟡 ❌ · ผิดครั้งแรกปิ๊บห้ามทันไม่เสียหาย · คะแนนเต็ม 100 ผ่าน ≥ 60 (⭐ 60 / ⭐⭐ 80 / ⭐⭐⭐ 95)

## ลำดับที่แนะนำให้ทำ

1. แก้ที่เหลือใน `BUG_LIST.md` (ที่ยังเป็น ⬜)
2. ตัดสินใจเรื่อง Player / MainGame.tscn (BUG-15) ก่อนเริ่ม scene ใหม่
3. ทำ asset ชุด A + B ใน `ASSET_TODO.md`
4. implement Core Part: RAM ให้ครบ 8 phase เป็นต้นแบบ
5. ทำ `RepairManager` + Scene S1/S2 ตาม `REPAIR_FLOW.md`
6. ขยาย Core Part ที่เหลือทีละตัวด้วยโครงเดียวกัน


## ไฟล์บทของปิ๊บ (`Assets/Dialog/MiniGame/`)

| ไฟล์ | บทพูด | section | ใช้กับ |
|---|---|---|---|
| `Ram_Pib.txt` | 57 | 32 | Core Part RAM |
| `Mainboard_Pib.txt` | 40 | 27 | Core Part Mainboard + CPU |
| `Gpu_Pib.txt` | 36 | 24 | Core Part GPU |
| `FrontPanel_Pib.txt` | 28 | 20 | Core Part Front Panel |
| `Bios_Pib.txt` | 34 | 21 | Core Part BIOS |
| `FindEraser.txt` | 4 | 4 | มินิเกมหายางลบ (แทน `dialog_arr` ในสคริปต์) |

### ฟอร์แมต

```
# คอมเมนต์ธรรมดา parser ข้ามให้
# @SECTION_NAME        ← หัวข้อ section สำหรับ PibHint ใช้ค้นหา
ปิ๊บ,ข้อความที่จะพูด
ปิ๊บ,บรรทัดถัดไปในหัวข้อเดียวกัน
```

**กฎที่ตรวจแล้วว่าไฟล์ทั้ง 6 ผ่านครบ**

1. หนึ่งบรรทัดมี **คอมมาเดียว** เท่านั้น — `parse_text()` ใช้ `split(",")` แล้วอ่าน `body[1]` คอมมาเกินจะทำให้ข้อความขาด
2. **ห้ามมีเครื่องหมาย colon** ในบรรทัดบท — parser จะคิดว่าเป็น header ของ choice block
3. ชื่อหน้าคอมมาต้องตรงกับ key ใน `Global._CharacterMap` เป๊ะ
4. ไฟล์ต้องเป็น `.txt` และอยู่ใต้ `Assets/` (export preset กรองด้วย `include_filter="*.txt"`)

### ⚠️ ต้องทำก่อนใช้ไฟล์เหล่านี้

- [ ] เพิ่ม `"ปิ๊บ"` เข้า `_CharacterMap` ใน `Scene/Global.tscn` (sprite มีแล้ว 5 อารมณ์ที่ `Assets/CharacterSprite/char_pib_*.png`)
- [ ] เขียนคอมโพเนนต์ `PibHint` ที่อ่านไฟล์แล้วแยกตาม `# @SECTION` — `DialogScene` เดิมอ่านทั้งไฟล์รวดเดียว ใช้กับ section ไม่ได้

| `Storyboard/CROP_REPORT.md` | ผลตรวจ asset ที่ crop จาก sheet |
