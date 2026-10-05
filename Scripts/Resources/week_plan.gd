@tool
class_name WeekPlan extends Resource
## ลูกค้าของ 1 รอบ (7 วัน) · ช่องที่ 1 = วันที่ 1 · ช่องว่าง (empty) = สุ่มจาก random_pool ของ DayLoop
## แก้ใน Inspector: ดับเบิลคลิก Resources/Week/week1.tres → ลากไฟล์ลูกค้าจาก Resources/Customers/ ใส่แต่ละวัน
## [Claude 5 ต.ค. 2569]

## รอบที่ (1–12)
@export_range(1, 12) var week := 1
## ลูกค้าวันละ 1 คน · ใส่ได้ไม่เกิน 7 ช่อง
@export var days: Array[CustomerCase] = []
## หมายเหตุสำหรับทีม (ไม่แสดงในเกม)
@export_multiline var note: String


func case_for_day(day: int) -> CustomerCase:
	if day < 1 or day > days.size():
		return null
	return days[day - 1]
