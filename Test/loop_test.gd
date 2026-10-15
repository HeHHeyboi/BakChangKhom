extends Node
## [Claude 9 ต.ค. 2569] ทดสอบลูปกะ/สัปดาห์ (LEVEL_DESIGN ข้อ 4–7): TimeSystem · ปลดระดับ · กระดานงาน · ล่วงเวลา · สรุปสัปดาห์
## เปิด Test/loop_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0" · มินิเกมเปิดจริงแล้วปิดทันที (คะแนนสมมติ)

var fails := 0
var _breaks: Array[StringName] = []
var _weeks: Array[int] = []
var _months: Array[int] = []
var _ended := false
var _closed := 0


func _ready() -> void:
	await get_tree().process_frame
	var root := get_tree().root
	get_parent().remove_child(self)
	root.add_child(self)
	var ts: TimeSystem = EventManager.time_system
	DayLoop.demo_shifts = 7 # [10 ต.ค.] เกมจริงจบบทที่ 1 ที่กะ 5 — เทสต์นี้เลื่อนไป 7 เพื่อทดสอบสรุปสัปดาห์ด้วย
	DayLoop.day_skip_seconds = 0.0 # [0.2.0] ปิดแอนิเมชันข้ามวันระหว่างเดินลูป (ทดสอบแยกในหัวข้อ A2)
	ts.break_started.connect(func(k: StringName) -> void: _breaks.append(k))
	ts.week_ended.connect(func(w: int) -> void: _weeks.append(w))
	ts.month_ended.connect(func(m: int) -> void: _months.append(m))
	ts.game_ended.connect(func() -> void: _ended = true)
	ts.shift_closed.connect(func() -> void: _closed += 1)

	# ---------------- A · TimeSystem
	ts.set_shift(1)
	_check(ts.current_minute == TimeSystem.OPEN and ts.remaining_work_minutes() == 480, "เปิดร้าน 08:30 · ทำงานได้ 8 ชม. (16 ช่อง)")
	ts.advance_minutes(120)
	_check(ts.current_minute == 11 * 60, "08:30 ทำงาน 2 ชม. → เริ่ม 09:00 จบ 11:00 (%s)" % TimeSystem.clock_text(ts.current_minute))
	ts.set_clock(11 * 60 + 30)
	ts.advance_minutes(60)
	_check(ts.current_minute == 13 * 60 + 30 and _breaks.has(&"lunch"), "11:30 +1 ชม. ข้ามพักเที่ยง → 13:30 (%s)" % TimeSystem.clock_text(ts.current_minute))
	ts.set_clock(15 * 60)
	ts.advance_minutes(60)
	_check(ts.current_minute == 16 * 60 + 30 and _breaks.has(&"afternoon"), "15:00 +1 ชม. ข้ามพักบ่าย → 16:30")
	ts.set_clock(9 * 60 + 10)
	ts.snap_to_slot()
	_check(ts.current_minute == 9 * 60 + 30, "ปัดเป็นช่อง 09:10 → 09:30")
	ts.set_clock(18 * 60)
	var got := ts.advance_minutes(120)
	_check(got == 30 and ts.current_minute == TimeSystem.CLOSE and _closed == 1, "18:00 +2 ชม. ไม่ล่วงเวลา → หยุด 18:30 (ทำได้ %d นาที)" % got)
	ts.set_shift(1, 18 * 60)
	ts.overtime = true
	ts.advance_minutes(120)
	_check(ts.current_minute == TimeSystem.OT_LIMIT, "ล่วงเวลา → หยุด 19:30")
	ts.set_shift(1)
	for i in 4:
		ts.end_shift()
	_check(_weeks.is_empty() and ts.shift_in_week() == 5, "4 กะยังไม่จบสัปดาห์")
	ts.end_shift()
	# [0.2.0] 1 บท = 1 เดือน = 5 วัน → จบบทยิงทั้ง week_ended และ month_ended
	_check(_weeks == [1] and _months == [1] and ts.week() == 2 and ts.month() == 2 and ts.chapter() == 2 and ts.shift_in_week() == 1, "ครบ 5 วัน → จบบท 1 = จบเดือน ม.ค. (week_ended + month_ended) · บท 2")
	ts.updateTime()
	_check(ts.dateText.text.contains("บทที่ 2") and ts.dateText.text.contains("ก.พ."), "HUD บอกบทและชื่อเดือน (%s)" % ts.dateText.text.replace("\n", " | "))
	ts.set_shift(55)
	ts.end_shift()
	_check(_months.back() == 11 and ts.month() == 12 and TimeSystem.MONTH_NAME[ts.month() - 1] == "ธ.ค.", "ครบ 55 วัน → month_ended(11) · บท 12 = ธ.ค.")
	_check(ts.work_slots_per_month() == 80, "เทิร์นงานต่อบท = 16 × 5 = 80")
	ts.set_shift(60)
	ts.end_shift()
	_check(_ended and ts.finished and _months.back() == 12, "ครบ 60 วัน → month_ended(12) + game_ended")
	_weeks.clear()
	_months.clear()

	# ---------------- A2 · [0.2.0] วันที่ได้เล่น + ข้ามวัน (ปิ๊บ + ปฏิทิน)
	ts.set_shift(2)
	_check(ts.calendar_day() == 7 and ts.date_text() == "7 ม.ค." and ts.days_since_last_play() == 6, "วันที่ 2 ของบท 1 = 7 ม.ค. · ผ่านไป 6 วัน")
	ts.set_shift(6)
	_check(ts.date_text() == "1 ก.พ." and ts.days_since_last_play() == 7, "วันแรกบท 2 = 1 ก.พ. · ข้ามจาก 25 ม.ค. = 7 วัน (%d)" % ts.days_since_last_play())
	ts.set_shift(11)
	_check(ts.date_text() == "1 มี.ค." and ts.days_since_last_play() == 4, "1 มี.ค. ข้ามจาก 25 ก.พ. (28 วัน) = 4 วัน")
	ts.set_shift(1)
	_check(ts.days_since_last_play() == 0, "วันแรกของเกมไม่มีข้ามวัน")
	var ds: DaySkip = DayLoop._day_skip
	ds.play(25, 1, 2, 7, PackedStringArray(["ของที่สั่งมาถึงแล้ว"]), 0.4)
	await _frames(3)
	_check(ds.visible and ds.is_playing() and ds._pib.texture != null, "ข้ามวัน → จอปิ๊บ + ปฏิทินขึ้น")
	await ds.finished
	_check(not ds.visible and ds._cal_day.text == "1" and ds._cal_month.text == "ก.พ." and ds._say.text.contains("ผ่านไป 7 วัน") and ds._say.text.contains("ของที่สั่งมาถึงแล้ว"), "ปฏิทินพลิกถึง 1 ก.พ. · ปิ๊บบอกผ่านไป 7 วัน + เรื่องที่เกิด (%s)" % ds._say.text.replace("\n", " / "))

	# ---------------- B · ระดับงาน
	DayLoop._reset_run()
	_check(not ts.finished and ts.shift == 1 and GameState.reputation == GameState.economy.reputation_start, "เริ่มเกมใหม่ → กะ 1 · ชื่อเสียงเริ่มต้น")
	_check(GameState.level_unlocked(2) and not GameState.level_unlocked(3), "เริ่มเกม Lv2 เปิด · Lv3 ล็อก")
	var w1 := DayLoop.effective_weights(1)
	_check(w1[0] == 70.0 and w1[1] == 30.0, "สัปดาห์ 1: Lv1 70 · Lv2 30 (มีงานขมOS แล้ว) (%s)" % w1)
	var w3 := DayLoop.effective_weights(3)
	_check(w3[2] == 0.0, "สัปดาห์ 3 ก่อนได้ ⭐⭐: Lv3 ยังไม่ขึ้น (%s)" % w3)
	var ids := DayLoop.board.map(func(j: Dictionary) -> StringName: return j["case"].id)
	var uniq := { }
	for i in ids:
		uniq[i] = true
	_check(DayLoop.board.size() == 5 and uniq.size() == 5 and DayLoop.board.all(func(j: Dictionary) -> bool: return j["case"].level <= 2),
		"กะ 1 กระดานมีงาน Lv1–2 %d ใบ (ไม่ซ้ำ) %s" % [DayLoop.board.size(), ids])
	_check(DayLoop.forced_case != null and DayLoop.forced_case.id == &"w1_d1_amnuay_space", "กะ 1 มีงานบังคับ ลุงอำนวย")
	_check(DayLoop.forced_case.level == 1 and DayLoop.forced_case.part_id == "part_desktop", "งานแรกของลุงเป็นงานบนจอ Lv1 (ไม่ซ้ำเควสต์ซ่อมแรม)")
	# ส่วนที่เหลือของเทสต์ทดสอบกลไกเวลา/ปลดระดับด้วยงาน Lv2 → ใช้เคสซ่อมแรมเดิมเป็นงานบังคับแทน
	DayLoop.forced_case = load("res://Resources/Customers/w1_d1_amnuay_ram.tres")

	# ---------------- C · เล่นกะ 1
	EventManager.eventMap[EventManager.EventID.MAIN].isDone = true
	SceneRouter.go(SceneRouter.ROOM)
	await _wait(2.4)
	_check(DialogScene.visible and DialogScene.DialogDict.get("dialog", []).size() == 6, "บทพักหลัง Tutorial")
	DialogScene.dialog_end()
	await _wait(DayLoop.time_skip_seconds + 0.8)
	_check(ts.current_minute == 9 * 60, "เวลาหมุน 08:30 → 09:00 (%s)" % TimeSystem.clock_text(ts.current_minute))
	await _wait(DayLoop.forced_delay + 0.4)
	_check(DialogScene.visible, "ลุงอำนวยเดินเข้ามาเอง")
	DialogScene.dialog_end()
	await _frames(3)
	_check(DayLoop._card == DayLoop.Card.JOB_FORCED and not DayLoop._secondary.visible, "การ์ดงานด่วน ปุ่มเดียว")
	DayLoop._on_primary()
	await _finish_minigame(96)
	_check(ts.current_minute == 11 * 60, "งาน Lv2 3 ช่อง + ครั้งแรก 1 ช่อง → 09:00 → 11:00 (%s)" % TimeSystem.clock_text(ts.current_minute))
	_check(DayLoop._card == DayLoop.Card.RESULT and GameState.money == GameState.economy.start_money + 150 + 20,
		"การ์ดผลงาน · ค่าแรง Lv2 ฿150 + ทิป ⭐⭐⭐ ฿20 (เงิน %d)" % GameState.money)
	print("T   ", DayLoop._body.text.replace("\n", " | "))
	DayLoop._on_primary()
	await _frames(3)
	_check(DayLoop._card == DayLoop.Card.BOARD and DayLoop._board_list.get_child_count() == DayLoop.board.size(), "กลับกระดานงาน (%d ใบ)" % DayLoop.board.size())
	var job_text: String = ""
	for n in DayLoop._board_list.get_children():
		job_text += _all_text(n)
	_check(not job_text.contains("ทำความสะอาดแรม") and job_text.contains("อาการ"), "การ์ดบนกระดานบอกอาการ ไม่บอก Part/ชื่องาน")
	# [Claude 9 ต.ค.] กระดานสัปดาห์ 1 มี Lv1 (ขมOS) ปน → เลือกงาน Lv2 ใบแรก (ไม่มีก็เติมงาน)
	var j2 := -1
	for tries in 60: # งาน Lv2 ซ่อมแรม (เคยทำแล้ว → ไม่บวกช่องครั้งแรก · เวลาคาดได้)
		for i in DayLoop.board.size():
			if DayLoop.board[i]["case"].level == 2 and DayLoop.board[i]["case"].part_id == "part_ram":
				j2 = i
				break
		if j2 >= 0:
			break
		_swap_job()
	var c0: CustomerCase = DayLoop.board[j2]["case"]
	DayLoop.accept_job(j2)
	await _frames(2)
	_check(DialogScene.visible and DayLoop.today_case == c0, "รับงาน → บทลูกค้า %s" % c0.customer)
	DialogScene.dialog_end()
	await _finish_minigame(85)
	_check(ts.current_minute == 13 * 60 + 30, "11:00 + 3 ช่อง ข้ามพักเที่ยง → 13:30 (%s)" % TimeSystem.clock_text(ts.current_minute))
	_check(GameState.level_unlocked(3), "ได้ ⭐⭐ Lv2 ครบ 2 งาน → ปลด Lv3")
	DayLoop._on_primary()
	await _frames(2)
	var rep := GameState.reputation
	var n_before := DayLoop.board.size()
	DayLoop.reject_job(0)
	_check(DayLoop.board.size() == n_before - 1 and GameState.reputation == rep + GameState.economy.rep_reject, "ปฏิเสธงาน → หายจากกระดาน ชื่อเสียง −1")

	# ล่วงเวลา
	DayLoop.add_jobs(2)
	ts.set_clock(17 * 60 + 30)
	var j_ot := -1
	for tries in 30: # งาน Lv1 (1 ช่อง) ไม่ล่วงเวลา → เติมงานจนมี Lv2
		for i in DayLoop.board.size():
			if DayLoop.job_fit(DayLoop.board[i]["case"]) == &"ot" and DayLoop.job_slots(DayLoop.board[i]["case"]) == 3: # [10 ต.ค.] งานโต๊ะช่าง 4 ช่องทำให้สุ่มพลาด
				j_ot = i
				break
		if j_ot >= 0:
			break
		_swap_job()
	_check(j_ot >= 0, "17:30 งาน 3 ช่อง → ต้องล่วงเวลา")
	if j_ot >= 0:
		DayLoop.accept_job(j_ot)
		await _frames(2)
		DialogScene.dialog_end()
		await _finish_minigame(70)
		_check(ts.overtime and ts.current_minute == 19 * 60 and DayLoop.ot_this_week == 1, "ล่วงเวลา → จบ 19:00 · นับ 1 กะในสัปดาห์ (%s)" % TimeSystem.clock_text(ts.current_minute))
		DayLoop._on_primary()
		await _frames(3)
	_check(DayLoop._card == DayLoop.Card.SHIFT_END, "เลย 18:30 → การ์ดปิดร้าน")
	var money_before := GameState.money
	print("T   ", DayLoop._body.text.replace("\n", " | "))
	DayLoop._on_primary()
	await _frames(3)
	_check(ts.shift == 2 and GameState.money == money_before - DayLoop.ot_slots_now() - 1 * GameState.economy.ot_cost_per_slot,
		"ปิดร้าน → กะ 2 · จ่ายค่าไฟล่วงเวลา 1 ช่อง ฿30")
	_check(DayLoop._card == DayLoop.Card.BOARD and DayLoop.board.size() > 0, "กะ 2 กระดานมีงาน (%d ใบ)" % DayLoop.board.size())

	# [10 ต.ค.] ย่อกระดาษงาน → เหลือแถบ · กดแถบ → กลับมา
	DayLoop.set_cards_hidden(true)
	await _frames(3)
	_check(not DayLoop._board_panel.visible and DayLoop._cards_tab.visible and DayLoop._cards_tab.text.contains("กระดานงาน"), "ย่อกระดานงาน → เหลือแถบมุมขวา")
	DayLoop._cards_tab.pressed.emit()
	await _frames(3)
	_check(DayLoop._board_panel.visible and not DayLoop._cards_tab.visible, "กดแถบ → กระดานงานกลับมา")

	# กะ 2–5: ปิดร้านเลย · งานหมดเขตต้องเดินออก
	for s in range(2, 6):
		ts.set_clock(TimeSystem.CLOSE)
		await _frames(3)
		_check(DayLoop._card == DayLoop.Card.SHIFT_END, "กะ %d ปิดร้าน" % s)
		DayLoop._on_primary()
		await _frames(3)
	_check(_weeks == [1] and DayLoop._card == DayLoop.Card.WEEK_SUMMARY, "ครบ 5 กะ → สรุปสัปดาห์ 1")
	print("T   ", DayLoop._body.text.replace("\n", " | "))
	_check(GameState.reputation < rep, "ลูกค้าที่รอนานเกินเดินออก → ชื่อเสียงลด (%d → %d)" % [rep, GameState.reputation])
	DayLoop._on_primary()
	await _frames(3)
	_check(DialogScene.visible and DialogScene.Title.text.contains("คอมเก่า"), "สรุปสัปดาห์ → บท Chapter 2")
	DialogScene.dialog_end()
	await _frames(3)
	_check(ts.week() == 2 and DayLoop._card == DayLoop.Card.BOARD, "สัปดาห์ 2 กะ 1 → กระดานงาน")
	_check(DayLoop.effective_weights(2)[2] > 0.0, "สัปดาห์ 2 มีสัดส่วน Lv3 แล้ว (%s)" % DayLoop.effective_weights(2))

	# [10 ต.ค.] จบบท (demo_shifts): ปิดร้านกะสุดท้าย → การ์ดจบบท → กลับบ้าน → บทยาย → ป้าย "กำลังพัฒนา"
	# (เกมจริงจบที่กะ 5 = จบบทที่ 1 · เทสต์นี้ตั้ง 7 เพื่อทดสอบสรุปสัปดาห์ + Chapter 2 ก่อน)
	for s in [6, 7]:
		ts.set_clock(TimeSystem.CLOSE)
		await _frames(3)
		_check(DayLoop._card == DayLoop.Card.SHIFT_END and ts.shift == s, "กะ %d ปิดร้าน" % s)
		if s == 7:
			_check(DayLoop._primary.text.contains("จบบทที่"), "กะ 7 ปุ่มปิดร้าน = จบบท (%s)" % DayLoop._primary.text)
		DayLoop._on_primary()
		await _frames(3)
	_check(DayLoop.demo_over and ts.shift == 7 and DayLoop._card == DayLoop.Card.DEMO_END, "ครบ 7 กะ → การ์ดสิ้นสุดการเล่นเดโม")
	print("T   ", DayLoop._body.text.replace("\n", " | "))
	_check(DayLoop._title.text.contains("จบบทที่ 1") and DayLoop._body.text.contains("ยศช่าง"), "การ์ดจบบทมียศช่าง")
	DayLoop._on_primary()
	await _wait(3.0)
	_check(SceneRouter.current_id == SceneRouter.HOME and DialogScene.visible and DialogScene.Title.text == "จบบทที่ 1", "กลับบ้าน → บทปิดบทกับยาย (%s · %s · %s)" % [SceneRouter.current_id, DialogScene.visible, DialogScene.Title.text])
	DialogScene.dialog_end()
	await _frames(3)
	_check(DayLoop._demo_banner.visible, "จบบทกับยาย → ป้ายจบบทที่ 1 (กำลังพัฒนาบทที่ 2)")
	_check(DayLoop._card == DayLoop.Card.NONE and not DayLoop._board_panel.visible, "หลังจบเดโมไม่มีกระดานงาน")
	_check(DayLoop._demo_card.visible and DayLoop._demo_layer.layer > 100, "หน้าจบเดโมอยู่กลางจอ เหนือ HUD")
	_check(Audio.want_music() == &"demo_end", "จบเดโม → เพลงจบเดโม")
	DayLoop._demo_minimize(true)
	_check(not DayLoop._demo_card.visible and DayLoop._demo_badge.visible, "อยู่ในบ้านต่อ → เหลือป้ายเล็ก")
	DayLoop._reset_run()
	_check(not DayLoop.demo_over and not DayLoop._demo_banner.visible and ts.shift == 1, "เริ่มใหม่ → ล้างสถานะเดโม")

	# บิลรายเดือน [0.2.0] = ทุกบท · ค่าเช่า (บท 1 = 0) + ไฟ (ฐาน + 4/เทิร์น) + น้ำ 50 + เน็ต 150
	GameState.debt = 0
	GameState.money = 5000
	var m0 := GameState.money
	var bill := GameState.pay_month_bill(1, 20)
	_check(int(bill["total"]) == 0 + (100 + 4 * 20) + 50 + 150 and GameState.money == m0 - int(bill["paid"]) and GameState.debt == 0, "บิลบท 1 (ทำงาน 20 เทิร์น) = ฿380 (จ่าย %d)" % bill["paid"])
	bill = GameState.pay_month_bill(9, 60)
	_check(int(bill["rent"]) == 700 and int(bill["power"]) == 150 + 240 and int(bill["total"]) == 700 + 390 + 50 + 150, "บิลบท 9 = เช่า 700 + ไฟ 390 + น้ำ 50 + เน็ต 150 (= %d)" % bill["total"])
	GameState.money = 100
	bill = GameState.pay_month_bill(2, 0)
	_check(int(bill["paid"]) == 100 and GameState.money == 0 and GameState.debt == int(bill["total"]) - 100, "เงินไม่พอ → จ่ายเท่าที่มี ส่วนที่ขาดเป็นยอดค้าง (ค้าง %d)" % GameState.debt)
	bill = GameState.pay_month_bill(3, 0)
	_check(int(bill["prev_debt"]) > 0 and int(bill["total"]) == 300 + 100 + 50 + 150 + int(bill["prev_debt"]), "ยอดค้างเดิมรวมในบิลบทถัดไป")
	GameState.debt = 0

	print("T DONE fails=", fails)
	get_tree().quit()


## รอมินิเกมขึ้น (จอดำ 1 วิ) → ส่งคะแนน → ปิด
func _finish_minigame(score: int) -> void:
	await _wait(1.4)
	var m: Node = DayLoop._minigame
	_check(m != null and m.is_inside_tree() and m.get_meta("work_order", null) == DayLoop.today_case, "เปิดมินิเกม %s" % (DayLoop.today_case.part_id if DayLoop.today_case else "?"))
	if m == null:
		return
	var c: CustomerCase = DayLoop.today_case
	GameState.record_repair(c.part(), score, false, c.fee, c.level)
	SceneRouter.pop()
	Global.in_minigame = false
	EventManager.showUI()
	await _frames(3)


## เอางาน Lv1 ใบแรกออกจากกระดาน (ไม่หักชื่อเสียง) แล้วสุ่มใบใหม่ — ใช้หางาน Lv2 ในสัปดาห์ที่ Lv1 70%
func _swap_job() -> void:
	for i in DayLoop.board.size():
		var c: CustomerCase = DayLoop.board[i]["case"]
		if not (c.level == 2 and c.part_id == "part_ram"):
			DayLoop.board.remove_at(i)
			break
	DayLoop.add_jobs(1)
	DayLoop._board_dirty = true


func _all_text(n: Node) -> String:
	var t := ""
	if n is Label:
		t += (n as Label).text
	for ch in n.get_children():
		t += _all_text(ch)
	return t


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
