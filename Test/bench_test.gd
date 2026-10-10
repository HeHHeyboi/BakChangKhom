extends Node
## [Claude 10 ต.ค. 2569] โต๊ะหลังเครื่อง (Lv2): เมาส์ไม่ทำงาน · จอไม่ขึ้น · ทำความสะอาดคีย์บอร์ด
## เปิด Test/bench_test.tscn → F6 → "T DONE fails=0"

const SCENE := "res://Scene/MiniGame/Bench/back_bench.tscn"
var fails := 0


func _ready() -> void:
	await get_tree().process_frame
	for c in ["lv2_coworker_mouse", "lv2_teacher_monitor", "lv2_kid_keyboard"]:
		var cc: CustomerCase = load("res://Resources/Customers/%s.tres" % c)
		_check(cc.level == 2 and cc.part_id == "part_bench" and cc.problems().is_empty(), "ลูกค้า %s ครบ %s" % [c, cc.problems()])
	_check(DayLoop.random_pool.filter(func(c): return c.part_id == "part_bench").size() == 3, "random_pool มีงานโต๊ะหลังเครื่อง 3 งาน")

	# ---- เมาส์ไม่ทำงาน
	var m := await _open("bench_mouse_coworker")
	_check(m.step == BenchMinigame.Step.LISTEN and m._modal.visible, "เริ่มที่ขั้นฟัง")
	m.ask(m.task.ask_best)
	m._close_modal()
	_check(not m.device_ok("mouse") and m.device_ok("keyboard"), "เมาส์อยู่ช่องเสีย (ไม่มีไฟ) · คีย์บอร์ดปกติ")
	await _shot("mouse_start")
	m.unplug("mouse")
	_check(m.plug_in("mouse", "lan") != "" and m.score_of(&"safety") == 25, "ฝืนเสียบ USB ช่องแลน → เสียบไม่เข้า · ปลอดภัย −5")
	_check(m.plug_in("mouse", "usb1") != "", "ช่องที่มีสายอยู่แล้วเสียบซ้อนไม่ได้")
	_check(m.plug_in("mouse", "usb4") == "" and m.device_ok("mouse"), "ย้ายไป USB 4 → เมาส์ติด")
	await _shot("mouse_fixed")
	await _pass(m, "เมาส์", 95)

	# ---- จอไม่ขึ้น
	m = await _open("bench_monitor_teacher")
	m.ask(m.task.ask_best)
	m._close_modal()
	_check(not m.device_ok("monitor") and m.check() != "", "สายจอเสียบช่องเมนบอร์ด → ไม่มีสัญญาณ")
	m.unplug("power")
	_check(m.score_of(&"safety") == 20 and not m.pc_on, "ดึงปลั๊กไฟตอนเครื่องเปิด → ปลอดภัย −10")
	m.plug_in("power", "power")
	m.set_power(true)
	m.unplug("monitor")
	_check(m.plug_in("monitor", "dp_gpu") != "", "หัว HDMI เสียบช่อง DP ไม่ได้")
	_check(m.plug_in("monitor", "hdmi_gpu") == "" and m.device_ok("monitor"), "เสียบที่การ์ดจอ → ขึ้นภาพ")
	await _pass(m, "จอ", 100 - 10 - 10 - 5)

	# ---- ทำความสะอาดคีย์บอร์ด
	m = await _open("bench_keyboard_kid")
	m.ask(m.task.ask_best)
	m._close_modal()
	m.open_clean()
	m.clean_spot(0, 0)
	_check(m.score_of(&"safety") == 20 and m.spots[0] == 1, "ทำความสะอาดทั้งที่ยังเสียบ → ปลอดภัย −10 · เศษหลุด")
	m.unplug("keyboard")
	m.clean_spot(1, 2)
	_check(m.wet and m.score_of(&"safety") == 10, "ใช้ผ้าชุบน้ำ → เปียก · ปลอดภัย −10")
	await _shot("keyboard_clean")
	m.clean_spot(1, 1)
	_check(not m.wet and m.spots[1] == 2, "ลูกยางเป่าแห้ง (เศษติดแน่นยังอยู่)")
	for i in m.spots.size():
		m.clean_spot(i, 0)
		m.clean_spot(i, 1)
	_check(m.dirt_left() == 0, "แปรง + เป่า ครบ 6 จุด")
	m.close_clean()
	_check(m.check().contains("เสียบ"), "ยังไม่เสียบคีย์บอร์ดกลับ → เช็กไม่ผ่าน")
	m.plug_in("keyboard", "usb1")
	await _pass(m, "คีย์บอร์ด", 100 - 20 - 10)

	print("T DONE fails=", fails)
	get_tree().quit()


func _open(task_name: String) -> BenchMinigame:
	var m: BenchMinigame = (load(SCENE) as PackedScene).instantiate()
	m.task = load("res://Resources/Bench/%s.tres" % task_name)
	add_child(m)
	await _frames(2)
	_check(m.task.problems().is_empty(), "%s ข้อมูลครบ %s" % [task_name, m.task.problems()])
	return m


func _pass(m: BenchMinigame, tag: String, want: int) -> void:
	var why := m.check()
	_check(why == "", "%s ลองใช้ให้ลูกค้าดู → ผ่าน %s" % [tag, why])
	m.explain(m.task.explain_best)
	_check(m.final_score() == want, "%s คะแนน %d (ได้ %d · %s)" % [tag, want, m.final_score(), m.notes])
	m.queue_free()
	await _frames(2)


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)


func _shot(n: String) -> void:
	if OS.get_environment("SHOT") == "":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_jpg(OS.get_environment("SHOT") + "/bench_%s.jpg" % n, 0.8)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
