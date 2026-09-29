class_name GuideMarker extends Control
## ไกด์ "คลิกตรงนี้" — วงกลมกะพริบ + ลูกศรเด้ง + ป้ายข้อความ ตามชิ้นใน 3D (หรือจุดคงที่)
## สร้างผ่าน Phase3D.hint() — ไม่ต้องวางในซีน · [Claude 30 ก.ย. 2569]

const COL_RING := Color(1.0, 0.82, 0.3)
const COL_INK := Color(0.2, 0.12, 0.06)
const COL_PAPER := Color(0.98, 0.93, 0.8)

var stage: PartStage3D
var target: Node3D
var text := "คลิกตรงนี้"
var radius := 34.0
var _t := 0.0
var _font: Font


static func follow(p_parent: Control, p_stage: PartStage3D, p_target: Node3D, p_text: String) -> GuideMarker:
	var m := GuideMarker.new()
	m.stage = p_stage
	m.target = p_target
	m.text = p_text
	p_parent.add_child(m)
	return m


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true
	z_index = 50
	_font = get_theme_default_font()


func _process(delta: float) -> void:
	_t += delta
	if stage and is_instance_valid(target):
		global_position = stage.screen_pos_of(target.global_position)
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	var r := radius * (0.9 + 0.2 * pulse)
	draw_arc(Vector2.ZERO, r + 4, 0, TAU, 48, Color(COL_INK, 0.9), 7, true)
	draw_arc(Vector2.ZERO, r + 4, 0, TAU, 48, Color(COL_RING, 0.6 + 0.4 * pulse), 4, true)
	# ลูกศรชี้ลงเหนือวง
	# ชิดขอบบนจอ → ย้ายลูกศร/ป้ายไปไว้ใต้วงกลม (ชี้ขึ้น)
	var flip := global_position.y < 150.0
	var sgn := -1.0 if flip else 1.0
	var y: float = sgn * (-r - 26 - 8 * abs(sin(_t * 4.0)))
	var tri := PackedVector2Array([Vector2(-14, y - 16 * sgn), Vector2(14, y - 16 * sgn), Vector2(0, y + 4 * sgn)])
	draw_colored_polygon(tri, COL_RING)
	draw_polyline(tri + PackedVector2Array([tri[0]]), COL_INK, 3, true)
	if text != "" and _font:
		var fs := 18
		var w: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var by: float = y + 20.0 if flip else y - 50.0
		var box := Rect2(-w / 2 - 10, by, w + 20, 30)
		draw_rect(box, COL_PAPER)
		draw_rect(box, COL_INK, false, 3)
		draw_string(_font, Vector2(-w / 2, by + 22), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, COL_INK)
