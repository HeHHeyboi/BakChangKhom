class_name EconomyConfig extends Resource
## ตัวเลขเศรษฐกิจของร้านซ่อม — ปรับที่ Resources/Balance/economy.tres ที่เดียว
## ตาราง "ผลของการซ่อม" ใน Docs/GAME_LOOP.md §3 · [Claude 5 ต.ค. 2569] ตัวเลขเริ่มต้นเป็นค่าทดลอง รอทีมปรับ

## เงินตอนเริ่มเกม (บาท)
@export var start_money := 500
## ค่าซ่อมเต็มต่อ Core Part (part_id → บาท) · part_id = ชื่อไฟล์ซีนมินิเกม
@export var repair_fee: Dictionary[StringName, int] = {
	&"part_ram": 150,
	&"part_mainboard": 300,
	&"part_gpu": 400,
	&"part_front_panel": 200,
	&"part_bios": 350,
}
## ค่าซ่อมเมื่อไม่มีใน repair_fee
@export var default_fee := 200
## ทิปเมื่อได้ ⭐⭐⭐
@export var tip_three_star := 50
## ค่าของที่เสีย (หักเงิน) เมื่อทำของลูกค้าเสียระหว่างซ่อม
@export var damage_penalty: Dictionary[StringName, int] = {
	&"part_ram": 300,
	&"part_mainboard": 1500,
	&"part_gpu": 2500,
	&"part_front_panel": 200,
	&"part_bios": 500,
}
@export var default_penalty := 300

@export_group("เกณฑ์คะแนน (0–100)")
## ≥ ค่านี้ = ซ่อมถูกทุกอย่าง
@export var good_score := 80
## ≥ ค่านี้ = ผ่านแบบมีจุดพลาด · ต่ำกว่า = ผิด
@export var pass_score := 60
## ≥ ค่านี้ = ⭐⭐⭐ (ได้ทิป)
@export var three_star_score := 95

@export_group("ความพอใจ")
## ความพอใจของลูกค้า 1 งาน (0–100) ใช้คำนวณเฉลี่ยสำหรับฉากจบ
@export var satisfaction_good := 90
@export var satisfaction_pass := 65
@export var satisfaction_fail := 25

@export_group("XP")
@export var xp_base := 100
@export var xp_mult_pass := 0.6
@export var xp_mult_fail := 0.4
