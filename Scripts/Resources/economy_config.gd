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
	&"part_desktop": 60, # ขมOS งานบนจอ Lv1
}
## ค่าซ่อมเมื่อไม่มีใน repair_fee
@export var default_fee := 200
## ทิปเมื่อได้ ⭐⭐⭐ (ECONOMY_ENERGY 1.2)
@export var tip_three_star := 20
## ค่าของที่เสีย (หักเงิน) เมื่อทำของลูกค้าเสียระหว่างซ่อม
@export var damage_penalty: Dictionary[StringName, int] = {
	&"part_ram": 300,
	&"part_mainboard": 1500,
	&"part_gpu": 2500,
	&"part_front_panel": 200,
	&"part_bios": 500,
	&"part_desktop": 100, # ล้างถังขยะทั้งที่มีไฟล์ลูกค้า = ของหาย (ค่ากู้ข้อมูล/ชดเชย)
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

@export_group("ระดับงาน Lv1–5 (LEVEL_DESIGN ข้อ 2 · ECONOMY_ENERGY ข้อ 1.1)")
## ค่าแรงฐานต่อระดับ (ช่อง 0 = Lv1) — ใช้เมื่อ CustomerCase.fee = −1
@export var level_fee: PackedInt32Array = [60, 150, 300, 420, 750]
## ตัวคูณ XP ต่อระดับ (× xp_base)
@export var level_xp_mult: PackedFloat32Array = [0.5, 1.0, 1.5, 2.5, 4.0]
## เวลาเฉลี่ย (ช่อง 30 นาที) ใช้เมื่อ CustomerCase.est_slots = 0
@export var level_avg_slots: PackedFloat32Array = [1.5, 3.0, 5.0, 6.5, 10.0]
## ระดับ n+1 ขึ้นกระดานได้เมื่อได้ ⭐⭐ ขึ้นไปในระดับ n ครบกี่งาน (LEVEL_DESIGN ข้อ 6)
@export var unlock_stars_needed := 2
## ครั้งแรกที่เจอมินิเกมนั้น (ปิ๊บสอนเต็ม) ใช้เวลาเพิ่มกี่ช่อง
@export var first_time_extra_slots := 1

@export_group("กระดานงาน (LEVEL_DESIGN ข้อ 5)")
## งานใหม่ขึ้นกระดานตอนเปิดร้าน ต่อกะ (ช่อง 0 = เดือน 1) — คิดจากจำนวนงานต่อเดือน × 1.3 ÷ 20 กะ
@export var board_new_per_shift: PackedInt32Array = [5, 4, 3]
## งานโทรเข้าตอนพักบ่าย 15:30
@export var board_phone_jobs := 1
## กระดานแสดงได้มากสุดกี่ใบ
@export var board_max := 6

@export_group("ล่วงเวลา (LEVEL_DESIGN 4.2)")
@export var ot_cost_per_slot := 30
## ล่วงเวลาได้กี่กะต่อสัปดาห์
@export var ot_max_per_week := 2

@export_group("ชื่อเสียง (GAME_REDESIGN 7.3)")
@export var reputation_start := 20
@export var rep_good := 2
@export var rep_three_star := 4
@export var rep_fail := -2
@export var rep_damaged := -5
@export var rep_reject := -1
@export var rep_walkout := -3

@export_group("บิลรายเดือน (ECONOMY_ENERGY 1.3)")
## ค่าไฟร้าน (ช่อง 0 = เดือน 1)
@export var bill_power: PackedInt32Array = [500, 700, 900]
@export var bill_grandma := 1500
@export var bill_internet := 300

@export_group("ยศช่าง (GAME_REDESIGN 10.1)")
@export var rank_xp: PackedInt32Array = [0, 500, 1500, 3500, 7000]
@export var rank_names: PackedStringArray = ["ช่างมือใหม่", "ช่างฝึกหัด", "ช่างประจำหมู่บ้าน", "ช่างเชี่ยวชาญ", "ช่างมือโปร"]


func fee_for_level(level: int) -> int:
	return level_fee[clampi(level, 1, level_fee.size()) - 1] if not level_fee.is_empty() else default_fee


func xp_mult_for_level(level: int) -> float:
	return level_xp_mult[clampi(level, 1, level_xp_mult.size()) - 1] if not level_xp_mult.is_empty() else 1.0


func avg_slots_for_level(level: int) -> float:
	return level_avg_slots[clampi(level, 1, level_avg_slots.size()) - 1] if not level_avg_slots.is_empty() else 3.0


func month_value(arr: PackedInt32Array, month: int) -> int:
	return arr[clampi(month, 1, arr.size()) - 1] if not arr.is_empty() else 0
