extends Node
## [0.9.0] ความสำเร็จอยู่ในเมนูพักที่เดียว · CSV มี game_version · session.csv · ส่งออก zip · เซฟ v10 (playtime) · ไม่มีหน้ารหัส/ฟอร์มในเกม
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

	# A · ไม่มีระบบผู้ทดสอบ/ฟอร์มในเกม (ผู้ใช้ 16 พ.ย.)
	_check(not ResourceLoader.exists("res://Resources/tester_config.tres") and not PL.has_method(&"show_post_form") and not PL.has_method(&"ask_tester_id"), "ไม่มีหน้ารหัสผู้ทดสอบ/แบบทดสอบในเกม")
	gs.reset()
	_check(gs.playtime_sec == 0.0, "เริ่มเกมใหม่ เวลาเล่นเริ่ม 0")

	# B · CSV
	Playlog.append("unit.csv", ["a", "b"], [1, "x,y"])
	var rows := Playlog.read_rows("unit.csv")
	_check(rows.size() == 2 and ",".join(rows[0]) == "time,game_version,a,b", "หัวตาราง time · game_version")
	_check(rows[1][1] == Playlog.game_version() and rows[1][3] == "x y", "แถวมีเวอร์ชัน · , ในข้อความถูกแทน")
	var old := FileAccess.open(Playlog.DIR.path_join("old.csv"), FileAccess.WRITE)
	old.store_line("time,a")
	old.store_line("2026,1")
	old.close()
	Playlog.append("old.csv", ["a"], [2])
	_check(Playlog.read_rows("old.csv").size() == 2 and DirAccess.get_files_at(Playlog.DIR).has("old.csv") and Array(DirAccess.get_files_at(Playlog.DIR)).any(func(f: String) -> bool: return f.begins_with("old_old_")), "หัวตารางเก่า → ย้ายไฟล์เก่าแยก")
	EventDirector.append_csv({ "ch": 3, "day": 2, "id": &"cal_test", "choice": "ไป,ช่วย" })
	var ev := Playlog.read_rows("events.csv")
	_check(ev.size() == 2 and ev[1][4] == "cal_test", "events.csv ผ่าน Playlog")
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
	_check(ss.size() == 2 and ss[1][3] == "125" and ss[1][4] == "menu" and ss[1][8] == "3600", "session.csv: วินาที · เหตุ · เวลาสะสม")
	PL._begin()
	PL._seg_sec = 0.4
	PL.end_session(&"quit")
	_check(Playlog.read_rows("session.csv").size() == 2, "สั้นกว่า 1 วิไม่จด")
	PL._in_game = false

	# D · ส่งออก zip
	var dest := ProjectSettings.globalize_path("user://zip_test")
	DirAccess.make_dir_recursive_absolute(dest)
	var r: Dictionary = PL.export_zip(dest)
	_check(r.ok and FileAccess.file_exists(String(r.path)) and String(r.path).get_file().begins_with("BakChangKhom_playlog_"), "ส่งออก zip")
	var zr := ZIPReader.new()
	if zr.open(String(r.path)) == OK:
		var files := zr.get_files()
		_check(files.has("playlog/events.csv") and files.has("playlog/session.csv") and files.has("info.txt"), "zip มี playlog + info.txt")
		_check(zr.read_file("info.txt").get_string_from_utf8().contains("game_version=" + Playlog.game_version()), "info.txt มีเวอร์ชัน")
		zr.close()
		DirAccess.remove_absolute(String(r.path))
	else:
		_check(false, "เปิด zip ได้")
	Playlog.allow_in_tests = false

	# E · เซฟ v10
	SaveGame.allow_in_tests = true
	gs.reset()
	gs.playtime_sec = 777.0
	_check(SaveGame.VERSION >= 10 and SaveGame.save(), "บันทึกเป็น VERSION %d (≥ 10 มี playtime)" % SaveGame.VERSION)
	gs.playtime_sec = 0.0
	SaveGame.load_into()
	_check(int(gs.playtime_sec) == 777, "โหลด v10 ได้เวลาเล่น")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveGame.PATH))
	d["version"] = 9
	(d.game as Dictionary).erase("playtime_sec")
	(d.game as Dictionary).erase("city") # [0.9.5] v11
	var f := FileAccess.open(SaveGame.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	_check(not SaveGame.is_old_version() and SaveGame.load_into() >= 0 and gs.playtime_sec == 0.0 and int(gs.city.visits) == 0, "เซฟ v9 ยังโหลดได้ (เมือง = ยังไม่เคยไป)")
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
