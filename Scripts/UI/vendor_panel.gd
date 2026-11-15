class_name VendorPanel extends Control
## [Claude 15 พ.ย. 2569 · 0.4.0 ขั้น J] รถขายของ (VendorLayer ชั้น 92 ใน day_loop.tscn) — PLAN_0_4_0 ข้อ 6
## ปุ่ม "รถขายของ · อีก n เทิร์น" มุมล่าง (ข้างปุ่มชั้นวาง) โผล่เฉพาะตอนรถจอดหน้าร้าน → แผงของ 3 ชิ้น ราคาลด · ปุ่ม "ซื้อ"
## แสดงผลอย่างเดียว: DayLoop ส่ง view (DayLoop.vendor_view()) ทุกเฟรม · กด "ซื้อ" → buy_pressed(index) → DayLoop.vendor_buy(i)

signal buy_pressed(index: int)

@export var row_style: StyleBox
@export var status_color := Color(0.35, 0.2, 0.08)
@export var warn_color := Color(0.75, 0.25, 0.1)
@export var window_bottom := 574.0
@export var window_left := 300.0

var _last_hash := 0


func _ready() -> void:
	%OpenButton.pressed.connect(toggle)
	%CloseButton.pressed.connect(close)


func toggle() -> void:
	%Window.visible = not %Window.visible


func close() -> void:
	%Window.visible = false


func is_open() -> bool:
	return %Window.visible


## v = { show, button, title, note, rows: [{ name, status, warn, icon, buy: {text, disabled} }] }
func show_view(v: Dictionary) -> void:
	var show := bool(v.get("show", false))
	%OpenButton.visible = show
	if not show:
		%Window.visible = false
		_last_hash = 0
		return
	var h := v.hash()
	if h == _last_hash:
		return
	_last_hash = h
	%OpenButton.text = String(v.get("button", ""))
	%Title.text = String(v.get("title", ""))
	%Note.text = String(v.get("note", ""))
	for n in %List.get_children():
		%List.remove_child(n)
		n.queue_free()
	var rows: Array = v.get("rows", [])
	%Empty.visible = rows.is_empty()
	for i in rows.size():
		%List.add_child(_row(i, rows[i]))
	_place_window()


func _process(_d: float) -> void:
	if %Window.visible:
		_place_window()


func _place_window() -> void:
	var w: Control = %Window
	var m := w.get_combined_minimum_size()
	if absf(w.size.y - m.y) > 1.0 or absf(w.size.x - m.x) > 1.0:
		w.size = m
	w.position = Vector2(window_left, window_bottom - w.size.y)


func _row(i: int, r: Dictionary) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Row%d" % i
	if row_style:
		p.add_theme_stylebox_override(&"panel", row_style)
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 8)
	p.add_child(h)
	var ic := TextureRect.new()
	ic.texture = r.get("icon") as Texture2D
	ic.custom_minimum_size = Vector2(44, 44)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(ic)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override(&"separation", 2)
	h.add_child(info)
	var name_l := Label.new()
	name_l.name = "Name"
	name_l.text = String(r.get("name", ""))
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.add_theme_font_size_override(&"font_size", 16)
	name_l.add_theme_color_override(&"font_color", Color(0.15, 0.12, 0.1))
	info.add_child(name_l)
	var st := Label.new()
	st.name = "Status"
	st.text = String(r.get("status", ""))
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.add_theme_font_size_override(&"font_size", 13)
	st.add_theme_color_override(&"font_color", warn_color if r.get("warn", false) else status_color)
	info.add_child(st)
	var bp: Dictionary = r.get("buy", { })
	var b := Button.new()
	b.name = "Buy"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(96, 0)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.text = String(bp.get("text", "ซื้อ"))
	b.disabled = bool(bp.get("disabled", false))
	b.pressed.connect(func() -> void: buy_pressed.emit(i))
	h.add_child(b)
	return p
