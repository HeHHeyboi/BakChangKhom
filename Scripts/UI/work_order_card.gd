class_name WorkOrderCard extends PanelContainer
## [Claude 15 พ.ย. 2569 · 0.3.0 ขั้น C] ใบรับเครื่อง (WorkOrderLayer ชั้น 91 ใน day_loop.tscn) — เลือกวันนัดลูกค้ามารับเครื่อง
## DayLoop เปิดตอนกด "รับเครื่อง" งานฮาร์ดแวร์ (DayLoop.open_work_order) · ยืนยัน → DayLoop.door_accept(index) → เครื่องขึ้นชั้น
## แสดงผลอย่างเดียว: view จาก DayLoop.work_order_view() · ตัวเลือกวันนัด = ปุ่มเลือกได้ 1 อัน (สร้างจาก view)

signal confirmed(promise_index: int)
signal cancelled

## สไตล์ปุ่มตัวเลือกวันนัด (ตั้งใน work_order_card.tscn) · เลือกอยู่ = สีส้มขอบหนา
@export var option_normal: StyleBox
@export var option_hover: StyleBox
@export var option_selected: StyleBox
@export var option_disabled: StyleBox
@export var option_font := Color(0.35, 0.2, 0.08)
@export var option_font_disabled := Color(0.55, 0.5, 0.44)

var _group := ButtonGroup.new()


func _ready() -> void:
	%Confirm.pressed.connect(_on_confirm)
	%Cancel.pressed.connect(func() -> void: cancelled.emit())


## v = { title, shelf, detail, hint, options: [{index, label, sub, disabled}], selected: index }
func show_view(v: Dictionary) -> void:
	%Title.text = String(v.get("title", "ใบรับเครื่อง"))
	%Shelf.text = String(v.get("shelf", ""))
	%Detail.text = String(v.get("detail", ""))
	%Hint.text = String(v.get("hint", ""))
	for n in %Options.get_children():
		%Options.remove_child(n)
		n.queue_free()
	var sel := int(v.get("selected", -1))
	var opts: Array = v.get("options", [])
	for o: Dictionary in opts:
		var b := Button.new()
		b.name = "Option%d" % int(o.get("index", 0))
		b.toggle_mode = true
		b.button_group = _group
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%s\n%s" % [String(o.get("label", "")), String(o.get("sub", ""))]
		b.disabled = bool(o.get("disabled", false))
		b.set_meta(&"promise", int(o.get("index", 0)))
		_style_option(b)
		b.button_pressed = int(o.get("index", -2)) == sel and not b.disabled
		b.toggled.connect(func(_on: bool) -> void: _sync_confirm())
		%Options.add_child(b)
	_sync_confirm()
	visible = true
	reset_size()


func _style_option(b: Button) -> void:
	b.add_theme_font_size_override(&"font_size", 15)
	for k in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color", &"font_focus_color"]:
		b.add_theme_color_override(k, option_font)
	b.add_theme_color_override(&"font_disabled_color", option_font_disabled)
	if option_normal:
		b.add_theme_stylebox_override(&"normal", option_normal)
	if option_hover:
		b.add_theme_stylebox_override(&"hover", option_hover)
	if option_selected:
		b.add_theme_stylebox_override(&"pressed", option_selected)
		b.add_theme_stylebox_override(&"hover_pressed", option_selected)
	if option_disabled:
		b.add_theme_stylebox_override(&"disabled", option_disabled)
	b.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())


## index ของ promise ที่เลือก (-1 = ยังไม่เลือก)
func selected() -> int:
	var b := _group.get_pressed_button()
	return int(b.get_meta(&"promise", -1)) if b else -1


## เลือกตัวเลือกวันนัด (เทส/คีย์ลัด)
func select(promise_index: int) -> void:
	for b in %Options.get_children():
		if b is Button and int(b.get_meta(&"promise", -1)) == promise_index and not b.disabled:
			b.button_pressed = true
	_sync_confirm()


func _sync_confirm() -> void:
	%Confirm.disabled = selected() < 0


func _on_confirm() -> void:
	var i := selected()
	if i >= 0:
		confirmed.emit(i)
