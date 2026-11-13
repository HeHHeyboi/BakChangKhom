extends Node
## [Claude 13 พ.ย. 2569] งานลูกค้าขมOS ใช้ขมOS ชุดใหม่ (desktop_window2 · DesktopMinigameV2) ผ่านร้านจริง (DayLoop.start_repair)
## • งาน part_desktop ทุกงานเปิดซีนใหม่ได้ อ่าน DesktopTask จากใบงานถูก
## • ถาม → ลองใช้ไม่ผ่าน 2 ครั้ง → ส่งงานตามสภาพ → หน้าสรุป → ส่งเครื่องคืน → ผลเข้าร้าน (การ์ดผลงาน)
## • ปุ่ม "งาน" (ReminderLayer) อ่านข้อมูลจากขมOS ใหม่ได้
## เปิด Test/desktop_v2_loop_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0


func _ready() -> void:
	await get_tree().process_frame
	Global.on_start = false
	GameState.reset()
	# ---- ทุกงาน part_desktop → ซีนใหม่ · อ่านงานจากใบงาน
	var bad := PackedStringArray()
	var n := 0
	for c in DayLoop.random_pool:
		if c == null or c.part_id != "part_desktop":
			continue
		n += 1
		if not c.scene_path().ends_with("desktop_window2.tscn"):
			bad.append("%s ยังใช้ %s" % [c.id, c.scene_path()])
			continue
		var m: DesktopMinigameV2 = (load(c.scene_path()) as PackedScene).instantiate()
		m.boot_screen = false
		m.set_meta("work_order", c)
		add_child(m)
		await _frames(2)
		if m.task != c.desktop_task or m.customer_name != c.customer or m.step != DesktopMinigameV2.Step.LISTEN:
			bad.append("%s อ่านงานไม่ถูก" % c.id)
		m.queue_free()
		await _frames(1)
	_check(n >= 14 and bad.is_empty(), "งานขมOS ในคลัง %d งาน เปิดขมOS ใหม่ + อ่านใบงานถูก %s" % [n, bad])
	Global.in_minigame = false

	# ---- เล่นผ่านร้านจริง: ถาม → ไม่ผ่าน 2 ครั้ง → ส่งตามสภาพ → ผลเข้าร้าน
	var case: CustomerCase = load("res://Resources/Customers/lv1_min_hang.tres")
	DayLoop.today_case = case
	DayLoop.start_repair()
	var m2: DesktopMinigameV2 = null
	for i in 240:
		await get_tree().process_frame
		if is_instance_valid(DayLoop._minigame) and DayLoop._minigame is DesktopMinigameV2 and DayLoop._minigame.is_inside_tree():
			m2 = DayLoop._minigame
			break
	_check(m2 != null, "ร้านเปิดงานขมOS ด้วยขมOS ใหม่")
	if m2 == null:
		_done()
		return
	await _frames(10)
	var rem: JobReminder = DayLoop.job_reminder
	_check(rem._btn.visible, "ระหว่างซ่อมมีปุ่ม \"งาน\"")
	rem.open_card()
	_check(rem.card_text().contains("ยังไม่ได้ถามลูกค้า") and rem.card_text().contains(String(m2.task.request).left(10)), "ปุ่มงาน: ลูกค้าบอกอะไร + ยังไม่ได้ถาม")
	rem.close_card()
	m2._ask(m2.task.ask_best)
	await _frames(2)
	rem.open_card()
	var ans := String(m2.task.ask_answer)
	_check(m2.step == DesktopMinigameV2.Step.WORK and (ans == "" or rem.card_text().contains(ans.left(10))), "ถามถูก → ขั้นลงมือ · ปุ่มงานบอกคำตอบลูกค้า")
	rem.close_card()
	m2._on_check_pressed()
	m2._on_check_pressed()
	await _frames(2)
	_check(m2.check_fails >= 2 and m2.can_give_up(), "ลองใช้ไม่ผ่าน 2 ครั้ง → ส่งงานตามสภาพได้")
	var sat0 := GameState.satisfaction_history.size()
	m2.give_up()
	_check(m2.step == DesktopMinigameV2.Step.SUMMARY and m2.score_of(&"fix") == 0, "ส่งตามสภาพ → หน้าสรุป · คะแนนทำงาน 0")
	m2.finish()
	for i in 120:
		await get_tree().process_frame
		if DayLoop._result_pending and not is_instance_valid(DayLoop._minigame):
			break
	_check(GameState.satisfaction_history.size() == sat0 + 1 and DayLoop._result_pending and DayLoop.last_result.has("score") and not is_instance_valid(DayLoop._minigame), "ส่งเครื่องคืน → ผลเข้าร้าน รอขึ้นการ์ดผลงาน (คะแนน %d)" % int(DayLoop.last_result.get("score", -1)))
	await _frames(2)
	_check(not Global.in_minigame and not rem._btn.visible, "ปิดมินิเกม → ปุ่มงานหาย")
	_done()


func _done() -> void:
	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
	print("T %s %s" % ["PASS" if ok else "FAIL", msg])
