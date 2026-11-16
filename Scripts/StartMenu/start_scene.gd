extends Control
## เมนูหลัก (เริ่มเกม · ตั้งค่า · ออกจากเกม) — [Claude 10 ต.ค. 2569] สร้างใหม่เป็นโหนดทั้งหมด (เดิมเป็นภาพวาด)
## ปุ่ม/ตัวละคร/หัวเรื่อง แก้ใน Start_Scene.tscn ได้ · หน้าตั้งค่า = Scene/UI/settings_panel.tscn

@export var SettingScene: SettingsPanel
@export var tutorial: TextureRect
var showTutorial = false
var _confirm_new := false
## ข้อความตัวเลือกใน Prolouge.txt ที่แปลว่า "ข้ามบทนำ" (ต้องตรงกับในไฟล์บททุกตัวอักษร)
const SKIP_INTRO_CHOICE := "ข้ามบทนำ ไปเปิดร้านเลย"


func _ready() -> void:
	Global.on_start = true
	EventManager.hideUI()
	EventManager.on_tutorial_finish.connect(tutorial_end)
	EventManager.on_dialog_end.connect(dialog_end)
	# เวอร์ชันเว็บปิดหน้าต่างเองไม่ได้ → ซ่อนปุ่มออก
	$Menu/Quit_Button.visible = not OS.has_feature("web")
	# [10 ต.ค.] มีเซฟ → ปุ่ม "เล่นต่อ" (บอกกะ + เงิน)
	var info := SaveGame.info()
	$Menu/Continue_Button.visible = not info.is_empty()
	if not info.is_empty():
		$Menu/Continue_Button.text = "เล่นต่อ (%s · ฿%d)" % [TimeSystem.shift_label(int(info.shift)), info.money]
	elif SaveGame.is_old_version():
		# [0.2.0-G] เซฟจาก 0.1.x ใช้ไม่ได้ (ระบบเวลาเปลี่ยน) → บอกแทนการซ่อนเงียบ ๆ
		$Menu/Continue_Button.visible = true
		$Menu/Continue_Button.disabled = true
		$Menu/Continue_Button.text = "เซฟเวอร์ชันเก่าใช้ไม่ได้ · เริ่มใหม่"
		$Menu/Continue_Button.tooltip_text = "ระบบเวลาในเกมเปลี่ยนแล้ว เซฟจากเวอร์ชัน 0.1.x จึงโหลดไม่ได้"
	# [0.7.0] ใบประกาศรวมทุกเซฟ (user://achievements.cfg)
	var ach := get_node_or_null(^"/root/Achievements")
	if ach and ach.profile_count() > 0:
		var al := Label.new()
		al.name = "AchievementCount"
		al.text = "ใบประกาศที่เคยได้ (ทุกเซฟ) %d/%d" % [ach.profile_count(), ach.all().size()]
		al.add_theme_font_size_override(&"font_size", 15)
		al.add_theme_color_override(&"font_color", Color(1, 0.93, 0.75))
		al.add_theme_color_override(&"font_outline_color", Color(0.2, 0.12, 0.05))
		al.add_theme_constant_override(&"outline_size", 4)
		al.position = Vector2(16, 612)
		add_child(al)
	_add_export_button() # [0.9.0 ขั้น A]
	for b in $Menu.get_children():
		if b is Button:
			_hover_bounce(b)
	_idle_bob($Khom, 0.0)
	_idle_bob($Grandma, 0.6)
	($Menu/Continue_Button if $Menu/Continue_Button.visible and not $Menu/Continue_Button.disabled else $Menu/Start_Button).grab_focus.call_deferred()


func dialog_end():
	EventManager.on_dialog_end.disconnect(dialog_end)
	if DialogScene.last_choice == SKIP_INTRO_CHOICE:
		_skip_intro()
	else:
		SceneRouter.go(SceneRouter.HOME)
	Fade.set_opacity(1)


func tutorial_end():
	EventManager.show_dialog("ออฟฟิศ", Constant.PROLOUGE_TEXT, Constant.OFFICE_BG)
	Global.on_start = false
	showTutorial = false
	EventManager.showUI()
	self.hide()
	EventManager.on_tutorial_finish.disconnect(tutorial_end)


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_option_button_pressed() -> void:
	SettingScene.open()


func _on_start_button_pressed() -> void:
	if showTutorial:
		return
	# [10 ต.ค.] มีเซฟอยู่ → ถามก่อน (กดซ้ำ = เริ่มใหม่ · เซฟเดิมถูกแทนที่ด้วยเซฟใหม่ตอนเข้าบ้าน)
	if SaveGame.exists() and not _confirm_new:
		_confirm_new = true
		$Menu/Start_Button.text = "เริ่มใหม่? กดอีกครั้ง"
		$Menu/Start_Button.tooltip_text = "เซฟเดิมจะถูกแทนที่ด้วยเกมใหม่"
		return
	if Playlog.tester_build(): # [0.9.0 ขั้น A] บิลด์ผู้ทดสอบ: ถามรหัสก่อนเริ่ม
		showTutorial = true
		Playlog.ask_tester_id(func() -> void: Playlog.show_pre_form(_begin_new_game)) # [0.9.0 ขั้น B] แล้วหน้าแบบทดสอบก่อนเล่น
		return
	_begin_new_game()


func _begin_new_game(pre_opened := false) -> void:
	SaveGame.clear() # เริ่มใหม่ = ลบเซฟเดิม → เซฟใหม่สร้างเองตอนเข้าฉากแรก
	DayLoop._reset_run()
	GameState.form_pre_opened = pre_opened # [0.9.0] reset() ล้างแล้ว → ใส่หลังรีเซ็ต
	EventManager.jump_event(EventManager.EventID.MAIN, 0) # เควสต์กลับขั้นแรก (กรณีกลับเมนูมาเริ่มใหม่)
	EventManager.hideUI()
	showTutorial = true
	EventManager.show_tutorial(EventManager.TutorialState.BASIC_START)


## [0.3.0 ขั้น J] ข้ามบทนำ = ตัวเลือกต้นบทนำ (Assets/Dialog/Prolouge.txt) · ไม่ใช่ปุ่มที่เมนู
## จบเควสต์หลักทั้งหมด + ของติดตัว → ไปหน้าร้าน (บทพักก่อนลูกค้าคนแรกยังเล่นตามปกติ)
func _skip_intro() -> void:
	var ev = EventManager.eventMap.get(EventManager.EventID.MAIN)
	if ev:
		EventManager.jump_event(EventManager.EventID.MAIN, 0)
		EventManager.complete_step(EventManager.EventID.MAIN, ev.totalTask - 1)
	GameState.ensure_starter_kit()
	EventManager.showUI()
	await SceneRouter.go(SceneRouter.ROOM)
	SaveGame.save()


## ปุ่มขยายนิดหน่อยตอนเอาเมาส์ชี้
func _hover_bounce(b: Button) -> void:
	b.pivot_offset = b.custom_minimum_size / 2.0
	b.mouse_entered.connect(func(): create_tween().tween_property(b, "scale", Vector2(1.05, 1.05), 0.1))
	b.mouse_exited.connect(func(): create_tween().tween_property(b, "scale", Vector2.ONE, 0.1))


## ตัวละครหายใจเบา ๆ
func _idle_bob(n: Control, delay: float) -> void:
	var tw := create_tween().set_loops()
	tw.tween_interval(delay)
	tw.tween_property(n, "scale", Vector2(1.0, 1.025), 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(n, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE)


## โหลดเซฟ → ข้ามบทนำ ไปฉากที่บันทึกไว้
func _on_continue_button_pressed() -> void:
	if showTutorial:
		return
	showTutorial = true
	var loc := SaveGame.load_into()
	if loc < 0:
		showTutorial = false
		$Menu/Continue_Button.hide()
		return
	if Playlog.tester_build() and GameState.tester_id == "": # [0.9.0] เซฟเก่ายังไม่มีรหัส
		Playlog.ask_tester_id(_enter_loaded.bind(loc))
		return
	_enter_loaded(loc)


func _enter_loaded(loc: int) -> void:
	EventManager.on_tutorial_finish.disconnect(tutorial_end)
	EventManager.on_dialog_end.disconnect(dialog_end)
	Global.on_start = false
	EventManager.showUI()
	hide()
	SceneRouter.go(loc)


## [0.9.0 ขั้น A] ปุ่ม "ส่งออกข้อมูลการเล่น" มุมขวาล่าง (มีข้อมูลแล้ว หรือบิลด์ผู้ทดสอบ) + รหัสผู้ทดสอบ
func _add_export_button() -> void:
	if not (Playlog.has_data() or Playlog.tester_build()):
		return
	var b := Button.new()
	b.name = "ExportButton"
	b.text = "ส่งออกข้อมูลการเล่น"
	b.tooltip_text = "รวมข้อมูลการเล่นเป็นไฟล์ zip ไว้ในโฟลเดอร์เอกสาร เพื่อส่งให้ทีม"
	b.add_theme_font_size_override(&"font_size", 18)
	b.custom_minimum_size = Vector2(250, 44)
	b.position = Vector2(1152 - 250 - 16, 648 - 44 - 40)
	b.pressed.connect(func() -> void:
		var msg := Playlog.export_and_show()
		b.text = "ส่งออกแล้ว ✓"
		b.tooltip_text = msg)
	add_child(b)
	var tid := SaveGame.saved_tester_id()
	if tid != "" or Playlog.tester_build():
		var l := Label.new()
		l.name = "TesterTag"
		l.text = "ผู้ทดสอบ %s" % (tid if tid != "" else "—")
		l.add_theme_font_size_override(&"font_size", 14)
		l.add_theme_color_override(&"font_color", Color(1, 0.93, 0.75))
		l.add_theme_color_override(&"font_outline_color", Color(0.2, 0.12, 0.05))
		l.add_theme_constant_override(&"outline_size", 4)
		l.position = Vector2(1152 - 250 - 16, 648 - 36)
		add_child(l)
