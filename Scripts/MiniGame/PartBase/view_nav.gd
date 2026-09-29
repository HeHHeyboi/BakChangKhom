class_name ViewNav extends CanvasLayer
## แถบนำทางกล้อง (บนซ้ายของฉาก) — ปุ่ม "◀ กลับ" + ปุ่มสลับมุม (ภาพรวม · จอ · ในเคส · เมนบอร์ด …)
## ปุ่มมาจาก CameraPoint3D ที่ตั้ง label ไว้ · มุมที่อยู่ตอนนี้เป็นสีส้ม · มุมซูมย่อย (ไม่มี label) กด "กลับ" ออก
## คีย์ลัด: Esc / Backspace / ปุ่มข้างเมาส์ = กลับ · สร้างเองผ่าน Phase3D.cam() ไม่ต้องวางในซีน
## [Claude 30 ก.ย. 2569]

const POS := Vector2(12, 64)

var stage: PartStage3D
var _back: Button
var _chips := {} # StringName → Button


static func ensure(host: Node, st: PartStage3D) -> ViewNav:
	var n := host.get_node_or_null("ViewNav") as ViewNav
	if n == null:
		n = ViewNav.new()
		n.name = "ViewNav"
		n.stage = st
		host.add_child(n)
	return n


func _ready() -> void:
	layer = 110 # ใต้แถบปิ๊บ (120) และสมุด (128)
	var row := HBoxContainer.new()
	row.position = POS
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	_back = _button("◀ กลับ", true)
	_back.tooltip_text = "กลับไปมุมก่อนหน้า (Esc)"
	_back.pressed.connect(stage.back)
	row.add_child(_back)
	for p in stage.nav_views():
		var b := _button(p.label, false)
		b.pressed.connect(stage.go_to.bind(p.name))
		row.add_child(b)
		_chips[p.name] = b
	stage.view_name_changed.connect(_refresh)
	_refresh(stage.current_view)


func set_enabled(on: bool) -> void:
	visible = on


func _refresh(view: StringName) -> void:
	_back.visible = stage.can_back()
	for k in _chips:
		_style(_chips[k], k == view)


func _unhandled_input(e: InputEvent) -> void:
	if not visible or not stage.can_back() or not get_tree().get_nodes_in_group("modal").is_empty():
		return
	var go := false
	if e is InputEventKey and e.pressed and not e.echo:
		go = e.keycode == KEY_ESCAPE or e.keycode == KEY_BACKSPACE
	elif e is InputEventMouseButton and e.pressed:
		go = e.button_index == MOUSE_BUTTON_XBUTTON1
	if go:
		stage.back()
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
