extends CanvasLayer

@onready var pause_panel = $PausePanel
@onready var master_slider = $PausePanel/PanelContainer/VBoxContainer/MasterVolume/HSlider
@onready var fullscreen_check = $PausePanel/PanelContainer/VBoxContainer/Fullscreen/CheckButton
@onready var gear_button = $GearButton

func _ready():
	_init_ui()
	# ผูก event เพื่อเช็คการเปลี่ยนหน้า
	get_tree().node_added.connect(_on_node_added)
	_update_visibility()

func _on_node_added(_node: Node):
	# คอยตรวจสอบว่าอยู่หน้า Start หรือหน้าเกม แล้วซ่อน/โชว์ฟันเฟือง
	call_deferred("_update_visibility")

func _update_visibility():
	var root = get_tree().root
	var current_scene = root.get_child(root.get_child_count() - 1)
	if current_scene and current_scene.name == "StartScene":
		gear_button.hide()
	else:
		gear_button.show()

	# ถ้าหน้า Pause Panel ถูกดึงอยู่ ให้คงฟันเฟืองไว้ตามค่าเดิม
	if pause_panel.visible:
		gear_button.hide()

func _input(event):
	# สั่งหยุดเวลา (Pause) ตอนกดปุ่ม ESC ได้สมบูรณ์
	if event.is_action_pressed("ui_cancel"):
		var root = get_tree().root
		var current_scene = root.get_child(root.get_child_count() - 1)
		
		# ห้ามกดหยุดในหน้า Start
		if current_scene and current_scene.name != "StartScene":
			if pause_panel.visible:
				_resume_game()
			else:
				_pause_game()

func _init_ui():
	var master_bus = AudioServer.get_bus_index("Master")
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus))
	fullscreen_check.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

func _pause_game():
	# หยุด Engine ไม่ให้สิ่งอื่นในเกมอัปเดต / ขยับได้
	get_tree().paused = true
	pause_panel.show()
	gear_button.hide()

func _resume_game():
	get_tree().paused = false
	pause_panel.hide()
	_update_visibility()

func _on_gear_button_pressed():
	_pause_game()

func _on_resume_button_pressed():
	_resume_game()

func _on_main_menu_button_pressed():
	_resume_game()
	# กลับหน้าแรก
	get_tree().change_scene_to_file("res://Scene/Start_Scene.tscn")

# ======== การตั้งค่าเหมือนหน้า Option ใน Start ============
func _on_master_volume_changed(value: float):
	var master_bus = AudioServer.get_bus_index("Master")
	if value <= 0.01:
		AudioServer.set_bus_volume_db(master_bus, -80.0)
	else:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))

func _on_fullscreen_toggled(button_pressed: bool):
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
