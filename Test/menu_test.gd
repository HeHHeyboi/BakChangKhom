extends Node
## [Claude 10 ต.ค. 2569] ทดสอบเมนูหลัก · หน้าตั้งค่า (GameSettings) · เมนูพัก (Esc)
## เปิด Test/menu_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	var vol0: float = GameSettings.get_value("master_volume")
	var spd0: float = GameSettings.get_value("text_speed")
	var mus0: float = GameSettings.get_value("music_volume")

	# ---- เมนูหลักเป็นโหนด
	var start: Control = load("res://Scene/Start_Scene.tscn").instantiate()
	add_child(start)
	await _frames(3)
	var btns: Array = start.get_node("Menu").get_children().filter(func(b): return b.name != "Continue_Button").map(func(b): return b.text)
	_check(btns == ["เริ่มเกม", "ตั้งค่า", "ออกจากเกม"], "เมนูหลัก: ปุ่ม เริ่มเกม · ตั้งค่า · ออกจากเกม (%s)" % [btns])
	# [0.9.5] เมนูหลักเหลือแค่ปุ่มหลัก · ใบประกาศ/ส่งออกอยู่ในปุ่มถ้วยมุมขวาบน
	var sbtn: Button = start.get_node_or_null("StatsButton")
	var spanel: Control = start.get_node_or_null("StatsPanel")
	_check(sbtn != null and spanel != null and not spanel.visible and not start.get_node("Version").visible and start.get_node_or_null("ExportButton") == null, "เมนูหลักไม่มีป้ายความสำเร็จ/ปุ่มส่งออก/ป้าย Esc · มีปุ่มถ้วย")
	await _shot("main_menu_clean")
	sbtn.pressed.emit()
	await _frames(2)
	var mapp: Node = spanel.find_child("AchievementApp", true, false)
	_check(spanel.visible and mapp != null and mapp.source_profile and (mapp.get_node("Tabs") as Container).get_child_count() == 6 and spanel.find_child("ExportButton", true, false) == null, "กดถ้วย → หน้าความสำเร็จ ทั้งหมด + 5 หมวด (ไม่มีปุ่มส่งออก)")
	_check(mapp.category == -1 and mapp.find_child("Row_A01", true, false) != null and mapp.find_child("Row_E01", true, false) != null, "เปิดมา = ทั้งหมด")
	mapp.select_category(0)
	await _frames(1)
	_check(mapp.find_child("Row_A01", true, false) != null and mapp.find_child("Row_B01", true, false) == null, "แถบซ่อมฮาร์ดแวร์ = เฉพาะหมวดนั้น")
	var cb: Button = spanel.find_child("Close", true, false)
	_check(cb.size.x < 300, "ปุ่มกลับไม่ยืดเต็มแผง (%d)" % cb.size.x)
	mapp.select_category(1)
	await _frames(1)
	_check(mapp.find_child("Row_B01", true, false) != null, "กดแถบ → เปลี่ยนหมวด")
	var tabs: Control = mapp.get_node("Tabs")
	_check(tabs is HBoxContainer and tabs.get_child(5).position.y == tabs.get_child(0).position.y, "แถบหมวด 6 อันอยู่บรรทัดเดียว")
	var rb: Control = mapp.find_child("Row_B01", true, false)
	var desc: Label = rb.find_child("Desc", true, false)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	var hid := not desc.visible
	rb.gui_input.emit(click)
	_check(hid and desc.visible, "แถวโชว์แค่ชื่อ · กดแล้วขึ้นคำอธิบาย")
	await _shot("main_menu_stats")
	sbtn.pressed.emit()
	_check(not spanel.visible, "กดถ้วยอีกครั้ง → ปิดแผง")
	var fbtn: Button = start.get_node_or_null("FormButton")
	var fpanel: Control = start.get_node_or_null("FormPanel")
	fbtn.pressed.emit()
	_check(fpanel.visible and fpanel.find_child("Form_pre", true, false) != null and fpanel.find_child("Form_post", true, false) != null and Playlog.FORM_PRE.begins_with("https://forms.gle/") and (fpanel.find_child("QR", true, false) as TextureRect).texture != null and (fpanel.find_child("Link", true, false) as LinkButton).text.begins_with("forms.gle/"), "ปุ่มคลิปบอร์ด → แผงช่วยทดสอบ (QR + ลิงก์ใต้รูป ก่อน/หลังเล่น)")
	await _shot("main_menu_form")
	fbtn.pressed.emit()
	_check(not fpanel.visible, "กดอีกครั้ง → ปิด")
	# [0.9.0] ดู/ข้ามบทนำ = หน้าเลือกการ์ด 2 ใบ (ไม่ใช่ตัวเลือกในบท) · ทั้งสองทางมีบท
	DialogScene.read_file(Constant.PROLOUGE_TEXT)
	var lines: Array = DialogScene.DialogDict["dialog"]
	_check(lines.size() >= 16 and not lines.any(func(t): return t is ChoiceToken), "บทนำเล่นตรง ๆ ไม่มีตัวเลือกในบท (%d บรรทัด)" % lines.size())
	DialogScene.read_file(start.PROLOGUE_SKIP_TEXT)
	_check((DialogScene.DialogDict["dialog"] as Array).size() >= 1, "บทข้ามบทนำมีบท")
	DialogScene.DialogDict = { "dialog": [] }
	start._show_intro_choice()
	await _frames(2)
	var watch: Button = start.intro_layer.find_child("WatchCard", true, false)
	var skipc: Button = start.intro_layer.find_child("SkipCard", true, false)
	_check(watch != null and skipc != null and watch.has_focus() and (watch.find_child("Head", true, false) as Label).text == "ดูเรื่องราวตั้งแต่ต้น", "หน้าเลือกบทนำ: การ์ดดูเรื่องราว (โฟกัสก่อน) + การ์ดข้าม")
	await _shot("intro_choice")
	start.intro_layer.queue_free()
	start.intro_layer = null
	_check(start.get_node("Menu/Continue_Button").visible == SaveGame.exists(), "ปุ่มเล่นต่อขึ้นเมื่อมีเซฟเท่านั้น")
	_check(start.is_in_group("main_menu") and start.get_node("Khom") is TextureRect and start.get_node("Title").text == "บักช่างขม", "เมนูหลักมีชื่อเกม + ตัวละคร (โหนด)")
	await _shot("main_menu")
	# [10 ต.ค.] เสียง: บัส Music/SFX · เพลงเมนู · ไฟล์ครบ
	_check(AudioServer.get_bus_index("Music") > 0 and AudioServer.get_bus_index("SFX") > 0, "มีบัสเสียง Music / SFX")
	_check(Audio.want_music() == &"menu", "อยู่เมนูหลัก → เพลงเมนู")
	for k in Audio.MUSIC:
		_check(Audio._stream(Audio.MUSIC[k]) != null, "โหลดเพลง %s ได้" % k)
	for k in Audio.SFX:
		_check(Audio._stream(Audio.SFX[k]) != null, "โหลดเสียง %s ได้" % k)
	_check((Audio._stream(Audio.MUSIC[&"village"]) as AudioStreamOggVorbis).loop, "เพลงวนลูป")
	for k in Audio.BEEP:
		_check(Audio._stream("res://Assets/Audio/Sfx/Beep/beep_%s.wav" % k) != null, "รหัสบี๊บ %s" % k)
	start._on_option_button_pressed()
	await _frames(2)
	var sp: SettingsPanel = start.SettingScene
	_check(sp.visible, "กดตั้งค่า → เปิดหน้าตั้งค่า")
	sp.volume.value = 40
	_check(is_equal_approx(GameSettings.get_value("master_volume"), 0.4) and AudioServer.get_bus_volume_db(0) < -7.0, "ลากเสียงรวม → ใช้ทันที (%.1f dB)" % AudioServer.get_bus_volume_db(0))
	sp.volume.value = 0
	_check(AudioServer.is_bus_mute(0), "เสียง 0 → ปิดเสียง")
	sp.music.value = 30
	_check(is_equal_approx(GameSettings.get_value("music_volume"), 0.3) and AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) < -9.0, "ลากเพลง → บัส Music เบาลง")
	sp.text_speed.value = 100
	_check(GameSettings.text_speed() == 100.0 and sp.text_speed_value.text == "เร็ว", "ความเร็วข้อความ → เร็ว")
	var cfg := ConfigFile.new()
	_check(cfg.load(GameSettings.PATH) == OK and float(cfg.get_value("settings", "text_speed")) == 100.0, "เซฟลง user://settings.cfg")
	await _shot("settings")
	sp.get_node("%ResetButton").pressed.emit()
	_check(is_equal_approx(sp.volume.value, 80.0) and GameSettings.text_speed() == 45.0 and not AudioServer.is_bus_mute(0), "ค่าเริ่มต้น → กลับค่าเดิม")
	sp.get_node("%BackButton").pressed.emit()
	_check(not sp.visible, "กลับ → ปิดหน้าตั้งค่า")
	start.queue_free()
	await _frames(2)

	# ---- เมนูพัก
	var pm = get_node("/root/PauseMenu")
	_check(pm != null and pm.can_pause(), "autoload PauseMenu พร้อม · หน้าเล่นปกติพักได้")
	Global.in_minigame = true
	_check(not pm.can_pause(), "อยู่ในมินิเกม → Esc ไม่เปิดเมนูพัก")
	Global.in_minigame = false
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	Input.parse_input_event(esc)
	await _frames(3)
	_check(pm.visible and get_tree().paused, "กด Esc → เปิดเมนูพัก + หยุดเกม")
	await _shot("pause")
	pm._open_settings()
	await _frames(2)
	_check(pm.settings.visible and not pm.panel.visible, "เมนูพัก → ตั้งค่า")
	pm.settings.close()
	_check(pm.panel.visible, "ปิดตั้งค่า → กลับเมนูพัก")
	pm._on_menu_pressed()
	_check(pm.visible and pm.menu_button.text.contains("อีกครั้ง"), "กลับเมนูหลัก ต้องกดยืนยันอีกครั้ง")
	pm.resume()
	_check(not pm.visible and not get_tree().paused, "เล่นต่อ → เกมเดินต่อ")

	# ---- [10 ต.ค.] กระดานเควสต์ย่อ/ขยายได้
	var qb: QuestBoard = EventManager.questboard
	qb.set_collapsed(false)
	qb.ToggleButton.pressed.emit()
	_check(qb.collapsed and not qb.QuestList.visible and qb.ToggleButton.text == "แสดง", "กดซ่อน → กระดานเควสต์ย่อ")
	qb.toggle()
	_check(not qb.collapsed and qb.QuestList.visible, "กดแสดง → กระดานเควสต์กลับมา")

	GameSettings.set_value("master_volume", vol0)
	GameSettings.set_value("text_speed", spd0)
	GameSettings.set_value("music_volume", mus0)
	print("T DONE fails=", fails)
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
	get_viewport().get_texture().get_image().save_jpg(OS.get_environment("SHOT") + "/menu_%s.jpg" % n, 0.8)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
