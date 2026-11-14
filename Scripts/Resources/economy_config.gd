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
	&"part_bench": 150, # โต๊ะหลังเครื่อง Lv2
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
	&"part_bench": 200, # คีย์บอร์ดเปียก/ช่องเสีย
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
## งานใหม่ขึ้นกระดานตอนเปิดร้าน ต่อกะ (ช่อง 0 = บท/เดือน 1 … ช่อง 11 = บท 12)
## [0.2.5] ลูกค้าต่อวัน (ฐาน ก่อนบวกโบนัสชื่อเสียง rep_visitor_bonus) · 12 ช่อง = ม.ค.–ธ.ค. · งานยากขึ้น คนน้อยลง · ทยอยมาตาม visitor_waves
@export var board_new_per_shift: PackedInt32Array = [5, 5, 5, 5, 4, 4, 4, 4, 3, 3, 3, 3]
## งานโทรเข้าตอนพักบ่าย 15:30
@export var board_phone_jobs := 1
## กระดานแสดงได้มากสุดกี่ใบ
@export var board_max := 6

@export_group("ลูกค้าทยอยมา + ชื่อเสียง (0.2.5 · PLAN_0_2_5 ข้อ 3)")
## [0.2.5] เวลาที่ลูกค้าเดินเข้าร้าน (นาทีของวัน) · ช่อง 0 = ตอนเปิดร้าน 08:30 · 11:00 · 14:00 (งานโทรเข้า 15:30 แยกที่ board_phone_jobs)
@export var visitor_waves: PackedInt32Array = [510, 660, 840]
## สัดส่วนลูกค้าต่อรอบ (ช่องตรงกับ visitor_waves · รวมกันควรได้ 1)
@export var visitor_wave_share: PackedFloat32Array = [0.5, 0.3, 0.2]
## ชื่อเสียงขั้นต่ำของขั้นที่ 1 · 2 · 3 (ต่ำกว่าช่อง 0 = ขั้น 0)
@export var rep_visitor_steps: PackedInt32Array = [20, 40, 70]
## ลูกค้าเพิ่ม/ลดต่อวันตามขั้นชื่อเสียง 0–3
@export var rep_visitor_bonus: PackedInt32Array = [-1, 0, 1, 2]
## ชื่อขั้นชื่อเสียง 0–3 (แสดงบนกระดานงาน)
@export var rep_tier_names: PackedStringArray = ["คนยังไม่ค่อยรู้จัก", "ปกติ", "คนเริ่มบอกต่อ", "ขึ้นชื่อทั้งหมู่บ้าน"]
## ลูกค้าต่อวันอย่างน้อย
@export var min_visitors := 2
## ลูกค้าที่ยังไม่ได้รับงานตอนปิดร้าน → กลับบ้าน ชื่อเสียงลดคนละเท่านี้ (งานนัด/งานแก้ตัวที่เลยกำหนดยังใช้ rep_walkout)
@export var rep_left_unserved := -1

@export_group("เทศกาลรายเดือน (0.2.5 · PLAN_0_2_5 ข้อ 8)")
## ชื่อเทศกาล/ช่วงของแต่ละเดือน (ช่อง 0 = ม.ค.) · ขึ้นป้ายตอนเปิดร้านวันแรกของเดือน + บนกระดานงาน
@export var month_events: PackedStringArray = ["ปีใหม่", "ตรุษจีน", "หน้าร้อน · สอบปลายภาค", "สงกรานต์", "เปิดเทอม", "บุญบั้งไฟ", "เข้าพรรษา · หน้าฝน", "พายุเข้า", "ใกล้สอบกลางภาค", "ออกพรรษา · ปิดเทอม", "ลอยกระทง · ร้านคู่แข่งเปิด", "ส่งท้ายปี"]
## เรื่องที่เกิด (1 ประโยค) — บอกผลให้ผู้เล่นรู้
@export var month_event_notes: PackedStringArray = [
	"คนยังเที่ยวปีใหม่กันอยู่ ร้านเพิ่งเปิด ลูกค้ายังไม่เยอะ",
	"ลูกหลานกลับบ้านช่วงตรุษจีน พาพ่อแม่มาดูคอม ลูกค้า +1 ต่อวัน",
	"อากาศร้อน เครื่องร้อนดับบ่อย ครูกับนักเรียนรีบใช้คอมก่อนสอบ",
	"สงกรานต์ ลูกหลานกลับบ้านพาพ่อแม่มาตั้งเครื่อง ลูกค้า +1 ต่อวัน",
	"เปิดเทอม เด็ก ๆ ต้องใช้คอมทำการบ้าน ลูกค้า +1 ต่อวัน",
	"คนในหมู่บ้านไปช่วยงานบุญบั้งไฟ ลูกค้า −1 ต่อวัน",
	"ฝนตกบ่อย คนออกจากบ้านน้อย ลูกค้า −1 ต่อวัน",
	"พายุเข้า ไฟตกบ่อย ลูกค้า −1 ต่อวัน",
	"นักเรียนเตรียมสอบ ครูใช้คอมพิมพ์ข้อสอบ",
	"ออกพรรษา ปิดเทอม เด็ก ๆ มาได้ทั้งวัน ลูกค้า +1 ต่อวัน",
	"ร้านคอมเปิดใหม่ในตัวอำเภอ ลูกค้าบางคนไปลองร้านนั้น ลูกค้า −1 ต่อวัน",
	"ใกล้ปีใหม่ คนซื้อคอมให้ลูกหลานเป็นของขวัญ ลูกค้า +1 ต่อวัน",
]
## ลูกค้าเพิ่ม/ลดต่อวันจากเทศกาล (บวกกับฐาน board_new_per_shift + โบนัสชื่อเสียง)
@export var month_visitor_bonus: PackedInt32Array = [0, 1, 0, 1, 1, -1, -1, -1, 0, 1, -1, 1]

@export_group("หน้าประตู + ใบรับเครื่อง + ชั้นวาง (0.3.0 · PLAN_0_3_0 ข้อ 2–4)")
## รับลูกค้าใหม่ได้กี่คนต่อวัน (ลูกค้าที่นัดไว้นับโควตาของวันที่เขามา · งานเนื้อเรื่องไม่นับ)
@export var daily_cap := 3
## ลูกค้ายืนรอหน้าประตูได้กี่เทิร์น (ผู้สูงอายุ/รีบ ใช้ CustomerCase.patience แทน)
@export var door_patience_slots := 2
## ปล่อยรอหน้าประตูจนเดินกลับ
@export var rep_door_walkout := -1
## ชั้นวางเครื่องเริ่มกี่ช่อง (อัปเกรดด้วย ItemDef.shelf_slots_to)
@export var shelf_slots_start := 2
## ตัวเลือกวันนัดรับเครื่อง = อีกกี่วันเปิดร้าน (0 = วันนี้) · ค่าแรงคูณตามความเร็ว
@export var promise_days: PackedInt32Array = [0, 1, 2]
@export var promise_pay_mult: PackedFloat32Array = [1.2, 1.0, 0.9]
@export var promise_names: PackedStringArray = ["ด่วน วันนี้", "วันเปิดร้านถัดไป", "อีก 2 วันเปิดร้าน"]
## ส่งทันนัด → ความพอใจ +
@export var on_time_sat_bonus := 10
## ช้ากว่านัด — ลูกค้ายอมรอเพิ่มได้กี่วันเปิดร้าน ("ล่วงเวลา" ของใบรับเครื่อง) · หักความพอใจต่อวัน
@export var late_grace_days := 2
@export var late_sat_per_day := 15
## ค่าแรงลดต่อวันที่ช้า (สัดส่วน)
@export var late_pay_cut_per_day := 0.1
## เลยช่วงผ่อนผัน → ลูกค้ามาเอาเครื่องคืนตามสภาพ
@export var rep_returned := -3
@export var returned_satisfaction := 25

@export_group("ล่วงเวลา (LEVEL_DESIGN 4.2)")
@export var ot_cost_per_slot := 30
## ล่วงเวลาได้กี่วันต่อบท ([0.2.5] 1 บท = 1 เดือน เปิดร้าน 4 วัน)
@export var ot_max_per_week := 2

@export_group("ชื่อเสียง (GAME_REDESIGN 7.3)")
@export var reputation_start := 20
@export var rep_good := 2
@export var rep_three_star := 4
@export var rep_fail := -2
@export var rep_damaged := -5
@export var rep_reject := -1
@export var rep_walkout := -3

@export_group("บิลรายเดือน (ทุกบท · GDD v2.1 ข้อ 8.3)")
## [0.2.5] 1 บท = 1 เดือน = เปิดร้าน 4 วัน · ช่อง 0 = ม.ค. … ช่อง 11 = ธ.ค.
## ค่าเช่าที่หน้าบ้านยาย ต่อเดือน · ม.ค. ยายยกให้ (เดือนแรก) · ร้านโตขึ้นใช้พื้นที่มากขึ้น
@export var bill_rent: PackedInt32Array = [0, 300, 300, 300, 400, 400, 400, 400, 500, 500, 500, 500]
## ค่าไฟฐานต่อเดือน · มี.ค.–พ.ค. หน้าร้อนแพงขึ้น
@export var power_base: PackedInt32Array = [100, 100, 150, 150, 150, 100, 100, 100, 100, 100, 100, 100]
## ค่าไฟต่อเทิร์นที่ทำงานจริงในเดือนนั้น (TimeSystem.work_slots_used_this_month) · ค่าไฟล่วงเวลา (ot_cost_per_slot) จ่ายทันทีตอนปิดร้านแยกต่างหาก
@export var power_per_slot := 2
@export var bill_water := 50
@export var bill_internet := 150

@export_group("เป้ากำไรรายเดือน (Docs/ROADMAP_1_0_0.md ข้อ 5.2 · 8.1 D)")
## [0.2.0-D] กำไรขั้นต่ำต่อเดือน (ช่อง 0 = ม.ค.) · กำไร = รายรับ − รายจ่าย ไม่นับเงินลงทุน (GameState.month_profit) · ค่าทดลอง ≈ 70% ของกำไรเมื่อเล่นปกติ
## [0.2.5] 12 เดือน × เปิดร้าน 4 วัน · คิดจากค่าแรงเฉลี่ยตาม DEFAULT_WEIGHTS ของบท − บิล − ของสิ้นเปลือง ~10% (GDD v2.1 ข้อ 8.4)
@export var month_target: PackedInt32Array = [200, 300, 500, 800, 850, 900, 1300, 1300, 1550, 1600, 2000, 2000]

@export_group("ผลสิ้นเดือน (Docs/ROADMAP_1_0_0.md ข้อ 5.3 · 8.1 E–F)")
## ค่าปรับยอดค้างชำระ (สัดส่วนของยอดค้าง) บวกในบิลเดือนถัดไป · โหมดช่วยไม่มีค่าปรับ
@export var late_fee_rate := 0.1
## กี่เดือนแรกที่ไม่นับว่าพลาดเป้า (ช่วงเรียนรู้) · [0.2.5] ม.ค.–ก.พ.
@export var grace_months := 2
## [0.2.5] พลาดเป้ากี่เดือน **ติดกัน** (หลังช่วงเรียนรู้) → ร้านปิด · ถึงเป้าเดือนไหนนับใหม่
@export var fail_missed_months := 3
## ค้างบิลกี่เดือนติดกัน → ร้านปิด
@export var fail_debt_months := 2
## กำไร ≥ เป้า × ค่านี้ = "เกินเป้า"
@export var over_target_ratio := 1.3
## ชื่อเสียงที่ได้เมื่อถึงเป้าเดือน
@export var rep_month_goal := 3
## โหมดช่วย: เป้าเหลือกี่เท่า
@export var help_target_mult := 0.7

@export_group("ยศช่าง (GAME_REDESIGN 10.1)")
@export var rank_xp: PackedInt32Array = [0, 500, 1500, 3500, 7000]
@export var rank_names: PackedStringArray = ["ช่างมือใหม่", "ช่างฝึกหัด", "ช่างประจำหมู่บ้าน", "ช่างเชี่ยวชาญ", "ช่างมือโปร"]


func fee_for_level(level: int) -> int:
	return level_fee[clampi(level, 1, level_fee.size()) - 1] if not level_fee.is_empty() else default_fee


func xp_mult_for_level(level: int) -> float:
	return level_xp_mult[clampi(level, 1, level_xp_mult.size()) - 1] if not level_xp_mult.is_empty() else 1.0


func avg_slots_for_level(level: int) -> float:
	return level_avg_slots[clampi(level, 1, level_avg_slots.size()) - 1] if not level_avg_slots.is_empty() else 3.0


## [0.2.5] ขั้นชื่อเสียง 0–3
func rep_tier(rep: int) -> int:
	var t := 0
	for i in rep_visitor_steps.size():
		if rep >= rep_visitor_steps[i]:
			t = i + 1
	return t


## [0.2.5] ลูกค้าต่อวัน = ฐานของเดือน (board_new_per_shift) + โบนัสชื่อเสียง + เทศกาล (month_visitor_bonus)
func visitors_for(month: int, rep: int) -> int:
	var t := rep_tier(rep)
	var bonus := rep_visitor_bonus[clampi(t, 0, rep_visitor_bonus.size() - 1)] if not rep_visitor_bonus.is_empty() else 0
	var season := month_value(month_visitor_bonus, month) if month_visitor_bonus.size() >= 12 else 0
	return maxi(min_visitors, month_value(board_new_per_shift, month) + bonus + season)


## [0.2.5] เทศกาลของเดือน { name, note, bonus }
func month_event(month: int) -> Dictionary:
	var i := clampi(month, 1, 12) - 1
	return {
		"name": month_events[i] if i < month_events.size() else "",
		"note": month_event_notes[i] if i < month_event_notes.size() else "",
		"bonus": month_visitor_bonus[i] if i < month_visitor_bonus.size() else 0,
	}


## [0.2.5] แบ่ง n คนเป็นรอบตาม visitor_wave_share (เศษให้รอบที่ทศนิยมมากสุด · รอบแรกได้อย่างน้อย 1)
func split_waves(n: int) -> PackedInt32Array:
	var k := maxi(visitor_waves.size(), 1)
	var out := PackedInt32Array()
	out.resize(k)
	var frac: Array[float] = []
	var used := 0
	for i in k:
		var share := visitor_wave_share[i] if i < visitor_wave_share.size() else 0.0
		var x := n * share
		out[i] = floori(x)
		used += out[i]
		frac.append(x - floorf(x))
	while used < n:
		var best := 0
		for i in k:
			if frac[i] > frac[best] + 0.001: # เสมอกัน → รอบก่อนได้
				best = i
		out[best] += 1
		frac[best] = -1.0
		used += 1
		if frac.all(func(f: float) -> bool: return f < 0.0):
			for i in k:
				frac[i] = 0.0
	if n > 0 and out[0] == 0:
		for i in range(k - 1, 0, -1):
			if out[i] > 0:
				out[i] -= 1
				out[0] += 1
				break
	return out


## [0.2.0-D] เป้ากำไรของเดือน m (1–12)
func target_for(m: int) -> int:
	return month_value(month_target, m)


func month_value(arr: PackedInt32Array, month: int) -> int:
	return arr[clampi(month, 1, arr.size()) - 1] if not arr.is_empty() else 0


## [0.3.0] ค่าแรงคูณตามวันนัดที่เลือก (index ของ promise_days)
func promise_mult(i: int) -> float:
	return promise_pay_mult[i] if i >= 0 and i < promise_pay_mult.size() else 1.0
