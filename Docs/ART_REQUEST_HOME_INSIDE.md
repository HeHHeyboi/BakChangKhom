# ขอภาพ: ในบ้านขมกับยาย (ฉากแรกของเกม)

> [Claude 9 ต.ค. 2569] ฉาก `Scene/Location/Home.tscn` ย้ายเข้ามา "ในบ้าน" แล้ว — ตอนนี้ใช้ภาพชั่วคราว (`bg_home_inside.jpg` = สำเนาของ `bg_shop_empty.jpg`)
> ได้ภาพจริงแล้ว **วางทับไฟล์ `Assets/Background/bg_home_inside.jpg` ชื่อเดิม** จบ ไม่ต้องแก้ซีน (ถ้าประตูอยู่คนละที่ ค่อยขยับ node `Door` ใน Home.tscn)

## ลำดับฉากใหม่

```
ในบ้าน (Home) ──ประตูหน้าบ้าน──▶ หน้าบ้าน (Village) ──ป้าย "ร้านซ่อมคอมขม"──▶ ร้าน (Room)
   ▲  ยาย + ! เควสต์แรก              │  กลับบ้าน = คลิกเรือนซ้าย           │
   └──────────────────────────────────┘◀──────────── ประตูร้าน ────────────┘
```

## สเปกภาพ

| | |
|---|---|
| ขนาด | **1152 × 648** JPG (เท่าจอ ไม่ต้องย่อ) |
| สไตล์ | เดียวกับ `bg_shop_open.jpg` / `bg_village_day.jpg` — ภาพวาดการ์ตูนลงสี เส้นขอบเข้ม แสงอุ่น ชนบทไทย |
| เวลา | เช้า แดดอ่อนเข้าทางประตู/หน้าต่าง |
| ห้ามมี | ตัวละคร · ตัวหนังสือ · โลโก้ |

## ตำแหน่งที่โค้ดใช้ (พิกเซลบนภาพ 1152×648)

| ของ | ตำแหน่ง | เหตุผล |
|---|---|---|
| **ประตูหน้าบ้าน (เปิดอยู่ เห็นหมู่บ้านข้างนอก)** | ขวา x 985–1145 · y 100–495 | node `Door` กดแล้วออกไปหน้าบ้าน |
| **พื้นว่างให้ยายยืน** | x 430–665 · เท้าอยู่ที่ y ≈ 590 | ยายเป็นสไปรต์แยก วางทับ |
| มุมซ้ายบน x 0–500 · y 0–170 | โล่ง ๆ | แถบเวลา/เงิน (HUD) ทับ |
| มุมขวาบน x 830–1152 · y 0–110 | โล่ง ๆ | กล่องภารกิจทับ |
| มุมซ้ายล่าง x 0–170 · y 570–648 | โล่ง ๆ | ปุ่ม "แผนที่" |

## ของในห้องที่อยากให้มี (บอกเรื่องราว)

- เรือนไม้ยกพื้นแบบบ้านต่างจังหวัด ฝาไม้ หน้าต่างบานเกล็ด
- เสื่อกก · โต๊ะญี่ปุ่นเตี้ย มีกระติกน้ำ แก้ว จานขนม
- หิ้งพระเล็ก ๆ บนผนังสูง · รูปครอบครัวใส่กรอบ (ขมตอนเด็กกับยาย)
- พัดลมตั้งพื้น · ตู้ไม้เก่า · ปฏิทินแขวน
- (ใบ้เนื้อเรื่อง) คอมเครื่องเก่าคลุมผ้าวางมุมห้อง — ขมเพิ่งกลับมาจากกรุงเทพ

## Prompt (ใช้กับเครื่องเจนภาพ)

```
Cozy interior of a rural Thai wooden stilt house living room, morning sunlight, warm colors,
2D game background, hand-painted cartoon style with dark clean outlines, same style as a cozy
anime village game, wide shot 16:9 (1152x648), eye-level view.
Wooden plank walls and floor, louvered wooden windows, a woven reed mat on the floor,
a low wooden table with a thermos, glasses and a plate of Thai snacks,
a small Buddha shelf high on the back wall, framed family photos,
a standing electric fan, an old wooden cabinet, a hanging calendar,
an old desktop computer covered with a cloth in the back corner.
The front door on the RIGHT side is wide open, showing a sunny village path and palm trees outside.
Empty floor space in the center-left for a character to stand.
Keep the top-left corner, top-right corner and bottom-left corner uncluttered.
No people, no text, no logos.
```

(อ้างอิงภาพสไตล์: แนบ `bg_shop_open.jpg` กับ `bg_village_day.jpg` ไปกับ prompt ด้วยถ้าเครื่องเจนรองรับ image reference)
