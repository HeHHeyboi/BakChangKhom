extends Node
## [Claude 9 ต.ค. 2569] ทดสอบบทฝึกประกอบคอม ขั้นประกอบ: วางชิ้นแล้วลอยค้าง → ท่าจริง (น็อต · คันล็อก · กดค้าง · M.2) → ลงสุด
## เปิด Test/assembly_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"
## SHOT=1 (รันแบบมีจอ) = เก็บภาพไว้ที่ user://assembly_*.jpg

var fails := 0
var m: TutorialAssembly


func _ready() -> void:
	await get_tree().process_frame
	QteRunner.auto_result = QteRunner.Result.PERFECT
	m = load("res://Scene/MiniGame/TutorialAssembly/tutorial_assembly.tscn").instantiate()
	m.start_phase = TutorialAssembly.PhaseState.BUILD
	add_child(m)
	_click_pib_forever()
	await _wait(1.0)
	var ph = m.get_node("PhaseBuild")
	_check(m.current_phase == TutorialAssembly.PhaseState.BUILD, "เริ่มขั้นประกอบ")
	var st: Stage2D = m.stage
	var expect := { &"psu_bay": 4, &"mb_standoff": 4, &"cpu_socket": 0, &"cooler_mount": 4, &"ram_slot": 0, &"pcie_x16": 1, &"m2_slot": 1 }
	for p in m.parts():
		var s: Socket2D = ph._socket_for(p)
		st.go_to(&"Build", true)
		st.install(p, s)
		await _wait(0.35)
		var t := String(p.data.socket_type)
		_check(ph._seating and p.scale.x > 1.0 or t == "m2_slot", "%s ลอยค้างเหนือช่อง (ยังไม่ลงสุด)" % p.data.display_name)
		await _shot(t + "_lift")
		await _wait(0.6) # น็อต/คันล็อกโผล่หลังชิ้นลงช่อง
		if t == "mb_standoff":
			var sc := _targets(p)
			var wrong: SeatTarget = sc[2] if sc.size() > 2 else null
			if wrong:
				wrong.press()
				_check(not wrong.finished, "กดน็อตผิดคิว → ไม่ขัน (ต้องทแยงมุม)")
		await _shot(t)
		var screws := 0
		var guard := 0
		while ph._seating and guard < 400:
			guard += 1
			for x in _targets(p):
				if x.next and not x.finished:
					if x.kind == SeatTarget.Kind.SCREW:
						screws += 1
					x.press()
			await _wait(0.05)
		_check(not ph._seating, "%s ติดตั้งจนจบ" % p.data.display_name)
		_check(screws == int(expect.get(p.data.socket_type, 0)), "%s ขันน็อต %d ตัว (ต้อง %d)" % [p.data.display_name, screws, expect.get(p.data.socket_type, 0)])
		_check(p.position.is_equal_approx(s.position) and p.scale.is_equal_approx(Vector2.ONE) and is_zero_approx(p.rotation), "%s ลงสุดตรงช่อง" % p.data.display_name)
		_check(not p.visible and m.layer_shown(p.data.socket_type), "%s ชิ้นลอยหาย → ภาพประกอบแล้ว" % p.data.display_name)
		await _wait(2.0) # รอกล้องกลับไปแผ่นรองให้เสร็จก่อน
	st.go_to(&"Build", true)
	await _wait(0.5)
	_check(m.layer_shown(&"cables"), "ครบทุกชิ้น → มีสายไฟ (ภาพประกอบเสร็จ)")
	await _shot("done")
	await _wait(1.5)
	_check(m.current_phase == TutorialAssembly.PhaseState.POWER_TEST, "ครบ 7 ชิ้น → ขั้นเปิดเครื่อง")

	# ---- เปิดเครื่อง → ทำความรู้จัก ขมOS → ปิดเครื่อง → สรุป
	await _wait(0.5)
	await _shot("power")
	m.stage.press_part(m.find_child("PowerButton", true, false))
	await _wait(0.4)
	await _shot("power_on")
	var guard := 0
	while not is_instance_valid(m.os_tour) and guard < 100:
		guard += 1
		await _wait(0.1)
	var os: DesktopMinigame = m.os_tour
	_check(os != null and os.tour_mode and os.free_mode, "เปิดเครื่องแล้วขึ้น ขมOS (แทนจอ OK)")
	if os:
		await _wait(0.9)
		_check(os.framed and os.is_booting, "เปิดเครื่อง → ซูมเข้าจอบนโต๊ะ · บูตในโหนด OS เดียวกัน")
		await _shot("os_boot")
		os.skip_boot()
		await _wait(0.6)
		await _shot("os_tour")
		os.shut_down()
		_check(is_instance_valid(os) and os.step != DesktopMinigame.Step.DONE, "ยังไม่ครบขั้น → ปิดเครื่องไม่ได้")
		os.open_explorer("เอกสาร")
		os.open_browser()
		os.open_settings()
		_check(os._tour_current() == "delete_file", "เปิดไฟล์ · เบราว์เซอร์ · ตั้งค่า แล้วขั้นต่อไป = ลบไฟล์")
		os.delete_file(os.find_file("ไฟล์ทดสอบ.doc"))
		os.empty_trash()
		_check(os._tour_current() == "shutdown", "ลบไฟล์ + ล้างถังขยะ → เหลือปิดเครื่อง")
		await _shot("os_tour_last")
		os.shut_down()
		await _wait(0.2)
		_check(not is_instance_valid(os) and m.os_tour == null and Global.cur_pib == m.pib, "ปิดเครื่อง → กลับบทฝึก")
	guard = 0
	while m.current_phase != TutorialAssembly.PhaseState.SUMMARY and guard < 60:
		guard += 1
		await _wait(0.1)
	_check(m.current_phase == TutorialAssembly.PhaseState.SUMMARY, "จบ OS → ขั้นสรุป")
	# ข้ามไปขั้นเปิดเครื่องด้วย Debug (F2) → ใส่ครบ + ภาพประกอบเสร็จทันที
	var m2: TutorialAssembly = load("res://Scene/MiniGame/TutorialAssembly/tutorial_assembly.tscn").instantiate()
	add_child(m2)
	await _wait(0.8)
	m2.debug_jump(TutorialAssembly.PhaseState.POWER_TEST)
	await _wait(0.2)
	var all_ok := true
	for k in m2.LAYERS:
		all_ok = all_ok and m2.layer_shown(k)
	_check(all_ok, "Debug ข้ามไปเปิดเครื่อง → ภาพประกอบครบทุกชั้น")
	await _wait(1.0)
	m2.stage.press_part(m2.find_child("PowerButton", true, false))
	for i in 60:
		if is_instance_valid(m2.os_tour):
			break
		if is_instance_valid(m2.pib) and m2.pib.dialog_panel.visible:
			m2.pib._on_dialog_panel_pressed()
		await _wait(0.15)
	var os2 = m2.os_tour
	var opened := is_instance_valid(os2)
	if opened:
		(os2.find_child("SkipTour", true, false) as Button).pressed.emit()
		await _wait(0.2)
	_check(opened and not is_instance_valid(os2) and m2.os_tour == null, "กด \"ข้ามการแนะนำ\" ได้")
	m2.queue_free()
	QteRunner.auto_result = -1
	print("T DONE fails=", fails)
	get_tree().quit()


func _targets(p: Node) -> Array:
	var out := []
	for c in p.get_children():
		if c is SeatTarget:
			out.append(c)
	return out


func _click_pib_forever() -> void:
	while is_inside_tree():
		if is_instance_valid(m) and is_instance_valid(m.pib) and m.pib.dialog_panel.visible:
			m.pib._on_dialog_panel_pressed()
		await _wait(0.15)


func _shot(n: String) -> void:
	if OS.get_environment("SHOT") == "":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(864, 486)
	img.save_jpg(OS.get_environment("SHOT") + "/assembly_%s.jpg" % n, 0.75)


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
