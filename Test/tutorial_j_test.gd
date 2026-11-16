extends Node
## [Claude 15 พ.ย. 2569 · 0.3.0 ขั้น J] บทสอนครั้งแรก (หน้าประตู · ชั้นวาง · มารับเครื่อง) + ปุ่ม "งาน" อ่านใบรับเครื่อง
## เปิด Test/tutorial_j_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0


func _ready() -> void:
	await get_tree().process_frame
	var ts: TimeSystem = EventManager.time_system
	DayLoop.day_skip_seconds = 0.0
	DayLoop._reset_run()
	DayLoop._break_done = true
	DayLoop.forced_case = null
	DayLoop.door_queue.clear()
	DayLoop.visitor_waves.clear()
	ts.set_clock(9 * 60)
	var ram: CustomerCase = load("res://Resources/Customers/lv2_teacher_ram.tres")
	_check(GameState.story_flags.is_empty(), "เกมใหม่ยังไม่มี flag บทสอน")
	for f in DayLoop.TUTORIALS:
		_check(FileAccess.file_exists(DayLoop.TUTORIALS[f]) and DialogUtil.speakers_in(DayLoop.TUTORIALS[f]).size() > 0, "ไฟล์บท %s มีอยู่ · มีผู้พูด" % f)
		for who in DialogUtil.speakers_in(DayLoop.TUTORIALS[f]):
			_check(Global._CharacterMap.has(who), "  ผู้พูด \"%s\" อยู่ใน _CharacterMap" % who)

	# นอกร้าน → ไม่ขึ้น
	DayLoop.door_queue.append(DayLoop.door_entry(ram))
	_check(not DayLoop._maybe_tutorial(DayLoop.Card.DOOR), "นอกร้าน: ไม่ขึ้นบทสอน")
	SceneRouter.current_id = SceneRouter.ROOM
	DayLoop.tutorials = false
	_check(not DayLoop._maybe_tutorial(DayLoop.Card.DOOR), "tutorials = false: ไม่ขึ้น")
	DayLoop.tutorials = true
	_check(DayLoop._maybe_tutorial(DayLoop.Card.DOOR) and GameState.story_flags.get("tut_door", false), "ลูกค้าหน้าประตูคนแรก → บทสอนหน้าประตู (ตั้ง flag)")
	await _end_dialog()
	_check(not DayLoop._maybe_tutorial(DayLoop.Card.DOOR), "ครั้งที่ 2 ไม่ขึ้นซ้ำ")
	# เครื่องขึ้นชั้น → บทชั้นวาง
	var o := DayLoop.shelf.add(ram, ts.shift, 1)
	_check(DayLoop._maybe_tutorial(DayLoop.Card.DOOR) and GameState.story_flags.get("tut_shelf", false), "มีเครื่องบนชั้นครั้งแรก → บทสอนชั้นวาง")
	await _end_dialog()
	# ลูกค้ามารับ → บทมารับเครื่อง
	DayLoop.door_queue.clear()
	DayLoop.door_queue.append(DayLoop.pickup_entry({ "order": o, "late": 0, "mult": 1.0, "sat_delta": 0, "on_time": true })) # [0.7.0] ใช้รูปแบบจริง (เดิมไม่มีคีย์ pickup → SCRIPT ERROR ใน _part_tutorials)
	_check(DayLoop._maybe_tutorial(DayLoop.Card.DOOR) and GameState.story_flags.get("tut_pickup", false), "ลูกค้ามารับเครื่องครั้งแรก → บทสอนมารับ")
	await _end_dialog()
	_check(not DayLoop._maybe_tutorial(DayLoop.Card.DOOR) and not DayLoop._maybe_tutorial(DayLoop.Card.NONE), "ครบ 3 บทแล้ว ไม่ขึ้นอีก")
	# เซฟ/โหลด flag ผ่าน JSON (คีย์เป็น String)
	var back: Dictionary = JSON.parse_string(JSON.stringify(GameState.story_flags))
	_check(back.get("tut_door", false) and back.get("tut_shelf", false) and back.get("tut_pickup", false), "flag บทสอนเข้าเซฟได้ (JSON)")
	DayLoop.door_queue.clear()

	# ปุ่ม "งาน": บรรทัดใบรับเครื่อง
	var jr: JobReminder = load("res://Scene/UI/job_reminder.tscn").instantiate()
	add_child(jr)
	DayLoop.current_job = { "case": ram, "order": o }
	var line := jr._work_order_line()
	_check(line.begins_with("ใบรับเครื่อง: นัดรับ") and line.contains("฿") and line.contains("ได้ตอนลูกค้ามารับ"), "ปุ่มงาน: %s" % line)
	o.due = ts.shift - 1
	_check(jr._work_order_line().contains("เลยนัดมา 1 วัน"), "เลยนัด → บอกว่าเลยมากี่วัน")
	DayLoop.current_job = { "case": ram }
	_check(jr._work_order_line() == "", "งานหน้าร้าน (ไม่มีใบรับเครื่อง) → ไม่มีบรรทัดนี้")
	jr.queue_free()
	SceneRouter.current_id = SceneRouter.HOME
	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _end_dialog() -> void:
	await _frames(2)
	if DialogScene.visible:
		DialogScene.dialog_end()
	await _frames(3)
	_check(not DayLoop._working, "  จบบท → ปลดล็อก")


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
