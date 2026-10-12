extends Node
## [Claude 13 ต.ค. 2569] ขมOS: ผู้เล่นเล่นแปลก ๆ (ลบรูปลูกค้าแล้วล้างถัง · ส่งงานพลาดซ้ำ) ต้องไม่ค้าง
## • ทำของลูกค้าหาย / ลองใช้ไม่ผ่าน 2 ครั้ง → ปุ่ม "ส่งงานตามสภาพ" โผล่ → ไปหน้าสรุปได้
## • หน้าสรุปที่มีบันทึกความผิดพลาดยาว ๆ → ปุ่ม "ส่งเครื่องคืนลูกค้า" ยังอยู่ในหน้าต่าง กดได้
## เปิด Test/desktop_giveup_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

const SCENE := "res://Scene/MiniGame/Desktop/desktop_window.tscn"
var fails := 0


func _ready() -> void:
	await get_tree().process_frame
	var m: DesktopMinigame = (load(SCENE) as PackedScene).instantiate()
	m.task = load("res://Resources/Desktop/task_free_space_photos.tres")
	add_child(m)
	await _frames(2)
	m.skip_boot()
	await _frames(1)
	m.ask(m.task.ask_best)
	await _frames(1)
	_check(m.step == DesktopMinigame.Step.WORK and not m._giveup_btn.visible, "เริ่มงาน → ยังไม่มีปุ่มส่งงานตามสภาพ")
	# ลบไฟล์ของลูกค้าทุกไฟล์ แล้วล้างถังขยะ (เล่นแบบหาบั๊ก)
	var n := 0
	for f in m.files:
		if f.kind == "user" and not f.trashed:
			m.delete_file(f)
			n += 1
	m.empty_trash()
	await _frames(1)
	_check(n > 0 and m.lost_user_file, "ลบรูปลูกค้า %d ไฟล์ + ล้างถัง → ของลูกค้าหาย" % n)
	_check(m._giveup_btn.visible, "ของลูกค้าหาย → ปุ่ม \"ส่งงานตามสภาพ\" โผล่")
	# ใส่บันทึกยาว ๆ เยอะ ๆ (จำลองคนกดผิดทุกอย่าง)
	for i in 12:
		m.notes.append("บันทึกความผิดพลาดทดสอบข้อที่ %d ข้อความยาวมาก ๆ เพื่อดูว่าหน้าต่างสรุปยังกดปุ่มส่งเครื่องคืนได้หรือไม่ เมื่อข้อความล้นหน้าต่าง" % (i + 1))
	m._giveup_btn.pressed.emit()
	await _frames(3)
	_check(m.step == DesktopMinigame.Step.SUMMARY, "กดส่งงานตามสภาพ → หน้าสรุป")
	_check(m.score_of(&"fix") == 0, "งานไม่เสร็จ → คะแนนทำงานสำเร็จ 0")
	var fin: Button = m._modal.find_child("Finish", true, false)
	var win: Control = m._modal.get_child(m._modal.get_child_count() - 1)
	var ok := fin != null and fin.is_visible_in_tree()
	if ok:
		var wr := win.get_global_rect()
		var br := fin.get_global_rect()
		ok = wr.encloses(br)
	_check(ok, "บันทึกยาว 12+ ข้อ → ปุ่ม \"ส่งเครื่องคืนลูกค้า\" ยังอยู่ในหน้าต่าง")
	_check(m._modal.find_child("Details", true, false) is ScrollContainer, "รายละเอียดเลื่อนดูได้")
	if OS.get_environment("SHOT") != "":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg(OS.get_environment("SHOT") + "/desktop_giveup_summary.jpg", 0.85)
	# ลองใช้ไม่ผ่าน 2 ครั้ง (อีกงาน) → มีปุ่มทางออก
	var m2: DesktopMinigame = (load(SCENE) as PackedScene).instantiate()
	m2.task = load("res://Resources/Desktop/task_install_chat.tres")
	add_child(m2)
	await _frames(2)
	m2.skip_boot()
	await _frames(1)
	m2.ask(m2.task.ask_best)
	m2._on_check_pressed()
	await _frames(1)
	_check(not m2._giveup_btn.visible, "ลองใช้ไม่ผ่าน 1 ครั้ง → ยังไม่มีปุ่ม (ให้ลองแก้เองก่อน)")
	m2._on_check_pressed()
	await _frames(1)
	_check(m2._giveup_btn.visible, "ลองใช้ไม่ผ่าน 2 ครั้ง → ปุ่ม \"ส่งงานตามสภาพ\" โผล่")
	m.queue_free()
	m2.queue_free()
	print("T DONE fails=", fails)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
