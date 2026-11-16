class_name OfficeTaskCard
extends CanvasLayer
## [Claude 16 พ.ย. 2569 · 0.9.5 ขั้น C] การ์ดตั๋วไอทีซัพพอร์ตที่ออฟฟิศในเมือง — ชั้น 119 · สร้างจากโค้ด · แผงเล็ก (กว้าง PANEL_W)
## ขั้น 1 ตรวจ: กดปุ่ม → จอดำพิมพ์คำสั่ง/สิ่งที่เห็นทีละตัว (กดได้หลายปุ่ม) · ขั้น 2 แก้: "ลงมือแก้" → เลือกวิธี (2 คอลัมน์) → ปิ๊บอธิบาย
## แสดง view จาก DayLoop.city_ticket_view · กฎอยู่ที่ DayLoop (city.gd ต่อสัญญาณ)

signal checked(i: int)
signal picked(text: String)
signal done

const PANEL_W := 600
const COL_OK := Color(0.12, 0.48, 0.2)
const COL_BAD := Color(0.7, 0.22, 0.12)
const CODE_BG := Color(0.12, 0.14, 0.18)
const CODE_FG := Color(0.82, 0.93, 0.85)
## วินาทีต่อตัวอักษรตอนพิมพ์ (ต่อครั้ง 0.3–1.2 วิ)
const TYPE_SEC := 0.018

var _kind: Label
var _title: Label
var _ask: Label
var _term_box: PanelContainer
var _term: Label
var _check_label: Label
var _checks: HFlowContainer
var _fix: Button
var _fix_box: VBoxContainer
var _question: Label
var _choices: GridContainer
var _feedback: Label
var _action: Button
var _tw: Tween
var _picked := "" # ตัวเลือกที่ผู้เล่นกด (ไว้ทำสีแดงถ้าผิด)


func _ready() -> void:
	layer = 119 # เหนือ HUD เวลา/เป้าหมาย (100) และคลัง (105) · ใต้ป๊อปอัปความสำเร็จ (120) · ป๊อปอัปเงินขึ้นหลังปิดการ์ด
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.name = "OfficePanel"
	panel.custom_minimum_size = Vector2(PANEL_W, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.99, 0.95, 0.86)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(14)
	sb.border_color = Color(0.45, 0.3, 0.18)
	sb.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	_kind = _label(box, 14, Color(0.55, 0.38, 0.2))
	_title = _label(box, 20, Color(0.25, 0.16, 0.1))
	_ask = _label(box, 15, Color(0.3, 0.22, 0.15))
	# จอดำ
	_term_box = PanelContainer.new()
	_term_box.name = "Terminal"
	_term_box.custom_minimum_size = Vector2(0, 92)
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = CODE_BG
	tsb.set_corner_radius_all(8)
	tsb.set_content_margin_all(8)
	_term_box.add_theme_stylebox_override("panel", tsb)
	box.add_child(_term_box)
	_term = Label.new()
	_term.name = "Text"
	_term.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas", "Cascadia Mono", "Courier New", "DejaVu Sans Mono", "Liberation Mono", "monospace"])
	var thai := load("res://Assets/Fonts/main_font.tres") as Font
	if thai:
		mono.fallbacks = [thai]
	_term.add_theme_font_override("font", mono)
	_term.add_theme_font_size_override("font_size", 14)
	_term.add_theme_color_override("font_color", CODE_FG)
	_term_box.add_child(_term)
	# ขั้น 1 ตรวจ
	_check_label = _label(box, 15, Color(0.25, 0.16, 0.1))
	_check_label.text = "ตรวจอะไรก่อนดี? (กดได้หลายอย่าง)"
	_checks = HFlowContainer.new()
	_checks.name = "Checks"
	_checks.add_theme_constant_override("h_separation", 6)
	_checks.add_theme_constant_override("v_separation", 6)
	box.add_child(_checks)
	_fix = _button(box, "ลงมือแก้ ►", 16)
	_fix.name = "Fix"
	_fix.pressed.connect(_show_fix)
	# ขั้น 2 แก้
	_fix_box = VBoxContainer.new()
	_fix_box.add_theme_constant_override("separation", 6)
	box.add_child(_fix_box)
	_question = _label(_fix_box, 16, Color(0.2, 0.13, 0.08))
	_choices = GridContainer.new()
	_choices.name = "Choices"
	_choices.columns = 2
	_choices.add_theme_constant_override("h_separation", 6)
	_choices.add_theme_constant_override("v_separation", 6)
	_fix_box.add_child(_choices)
	_feedback = _label(box, 14, COL_OK)
	_feedback.name = "Feedback"
	_action = _button(box, "", 16)
	_action.name = "Action"
	_action.pressed.connect(func() -> void: done.emit())


func _label(parent: Node, size: int, col: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l


func _button(parent: Node, text: String, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.custom_minimum_size = Vector2(180, 34)
	parent.add_child(b)
	return b


## v = DayLoop.city_ticket_view() { kind, who, title, ask, actions, question, choices, step, steps }
func show_question(v: Dictionary) -> void:
	_kind.text = "ไอทีซัพพอร์ต · %s · จาก %s · ตั๋ว %d/%d" % [v.get("kind", ""), v.get("who", ""), int(v.get("step", 1)), int(v.get("steps", 1))]
	_title.text = String(v.get("title", ""))
	_ask.text = "\"%s\"" % String(v.get("ask", ""))
	if _tw:
		_tw.kill()
	_term.text = "> รอคำสั่ง_"
	_term.visible_ratio = 1.0
	for c in _checks.get_children():
		c.queue_free()
	var acts: Array = v.get("actions", [])
	for i in acts.size():
		var b := Button.new()
		b.text = String(acts[i])
		b.add_theme_font_size_override("font_size", 14)
		b.custom_minimum_size.y = 30
		b.pressed.connect(func() -> void:
			b.text = "✓ " + String(acts[i])
			checked.emit(i))
		_checks.add_child(b)
	_check_label.show()
	_checks.show()
	_fix.hide()
	_question.text = String(v.get("question", ""))
	for c in _choices.get_children():
		c.queue_free()
	for t in v.get("choices", []):
		var b := Button.new()
		b.text = String(t)
		b.add_theme_font_size_override("font_size", 14)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2((PANEL_W - 40) / 2.0, 44)
		b.pressed.connect(func() -> void:
			_picked = String(t)
			picked.emit(String(t)))
		_choices.add_child(b)
	_fix_box.hide()
	_feedback.hide()
	_action.hide()


## พิมพ์ผลการตรวจลงจอดำทีละตัว · หลังตรวจอย่างแรก ปุ่ม "ลงมือแก้" ขึ้น
func type_out(text: String) -> void:
	if text == "":
		return
	if _tw:
		_tw.kill()
	_term.text = text
	_term.visible_characters = 0
	var n := text.length()
	_tw = create_tween()
	_tw.tween_property(_term, "visible_characters", n, clampf(n * TYPE_SEC, 0.3, 1.2))
	_fix.show()


func _show_fix() -> void:
	if _tw:
		_tw.kill()
	_term.visible_ratio = 1.0
	_check_label.hide()
	_checks.hide()
	_fix.hide()
	_fix_box.show()


## r = { correct, answer, explain, more }
## หลังตอบ: ถูก = เขียว ✓ · ที่เลือกผิด = แดง ✗ · ที่เหลือ = พื้นครีมตัวอักษรเข้ม (อ่านออก ไม่จางจนมองไม่เห็น)
func show_answer(r: Dictionary) -> void:
	var answer := String(r.get("answer", ""))
	for b in _choices.get_children():
		if not b is Button:
			continue
		var btn := b as Button
		var txt := btn.text
		btn.disabled = true
		if txt == answer:
			_style_done(btn, Color(0.2, 0.5, 0.25), Color(1, 1, 1), "✓ ")
		elif txt == _picked:
			_style_done(btn, Color(0.72, 0.27, 0.2), Color(1, 1, 1), "✗ ")
		else:
			_style_done(btn, Color(0.94, 0.9, 0.81), Color(0.38, 0.3, 0.22), "", Color(0.75, 0.65, 0.5))
	var ok := bool(r.get("correct", false))
	_feedback.add_theme_color_override("font_color", COL_OK if ok else COL_BAD)
	_feedback.text = ("แก้ได้! " if ok else "ยังไม่ใช่ · วิธีที่ถูกคือ \"%s\"\n" % String(r.get("answer", ""))) + "ปิ๊บ: " + String(r.get("explain", ""))
	_feedback.show()
	_action.text = "ตั๋วถัดไป ►" if bool(r.get("more", false)) else "ส่งงานให้หัวหน้า"
	_action.show()


func _style_done(btn: Button, bg: Color, fg: Color, mark: String, border := Color(0, 0, 0, 0)) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(6)
	if border.a > 0.0:
		sb.border_color = border
		sb.set_border_width_all(1)
	btn.add_theme_stylebox_override("disabled", sb)
	btn.add_theme_color_override("font_disabled_color", fg)
	btn.text = mark + btn.text
