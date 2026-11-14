extends Node
## [Claude 9 ต.ค. 2569 · 0.2.5 1 บท = 1 เดือน] ทดสอบลูปกะ/บท/เดือน (LEVEL_DESIGN ข้อ 4–7): TimeSystem · ปลดระดับ · หน้าประตู (0.3.0) · ล่วงเวลา · สรุปสัปดาห์
## เปิด Test/loop_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0" · มินิเกมเปิดจริงแล้วปิดทันที (คะแนนสมมติ)

var fails := 0
var _breaks: Array[StringName] = []
var _weeks: Array[int] = []
var _months: Array[int] = []
var _ended := false
var _closed := 0
var _rem_checked := false


func _ready() -> void:
	await get_tree().process_frame
	var root := get_tree().root
	get_parent().remove_child(self)
	root.add_child(self)
	var ts: TimeSystem = EventManager.time_system
	DayLoop.demo_shifts = 6 # [0.2.5] เกมจริงจบบทที่ 1 ที่วันที่ 4 (25 ม.ค.) — เทสต์นี้เลื่อนไป 6 เพื่อทดสอบสรุปเดือน + บทที่ 2 ด้วย
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
	for i in 3:
		ts.end_shift()
	_check(_weeks.is_empty() and ts.shift_in_week() == 4, "3 วันยังไม่จบบท")
	ts.end_shift()
	# [0.2.5] 1 บท = 1 เดือน (เปิดร้าน 4 วัน วันที่ 4 · 11 · 18 · 25)
	_check(_weeks == [1] and _months == [1] and ts.week() == 2 and ts.chapter() == 2 and ts.month() == 2 and ts.shift_in_week() == 1, "ครบ 4 วัน → จบบท 1 = สิ้นเดือน ม.ค. · บท 2 = ก.พ.")
	ts.updateTime()
	_check(ts.dateText.text.contains("พฤหัสบดี 4 ก.พ.") and ts.dateText.text.contains("บทที่ 2 · กุมภาพันธ์ · วันที่ 1/4") and not ts.dateText.text.contains("สัปดาห์"), "HUD บอกวัน + บท + เดือน (%s)" % ts.dateText.text.replace("\n", " | "))
	ts.set_shift(44)
	ts.end_shift()
	_check(_months.back() == 11 and ts.month() == 12 and ts.chapter() == 12, "ครบ 44 วัน → month_ended(11) · บท 12 = ธ.ค.")
	_check(ts.work_slots_per_month() == 64 and TimeSystem.TOTAL_SHIFTS == 48, "เทิร์นงานต่อเดือน = 16 × 4 = 64 · ทั้งเกม 48 วัน")
	ts.set_shift(48)
	ts.end_shift()
	_check(_ended and ts.finished and _months.back() == 12, "ครบ 48 วัน (12 บท = 1 ปี) → month_ended(12) + game_ended")
	_weeks.clear()
	_months.clear()

	# ---------------- A2 · [0.2.5] ปฏิทินจริง 2570 · เปิดร้านวันที่ 4 · 11 · 18 · 25 ของทุกเดือน
	ts.set_shift(1)
	_check(ts.date_text() == "จ. 4 ม.ค." and ts.days_since_last_play() == 0, "วันแรกของเกม = จ. 4 ม.ค. ไม่มีข้ามวัน")
	ts.set_shift(2)
	_check(ts.date_text() == "จ. 11 ม.ค." and ts.days_since_last_play() == 7, "วันที่ 2 = 11 ม.ค. · ผ่านไป 7 วัน")
	ts.set_shift(4)
	_check(ts.date_text() == "จ. 25 ม.ค." and ts.days_left_in_month() == 0, "วันที่ 4 = 25 ม.ค. = วันสุดท้ายของ ม.ค.")
	ts.set_shift(5)
	_check(ts.date_text() == "พฤ. 4 ก.พ." and ts.month() == 2 and ts.days_since_last_play() == 10, "บท 2 เริ่ม พฤ. 4 ก.พ. · ข้ามเดือน 10 วัน")
	ts.set_shift(9)
	_check(ts.date_text() == "พฤ. 4 มี.ค." and ts.month() == 3 and ts.days_since_last_play() == 7, "บท 3 = 4 มี.ค. (ก.พ. 28 วัน → 25 ก.พ. ถึง 4 มี.ค. = 7 วัน)")
	ts.set_shift(48)
	_check(ts.date_text() == "ส. 25 ธ.ค." and ts.days_left_in_month() == 0 and TimeSystem.shift_label(48) == "บทที่ 12 · ส. 25 ธ.ค.", "วันสุดท้ายของเกม = ส. 25 ธ.ค.")
	ts.set_shift(1)
	_check(ts.days_left_in_month() == 3 and TimeSystem.weekday_of(9, 1) == 5 and TimeSystem.weekday_of(10, 1) == 6, "เหลือ 3 วันเปิดร้านใน ม.ค. · 9–10 ม.ค. = เสาร์–อาทิตย์")
	var ds: DaySkip = DayLoop._day_skip
	ds.play(25, 4, 2, 10, PackedStringArray(["ของที่สั่งมาถึงแล้ว"]), 0.4)
	await _frames(3)
	_check(ds.visible and ds.is_playing() and ds._pib.texture != null, "ข้ามวัน → จอปิ๊บ + ปฏิทินขึ้น")
	await ds.finished
	_check(not ds.visible and ds._page_day.text == "4" and ds._page_month.text == "ก.พ." and ds._page_wd.text == "พฤหัสบดี" and ds._passed.text.begins_with("ผ่านไป 10 วัน") and ds._passed.text.contains("เข้าสู่เดือนกุมภาพันธ์"), "25 ม.ค. → พฤ. 4 ก.พ. · ป้าย \"%s\"" % ds._passed.text)
	_check(ds._pib.visible and ds._say.text == "ของที่สั่งมาถึงแล้ว" and not ds._say.text.contains("ผ่านไป"), "ปิ๊บพูดแค่เรื่องที่เกิดระหว่างข้ามวัน")
	ds.play(4, 11, 1, 7, PackedStringArray(), 0.3)
	await ds.finished
	_check(not ds._pib.visible and ds._page_day.text == "11" and ds._page_wd.text == "จันทร์" and ds._passed.text == "ผ่านไป 7 วัน · ร้านปิด ขมไปช่วยยาย", "4 → 11 ม.ค. · ไม่มีปิ๊บ · บอกว่าร้านปิด (%s)" % ds._passed.text)

	# ---------------- B · ระดับงาน
	DayLoop._reset_run()
	_check(not ts.finished and ts.shift == 1 and GameState.reputation == GameState.economy.reputation_start, "เริ่มเกมใหม่ → กะ 1 · ชื่อเสียงเริ่มต้น")
	_check(GameState.level_unlocked(2) and not GameState.level_unlocked(3), "เริ่มเกม Lv2 เปิด · Lv3 ล็อก")
	var w1 := DayLoop.effective_weights(1)
	_check(w1[0] == 70.0 and w1[1] == 30.0, "สัปดาห์ 1: Lv1 70 · Lv2 30 (มีงานขมOS แล้ว) (%s)" % w1)
	var w3 := DayLoop.effective_weights(3)
	_check(w3[2] == 0.0, "สัปดาห์ 3 ก่อนได้ ⭐⭐: Lv3 ยังไม่ขึ้น (%s)" % w3)
	var ids := DayLoop.door_queue.map(func(j: Dictionary) -> StringName: return j["case"].id)
	var uniq := { }
	for i in ids:
		uniq[i] = true
	# [0.2.5] ลูกค้า 5 คน (ชื่อเสียง 20 = ปกติ) ทยอยมา 3 รอบ: เปิดร้าน 3 · 11:00 1 · 14:00 1
	_check(DayLoop.visitors_today == 5 and GameState.economy.split_waves(5) == PackedInt32Array([3, 1, 1]) and DayLoop.visitor_waves.size() == 2, "ลูกค้าวันนี้ 5 คน แบ่ง 3 · 1 · 1 (%s)" % [DayLoop.visitor_waves])
	_check(DayLoop.door_queue.size() == 3 and uniq.size() == 3 and DayLoop.door_queue.all(func(j: Dictionary) -> bool: return j["case"].level <= 2 and not j.phone and not j.appointed),
		"[0.3.0] กะ 1 เปิดร้านมีลูกค้า Lv1–2 ยืนหน้าประตู %d คน (ไม่ซ้ำ) %s" % [DayLoop.door_queue.size(), ids])
	var e := GameState.economy
	_check(e.visitors_for(1, 10) == 4 and e.visitors_for(1, 20) == 5 and e.visitors_for(1, 45) == 6 and e.visitors_for(1, 80) == 7 and e.visitors_for(9, 0) == 2 and e.visitors_for(8, 0) == 2, "[0.2.5] ชื่อเสียงคุมจำนวนลูกค้า: <20 → 4 · 20 → 5 · 45 → 6 · 80 → 7 · ก.ย./ส.ค. ชื่อเสียง 0 → ขั้นต่ำ 2")
	_check(e.visitors_for(2, 20) == 6 and e.visitors_for(6, 20) == 3 and String(e.month_event(4).name) == "สงกรานต์" and e.month_events.size() == 12 and e.month_event_notes.size() == 12 and e.month_visitor_bonus.size() == 12, "[0.2.5] เทศกาล: ตรุษจีน +1 · บุญบั้งไฟ −1 · เม.ย. = สงกรานต์ · ครบ 12 เดือน")
	_check(DayLoop.visitors_line().contains("ลูกค้าวันนี้มาแล้ว 3/5 คน") and DayLoop.visitors_line().contains("รอบถัดไปอีก"), "กระดานบอกชื่อเสียง + ลูกค้าวันนี้ (%s)" % DayLoop.visitors_line())
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
	var pops := DayLoop.reward_popup.live.map(func(l: Label) -> String: return l.text)
	_check(DayLoop.reward_popup.get_parent().name == "PopupLayer" and (DayLoop.reward_popup.get_parent() as CanvasLayer).layer == 106 and pops.has("+฿170") and pops.has("XP +100") and pops.any(func(t: String) -> bool: return t.begins_with("ชื่อเสียง +")), "[0.2.5] ตัวเลขเด้งตอนส่งงาน (PopupLayer ชั้น 106) %s" % [pops])
	print("T   ", DayLoop._body.text.replace("\n", " | "))
	DayLoop._on_primary()
	await _frames(3)
	_check(DayLoop._card == DayLoop.Card.DOOR and DayLoop.door_queue.size() == 4 and DayLoop._board_list.get_child_count() == 2, "[0.3.0] กลับหน้าร้าน · ระหว่างงานเนื้อเรื่องลูกค้าไม่หมดความอดทน (%d คน)" % DayLoop.door_queue.size())
	var job_text: String = ""
	for n in DayLoop._board_list.get_children():
		job_text += _all_text(n)
	_check(not job_text.contains("ทำความสะอาดแรม") and job_text.contains("อาการ") and job_text.contains("รอคิวอีก 3 คน"), "การ์ดหน้าประตูบอกอาการ ไม่บอก Part/ชื่องาน · บอกคิวที่รอ")
	# [Claude 9 ต.ค.] กระดานสัปดาห์ 1 มี Lv1 (ขมOS) ปน → เลือกงาน Lv2 ใบแรก (ไม่มีก็เติมงาน)
	var j2 := -1
	for tries in 60: # งาน Lv2 ซ่อมแรม (เคยทำแล้ว → ไม่บวกช่องครั้งแรก · เวลาคาดได้)
		for i in DayLoop.door_queue.size():
			if DayLoop.door_queue[i]["case"].level == 2 and DayLoop.door_queue[i]["case"].part_id == "part_ram":
				j2 = i
				break
		if j2 >= 0:
			break
		_swap_job()
	var c0: CustomerCase = _to_front(j2)["case"]
	_check(DayLoop.door_accept(), "รับเครื่องคนหน้าประตู (ซ่อมเลย)")
	_check(DayLoop.accepted_today == 1, "[0.3.0] รับแล้ววันนี้ 1/3")
	await _frames(2)
	_check(DialogScene.visible and DayLoop.today_case == c0, "รับงาน → บทลูกค้า %s" % c0.customer)
	DialogScene.dialog_end()
	await _finish_minigame(85)
	_check(ts.current_minute == 13 * 60 + 30, "11:00 + 3 ช่อง ข้ามพักเที่ยง → 13:30 (%s)" % TimeSystem.clock_text(ts.current_minute))
	_check(GameState.level_unlocked(3), "ได้ ⭐⭐ Lv2 ครบ 2 งาน → ปลด Lv3")
	DayLoop._on_primary()
	await _frames(2)
	_check(DayLoop.walkouts.size() == 3 and DayLoop.door_queue.is_empty(), "[0.3.0] ซ่อม 3 เทิร์น → คนที่ยืนรอ 3 คนหมดความอดทน เดินกลับ (%s)" % [DayLoop.walkouts])
	DayLoop.add_visitors(1)
	var rep := GameState.reputation
	var n_before := DayLoop.door_queue.size()
	DayLoop.door_reject()
	_check(DayLoop.door_queue.size() == n_before - 1 and GameState.reputation == rep + GameState.economy.rep_reject, "ปฏิเสธ → ลูกค้าหน้าประตูกลับไป ชื่อเสียง −1")

	# ล่วงเวลา
	ts.set_clock(17 * 60 + 30)
	DayLoop.add_visitors(2)
	var j_ot := -1
	for tries in 30: # งาน Lv1 (1 ช่อง) ไม่ล่วงเวลา → เติมงานจนมี Lv2
		for i in DayLoop.door_queue.size():
			if not DayLoop.door_queue[i].phone and DayLoop.job_fit(DayLoop.door_queue[i]["case"]) == &"ot" and DayLoop.job_slots(DayLoop.door_queue[i]["case"]) == 3: # [10 ต.ค.] งานโต๊ะช่าง 4 ช่องทำให้สุ่มพลาด
				j_ot = i
				break
		if j_ot >= 0:
			break
		_swap_job()
	_check(j_ot >= 0, "17:30 งาน 3 ช่อง → ต้องล่วงเวลา")
	if j_ot >= 0:
		_to_front(j_ot)
		_check(DayLoop.door_accept_state() == &"ot" and DayLoop.door_accept(), "รับเครื่อง (ล่วงเวลา)")
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
	_check(DayLoop._card == DayLoop.Card.DOOR and DayLoop.door_queue.size() > 0 and DayLoop.accepted_today == 0, "กะ 2 มีลูกค้าหน้าประตู (%d คน) · โควตาเริ่มใหม่" % DayLoop.door_queue.size())

	# [10 ต.ค.] ย่อกระดาษงาน → เหลือแถบ · กดแถบ → กลับมา
	DayLoop.set_cards_hidden(true)
	await _frames(3)
	_check(not DayLoop._board_panel.visible and DayLoop._cards_tab.visible and DayLoop._cards_tab.text.contains("หน้าร้าน"), "ย่อการ์ดหน้าร้าน → เหลือแถบมุมขวา")
	DayLoop._cards_tab.pressed.emit()
	await _frames(3)
	_check(DayLoop._board_panel.visible and not DayLoop._cards_tab.visible, "กดแถบ → กระดานงานกลับมา")

	# กะ 2–4: ปิดร้านเลย · งานหมดเขตต้องเดินออก
	for s in range(2, 5):
		ts.set_clock(TimeSystem.CLOSE)
		await _frames(3)
		_check(DayLoop._card == DayLoop.Card.SHIFT_END, "กะ %d ปิดร้าน" % s)
		DayLoop._on_primary()
		await _frames(3)
	_check(_weeks == [1] and _months == [1] and DayLoop._card == DayLoop.Card.WEEK_SUMMARY and DayLoop.month_summary.visible, "[0.2.5] ครบ 4 วัน → สรุปบท 1 = หน้าสรุปเดือน ม.ค.")
	print("T   ", DayLoop._body.text.replace("\n", " | "))
	var goal_rep: int = GameState.economy.rep_month_goal if bool(DayLoop._last_month.get("reached", false)) else 0
	_check(GameState.reputation < rep + goal_rep, "ลูกค้าที่รอนานเกินเดินออก → ชื่อเสียงลด (%d → %d)" % [rep, GameState.reputation])
	DayLoop._on_primary()
	await _frames(3)
	_check(DialogScene.visible and DialogScene.Title.text.contains("เก่าของขม"), "สรุปสัปดาห์ → บท Chapter 2")
	DialogScene.dialog_end()
	await _frames(3)
	# [0.2.5] บท 2 วันที่ 1 มีลูกค้าเนื้อเรื่อง (week2.tres) เดินเข้ามาเอง → เล่นให้จบก่อน
	_check(ts.week() == 2 and DayLoop.forced_case != null and DayLoop.forced_case.id == &"w2_min_ram", "บท 2 วันที่ 1 มีงานเนื้อเรื่อง มิ้น (%s)" % (DayLoop.forced_case.id if DayLoop.forced_case else "ไม่มี"))
	await _wait(DayLoop.time_skip_seconds + DayLoop.forced_delay + 1.2)
	_check(DialogScene.visible and DialogScene.Title.text.contains("มิ้น"), "มิ้นเดินเข้ามาเอง (%s)" % DialogScene.Title.text)
	DialogScene.dialog_end()
	await _frames(3)
	_check(DayLoop._card == DayLoop.Card.JOB_FORCED, "การ์ดงานเนื้อเรื่อง ปุ่มเดียว")
	DayLoop._on_primary()
	await _finish_minigame(90)
	DayLoop._on_primary()
	await _frames(3)
	_check(ts.week() == 2 and DayLoop._card == DayLoop.Card.DOOR, "สัปดาห์ 2 กะ 1 → หน้าร้าน")
	_check(DayLoop.effective_weights(2)[2] > 0.0, "สัปดาห์ 2 มีสัดส่วน Lv3 แล้ว (%s)" % DayLoop.effective_weights(2))

	# [10 ต.ค.] จบบท (demo_shifts): ปิดร้านกะสุดท้าย → การ์ดจบบท → กลับบ้าน → บทยาย → ป้าย "กำลังพัฒนา"
	# (เกมจริงจบที่วันที่ 4 = จบบทที่ 1 · เทสต์นี้ตั้ง 6 เพื่อทดสอบสรุปเดือน + Chapter 2 ก่อน)
	for s in [5, 6]:
		ts.set_clock(TimeSystem.CLOSE)
		await _frames(3)
		_check(DayLoop._card == DayLoop.Card.SHIFT_END and ts.shift == s, "กะ %d ปิดร้าน" % s)
		if s == 6:
			_check(DayLoop._primary.text.contains("จบบทที่"), "กะ 6 ปุ่มปิดร้าน = จบบท (%s)" % DayLoop._primary.text)
		DayLoop._on_primary()
		await _frames(3)
	_check(DayLoop.demo_over and ts.shift == 6 and DayLoop._card == DayLoop.Card.DEMO_END, "ครบ 6 วัน → การ์ดสิ้นสุดการเล่นเดโม")
	print("T   ", DayLoop._body.text.replace("\n", " | "))
	_check(DayLoop._title.text.contains("จบบทที่ 2") and DayLoop._body.text.contains("ยศช่าง"), "การ์ดจบบทมียศช่าง (เดโมเทสต์จบวันที่ 6 = บทที่ 2)")
	DayLoop._on_primary()
	await _wait(3.0)
	_check(SceneRouter.current_id == SceneRouter.HOME and DialogScene.visible and DialogScene.Title.text == "จบบทที่ 2", "กลับบ้าน → บทปิดบทกับยาย (%s · %s · %s)" % [SceneRouter.current_id, DialogScene.visible, DialogScene.Title.text])
	DialogScene.dialog_end()
	await _frames(3)
	_check(DayLoop._demo_banner.visible and (DayLoop._demo_card.find_child("Text", true, false) as Label).text.contains("บทที่ 3"), "จบบทกับยาย → ป้ายจบบทที่ 2 (กำลังพัฒนาบทที่ 3)")
	_check(DayLoop._card == DayLoop.Card.NONE and not DayLoop._board_panel.visible, "หลังจบเดโมไม่มีกระดานงาน")
	_check(DayLoop._demo_card.visible and DayLoop._demo_layer.layer > 100, "หน้าจบเดโมอยู่กลางจอ เหนือ HUD")
	_check(Audio.want_music() == &"demo_end", "จบเดโม → เพลงจบเดโม")
	DayLoop._demo_minimize(true)
	_check(not DayLoop._demo_card.visible and DayLoop._demo_badge.visible, "อยู่ในบ้านต่อ → เหลือป้ายเล็ก")
	DayLoop._reset_run()
	_check(not DayLoop.demo_over and not DayLoop._demo_banner.visible and ts.shift == 1, "เริ่มใหม่ → ล้างสถานะเดโม")

	# [0.2.5] ลูกค้าทยอยมา: 11:00 · 14:00 · ป้ายแจ้ง · ไม่รับภายในวัน = กลับบ้าน ชื่อเสียง −1/คน
	DayLoop._reset_run()
	var toast: VisitorToast = DayLoop.visitor_toast
	_check(toast != null and toast.get_parent().name == "ToastLayer" and (toast.get_parent() as CanvasLayer).layer == 104, "ป้ายลูกค้าเข้าร้านอยู่ใน day_loop.tscn → ToastLayer ชั้น 104")
	toast.clear()
	ts.set_clock(11 * 60)
	_check(DayLoop.visitors_arrived == 4 and DayLoop.door_queue.size() == 4 and toast._queue.size() == 1 and toast._queue[0][0] == "มีลูกค้ามารอหน้าร้าน 1 คน", "11:00 ลูกค้ารอบ 2 มารอหน้าร้าน + ป้ายแจ้ง (ลุงอำนวยยังไม่มา ความอดทนไม่เดิน)")
	ts.set_clock(14 * 60 + 30)
	_check(DayLoop.visitors_arrived == 5 and DayLoop.visitor_waves.is_empty(), "14:00 ครบ 5 คน")
	var rep_close := GameState.reputation
	var n_left := DayLoop.door_queue.size()
	ts.end_shift()
	await _frames(2)
	_check(DayLoop.left_home.size() == n_left and GameState.reputation == rep_close + n_left * GameState.economy.rep_left_unserved and DayLoop.walkouts.is_empty(), "ปิดร้าน → ลูกค้า %d คนกลับบ้าน ชื่อเสียง −1/คน (%d → %d)" % [n_left, rep_close, GameState.reputation])
	DayLoop._reset_run()
	ts.set_clock(TimeSystem.CLOSE)
	_check(DayLoop.visitors_arrived == 3 and DayLoop.visitor_waves.is_empty(), "ข้ามไปปิดร้านเลย → รอบ 11:00/14:00 ไม่มา (ไม่หักชื่อเสียง)")
	DayLoop._reset_run()

	# [0.2.5] เนื้อหา: บท 2–12 มีงานเนื้อเรื่อง · งานในคลังกรอกครบ · ทุกเดือนมีงานแต่ละระดับให้เลือกพอ
	var plan_weeks := { }
	for plan in DayLoop.week_plans:
		var fc0: CustomerCase = plan.case_for_shift(1) if plan else null
		if plan and fc0 and fc0.forced and fc0.problems().is_empty():
			plan_weeks[plan.week] = true
	_check(plan_weeks.size() == 12, "บท 1–12 มีงานเนื้อเรื่องวันที่ 1 ครบ (%s)" % [plan_weeks.keys()])
	var bad := PackedStringArray()
	for c in DayLoop.random_pool:
		if c.forced or not c.problems().is_empty():
			bad.append("%s %s" % [c.id, c.problems()])
	_check(DayLoop.random_pool.size() >= 48 and bad.is_empty(), "คลังสุ่ม %d งาน กรอกครบ ไม่มีงานบังคับปน %s" % [DayLoop.random_pool.size(), bad])
	var thin := PackedStringArray()
	for m in range(1, 13):
		for lv in range(1, 6):
			var n := DayLoop.random_pool.filter(func(c: CustomerCase) -> bool: return c.level == lv and c.in_month(m)).size()
			if n < (4 if lv >= 3 else 8):
				thin.append("เดือน %d Lv%d มี %d" % [m, lv, n])
	_check(thin.is_empty(), "ทุกเดือนมีงาน Lv1–2 ≥ 8 · Lv3–5 ≥ 4 ให้สุ่ม %s" % thin)

	# [8 พ.ย.] บทปิ๊บใช้อาการจากใบงานลูกค้า ({symptom|ข้อความเดิม})
	var hc: CustomerCase = load("res://Resources/Customers/w1_d2_headman_mainboard.tres")
	var tpl := "{customer|ลูกค้า}บอกว่า \"{symptom|เล่นเกมไปสักพักแล้วดับเอง}\""
	_check(PartMinigame.fill_case_text(tpl, hc) == "ผู้ใหญ่บ้านบอกว่า \"%s\"" % hc.symptom and PartMinigame.fill_case_text(tpl, null) == "ลูกค้าบอกว่า \"เล่นเกมไปสักพักแล้วดับเอง\"", "บทปิ๊บ: งานลูกค้าใช้อาการจากใบงาน · บทฝึกใช้ข้อความเดิม")
	var leftover := PackedStringArray()
	for f in ["Ram", "Mainboard", "Gpu", "FrontPanel", "Bios"]:
		var dd := PhaseDialogParser.parse("res://Assets/Dialog/MiniGame/%s_Pib.txt" % f)
		for k in dd:
			for t in dd[k]:
				var filled := PartMinigame.fill_case_text(t.dialog, hc)
				if filled.contains("{") or filled.contains("|"):
					leftover.append("%s/%s" % [f, k])
	_check(leftover.is_empty(), "บทปิ๊บ 5 Part ไม่มีตัวแทนค้าง %s" % leftover)

	# บิลรายเดือน [0.2.5] ทุกบท · ค่าเช่า (ม.ค. ฿0 · ก.พ.–เม.ย. ฿300) + ไฟ (ฐาน + 2/เทิร์น) + น้ำ 50 + เน็ต 150
	GameState.debt = 0
	GameState.money = 5000
	var m0 := GameState.money
	var bill := GameState.pay_month_bill(1, 50)
	_check(int(bill["total"]) == 0 + (100 + 100) + 50 + 150 and GameState.money == m0 - int(bill["paid"]) and GameState.debt == 0, "บิล ม.ค. (ทำงาน 50 เทิร์น · ยายไม่เก็บค่าเช่า) = ฿400 (จ่าย %d)" % bill["paid"])
	bill = GameState.pay_month_bill(3, 0)
	_check(int(bill["power"]) == 150 and int(bill["total"]) == 300 + 150 + 50 + 150, "บิล มี.ค. ไฟฐาน 150 (หน้าร้อน) = %d" % bill["total"])
	bill = GameState.pay_month_bill(12, 0)
	_check(int(bill["rent"]) == 500 and int(bill["total"]) == 500 + 100 + 50 + 150, "บิล ธ.ค. ค่าเช่า 500 = %d" % bill["total"])
	GameState.money = 100
	bill = GameState.pay_month_bill(2, 0)
	_check(int(bill["paid"]) == 100 and GameState.money == 0 and GameState.debt == int(bill["total"]) - 100, "เงินไม่พอ → จ่ายเท่าที่มี ส่วนที่ขาดเป็นยอดค้าง (ค้าง %d)" % GameState.debt)
	bill = GameState.pay_month_bill(3, 0)
	_check(int(bill["prev_debt"]) > 0 and int(bill["total"]) == 300 + 150 + 50 + 150 + int(bill["prev_debt"]) + int(bill["late_fee"]) and int(bill["late_fee"]) == ceili(int(bill["prev_debt"]) * 0.1), "ยอดค้างเดิม + ค่าปรับ 10%% รวมในบิลเดือนถัดไป (ปรับ ฿%d)" % bill["late_fee"])
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
	if not _rem_checked:
		# [8 พ.ย.] ปุ่ม "งาน" ระหว่างซ่อม (ReminderLayer ชั้น 11) → การ์ดบอกว่าลูกค้าขออะไร
		_rem_checked = true
		await _frames(2)
		var rem: JobReminder = DayLoop.job_reminder
		_check(rem != null and (rem.get_parent() as CanvasLayer).layer == 11 and rem._btn.visible, "ระหว่างซ่อมมีปุ่ม \"งาน\" เหนือมินิเกม")
		rem.open_card()
		_check(rem.is_open() and rem.card_text().contains(c.customer) and rem.card_text().contains(c.symptom), "กดแล้วเห็นว่าลูกค้าขออะไร (%s)" % rem.card_text().replace("\n", " | "))
		rem.close_card()
	GameState.record_repair(c.part(), score, false, c.fee, c.level)
	SceneRouter.pop()
	Global.in_minigame = false
	EventManager.showUI()
	await _frames(3)


## เอางาน Lv1 ใบแรกออกจากกระดาน (ไม่หักชื่อเสียง) แล้วสุ่มใบใหม่ — ใช้หางาน Lv2 ในสัปดาห์ที่ Lv1 70%
func _swap_job() -> void:
	for i in DayLoop.door_queue.size():
		var c: CustomerCase = DayLoop.door_queue[i]["case"]
		if not (c.level == 2 and c.part_id == "part_ram"):
			DayLoop.door_queue.remove_at(i)
			break
	DayLoop.add_visitors(1)
	DayLoop._board_dirty = true


## [0.3.0] ย้ายลูกค้าคิวที่ i ขึ้นมายืนหน้าประตู (เทสต์เลือกงานที่ต้องการ)
func _to_front(i: int) -> Dictionary:
	var j: Dictionary = DayLoop.door_queue[i]
	DayLoop.door_queue.remove_at(i)
	DayLoop.door_queue.push_front(j)
	DayLoop._board_dirty = true
	return j


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
