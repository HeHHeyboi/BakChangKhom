@tool
class_name SceneHotspot extends TextureButton
## จุดกดในฉาก (ไม่ต้องมีรูป) — วางทับของในภาพพื้นหลัง เช่น คอมบนโต๊ะ · ประตู
## ชี้แล้วมีกรอบเรืองแสง + ป้ายชื่อ (label_text) · ในเอดิเตอร์เห็นกรอบประให้ลากปรับขนาดได้
## ใส่รูปก็ได้ (texture_normal / texture_hover) — กรอบยังวาดทับตอนชี้
## [Claude 9 ต.ค. 2569] ใช้ใน Scene/Location/Room.tscn (คอมของขม · ทางออก)

## ป้ายที่ขึ้นตอนชี้ เช่น "คอมของขม"
@export var label_text := "":
	set(v):
		label_text = v
		queue_redraw()
## สีกรอบ/ป้าย
@export var glow := Color(1.0, 0.86, 0.35)
## ป้ายอยู่ใต้กรอบ (ปกติอยู่บน)
@export var label_below := false

var _hover := false


func _ready() -> void:
	ignore_texture_size = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = ""
	if not mouse_entered.is_connected(_on_hover):
		mouse_entered.connect(_on_hover.bind(true))
		mouse_exited.connect(_on_hover.bind(false))


func _on_hover(on: bool) -> void:
	_hover = on
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if Engine.is_editor_hint():
		draw_rect(r, Color(glow, 0.8), false, 2.0)
	if not _hover or disabled:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(glow, 0.12)
	sb.border_color = glow
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(glow, 0.45)
	sb.shadow_size = 10
	draw_style_box(sb, r)
	if label_text == "":
		return
	var font := get_theme_default_font()
	var fs := 20
	var ts := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var plate := Rect2(Vector2((size.x - ts.x) / 2.0 - 12, 0), ts + Vector2(24, 12))
	plate.position.y = size.y + 6 if label_below else -plate.size.y - 6
	plate.position.x = clampf(plate.position.x, -global_position.x + 4, get_viewport_rect().size.x - global_position.x - plate.size.x - 4)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.23, 0.16, 0.11, 0.92)
	ps.border_color = glow
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	draw_style_box(ps, plate)
	draw_string(font, plate.position + Vector2(12, 6 + font.get_ascent(fs)), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
