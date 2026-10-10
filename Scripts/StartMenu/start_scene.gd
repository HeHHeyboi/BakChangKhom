extends Control
## เมนูหลัก (เริ่มเกม · ตั้งค่า · ออกจากเกม) — [Claude 10 ต.ค. 2569] สร้างใหม่เป็นโหนดทั้งหมด (เดิมเป็นภาพวาด)
## ปุ่ม/ตัวละคร/หัวเรื่อง แก้ใน Start_Scene.tscn ได้ · หน้าตั้งค่า = Scene/UI/settings_panel.tscn

@export var SettingScene: SettingsPanel
@export var tutorial: TextureRect
var showTutorial = false
var _confirm_new := false


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
		$Menu/Continue_Button.text = "เล่นต่อ (วันที่ %d · ฿%d)" % [info.shift, info.money]
	for b in $Menu.get_children():
		if b is Button:
			_hover_bounce(b)
	_idle_bob($Khom, 0.0)
	_idle_bob($Grandma, 0.6)
	($Menu/Continue_Button if $Menu/Continue_Button.visible else $Menu/Start_Button).grab_focus.call_deferred()


func dialog_end():
	SceneRouter.go(SceneRouter.HOME)
	Fade.set_opacity(1)
	EventManager.on_dialog_end.disconnect(dialog_end)


func tutorial_end():
	EventManager.show_dialog("ออฟฟิส", Constant.PROLOUGE_TEXT, Constant.OFFICE_BG)
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
	SaveGame.clear() # เริ่มใหม่ = ลบเซฟเดิม → เซฟใหม่สร้างเองตอนเข้าฉากแรก
	DayLoop._reset_run()
	EventManager.jump_event(EventManager.EventID.MAIN, 0) # เควสต์กลับขั้นแรก (กรณีกลับเมนูมาเริ่มใหม่)
	EventManager.hideUI()
	showTutorial = true
	EventManager.show_tutorial(EventManager.TutorialState.BASIC_START)


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
	EventManager.on_tutorial_finish.disconnect(tutorial_end)
	EventManager.on_dialog_end.disconnect(dialog_end)
	Global.on_start = false
	EventManager.showUI()
	hide()
	SceneRouter.go(loc)
