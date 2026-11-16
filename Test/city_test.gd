extends Node
## [Claude 16 พ.ย. 2569 · 0.9.5] เมือง — ปลดหลังบท 11 · ใช้ทั้งวัน + ค่ารถ · เดือนละครั้ง · ออฟฟิศ (ตั๋วงานโปรแกรม/ไอทีซัพพอร์ต) · ร้านกาแฟ · กลับบ้าน
## บท 12/ฉากจบอ้างถึงเมือง · เซฟ v11 · ฉาก City.tscn + การ์ดตั๋ว
## เปิด Test/city_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0" · SHOT=<โฟลเดอร์> = เก็บภาพหน้าจอ

var fails := 0
var ts: TimeSystem
var e: EconomyConfig


func _ready() -> void:
	await get_tree().process_frame
	ts = EventManager.time_system
	e = GameState.economy
	var gs := GameState
	var known := DialogUtil.known_speakers()
	DayLoop.day_skip_seconds = 0.0
	DayLoop.tutorials = false
	gs.seed_override = 95
	DayLoop._reset_run()
	DayLoop.quiet = true
	DayLoop.force_active = true
	gs.reset()

	# A · ข้อมูล: ตั๋ว · บท
	var tk := CityBook.tickets()
	var cats := { }
	for t in tk:
		cats[t.category] = int(cats.get(t.category, 0)) + 1
	_check(tk.size() >= 2 * CityBook.PER_TRIP and cats.size() >= CityBook.PER_TRIP, "ตั๋วไอทีซัพพอร์ต %d ใบ %d หมวด (พอไป 2 ครั้งไม่ซ้ำ)" % [tk.size(), cats.size()])
	var bad := PackedStringArray()
	var ids := { }
	for t in tk:
		if t.choices.size() < 3 or t.explain == "" or t.question == "" or t.actions.size() < 2 or t.actions.size() != t.results.size() or t.skill == "" or ids.has(t.id):
			bad.append(String(t.id))
		ids[t.id] = true
	_check(bad.is_empty(), "ตั๋วครบช่อง ไม่ซ้ำ id %s" % ", ".join(bad))
	for f in DirAccess.get_files_at(CityBook.DIALOG_DIR):
		if f.ends_with(".txt"):
			var l := DialogUtil.lint(CityBook.DIALOG_DIR + f, known)
			_check(l.is_empty(), "บทเมือง %s ผ่านตัวตรวจ %s" % [f, str(l)])
	for lean in ["stay", "coworking", "city"]:
		var txt := FileAccess.get_file_as_string(CityBook.DIALOG_DIR + "office_%s.txt" % lean)
		_check(txt.contains("Choice: " + CityBook.TRY_OFFICE + ","), "office_%s ตัวเลือกแรก = ลองงาน" % lean)
	_check(DialogUtil.lint("res://Assets/Dialog/Chapter11Path.txt", known).is_empty(), "บท 11 (เพิ่มชวนไปออฟฟิศ) ผ่านตัวตรวจ")
	_check(Global.hasCharacter("พี่แนน"), "พี่แนนมีรูป (ชั่วคราว)")

	# B · ล็อกจนจบบทต้นเดือนบท 11
	ts.set_shift(41)
	DayLoop.reseed_day()
	_check(ts.month() == 11, "วันที่ 41 = เดือน 11")
	_check(DayLoop.city_state() == &"locked" and DayLoop.city_state_text(&"locked") == "ขมยังไม่พร้อมกลับไป", "ก่อนบท 11 = ล็อก (ขมยังไม่พร้อมกลับไป)")
	gs._on_chapter_done(11)
	DayLoop.forced_case = DayLoop.random_pool[0]
	_check(DayLoop.city_state() == &"busy", "มีลูกค้าเนื้อเรื่องรอซ่อม → ต้องซ่อมก่อน")
	DayLoop.forced_case = null
	ts.set_shift(42)
	DayLoop.reseed_day()
	_check(DayLoop.city_unlocked() and DayLoop.city_state() == &"ok", "จบบทต้นเดือนบท 11 → ไปได้ (%s f=%s w=%s r=%s)" % [DayLoop.city_state(), DayLoop.forced_case, DayLoop._working, DayLoop._result_pending])
	MapPanel.show()
	await _frames(2)
	var card: MapCard = MapPanel.card_for(SceneRouter.CITY)
	_check(card != null and not card.locked and card.location == SceneRouter.CITY, "การ์ดเมืองในแผนที่ปลด (ไปฉาก CITY)")
	MapPanel._on_card_pressed(card)
	var conf: Control = MapPanel.get_node_or_null(^"Root/CityConfirm")
	_check(conf != null and conf.visible and MapPanel.visible and MapPanel._confirm_text.text.contains("฿%d" % e.city_fare), "กดเมือง → ถามยืนยัน (ค่ารถ · ร้านปิดทั้งวัน)")
	await _shot("confirm")
	MapPanel.hide()

	# C · ไปเมือง: ค่ารถ · ลูกค้าวันนี้ไม่มา · คนนัดเลื่อน
	DayLoop._plan_visitors(ts)
	DayLoop.add_visitors(2)
	var walkins := DayLoop.door_queue.size()
	var appt_case: CustomerCase = DayLoop.random_pool[0]
	DayLoop.door_queue.append(DayLoop.door_entry(appt_case, false, true))
	var m0 := gs.money
	var rep0 := gs.reputation
	_check(DayLoop.city_trip(), "ไปเมืองได้ (มีลูกค้ารอ %d คน)" % walkins)
	_check(gs.money == m0 - e.city_fare and gs.ledger.back().kind == &"city", "หักค่ารถ ฿%d (หมวดเข้าเมือง)" % e.city_fare)
	_check(DayLoop.door_queue.is_empty() and DayLoop.visitor_waves.is_empty() and gs.reputation == rep0, "ลูกค้าวันนี้ไม่มา ไม่เสียชื่อเสียง")
	_check(DayLoop.appointments.any(func(a: Dictionary) -> bool: return a.case == appt_case), "คนที่นัดเลื่อนเป็นรอบหน้า")
	_check(DayLoop.city_today() and DayLoop.city_state() == &"here" and ts.current_minute == e.city_arrive_minute, "ถึงเมือง %s" % TimeSystem.clock_text(ts.current_minute))
	_check(not DayLoop.city_trip(), "ไปซ้ำวันเดียวกันไม่ได้")

	# D · ออฟฟิศ: ตั๋วไอทีซัพพอร์ต 3 ใบคนละหมวด · กดตรวจ → จอพิมพ์ผล · ค่าแรงตามที่ปิดได้
	_check(DayLoop.city_office_can(), "ลองงานได้")
	var list := DayLoop.city_office_begin()
	var lcats := { }
	for t in list:
		lcats[t.category] = true
	_check(list.size() == 3 and lcats.size() == 3, "ตั๋ว 3 ใบ คนละหมวด")
	var v := DayLoop.city_ticket_view()
	_check((v.actions as Array).size() >= 2 and (v.choices as Array).has(list[0].choices[0]) and int(v.steps) == 3 and String(v.kind) == list[0].category_name(), "ตั๋วแรกมีปุ่มตรวจ + ตัวเลือก (สลับแล้ว)")
	_check(DayLoop.city_ticket_check(0) == list[0].results[0] and DayLoop.city_ticket_check(9) == "" and (DayLoop.office_state.checked as Array) == [0], "กดตรวจ → ได้ผลของปุ่มนั้น (จดว่าตรวจอะไร)")
	var r := DayLoop.city_ticket_answer(list[0].choices[1])
	_check(not r.correct and String(r.answer) == list[0].choices[0] and r.more, "ตอบผิด → เฉลย + มีตั๋วต่อ")
	_check(DayLoop.city_ticket_answer(list[0].choices[0]).is_empty() and DayLoop.city_ticket_check(1) == "", "ตอบแล้วตรวจ/ตอบซ้ำไม่ได้")
	for i in range(1, 3):
		DayLoop.city_ticket_next()
		_check((DayLoop.office_state.checked as Array).is_empty(), "ตั๋วใหม่เริ่มยังไม่ได้ตรวจ")
		DayLoop.city_ticket_answer(list[i].choices[0])
	_check(not DayLoop.city_ticket_next(), "ครบ 3 ใบ")
	var m1 := gs.money
	var t1 := ts.current_minute
	var res := DayLoop.city_office_finish()
	_check(int(res.right) == 2 and int(res.pay) == 2 * e.city_ticket_pay and gs.money == m1 + 2 * e.city_ticket_pay, "ปิดได้ 2/3 → ฿%d (ไม่มีโบนัส)" % int(res.get("pay", 0)))
	_check(ts.current_minute > t1 and ts.current_minute < TimeSystem.CLOSE, "ลองงานใช้เวลา")
	_check(not DayLoop.city_office_can() and gs.city.tried_office and (gs.city.seen_tickets as Array).size() == 3, "วันนี้ลองงานแล้ว · จำตั๋วที่ทำ")
	var df := CityBook.office_done_file(2, 3, int(res.pay))
	_check(DialogUtil.lint(df, known).is_empty() and FileAccess.get_file_as_string(df).contains("2 จาก 3"), "บทหลังลองงาน (ตัวเลขจริง) ผ่านตัวตรวจ")

	# E · ร้านกาแฟ
	var m2 := gs.money
	_check(DayLoop.city_cafe("จัดเวลายังไงไม่ให้งานล้น") and gs.city.met_cowork and gs.money == m2 - e.city_coffee, "ร้านกาแฟ: เจอพี่แนน · ค่ากาแฟ")
	_check(not DayLoop.city_cafe() and CityBook.cafe_dialog().ends_with("cafe_again.txt"), "วันละครั้ง · ครั้งหน้าใช้บทเจอซ้ำ")

	# F · กลับบ้าน = ปิดร้านวันนั้น
	_check(DayLoop.city_return() and ts.current_minute == TimeSystem.CLOSE, "กลับบ้าน → 18:30")
	_check(not DayLoop.city_return(), "กลับซ้ำไม่ได้")
	_check(DayLoop.city_state() == &"here", "วันเดียวกันยังนับว่าไปแล้ว")
	ts.set_shift(43)
	DayLoop.reseed_day()
	_check(DayLoop.city_state() == &"used", "เดือนเดียวกัน = ไปแล้ว (เดือนละครั้ง)")

	# G · บท 12 อ้างถึงเมือง
	var ch12: String = gs.chapter_story(12).file
	var t12 := FileAccess.get_file_as_string(ch12)
	_check(ch12 != CityBook.CH12_FILE and DialogUtil.lint(ch12, known).is_empty() and t12.contains("ปิดตั๋วได้ 2 จาก 3") and t12.contains("พี่แนน"), "บท 12 แทรกเรื่องเมือง + ผ่านตัวตรวจ")
	_check(t12.find("ปิดตั๋วได้") < t12.find(CityBook.CH12_MARK), "แทรกก่อนยายถามเรื่องบริษัท")

	# H · เดือน 12 ไปได้อีกครั้ง ตั๋วไม่ซ้ำ · ข้อจำกัดเวลา/วันสุดท้าย
	ts.set_shift(46)
	DayLoop.reseed_day()
	ts.set_clock(12 * 60 + 30)
	_check(DayLoop.city_state() == &"late", "หลังเที่ยง = รถเที่ยวสุดท้ายไปแล้ว")
	ts.set_clock(TimeSystem.OPEN)
	_check(DayLoop.city_trip(), "เดือน 12 ไปได้อีกครั้ง")
	var seen: Array = (gs.city.seen_tickets as Array).duplicate()
	var r2 := DayLoop.city_office_auto(1.0, RandomNumberGenerator.new())
	var fresh := true
	for id in (gs.city.seen_tickets as Array).slice(3):
		fresh = fresh and not seen.has(id)
	_check(fresh and int(r2.pay) == 3 * e.city_ticket_pay + e.city_full_bonus, "ครั้งที่ 2 ตั๋วใหม่ทั้งหมด · ปิดครบ = โบนัส (฿%d)" % int(r2.get("pay", 0)))
	_check(int(gs.city.visits) == 2 and int(gs.city.office_right) == 5 and int(gs.city.office_total) == 6, "สะสม 2 ครั้ง 5/6")
	DayLoop.city_return()
	ts.set_shift(TimeSystem.TOTAL_SHIFTS)
	gs.city.months = [11]
	_check(DayLoop.city_state() == &"last_day", "วันสุดท้ายของปีไปไม่ได้")
	gs.city.months = [11, 12]

	# I · ฉากจบอ้างถึงเมือง · ภาพเมือง
	gs.story_flags["ch11_choice"] = "coworking"
	_check(Array(EndingBook.lines_for(&"coworking")).any(func(l: String) -> bool: return l.contains("พี่แนน")), "ฉากจบ coworking อ้างถึงพี่แนน")
	_check(Array(EndingBook.lines_for(&"city")).any(func(l: String) -> bool: return l.contains("ลองปิดตั๋ว")), "ฉากจบ city อ้างถึงการลองงาน")
	_check(Array(EndingBook.lines_for(&"stay")).any(func(l: String) -> bool: return l.contains("ไปดูเมืองมาแล้ว")), "ฉากจบ stay อ้างถึงการไปเมือง")
	_check(EndingBook.bg(&"city").ends_with("bg_city_day.jpg") and ResourceLoader.exists(EndingBook.bg(&"city")), "ฉากจบ city ใช้ภาพเมือง")
	_check(DialogUtil.lint(EndingBook.build(&"coworking"), known).is_empty(), "บทฉากจบ (มีเรื่องเมือง) ผ่านตัวตรวจ")

	# J · เซฟ v11
	SaveGame.allow_in_tests = true
	var backup := FileAccess.get_file_as_string(SaveGame.PATH) if FileAccess.file_exists(SaveGame.PATH) else ""
	var snap: Dictionary = gs.city.duplicate(true)
	_check(SaveGame.save(), "เซฟได้")
	gs.reset()
	_check(int(gs.city.visits) == 0, "reset ล้างเมือง")
	SaveGame.load_into()
	_check(int(gs.city.visits) == 2 and (gs.city.months as Array).has(11) and (gs.city.months as Array).has(12) and int(gs.city.office_right) == int(snap.office_right) and bool(gs.city.met_cowork), "โหลด → เมืองกลับมาครบ (เดือนเป็น int)")
	_check(SaveGame.VERSION == 11, "เซฟ VERSION 11")
	if backup != "":
		var f := FileAccess.open(SaveGame.PATH, FileAccess.WRITE)
		f.store_string(backup)
		f.close()
	else:
		SaveGame.clear()
	SaveGame.allow_in_tests = false

	# J2 · playlog/city.csv
	Playlog.allow_in_tests = true
	DayLoop.quiet = false
	var cp := Playlog.DIR.path_join("city.csv")
	var before := FileAccess.get_file_as_string(cp).split("\n").size() if FileAccess.file_exists(cp) else 0
	DayLoop.city_log(&"test", "ทดสอบ, มีจุลภาค", 1, 2, 3)
	var lines := FileAccess.get_file_as_string(cp).split("\n")
	_check(lines[0].begins_with("time,game_version,event,month,day,lean,detail") and lines.size() > before and not lines[lines.size() - 2].contains("ทดสอบ,"), "playlog/city.csv มีหัวตาราง + แถวใหม่ (ตัด , ในรายละเอียด)")
	DayLoop.quiet = true
	Playlog.allow_in_tests = false

	# K · ฉาก City.tscn + การ์ดตั๋ว
	gs.reset()
	gs.story_flags["city_open"] = true
	DayLoop.forced_case = null
	ts.set_shift(42)
	DayLoop.reseed_day()
	ts.set_clock(TimeSystem.OPEN)
	DayLoop.city_trip()
	var city: Control = load("res://Scene/Location/City.tscn").instantiate()
	add_child(city)
	await _frames(3)
	_check(city.get_node("Office") is SceneHotspot and city.get_node("StallParts") is MarketStall and city.get_node("Cafe") is SceneHotspot and city.get_node("Van") is SceneHotspot, "ฉากเมือง: ออฟฟิศ · ร้านอะไหล่ · ร้านกาแฟ · รถตู้")
	var stall: MarketStall = city.get_node("StallParts")
	var ids2: Array = stall.items.map(func(it: ShopItem) -> String: return String(it.resource_path.get_file()))
	_check(ids2.has("gpu_used.tres") and ids2.has("mb_used.tres"), "ร้านอะไหล่ในเมืองมีการ์ดจอ/เมนบอร์ด (ตลาดไม่มี)")
	_check(DialogScene.visible, "ถึงเมือง → บทแรก")
	await _shot("arrive")
	DialogScene.dialog_end()
	await _frames(2)
	await _shot("city")
	_check(city.start_office() and city.card.visible and city.card._checks.get_child_count() >= 2 and not city.card._fix.visible and not city.card._fix_box.visible, "เปิดการ์ดตั๋ว: ปุ่มตรวจ · ยังไม่มีปุ่มลงมือแก้")
	await _frames(2)
	await _shot("ticket")
	var first: OfficeTicket = DayLoop.office_state.tickets[0]
	(city.card._checks.get_child(0) as Button).pressed.emit()
	await get_tree().create_timer(1.4).timeout
	_check(city.card._term.text == first.results[0] and city.card._term.visible_ratio >= 1.0 and city.card._fix.visible, "กดตรวจ → จอพิมพ์ผลจนครบ + ปุ่มลงมือแก้ขึ้น")
	await _shot("check")
	city.card._fix.pressed.emit()
	await _frames(2)
	_check(city.card._fix_box.visible and not city.card._checks.visible and city.card._choices.columns == 2, "ลงมือแก้ → ตัวเลือก 2 คอลัมน์")
	var wrong_btn: Button = null
	for b in city.card._choices.get_children():
		if (b as Button).text == first.choices[1]:
			wrong_btn = b
	wrong_btn.pressed.emit() # กดตัวผิด → ดูสีหลังตอบ
	await _frames(2)
	var marks: Array = city.card._choices.get_children().map(func(b: Button) -> String: return b.text.left(2))
	_check(city.card._feedback.visible and city.card._action.text == "ตั๋วถัดไป ►", "ตอบแล้วขึ้นคำอธิบาย")
	_check(marks.count("✓ ") == 1 and marks.count("✗ ") == 1, "หลังตอบ: ถูก ✓ เขียว · ที่เลือกผิด ✗ แดง %s" % [marks])
	await _shot("answer")
	for i in 2:
		city.card.done.emit()
		var tt: OfficeTicket = DayLoop.office_state.tickets[int(DayLoop.office_state.step)]
		city.card.picked.emit(tt.choices[0])
	_check(city.card._action.text == "ส่งงานให้หัวหน้า", "ใบสุดท้าย → ส่งงาน")
	city.card.done.emit()
	await _frames(2)
	_check(not city.card.visible and gs.city.tried_office and DialogScene.visible, "ส่งงาน → บทหลังลองงาน")
	DialogScene.dialog_end()
	city.queue_free()
	DayLoop.city_return()

	gs.reset()
	DayLoop.quiet = false
	DayLoop.force_active = false
	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _shot(n: String) -> void:
	if OS.get_environment("SHOT") == "":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_jpg(OS.get_environment("SHOT") + "/city_%s.jpg" % n, 0.85)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL ", msg)
	else:
		print("ok   ", msg)
