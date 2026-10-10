extends Node
## [Claude 10 ต.ค. 2569] มินิเกมตรวจเครื่องเบื้องต้น (แทนหายางลบ) · ระบบเทิร์น · ยศช่าง · จบบทที่ 1
## เปิด Test/power_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	var m: PowerCheckMinigame = load("res://Scene/MiniGame/PowerCheck/power_check.tscn").instantiate()
	add_child(m)
	await _frames(2)
	_check(m.steps.get_child_count() == 5 and not m.quiz.visible, "เริ่ม: เช็คลิสต์ 5 ขั้น · ยังไม่มีคำถาม")
	await _shot("start")
	m.power_button.pressed.emit()
	_check(not m.powered and m.mistakes == 1 and m.say_label.text.contains("ปลั๊ก"), "กดเปิดก่อนเสียบปลั๊ก → เงียบ + บอกว่าปลั๊กหลุด")
	m.plug.pressed.emit()
	m.strip_switch.pressed.emit()
	m.power_button.pressed.emit()
	_check(not m.powered and m.say_label.text.contains("PSU"), "ลืมสวิตช์ PSU → บอก")
	m.psu_switch.pressed.emit()
	_check(m.is_ready(), "ไฟพร้อม 3 อย่าง")
	await get_tree().create_timer(0.5).timeout
	m.power_button.pressed.emit()
	_check(m.powered, "กดเปิดเครื่อง → ไฟเข้า")
	await get_tree().create_timer(1.0).timeout
	await _shot("beep")
	await get_tree().create_timer(4.5).timeout
	_check(m.quiz.visible, "บี๊บจบ → ถามอาการ")
	m.answers.get_node("Gpu").pressed.emit()
	_check(not m.answered and m.mistakes == 3, "ตอบการ์ดจอ → ผิด อธิบาย")
	m.answers.get_node("Ram").pressed.emit()
	_check(m.answered and m.done_button.visible, "ตอบแรม → ถูก ปุ่มไปต่อ")
	await _shot("done")
	var got := [-1]
	m.finished.connect(func(n): got[0] = n)
	m.finish()
	await _frames(2)
	_check(got[0] == 3 and not is_instance_valid(m), "จบมินิเกม (ผิด %d ครั้ง)" % got[0])
	var q := FileAccess.get_file_as_string("res://Resources/main.tres")
	_check(q.contains("PowerCheck/power_check.tscn") and not q.contains("d3tpe65flyrex"), "เควสต์หลักขั้น 3 = ตรวจเครื่องเบื้องต้น (ไม่มีหายางลบแล้ว)")
	# ---- HUD แบบเทิร์น + แถบยศช่าง
	var ts: TimeSystem = load("res://Scene/time_system.tscn").instantiate()
	add_child(ts)
	await _frames(1)
	ts.set_shift(2, TimeSystem.OPEN)
	ts.updateTime()
	_check(not ts.show_clock and ts.timeText.text == "16 เทิร์น" and ts.dateText.text.contains("บทที่ 1 · วันที่ 2/5") and ts.dateText.text.contains("อีก 3 วัน"), "HUD บอกเทิร์น (%s | %s)" % [ts.timeText.text, ts.dateText.text.replace("\n", " / ")])
	ts.set_clock(TimeSystem.CLOSE - 90)
	ts.updateTime()
	_check(ts.timeText.text == "3 เทิร์น", "เหลือ 1½ ชม. = 3 เทิร์น (%s)" % ts.timeText.text)
	GameState.xp = 0
	var ups := []
	GameState.rank_up.connect(func(r, n): ups.append(n))
	GameState.add_xp(450)
	await _frames(2)
	_check(ts.get_node("RankPanel/Box/Rank").text == "ช่างมือใหม่" and is_equal_approx(ts.get_node("RankPanel/Box/Bar").value, 0.9) and ts.get_node("RankPanel/Box/Xp").text == "450/500 XP", "แถบยศ 450/500")
	GameState.add_xp(100)
	await _frames(2)
	_check(ups == ["ช่างฝึกหัด"] and ts.get_node("RankUp").visible, "ครบ 500 XP → เลื่อนขั้นเป็นช่างฝึกหัด + ป้าย")
	await get_tree().create_timer(0.4).timeout
	await _shot("hud")
	GameState.xp = 0
	ts.queue_free()
	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _check(ok: bool, what: String) -> void:
	if ok:
		print("PASS ", what)
	else:
		fails += 1
		print("FAIL ", what)


func _shot(n: String) -> void:
	if OS.get_environment("SHOT") == "":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_jpg(OS.get_environment("SHOT") + "/power_%s.jpg" % n, 0.8)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
