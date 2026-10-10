@tool
class_name MapCard extends Button
## การ์ดสถานที่บนแผนที่ (รูป + ชื่อ) — กดแล้วไปฉากนั้นทันที ไม่ต้องเดิน
## ตั้งค่าทุกอย่างใน Inspector: ชื่อ · ฉากปลายทาง · รูป · คำอธิบาย (ปิ๊บพูดตอนชี้) · ล็อก
## [Claude 10 ต.ค. 2569] ใช้ใน Scene/map.tscn (Root/Cards) · รูปการ์ดอยู่ Assets/Map/loc_*.jpg (สร้างจาก Assets/Map/src/gen_map.py)

signal card_hovered(card: MapCard, on: bool)

## ชื่อสถานที่ (ป้ายใต้รูป)
@export var title := "สถานที่":
	set(v):
		title = v
		_apply()
## ฉากปลายทาง (ตรงกับ SceneRouter.LocationID)
@export_enum("บ้าน:0", "ร้านช่างขม:1", "Workshop:2", "Workbench:3", "ตลาด:4", "หน้าบ้าน:5") var location := 0
## รูปสถานที่
@export var thumbnail: Texture2D:
	set(v):
		thumbnail = v
		_apply()
## ปิ๊บพูดอะไรตอนชี้การ์ดนี้
@export_multiline var hint := ""
## ยังไปไม่ได้ (ขึ้นแถบมืด + ข้อความ locked_text)
@export var locked := false:
	set(v):
		locked = v
		_apply()
## ข้อความบนการ์ดที่ล็อก
@export var locked_text := "เร็ว ๆ นี้":
	set(v):
		locked_text = v
		_apply()

## ขมอยู่ที่นี่ตอนนี้ (map.gd ตั้งให้ตอนเปิดแผนที่)
var is_here := false:
	set(v):
		is_here = v
		_apply()


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pivot_offset = size / 2.0
	if not mouse_entered.is_connected(_on_hover):
		mouse_entered.connect(_on_hover.bind(true))
		mouse_exited.connect(_on_hover.bind(false))
	_apply()


func _apply() -> void:
	if not is_inside_tree():
		return
	var thumb := get_node_or_null(^"Thumb") as TextureRect
	if thumb:
		thumb.texture = thumbnail
		thumb.modulate = Color(0.55, 0.55, 0.6) if locked else Color.WHITE
	var nm := get_node_or_null(^"Name") as Label
	if nm:
		nm.text = title
	var lk := get_node_or_null(^"Lock") as Control
	if lk:
		lk.visible = locked
		var ll := lk.get_node_or_null(^"Text") as Label
		if ll:
			ll.text = locked_text
	var here := get_node_or_null(^"Here") as Control
	if here:
		here.visible = is_here


func _on_hover(on: bool) -> void:
	if Engine.is_editor_hint():
		return
	pivot_offset = size / 2.0
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE * (1.07 if on and not locked else 1.0), 0.12)
	card_hovered.emit(self, on)
