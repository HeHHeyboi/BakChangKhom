class_name ViewNav extends CanvasLayer
## ปุ่ม "◀ กลับ" ลอยมุมซ้าย (ใต้การ์ดความคืบหน้า) — ย้ายมุมกล้องด้วยการกดจุดในฉาก (Hotspot2D) แล้วกดปุ่มนี้ถอยออก
## [Claude 1 ต.ค.] เอาแถบแท็บสลับมุมออกแล้ว ฉากโล่งขึ้น · ไกด์ชี้ที่ปุ่มนี้เมื่อเป้าหมายอยู่มุมอื่นที่ไม่มีทางกดไปตรง ๆ
## คีย์ลัด: Esc / Backspace / ปุ่มข้างเมาส์ = กลับ · สร้างเองผ่าน Phase2D.cam() ไม่ต้องวางในซีน
## [Claude 30 ก.ย. 2569]

const POS := Vector2(12, 86)

var stage: Stage2D
var _back: Button
var _chips := {} # StringName → Button


static func ensure(host: Node, st: Stage2D) -> ViewNav:
	var n := host.get_node_or_null("ViewNav") as ViewNav
	if n == null:
		n = ViewNav.new()
		n.name = "ViewNav"
		n.stage = st
		host.add_child(n)
	return n


func _ready() -> void:
	layer = 110 # ใต้แถบปิ๊บ (120) และสมุด (128)
	_back = _button("◀ กลับ", true)
	_back.tooltip_text = "กลับ (Esc)"
	_back.position = POS
	_back.pressed.connect(_go_back)
	add_child(_back)
	stage.back_anchor = _back
	stage.view_name_changed.connect(_refresh)
	_refresh(stage.current_view)


func set_enabled(on: bool) -> void:
	visible = on


func _can_go_back() -> bool:
	return stage.can_back() or stage.current_view != stage.start_view


## ย้อนมุมก่อนหน้า · ไม่มีประวัติ (มาด้วย cam() ของ phase) → กลับภาพรวม
func _go_back() -> void:
	if stage.can_back():
		stage.back()
	else:
		stage.reset_view()


func _refresh(_view: StringName) -> void:
	_back.visible = _can_go_back()


func _unhandled_input(e: InputEvent) -> void:
	if not visible or not _can_go_back() or not get_tree().get_nodes_in_group("modal").is_empty():
		return
	var go := false
	if e is InputEventKey and e.pressed and not e.echo:
		go = e.keycode == KEY_ESCAPE or e.keycode == KEY_BACKSPACE
	elif e is InputEventMouseButton and e.pressed:
		go = e.button_index == MOUSE_BUTTON_XBUTTON1
	if go:
		_go_back()
		get_viewport().set_input_as_handled()


func _button(text: String, is_back: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 36)
	b.add_theme_font_size_override("font_size", 17)
	b.set_meta("back", is_back)
	_style(b, false)
	return b


## กระดาษครีม = ปุ่มปกติ · ส้ม = มุมที่อยู่ตอนนี้ / ปุ่มกลับ
func _style(b: Button, active: bool) -> void:
	var hot: bool = active or b.get_meta("back", false)
	var sb := StyleBoxFlat.new()
	sb.bg_color = PhaseUI.COL_HEAD if hot else PhaseUI.COL_PAPER
	sb.border_color = PhaseUI.COL_EDGE
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	var hover := sb.duplicate() as StyleBoxFlat
	hover.bg_color = sb.bg_color.lightened(0.12)
	for st in ["normal", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	var fc := PhaseUI.COL_PAPER if hot else PhaseUI.COL_INK
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fc)
