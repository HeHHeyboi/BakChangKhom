class_name OsWindow extends PanelContainer
## หน้าต่าง 1 บานในขมOS — แถบหัว (ไอคอน · ชื่อ · [_] [×]) ลากย้ายได้ · คลิกแล้วขึ้นมาหน้าสุด
## เนื้อหาใส่ใน body · DesktopMinigame สร้างให้ (open_window) · [Claude 9 ต.ค. 2569]

signal closed
signal minimized

const TITLE_H := 32
const C_FRAME := Color(0.97, 0.96, 0.93)
const C_TITLE := Color(0.29, 0.45, 0.62)
const C_TITLE_DIM := Color(0.55, 0.6, 0.66)
const C_INK := Color(0.23, 0.16, 0.11)

var key := ""
var body: VBoxContainer
var title_label: Label
var close_btn: Button
var min_btn: Button
var closable := true
var _bar: PanelContainer
var _bar_style: StyleBoxFlat
var _drag := false
var _drag_off := Vector2.ZERO


static func make(p_key: String, p_title: String, icon: Texture2D, p_size: Vector2) -> OsWindow:
	var w := OsWindow.new()
	w.key = p_key
	w.name = "Win_" + p_key.validate_node_name()
	w.custom_minimum_size = p_size
	w.size = p_size
	w._build(p_title, icon)
	return w


func _build(p_title: String, icon: Texture2D) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_FRAME
	sb.border_color = C_INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(3, 5)
	add_theme_stylebox_override("panel", sb)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	add_child(col)

	_bar = PanelContainer.new()
	_bar_style = StyleBoxFlat.new()
	_bar_style.bg_color = C_TITLE
	_bar_style.corner_radius_top_left = 6
	_bar_style.corner_radius_top_right = 6
	_bar_style.content_margin_left = 8
	_bar_style.content_margin_right = 4
	_bar.add_theme_stylebox_override("panel", _bar_style)
	_bar.custom_minimum_size.y = TITLE_H
	_bar.gui_input.connect(_on_bar_input)
	col.add_child(_bar)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(row)
	if icon:
		var ic := TextureRect.new()
		ic.texture = icon
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(22, 22)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(ic)
	title_label = Label.new()
	title_label.text = p_title
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.clip_text = true
	row.add_child(title_label)
	min_btn = _bar_button("–")
	min_btn.tooltip_text = "ย่อ"
	min_btn.pressed.connect(func(): minimize())
	row.add_child(min_btn)
	close_btn = _bar_button("×")
	close_btn.tooltip_text = "ปิด"
	close_btn.pressed.connect(close)
	row.add_child(close_btn)

	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 10)
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(pad)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	pad.add_child(body)


func _bar_button(t: String) -> Button:
	var b := Button.new()
	b.text = t
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(30, 26)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_font_size_override("font_size", 18)
	return b


func set_active(on: bool) -> void:
	if _bar_style:
		_bar_style.bg_color = C_TITLE if on else C_TITLE_DIM


func close() -> void:
	if not closable:
		return
	closed.emit()
	queue_free()


func minimize() -> void:
	hide()
	minimized.emit()


func restore() -> void:
	show()
	move_to_front()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		move_to_front()


func _on_bar_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_drag = event.pressed
		_drag_off = event.global_position - global_position
		if event.pressed:
			move_to_front()
	elif event is InputEventMouseMotion and _drag:
		var p: Vector2 = event.global_position - _drag_off
		var area := get_parent_area_size()
		position = Vector2(clampf(p.x, -size.x + 80, area.x - 80), clampf(p.y, 0, area.y - TITLE_H))
