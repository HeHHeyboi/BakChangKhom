extends CanvasLayer
## เมนูพัก (autoload PauseMenu) — กด Esc ระหว่างเล่น: เล่นต่อ · บันทึก · ความสำเร็จ · ตั้งค่า · ส่งออกข้อมูลการเล่น · กลับเมนูหลัก · ออกจากเกม
## [0.9.0 ขั้น 0] หน้า "ความสำเร็จ" (ใบประกาศ + ของขวัญส่งท้ายปี) อยู่ที่นี่ที่เดียว · ปุ่ม "ความสำเร็จ"/"ส่งออก" สร้างในโค้ด (_add_buttons)
## ไม่เปิดตอนอยู่เมนูหลัก และตอนอยู่ในมินิเกม (มินิเกมใช้ Esc = ย้อนกลับมุมมอง)
## โหลด + ใช้ค่าตั้งค่าของผู้เล่นตอนเปิดเกม (GameSettings) · [Claude 10 ต.ค. 2569]

const START_SCENE := "res://Scene/Start_Scene.tscn"
const ACH_SCENE := preload("res://Scene/UI/achievement_app.tscn")
const BUTTON_H := 56.0

@onready var panel: Control = %Panel
@onready var settings: SettingsPanel = %Settings
@onready var menu_button: Button = %MenuButton

var _confirm_menu := false
var ach_button: Button
var export_button: Button
var ach_page: PanelContainer


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
	_add_buttons()


## [0.9.0] ปุ่มเพิ่ม 2 ปุ่ม + ย่อความสูงปุ่มให้ 7 ปุ่มพอดีจอ
func _add_buttons() -> void:
	var vb := %ResumeButton.get_parent() as VBoxContainer
	ach_button = Button.new()
	ach_button.name = "AchButton"
	ach_button.text = "ความสำเร็จ"
	ach_button.pressed.connect(open_achievements)
	vb.add_child(ach_button)
	vb.move_child(ach_button, %SettingsButton.get_index())
	export_button = Button.new()
	export_button.name = "ExportButton"
	export_button.text = "ส่งออกข้อมูลการเล่น"
	export_button.tooltip_text = "รวมข้อมูลการเล่นเป็นไฟล์ zip ไว้ในโฟลเดอร์เอกสาร"
	export_button.pressed.connect(_on_export_pressed)
	vb.add_child(export_button)
	vb.move_child(export_button, menu_button.get_index())
	vb.add_theme_constant_override(&"separation", 10)
	for b in vb.get_children():
		if b is Button:
			b.custom_minimum_size = Vector2(340, BUTTON_H)
			b.add_theme_font_size_override(&"font_size", 24)
	panel.offset_top = -300.0
	panel.offset_bottom = 300.0


func _on_export_pressed() -> void:
	var msg := Playlog.export_and_show()
	export_button.text = "ส่งออกแล้ว ✓"
	export_button.tooltip_text = msg


## หน้าความสำเร็จ (ใบประกาศทั้งหมด + ของขวัญส่งท้ายปี) · Esc/ปุ่มปิด = กลับเมนูพัก
func open_achievements() -> void:
	if ach_page == null:
		ach_page = PanelContainer.new()
		ach_page.name = "AchievementPage"
		ach_page.set_anchors_preset(Control.PRESET_CENTER)
		ach_page.offset_left = -330.0
		ach_page.offset_right = 330.0
		ach_page.offset_top = -300.0
		ach_page.offset_bottom = 300.0
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 0.97, 0.9)
		sb.border_color = Color(0.6, 0.42, 0.2)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(12)
		sb.set_content_margin_all(16)
		ach_page.add_theme_stylebox_override(&"panel", sb)
		var box := VBoxContainer.new()
		box.add_theme_constant_override(&"separation", 8)
		ach_page.add_child(box)
		var app := ACH_SCENE.instantiate() as Control
		app.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(app)
		var close := Button.new()
		close.name = "Close"
		close.text = "กลับ"
		close.custom_minimum_size = Vector2(0, 48)
		close.pressed.connect(close_achievements)
		box.add_child(close)
		panel.get_parent().add_child(ach_page)
	var app_node := ach_page.get_child(0).get_child(0)
	if app_node.has_method(&"refresh"):
		app_node.refresh(true)
	panel.hide()
	ach_page.show()
	(ach_page.find_child("Close", true, false) as Button).grab_focus.call_deferred()


func close_achievements() -> void:
	if ach_page:
		ach_page.hide()
	panel.show()
	ach_button.grab_focus.call_deferred()


## เปิดเมนูพักได้ไหมตอนนี้
func can_pause() -> bool:
	var cur := get_tree().current_scene
	if cur == null:
		return false
	if cur.is_in_group("main_menu") and cur.visible:
		return false
	if Global.in_minigame:
		return false
	if MapPanel.visible: # [Claude 10 ต.ค. 2569] Esc ปิดแผนที่ก่อน
		return false
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		return
	if visible:
		get_viewport().set_input_as_handled()
		if settings.visible:
			settings.close()
		elif ach_page and ach_page.visible:
			close_achievements()
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
	if ach_page:
		ach_page.hide()
	if export_button:
		export_button.text = "ส่งออกข้อมูลการเล่น"
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
	%SaveButton.text = ("บันทึกแล้ว ✓ %s" % TimeSystem.shift_label(int(info.shift))) if ok and not info.is_empty() else "บันทึกตอนนี้ไม่ได้"
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
