extends Node
## [Claude 13 ต.ค. 2569] บทฝึกประกอบคอม: ผู้เล่นเล่นเร็ว / วางหลายชิ้นซ้อนกันตอนกำลังขันน็อต
## เดิม: วาง PSU แล้วรีบวางเมนบอร์ด → นับแค่เมนบอร์ด ข้ามการขันน็อต PSU · ระหว่างขันน็อตยังลากชิ้นอื่นได้ (allow([]) = ทุกชิ้น)
## เปิด Test/assembly_race_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

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
	var st: Stage2D = m.stage
	var psu: Item2D = m.parts()[0]
	var mb: Item2D = m.parts()[1]
	_check(psu.data.socket_type == &"psu_bay" and mb.data.socket_type == &"mb_standoff", "ลำดับชิ้น: PSU → เมนบอร์ด")
	var s_psu: Socket2D = ph._socket_for(psu)
	var s_mb: Socket2D = ph._socket_for(mb)
	st.go_to(&"Build", true)
	st.install(psu, s_psu)
	await _wait(0.35)
	_check(ph._seating, "วาง PSU → เริ่มขันน็อต PSU")
	_check(not st._can_use(mb), "ระหว่างขันน็อต PSU ลากเมนบอร์ดไม่ได้")
	# จำลองผู้เล่นที่ปล่อยเมนบอร์ดลงช่องได้ทันพอดี (เช่น ลากค้างไว้ก่อน)
	st.install(mb, s_mb)
	await _wait(0.5)
	_check(ph._queue.size() == 1, "เมนบอร์ดเข้าคิว (ไม่ถูกข้าม)")
	_check(not mb.visible or mb.scale.x > 1.0, "เมนบอร์ดลอยค้าง ยังไม่ลงสุด")
	_check(not _done(ph, mb), "เมนบอร์ดยังไม่นับว่าติดตั้ง")
	var psu_screws := await _do_screws(ph, psu)
	_check(psu_screws == 4, "ขันน็อต PSU ครบ 4 ตัว (ได้ %d)" % psu_screws)
	_check(_done(ph, psu), "PSU ติดตั้งแล้ว ✓")
	await _wait(1.2)
	_check(ph._seating, "ต่อคิว → ขันน็อตเมนบอร์ดต่อทันที")
	var mb_screws := await _do_screws(ph, mb, true)
	_check(mb_screws == 4, "ขันน็อตเมนบอร์ดครบ 4 ตัว (ได้ %d)" % mb_screws)
	await _wait(0.3)
	_check(_done(ph, mb) and not ph._seating, "เมนบอร์ดติดตั้งแล้ว ✓ ไม่มีชิ้นค้าง")
	_check(st._can_use(m.parts()[2]), "ติดตั้งเสร็จ → หยิบชิ้นถัดไปได้")
	QteRunner.auto_result = -1
	print("T DONE fails=", fails)
	get_tree().quit()


func _done(ph, p) -> bool:
	return ph._checks[p].get_meta("done", false)


## กดน็อตตามคิวของชิ้น p จนชิ้นนั้นติดตั้งเสร็จ · คืนจำนวนน็อตที่ขัน
func _do_screws(ph, p: Item2D, until_idle := false) -> int:
	var n := 0
	var guard := 0
	while guard < 400 and not _done(ph, p):
		guard += 1
		for x in p.get_children():
			if x is SeatTarget and x.next and not x.finished:
				if x.kind == SeatTarget.Kind.SCREW:
					n += 1
				x.press()
		await _wait(0.05)
	if until_idle:
		while ph._seating and guard < 600:
			guard += 1
			await _wait(0.05)
	return n


func _click_pib_forever() -> void:
	while is_inside_tree():
		if is_instance_valid(m) and is_instance_valid(m.pib) and m.pib.dialog_panel.visible:
			m.pib._on_dialog_panel_pressed()
		await _wait(0.15)


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
