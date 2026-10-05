extends Node
## [Claude 5 ต.ค. 2569] ทดสอบตัวดัก error ของโค้ดลูปร้าน / QTE / Tutorial — ป้อนค่าผิด ๆ แล้วต้องไม่ crash ไม่ค้าง
## เปิด Test/guard_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0" (warning สีเหลืองระหว่างทางเป็นเรื่องปกติ)

var fails := 0
var _finished_count := 0


func _ready() -> void:
	await get_tree().process_frame
	var root := get_tree().root
	get_parent().remove_child(self)
	root.add_child(self)
	var ts: TimeSystem = EventManager.time_system

	# --- บทพูด
	_check(not EventManager.play_story_dialog("x", "res://ไม่มีไฟล์นี้.txt", ""), "บทหาย → play_story_dialog คืน false")
	var empty := "user://empty_dialog.txt"
	var f := FileAccess.open(empty, FileAccess.WRITE)
	f.store_line("# มีแต่คอมเมนต์")
	f.close()
	_check(not EventManager.play_story_dialog("x", empty, ""), "บทว่าง → คืน false (ไม่เปิด DialogScene)")
	_check(not DialogScene.visible, "DialogScene ไม่ถูกเปิด")
	_check(EventManager.play_story_dialog("x", "res://Assets/Dialog/Break/after_tutorial.txt", "res://ไม่มีรูป.jpg"), "ฉากหลังหาย → ยังเปิดบทได้")
	_check(not EventManager.play_story_dialog("y", "res://Assets/Dialog/Break/after_tutorial.txt", ""), "เปิดบทซ้อน → คืน false")
	DialogScene.dialog_end()
	await _frames(2)

	# --- เวลา
	ts.call("set_period", 99)   # ค่าที่ไม่มีใน enum
	_check(ts.cur_period != 99, "set_period ค่าผิด → ไม่เปลี่ยน")
	_check(TimeSystem.clock_text(-50) == "00:00" and TimeSystem.clock_text(99999) == "23:59", "clock_text ค่าเกิน → clamp")
	ts.set_clock(-10)
	_check(ts.current_minute == 0, "set_clock ติดลบ → 00:00")
	ts.set_date(1, 1)
	var m0 := ts.current_minute
	await DayLoop.time_skip(0)
	_check(ts.current_minute == m0, "time_skip 0 นาที → ไม่ทำอะไร")
	DayLoop.time_skip(30, 0.3)
	DayLoop.time_skip(30, 0.3)   # ซ้อน → ต้องถูกข้าม
	await get_tree().create_timer(1.0).timeout
	_check(ts.current_minute == m0 + 30, "time_skip ซ้อนกัน → เดินแค่ครั้งเดียว (%s)" % TimeSystem.clock_text(ts.current_minute))

	# --- เงิน
	var money0 := GameState.money
	var r := GameState.record_repair(&"part_ไม่มีจริง", 150)
	_check(r["score"] == 100 and GameState.money == money0 + GameState.economy.default_fee + GameState.economy.tip_three_star, "คะแนนเกิน 100 → clamp · Part ไม่รู้จัก → ค่าซ่อม default")
	DayLoop.job_done_today = false

	# --- ลูกค้ากรอกไม่ครบ
	var bad := CustomerCase.new()
	bad.customer = "คนที่ไม่มีในเกม"
	bad.arrive_dialog = "res://Assets/Dialog/Customer/ไม่มีไฟล์.txt"
	bad.fee = -5
	var probs := bad.problems()
	_check(probs.size() >= 6, "CustomerCase ว่าง → เตือน %d ข้อ: %s" % [probs.size(), " / ".join(probs)])

	# --- มินิเกม: จบซ้ำ · ข้ามงานลูกค้า
	var ram: PartMinigame = load("res://Scene/MiniGame/PartRam/part_ram.tscn").instantiate()
	ram.set_meta("work_order", load("res://Resources/Customers/w1_d6_girl_ram.tres"))
	add_child(ram)
	await _frames(2)
	ram.minigame_finished.connect(func(_s: Dictionary) -> void: _finished_count += 1)
	ram.skip()
	_check(_finished_count == 0, "งานลูกค้าเรียก skip() → ไม่ยอม")
	var jobs1 := GameState.satisfaction_history.size()
	ram._finish(true)
	ram._finish(true)
	ram._advance_phase()
	await _frames(2)
	_check(_finished_count == 1, "minigame_finished ส่งครั้งเดียว (ได้ %d)" % _finished_count)
	_check(GameState.satisfaction_history.size() == jobs1 + 1, "บันทึกผลงานครั้งเดียว (ได้ %d)" % (GameState.satisfaction_history.size() - jobs1))
	_check(not Global.in_minigame, "มินิเกมปิดแล้ว in_minigame = false")
	DayLoop.job_done_today = false

	# --- QTE
	var q := QteRunner.new()
	_check(await q.run(QteSpec.new()) == QteRunner.Result.MISS, "QTE runner ไม่อยู่ใน tree → MISS ไม่ crash")
	q.free()
	var layer := CanvasLayer.new()
	add_child(layer)
	q = QteRunner.new()
	layer.add_child(q)
	await _frames(1)
	var weird := QteSpec.new()
	weird.zone = Vector2(0.7, 0.3)
	weird.perfect = Vector2(0.9, 0.95)
	weird.duration = 0.0
	_check(weird.problems().size() >= 2, "QteSpec ค่าผิด → problems() เตือน")
	QteRunner.auto_result = 7
	_check(await q.run(weird) == QteRunner.Result.MISS, "auto_result เกินช่วง → clamp เป็น MISS")
	QteRunner.auto_result = -1
	var rs := QteSpec.new()
	rs.kind = QteSpec.Kind.RING
	_check(await q.run(rs) == QteRunner.Result.GOOD, "QTE แบบที่ยังไม่ทำ → GOOD ไม่ค้าง")
	var task := {"done": false}
	var go := func() -> void:
		await q.run(weird)
		task["done"] = true
	go.call()
	await _frames(2)
	_check(q._zone.x <= q._zone.y and q._perfect.x >= q._zone.x and q._perfect.y <= q._zone.y, "โซนกลับด้าน → runner สลับ + บีบ PERFECT เข้าโซน")
	q.cancel()
	await _frames(1)
	_check(task["done"] and not q.running, "cancel() → run จบ ไม่ค้าง")

	# --- watchdog: _working ค้างโดยไม่มีบท/มินิเกม
	DayLoop._working = true
	await get_tree().create_timer(DayLoop.STUCK_LIMIT + 0.5).timeout
	_check(not DayLoop._working, "watchdog ปลด _working ที่ค้าง")

	# --- ลูกค้าไม่มีบท → ไปมินิเกมเลย ไม่ค้าง
	get_tree().change_scene_to_file(Constant.ROOM_SCENE)
	await _frames(5)
	var nodlg: CustomerCase = load("res://Resources/Customers/w1_d2_headman_mainboard.tres").duplicate()
	nodlg.arrive_dialog = ""
	DayLoop.today_case = nodlg
	DayLoop.play_arrival(true)
	await _frames(3)
	var opened := false
	for n in get_tree().current_scene.get_children():
		if n is PartMinigame:
			opened = true
			n.queue_free()
	_check(opened and not DialogScene.visible, "ลูกค้าไม่มีบท → เปิดมินิเกมเลย")
	await _frames(3)
	_check(not DayLoop._working and not Global.in_minigame, "ปิดมินิเกมแล้วปลดล็อกการ์ด")
	nodlg.part_id = "part_ram"
	nodlg.scene_override = "res://ไม่มีซีน.tscn"
	DayLoop.start_repair()
	_check(not DayLoop._working, "มินิเกมโหลดไม่ได้ → ไม่ค้าง")

	print("T DONE fails=", fails)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
