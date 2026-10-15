class_name DaySkip extends Control
## [0.2.0-B · 15 ต.ค. 2569] ข้ามวันระหว่าง "วันที่ได้เล่น" (Docs/ROADMAP_1_0_0.md ข้อ 1.1)
## ฉาก Scene/UI/day_skip.tscn (วางใน day_loop.tscn → DaySkipLayer ชั้น 110) — ตำแหน่ง/ฟอนต์/สี/รูปปิ๊บ ปรับใน Editor ได้
##   Dim = จอมืด · Passed = ป้าย "ผ่านไป n วัน" เหนือปฏิทิน · CalUnder/CalTop = ปฏิทิน 2 แผ่น (Scene/UI/calendar_page.tscn)
##   Pib + Bubble/Say = ปิ๊บมุมซ้ายล่าง โผล่เฉพาะเมื่อมีเรื่องเกิดระหว่างข้ามวัน (notes)
## แผ่นบน (CalTop) ฉีกทีละวัน: ลอยขึ้น เอียง จางหาย → รีเซ็ตเป็นวันใหม่ · คลิกเพื่อข้ามได้
## ใช้: await day_skip.play(25, 1, 2, 7, ["ของที่สั่งมาถึงแล้ว"])

signal finished

@export_group("จังหวะ")
## เวลารวม (วินาที) เมื่อ play() ไม่ได้ส่งมา · DayLoop.day_skip_seconds ส่งทับ
@export var seconds := 2.4
## สัดส่วนเวลาฉีกแผ่น (ที่เหลือ = ค้างให้อ่าน)
@export_range(0.1, 0.95) var flip_ratio := 0.55
## ค้างเพิ่มต่อ 1 บรรทัดที่ปิ๊บพูด (วินาที)
@export var note_extra := 0.4
@export_group("แผ่นที่ฉีก")
## แผ่นบนลอยไปเท่าไรจากตำแหน่งเดิม
@export var tear_offset := Vector2(30, -70)
## แผ่นบนเอียงกี่เรเดียน (ลบ = ทวนเข็ม)
@export var tear_rotation := -0.35
@export_group("ปิ๊บ")
## ปิ๊บเริ่มต่ำกว่าตำแหน่งที่วางไว้กี่พิกเซล แล้วเด้งขึ้นมา
@export var pib_rise := 300.0

@onready var _passed: Label = %Passed
@onready var _cal: Control = %CalUnder
@onready var _page: Control = %CalTop
@onready var _pib: TextureRect = %Pib
@onready var _bubble: PanelContainer = %Bubble
@onready var _say: Label = %Say
@onready var _cal_month: Label = _cal.get_node(^"Month")
@onready var _cal_day: Label = _cal.get_node(^"Day")
@onready var _page_month: Label = _page.get_node(^"Month")
@onready var _page_day: Label = _page.get_node(^"Day")
@onready var _cal_wd: Label = _cal.get_node(^"Weekday")
@onready var _page_wd: Label = _page.get_node(^"Weekday")
## ข้อความต่อท้ายป้ายเมื่อข้ามเสาร์–อาทิตย์
@export var weekend_note := "หยุดเสาร์–อาทิตย์"
## [0.2.0] ข้อความต่อท้ายเมื่อข้ามวันธรรมดาที่ร้านปิด (อ. · พฤ.)
@export var closed_note := "ร้านปิด ขมไปช่วยยาย"

var _page_pos: Vector2
var _pib_pos: Vector2
var _tw: Tween
var _playing := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_page_pos = _page.position
	_pib_pos = _pib.position


## from_day = วันที่เล่นครั้งก่อน · to_day = วันนี้ · month = เดือนของวันนี้ (1–12) · gap_days = ผ่านไปกี่วัน
## notes = เรื่องที่เกิดระหว่างข้าม (ว่าง = ไม่มีปิ๊บ) · secs < 0 = ใช้ค่า seconds ใน Inspector
func play(from_day: int, to_day: int, month: int, gap_days: int, notes: PackedStringArray = PackedStringArray(), secs := -1.0) -> void:
	if _playing:
		return
	_playing = true
	var total := seconds if secs < 0.0 else secs
	gap_days = maxi(gap_days, 1)
	var from_month := month if from_day <= to_day else (month - 1 if month > 1 else 12)
	_set_page(_page_month, _page_day, from_month, from_day, _page_wd)
	_set_page(_cal_month, _cal_day, from_month, from_day, _cal_wd)
	var weekend := false
	var closed := false
	_reset_page()
	_passed.text = ""
	_say.text = "\n".join(notes)
	var has_pib := not notes.is_empty()
	_pib.visible = has_pib
	_bubble.visible = has_pib
	_pib.position = _pib_pos + Vector2(0, pib_rise)
	_bubble.modulate.a = 0.0
	modulate.a = 0.0
	visible = true
	var flip_total := maxf(total * flip_ratio, 0.05)
	var step := flip_total / gap_days
	_tw = create_tween()
	_tw.tween_property(self, "modulate:a", 1.0, 0.2)
	for i in gap_days:
		var d := _day_after(from_day, from_month, i + 1)
		var wd_i := TimeSystem.weekday_of(d.x, d.y)
		weekend = weekend or wd_i >= 5
		closed = closed or (i < gap_days - 1 and wd_i < 5) # วันธรรมดาที่ข้ามไป (ไม่ใช่วันนี้)
		_tw.tween_callback(_set_page.bind(_cal_month, _cal_day, d.y, d.x, _cal_wd))
		_tw.tween_property(_page, "position", _page_pos + tear_offset, step).set_ease(Tween.EASE_IN)
		_tw.parallel().tween_property(_page, "rotation", tear_rotation, step)
		_tw.parallel().tween_property(_page, "modulate:a", 0.0, step)
		_tw.tween_callback(_after_tear.bind(d.y, d.x, i + 1))
	if weekend and weekend_note != "":
		_tw.tween_callback(func() -> void: _passed.text += " · " + weekend_note)
	elif closed and closed_note != "":
		_tw.tween_callback(func() -> void: _passed.text += " · " + closed_note)
	_tw.tween_callback(func() -> void:
		if has_node(^"/root/Audio"):
			get_node(^"/root/Audio").sfx(&"success")
	)
	if has_pib:
		_tw.tween_property(_pib, "position", _pib_pos, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tw.tween_property(_bubble, "modulate:a", 1.0, 0.15)
	_tw.tween_interval(maxf(total - flip_total, 0.3) + note_extra * notes.size())
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
	_set_page(_page_month, _page_day, month, day, _page_wd)
	_reset_page()
	_passed.text = "ผ่านไป %d วัน" % passed


func _reset_page() -> void:
	_page.position = _page_pos
	_page.rotation = 0.0
	_page.modulate.a = 1.0


func _set_page(m_label: Label, d_label: Label, month: int, day: int, wd_label: Label = null) -> void:
	m_label.text = TimeSystem.MONTH_NAME[clampi(month, 1, 12) - 1]
	d_label.text = str(day)
	if wd_label:
		var wd := TimeSystem.weekday_of(day, month)
		wd_label.text = TimeSystem.WEEKDAY_FULL[wd]
		# เสาร์–อาทิตย์ = สีแดง (วันหยุด)
		wd_label.add_theme_color_override(&"font_color", Color(0.78, 0.2, 0.16) if wd >= 5 else Color(0.45, 0.32, 0.2))


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
