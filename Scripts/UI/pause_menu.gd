extends CanvasLayer
## เมนูพัก (autoload PauseMenu) — กด Esc ระหว่างเล่น: เล่นต่อ · ตั้งค่า · กลับเมนูหลัก · ออกจากเกม
## ไม่เปิดตอนอยู่เมนูหลัก และตอนอยู่ในมินิเกม (มินิเกมใช้ Esc = ย้อนกลับมุมมอง)
## โหลด + ใช้ค่าตั้งค่าของผู้เล่นตอนเปิดเกม (GameSettings) · [Claude 10 ต.ค. 2569]

const START_SCENE := "res://Scene/Start_Scene.tscn"

@onready var panel: Control = %Panel
@onready var settings: SettingsPanel = %Settings
@onready var menu_button: Button = %MenuButton

var _confirm_menu := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	GameSettings.load_and_apply()
	%ResumeButton.pressed.connect(_on_resume_pressed)
	%SaveButton.pressed.connect(save_now)
	%SettingsButton.pressed.connect(_open_settings)
	menu_button.pressed.connect(_on_menu_pressed)
	%QuitButton.pressed.connect(func(): get_tree().quit())
	%QuitButton.visible = not OS.has_feature("web")
	settings.closed.connect(func():
		panel.show()
		%ResumeButton.grab_focus())


## เปิดเมนูพักได้ไหมตอนนี้
func can_pause() -> bool:
	var cur := get_tree().current_scene
	if cur == null:
		return false
	if cur.is_in_group("main_menu") and cur.visible:
		return false
	if Global.in_minigame:
		return false
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		return
	if visible:
		get_viewport().set_input_as_handled()
		if settings.visible:
			settings.close()
		else:
			resume()
	elif can_pause():
		get_viewport().set_input_as_handled()
		open()


func open() -> void:
	_confirm_menu = false
	menu_button.text = "กลับเมนูหลัก"
	%SaveButton.text = "บันทึกเกม"
	settings.hide()
	panel.show()
	show()
	get_tree().paused = true
	%ResumeButton.grab_focus.call_deferred()


func resume() -> void:
	hide()
	get_tree().paused = false


## [10 ต.ค.] เล่นต่อ = บันทึกให้ด้วย
func _on_resume_pressed() -> void:
	resume()
	DayLoop.autosave()


## บันทึกตอนนี้ (ปุ่ม "บันทึกเกม") · คืน true = บันทึกได้
func save_now() -> bool:
	var ok := DayLoop.autosave()
	var info := SaveGame.info()
	%SaveButton.text = ("บันทึกแล้ว ✓ วันที่ %d" % info.shift) if ok and not info.is_empty() else "บันทึกตอนนี้ไม่ได้"
	return ok


func _open_settings() -> void:
	panel.hide()
	settings.open()


## กดครั้งแรก = ถามยืนยัน · กดซ้ำ = บันทึก แล้วกลับเมนูหลัก (เล่นต่อได้จากปุ่ม "เล่นต่อ")
func _on_menu_pressed() -> void:
	if not _confirm_menu:
		_confirm_menu = true
		menu_button.text = "กดอีกครั้งเพื่อยืนยัน (บันทึกให้แล้ว)"
		return
	go_to_main_menu()


func go_to_main_menu() -> void:
	resume()
	DayLoop.autosave() # [10 ต.ค.] บันทึกก่อนกลับเมนู → กด "เล่นต่อ" ได้
	Global.on_start = true # กันรีเซ็ตด้านล่างไปบันทึกทับ
	DayLoop._reset_run()
	SceneRouter.clear()
	EventManager.hideUI()
	var err := get_tree().change_scene_to_file(START_SCENE)
	if err != OK:
		push_error("PauseMenu: กลับเมนูหลักไม่ได้ (error %d)" % err)
