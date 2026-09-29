@tool
class_name PartBody3D extends StaticBody3D
## ชิ้นส่วนในฉาก 3D ที่สร้างรูปร่างจาก PcPart — กล่อง/ทรงกระบอก + แผ่นรูป PNG หรือรายละเอียดจากโค้ด (ไม่มีไฟล์โมเดล)
## วางเป็น node ในซีนได้เลย: ตั้ง Data (.tres) + Mode ใน Inspector แล้วเห็นหน้าตาใน Editor ทันที (@tool)
## Mode: STATIC = ขยับไม่ได้ · DRAGGABLE = ลากถอด/ใส่ได้ · TOGGLE = คลิกสลับเปิด/ปิด (สลัก ก้านล็อก สวิตช์)
##       CLICK = คลิกแล้วส่งสัญญาณเฉย ๆ (จุดสังเกต ปุ่มเปิดเครื่อง ปลั๊ก)

enum Mode { STATIC, DRAGGABLE, TOGGLE, CLICK }

## แนวภาพ: true = การ์ดตูนสีเรียบ + ขอบดำ (เข้ากับฉาก 2D ของเกม) · false = 3D ปกติ
const TOON := true
## ความหนาขอบดำ (พิกเซลบนจอ) · 0 = ไม่มีขอบ
const OUTLINE_PX := 3.5
## ลบมุมกล่องให้ดูนุ่ม (หน่วย 1 = 10 ซม.) · 0 = กล่องเหลี่ยมเดิม · ชิ้นบางกว่า BEVEL_MIN ไม่ลบมุม [30 ก.ย.]
const BEVEL := 0.07
const BEVEL_MIN := 0.03

signal toggled(on: bool)
signal clicked

@export var data: PcPart:
	set(v):
		data = v
		if is_inside_tree():
			_rebuild()
@export var mode: Mode = Mode.DRAGGABLE
## นับว่า "ติดตั้งแล้ว" ตั้งแต่เริ่ม (เช่นเมนบอร์ดที่วางอยู่แล้ว) — ใช้ตรวจ PcPart.requires
@export var counts_as_installed := false
## ใช้ .tres เดียวกันได้หลายขนาด/สี (เช่นผนังเคสทุกด้านใช้ case_panel.tres) · ศูนย์ = ใช้ค่าใน data
@export var size_override := Vector3.ZERO:
	set(v):
		size_override = v
		if is_inside_tree():
			_rebuild()
@export var color_override := Color(0, 0, 0, 0):
	set(v):
		color_override = v
		if is_inside_tree():
			_rebuild()
## รูปแปะทับ (เช่นจอมอนิเตอร์ที่เปลี่ยนภาพตามสถานะ) — เปลี่ยนตอนเล่นด้วย set_texture()
@export var texture_override: Texture2D:
	set(v):
		texture_override = v
		if is_inside_tree():
			_rebuild()

@export_group("Toggle")
@export var toggle_axis := Vector3.RIGHT
@export var toggle_angle := 40.0
@export var start_on := false: # true = เปิด/กางออกตั้งแต่เริ่ม
	set(v):
		start_on = v
		if _visual:
			_apply_toggle(v, false)

var socket: Socket3D # socket ที่ติดตั้งอยู่ (null = อยู่ในมือ/ลอย)
var yaw_deg := 0.0
var toggle_on := false

var _visual: Node3D
var _collision: CollisionShape3D


static func create(p: PcPart, m: Mode = Mode.DRAGGABLE) -> PartBody3D:
	var b := PartBody3D.new()
	b.mode = m
	b.data = p
	b.name = String(p.id)
	return b


func _ready() -> void:
	_rebuild()
	yaw_deg = fposmod(rotation_degrees.y, 360.0)
	if mode == Mode.TOGGLE:
		_apply_toggle(start_on, false)


# ---------------------------------------------------------------- สร้างรูปร่าง

func _rebuild() -> void:
	if _visual:
		_visual.queue_free()
		_visual = null
	if _collision:
		_collision.queue_free()
		_collision = null
	if data == null:
		return
	var s := get_size()
	_visual = Node3D.new()
	_visual.name = "_Visual"
	add_child(_visual) # ไม่ตั้ง owner → ไม่ถูกเซฟลงไฟล์ซีน สร้างใหม่ทุกครั้งจาก data
	# TOGGLE หมุนรอบขอบล่าง (เหมือนสลักจริง)
	var root := _visual
	if mode == Mode.TOGGLE:
		_visual.position.y = -s.y / 2.0
		root = Node3D.new()
		root.position.y = s.y / 2.0
		_visual.add_child(root)

	if data.procedural == "none":
		_box(root, s, Vector3.ZERO, get_color(), data.shape == "cylinder")
		if _tex() and data.texture_face != PcPart.Face.NONE:
			_add_texture_faces(root)
		if data.notch_pos >= 0.0:
			_add_notch(root)
	else:
		_build_procedural(root)

	_collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(maxf(s.x, 0.03), maxf(s.y, 0.03), maxf(s.z, 0.03))
	if data.shape == "cylinder":
		shape.size = Vector3(s.x, s.y, s.x) # ชิ้นบางมากคลิกยาก → ขยายกล่องชนนิดหน่อย
	_collision.shape = shape
	add_child(_collision)


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, cylinder := false, metal := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if cylinder:
		var c := CylinderMesh.new()
		c.top_radius = size.x / 2.0
		c.bottom_radius = size.x / 2.0
		c.height = size.y
		mi.mesh = c
	elif BEVEL > 0.0 and minf(size.x, minf(size.y, size.z)) >= BEVEL_MIN:
		mi.mesh = _rounded_box(size)
	else:
		var b := BoxMesh.new()
		b.size = size
		mi.mesh = b
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if TOON:
		# แนวการ์ตูนให้เข้ากับฉาก 2D: สีเรียบ 2 โทน + ขอบดำหนา (inverted hull)
		m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		m.roughness = 1.0
	else:
		m.roughness = 0.35 if metal > 0 else 0.8
		m.metallic = metal
	if color.a < 1.0: # กระจก/ของโปร่ง
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	elif TOON and OUTLINE_PX > 0.0:
		m.next_pass = _outline_mat(size)
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi


static var _rbox_cache := {}


## กล่องลบมุม (chamfer): 6 หน้า + 12 แถบขอบ + 8 มุมสามเหลี่ยม · แชร์ mesh ระหว่างชิ้นขนาดเท่ากัน
static func _rounded_box(size: Vector3) -> ArrayMesh:
	if _rbox_cache.has(size):
		return _rbox_cache[size]
	var h := size / 2.0
	var r := minf(BEVEL, minf(h.x, minf(h.y, h.z)) * 0.5)
	var i := h - Vector3(r, r, r)
	# จุดของมุม (sx,sy,sz): ยื่นแกน X / Y / Z
	var pts := func(sx: float, sy: float, sz: float, axis: int) -> Vector3:
		var p := Vector3(sx * i.x, sy * i.y, sz * i.z)
		p[axis] = [sx, sy, sz][axis] * h[axis]
		return p
	var polys: Array = []
	var S := [-1.0, 1.0]
	for axis in 3: # หน้าหลัก
		for sg in S:
			var q: Array = []
			for a: float in S:
				for b: float in S:
					var c := [0.0, 0.0, 0.0]
					c[axis] = sg
					c[(axis + 1) % 3] = a
					c[(axis + 2) % 3] = b * (a) # วนรอบให้เป็นสี่เหลี่ยม
					q.append(pts.call(c[0], c[1], c[2], axis))
			polys.append(q)
	for axis in 3: # แถบขอบ ขนานแกน axis
		var u := (axis + 1) % 3
		var v := (axis + 2) % 3
		for su in S:
			for sv in S:
				var q: Array = []
				for e in [[-1.0, u], [1.0, u], [1.0, v], [-1.0, v]]:
					var c := [0.0, 0.0, 0.0]
					c[axis] = e[0]
					c[u] = su
					c[v] = sv
					q.append(pts.call(c[0], c[1], c[2], e[1]))
				polys.append(q)
	for sx in S: # มุม
		for sy in S:
			for sz in S:
				polys.append([pts.call(sx, sy, sz, 0), pts.call(sx, sy, sz, 1), pts.call(sx, sy, sz, 2)])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for q in polys:
		var ctr := Vector3.ZERO
		for p: Vector3 in q:
			ctr += p
		ctr /= float(q.size())
		# เรียงจุดรอบศูนย์กลางให้เป็นรูปหลายเหลี่ยมนูน (กันลำดับสลับ)
		var n: Vector3 = (q[1] - q[0]).cross(q[2] - q[0]).normalized()
		if n.length() < 0.5 or n.dot(ctr) < 0.0:
			n = ctr.normalized() if n.length() < 0.5 else -n
		var t: Vector3 = (q[0] - ctr).normalized()
		var bt: Vector3 = n.cross(t)
		q.sort_custom(func(a: Vector3, b: Vector3) -> bool: return atan2((a - ctr).dot(bt), (a - ctr).dot(t)) > atan2((b - ctr).dot(bt), (b - ctr).dot(t)))
		for k in range(1, q.size() - 1): # Godot: หน้าตามเข็มนาฬิกา = ด้านหน้า
			for p in [q[0], q[k], q[k + 1]]:
				st.set_normal(n)
				st.add_vertex(p)
	var m := st.commit()
	_rbox_cache[size] = m
	return m


## แรมแท่ง DDR4 สัดส่วนจริง (133 × 31 มม. · PCB 1.3 มม.) — ความยาวอยู่แกน Z · ความสูงแกน Y
func _build_procedural(root: Node3D) -> void:
	var s := get_size()
	match data.procedural:
		"dimm":
			var gold_h := s.y * 0.1
			_box(root, Vector3(s.x, s.y - gold_h, s.z), Vector3(0, gold_h / 2, 0), get_color()).name = "PCB"
			# ขาทอง แบ่งสองท่อนเว้นร่องบาก
			var n := clampf(data.notch_pos if data.notch_pos >= 0 else 0.5, 0.05, 0.95)
			var gap := 0.012
			var z0 := -s.z / 2
			var cut := z0 + s.z * n
			var gold := Color(0.93, 0.73, 0.25)
			var y_g := -s.y / 2 + gold_h / 2
			_box(root, Vector3(s.x * 1.05, gold_h, cut - gap / 2 - z0), Vector3(0, y_g, (z0 + cut - gap / 2) / 2), gold, false, 0.9).name = "Gold1"
			_box(root, Vector3(s.x * 1.05, gold_h, s.z / 2 - (cut + gap / 2)), Vector3(0, y_g, (cut + gap / 2 + s.z / 2) / 2), gold, false, 0.9).name = "Gold2"
			# ชิปหน่วยความจำ 8 ตัวต่อด้าน
			var chip := Vector3(s.x * 0.9, s.y * 0.36, s.z * 0.1)
			for side in [-1.0, 1.0]:
				for i in 8:
					var zc := z0 + s.z * (0.09 + i * 0.115)
					_box(root, chip, Vector3(side * (s.x / 2 + chip.x / 2), s.y * 0.1, zc), Color(0.07, 0.07, 0.08))
			# สติกเกอร์ฉลาก
			_box(root, Vector3(0.001, s.y * 0.12, s.z * 0.25), Vector3(s.x / 2 + chip.x + 0.0005, s.y * 0.36, 0), Color(0.85, 0.85, 0.8))
		"dimm_slot":
			_box(root, s, Vector3.ZERO, get_color()) # ตัวสล็อต
			_box(root, Vector3(s.x * 0.3, 0.004, s.z * 0.96), Vector3(0, s.y / 2, 0), Color(0.02, 0.02, 0.02)) # ร่องรับแรม
			if data.notch_pos >= 0.0:
				# สันกันเสียบกลับด้าน — ตรงกับร่องบากของแรม
				_box(root, Vector3(s.x * 0.32, 0.006, 0.01), Vector3(0, s.y / 2 + 0.002, -s.z / 2 + s.z * data.notch_pos), Color(0.95, 0.8, 0.2))


const OUTLINE_SHADER := preload("res://Scripts/MiniGame/PartBase/stage3d/toon_outline.gdshader")
static var _outline_shared: ShaderMaterial


## ขอบดำรอบชิ้น — หนาเท่ากันบนจอ (ดู toon_outline.gdshader) · ใช้วัสดุร่วมกันทุกชิ้น
static func _outline_mat(_size: Vector3) -> ShaderMaterial:
	if _outline_shared == null:
		_outline_shared = ShaderMaterial.new()
		_outline_shared.shader = OUTLINE_SHADER
		_outline_shared.set_shader_parameter("width_px", OUTLINE_PX)
	return _outline_shared


func _face_quad(root: Node3D, quad_size: Vector2, pos: Vector3, rot: Vector3) -> void:
	var q := QuadMesh.new()
	q.size = quad_size
	var mi := MeshInstance3D.new()
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.roughness = 0.7
	if TOON:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED # รูปวาด 2D แสดงสีตามรูปจริง
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot
	root.add_child(mi)


func _add_texture_faces(root: Node3D) -> void:
	var s := get_size()
	const E := 0.002 # ยกผิวรูปให้ลอยเหนือกล่องนิดเดียว กันกระพริบ
	match data.texture_face:
		PcPart.Face.TOP:
			_face_quad(root, Vector2(s.x, s.z), Vector3(0, s.y / 2 + E, 0), Vector3(-90, 0, 0))
		PcPart.Face.SIDE_X:
			_face_quad(root, Vector2(s.z, s.y), Vector3(s.x / 2 + E, 0, 0), Vector3(0, 90, 0))
			_face_quad(root, Vector2(s.z, s.y), Vector3(-s.x / 2 - E, 0, 0), Vector3(0, -90, 0))
		PcPart.Face.SIDE_Z:
			_face_quad(root, Vector2(s.x, s.y), Vector3(0, 0, s.z / 2 + E), Vector3.ZERO)
			_face_quad(root, Vector2(s.x, s.y), Vector3(0, 0, -s.z / 2 - E), Vector3(0, 180, 0))


func _add_notch(root: Node3D) -> void:
	var s := get_size()
	if s.z >= s.x:
		_box(root, Vector3(s.x + 0.004, s.y * 0.25, 0.02), Vector3(0, -s.y * 0.38, -s.z / 2 + s.z * data.notch_pos), Color(0.05, 0.05, 0.05))
	else:
		_box(root, Vector3(0.02, s.y * 0.25, s.z + 0.004), Vector3(-s.x / 2 + s.x * data.notch_pos, -s.y * 0.38, 0), Color(0.05, 0.05, 0.05))


func get_size() -> Vector3:
	return size_override if size_override != Vector3.ZERO else (data.size if data else Vector3.ONE)


func get_color() -> Color:
	return color_override if color_override.a > 0.0 else data.color


func _tex() -> Texture2D:
	return texture_override if texture_override else data.texture


## เปลี่ยนรูปตอนเล่น (ไม่สร้างรูปร่างใหม่) — ใช้กับจอมอนิเตอร์
func set_texture(t: Texture2D) -> void:
	texture_override = t


## ปรับความทึบของผิวที่ชื่อ node ตรงกับ name_prefix (เช่นชั้นฝุ่น) · 0 = หายหมด
func set_layer_alpha(name_prefix: String, a: float) -> void:
	for mi in _all_meshes(_visual):
		if mi.name.begins_with(name_prefix):
			var c: Color = mi.material_override.albedo_color
			c.a = a
			mi.material_override.albedo_color = c
			mi.visible = a > 0.01


## เพิ่มชั้นผิว (ฝุ่น/คราบ) แปะทับด้านข้างทั้งสองฝั่ง — สำหรับ PCB แรม และสล็อต
func add_overlay(layer_name: String, tex: Texture2D, color := Color.WHITE, face := PcPart.Face.SIDE_X, height_ratio := 1.0, y_offset := 0.0) -> void:
	if _visual == null:
		return
	var root: Node3D = _visual
	var s := get_size()
	var pairs := []
	match face:
		PcPart.Face.SIDE_X:
			var q := Vector2(s.z, s.y * height_ratio)
			pairs = [[q, Vector3(s.x / 2 + 0.006, y_offset, 0), Vector3(0, 90, 0)], [q, Vector3(-s.x / 2 - 0.006, y_offset, 0), Vector3(0, -90, 0)]]
		PcPart.Face.TOP:
			pairs = [[Vector2(s.x, s.z), Vector3(0, s.y / 2 + 0.004, 0), Vector3(-90, 0, 0)]]
	for i in pairs.size():
		var mi := MeshInstance3D.new()
		mi.name = "%s%d" % [layer_name, i]
		var qm := QuadMesh.new()
		qm.size = pairs[i][0]
		mi.mesh = qm
		var m := StandardMaterial3D.new()
		m.albedo_texture = tex
		m.albedo_color = color
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = m
		mi.position = pairs[i][1]
		mi.rotation_degrees = pairs[i][2]
		root.add_child(mi)


## เรืองแสงบาง ๆ ตอนเมาส์ชี้ (ให้รู้ว่าคลิกได้)
func set_hover(on: bool) -> void:
	for mi in _all_meshes(_visual):
		var m := mi.material_override as StandardMaterial3D
		m.emission_enabled = on
		if on:
			m.emission = Color(0.35, 0.55, 0.9)
			m.emission_energy_multiplier = 0.35


# ---------------------------------------------------------------- สถานะ

func set_yaw(deg: float, animate := true) -> void:
	yaw_deg = fposmod(deg, 360.0)
	if animate and is_inside_tree():
		create_tween().tween_property(self, "rotation:y", deg_to_rad(deg), 0.15)
	else:
		rotation.y = deg_to_rad(deg)


func set_toggle(on: bool, animate := true) -> void:
	_apply_toggle(on, animate)
	toggled.emit(on)


func _apply_toggle(on: bool, animate: bool) -> void:
	toggle_on = on
	if _visual == null:
		return
	var target := toggle_axis * deg_to_rad(toggle_angle if on else 0.0)
	if animate and is_inside_tree():
		create_tween().tween_property(_visual, "rotation", target, 0.12)
	else:
		_visual.rotation = target


func tint(c: Color) -> void:
	for mi in _all_meshes(_visual):
		if not mi.has_meta("base"):
			mi.set_meta("base", mi.material_override.albedo_color)
		mi.material_override.albedo_color = (mi.get_meta("base") as Color).lerp(c, 0.6)


func clear_tint() -> void:
	for mi in _all_meshes(_visual):
		if mi.has_meta("base"):
			mi.material_override.albedo_color = mi.get_meta("base")


func _all_meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n == null:
		return out
	for c in n.get_children():
		if c is MeshInstance3D and c.material_override:
			out.append(c)
		out.append_array(_all_meshes(c))
	return out
