# ART_25D_PLAN.md — แผนเปลี่ยนภาพเป็น 2.5D + วิธีทำโมเดลให้เปลือง token น้อยสุด

> **30 ก.ย. 2569: เปลี่ยนเป็น 2D ทั้งหมดแล้ว** — ภาพรวมร้าน 2D (Volcano Princess) · ในเคส 2.5D แบบภาพวาด (Lil' Guardsman) · ดู `SCENE_2D.md` · ชื่อคลาส/กล้อง/พิกัด 3 มิติในเอกสารนี้ใช้ไม่ได้แล้ว (Item2D · Socket2D · Stage2D · Phase2D แทน)

> 29 ก.ย. 2569 · Godot 4.7 · GL Compatibility · ใช้คู่กับ `TUTORIAL_ASSEMBLY_DESIGN.md` (สเปกฉาก 3D ของมินิเกม)

## 1. ทำได้ไหม — ได้ แบ่ง 3 ช่วง

| ช่วง | ขอบเขต | ตัวละคร | สถานะ |
|---|---|---|---|
| **1. Core Part** | play area ของมินิเกม (Tutorial ประกอบคอม + Part ทั้ง 5) เป็นฉาก 3D ใน SubViewport | ปิ๊บยังเป็นภาพ 2D ในแถบล่าง | ✅ **ทำตอนนี้** |
| 2. ฉากนิ่ง | พื้นหลังห้อง/ร้าน/ตลาด เปลี่ยนเป็นภาพ render จากฉาก 3D (ในเกมยังเป็นรูป 2D) | ไม่แตะ | ⏸ ภายหลัง |
| 3. World 2.5D (แบบ HD-2D) | ห้อง/บ้าน/แผนที่เป็นฉาก 3D กล้อง perspective เอียง 35–45° · ตัวละครเป็น `Sprite3D` billboard ใช้ sprite 2D เดิม | sprite 2D เดิม | ⏸ **อย่าเพิ่งทำ** |

**ช่วง 3 กระทบอะไร (จดไว้ก่อน):** `player.gd` → `CharacterBody3D` เดินบนระนาบ XZ · physics layer เป็น 3D · `Room/Home/Market.tscn` ทำใหม่ · caution marker / NPC เป็น `Area3D` · dialog / HUD / map ยังเป็น 2D · sprite ตัวละครใช้ต่อได้ ไม่ต้องวาดใหม่

---

## 2. หลักการ: ไม่ปั้นโมเดล ใช้ "กล่องแปะรูป" + ข้อมูลสั้น ๆ

token ส่วนใหญ่หมดไปกับการให้ AI **เขียนไฟล์โมเดล/ซีนทีละชิ้น** และ **อ่านรูป/ไฟล์ใหญ่** — เลี่ยงด้วยการเขียนตัวสร้างครั้งเดียว แล้วเพิ่มชิ้นส่วนเป็นข้อมูลสั้น ๆ

| ระดับ | วิธี | token ต่อชิ้นใหม่ | ใช้กับ |
|---|---|---|---|
| **A (ค่าเริ่มต้น)** | `Item2D` สร้าง `BoxMesh` จาก `PcPart.size` แล้วแปะ `PcPart.texture` (PNG 2D ที่มีอยู่) — **ไม่มีไฟล์โมเดลเลย** | ~15 บรรทัด `.tres` | แผงวงจร · แรม · การ์ดจอ · SSD · PSU · สาย |
| B | shape สำเร็จรูปใน `Item2D`: `box` · `cylinder` · `plate` · `socket` เลือกด้วยค่า `shape` | ~15 บรรทัด | พัดลม · ฮีตซิงก์ · CPU socket |
| C | ของใหญ่: `CSGBox3D` ต่อเป็น kit ครั้งเดียว เซฟเป็น `.tscn` แล้ว instance ซ้ำ | เขียนครั้งเดียว | เคส · โต๊ะ |
| D (เมื่อจำเป็นจริง) | AI แปลงรูปเป็น 3D ภายนอก (Tripo · Meshy · Hunyuan3D) จากรูป 2D ที่มี → `.glb` → `res://Assets/Models/` | **0 token ฝั่ง Claude** (ใช้เครดิตเว็บนั้น) | ชิ้นโชว์ 1–2 ชิ้น เช่น เคสหลัก |

> **ห้าม:** ให้ Claude เขียน `.glb` / `.obj` / vertex เอง · เขียน `.tscn` 3D ยาว ๆ ทีละชิ้น · ส่งรูปทีละชิ้นเพื่อ "กะขนาด" (บอกขนาดเป็นตัวเลขแทน)

**งบต่อชิ้น (ระดับ D):** ≤ 2,000 สามเหลี่ยม · 1 material · texture 512–1024 px · ไม่มี rig/animation (ขยับด้วย Tween)

---

## 3. ชิ้นส่วน 1 ชิ้น = 1 ไฟล์ `.tres` สั้น ๆ

```
[gd_resource type="Resource" script_class="PcPart" format=3]
[ext_resource type="Script" path="res://Scripts/Resources/pc_part.gd" id="1"]
[ext_resource type="Texture2D" path="res://Assets/MiniGame/PartGpu/gpu_card.png" id="2"]
[resource]
script = ExtResource("1")
id = &"gpu"
display_name = "การ์ดจอ"
shape = &"box"
size = Vector3(2.7, 0.4, 1.1)
texture = ExtResource("2")
socket_type = &"pcie_x16"
requires = Array[StringName]([&"mainboard"])
core_part = &"gpu"
```

**สั่งทำชิ้นใหม่แบบประหยัด:** ส่งตารางบรรทัดเดียวต่อชิ้น แล้วให้สคริปต์ generate `.tres` ทั้งชุดครั้งเดียว

```
id | ชื่อ | shape | size (x,y,z) | รูป | socket | requires | core_part
ssd | SSD M.2 | plate | 0.8,0.05,0.22 | asm_ssd_m2.png | m2 | mainboard | bios
```

---

## 4. สั่งงาน Claude ให้เปลือง token น้อย

| ทำ | ไม่ทำ |
|---|---|
| บอก path + หัวข้อ md เช่น "ทำตาม `TUTORIAL_ASSEMBLY_DESIGN.md` ข้อ 5.3" | ให้อ่านทุก md ใหม่ทุกรอบ |
| ของานก้อนเดียวต่อ 1 ข้อใน "ลำดับการทำ" | ขอทีละบรรทัดหลายรอบ |
| วาง error **เฉพาะบรรทัดแดง + บรรทัด `at:`** | วาง log ทั้งหน้า |
| ส่งรูปเฉพาะตอนต้องดู layout · ย่อก่อน (≤ 1000 px) | ส่งรูป asset ทีละชิ้น |
| แก้ด้วย diff สั้น ๆ ในไฟล์เดิม | เขียนไฟล์ใหม่ทั้งไฟล์ |
| ใช้ตาราง (`.tres` · CSV) แล้วให้สคริปต์ generate | พิมพ์ข้อมูล 10 ชิ้นทีละชิ้น |
| เทสต์ใน Godot เองแล้วบอกผลสั้น ๆ | ให้ Claude รัน headless ทุกครั้ง (ใช้เฉพาะบั๊กยาก) |

---

## 5. ลำดับทำ (ช่วง 1)

1. ✅ `Item2D` ระดับ A + B (box · cylinder) + `PcPart` — ทำแล้ว 29 ก.ย. (ดู `MINIGAME_PREFAB.md` ท้ายไฟล์) · ต้นแบบ `Test/stage3d_ram_demo.tscn`
2. เคส kit ระดับ C (`asm_case.tscn`)
3. ชิ้นส่วน 9 ชิ้นของ Tutorial เป็น `.tres` (ใช้รูปที่มีแล้วก่อน — `TUTORIAL_ASSEMBLY_DESIGN.md` ข้อ 8)
4. พิจารณาระดับ D เฉพาะเคสหลัก หลังเล่นได้ครบแล้ว
5. Core Part อื่นยืม `part_stage_2d.tscn` + `Item2D` — เพิ่มแค่ `.tres`

## 6. โฟลเดอร์

```
Assets/Models/            ← .glb จากระดับ D เท่านั้น (เพิ่ม *.glb ใน .gitattributes ให้ใช้ Git LFS ก่อน)
Assets/Textures3D/        ← texture ผิวเคส/โต๊ะ (asm_case_side ฯลฯ)
Resources/Tutorial/Parts/ · Resources/Parts/<PartName>/   ← PcPart .tres
Scene/MiniGame/PartBase/asm_case.tscn · part_stage_2d.tscn
```

## ตัดสินใจสไตล์ (30 ก.ย.)
มินิเกม Part ใช้ **side-view 2.5D**: กล้อง orthographic ด้านข้าง, toon + เส้นขอบดำ, ฉากหลังเป็นภาพ 2D วาดมือ (ตัวอย่าง `part_bg_workshop_wall.png`) — ให้โมเดลกล่องกลมกลืนกับฉาก 2D เดิม

## อัปเดตสไตล์ (30 ก.ย. ครั้งที่ 2) — ยึด Volcano Princess
เปลี่ยนจากด้านข้างเป็น **ห้อง diorama มุมเฉียงสูง ~40°** (orthographic) · โทนอุ่น · เส้นขอบน้ำตาลเข้ม · ผนัง 2 ด้าน · UI แบบกระดาษ (สมุดคู่มือ) + ป้ายปิ๊บด้านล่าง — ดู RAM_3D_GAMEPLAY.md อัปเดต (4)
