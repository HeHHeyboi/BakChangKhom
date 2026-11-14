class_name RepairShelfPanel extends Control
## [Claude 15 พ.ย. 2569 · 0.3.0 ขั้น D] แผงชั้นวางเครื่อง (ShelfLayer ชั้น 95 ใน day_loop.tscn)
## ปุ่ม "ชั้นวาง n/m" มุมล่าง (ข้างปุ่มคลัง) → แผงรายการเครื่องที่รับไว้: ลูกค้า · เครื่อง · สถานะ · วันนัด · ปุ่ม "ซ่อม"
## แสดงผลอย่างเดียว: DayLoop ส่ง view (DayLoop.shelf_view()) ทุกเฟรม · สร้างแถวใหม่เฉพาะตอน view เปลี่ยน · กด "ซ่อม" → repair_pressed(index)

signal repair_pressed(index: int)

## กล่องพื้นหลังของแต่ละแถว
@export var row_style: StyleBox
## สีบรรทัดสถานะ: ปกติ / เตือน (ถึงนัด/เลยนัด) / เสร็จแล้ว
@export var status_color := Color(0.35, 0.2, 0.08)
@export var warn_color := Color(0.75, 0.25, 0.1)
@export var done_color := Color(0.25, 0.5, 0.2)

var _last_hash := 0
## ขอบล่างของแผงรายการ (เหนือปุ่มชั้นวาง/คลัง) · แผงสูงขึ้นข้างบนตามจำนวนเครื่อง
@export var window_bottom := 574.0
@export var window_left := 12.0


func _ready() -> void:
	%OpenButton.pressed.connect(toggle)
	%CloseButton.pressed.connect(close)


func toggle() -> void:
	%Window.visible = not %Window.visible


func open() -> void:
	%Window.visible = true


func close() -> void:
	%Window.visible = false


func is_open() -> bool:
	return %Window.visible


## v = { show: bool (ปุ่มโชว์ได้ไหม), button: "ชั้นวาง 1/2", alert: bool, title, note, empty,
##       rows: [{ name, status, state: &"wait"/&"done", warn: bool, repair: {text, disabled, visible, tooltip} }] }
func show_view(v: Dictionary) -> void:
	var show := bool(v.get("show", false))
	%OpenButton.visible = show
	if not show:
		%Window.visible = false
	var h := v.hash()
	if h == _last_hash:
		return
	_last_hash = h
	%OpenButton.text = String(v.get("button", ""))
	%OpenButton.modulate = Color(1, 0.85, 0.75) if v.get("alert", false) else Color.WHITE
	%Title.text = String(v.get("title", ""))
	var note := String(v.get("note", ""))
	%Note.text = note
	%Note.visible = note != ""
	for n in %List.get_children():
		%List.remove_child(n)
		n.queue_free()
	var rows: Array = v.get("rows", [])
	%Empty.visible = rows.is_empty()
	%Empty.text = String(v.get("empty", ""))
	for i in rows.size():
		%List.add_child(_row(i, rows[i]))
	_place_window()


func _process(_d: float) -> void:
	if %Window.visible:
		_place_window()


## กว้างตาม custom_minimum_size · สูงเท่าเนื้อหา · ชิดขอบล่าง window_bottom
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
	var col := status_color
	if r.get("state", &"wait") == &"done":
		col = done_color
	if r.get("warn", false):
		col = warn_color
	st.add_theme_color_override(&"font_color", col)
	info.add_child(st)
	var rp: Dictionary = r.get("repair", { })
	var b := Button.new()
	b.name = "Repair"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(118, 0)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.visible = bool(rp.get("visible", true))
	b.text = String(rp.get("text", "ซ่อม"))
	b.disabled = bool(rp.get("disabled", false))
	b.tooltip_text = String(rp.get("tooltip", ""))
	b.pressed.connect(func() -> void: repair_pressed.emit(i))
	h.add_child(b)
	return p
