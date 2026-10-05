extends Node
## [Claude 5 ต.ค. 2569] ทดสอบลูป Week 1 (DayLoop + WeekPlan + CustomerCase + TimeSystem + GameState) แบบไม่ต้องเล่นมินิเกม
## เปิด Test/loop_test.tscn แล้วกด Run Current Scene (F6) · ดูผลใน Output (บรรทัดขึ้นต้นด้วย "T ")
## มินิเกมจะถูกเปิดจริงแล้วปิดทันที แทนด้วยคะแนนสมมติ

const SCORES := [96, 85, 70, 40, 90, 82, 88]
var fails := 0


func _ready() -> void:
	# ย้ายตัวเองไปไว้ใต้ root เพื่ออยู่รอดตอนเปลี่ยนซีนไปห้องขม (DayLoop แสดงการ์ดเฉพาะบ้าน/ห้อง)
	await get_tree().process_frame
	var root := get_tree().root
	get_parent().remove_child(self)
	root.add_child(self)
	var ts: TimeSystem = EventManager.time_system

	# งานซ่อมในเควสต์ (ไม่มี meta work_order) ต้องไม่คิดเงิน
	var m0: PartMinigame = load("res://Scene/MiniGame/PartRam/part_ram.tscn").instantiate()
	var money0 := GameState.money
	add_child(m0)
	await _frames(1)
	m0._report_repair()
	m0.queue_free()
	await _frames(1)
	EventManager.showUI()
	_check(GameState.money == money0, "งานในเควสต์ไม่คิดเงิน")
	Global.in_minigame = false

	# ปุ่มข้าม: Tutorial ประกอบคอม (กด 2 ครั้ง) · สไลด์
	var ta: PartMinigame = load("res://Scene/MiniGame/TutorialAssembly/tutorial_assembly.tscn").instantiate()
	add_child(ta)
	await _frames(2)
	_check(ta._skip_btn != null and ta._skip_btn.is_visible_in_tree(), "Tutorial ประกอบคอมมีปุ่มข้าม")
	ta._on_skip_pressed()
	_check(is_instance_valid(ta) and ta.is_inside_tree(), "กดข้ามครั้งแรก = ถามยืนยัน (ยังไม่ปิด)")
	ta._on_skip_pressed()
	await _frames(2)
	_check(not is_instance_valid(ta) or not ta.is_inside_tree(), "กดข้ามครั้งที่สอง = ปิดมินิเกม")
	var cust: PartMinigame = load("res://Scene/MiniGame/PartRam/part_ram.tscn").instantiate()
	cust.set_meta("work_order", true)
	add_child(cust)
	await _frames(2)
	_check(cust._skip_btn == null, "งานลูกค้าไม่มีปุ่มข้าม")
	cust.queue_free()
	await _frames(2)
	EventManager.tutorial.show_tutorial(Tutorial.TutorialState.RAM_CLEANING)
	await _frames(1)
	EventManager.tutorial.skip()
	_check(not EventManager.tutorial.visible, "สไลด์ Tutorial กดข้ามได้")
	Global.in_minigame = false
	EventManager.showUI()

	DayLoop.force_active = true
	get_tree().change_scene_to_file(Constant.ROOM_SCENE)
	await _frames(5)
	print("T start money=", GameState.money, " ", ts.dateText.get_parsed_text())
	for d in 7:
		await _frames(2)
		var c: CustomerCase = DayLoop.today_case
		_check(c.problems().is_empty(), "day %d ข้อมูลลูกค้าครบ %s" % [d + 1, c.problems()])
		_check(c != null and c.reason != "", "day %d ลูกค้ามีเหตุผล: %s — %s" % [d + 1, c.customer, c.reason])
		if c.forced:
			_check(DayLoop._break_done and not DayLoop.arrived_today, "day %d event บังคับ (เริ่มด้วยบทพัก ยังไม่ให้ลูกค้าเข้า)" % (d + 1))
			# พักหลัง Tutorial → เวลาหมุน 30 นาทีใน 1 วิ
			await _frames(2)
			_check(DialogScene.visible and DialogScene.DialogDict.get("dialog", []).size() == 6, "day %d บทพักหลัง Tutorial" % (d + 1))
			var before := ts.current_minute
			DialogScene.dialog_end()
			await _frames(3)
			_check(DayLoop._skip_overlay.visible, "day %d จอเวลาหมุน" % (d + 1))
			await get_tree().create_timer(DayLoop.time_skip_seconds + 0.6).timeout
			_check(ts.current_minute == before + DayLoop.break_minutes and not DayLoop._skip_overlay.visible,
				"day %d เวลา %s → %s" % [d + 1, TimeSystem.clock_text(before), TimeSystem.clock_text(ts.current_minute)])
			await get_tree().create_timer(DayLoop.forced_delay + 0.3).timeout
			_check(DialogScene.visible and DialogScene.DialogDict.get("dialog", []).size() > 0, "day %d บทลูกค้าเล่นเอง" % (d + 1))
			DialogScene.dialog_end()
			await _frames(3)
			_check(DayLoop._card == DayLoop.Card.JOB_FORCED and not DayLoop._secondary.visible, "day %d การ์ดเริ่มซ่อม (ไม่มีปุ่มปิดร้าน)" % (d + 1))
			DayLoop._on_primary()
		else:
			_check(DayLoop._card == DayLoop.Card.JOB, "day %d การ์ดลูกค้า" % (d + 1))
			DayLoop._on_primary()   # รับงาน → บทลูกค้า
			await _frames(2)
			_check(DialogScene.visible and DialogScene.DialogDict.get("dialog", []).size() > 0, "day %d บทลูกค้า" % (d + 1))
			DialogScene.dialog_end()   # เหมือนกดข้ามบทจนจบ
		await _frames(3)
		var mg: Node = null
		for n in get_tree().current_scene.get_children():
			if n is PartMinigame:
				mg = n
		_check(mg != null and mg.get_meta("work_order", null) == c, "day %d เปิดมินิเกม %s" % [d + 1, c.part_id])
		if mg:
			mg.queue_free()
		await _frames(2)
		Global.in_minigame = false
		EventManager.showUI()
		GameState.record_repair(c.part(), SCORES[d], d == 3, c.fee)
		await _frames(2)
		_check(DayLoop._card == DayLoop.Card.RESULT, "day %d การ์ดผลงาน" % (d + 1))
		print("T   ", DayLoop._body.text.replace("\n", " | "))
		DayLoop._on_primary()   # ปิดร้าน → เย็น
		await _frames(2)
		_check(DayLoop._card == DayLoop.Card.EVENING, "day %d ช่วงเย็น" % (d + 1))
		DayLoop._on_primary()   # นอน
		await _frames(2)
	_check(DayLoop._card == DayLoop.Card.WEEK_SUMMARY, "การ์ดสรุปรอบ")
	print("T summary: ", DayLoop._body.text.replace("\n", " | "))
	DayLoop._on_primary()
	await _frames(2)
	_check(DialogScene.visible, "บท Chapter 2 หลังจบรอบ 1")
	print("T after week: ", ts.dateText.get_parsed_text(), " ลูกค้ารอบ 2 วันที่ 1 (สุ่ม)=", DayLoop.today_case.id)
	print("T DONE fails=", fails)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
