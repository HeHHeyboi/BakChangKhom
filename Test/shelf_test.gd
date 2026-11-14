extends Node
## [Claude 14 พ.ย. 2569 · 0.3.0 ขั้น A] ทดสอบ RepairShelf (ใบรับเครื่อง + ชั้นวาง) — ข้อมูลล้วน
## เปิด Test/shelf_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0


func _ready() -> void:
	var e := EconomyConfig.new()
	var c1: CustomerCase = load("res://Resources/Customers/lv2_teacher_ram.tres")
	var c2: CustomerCase = load("res://Resources/Customers/w1_d1_amnuay_ram.tres")
	var c3: CustomerCase = load("res://Resources/Customers/w1_d6_girl_ram.tres")

	# A · รับเครื่อง + ชั้นเต็ม
	var s := RepairShelf.new(e)
	_check(s.slots == e.shelf_slots_start and s.used() == 0, "ชั้นเริ่ม %d ช่อง ว่าง" % e.shelf_slots_start)
	var opts := s.promise_options(5)
	_check(opts.size() == 3 and opts[0].due == 5 and opts[1].due == 6 and opts[2].due == 7, "วันนัด 3 ตัวเลือก: วันนี้ / +1 / +2")
	_check(s.promise_options(5, false).size() == 2, "วันนี้เวลาไม่พอ → ซ่อน 'ด่วน วันนี้'")
	var o1 := s.add(c1, 5, 1)
	var o2 := s.add(c2, 5, 2)
	_check(o1 and o2 and o1.due == 6 and o2.due == 7, "รับ 2 เครื่อง นัดวันที่ 6 และ 7")
	_check(s.is_full() and s.add(c3, 5, 1) == null, "ชั้นเต็ม (2/2) รับเพิ่มไม่ได้")
	_check(s.waiting()[0] == o1, "งานค้างเรียงวันนัดใกล้สุดก่อน")

	# B · ซ่อมเสร็จก่อนนัด → ยังไม่มารับ · เปิดร้านวันนัด → มารับทันนัด
	var r: Dictionary = s.finish(o1, { "score": 90 }, 5)
	_check(r.is_empty() and o1.state == RepairShelf.State.DONE and s.used() == 2, "ซ่อมเสร็จก่อนนัด → รอลูกค้า (ยังกินช่อง)")
	var day6 := s.open_day(6)
	_check(day6.picked.size() == 1 and day6.picked[0].on_time and day6.picked[0].sat_delta == e.on_time_sat_bonus, "วันนัด ลูกค้ามารับ ทันนัด ความพอใจ +%d" % e.on_time_sat_bonus)
	_check(is_equal_approx(day6.picked[0].mult, e.promise_mult(1)), "ค่าแรงคูณตามวันนัด (ปกติ ×1.0)")
	_check(s.used() == 1 and s.history[0] == o1 and o1.state == RepairShelf.State.PICKED, "ส่งแล้วออกจากชั้น ไปอยู่ประวัติ")

	# C · ช้ากว่านัด 1 วัน (ยังผ่อนผัน) แล้วซ่อมเสร็จ → มารับทันที ค่าแรงลด ความพอใจลด
	var day8 := s.open_day(8)
	_check(day8.late_waiting.size() == 1 and day8.returned.is_empty(), "เลยนัด 1 วัน ลูกค้ายังรอ (ผ่อนผัน %d วัน)" % e.late_grace_days)
	r = s.finish(o2, { "score": 80 }, 8)
	_check(not r.is_empty() and r.late == 1 and r.sat_delta == -e.late_sat_per_day, "ซ่อมเสร็จวันที่เลยนัด → มารับเลย ช้า 1 วัน ความพอใจ −%d" % e.late_sat_per_day)
	_check(is_equal_approx(r.mult, e.promise_mult(2) * (1.0 - e.late_pay_cut_per_day)), "ค่าแรง = ×วันนัด(0.9) × ช้า 1 วัน(0.9)")

	# D · เลยช่วงผ่อนผัน → มาเอาคืนตามสภาพ
	var s2 := RepairShelf.new(e)
	var o3 := s2.add(c3, 1, 0)
	_check(o3.due == 1 and is_equal_approx(e.promise_mult(0), 1.2), "นัดด่วนวันนี้ ค่าแรง ×1.2")
	var d3 := s2.open_day(1 + e.late_grace_days)
	_check(d3.returned.is_empty() and d3.late_waiting.size() == 1, "ช้า %d วัน (ครบผ่อนผัน) ยังรอ" % e.late_grace_days)
	var d4 := s2.open_day(2 + e.late_grace_days)
	_check(d4.returned.size() == 1 and o3.state == RepairShelf.State.RETURNED and s2.used() == 0, "เลยผ่อนผัน → ลูกค้ามาเอาคืน ชั้นว่าง")
	_check(s2.finish(o3, { "score": 90 }, 9).is_empty(), "เอาคืนแล้วซ่อมต่อไม่ได้")

	# E · วันนัดวันนี้ ยังไม่ซ่อม → due_today
	var s3 := RepairShelf.new(e)
	var o4 := s3.add(c1, 3, 1)
	_check(s3.open_day(4).due_today == [o4], "เปิดร้านวันนัด งานยังไม่ซ่อม → แจ้ง 'ถึงนัดวันนี้'")

	# F · เซฟ/โหลด
	var s4 := RepairShelf.new(e)
	s4.slots = 4
	var a := s4.add(c1, 2, 0)
	var b := s4.add(c2, 2, 2)
	s4.finish(a, { "score": 70 }, 1) # ซ่อมเสร็จก่อนนัด (วันที่ 1 < นัด 2)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(s4.to_save()))
	var s5 := RepairShelf.new(e)
	s5.load_save(saved)
	_check(s5.slots == 4 and s5.used() == 2, "โหลดเซฟ: ชั้น 4 ช่อง มี 2 ใบ")
	_check(s5.orders[0].case == c1 and s5.orders[0].state == RepairShelf.State.DONE and int(s5.orders[0].result.score) == 70, "ใบแรก: เคสเดิม ซ่อมเสร็จ คะแนน 70")
	_check(s5.orders[1].due == 4 and s5.orders[1].promise == 2 and s5.orders[1].state == RepairShelf.State.WAITING, "ใบสอง: นัดวันที่ 4 ยังไม่ซ่อม")
	_check(b != null, "-")

	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _check(ok: bool, msg: String) -> void:
	if ok:
		print("  ok  ", msg)
	else:
		fails += 1
		print("  FAIL ", msg)
