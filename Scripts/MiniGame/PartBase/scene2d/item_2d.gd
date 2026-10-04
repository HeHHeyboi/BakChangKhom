@tool
class_name Item2D extends Control
## ชิ้นในฉาก 2D — รูป PNG 1 ใบต่อ "หน้าตา" · จัดตำแหน่ง/ขนาดใน Editor ได้เลย (เป็น Control ธรรมดา)
## Mode: STATIC = ขยับไม่ได้ · DRAGGABLE = ลากถอด/ใส่ได้ · TOGGLE = คลิกสลับเปิด/ปิด (สลัก) · CLICK = คลิกแล้วส่งสัญญาณ
## หน้าตาเลือกจาก looks ตามลำดับ: "บริบท@สถานะ" → "บริบท" → "@สถานะ" / "สถานะ" → texture
##   บริบท = look ของ socket ที่ชิ้นเสียบอยู่ (เช่น "slot" · "mat" · "case") → ชิ้นเดียวกันหน้าตาต่างกันในแต่ละมุม
##   สถานะ = state (เช่น "dirty" · "clean" · "off") เปลี่ยนด้วย set_state() แบบ crossfade
## ไม่มีรูปเลย (texture ว่าง) = จุดคลิกล่องหน (hotspot) แสดงกรอบเรืองแสงตอนชี้
## [Claude 30 ก.ย. 2569] แทนระบบ 2.5D เดิม (PartBody25D)

enum Mode {
	STATIC,
	DRAGGABLE,
	TOGGLE,
	CLICK,
}

signal toggled(on: bool)
signal clicked

const XFADE := 0.28
const OUTLINE := preload("res://Scripts/MiniGame/PartBase/scene2d/hover_outline.gdshader")
const COL_PLATE := Color(0.98, 0.94, 0.84)
const COL_INK := Color(0.28, 0.18, 0.1)

@export var data: PcPart
@export var mode: Mode = Mode.CLICK
## นับว่าติดตั้งแล้วตั้งแต่เริ่ม (ใช้ตรวจ PcPart.requires)
@export var counts_as_installed := false
@export var texture: Texture2D:
	set(v):
		texture = v
		queue_redraw()
## รูปตอน TOGGLE เปิด (สลักกางออก)
@export var texture_on: Texture2D
## หน้าตาอื่น ๆ (ดูคำอธิบายด้านบน) · ค่า <empty> = ซ่อนรูป (เช่นฝากระจก "open")
@export var looks: Dictionary[String, Texture2D] = { }
			
@export var state := "":
	set(v):
		state = v
		queue_redraw()
@export var start_on := false
## true = ยืดรูปเต็มกรอบ (ภาพบนจอ) · false = รักษาสัดส่วน อยู่กลางกรอบ
@export var stretch := false
## กลับซ้าย-ขวา (เช่นสลักฝั่งขวาใช้รูปเดียวกับฝั่งซ้าย)
@export var mirror := false
## ป้ายชื่อตอนเมาส์ชี้ (แนว Volcano Princess) · ว่าง = ไม่มีป้าย
@export var label_text := ""
## true = ลูกศร/ป้ายไกด์ของชิ้นนี้ไปอยู่ใต้วงกลม (ชี้ขึ้น) — ใช้กับชิ้นที่ป้ายบนไปบังของอื่น
@export var hint_flip := false

var socket: Socket2D
## ทิศ: 0 = ปกติ · 180 = กลับด้าน (รูปกลับซ้าย-ขวา) — ใช้ตรวจร่องบากแรม
var yaw_deg := 0.0
var toggle_on := false
var hovered := false

var _tint := Color(0, 0, 0, 0)
var _prev_tex: Texture2D
var _last_tex: Texture2D
var _xf_t := 1.0
var _blend_to := ""
var _blend := 0.0
var _mat: ShaderMaterial
var _plate: PanelContainer

static var _blank: ImageTexture = ImageTexture.new()

## key ไหนใน looks เป็น null → ใส่รูปโปร่งใสแทน · ทำเฉพาะตอนรันเกม (ใน Editor จะไปฝัง ImageTexture ลงไฟล์ .tscn)
func _fill_null_looks() -> void:
	if Engine.is_editor_hint():
		return
	for k in looks.keys():
		if looks[k] == null:
			looks[k] = _blank

static func _masks() -> Dictionary:
	if not Engine.has_meta("item2d_masks"):
		Engine.set_meta("item2d_masks", { })
	return Engine.get_meta("item2d_masks")


func _ready() -> void:
	_fill_null_looks()
	mouse_filter = Control.MOUSE_FILTER_PASS # Stage2D จัดการเมาส์เอง
	pivot_offset = size / 2.0
	if mode == Mode.TOGGLE:
		toggle_on = start_on
	_last_tex = current_texture()
	if label_text.is_empty():
		return
	# ป้ายชื่อเป็น node ลูก (ไม่วาดในตัว) เพื่อไม่ให้โดน shader outline ตอนชี้ · วางไว้เหนือชิ้น กึ่งกลางแนวนอน
	_plate = PanelContainer.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = COL_PLATE
	style.border_color = COL_INK
	style.set_border_width_all(3)
	style.set_expand_margin_all(2)
	_plate.add_theme_stylebox_override("panel", style)
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.z_index = 10
	_plate.visible = Engine.is_editor_hint()
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = label_text
	label.add_theme_color_override("font_color", COL_INK)
	_plate.add_child(label)
	add_child(_plate)
	_plate.resized.connect(_place_plate)
	resized.connect(_place_plate)
	_place_plate()


## ป้ายอยู่เหนือชิ้น · ถ้าชิ้นอยู่ชิดขอบบนจอ (ป้ายจะหลุดจอ) ให้ซ้อนลงมาในชิ้นแทน
func _place_plate() -> void:
	if _plate == null:
		return
	var y := -_plate.size.y - 6.0
	if y + get_global_rect().position.y < 60.0:
		y = 0.0
	_plate.position = Vector2((size.x - _plate.size.x) / 2.0, y)

# ---------------------------------------------------------------- หน้าตา


func look_context() -> String:
	return socket.look if socket else ""


## รูปที่ควรแสดงตอนนี้ (null = ไม่แสดง)
func current_texture() -> Texture2D:
	if mode == Mode.TOGGLE and toggle_on and texture_on:
		return texture_on
	return texture_for(look_context(), state)


func texture_for(ctx: String, st: String) -> Texture2D:
	var keys: Array[String] = []
	if ctx != "" and st != "":
		keys.append(ctx + "@" + st)
	if ctx != "":
		keys.append(ctx)
	if st != "":
		keys.append("@" + st)
		keys.append(st)
	for k in keys:
		if looks.has(k):
			return looks[k]
	return texture


func is_hotspot() -> bool:
	return texture == null and looks.is_empty()


func _process(delta: float) -> void:
	var t := current_texture()
	if t != _last_tex:
		if not Engine.is_editor_hint() and is_visible_in_tree():
			_prev_tex = _last_tex
			_xf_t = 0.0
		_last_tex = t
	if _xf_t < 1.0:
		_xf_t = minf(1.0, _xf_t + delta / XFADE)
		if _xf_t >= 1.0:
			_prev_tex = null
		queue_redraw()


func _flip() -> bool:
	return mirror != (roundi(fposmod(yaw_deg, 360.0)) == 180)


func _tex_rect(t: Texture2D) -> Rect2:
	if stretch or t == null:
		return Rect2(Vector2.ZERO, size)
	var ts := t.get_size()
	var s := minf(size.x / ts.x, size.y / ts.y)
	var d := ts * s
	return Rect2((size - d) / 2.0, d)


func _draw() -> void:
	var cur := current_texture()
	if is_hotspot():
		if hovered or Engine.is_editor_hint():
			var c := Color(1, 0.86, 0.35, 0.95 if hovered else 0.35)
			draw_rect(Rect2(Vector2.ZERO, size).grow(-2), Color(c, 0.12 if hovered else 0.0))
			_draw_dashed_rect(Rect2(Vector2.ZERO, size).grow(-2), c)
		return
	var mod := Color.WHITE
	if _tint.a > 0.0:
		mod = Color.WHITE.lerp(_tint, 0.6)
	if _prev_tex and _xf_t < 1.0:
		_draw_tex(_prev_tex, Color(mod, 1.0 - _xf_t))
	if cur:
		_draw_tex(cur, Color(mod, _xf_t if _prev_tex else 1.0))
	if _blend > 0.001 and _blend_to != "":
		var bt := texture_for(look_context(), _blend_to)
		if bt and bt != cur:
			_draw_tex(bt, Color(mod, _blend))


func _draw_tex(t: Texture2D, mod: Color) -> void:
	var r := _tex_rect(t)
	if _flip():
		# [Claude 1 ต.ค.] กลับซ้าย-ขวารอบกลางชิ้น — เดิมใช้ Rect ความกว้างติดลบ รูปเลยเลื่อนออกไปทางขวาเท่าความกว้าง (สลักขวาลอยห่างสล็อต)
		draw_set_transform(Vector2(size.x, 0), 0.0, Vector2(-1, 1))
		draw_texture_rect(t, r, false, mod)
		draw_set_transform(Vector2.ZERO)
		return
	draw_texture_rect(t, r, false, mod)


func _draw_dashed_rect(r: Rect2, c: Color) -> void:
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	for i in 4:
		draw_dashed_line(pts[i], pts[i + 1], c, 3.0, 10.0)

# ---------------------------------------------------------------- คลิก


## จุด (พิกัดของชิ้นนี้) โดนเนื้อรูปไหม
func hit_local(p: Vector2) -> bool:
	if not Rect2(Vector2.ZERO, size).grow(4).has_point(p):
		return false
	var t := current_texture()
	if t == null:
		return is_hotspot()
	var r := _tex_rect(t)
	if not r.grow(4).has_point(p):
		return false
	var bm := _mask(t)
	if bm == null:
		return true
	var bs := Vector2(bm.get_size())
	for d: Vector2 in [Vector2.ZERO, Vector2(4, 0), Vector2(-4, 0), Vector2(0, 4), Vector2(0, -4)]:
		var u := ((p + d) - r.position) / r.size
		if _flip():
			u.x = 1.0 - u.x
		var q := u * bs
		if q.x >= 0 and q.y >= 0 and q.x < bs.x and q.y < bs.y and bm.get_bitv(Vector2i(q)):
			return true
	return false


static func _mask(t: Texture2D) -> BitMap:
	var m := _masks()
	if m.has(t):
		return m[t]
	var bm: BitMap = null
	var img := t.get_image()
	if img and not img.is_empty():
		if img.is_compressed():
			img.decompress()
		bm = BitMap.new()
		bm.create_from_image_alpha(img, 0.5)
	m[t] = bm
	return bm


func set_hover(on: bool) -> void:
	if hovered == on:
		return
	hovered = on
	if _plate and not Engine.is_editor_hint():
		_plate.visible = on
		if on:
			_place_plate()
	if on and not is_hotspot():
		if _mat == null:
			_mat = ShaderMaterial.new()
			_mat.shader = OUTLINE
		material = _mat
	else:
		material = null
	queue_redraw()

# ---------------------------------------------------------------- สถานะ


## เปลี่ยนหน้าตา (crossfade อัตโนมัติ)
func set_state(p_state: String) -> void:
	state = p_state
	_blend = 0.0
	_blend_to = ""


## ค่อย ๆ เปลี่ยนจากสถานะ from ไป to ตามความคืบหน้า t (0..1) — ฝุ่นจาง · ขาทองวาว
func set_state_blend(from: String, to: String, t: float) -> void:
	if t >= 0.999:
		state = to
		_last_tex = current_texture()
		_blend = 0.0
		_blend_to = ""
	else:
		state = from
		_blend_to = to
		_blend = clampf(t, 0.0, 1.0)
	queue_redraw()


## ย้ายแบบภาพ: จางหาย → โผล่ที่ใหม่
func fade_move(to_pos: Vector2, dur := 0.35) -> Tween:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, dur * 0.45)
	tw.tween_callback(
		func():
			position = to_pos,
	)
	tw.tween_property(self, "modulate:a", 1.0, dur * 0.55)
	return tw


func set_yaw(deg: float, _animate := true) -> void:
	yaw_deg = fposmod(deg, 360.0)
	queue_redraw()


func set_toggle(on: bool, _animate := true) -> void:
	toggle_on = on
	queue_redraw()
	toggled.emit(on)


func tint(c: Color) -> void:
	_tint = c
	queue_redraw()


func clear_tint() -> void:
	_tint = Color(0, 0, 0, 0)
	queue_redraw()


## ใช้แทนของเดิม (ภาพวาดจากโค้ด) — ระบบ 2D ใช้รูปสถานะแทน จึงไม่ต้องทำอะไร
func set_layer_alpha(_prefix: String, _a: float) -> void:
	pass


func set_shape_color(_prefix: String, _c: Color) -> void:
	pass


func add_overlay(_n: String, _t: Texture2D, _c := Color.WHITE, _f := 0, _h := 1.0, _y := 0.0) -> void:
	pass
