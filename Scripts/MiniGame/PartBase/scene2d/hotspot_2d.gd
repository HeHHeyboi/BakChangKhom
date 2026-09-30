@tool
class_name Hotspot2D extends Control
## จุดกดเข้ามุมอื่น (แนว Volcano Princess: ป้ายชื่อ + กรอบเรืองแสงตอนชี้) · ตอนถือชิ้นส่วนอยู่ = "ประตู" พาไปมุมนั้น
## ใส่เป็นลูกของ View2D · target_view = ชื่อ node ของ View2D ปลายทาง

const COL_PLATE := Color(0.98, 0.94, 0.84)
const COL_INK := Color(0.28, 0.18, 0.1)
const COL_GLOW := Color(1, 0.86, 0.35)

@export var target_view: StringName
@export var label_text := ""
## แสดงป้ายตลอด (true) หรือเฉพาะตอนเมาส์ชี้ (false)
@export var always_show_label := true
## ใช้เป็นประตูตอนถือชิ้นส่วน (ลากมาค้างไว้แป๊บเดียว = ไปมุมนั้น)
@export var portal := true

var hovered := false
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	if hovered:
		queue_redraw()


func set_hover(on: bool) -> void:
	hovered = on
	queue_redraw()


func hit_local(p: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(p)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size).grow(-2)
	var holding := false
	var st := get_parent().get_parent().get_parent() if get_parent() else null
	if st is Stage2D and st.held() != null and portal:
		holding = true
	if hovered or holding or Engine.is_editor_hint():
		var pulse := 0.6 + 0.4 * sin(_t * 6.0)
		var c := Color(COL_GLOW, (0.95 if hovered else 0.6) * (pulse if hovered else 1.0))
		draw_rect(r, Color(COL_GLOW, 0.14 if hovered else 0.06))
		var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
		for i in 4:
			draw_dashed_line(pts[i], pts[i + 1], c, 3.0, 12.0)
	if label_text != "" and (always_show_label or hovered or holding or Engine.is_editor_hint()):
		var f := get_theme_default_font()
		var fs := 17
		var w := f.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var box := Rect2(size.x / 2.0 - w / 2.0 - 12, -30, w + 24, 28)
		if box.position.y + get_global_rect().position.y < 60:
			box.position.y = 4
		draw_rect(Rect2(box.position + Vector2(2, 3), box.size), Color(0, 0, 0, 0.35))
		draw_rect(box, COL_PLATE)
		draw_rect(box, COL_INK, false, 3)
		draw_string(f, Vector2(box.position.x + 12, box.position.y + 20), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, COL_INK)
