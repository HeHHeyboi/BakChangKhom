class_name SettingsPanel extends Control
## หน้าตั้งค่า (ใช้ทั้งเมนูหลักและเมนูพัก) — ปรับแล้วใช้ทันที + เซฟลง user://settings.cfg (GameSettings)
## โหนดทั้งหมดอยู่ใน settings_panel.tscn แก้หน้าตาใน Inspector ได้ · [Claude 10 ต.ค. 2569]

signal closed

@onready var volume: HSlider = %Volume
@onready var volume_value: Label = %VolumeValue
@onready var fullscreen: CheckButton = %Fullscreen
@onready var text_speed: HSlider = %TextSpeed
@onready var text_speed_value: Label = %TextSpeedValue


func _ready() -> void:
	text_speed.min_value = GameSettings.TEXT_SPEED_MIN
	text_speed.max_value = GameSettings.TEXT_SPEED_MAX
	_load_values()
	volume.value_changed.connect(func(v: float):
		GameSettings.set_value("master_volume", v / 100.0)
		_refresh_labels())
	fullscreen.toggled.connect(func(on: bool): GameSettings.set_value("fullscreen", on))
	text_speed.value_changed.connect(func(v: float):
		GameSettings.set_value("text_speed", v)
		_refresh_labels())
	%ResetButton.pressed.connect(func():
		GameSettings.reset_defaults()
		_load_values())
	%BackButton.pressed.connect(close)


func open() -> void:
	_load_values()
	show()
	%BackButton.grab_focus.call_deferred()


func close() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()


func _load_values() -> void:
	volume.set_value_no_signal(float(GameSettings.get_value("master_volume")) * 100.0)
	fullscreen.set_pressed_no_signal(bool(GameSettings.get_value("fullscreen")))
	text_speed.set_value_no_signal(float(GameSettings.get_value("text_speed")))
	_refresh_labels()


func _refresh_labels() -> void:
	volume_value.text = "%d%%" % roundi(volume.value)
	var t := text_speed.value
	text_speed_value.text = "ช้า" if t < 35.0 else ("ปกติ" if t < 70.0 else "เร็ว")
