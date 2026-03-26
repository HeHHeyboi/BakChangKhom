extends TextureRect

@onready var master_slider = $PanelContainer/VBoxContainer/MasterVolume/HSlider
@onready var fullscreen_check = $PanelContainer/VBoxContainer/Fullscreen/CheckButton

func _ready():
	_init_ui()

func _init_ui():
	# โหลดค่าระดับเสียง Master ปัจจุบันแล้วแปลงมาแสดงที่ Slider (0.0 - 1.0)
	var master_bus = AudioServer.get_bus_index("Master")
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus))
	
	# โหลดค่าโหมดหน้าจอปัจจุบัน
	fullscreen_check.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_master_volume_changed(value: float):
	# ตั้งค่าระดับเสียง โดยแปลงจาก linear กลับเป็น decibel
	var master_bus = AudioServer.get_bus_index("Master")
	if value <= 0.01:
		AudioServer.set_bus_volume_db(master_bus, -80.0) # mute
	else:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))

func _on_fullscreen_toggled(button_pressed: bool):
	# ตั้งโหมดหน้าจอ
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
