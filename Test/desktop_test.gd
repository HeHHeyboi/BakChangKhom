extends Node
## [Claude 9 ต.ค. 2569] ทดสอบขมOS (งานบนจอ Lv1): 1-1 ลงโปรแกรม · 1-2 ลบไฟล์ซ้ำ · 1-3 ถอนโปรแกรมโฆษณา · ส่งงานลูกค้าเข้า GameState
## เปิด Test/desktop_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

const SCENE := "res://Scene/MiniGame/Desktop/desktop_window.tscn"
var fails := 0


func _ready() -> void:
	await get_tree().process_frame

	# ---- ข้อมูลครบทุกไฟล์
	for f in DirAccess.get_files_at("res://Resources/Desktop"):
		if f.ends_with(".tres"):
			var t: DesktopTask = load("res://Resources/Desktop/" + f)
			_check(t != null and t.problems().is_empty(), "DesktopTask %s ครบ %s" % [f, t.problems() if t else "โหลดไม่ได้"])
	for c in ["lv1_yai_chat", "lv1_headman_chat", "lv1_amnuay_space", "lv1_min_space", "lv1_kid_ads", "lv1_director_ads",
			"lv1_min_hang", "lv1_teacher_printer", "lv1_headman_sound", "lv1_girl_wifi", "lv1_yai_backup", "lv1_amnuay_startup", "lv1_director_update"]:
		var cc: CustomerCase = load("res://Resources/Customers/%s.tres" % c)
		_check(cc.level == 1 and cc.problems().is_empty(), "ลูกค้า %s ครบ %s" % [c, cc.problems()])
	var pool: Array = DayLoop.random_pool
	_check(pool.filter(func(c): return c.level == 1).size() == 13, "random_pool มีงาน Lv1 13 งาน (1-1 … 1-10)")

	# ---- [10 ต.ค.] OS อยู่ในจอบนโต๊ะ (framed) + จอบูตในโหนดเดียวกัน
	var bm: DesktopMinigame = (load(SCENE) as PackedScene).instantiate()
	bm.task = load("res://Resources/Desktop/task_install_chat.tres")
	add_child(bm)
	await _wait(0.9)
	_check(bm.framed and bm._ui.scale.x < 0.9 and bm._root.has_node("Desk") and bm._ui.clip_contents, "OS แสดงในจอมอนิเตอร์บนโต๊ะ (ย่อ + ตัดขอบ)")
	_check(bm.is_booting and is_instance_valid(bm._boot) and not bm._modal.visible, "เริ่มด้วยจอบูต · ยังไม่ถามลูกค้า")
	await _shot("boot")
	await _wait(3.2)
	_check(not bm.is_booting and bm._modal.visible, "บูตเสร็จเอง → ขึ้นหน้าต่างถามลูกค้า")
	await _shot("framed_ask")
	bm.queue_free()
	await _frames(2)

	# ---- 1-1 ลงโปรแกรม: ตกทั้งสองกับดัก แล้วถอนแก้
	var m := await _open("task_install_chat")
	_check(m.step == DesktopMinigame.Step.LISTEN and m._modal.visible, "เริ่มที่ขั้นฟัง (หน้าต่างถามลูกค้า)")
	_check(m.check() != "", "ยังไม่ฟัง = เช็กไม่ได้")
	var ans := m.ask(m.task.ask_best)
	_check(m.step == DesktopMinigame.Step.WORK and ans.contains("พูดคุย") and m.score_of(&"listen") == 20, "ถามถูก → ได้คำใบ้ · ฟังเต็ม 20")
	var fake: Dictionary = m.click_download_ad()
	_check(m.score_of(&"safety") == 20 and m.visible_files("ดาวน์โหลด").has(fake), "กดปุ่มโฆษณา → ได้ไฟล์ปลอม · ปลอดภัย −10")
	m.open_browser()
	m._browser_show("official")
	m.download_official()
	var setup := m.find_file("setup_พูดคุย.exe")
	_check(setup.kind == "installer", "โหลดจากเว็บทางการได้ตัวติดตั้งจริง")
	m.open_file(setup)
	_check(m._windows.has("wizard"), "เปิดตัวติดตั้ง → วิซาร์ด")
	var free0: int = m.free_mb
	m.install_app(true)
	_check(m.app_installed and m.has_adware() and m.score_of(&"safety") == 10, "ไม่เอาติ๊กออก → โปรแกรมแถมติดมา · ปลอดภัย −10")
	_check(m.free_mb == free0 - 350 - DesktopMinigame.ADWARE_SIZE_MB, "พื้นที่ลดตามขนาดโปรแกรม")
	var why := m.check()
	_check(why.contains("โฆษณา") and m.score_of(&"fix") == 30, "เช็ก: ยังมีโปรแกรมแถม → ไม่ผ่าน · ทำงาน −10")
	_check(m.uninstall(m.find_program("ลดราคาเด้งไว")) and not m.has_adware(), "ถอนโปรแกรมแถมในหน้าตั้งค่า")
	_check(not m.uninstall(m.find_program("ไดรเวอร์เสียง")) and m.score_of(&"safety") == 0, "ถอนของระบบไม่ได้ · ปลอดภัย −10")
	_check(m.check() == "" and m.step == DesktopMinigame.Step.EXPLAIN, "เช็กผ่าน → ขั้นบอก")
	m.explain(m.task.explain_best)
	_check(m.step == DesktopMinigame.Step.SUMMARY and m.final_score() == 60, "สรุป 100 −30 ปลอดภัย −10 ทำงาน = 60 (ได้ %d)" % m.final_score())
	m.open_settings()
	m.open_trash()
	m.open_explorer("รูปภาพ")
	m._spawn_popup()
	await _frames(2)
	_check(m._windows.has("settings") and m._windows.has("trash") and m._windows.has("explorer"), "เปิดหน้าต่าง ตั้งค่า/ถังขยะ/ไฟล์ ได้")
	m.queue_free()
	await _frames(2)

	# ---- 1-2 ลบไฟล์ซ้ำ
	m = await _open("task_free_space_photos")
	m.ask(2)
	_check(m.score_of(&"listen") == 10, "ถามไม่ตรง → ฟัง −10")
	_check(not m.delete_file(m.find_file("ขมOS")) and m.score_of(&"safety") == 15, "ลบโฟลเดอร์ระบบ → ปิ๊บคว้าไว้ · ปลอดภัย −15")
	_check(m.delete_file(m.find_file("รูปงานบวช")) and m.score_of(&"safety") == 5, "ลบรูปตัวจริงของลูกค้า → ปลอดภัย −10")
	_check(m.check().contains("ถังขยะ"), "เช็ก: ของลูกค้าอยู่ในถังขยะ → ไม่ผ่าน")
	m.restore_file(m.find_file("รูปงานบวช"))
	m.open_file(m.find_file("รูปงานบวช - สำเนา"))
	m.delete_file(m.find_file("รูปงานบวช - สำเนา"))
	m.delete_file(m.find_file("รูปงานบวช - สำเนา (2)"))
	m.delete_file(m.find_file("รูปงานบวช.zip"))
	_check(m.score_of(&"listen") == 4, "ลบไฟล์ซ้ำโดยไม่เปิดดู 2 ไฟล์ → ฟัง −3 ×2")
	_check(m.check().contains("ล้างถังขยะ"), "ยังไม่ล้างถังขยะ → พื้นที่ยังไม่พอ")
	var freed := m.empty_trash()
	_check(freed == 3500 and m.free_mb == 3800 and not m.lost_user_file, "ล้างถังขยะ → ได้ 3.5 GB คืน")
	_check(m.check() == "", "เช็กผ่าน (เช็กไม่ผ่าน 2 ครั้ง)")
	m.explain(1)
	_check(m.final_score() == 100 - 20 - 25 - 16 - 10, "คะแนน 1-2 = %d" % m.final_score())
	m.queue_free()
	await _frames(2)

	# ลบของลูกค้าแล้วล้างถัง = หายถาวร
	m = await _open("task_free_space_photos")
	m.ask(0)
	m.delete_file(m.find_file("บัญชีสวนยาง.doc"))
	m.empty_trash()
	_check(m.lost_user_file and m.repair_damaged(), "ล้างถังขยะทั้งที่มีของลูกค้า → ของหาย (ซ่อมเสีย)")
	m.queue_free()
	await _frames(2)

	# ---- 1-3 ถอนโปรแกรมโฆษณา
	m = await _open("task_uninstall_ads_kid")
	m.ask(0)
	var ad := m.find_program("ลดราคาเด้งไว")
	m._on_popup_timer()
	await _frames(1)
	_check(m._windows.keys().any(func(k): return String(k).begins_with("ad")), "มีโปรแกรมโฆษณา → หน้าต่างโฆษณาเด้ง")
	m.click_ad_popup()
	_check(m.score_of(&"safety") == 25, "คลิกในโฆษณา → ปลอดภัย −5")
	m.remove_icon(ad)
	_check(ad.installed and not ad.icon and m.check().contains("ไอคอน"), "ลบแค่ไอคอน → โฆษณายังเด้ง เช็กไม่ผ่าน")
	m.uninstall(ad)
	await _frames(2)
	_check(not m._windows.keys().any(func(k): return String(k).begins_with("ad") and is_instance_valid(m._windows[k])), "ถอนแล้วหน้าต่างโฆษณาปิดหมด")
	_check(m.check() == "", "ถอนผ่านหน้าตั้งค่า → เช็กผ่าน")
	m.queue_free()
	await _frames(2)

	# ---- งานลูกค้าจริง: DayLoop เปิด → ส่งงาน → เงินเข้า
	var cc: CustomerCase = load("res://Resources/Customers/lv1_yai_chat.tres")
	var money0 := GameState.money
	m = (load(SCENE) as PackedScene).instantiate()
	m.set_meta("work_order", cc)
	SceneRouter.push_node(m)
	await _frames(2)
	m.skip_boot()
	await get_tree().create_timer(1.4).timeout
	_check(m.task == cc.desktop_task and m.customer_name == "ยาย", "work_order → ใช้ DesktopTask ของลูกค้า")
	m.ask(m.task.ask_best)
	m.download_official()
	m.install_app(false)
	_check(m.check() == "", "ลงโปรแกรมถูกวิธี เช็กผ่าน")
	m.explain(m.task.explain_best)
	_check(m.final_score() == 100, "เต็ม 100")
	m.finish()
	await get_tree().create_timer(1.4).timeout
	var fee: int = GameState.economy.fee_for_level(1)
	_check(GameState.money - money0 == fee + GameState.economy.tip_three_star, "ส่งงาน Lv1 ⭐⭐⭐ ได้ ฿%d (ได้ %d)" % [fee + GameState.economy.tip_three_star, GameState.money - money0])
	_check(not is_instance_valid(m), "มินิเกมปิดตัวเอง")

	# ---- คอมของขมในร้าน (เล่นอิสระ) · ฉากบ้านยาย/ร้านใหม่
	var home: Control = load("res://Scene/Location/Home.tscn").instantiate()
	add_child(home)
	await _frames(1)
	_check(home.has_node("Grandma") and home.has_node("Door") and home.has_node("Door/caution") and home.has_node("MapPlaceHolder") and not home.has_node("PC"),
		"ในบ้านขมกับยาย: ยาย · ประตูหน้าบ้าน · แผนที่")
	_check(home.get_node("Door") is LocationDoor and home.get_node("Door").target == SceneRouter.VILLAGE, "ประตูในบ้าน → หน้าบ้าน")
	home.queue_free()
	var vil: Control = load("res://Scene/Location/Village.tscn").instantiate()
	add_child(vil)
	await _frames(1)
	_check(vil.get_node("ShopSign").target == SceneRouter.ROOM and vil.get_node("HomeDoor").target == SceneRouter.HOME and vil.has_node("ShopSign/caution") and not vil.has_node("Grandma"),
		"หน้าบ้าน: ป้าย → ร้าน · เรือน → กลับบ้าน")
	vil.queue_free()
	var room: Control = load("res://Scene/Location/Room.tscn").instantiate()
	add_child(room)
	await _frames(1)
	var pc = room.get_node("PC")
	_check(pc is SceneHotspot and room.get_node("Door") is SceneHotspot and room.has_node("Event"), "ร้านฉากใหม่: คอมของขม · ทางออก · จุดเควสต์")
	_check(SceneRouter.LOCATIONS.has(SceneRouter.VILLAGE) and ResourceLoader.exists(SceneRouter.LOCATIONS[SceneRouter.VILLAGE]), "SceneRouter มีฉากหน้าบ้าน")
	var fm: DesktopMinigame = pc.open_pc()
	_check(fm != null and Global.in_minigame, "กดคอมในร้าน → เปิดขมOS")
	_check(pc.open_pc() == null, "เปิดซ้ำระหว่างอยู่ในคอมไม่ได้")
	while is_instance_valid(fm) and not fm.is_booting:
		await _frames(1)
	await _wait(0.8)
	await _shot("shop_pc_boot")
	fm.skip_boot()
	await get_tree().create_timer(1.4).timeout
	await _shot("shop_pc")
	_check(fm.free_mode and fm.step == DesktopMinigame.Step.WORK and not fm._modal.visible and fm.app_installed, "เล่นอิสระ: ไม่มีขั้นฟัง · มีแอปพูดคุยในเครื่อง")
	var money1 := GameState.money
	fm.delete_file(fm.find_file("รูปกับยาย.jpg"))
	fm.empty_trash()
	_check(fm.score_of(&"safety") == 30 and fm.free_mb > 120000, "ลบไฟล์ตัวเองได้ ไม่หักคะแนน")
	fm.shut_down()
	await _frames(3)
	_check(not is_instance_valid(fm) and not Global.in_minigame and GameState.money == money1, "ปิดเครื่อง → กลับร้าน ไม่คิดเงิน")
	room.queue_free()

	print("T DONE fails=", fails)
	get_tree().quit()


func _open(task_name: String) -> DesktopMinigame:
	var m: DesktopMinigame = (load(SCENE) as PackedScene).instantiate()
	m.task = load("res://Resources/Desktop/%s.tres" % task_name)
	add_child(m)
	await _frames(2)
	m.skip_boot()
	await _frames(1)
	return m


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


## SHOT=<โฟลเดอร์> → เซฟภาพหน้าจอ (ต้องรันแบบมีหน้าจอ ไม่ใช่ --headless)
func _shot(n: String) -> void:
	if OS.get_environment("SHOT") == "":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_jpg(OS.get_environment("SHOT") + "/desktop_%s.jpg" % n, 0.8)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
