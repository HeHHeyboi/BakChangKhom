class_name SeatTarget extends Control
## จุดที่ผู้เล่นต้องกดตอน "ติดตั้งให้แน่น" ในบทฝึกประกอบคอม (phase_build._seat)
##   SCREW = น็อต (กดแล้วหมุนขันแน่น) · LEVER = คันล็อกซีพียู (กดแล้วพับลง) · PUSH = จุดกดลง (M.2)
## next = ตัวที่ต้องกดตอนนี้ (วงแหวนกะพริบ) · กดตัวอื่นก่อน → สัญญาณ wrong_order (ปิ๊บเตือนขันทแยง)
## [Claude 9 ต.ค. 2569]

signal done(t: SeatTarget)
signal wrong_order(t: SeatTarget)

enum Kind { SCREW, LEVER, PUSH }

const C_INK := Color(0.16, 0.12, 0.09)
const C_METAL := Color(0.78, 0.8, 0.84)
const C_METAL_DARK := Color(0.5, 0.52, 0.56)
const C_RING := Color(1.0, 0.86, 0.3)

var kind: Kind = Kind.SCREW
var next := false:
	set(v):
		next = v
		queue_redraw()
var finished := false
var _t := 0.0
## LEVER: มุมตอนยกค้าง (เรเดียน) → พับลงเป็น 0
var lever_open := 0.75


static func make(p_kind: Kind, center: Vector2, p_size := Vector2(20, 20)) -> SeatTarget:
	var t := SeatTarget.new()
	t.kind = p_kind
	t.size = p_size
	t.custom_minimum_size = p_size
	if p_kind == Kind.LEVER:
		# จุดหมุนอยู่ปลายล่างของคันโยก
		t.pivot_offset = Vector2(p_size.x / 2.0, p_size.y)
		t.position = center - t.pivot_offset
		t.rotation = t.lever_open
	else:
		t.pivot_offset = p_size / 2.0
		t.position = center - p_size / 2.0
	t.mouse_filter = Control.MOUSE_FILTER_STOP
	t.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	t.name = "Seat%s" % Kind.find_key(p_kind).capitalize()
	return t


func _process(delta: float) -> void:
	if next and not finished:
		_t += delta
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		press()


## กด (เรียกจากเทสต์ได้) · ยังไม่ถึงคิว → wrong_order
func press() -> void:
	if finished:
		return
	if not next:
		wrong_order.emit(self)
		return
	finished = true
	next = false
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	var tw := create_tween()
	match kind:
		Kind.SCREW:
			tw.tween_property(self, "rotation", rotation + TAU * 1.5, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(self, "scale", Vector2(0.85, 0.85), 0.35)
		Kind.LEVER:
			tw.tween_property(self, "rotation", 0.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		Kind.PUSH:
			tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func(): done.emit(self))
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	match kind:
		Kind.SCREW:
			var r := minf(size.x, size.y) / 2.0 - 1.0
			draw_circle(c, r, C_METAL_DARK if finished else C_METAL)
			draw_arc(c, r, 0, TAU, 24, C_INK, 2.0, true)
			var k := r * 0.55
			draw_line(c - Vector2(k, 0), c + Vector2(k, 0), C_INK, 2.5, true)
			draw_line(c - Vector2(0, k), c + Vector2(0, k), C_INK, 2.5, true)
		Kind.LEVER:
			var w := size.x
			draw_rect(Rect2(Vector2(w * 0.3, 4), Vector2(w * 0.4, size.y - 6)), C_METAL)
			draw_rect(Rect2(Vector2(w * 0.3, 4), Vector2(w * 0.4, size.y - 6)), C_INK, false, 1.5)
			draw_circle(Vector2(w / 2.0, 5), w * 0.45, C_METAL)
			draw_arc(Vector2(w / 2.0, 5), w * 0.45, 0, TAU, 16, C_INK, 1.5, true)
			draw_circle(Vector2(w / 2.0, size.y - 2), 3.0, C_INK)
		Kind.PUSH:
			if not finished:
				draw_arc(c, minf(size.x, size.y) / 2.0 - 2.0, 0, TAU, 32, Color(C_RING, 0.9), 3.0, true)
				draw_line(c + Vector2(0, -6), c + Vector2(0, 6), C_RING, 3.0, true)
				draw_line(c + Vector2(-5, 1), c + Vector2(0, 6), C_RING, 3.0, true)
				draw_line(c + Vector2(5, 1), c + Vector2(0, 6), C_RING, 3.0, true)
	if next and not finished:
		var pulse := 0.5 + 0.5 * sin(_t * 6.0)
		var rr := maxf(size.x, size.y) / 2.0 + 4.0 + pulse * 4.0
		var cc := c if kind != Kind.LEVER else Vector2(size.x / 2.0, 5)
		draw_arc(cc, rr if kind != Kind.LEVER else 10.0 + pulse * 4.0, 0, TAU, 32, Color(C_RING, 0.5 + pulse * 0.5), 2.5, true)
