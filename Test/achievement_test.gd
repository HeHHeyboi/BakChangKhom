extends Node
## [Claude 16 พ.ย. 2569 · 0.7.0 ขั้น J] ใบประกาศ — ข้อมูลครบ · ปลดครั้งเดียว · ไม่หายหลังโหลดเซฟ · โปรไฟล์รวมข้ามเซฟ · แอป
## เปิด Test/achievement_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0


func _ready() -> void:
	await get_tree().process_frame
	var A = Achievements
	A.auto_check = false
	DayLoop.day_skip_seconds = 0.0
	DayLoop.tutorials = false
	DayLoop._reset_run()
	DayLoop.quiet = true
	var e: EconomyConfig = GameState.economy

	# A · ข้อมูล: id ไม่ซ้ำ · เงื่อนไขรู้จัก · มีหมวดความสัมพันธ์ R01–R07 · เริ่มเกมยังไม่ได้สักใบ
	var ids := { }
	var bad := PackedStringArray()
	for a: Achievement in A.all():
		if ids.has(a.id):
			bad.append("ซ้ำ %s" % a.id)
		ids[a.id] = true
		if a.title == "" or a.desc == "" or a.check == &"" or a.target < 1:
			bad.append("ไม่ครบ %s" % a.id)
	_check(bad.is_empty() and A.all().size() >= 39, "ใบประกาศ %d ใบ ข้อมูลครบ %s" % [A.all().size(), ", ".join(bad)])
	for r in ["R01", "R02", "R03", "R04", "R05", "R06", "R07"]:
		_check(ids.has(StringName(r)), "มี %s" % r)
	GameState.reset()
	_check(A.check_all().is_empty(), "เกมใหม่ยังไม่ได้ใบไหน")

	# B · ซ่อมผ่าน → A01 · 3 ดาวแรม 3 ครั้ง → A03 · ปลดครั้งเดียว
	var got: Array[StringName] = []
	A.unlocked.connect(func(a: Achievement) -> void: got.append(a.id))
	GameState.record_repair(&"part_ram", 100, false, -1, 2)
	A.check_all()
	_check(A.has(&"A01") and got.count(&"A01") == 1, "ซ่อมผ่านครั้งแรก → A01")
	GameState.record_repair(&"part_ram", 100, false, -1, 2)
	GameState.record_repair(&"part_ram", 100, false, -1, 2)
	A.check_all()
	A.check_all()
	_check(A.has(&"A03") and got.count(&"A03") == 1 and got.count(&"A01") == 1, "3 ดาวแรม 3 ครั้ง → A03 · ได้ครั้งเดียว")
	_check(int(GameState.achievements[&"A01" if GameState.achievements.has(&"A01") else "A01"].month) >= 1, "จดเดือนที่ได้")

	# C · อ่านค่าจาก GameState: R05 (group_fair_count) · R01/R02 · D04 · B07 · ไม่ง้อคำใบ้
	GameState.group_fair_count = 5
	GameState.npc_affinity[&"amnuay"] = 45
	for id in [&"min", &"teacher", &"headman", &"fai", &"bew"]:
		GameState.npc_affinity[id] = 65
	GameState.event_state["scam_safe"] = 3
	GameState.event_state["fake_reported"] = 3
	GameState.event_state["storm_safe"] = true
	A.check_all()
	for id in [&"R05", &"R01", &"R02", &"D04", &"B07", &"D01"]:
		_check(A.has(id), "ได้ %s" % id)
	_check(not A.has(&"R04"), "R04 ยังไม่ได้ (ต้นกล้า/แพรวยังไม่สนิท)")
	var p: Vector2i = A.progress(A.by_id(&"R04"))
	_check(p == Vector2i(1, 3), "ความคืบหน้า R04 = 1/3 (บิว)")

	# D · เดือน/ปี: B01 · B03 · B04 (ครบ 12 ไม่ค้าง) · H03
	GameState.month_results.clear()
	for m in range(1, 13):
		GameState.month_results.append({ "m": m, "reached": true, "over": m == 3, "debt": 0 })
	A.check_all()
	for id in [&"B01", &"B02", &"B03", &"B04", &"H03"]:
		_check(A.has(id), "ได้ %s" % id)

	# E · เซฟ/โหลด ไม่หาย · โปรไฟล์รวมข้ามเซฟ
	var n_before: int = A.count()
	var pc_before: int = A.profile_count() # [0.8.0] เทสต์ (quiet) ไม่เขียนโปรไฟล์ → เทียบก่อน/หลัง reset แทน (เครื่องใหม่ไม่มีโปรไฟล์)
	SaveGame.allow_in_tests = true
	_check(SaveGame.save(), "เซฟได้")
	GameState.reset()
	_check(A.count() == 0, "เกมใหม่ (reset) ใบในเซฟนี้ = 0")
	_check(A.profile_count() == pc_before, "โปรไฟล์ไม่ถูกล้างตอนเริ่มเกมใหม่ (%d)" % A.profile_count())
	SaveGame.load_into()
	_check(A.count() == n_before and A.has(&"R05"), "โหลดเซฟ ใบประกาศกลับมาครบ (%d)" % A.count())
	got.clear()
	A.check_all()
	_check(got.is_empty(), "โหลดแล้วไม่ปลดซ้ำ")

	# F · แอป
	var app: Node = load("res://Scene/UI/achievement_app.tscn").instantiate()
	add_child(app)
	await get_tree().process_frame
	app.refresh(true)
	_check(app.find_child("Row_A01", true, false) != null and app.find_child("Row_H01", true, false) != null, "แอปใบประกาศขึ้นทุกใบ")
	var v: Dictionary = A.view()
	var h01: Dictionary = (v.rows as Array).filter(func(r: Dictionary) -> bool: return r.id == "H01")[0]
	_check(h01.title == "???", "ใบลับยังไม่ได้ = ???")
	app.queue_free()

	A.auto_check = true
	DayLoop.quiet = false
	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL ", msg)
	else:
		print("ok   ", msg)
