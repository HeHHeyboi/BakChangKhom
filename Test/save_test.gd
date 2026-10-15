extends Node
## [Claude 10 ต.ค. 2569] ระบบบันทึก: บันทึก → เปลี่ยนค่า → โหลดกลับครบ · เมนูหลักมีปุ่มเล่นต่อ · เริ่มใหม่ลบเซฟ
## เปิด Test/save_test.tscn → F6 → "T DONE fails=0"

var fails := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	SaveGame.allow_in_tests = true
	var backup := FileAccess.get_file_as_string(SaveGame.PATH) if SaveGame.exists() else ""
	SaveGame.clear()
	_check(not SaveGame.exists() and SaveGame.info().is_empty(), "ไม่มีเซฟ")
	Global.on_start = false
	var ts: TimeSystem = EventManager.time_system
	ts.set_shift(4)
	GameState.money = 1234
	GameState.xp = 77
	GameState.reputation = 33
	GameState.level_stars[1] = 2
	DayLoop.board.clear()
	var cc: CustomerCase = load("res://Resources/Customers/lv1_girl_wifi.tres")
	DayLoop.board.append({ "case": cc, "due_shift": 5, "phone": true })
	EventManager.jump_event(EventManager.EventID.MAIN, 1)
	SceneRouter.current_id = SceneRouter.VILLAGE
	_check(SaveGame.save() and SaveGame.exists(), "บันทึกได้")
	_check(SaveGame.info() == { "shift": 4, "money": 1234 }, "ข้อมูลย่อ: วันที่ 4 · ฿1234 (%s)" % SaveGame.info())

	# เปลี่ยนทุกอย่าง แล้วโหลดกลับ
	ts.set_shift(1)
	GameState.reset()
	DayLoop.board.clear()
	EventManager.jump_event(EventManager.EventID.MAIN, 0)
	var loc := SaveGame.load_into()
	_check(loc == SceneRouter.VILLAGE, "โหลด → กลับฉากหน้าบ้าน")
	_check(ts.shift == 4 and GameState.money == 1234 and GameState.xp == 77 and GameState.reputation == 33 and GameState.level_stars.get(1, 0) == 2, "โหลด → กะ เงิน XP ชื่อเสียง ดาว ครบ")
	_check(DayLoop.board.size() == 1 and DayLoop.board[0].case == cc and DayLoop.board[0].due_shift == 5 and DayLoop.board[0].phone, "โหลด → กระดานงานครบ")
	var ev = EventManager.eventMap[EventManager.EventID.MAIN]
	_check(ev.currentTask == 1 and not ev.isDone, "โหลด → เควสต์ขั้นที่ 2")

	# เควสต์จบแล้ว
	ev.set_step(ev.totalTask - 1)
	ev.currentTask = ev.totalTask
	ev.isDone = true
	SaveGame.save()
	EventManager.jump_event(EventManager.EventID.MAIN, 0)
	SaveGame.load_into()
	_check(ev.isDone and DayLoop._loop_active(), "โหลด → เควสต์จบแล้ว ลูปร้านทำงาน")

	# เมนูหลัก: ปุ่มเล่นต่อ
	var start: Control = load("res://Scene/Start_Scene.tscn").instantiate()
	add_child(start)
	await get_tree().process_frame
	var cont: Button = start.get_node("Menu/Continue_Button")
	_check(cont.visible and cont.text.contains("บทที่ 2 · จ. 11 ม.ค."), "เมนูหลักมีปุ่มเล่นต่อ (%s)" % cont.text)
	start._on_start_button_pressed()
	_check(SaveGame.exists() and start.get_node("Menu/Start_Button").text.contains("อีกครั้ง"), "มีเซฟ → เริ่มเกมใหม่ต้องกดยืนยันอีกครั้ง")
	start._on_start_button_pressed()
	_check(not SaveGame.exists() and ts.shift == 1 and GameState.money == GameState.economy.start_money, "กดยืนยัน → ลบเซฟเดิม · เริ่มวันที่ 1")
	_check(ev.currentTask == 0 and not ev.isDone, "เริ่มใหม่ → เควสต์กลับขั้นแรก")
	# จบสไลด์ → บทนำ → เข้าบ้าน = เซฟใหม่
	if DialogScene.visible:
		DialogScene.dialog_end()
	EventManager.tutorial.hide()
	start.tutorial_end()
	DialogScene.dialog_end()
	await get_tree().create_timer(1.6).timeout
	_check(SaveGame.exists() and SaveGame.info() == { "shift": 1, "money": GameState.economy.start_money }, "เข้าบ้านครั้งแรก → สร้างเซฟใหม่ (%s)" % SaveGame.info())
	start.queue_free()
	await get_tree().process_frame

	# ---- Debug: กดเควสต์ = ขั้นนั้นเสร็จ
	DebugMenu._complete_quest(2)
	await get_tree().create_timer(1.4).timeout
	_check(ev.currentTask == 3 and ev._tasks[2].isDone and SceneRouter.current_id == SceneRouter.ROOM, "Debug เควสต์ 3 เสร็จ → ไปขั้น 4 ที่ร้าน")
	DebugMenu._complete_quest(999)
	await get_tree().create_timer(1.4).timeout
	_check(ev.isDone and DayLoop._loop_active(), "Debug จบเควสต์ทั้งหมด → ลูปร้านทำงาน")
	_check(SaveGame.load_into() >= 0 and ev.isDone, "เซฟหลังกด Debug โหลดกลับได้")

	# ---- เมนูพัก: เล่นต่อ = บันทึก · ปุ่มบันทึกเกม
	DialogScene.dialog_end() # บทพักหลังบทฝึกที่ลูปร้านเปิดเอง
	DayLoop._working = false
	SaveGame.clear()
	PauseMenu.open()
	PauseMenu._on_resume_pressed()
	_check(SaveGame.exists() and not get_tree().paused, "เมนูพัก กดเล่นต่อ → บันทึกให้")
	PauseMenu.open()
	_check(PauseMenu.save_now() and PauseMenu.get_node("%SaveButton").text.contains("บันทึกแล้ว"), "ปุ่มบันทึกเกม → บันทึกแล้ว ✓")
	PauseMenu.resume()

	# [0.2.0-G] ผลสิ้นเดือนเซฟ/โหลดได้
	GameState.missed_months = 1
	GameState.debt_streak = 1
	GameState.help_mode = true
	GameState.month_results.clear()
	GameState.month_results.append({ "m": 1, "profit": 1500, "reached": false, "by_kind": { &"fee": 1500 } })
	_check(SaveGame.save(), "บันทึกผลสิ้นเดือน")
	GameState.missed_months = 0
	GameState.debt_streak = 0
	GameState.help_mode = false
	GameState.month_results.clear()
	_check(SaveGame.load_into() >= 0 and GameState.missed_months == 1 and GameState.debt_streak == 1 and GameState.help_mode and GameState.month_results.size() == 1 and int(GameState.month_results[0].profit) == 1500, "โหลด → ผลสิ้นเดือน พลาดเป้า ค้างบิล โหมดช่วย ครบ")
	GameState.help_mode = false
	_check(not SaveGame.is_old_version(), "เซฟปัจจุบันไม่ใช่เวอร์ชันเก่า")
	# [0.2.0] เซฟตอนการ์ดสรุปเดือนยังค้าง → โหลดแล้วการ์ดกลับมา (เดิมหาย + บทเนื้อเรื่องไม่เล่น)
	DayLoop._pending_summary_week = 4
	DayLoop._last_month = GameState.month_results.back()
	DayLoop._last_bill = { "rent": 1500, "power": 260, "water": 100, "internet": 300, "debt": 0 }
	_check(SaveGame.save(), "บันทึกตอนการ์ดสรุปเดือนค้าง")
	DayLoop._pending_summary_week = 0
	DayLoop._last_month = { }
	DayLoop._last_bill = { }
	_check(SaveGame.load_into() >= 0 and DayLoop._pending_summary_week == 4 and int(DayLoop._last_month.get("profit", 0)) == 1500 and int(DayLoop._last_bill.get("rent", 0)) == 1500, "โหลด → การ์ดสรุปบท 4 + ข้อมูลเดือนกลับมา")
	_check(DayLoop._decide_card() == DayLoop.Card.WEEK_SUMMARY or DayLoop._working or Global.in_minigame or DialogScene.visible, "โหลดแล้วการ์ดที่ต้องขึ้น = สรุปบท")
	DayLoop._pending_summary_week = 0
	DayLoop._last_month = { }
	DayLoop._last_bill = { }
	# เซฟเวอร์ชัน 1 (0.1.x) → โหลดไม่ได้ · เมนูบอกให้เริ่มใหม่
	var old := FileAccess.open(SaveGame.PATH, FileAccess.WRITE)
	old.store_string(JSON.stringify({ "version": 1, "game": { "shift": 3, "money": 99 } }))
	old.close()
	_check(SaveGame.is_old_version() and SaveGame.info().is_empty(), "เซฟ v1 → is_old_version() · info ว่าง")
	var start2: Control = load("res://Scene/Start_Scene.tscn").instantiate()
	add_child(start2)
	await get_tree().process_frame
	var cont2: Button = start2.get_node("Menu/Continue_Button")
	_check(cont2.visible and cont2.disabled and cont2.text.contains("เวอร์ชันเก่า"), "เมนู: %s (กดไม่ได้)" % cont2.text)
	start2.queue_free()

	# คืนเซฟเดิมของผู้เล่น
	if backup != "":
		var f := FileAccess.open(SaveGame.PATH, FileAccess.WRITE)
		f.store_string(backup)
	print("T DONE fails=", fails)
	get_tree().quit()


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
