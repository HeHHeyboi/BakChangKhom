class_name DaySkip extends Control
## [0.2.0 · 15 ต.ค. 2569] ข้ามวันระหว่าง "วันที่ได้เล่น" (Docs/ROADMAP_1_0_0.md ข้อ 1.1)
## จอมืด · ปฏิทินพลิกจากวันที่เล่นล่าสุดไปวันที่ใหม่ · ปิ๊บโผล่มุมซ้ายล่างบอก "ผ่านไป n วัน" + เรื่องที่เกิดระหว่างนั้น
## สร้างจากโค้ดเหมือน UI อื่นของ DayLoop · คลิกเพื่อข้ามได้ · ใช้: await day_skip.play(1, 7, 1, ["ของที่สั่งมาถึงแล้ว"])

signal finished

const PIB_TEX := "res://Assets/CharacterSprite/char_pib_happy.png"
## เวลาที่ปฏิทินพลิก + เวลาค้างให้อ่าน (วินาที) — DayLoop.day_skip_seconds คุมรวม
const FLIP_RATIO := 0.4

var _dim: ColorRect
var _cal: PanelContainer
var _cal_month: Label
var _cal_day: Label
var _pib: TextureRect
var _bubble: PanelContainer
var _say: Label
var _tw: Tween
var _playing := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = Vector2(1152, 648)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()


## เล่นแอนิเมชันข้ามวัน · from_day/to_day = วันที่ในปฏิทิน · month = 1–12 ของวันใหม่ · notes = เรื่องที่เกิดระหว่างข้าม
func play(from_day: int, to_day: int, month: int, gap_days: int, notes: PackedStringArray = PackedStringArray(), seconds := 2.4) -> void:
	if _playing:
		return
	_playing = true
	var mi := clampi(month, 1, TimeSystem.MONTH_NAME.size()) - 1
	_cal_month.text = TimeSystem.MONTH_NAME[mi]
	_cal_day.text = str(from_day)
	_say.text = ""
	var lines := PackedStringArray(["ผ่านไป %d วันแล้วนะ!" % gap_days, "วันนี้ %d %s" % [to_day, TimeSystem.MONTH_NAME[mi]]])
	lines.append_array(notes)
	modulate.a = 0.0
	visible = true
	_pib.position = Vector2(24, 648)
	_bubble.modulate.a = 0.0
	var flip := maxf(seconds * FLIP_RATIO, 0.05)
	_tw = create_tween()
	_tw.tween_property(self, "modulate:a", 1.0, 0.2)
	_tw.tween_property(_pib, "position:y", 648.0 - 300.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# วันข้ามเดือน (25 → 1): ให้ตัวเลขวิ่งต่อจากวันที่เก่าแล้วค่อยเป็น 1 ด้วยการนับเป็นจำนวนวันที่ผ่านไป
	_tw.tween_method(func(v: float) -> void: _cal_day.text = str(_day_after(from_day, int(v), month)), 0.0, float(gap_days), flip)
	_tw.tween_callback(func() -> void:
		_cal_day.text = str(to_day)
		_say.text = "\n".join(lines)
		if has_node(^"/root/Audio"):
			get_node(^"/root/Audio").sfx(&"success")
	)
	_tw.tween_property(_bubble, "modulate:a", 1.0, 0.15)
	_tw.tween_interval(maxf(seconds - flip, 0.3) + 0.25 * notes.size())
	_tw.tween_property(self, "modulate:a", 0.0, 0.25)
	await _tw.finished
	_end()


func is_playing() -> bool:
	return _playing


## คลิกเพื่อข้าม
func _gui_input(event: InputEvent) -> void:
	if _playing and event is InputEventMouseButton and event.pressed:
		accept_event()
		if _tw and _tw.is_valid():
			_tw.kill()
		_end()


func _end() -> void:
	if not _playing:
		return
	_playing = false
	visible = false
	finished.emit()


## วันที่หลังจากวันเก่าไป n วัน (ข้ามเดือนได้) · month = เดือนของวันใหม่
static func _day_after(from_day: int, n: int, month: int) -> int:
	var prev_len := TimeSystem.days_in_month(month - 1 if month > 1 else 12)
	var d := from_day + n
	return d - prev_len if d > prev_len and from_day > 20 else d


func _build() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.05, 0.04, 0.08, 0.65)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.size = size
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	# ปฏิทินกลางจอ
	_cal = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.98, 0.93)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(4)
	sb.border_color = Color(0.55, 0.25, 0.06)
	_cal.add_theme_stylebox_override("panel", sb)
	_cal.position = Vector2(446, 150)
	_cal.size = Vector2(260, 260)
	_cal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cal)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	_cal.add_child(box)
	var band := PanelContainer.new()
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.78, 0.2, 0.16)
	bsb.corner_radius_top_left = 10
	bsb.corner_radius_top_right = 10
	band.add_theme_stylebox_override("panel", bsb)
	box.add_child(band)
	_cal_month = Label.new()
	_cal_month.add_theme_font_size_override("font_size", 34)
	_cal_month.add_theme_color_override("font_color", Color.WHITE)
	_cal_month.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	band.add_child(_cal_month)
	_cal_day = Label.new()
	_cal_day.add_theme_font_size_override("font_size", 130)
	_cal_day.add_theme_color_override("font_color", Color(0.25, 0.15, 0.08))
	_cal_day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cal_day.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cal_day.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_cal_day)
	# ปิ๊บมุมซ้ายล่าง
	_pib = TextureRect.new()
	if ResourceLoader.exists(PIB_TEX):
		_pib.texture = load(PIB_TEX)
	_pib.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pib.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pib.size = Vector2(300, 300)
	_pib.position = Vector2(24, 648)
	_pib.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pib)
	# กล่องคำพูดข้างปิ๊บ
	_bubble = PanelContainer.new()
	var qsb := StyleBoxFlat.new()
	qsb.bg_color = Color(1, 1, 1, 0.97)
	qsb.set_corner_radius_all(16)
	qsb.set_content_margin_all(16)
	qsb.border_color = Color(0.3, 0.3, 0.35)
	qsb.set_border_width_all(2)
	_bubble.add_theme_stylebox_override("panel", qsb)
	_bubble.position = Vector2(300, 440)
	_bubble.custom_minimum_size = Vector2(420, 0)
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bubble)
	_say = Label.new()
	_say.add_theme_font_size_override("font_size", 26)
	_say.add_theme_color_override("font_color", Color(0.15, 0.15, 0.2))
	_say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.add_child(_say)
