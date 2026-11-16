extends Node
## [0.9.0 ขั้น 0 + A] ความสำเร็จอยู่ในเมนูพักที่เดียว · รหัสผู้ทดสอบ · CSV มี tester_id/game_version · session.csv · ส่งออก zip · เซฟ v10
var fails := 0


func _ready() -> void:
	DayLoop.quiet = true
	var gs := GameState
	var PL := get_node(^"/root/Playlog")
	# เก็บ playlog เดิมของเครื่องไว้ก่อน
	var bak := "user://playlog_bak_test"
	if DirAccess.dir_exists_absolute(Playlog.DIR):
		DirAccess.rename_absolute(Playlog.DIR, bak)

	# 0 · ของตกแต่ง/ใบประกาศในห้องและคอมขมออกแล้ว
	var room := FileAccess.get_file_as_string("res://Scene/Location/Room.tscn")
	_check(not room.contains("DecorShelf") and not room.contains("WallCertificates") and not room.contains("DecorCeiling"), "Room.tscn ไม่มีชั้น/กรอบ/ธง")
	_check(not FileAccess.get_file_as_string("res://Scripts/Room/shop_pc.gd").contains("ACH_APP"), "คอมขมไม่มีแอปใบประกาศ")
	_check(not FileAccess.file_exists("res://Scripts/Room/decor_shelf.gd") and not FileAccess.file_exists("res://Scripts/Room/wall_certificates.gd"), "ลบสคริปต์ชั้น/กรอบแล้ว")

	# A · รหัสผู้ทดสอบ
	_check(Playlog.normalize_id(" t01 ") == "T01" and Playlog.normalize_id("AB123") == "AB123", "รหัส t01 → T01")
	_check(Playlog.normalize_id("") == "" and Playlog.normalize_id("01") == "" and Playlog.normalize_id("T-1") == "" and Playlog.normalize_id("ABCD1") == "", "รหัสผิดแบบ = ว่าง")
	gs.reset()
	gs.tester_id = "T07"
	gs.reset()
	_check(gs.tester_id == "T07" and gs.playtime_sec == 0.0, "เริ่มเกมใหม่ (reset) รหัสยังอยู่ · เวลาเล่นเริ่ม 0")

	# B · CSV
	Playlog.append("unit.csv", ["a", "b"], [1, "x,y"])
	var rows := Playlog.read_rows("unit.csv")
	_check(rows.size() == 2 and ",".join(rows[0]) == "time,tester_id,game_version,a,b", "หัวตาราง time · tester_id · game_version")
	_check(rows[1][1] == "T07" and rows[1][2] == Playlog.game_version() and rows[1][4] == "x y", "แถวมีรหัส + เวอร์ชัน · , ในข้อความถูกแทน")
	var old := FileAccess.open(Playlog.DIR.path_join("old.csv"), FileAccess.WRITE)
	old.store_line("time,a")
	old.store_line("2026,1")
	old.close()
	Playlog.append("old.csv", ["a"], [2])
	_check(Playlog.read_rows("old.csv").size() == 2 and DirAccess.get_files_at(Playlog.DIR).has("old.csv") and Array(DirAccess.get_files_at(Playlog.DIR)).any(func(f: String) -> bool: return f.begins_with("old_old_")), "หัวตารางเก่า → ย้ายไฟล์เก่าแยก")
	EventDirector.append_csv({ "ch": 3, "day": 2, "id": &"cal_test", "choice": "ไป,ช่วย" })
	var ev := Playlog.read_rows("events.csv")
	_check(ev.size() == 2 and ev[1][1] == "T07" and ev[1][5] == "cal_test", "events.csv ผ่าน Playlog")
	RankExam.append_csv({ "ch": 2, "day": 1, "target": 1, "attempt": 1, "qid": "q1", "part": "ram", "chosen": "ก", "correct": true })
	_check(Playlog.read_rows("learn_log.csv").size() == 2, "learn_log.csv อยู่ใน playlog")
	ScenarioBook.append_csv({ "ch": 2, "day": 1, "id": "s1", "part": "ram", "first_try": true, "wrong": 0, "skipped": 0, "did_optional": 1, "score": 90, "gave_up": false })
	_check(Playlog.read_rows("scenario_log.csv").size() == 2, "scenario_log.csv อยู่ใน playlog")

	# C · session
	PL.end_session(&"menu")
	PL._begin()
	PL._seg_sec = 125.0
	PL.end_session(&"menu")
	_check(not FileAccess.file_exists(Playlog.DIR.path_join("session.csv")), "เทสต์/บอท (quiet) ไม่จด session")
	Playlog.allow_in_tests = true
	gs.playtime_sec = 3600.0
	PL._begin()
	PL._seg_sec = 125.0
	PL.end_session(&"menu")
	var ss := Playlog.read_rows("session.csv")
	_check(ss.size() == 2 and ss[1][4] == "125" and ss[1][5] == "menu" and ss[1][9] == "3600", "session.csv: วินาที · เหตุ · เวลาสะสม")
	PL._begin()
	PL._seg_sec = 0.4
	PL.end_session(&"quit")
	_check(Playlog.read_rows("session.csv").size() == 2, "สั้นกว่า 1 วิไม่จด")
	PL._in_game = false

	# D · ส่งออก zip
	var dest := ProjectSettings.globalize_path("user://zip_test")
	DirAccess.make_dir_recursive_absolute(dest)
	var r: Dictionary = PL.export_zip(dest)
	_check(r.ok and FileAccess.file_exists(String(r.path)) and String(r.path).get_file().begins_with("BakChangKhom_T07_"), "ส่งออก zip ชื่อมีรหัส")
	var zr := ZIPReader.new()
	if zr.open(String(r.path)) == OK:
		var files := zr.get_files()
		_check(files.has("playlog/events.csv") and files.has("playlog/session.csv") and files.has("info.txt"), "zip มี playlog + info.txt")
		_check(zr.read_file("info.txt").get_string_from_utf8().contains("tester_id=T07"), "info.txt มีรหัส")
		zr.close()
		DirAccess.remove_absolute(String(r.path))
	else:
		_check(false, "เปิด zip ได้")
	Playlog.allow_in_tests = false

	# E · เซฟ v10
	SaveGame.allow_in_tests = true
	gs.reset()
	gs.tester_id = "T09"
	gs.playtime_sec = 777.0
	gs.form_pre_opened = true
	_check(SaveGame.VERSION == 10 and SaveGame.save(), "บันทึกเป็น VERSION 10")
	_check(SaveGame.saved_tester_id() == "T09", "saved_tester_id() บอกรหัส (เมนูหลัก)")
	gs.tester_id = ""
	gs.playtime_sec = 0.0
	gs.form_pre_opened = false
	SaveGame.load_into()
	_check(gs.tester_id == "T09" and int(gs.playtime_sec) == 777 and gs.form_pre_opened and not gs.form_post_opened, "โหลด v10 ได้รหัส · เวลาเล่น · ฟอร์ม")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveGame.PATH))
	d["version"] = 9
	(d.game as Dictionary).erase("tester_id")
	(d.game as Dictionary).erase("playtime_sec")
	var f := FileAccess.open(SaveGame.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	_check(not SaveGame.is_old_version() and SaveGame.load_into() >= 0 and gs.tester_id == "" and gs.playtime_sec == 0.0, "เซฟ v9 ยังโหลดได้ · รหัสว่าง")
	SaveGame.clear()
	SaveGame.allow_in_tests = false

	# F · หน้าความสำเร็จในเมนูพัก + ของขวัญท้ายหน้า
	gs.reset()
	gs.gifts_received = { "amnuay": "gift_amnuay" }
	var pm := get_node(^"/root/PauseMenu")
	_check(pm.ach_button != null and pm.export_button != null and pm.ach_button.text == "ความสำเร็จ", "เมนูพักมีปุ่มความสำเร็จ + ส่งออก")
	pm.open()
	pm.open_achievements()
	await get_tree().process_frame
	_check(pm.ach_page.visible and not pm.panel.visible, "เปิดหน้าความสำเร็จ")
	_check(pm.ach_page.find_child("Row_A01", true, false) != null and pm.ach_page.find_child("GiftHead", true, false) != null and pm.ach_page.find_child("Row_gift_amnuay", true, false) != null, "ใบประกาศ + ของขวัญท้ายหน้า")
	_check(pm.ach_page.find_child("Pin", true, false) == null, "ไม่มีปุ่มติดผนัง")
	pm.close_achievements()
	_check(not pm.ach_page.visible and pm.panel.visible, "กลับเมนูพัก")
	pm.resume()

	# G · [ขั้น B] ฟอร์มก่อน/หลังเล่น
	PL.open_urls = false
	var cfg: TesterConfig = PL.config
	var old_pre := cfg.pre_form_url
	var old_post := cfg.post_form_url
	_check(TesterConfig.fill("https://x/viewform?entry.1={id}", "T07") == "https://x/viewform?entry.1=T07", "ลิงก์ pre-filled ใส่รหัส")
	gs.reset()
	gs.tester_id = "T07"
	var got: Array = []
	cfg.pre_form_url = ""
	PL.show_pre_form(func(opened: bool) -> void: got.append(opened))
	_check(got == [false] and not PL.modal_open(), "ไม่มีลิงก์ก่อนเล่น = ข้ามหน้า")
	cfg.pre_form_url = "https://x/pre?entry.1={id}"
	PL.show_pre_form(func(opened: bool) -> void: got.append(opened))
	var done_b := PL._ask_layer.find_child("Done", true, false) as Button
	_check(PL.modal_open() and done_b.disabled, "หน้าก่อนเล่น: ต้องเปิดฟอร์มก่อนถึงกดเริ่มได้")
	(PL._ask_layer.find_child("Open", true, false) as Button).pressed.emit()
	_check(PL.last_opened_url == "https://x/pre?entry.1=T07" and not done_b.disabled, "กดเปิด → ลิงก์มีรหัส · ปุ่มเริ่มกดได้")
	done_b.pressed.emit()
	_check(got == [false, true] and not PL.modal_open(), "ทำแล้ว → เริ่มเกม (opened = true)")
	_check(not PL.post_ready(), "ยังไม่ครบ 3 เดือน = ยังไม่ถึงหลังเล่น")
	for i in 3:
		gs.month_results.append({ "m": i + 1, "reached": true })
	_check(PL.post_ready() and not PL._safe_moment(), "ครบ 3 เดือน = ถึงหลังเล่น · ในซีนเทสต์ไม่ขึ้นเอง")
	cfg.post_form_url = "https://x/post?entry.2={id}"
	PL.show_post_form()
	_check(PL.modal_open() and get_tree().paused and PL._ask_layer.find_child("Export", true, false) != null, "ป๊อปอัปหลังเล่น: หยุดเกม · มีปุ่มส่งออก")
	(PL._ask_layer.find_child("Open", true, false) as Button).pressed.emit()
	_check(PL.last_opened_url == "https://x/post?entry.2=T07" and gs.form_post_opened and not PL.post_ready(), "เปิดฟอร์มหลังเล่น → จดว่าเปิดแล้ว")
	(PL._ask_layer.find_child("Close", true, false) as Button).pressed.emit()
	_check(not PL.modal_open() and not get_tree().paused, "เล่นต่อ → ปิดป๊อปอัป · เกมเดินต่อ")
	pm.open()
	_check(not pm.post_button.visible, "ไม่ใช่บิลด์ผู้ทดสอบ = ไม่มีปุ่มหลังเล่นในเมนูพัก")
	pm.resume()
	cfg.pre_form_url = old_pre
	cfg.post_form_url = old_post
	PL._post_snoozed = false
	PL.open_urls = true

	# คืน playlog เดิม
	for fn in DirAccess.get_files_at(Playlog.DIR):
		DirAccess.remove_absolute(Playlog.DIR.path_join(fn))
	DirAccess.remove_absolute(Playlog.DIR)
	if DirAccess.dir_exists_absolute(bak):
		DirAccess.rename_absolute(bak, Playlog.DIR)
	DayLoop.quiet = false
	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _check(ok: bool, msg: String) -> void:
	if ok:
		print("ok   ", msg)
	else:
		fails += 1
		print("FAIL ", msg)
