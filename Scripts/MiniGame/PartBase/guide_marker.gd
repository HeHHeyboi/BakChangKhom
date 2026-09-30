class_name GuideMarker extends Control
## ไกด์ "คลิกตรงนี้" — วงกลมกะพริบ + ลูกศรเด้ง + ป้ายข้อความ ตามชิ้นในฉาก 2D (ชิ้นอยู่มุมอื่น = ชี้ที่จุดกดที่พาไปมุมนั้น)
## สร้างผ่าน Phase2D.hint() — ไม่ต้องวางในซีน · [Claude 30 ก.ย. 2569]

const SCENE_PATH := "res://Scene/MiniGame/PartBase/guide_marker.tscn" # load ตอนเรียก — preload จะวนอ้างอิงกับสคริปต์นี้

@export var col_ring := Color(1.0, 0.82, 0.3)
@export var col_ink := Color(0.2, 0.12, 0.06)
@export var col_paper := Color(0.98, 0.93, 0.8)
@export var text := "คลิกตรงนี้"
@export var radius := 34.0

var stage: Stage2D
var target: Control
var _t := 0.0
var _font: Font
var flip = false


## สร้างจากซีน guide_marker.tscn (ปรับสี/ขนาดใน Editor ได้)
static func create() -> GuideMarker:
	return (load(SCENE_PATH) as PackedScene).instantiate() as GuideMarker


static func follow(p_parent: Control, p_stage: Stage2D, p_target: Control, p_text: String) -> GuideMarker:
	var m := create()
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
		var p = stage.screen_pos_of_node(target)
		visible = p != null
		if p != null:
			global_position = p
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	var r := radius * (0.9 + 0.2 * pulse)
	draw_arc(Vector2.ZERO, r + 4, 0, TAU, 48, Color(col_ink, 0.9), 7, true)
	draw_arc(Vector2.ZERO, r + 4, 0, TAU, 48, Color(col_ring, 0.6 + 0.4 * pulse), 4, true)
	# ลูกศรชี้ลงเหนือวง
	# ชิดขอบบนจอ → ย้ายลูกศร/ป้ายไปไว้ใต้วงกลม (ชี้ขึ้น)
	var flip := global_position.y < 150.0 or flip
	var sgn := -1.0 if flip else 1.0
	var y: float = sgn * (-r - 26 - 8 * abs(sin(_t * 4.0)))
	var tri := PackedVector2Array([Vector2(-14, y - 16 * sgn), Vector2(14, y - 16 * sgn), Vector2(0, y + 4 * sgn)])
	draw_colored_polygon(tri, col_ring)
	draw_polyline(tri + PackedVector2Array([tri[0]]), col_ink, 3, true)
	if text != "" and _font:
		var fs := 18
		var w: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var by: float = y + 20.0 if flip else y - 50.0
		var box := Rect2(-w / 2 - 10, by, w + 20, 30)
		draw_rect(box, col_paper)
		draw_rect(box, col_ink, false, 3)
		draw_string(_font, Vector2(-w / 2, by + 22), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col_ink)
