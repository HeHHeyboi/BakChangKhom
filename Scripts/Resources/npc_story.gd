class_name NpcStory
extends Resource
## [Claude 15 พ.ย. 2569 · 0.5.0] เรื่องส่วนตัวของลูกค้าประจำ 1 เรื่อง (PLAN_0_5_0 ข้อ 4)
## เล่นตอนคนนั้นมารับเครื่อง/ทำงานต่อหน้าเสร็จ แล้วความสนิทถึง `at` · ทีละขั้น · วันละไม่เกิน 1 เรื่อง

## ความสนิทที่ต้องถึง (40 / 60 / 80)
@export_range(0, 100) var at := 40
## ชื่อเรื่อง (โชว์ในสมุดลูกค้า)
@export var title: String
## ไฟล์บทพูด (Assets/Dialog/NPC/<id>_<at>.txt) · มีตัวเลือก 1 ครั้งได้
@export_file("*.txt") var dialog: String
## ข้อความตัวเลือกที่ถือว่า "จบดี" (ว่าง = จบดีเสมอ)
@export var good_choice: String
## ของฝากเข้าคลัง (id ใน Resources/Shop/ · ว่าง = ไม่มี)
@export var reward_item: StringName
## ธงที่ตั้งเมื่อฟังจบ (ว่าง = ไม่มี)
@export var flag: StringName
