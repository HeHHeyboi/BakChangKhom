class_name RequestCard
extends CanvasLayer
## [Claude 16 พ.ย. 2569 · 0.6.0 ขั้น G] การ์ดคำขอ (ขอคำปรึกษา/ขอให้ช่วย) — ชั้น 95 · สร้างจากโค้ด
## แสดง view จาก DayLoop (request_view) · ผู้เล่นเลือกคำตอบ → DayLoop.request_answer → ขึ้นคำอธิบาย → ข้อต่อ/เสร็จ
## กฎอยู่ที่ DayLoop · การ์ดนี้แสดงผลอย่างเดียว

signal picked(text: String)
signal done

const COL_HEAD := Color(0.93, 0.73, 0.25)
## ความกว้างแผง (px ที่ฐานจอ 1152×648)
const PANEL_W := 540
const COL_OK := Color(0.12, 0.48, 0.2)
const COL_BAD := Color(0.7, 0.22, 0.12)

var _panel: PanelContainer
var _kind: Label
var _title: Label
var _who: TextureRect
var _ask: Label
var _question: Label
var _choices: VBoxContainer
var _feedback: Label
var _action: Button


func _ready() -> void:
	layer = 95
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	# [0.6.0] แผงกว้างคงที่ PANEL_W อยู่กลางจอเสมอ (CenterContainer) — ไม่ยืดตามข้อความ/หน้าต่าง
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.name = "RequestPanel"
	_panel.custom_minimum_size = Vector2(PANEL_W, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.99, 0.95, 0.86)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(16)
	sb.border_color = Color(0.45, 0.3, 0.18)
	sb.set_border_width_all(3)
	_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	box.add_child(head)
	_who = TextureRect.new()
	_who.custom_minimum_size = Vector2(60, 60)
	_who.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_who.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(_who)
	var hv := VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	_kind = _label(hv, 16, Color(0.55, 0.38, 0.2))
	_kind.name = "Kind"
	_title = _label(hv, 22, Color(0.25, 0.16, 0.1))
	_title.name = "Title"
	_ask = _label(box, 17, Color(0.3, 0.22, 0.15))
	_ask.name = "Ask"
	var sep := HSeparator.new()
	box.add_child(sep)
	_question = _label(box, 18, Color(0.2, 0.13, 0.08))
	_question.name = "Question"
	_choices = VBoxContainer.new()
	_choices.name = "Choices"
	_choices.add_theme_constant_override("separation", 6)
	box.add_child(_choices)
	_feedback = _label(box, 17, COL_OK)
	_feedback.name = "Feedback"
	_action = Button.new()
	_action.name = "Action"
	_action.add_theme_font_size_override("font_size", 19)
	_action.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_action.custom_minimum_size = Vector2(200, 40)
	_action.pressed.connect(func() -> void: done.emit())
	box.add_child(_action)


func _label(parent: Node, size: int, col: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l


## v = { kind, title, ask, who (ชื่อ), portrait, question, choices, step, steps }
func show_question(v: Dictionary) -> void:
	_kind.text = "%s · %s · ข้อ %d/%d" % [v.get("kind", ""), v.get("who", ""), int(v.get("step", 1)), int(v.get("steps", 1))]
	_title.text = String(v.get("title", ""))
	_ask.text = "\"%s\"" % String(v.get("ask", ""))
	_who.texture = v.get("portrait")
	_question.text = String(v.get("question", ""))
	for c in _choices.get_children():
		c.queue_free()
	for t in v.get("choices", []):
		var b := Button.new()
		b.text = String(t)
		b.add_theme_font_size_override("font_size", 17)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.y = 34
		b.pressed.connect(func() -> void: picked.emit(String(t)))
		_choices.add_child(b)
	_feedback.text = ""
	_feedback.hide()
	_action.hide()


## r = { correct, answer, explain, more (มีข้อต่อ) }
func show_answer(r: Dictionary) -> void:
	for b in _choices.get_children():
		if b is Button:
			(b as Button).disabled = true
			if (b as Button).text == String(r.get("answer", "")):
				(b as Button).add_theme_color_override("font_disabled_color", Color(0.85, 1.0, 0.85))
				var ok_sb := StyleBoxFlat.new()
				ok_sb.bg_color = Color(0.2, 0.5, 0.25)
				ok_sb.set_corner_radius_all(4)
				(b as Button).add_theme_stylebox_override("disabled", ok_sb)
	var ok := bool(r.get("correct", false))
	_feedback.add_theme_color_override("font_color", COL_OK if ok else COL_BAD)
	_feedback.show()
	_feedback.text = ("ตอบได้ดี! " if ok else "ยังไม่ใช่ · คำตอบที่ดีกว่าคือ \"%s\"\n" % String(r.get("answer", ""))) + "ปิ๊บ: " + String(r.get("explain", ""))
	_action.text = "ข้อต่อไป ►" if bool(r.get("more", false)) else "เสร็จ"
	_action.show()
