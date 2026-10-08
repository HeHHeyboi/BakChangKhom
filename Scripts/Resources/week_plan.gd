@tool
class_name WeekPlan extends Resource
## งานของ 1 สัปดาห์ (5 กะ = 1 Chapter) ตาม Docs/LEVEL_DESIGN.md ข้อ 6
## แก้ใน Inspector: ดับเบิลคลิก Resources/Week/weekN.tres
##   shifts        — งานบังคับรายกะ (ช่อง 0 = กะ 1) ช่องว่าง = ไม่มีงานบังคับ · ลูกค้า forced เดินเข้ามาเอง
##   level_weights — สัดส่วนงานใหม่บนกระดาน Lv1–Lv5 (%) · ว่าง = ใช้ตาราง DayLoop.DEFAULT_WEIGHTS
## [Claude 5 ต.ค. 2569] · [9 ต.ค.] เปลี่ยน days (7 วัน) เป็น shifts (5 กะ) + level_weights

## สัปดาห์ที่ (1–12)
@export_range(1, 12) var week := 1
## งานบังคับรายกะ ≤ 5 ช่อง
@export var shifts: Array[CustomerCase] = []
## สัดส่วน Lv1/Lv2/Lv3/Lv4/Lv5 (%)
@export var level_weights: PackedFloat32Array = []
## หมายเหตุสำหรับทีม (ไม่แสดงในเกม)
@export_multiline var note: String
## (เลิกใช้ 9 ต.ค.) ลูกค้ารายวันแบบเดิม — ถ้า shifts ว่างจะอ่านจากที่นี่แทน
@export var days: Array[CustomerCase] = []


func case_for_shift(n: int) -> CustomerCase:
	var arr := shifts if not shifts.is_empty() else days
	if n < 1 or n > arr.size():
		return null
	return arr[n - 1]


## (เดิม)
func case_for_day(day: int) -> CustomerCase:
	return case_for_shift(day)
