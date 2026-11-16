extends Node
## [Claude 16 พ.ย. 2569 · 0.7.0 ขั้น B–H] อีเวนต์ปฏิทิน + สุ่ม + กิจกรรม (PLAN_0_7_0 ข้อ 2–3)
## เปิด Test/event_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0
var ts: TimeSystem
var e: EconomyConfig


func _ready() -> void:
	await get_tree().process_frame
	ts = EventManager.time_system
	e = GameState.economy
	DayLoop.day_skip_seconds = 0.0
	DayLoop.tutorials = false
	GameState.seed_override = 77
	DayLoop._reset_run()
	DayLoop.quiet = true

	# A · ข้อมูล
	var bad := PackedStringArray()
	for ev in EventDirector.all():
		for p in ev.problems():
			bad.append("%s: %s" % [ev.id, p])
		if ev.speaker != "" and not Global.hasCharacter(ev.speaker):
			bad.append("%s: ไม่มีรูป %s" % [ev.id, ev.speaker])
	_check(bad.is_empty(), "ShopEvent ไม่มีปัญหา %s" % ", ".join(bad))
	for m in range(2, 13):
		_check(EventDirector.all().any(func(x: ShopEvent) -> bool: return x.kind == ShopEvent.Kind.CALENDAR and x.month == m), "เดือน %d มีอีเวนต์ปฏิทิน" % m)
	_check(EventDirector.quiz(&"booth").size() >= e.booth_questions and EventDirector.quiz(&"sala").size() >= e.sala_questions and EventDirector.quiz(&"kids").size() >= 1, "คำถามบูธ/ศาลา/เด็กพอ")

	# B · ปฏิทินขึ้นตรงวัน · สุ่ม ≤ 1/วัน · ไม่เกิดวันแรก/วันปฏิทินรายวัน · cooldown · ครั้งเดียว
	GameState.rank_level = 2
	var problems := PackedStringArray()
	var random_days := 0
	var grandma := 0
	for s in [11, 22, 33, 44, 55]:
		GameState.event_state = { }
		GameState.run_seed = s
		var last := { }
		for sh in range(1, 49):
			_day(sh)
			var m := ts.month()
			var d := ts.shift_in_week()
			var rnd := DayLoop.today_events.filter(func(x: ShopEvent) -> bool: return x.kind == ShopEvent.Kind.RANDOM)
			var cal_day := DayLoop.today_events.filter(func(x: ShopEvent) -> bool: return x.kind == ShopEvent.Kind.CALENDAR and x.day > 0)
			if rnd.size() > 1:
				problems.append("วัน %d สุ่ม %d อัน" % [sh, rnd.size()])
			if not rnd.is_empty() and (d == 1 or not cal_day.is_empty()):
				problems.append("วัน %d สุ่มชนวันแรก/ปฏิทิน" % sh)
			for x in rnd:
				random_days += 1
				var k := String((x as ShopEvent).key())
				if last.has(k) and sh - int(last[k]) < (x as ShopEvent).cooldown_days:
					problems.append("%s ซ้ำใน %d วัน" % [k, sh - int(last[k])])
				last[k] = sh
				if (x as ShopEvent).id == &"rnd_grandma":
					grandma += 1
			for x in EventDirector.calendar(m, d):
				if x.min_rank <= GameState.rank() and not DayLoop.event_has(x.id):
					problems.append("วัน %d ไม่มี %s" % [sh, x.id])
			DayLoop.event_cards.clear()
	_check(problems.is_empty(), "กติกาสุ่ม/ปฏิทินถูก %s" % ", ".join(problems.slice(0, 5)))
	_check(random_days >= 25 and random_days <= 140, "อีเวนต์สุ่ม 5 ปี = %d ครั้ง (~1 ครั้ง/เดือน)" % random_days)
	_check(grandma <= 5, "ยายไม่สบายไม่เกินปีละครั้ง (%d)" % grandma)

	# C · ผลต่อลูกค้า · หน้าร้อน · ตรุษจีน
	_day(_sh(4, 2))
	_check(DayLoop.event_has(&"cal_songkran") and DayLoop.event_visitor_mod() >= e.songkran_extra_visitors, "สงกรานต์ ลูกค้า +%d" % e.songkran_extra_visitors)
	_check(is_equal_approx(DayLoop.request_share_today(), e.request_share * 2.0), "สงกรานต์ คำขอ ×2")
	GameState.reputation = 50
	_day(_sh(11, 2))
	var low := DayLoop.event_visitor_mod()
	GameState.reputation = 70
	_check(low <= -1 and DayLoop.event_visitor_mod() == low + 1, "คู่แข่ง พ.ย. ชื่อเสียง < 60 = −1")
	_day(_sh(3, 3))
	_check(ScenarioBook.bias.get(&"mb_m1_paste", 1.0) > 1.0, "หน้าร้อน เคสความร้อน ×2")
	_day(_sh(2, 2))
	DayLoop._plan_vendor(ts)
	_check(not DayLoop.vendor.is_empty(), "หลังตรุษจีน รถขายของมาแน่")
	_day(_sh(8, 1))
	ScenarioBook.flood_open = false
	var fl := 0
	for k in 60:
		if ScenarioBook.roll(&"part_ram", DayLoop.rng(&"scenario"), [], 4, 8).condition == &"flood":
			fl += 1
	_check(fl == 0, "ส.ค. ก่อนพายุยังไม่มีเครื่องน้ำท่วม")

	# D · ไฟดับ → ซ่อมไม่ได้ · คำขอได้
	_day(_sh(5, 3))
	DayLoop.outage = Vector2i(600, 660)
	ts.set_clock(610)
	var rq: CustomerCase = load("res://Resources/Customers/any_request.tres")
	var job: CustomerCase = load("res://Resources/Customers/lv2_yai_ram.tres")
	_check(DayLoop.job_fit(job) == &"power" and DayLoop.job_fit(rq) != &"power", "ไฟดับ: ซ่อมไม่ได้ · คำขอได้")
	ts.set_clock(670)
	_check(DayLoop.job_fit(job) != &"power", "ไฟมาแล้วซ่อมได้")

	# E · พายุ: ไม่ถอดปลั๊ก → เสียเงิน + ความสนิท · เปิดน้ำท่วม · ไฟดับบ่าย
	_day(_sh(8, 2))
	_check(DayLoop.event_cards.any(func(c: Dictionary) -> bool: return c.id == &"cal_storm"), "ส.ค. วันที่ 2 มีการ์ดพายุ")
	DayLoop.event_cards.clear()
	var c1 := (load("res://Resources/Customers/any_ram.tres") as CustomerCase).instance_for(NpcBook.by_id(&"amnuay"))
	DayLoop.shelf.add(c1, ts.shift, 1)
	var m0 := GameState.money
	var a0 := int(GameState.npc_affinity.get(&"amnuay", 0))
	var storm := EventDirector.by_id(&"cal_storm")
	DayLoop.event_open(storm)
	var r := DayLoop.event_answer(storm.choices[2])
	DayLoop.event_finish()
	_check(not bool(r.correct) and GameState.money == m0 - e.storm_damage, "ไม่ถอดปลั๊ก → ชดใช้ ฿%d" % e.storm_damage)
	_check(int(GameState.npc_affinity.get(&"amnuay", 0)) < a0 or a0 == 0, "เจ้าของเครื่องความสนิทลด")
	_check(bool(GameState.story_flags.get("after_storm", false)) and ScenarioBook.flood_open and DayLoop.outage == e.storm_outage, "หลังพายุ: น้ำท่วมเปิด · ไฟดับบ่าย")
	DayLoop.shelf.orders.clear()
	DayLoop.event_open(storm)
	DayLoop.event_answer(storm.choices[0])
	DayLoop.event_finish()
	_check(bool(GameState.event_state.get("storm_safe", false)), "ถอดปลั๊ก = ปลอดภัย (D01)")

	# F · มิจฉาชีพ
	var scam := EventDirector.by_id(&"rnd_scam_bank")
	m0 = GameState.money
	DayLoop.event_open(scam)
	DayLoop.event_answer(scam.choices[1])
	DayLoop.event_finish()
	DayLoop.event_open(scam)
	DayLoop.event_answer(scam.choices[2])
	DayLoop.event_finish()
	_check(GameState.money == m0 - e.scam_loss and int(GameState.event_state.get("scam_safe", 0)) >= 1 and int(GameState.event_state.get("scam_lost", 0)) == 1, "มิจฉาชีพ: ถามกลับปลอดภัย · บอก OTP เสีย ฿%d" % e.scam_loss)

	# G · บูธงานบุญ
	_day(_sh(6, 3))
	DayLoop.event_cards.clear()
	var rep0 := GameState.reputation
	GameState.npc_affinity[&"min"] = 30
	var boo := EventDirector.by_id(&"cal_rocket")
	DayLoop.event_open(boo)
	var rb := DayLoop.event_answer(boo.choices[0])
	_check(bool(rb.more) and DayLoop.booth_today and DayLoop.visitor_waves.all(func(w: Dictionary) -> bool: return int(w.minute) >= e.booth_end_minute), "ออกบูธ: มีคำถาม · ไม่มีรอบลูกค้าก่อน 15:30")
	var n := 0
	while not DayLoop.event_state.is_empty() and n < 10:
		n += 1
		if bool(DayLoop.event_state.answered):
			if int(DayLoop.event_state.step) < (DayLoop.event_state.quiz as Array).size():
				DayLoop.event_state.step = int(DayLoop.event_state.step) + 1
				DayLoop.event_state.answered = false
			else:
				await DayLoop.event_finish()
				break
		var q: ShopEvent = (DayLoop.event_state.quiz as Array)[int(DayLoop.event_state.step) - 1]
		DayLoop.event_answer(q.choices[0])
	_check(GameState.reputation >= rep0 + e.booth_rep - 1 and ts.current_minute >= e.booth_end_minute and int(GameState.npc_affinity[&"min"]) > 30, "จบบูธ: ชื่อเสียง + · ♥ ชาวบ้าน · เวลา 15:30")

	# H · งานเหมาโรงเรียน
	_day(_sh(9, 3))
	_check(DayLoop.event_has(&"cal_school"), "ก.ย. วันที่ 3 โรงเรียนจ้าง (ยศ 2)")
	DayLoop.event_cards.clear()
	DayLoop.shelf.orders.clear()
	var sch := EventDirector.by_id(&"cal_school")
	DayLoop.event_open(sch)
	DayLoop.event_answer(sch.choices[0])
	DayLoop.event_finish()
	var co := DayLoop.shelf.orders.filter(func(o: RepairShelf.Order) -> bool: return o.case.has_meta("contract"))
	_check(co.size() == e.contract_machines and DayLoop.visitor_waves.is_empty(), "รับงานเหมา: %d เครื่องขึ้นชั้น · ไม่มีลูกค้าหน้าร้าน" % co.size())
	var total := 0
	for o in co:
		total += roundi((o as RepairShelf.Order).case.fee * e.promise_mult(0))
	_check(absi(total - e.contract_fee) <= e.contract_machines, "ค่าเหมารวม ≈ ฿%d (%d)" % [e.contract_fee, total])
	DayLoop._close_contract()
	_check(DayLoop.shelf.orders.filter(func(o: RepairShelf.Order) -> bool: return o.case.has_meta("contract")).is_empty(), "วันถัดไป เครื่องที่ไม่ได้ซ่อมโรงเรียนรับคืน")
	GameState.rank_level = 1
	_day(_sh(9, 3))
	_check(not DayLoop.event_has(&"cal_school"), "ยศไม่ถึง ไม่มีงานเหมา")
	GameState.rank_level = 2

	# I · ยายไม่สบาย → ร้านเปิด 11:00
	_day(_sh(5, 2))
	DayLoop.door_queue.clear()
	DayLoop.add_visitors(2, false, 0, TimeSystem.OPEN)
	var g := EventDirector.by_id(&"rnd_grandma")
	DayLoop.event_open(g)
	DayLoop.event_answer(g.choices[0])
	await DayLoop.event_finish()
	var back := DayLoop.door_queue.filter(func(j: Dictionary) -> bool: return not DayLoop.is_pickup(j)).size()
	for w in DayLoop.visitor_waves:
		if int(w.minute) == e.grandma_open_minute:
			back += int(w.count)
	_check(ts.current_minute >= e.grandma_open_minute and back >= 2 and DayLoop.visitor_waves.all(func(w: Dictionary) -> bool: return int(w.minute) >= e.grandma_open_minute), "ยายไม่สบาย: เวลา 11:00 · คนที่มาเช้ากลับมารอบ 11:00 (%d)" % back)

	# J · แข่งประกอบคอม (ตั้งที่ได้เอง) · ศาลา
	_day(_sh(10, 3))
	DayLoop.event_cards.clear()
	DayLoop.race_auto_place = 1
	m0 = GameState.money
	var race := EventDirector.by_id(&"cal_race")
	DayLoop.event_open(race)
	DayLoop.event_answer(race.choices[0])
	await DayLoop.event_finish()
	_check(GameState.money == m0 + e.race_prize[0] and int(GameState.event_state.get("race_best", 0)) == 1, "แข่งได้ที่ 1 → ฿%d" % e.race_prize[0])
	_check(DayLoop.race_place(100) == 1 and DayLoop.race_place(9999) == 0, "เกณฑ์ที่จากเวลา")
	DayLoop.race_auto_place = -1
	GameState.event_state.erase("sala_offered")
	_day(_sh(7, 2))
	_check(DayLoop.event_has(&"act_sala") or DayLoop.today_events.any(func(x: ShopEvent) -> bool: return x.kind == ShopEvent.Kind.RANDOM), "ก.ค. ยศ 2 ผู้ใหญ่บ้านชวนสอนศาลา")

	# K · บอท (quiet): การ์ดถึงเวลา → เลือกเอง
	_day(_sh(8, 2))
	GameState.event_state.erase("storm_safe")
	ts.set_clock(e.storm_card_minute + 30)
	DayLoop._tick_events(ts)
	_check(DayLoop.event_cards.is_empty() and bool(GameState.event_state.get("storm_safe", false)), "บอทตอบการ์ดพายุเอง (ถอดปลั๊ก)")
	_check(GameState.event_log.size() > 0, "จดประวัติอีเวนต์")

	# L · บทสอนครั้งแรก 0.7.0
	_check(["tut_event", "tut_deal", "tut_achievement"].all(func(k: String) -> bool: return DialogUtil.has_lines(DayLoop.TUTORIALS[k]) and DialogUtil.speakers_in(DayLoop.TUTORIALS[k]).all(func(x: String) -> bool: return Global.hasCharacter(x))), "บทสอนอีเวนต์/ร้านลดราคา/ใบประกาศ อ่านได้")
	DayLoop.quiet = false
	_day(_sh(4, 2))
	_check(DayLoop._npc_tutorials().has("tut_event"), "วันที่มีอีเวนต์ → บทสอนอีเวนต์")
	DayLoop.quiet = false
	GameState.seed_override = 0
	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _sh(m: int, d: int) -> int:
	return (m - 1) * TimeSystem.SHIFTS_PER_WEEK + d


func _day(sh: int) -> void:
	ts.shift = sh
	ts.set_clock(TimeSystem.OPEN)
	DayLoop.reseed_day()
	DayLoop._plan_events(ts)
	DayLoop._plan_visitors(ts)


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL ", msg)
	else:
		print("ok   ", msg)
