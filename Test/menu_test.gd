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
