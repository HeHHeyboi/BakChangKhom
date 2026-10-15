class_name DaySkip extends Control
## [0.2.0 · 15 ต.ค. 2569] ข้ามวันระหว่าง "วันที่ได้เล่น" (Docs/ROADMAP_1_0_0.md ข้อ 1.1)
## จอมืด · ปฏิทินฉีกทีละแผ่นจากวันที่เล่นล่าสุดถึงวันใหม่ (ข้ามเดือนได้) · ป้ายเหนือปฏิทิน "ผ่านไป n วัน" นับตาม
## ปิ๊บโผล่มุมซ้ายล่างเฉพาะเมื่อมีเรื่องเกิดระหว่างข้ามวัน (notes) เช่น "ของที่สั่งมาถึงแล้ว"
## สร้างจากโค้ดเหมือน UI อื่นของ DayLoop · คลิกเพื่อข้ามได้ · ใช้: await day_skip.play(25, 1, 2, 7, ["ของที่สั่งมาถึงแล้ว"])
## [15 ต.ค. แก้ตามทีม] ปิ๊บไม่พูด "ผ่านไป n วัน / วันนี้ …" แล้ว — ย้ายไปเป็นป้ายเหนือปฏิทิน + แอนิเมชันฉีกแผ่น

signal finished

const PIB_TEX := "res://Assets/CharacterSprite/char_pib_happy.png"
## สัดส่วนเวลาฉีกแผ่น (ที่เหลือ = ค้างให้อ่าน)
const FLIP_RATIO := 0.55
const CAL_POS := Vector2(446, 170)
const CAL_SIZE := Vector2(260, 260)
const BAND_H := 52.0

var _dim: ColorRect
var _passed: Label ## "ผ่านไป n วัน" เหนือปฏิทิน
var _cal: Control ## แผ่นล่าง (วันถัดไป)
var _cal_month: Label
var _cal_day: Label
var _page: Control ## แผ่นบนที่ถูกฉีก (วันปัจจุบัน)
var _page_month: Label
var _page_day: Label
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


## from_day = วันที่เล่นครั้งก่อน · to_day = วันนี้ · month = เดือนของวันนี้ (1–12) · gap_days = ผ่านไปกี่วัน
## notes = เรื่องที่เกิดระหว่างข้าม (ว่าง = ไม่มีปิ๊บ)
func play(from_day: int, to_day: int, month: int, gap_days: int, notes: PackedStringArray = PackedStringArray(), seconds := 2.4) -> void:
	if _playing:
		return
	_playing = true
	gap_days = maxi(gap_days, 1)
	var from_month := month if from_day <= to_day else (month - 1 if month > 1 else 12)
	_set_page(_page_month, _page_day, from_month, from_day)
	_set_page(_cal_month, _cal_day, from_month, from_day)
	_reset_page()
	_passed.text = ""
	_say.text = "\n".join(notes)
	var has_pib := not notes.is_empty()
	_pib.visible = has_pib
	_bubble.visible = has_pib
	_pib.position = Vector2(24, 648)
	_bubble.modulate.a = 0.0
	modulate.a = 0.0
	visible = true
	var flip_total := maxf(seconds * FLIP_RATIO, 0.05)
	var step := flip_total / gap_days
	_tw = create_tween()
	_tw.tween_property(self, "modulate:a", 1.0, 0.2)
	# ฉีกทีละแผ่น: แผ่นล่างเป็นวันถัดไป · แผ่นบนลอยขึ้น เอียง จางหาย แล้วรีเซ็ตเป็นวันใหม่
	for i in gap_days:
		var d := _day_after(from_day, from_month, i + 1)
		_tw.tween_callback(_set_page.bind(_cal_month, _cal_day, d.y, d.x))
		_tw.tween_property(_page, "position", CAL_POS + Vector2(30, -70), step).set_ease(Tween.EASE_IN)
		_tw.parallel().tween_property(_page, "rotation", -0.35, step)
		_tw.parallel().tween_property(_page, "modulate:a", 0.0, step)
		_tw.tween_callback(_after_tear.bind(d.y, d.x, i + 1))
	_tw.tween_callback(func() -> void:
		if has_node(^"/root/Audio"):
			get_node(^"/root/Audio").sfx(&"success")
	)
	if has_pib:
		_tw.tween_property(_pib, "position:y", 648.0 - 300.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tw.tween_property(_bubble, "modulate:a", 1.0, 0.15)
	_tw.tween_interval(maxf(seconds - flip_total, 0.3) + 0.4 * notes.size())
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


func _after_tear(month: int, day: int, passed: int) -> void:
	_set_page(_page_month, _page_day, month, day)
	_reset_page()
	_passed.text = "ผ่านไป %d วัน" % passed


func _reset_page() -> void:
	_page.position = CAL_POS
	_page.rotation = 0.0
	_page.modulate.a = 1.0


func _set_page(m_label: Label, d_label: Label, month: int, day: int) -> void:
	m_label.text = TimeSystem.MONTH_NAME[clampi(month, 1, 12) - 1]
	d_label.text = str(day)


## วันที่หลังจาก (from_day, from_month) ไป n วัน → Vector2i(วัน, เดือน)
static func _day_after(from_day: int, from_month: int, n: int) -> Vector2i:
	var d := from_day + n
	var m := from_month
	var mlen := TimeSystem.days_in_month(m)
	while d > mlen:
		d -= mlen
		m = m + 1 if m < 12 else 1
		mlen = TimeSystem.days_in_month(m)
	return Vector2i(d, m)


## แผ่นปฏิทิน 1 แผ่น (แถบเดือนสีแดง + เลขวัน)
func _make_page(parent: Node) -> Array:
	var root := Control.new()
	root.position = CAL_POS
	root.size = CAL_SIZE
	root.pivot_offset = Vector2(CAL_SIZE.x * 0.5, 0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(root)
	var paper := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.98, 0.93)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(4)
	sb.border_color = Color(0.55, 0.25, 0.06)
	paper.add_theme_stylebox_override("panel", sb)
	paper.size = CAL_SIZE
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(paper)
	var band := Panel.new()
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.78, 0.2, 0.16)
	bsb.corner_radius_top_left = 12
	bsb.corner_radius_top_right = 12
	band.add_theme_stylebox_override("panel", bsb)
	band.position = Vector2(4, 4)
	band.size = Vector2(CAL_SIZE.x - 8, BAND_H)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(band)
	var m := Label.new()
	m.add_theme_font_size_override("font_size", 34)
	m.add_theme_color_override("font_color", Color.WHITE)
	m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	m.position = Vector2(4, 4)
	m.size = Vector2(CAL_SIZE.x - 8, BAND_H)
	root.add_child(m)
	var d := Label.new()
	d.add_theme_font_size_override("font_size", 130)
	d.add_theme_color_override("font_color", Color(0.25, 0.15, 0.08))
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	d.position = Vector2(0, BAND_H)
	d.size = Vector2(CAL_SIZE.x, CAL_SIZE.y - BAND_H)
	root.add_child(d)
	return [root, m, d]


func _build() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.05, 0.04, 0.08, 0.65)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.size = size
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	# ป้าย "ผ่านไป n วัน" เหนือปฏิทิน
	_passed = Label.new()
	_passed.add_theme_font_size_override("font_size", 40)
	_passed.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	_passed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_passed.position = Vector2(0, CAL_POS.y - 70)
	_passed.size = Vector2(1152, 56)
	add_child(_passed)
	var under := _make_page(self)
	_cal = under[0]
	_cal_month = under[1]
	_cal_day = under[2]
	var top := _make_page(self)
	_page = top[0]
	_page_month = top[1]
	_page_day = top[2]
	# ปิ๊บมุมซ้ายล่าง (เฉพาะเมื่อมี notes)
	_pib = TextureRect.new()
	if ResourceLoader.exists(PIB_TEX):
		_pib.texture = load(PIB_TEX)
	_pib.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pib.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pib.size = Vector2(300, 300)
	_pib.position = Vector2(24, 648)
	_pib.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pib)
	_bubble = PanelContainer.new()
	var qsb := StyleBoxFlat.new()
	qsb.bg_color = Color(1, 1, 1, 0.97)
	qsb.set_corner_radius_all(16)
	qsb.set_content_margin_all(16)
	qsb.border_color = Color(0.3, 0.3, 0.35)
	qsb.set_border_width_all(2)
	_bubble.add_theme_stylebox_override("panel", qsb)
	_bubble.position = Vector2(300, 470)
	_bubble.custom_minimum_size = Vector2(420, 0)
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bubble)
	_say = Label.new()
	_say.add_theme_font_size_override("font_size", 26)
	_say.add_theme_color_override("font_color", Color(0.15, 0.15, 0.2))
	_say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.add_child(_say)
