class_name WorkOrderApp extends VBoxContainer
## [Claude 15 พ.ย. 2569 · 0.3.0] แอป "งานซ่อม" ในคอมของขม (ขมOS เล่นอิสระ · ShopPC ใส่ผ่าน DesktopMinigameV2.add_custom_app)
## ตารางใบรับเครื่องแบ่งตามวันนัด (เลยนัด · วันนี้ · วันเปิดร้านถัดไป · อีก n วัน) + คนรอรับหน้าร้าน/คนนัดมาหน้าร้าน
## ปุ่มต่อแถว: ไปซ่อม (ปิดคอม → มินิเกม) · เลื่อนนัด +1 วัน · โทรเรียกมารับเลย (ซ่อมเสร็จแล้ว)
## แสดงผลอย่างเดียว: view = DayLoop.work_app_view() (เช็กทุก 0.25 วิ · วาดใหม่เมื่อเปลี่ยน) · กดปุ่ม → DayLoop.work_app_action(i, id)

@export var row_style: StyleBox
@export var main_button: StyleBox
@export var main_button_hover: StyleBox
@export var side_button: StyleBox
@export var button_disabled: StyleBox
@export var font := Color(0.35, 0.2, 0.08)
@export var warn := Color(0.75, 0.25, 0.1)
@export var done := Color(0.25, 0.5, 0.2)

var _last_hash := 0
var _t := 0.0


func _ready() -> void:
	refresh()


func _process(delta: float) -> void:
	_t += delta
	if _t >= 0.25:
		_t = 0.0
		refresh()


func refresh() -> void:
	var dl := get_node_or_null(^"/root/DayLoop")
	if dl == null:
		return
	show_view(dl.work_app_view())


## v = { title, shelf, note, empty, sections: [{ title, warn, rows: [{ name, status, state, warn, actions: [{id, text, disabled, tooltip}] }] }] }
func show_view(v: Dictionary) -> void:
	var h := v.hash()
	if h == _last_hash:
		return
	_last_hash = h
	%Title.text = String(v.get("title", ""))
	%Shelf.text = String(v.get("shelf", ""))
	%Note.text = String(v.get("note", ""))
	for n in %List.get_children():
		%List.remove_child(n)
		n.queue_free()
	var sections: Array = v.get("sections", [])
	%Empty.visible = sections.is_empty()
	%Empty.text = String(v.get("empty", ""))
	for s: Dictionary in sections:
		var head := Label.new()
		head.text = String(s.get("title", ""))
		head.add_theme_font_size_override(&"font_size", 15)
		head.add_theme_color_override(&"font_color", warn if s.get("warn", false) else font)
		%List.add_child(head)
		for r: Dictionary in s.get("rows", []):
			%List.add_child(_row(r))


func _row(r: Dictionary) -> PanelContainer:
	var p := PanelContainer.new()
	if row_style:
		p.add_theme_stylebox_override(&"panel", row_style)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override(&"separation", 8)
	p.add_child(hb)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override(&"separation", 0)
	hb.add_child(info)
	var n := Label.new()
	n.name = "Name"
	n.text = String(r.get("name", ""))
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.add_theme_font_size_override(&"font_size", 15)
	n.add_theme_color_override(&"font_color", Color(0.15, 0.12, 0.1))
	info.add_child(n)
	var st := Label.new()
	st.name = "Status"
	st.text = String(r.get("status", ""))
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.add_theme_font_size_override(&"font_size", 12)
	var col := font
	if r.get("state", &"wait") == &"done":
		col = done
	if r.get("warn", false):
		col = warn
	st.add_theme_color_override(&"font_color", col)
	info.add_child(st)
	var acts: Array = r.get("actions", [])
	if not acts.is_empty():
		var bx := VBoxContainer.new()
		bx.add_theme_constant_override(&"separation", 4)
		bx.custom_minimum_size = Vector2(128, 0)
		hb.add_child(bx)
		var row_i := int(r.get("index", -1))
		for k in acts.size():
			var a: Dictionary = acts[k]
			bx.add_child(_button(a, row_i, k == 0))
	return p


func _button(a: Dictionary, row_i: int, primary: bool) -> Button:
	var b := Button.new()
	b.name = "Btn_" + String(a.get("id", ""))
	b.text = String(a.get("text", ""))
	b.disabled = bool(a.get("disabled", false))
	b.tooltip_text = String(a.get("tooltip", ""))
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override(&"font_size", 13)
	for c in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
		b.add_theme_color_override(c, Color(0.23, 0.16, 0.11))
	b.add_theme_color_override(&"font_disabled_color", Color(0.55, 0.5, 0.44))
	var normal := main_button if primary else side_button
	if normal:
		b.add_theme_stylebox_override(&"normal", normal)
	if main_button_hover:
		b.add_theme_stylebox_override(&"hover", main_button_hover)
		b.add_theme_stylebox_override(&"pressed", main_button_hover)
	if button_disabled:
		b.add_theme_stylebox_override(&"disabled", button_disabled)
	var id: StringName = a.get("id", &"")
	b.pressed.connect(_on_action.bind(row_i, id))
	return b


func _on_action(row_i: int, id: StringName) -> void:
	var dl := get_node_or_null(^"/root/DayLoop")
	if dl == null:
		return
	var ok: bool = dl.work_app_action(row_i, id)
	_last_hash = 0
	if ok and id == &"repair":
		# ปิดคอม → DayLoop เปิดมินิเกมเครื่องนี้เมื่อกลับมาที่หน้าร้าน
		var n: Node = self
		while n and not n.has_method(&"shut_down"):
			n = n.get_parent()
		if n:
			n.shut_down()
	else:
		refresh()
