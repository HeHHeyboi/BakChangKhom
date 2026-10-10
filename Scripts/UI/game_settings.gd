class_name GameSettings extends RefCounted
## ค่าตั้งค่าของผู้เล่น (เสียงรวม · เต็มจอ · ความเร็วตัวอักษร) เก็บที่ user://settings.cfg
## โหลด + ใช้ตอนเปิดเกม (PauseMenu autoload เรียก load_and_apply) · หน้า SettingsPanel เรียก set_value
## [Claude 10 ต.ค. 2569]

const PATH := "user://settings.cfg"
const SECTION := "settings"
const DEFAULTS := {
	"master_volume": 0.8, # 0..1 (บัส Master)
	"music_volume": 0.7, # 0..1 (บัส Music) [10 ต.ค.]
	"sfx_volume": 0.8, # 0..1 (บัส SFX)
	"fullscreen": false,
	"text_speed": 45.0, # ตัวอักษร/วินาที ของกล่องข้อความปิ๊บ (PibHint)
}
const TEXT_SPEED_MIN := 15.0
const TEXT_SPEED_MAX := 120.0

static var _data: Dictionary = DEFAULTS.duplicate()
static var _loaded := false


static func load_and_apply() -> void:
	_data = DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for k in DEFAULTS:
			_data[k] = cfg.get_value(SECTION, k, DEFAULTS[k])
	_loaded = true
	apply_all()


static func save() -> void:
	var cfg := ConfigFile.new()
	for k in _data:
		cfg.set_value(SECTION, k, _data[k])
	var err := cfg.save(PATH)
	if err != OK:
		push_warning("GameSettings: เซฟไม่ได้ (error %d)" % err)


static func get_value(key: String) -> Variant:
	return _data.get(key, DEFAULTS.get(key))


## ตั้งค่า → ใช้ทันที → เซฟ
static func set_value(key: String, value: Variant) -> void:
	_data[key] = value
	_apply(key)
	save()


static func reset_defaults() -> void:
	_data = DEFAULTS.duplicate()
	apply_all()
	save()


static func apply_all() -> void:
	for k in _data:
		_apply(k)


## ความเร็วตัวอักษรที่ผู้เล่นตั้ง (ยังไม่โหลด = ใช้ค่า fallback ของกล่องข้อความนั้น)
static func text_speed(fallback := 45.0) -> float:
	return float(_data.text_speed) if _loaded else fallback


static func _apply(key: String) -> void:
	match key:
		"master_volume", "music_volume", "sfx_volume":
			var v := clampf(float(_data[key]), 0.0, 1.0)
			var bus := AudioServer.get_bus_index({"master_volume": "Master", "music_volume": "Music", "sfx_volume": "SFX"}[key])
			if bus < 0:
				return
			AudioServer.set_bus_mute(bus, v <= 0.001)
			AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v, 0.001)))
		"fullscreen":
			if DisplayServer.get_name() == "headless":
				return
			var want := DisplayServer.WINDOW_MODE_FULLSCREEN if bool(_data.fullscreen) else DisplayServer.WINDOW_MODE_WINDOWED
			if DisplayServer.window_get_mode() != want:
				DisplayServer.window_set_mode(want)
