extends Node
## [Claude 10 ต.ค. 2569] งาน ขมOS ที่เพิ่ม: Lv1 1-4 … 1-10 + Lv2 บนจอ (สแกนไวรัส · จอภาพ)
## แต่ละงาน: ตกกับดัก 1 ครั้ง → แก้ให้ถูก → เช็กผ่าน → คะแนนตามที่หัก
## เปิด Test/desktop_lv_test.tscn → F6 → "T DONE fails=0"

const SCENE := "res://Scene/MiniGame/Desktop/desktop_window.tscn"
var fails := 0


func _ready() -> void:
	await get_tree().process_frame
	for c in ["lv2_min_virus", "lv2_teacher_display"]:
		var cc: CustomerCase = load("res://Resources/Customers/%s.tres" % c)
		_check(cc.level == 2 and cc.problems().is_empty(), "ลูกค้า %s ครบ %s" % [c, cc.problems()])

	# ---- 1-4 ปิดโปรแกรมค้าง
	var m := await _open("task_close_hang_shop")
	var x: OsExtra = m.extra
	_check(m._windows.has("hang") and not x.hang_proc().is_empty(), "1-4 เปิดมาเจอหน้าต่างโปรแกรมค้าง")
	_check(m.check() != "", "1-4 ยังค้าง = เช็กไม่ผ่าน")
	x.open_task_manager()
	_check(m._windows.has("taskman"), "1-4 เปิดตัวจัดการงานได้")
	_check(not x.end_task(x.find_proc("ขมOS เดสก์ท็อป")) and m.score_of(&"safety") == 20, "1-4 ปิดของระบบ = จอฟ้า ปลอดภัย −10")
	_check(x.end_task(x.find_proc("โปรแกรมคิดเงิน")) and x.hang_proc().is_empty(), "1-4 จบงานโปรแกรมค้าง")
	_check(x.find_proc("ตารางบัญชี").running and not m.lost_user_file, "1-4 งานลูกค้าที่ยังไม่บันทึกยังอยู่")
	await _pass(m, "1-4", 80)

	# ---- 1-5 เครื่องพิมพ์
	m = await _open("task_printer_teacher")
	x = m.extra
	_check(x.print_test().contains("ยังไม่มี"), "1-5 เริ่มแรกไม่มีเครื่องพิมพ์")
	x.open_printers()
	x.add_printer(m.task.printers[0])
	_check(m.score_of(&"fix") == 30 and not x.print_test().contains("โต๊ะลูกค้า"), "1-5 เพิ่มผิดเครื่อง → พิมพ์ไปออกห้องอื่น · ทำงาน −10")
	x.add_printer(m.task.printers[1])
	x.set_default_printer(m.task.printers[1])
	_check(x.print_test().contains("โต๊ะลูกค้า"), "1-5 ตั้งห้องพักครูเป็นค่าเริ่มต้น → ออกกระดาษ")
	await _pass(m, "1-5", 90)

	# ---- 1-6 เสียง
	m = await _open("task_sound_headman")
	x = m.extra
	_check(not x.sound_ok() and x.test_sound().contains("ปิดเสียง"), "1-6 เริ่มแรกเงียบ (ปิดเสียง · ไปหูฟัง)")
	x.open_sound()
	m.uninstall(m.find_program("ไดรเวอร์เสียง"))
	_check(m.score_of(&"safety") == 20, "1-6 ถอนไดรเวอร์เสียง (ของระบบ) → ปลอดภัย −10")
	x.set_muted(false)
	x.set_volume(60)
	_check(not x.sound_ok() and x.test_sound().contains("หูฟัง"), "1-6 เปิดเสียงแล้วแต่ยังออกหูฟัง")
	x.set_sound_device(1)
	_check(x.sound_ok(), "1-6 เลือกลำโพง → มีเสียง")
	await _pass(m, "1-6", 90)

	# ---- 1-7 Wi-Fi
	m = await _open("task_wifi_girl", false)
	x = m.extra
	m.ask(m.task.ask_best)
	m._close_modal()
	_check(m._ask_note_label.visible and m._ask_note_label.text.contains("maikai2569"), "1-7 ถามถูก → จดรหัสบนกระดาษโน้ต")
	x.open_wifi()
	x.connect_wifi("FREE_WIFI_ฟรี")
	_check(m.score_of(&"safety") == 20 and m.check().contains("สาธารณะ"), "1-7 ต่อเน็ตฟรี → ปลอดภัย −10 · เช็กไม่ผ่าน")
	_check(x.connect_wifi("บ้านแม่ไก่", "1234") != "", "1-7 รหัสผิดต่อไม่ได้")
	_check(x.connect_wifi("บ้านแม่ไก่", "maikai2569") == "", "1-7 รหัสถูก → ต่อเน็ตบ้าน")
	await _pass(m, "1-7", 80, true)

	# ---- 1-8 สำรองลง USB
	m = await _open("task_backup_yai")
	x = m.extra
	m.open_explorer("รูปภาพ")
	var pics := m.visible_files("รูปภาพ")
	_check(pics.size() == 3 and x.usb_present(), "1-8 มีรูป 3 รูป + USB เสียบอยู่")
	x.move_to_usb(pics[0])
	_check(m.score_of(&"safety") == 20 and not x.backup_missing().is_empty(), "1-8 ย้าย (ไม่ใช่คัดลอก) → ปลอดภัย −10 · ในเครื่องไม่เหลือ")
	var moved: Dictionary = pics[0]
	moved.folder = "รูปภาพ" # ย้ายกลับ (ผู้เล่นคัดลอกกลับจาก USB)
	x.copy_to_usb(moved)
	for f in m.visible_files("รูปภาพ"):
		x.copy_to_usb(f)
	_check(x.backup_missing().is_empty() and m.check().contains("ถอด USB"), "1-8 คัดลอกครบแล้ว แต่ยังไม่ถอดอย่างปลอดภัย")
	_check(m.step == DesktopMinigame.Step.WORK, "1-8 ยังอยู่ขั้นลงมือ")
	x.eject_usb()
	await _pass(m, "1-8", 80)

	# ---- 1-9 เปิดพร้อมเครื่อง
	m = await _open("task_startup_amnuay")
	x = m.extra
	x.open_task_manager()
	x._tm_tab = "startup"
	x._refresh_tm()
	_check(x.boot_time() == 31, "1-9 เปิดเครื่อง ~31 วิ")
	x.set_startup(x.find_proc("ขมการ์ด (แอนตี้ไวรัส)"), false)
	_check(m.score_of(&"safety") == 20 and m.check().contains("ไม่ปลอดภัย"), "1-9 ปิดแอนตี้ไวรัส → ปลอดภัย −10")
	x.set_startup(x.find_proc("ขมการ์ด (แอนตี้ไวรัส)"), true)
	for n in ["เกมฟาร์มผัก", "โปรแกรมแชตเก่า", "ตัวอัปเดตเครื่องพิมพ์"]:
		x.set_startup(x.find_proc(n), false)
	_check(x.boot_time() <= m.task.boot_target_s and m.find_program("เกมฟาร์มผัก").installed, "1-9 ปิด 3 ตัว → เร็วขึ้น (~%d วิ) โปรแกรมยังอยู่" % x.boot_time())
	await _pass(m, "1-9", 80)

	# ---- 1-10 อัปเดต
	m = await _open("task_update_office")
	x = m.extra
	_check(m._windows.has("doc") and not x.doc_saved, "1-10 มีงานลูกค้ายังไม่บันทึก")
	x.open_update()
	x.check_update()
	x.start_install()
	x.power_off_during_update()
	_check(x.update_state == -1 and m.score_of(&"safety") == 20, "1-10 ปิดเครื่องกลางอัปเดต → พัง · ปลอดภัย −10")
	x.update_state = 0
	x.check_update()
	x.start_install()
	x.finish_install()
	_check(m.check().contains("รีสตาร์ต"), "1-10 ติดตั้งแล้วแต่ยังไม่รีสตาร์ต")
	x.save_doc()
	x.restart_now()
	_check(x.update_state == 4 and not m.lost_user_file, "1-10 บันทึกงานแล้วรีสตาร์ต → อัปเดตเสร็จ งานไม่หาย")
	m.skip_boot()
	await _pass(m, "1-10", 80)

	# ---- Lv2 สแกนไวรัส
	m = await _open("task_virus_min")
	x = m.extra
	x.open_security()
	x.set_protection(false)
	_check(x.scan_now() == 0 and m.score_of(&"safety") == 20, "Lv2 ปิดการป้องกัน → สแกนไม่ได้ · ปลอดภัย −10")
	x.set_protection(true)
	_check(x.scan_now() == 2, "Lv2 สแกนเจอ 2 ตัว")
	x.quarantine("ตัวขุดเหรียญแฝง")
	x.quarantine("ส่วนเสริมเบราว์เซอร์ปลอม")
	_check(m.check().contains("ชั่วคราว"), "Lv2 กักกันครบ แต่ไฟล์ชั่วคราวยังเต็ม")
	var free0: int = m.free_mb
	x.clean_temp()
	_check(m.free_mb == free0 + 6000, "Lv2 ล้างไฟล์ชั่วคราว → ได้พื้นที่ 6 GB")
	await _pass(m, "Lv2 สแกนไวรัส", 80)

	# ---- Lv2 จอภาพ
	m = await _open("task_display_director")
	x = m.extra
	_check(m._icons.scale.x > 1.5, "Lv2 จอ: เริ่มแรกไอคอนใหญ่ล้น (%.2f)" % m._icons.scale.x)
	x.open_display()
	_check(not x.set_resolution(2) and m.check().contains("จอดำ"), "Lv2 จอ: เลือกค่าที่จอไม่รองรับ → จอดับถามเก็บค่า")
	x.keep_resolution(true)
	_check(m.score_of(&"fix") == 20, "Lv2 จอ: กดเก็บค่า → ทำงาน −10 (รวมเช็กไม่ผ่าน −10)")
	x.set_resolution(1)
	_check(m.check().contains("ใหญ่"), "Lv2 จอ: ความละเอียดถูกแล้ว แต่ขนาด 150% ยังใหญ่")
	x.set_scale(100)
	_check(x.display_ok() and is_equal_approx(m._icons.scale.x, 1.0), "Lv2 จอ: 100% → พอดี")
	await _shot("display")
	await _pass(m, "Lv2 จอภาพ", 70)

	print("T DONE fails=", fails)
	get_tree().quit()


## เปิดงาน (ข้ามจอบูต · ถามข้อถูกให้เลย ถ้า ask = true)
func _open(task_name: String, ask := true) -> DesktopMinigame:
	var m: DesktopMinigame = (load(SCENE) as PackedScene).instantiate()
	m.task = load("res://Resources/Desktop/%s.tres" % task_name)
	add_child(m)
	await _frames(2)
	m.skip_boot()
	await _frames(2)
	_check(m.task.problems().is_empty(), "%s ข้อมูลครบ %s" % [task_name, m.task.problems()])
	if ask:
		m.ask(m.task.ask_best)
		m._close_modal()
	return m


## เช็กผ่าน → อธิบายถูก → คะแนนตามที่คาด → ปิด
func _pass(m: DesktopMinigame, tag: String, want: int, _asked := false) -> void:
	await _frames(2)
	var why := m.check()
	_check(why == "", "%s ลองใช้ให้ลูกค้าดู → ผ่าน %s" % [tag, why])
	m.explain(m.task.explain_best)
	_check(m.final_score() == want, "%s คะแนน %d (ได้ %d · %s)" % [tag, want, m.final_score(), m.notes])
	await _shot(tag)
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
	get_viewport().get_texture().get_image().save_jpg(OS.get_environment("SHOT") + "/lv_%s.jpg" % n.validate_filename(), 0.8)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
