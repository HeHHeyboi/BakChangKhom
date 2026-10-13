# PART_JOB_LINK.md — ผูกอะไหล่/ของสิ้นเปลืองในคลังกับงานซ่อม (สเปกพร้อมสั่งทำ)

> [Claude 13 ต.ค. 2569] · ต่อจาก `STORAGE_SHOP_ECO.md` ข้อ 1.6 · **ยังไม่ได้ลงโค้ด** — เอกสารนี้เขียนให้สั่งได้ทันที: "ทำตาม Docs/PART_JOB_LINK.md"
> ระบบที่ลงแล้วและใช้ต่อได้เลย: `ItemDef` (`Scripts/Resources/item_def.gd`) · `GameState.inventory` / `add_item` / `take_item` / `count_item` / `sell_back` / `buy` · ของ 14 ชิ้นใน `Resources/Shop/` · หน้าคลัง (autoload `Storage`) · ร้านในตลาด (`ShopPanel`)
> **ห้ามแตะ** `Scripts/MiniGame/Desktop/*` (ขมOS — เพื่อนกำลังทำ) · งาน Lv1 บนจอไม่ใช้อะไหล่ จึงไม่ต้องแก้

---

## 1. ข้อมูลที่ต้องเพิ่ม

### 1.1 `CustomerCase` (`Scripts/Resources/customer_case.gd`)

```gdscript
@export_group("อะไหล่ (PART_JOB_LINK)")
## อะไหล่ที่งานนี้ต้องใช้ (id ใน Resources/Shop/) · ว่าง = ไม่ต้องใช้
@export var needs_part: StringName
## ยอมรับของแทนได้ (เช่น มือสองแทนใหม่) — ลำดับแรกถูกเลือกก่อน
@export var part_alternatives: Array[StringName] = []
## ของสิ้นเปลืองที่ใช้ { id: จำนวนครั้ง } เช่น { &"ipa90": 1, &"paste_grey": 1 }
@export var supplies: Dictionary[StringName, int] = {}
## ชิ้นเก่าที่ถอดออก (คืนลูกค้าตอนส่งมอบ) — ว่าง = ไม่มี
@export var old_part_name := ""
```

### 1.2 `GameState` (เพิ่มต่อจากส่วนคลัง)

```gdscript
## จองชิ้นแรกที่ว่างของ id ให้งาน case_id · คืน index ในคลัง (-1 = ไม่มี)
func reserve(id: StringName, case_id: StringName) -> int
## ปลดจองทั้งหมดของงานนี้ (ยอมแพ้ / ปฏิเสธงาน)
func release(case_id: StringName) -> void
## ใช้ชิ้นที่จองไว้ (ลบออกจากคลัง) · คืน ItemDef ที่ใช้ (ไว้คิดเงินคืน)
func consume_reserved(case_id: StringName) -> ItemDef
## มีของสิ้นเปลืองพอสำหรับงานไหม
func has_supplies(need: Dictionary) -> bool
```

`reserved_for` มีอยู่แล้วในแต่ละรายการของ `inventory` (ตอนนี้เป็น `""` เสมอ) · `take_item()` ข้ามชิ้นที่จองแล้ว · หน้าคลังโชว์ป้าย "🔖 จอง" และห้ามขายแล้ว

---

## 2. ลำดับในเกม

| จังหวะ | ไฟล์ | ทำอะไร |
|---|---|---|
| **กระดานงาน** | `day_loop.gd` `_fill_board()` | งานที่มี `needs_part` แต่คลังไม่มี → ป้ายแดง "ขาดอะไหล่: แรม DDR4" · ปุ่มรับงานยังกดได้ |
| **รับงาน** | `day_loop.gd` `accept_job()` | มีของ → `reserve()` ทันที · ไม่มี → ถาม 2 ทาง: **"ไปซื้อที่ตลาดก่อน"** (งานค้างที่ช่อง "รอของ" บนกระดาน ไม่เสียเวลา) / **"รับไว้ก่อน"** (เข้ามินิเกมได้ แต่ขั้นใส่ชิ้นใหม่จะทำไม่ได้ → ต้องยอมแพ้) — แนะนำทางแรก |
| **เปิดมินิเกม** | `day_loop.gd` `start_repair()` | ตั้ง meta `"reserved_item"` = ItemDef ที่จอง (มินิเกมใช้โชว์ชื่อ/สภาพชิ้นใหม่) |
| **ในมินิเกม** | `part_ram.gd` · `phase_install.gd` (RAM) · `part_gpu.gd` · `part_mainboard.gd` | ขั้นใส่ชิ้นใหม่: ToolBelt มีช่องพิเศษ "ชิ้นใหม่จากคลัง" · ขั้นทำความสะอาด: หัก `supplies` ด้วย `take_item()` ตอนใช้จริงครั้งแรก · หมด → ปิ๊บบอก "น้ำยาหมด ใช้ผ้าแห้งแทนได้แต่ช้ากว่า" (ใช้เครื่องมือฟรีที่มีอยู่) |
| **ส่งงานผ่าน** | `part_minigame.gd` `_report_repair()` → `GameState.record_repair()` | `consume_reserved()` · ลูกค้าจ่าย **ค่าแรง + ราคาอะไหล่** (ราคาที่ซื้อมา + บวกได้ ≤ 15% ตาม ECONOMY_ENERGY 2.1) · การ์ดผลโชว์แยก "ค่าแรง ฿x · ค่าอะไหล่ ฿y" |
| **ยอมแพ้ / ไม่ผ่าน** | `GameState.record_repair()` (`gave_up`) | `release()` — ชิ้นกลับเป็นของว่างในคลัง ไม่เสียเงิน · ถ้า `damaged` = ชิ้นเสีย ลบออกจากคลัง (ขมจ่ายเอง แทน `damage_penalty`) |
| **ชิ้นเก่า** | การ์ดผล | ถ้ามี `old_part_name` → ปุ่ม "คืนชิ้นเก่าให้ลูกค้า" (ชื่อเสียง +1) / "เก็บไว้" (เข้าคลังเป็นมือสอง "ไม่รู้สภาพ" ใช้ 1 ช่อง) — ไม่เลือก = ถือว่าคืน |
| **ปฏิเสธงาน / ลูกค้าเดินออก** | `reject_job()` · `_on_shift_started()` | `release()` |

---

## 3. งานที่ต้องผูก (สัปดาห์ 1)

| เคส (`Resources/Customers/`) | `needs_part` | `supplies` | หมายเหตุ |
|---|---|---|---|
| `w1_d1_amnuay_ram` · `w1_d6_girl_ram` · `lv2_*_ram` | ไม่ต้อง (ทำความสะอาดแรมเดิม) | `contact` ถ้ามี / ไม่มี = ยางลบ | ให้ 1 เคสเป็น "แรมเสียจริง ต้องเปลี่ยน" → `ram_ddr4_8gb_used` + alt `ram_ddr4_8gb_new` |
| `w1_d2_headman_mainboard` · `w1_d7_amnuay_mainboard` | — | `ipa90` 1 · `paste_grey` 1 | alt น้ำยา: `alcohol70` (ต้องรอแห้ง +1 ช่อง) |
| `w1_d3_kid_gpu` | — | `air_can` 1 · `cable_tie` 2 | |
| `lv2_teacher_display` | `cable_hdmi` | — | จอไม่ขึ้นเพราะสาย |
| `lv2_kid_keyboard` · `lv2_coworker_mouse` (Bench) | `keyboard_basic` / `mouse_basic` ถ้าเปลี่ยนชิ้น | — | Bench ใช้ `bench_task` เดิม เพิ่มแค่ทางเลือก "เปลี่ยนใหม่" |

---

## 4. เช็กว่าทำครบ

- [ ] รับงานแรมเสียโดยไม่มีแรมในคลัง → ขึ้นป้ายขาดอะไหล่ · ไปตลาดซื้อ → กลับมารับได้ · ชิ้นโชว์ 🔖 ในคลัง
- [ ] ซ่อมผ่าน → ชิ้นหายจากคลัง · เงินเข้า = ค่าแรง + ค่าอะไหล่
- [ ] ยอมแพ้ → ชิ้นกลับเป็นของว่าง · งานกลับขึ้นกระดานวันถัดไป (ระบบ Task Fail มีแล้ว)
- [ ] น้ำยาหมดกลางงาน → งานยังจบได้ (ช้ากว่า) ไม่ค้าง
- [ ] เซฟ/โหลดกลางงาน → ของที่จองยังจองอยู่ (`reserved_for` อยู่ในเซฟแล้ว)
- [ ] ไม่มีไฟล์ใน `Scripts/MiniGame/Desktop/` ถูกแก้
