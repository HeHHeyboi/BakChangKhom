class_name Achievement
extends Resource
## [Claude 16 พ.ย. 2569 · 0.7.0 ขั้น J] ใบประกาศ (PLAN_0_7_0 ข้อ 5 · GDD v1.9 ข้อ 13.10 · V2_0_0_PLAN ข้อ 6)
## ไฟล์ Resources/Achievement/*.tres · เงื่อนไขคิดในโค้ด Achievements.progress(check) — check = ชื่อเงื่อนไข · target = ค่าที่ต้องถึง
## รางวัลเป็นของตกแต่ง/ฉายาเท่านั้น (ไม่มีเงิน → ไม่กระทบเป้าเดือน) · hidden = ใบลับ โชว์ ??? จนกว่าจะได้

## [0.9.5] 5 หมวด (ผู้ใช้ 16 พ.ย.: แยกหมวดชัด ๆ · เรียก "ความสำเร็จ" แทน "ใบประกาศ") · ใบลับใช้ hidden แทนหมวดลับ
enum Category { REPAIR, SHOP, PEOPLE, EVENT, STORY }
const CATEGORY_NAME := ["ซ่อมฮาร์ดแวร์", "ร้านและการเงิน", "ลูกค้าและชุมชน", "อีเวนต์ในหมู่บ้าน", "เรื่องราวและฉากจบ"]

@export var id: StringName
@export var title: String
@export_multiline var desc: String
@export var category: Category = Category.REPAIR
@export var hidden := false
## ชื่อเงื่อนไข (ดู Achievements.progress)
@export var check: StringName
@export var target := 1
## พารามิเตอร์เสริม เช่น part id
@export var arg: StringName
## รางวัล (ข้อความ) เช่น "ฉายา ช่างครบเครื่อง" · ว่าง = ไม่มี
@export var reward_text: String
## ความรู้ที่วัด (ประกอบเล่ม)
@export var skill: String


func category_name() -> String:
	return CATEGORY_NAME[clampi(int(category), 0, CATEGORY_NAME.size() - 1)]
