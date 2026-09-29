class_name PartStage3D extends SubViewportContainer
## ฉาก 3D ของมินิเกม Core Part — ใช้ผ่านซีน res://Scene/MiniGame/PartBase/part_stage_3d.tscn
## วาง PartBody3D / Socket3D / CameraPoint3D เป็นลูกของ SubViewport/World ในซีนที่ instance ไป (เปิด Editable Children)
##
## เมาส์: ซ้าย = ลาก/คลิกชิ้นส่วน · ขวาลาก = เลื่อนซ้าย-ขวา + ก้ม-เงย (lock_yaw) หรือหมุนรอบ · ล้อ = ซูม
## คีย์: R = หมุนชิ้นในมือ 180° · Q/E = เลื่อน/หมุนกล้อง · Home = กลับมุมเริ่มต้น
## กล้องและชิ้นที่ถือขยับแบบนุ่ม (smoothing) · phase สั่งย้ายกล้องอัตโนมัติด้วย go_to() / focus_on()
## phase ฟังสัญญาณแล้วตัดสินเอง (หักคะแนน / ให้ปิ๊บพูด) — ฉากนี้ไม่รู้เรื่องคะแนน
## Docs: MINIGAME_PREFAB.md · RAM_3D_GAMEPLAY.md

signal part_picked(part: PartBody3D)
signal part_installed(part: PartBody3D, socket: Socket3D)
signal part_removed(part: PartBody3D, socket: Socket3D) ## ส่งเมื่อชิ้นย้ายไปที่ใหม่สำเร็จ (วางกลับที่เดิม = ไม่ส่ง)
signal drop_rejected(part: PartBody3D, socket: Socket3D, reason: Socket3D.Result)
signal part_toggled(part: PartBody3D, on: bool)
signal part_clicked(part: PartBody3D) ## ชิ้นโหมด CLICK
signal part_returned(part: PartBody3D) ## ปล่อยแล้วกลับที่เดิม (วางไม่ลง/ไม่เจอ socket)
signal view_changed(yaw: float, pitch: float, distance: float)
signal view_name_changed(view: StringName) ## ย้ายไปมุมที่มีชื่อ (go_to / back) — ViewNav ใช้อัปเดตปุ่ม

@export_group("View style")
## แนว 2.5D ด้านข้าง: กล้องหันทิศเดียวตลอด (ไม่หมุนรอบ) · เลื่อนซ้าย-ขวา/ก้ม-เงย/ซูมได้
@export var lock_yaw := true
@export var fixed_yaw := 0.0
## กล้องแบบไม่มีมุมมองลึก (orthographic) — ดูเหมือนภาพวาด 2D มากกว่า · distance = ความสูงภาพที่เห็น
@export var orthographic := true
## พื้นหลังโปร่ง ให้เห็นภาพ 2D ของ part_base (Background) ข้างหลัง
@export var transparent_background := true
@export var pan_limits := Vector2(-8, 9) ## ขอบเขตเลื่อนซ้าย-ขวา (แกน X)
## โหมดสถานี (30 ก.ย.): ผู้เล่นคุมกล้องไม่ได้ · แต่ละ CameraPoint3D เป็น "หน้า" มุมเฉียงตายตัว
## เปลี่ยนสถานีแล้วกล้องหมุนไปหน้าใหม่เอง (ใช้ yaw ของจุดนั้น ไม่สน lock_yaw)
@export var station_mode := true

@export_group("Camera")
@export var focus := Vector3.ZERO ## จุดหมุนเริ่มต้น (ถ้ามี CameraPoint3D ชื่อ start_view จะใช้อันนั้นแทน)
@export var start_view: StringName = &""
@export var start_yaw := -30.0
@export var start_pitch := 45.0
@export var start_distance := 2.0
@export var pitch_limits := Vector2(8, 88)
@export var distance_limits := Vector2(0.5, 14.0)
@export var orbit_speed := 0.35
@export var smoothing := 7.0 ## ยิ่งมากยิ่งตามไว · 0 = ไม่หน่วง

@export_group("Drag")
@export var hold_lift := 0.35 ## ยกชิ้นสูงจากจุดที่หยิบเท่านี้ตอนถือ (หน่วย 10 ซม.)
@export var snap_dist := 0.12 ## ระยะแกน XZ ที่ socket เริ่มดูด (ใช้ตอนสั่งย้ายจากโค้ด)
## ระยะบนจอ (พิกเซล) ที่ socket เริ่มดูดตอนลากด้วยเมาส์ [30 ก.ย.] — เดิมเทียบแกน XZ ที่ความสูงชิ้นในมือ
## ทำให้มุมกล้องก้มมาก ๆ ต้องลากเลยเป้าไปไกล → วางไม่ลง (ถอดแรมไปแผ่น ESD ไม่ได้)
@export var snap_px := 48.0
@export var drag_smoothing := 18.0

@onready var viewport: SubViewport = $SubViewport
@onready var world: Node3D = $SubViewport/World
@onready var _rig: Node3D = $SubViewport/World/CameraRig
@onready var _pitch: Node3D = $SubViewport/World/CameraRig/Pitch
@onready var camera: Camera3D = $SubViewport/World/CameraRig/Pitch/Camera3D

var sockets: Array[Socket3D] = []
var installed_ids: Array[StringName] = []
## ถ้าไม่ว่าง: คลิก/ลากได้เฉพาะชิ้นในลิสต์นี้ (phase ตั้งให้ตรงกับขั้นที่กำลังเล่น)
var allowed: Array[PartBody3D] = []
## ถ้าไม่ว่าง: ชิ้นที่ถือจะดูดเข้าได้เฉพาะ socket ในลิสต์นี้ (ที่เดิมที่หยิบมาดูดได้เสมอ)
var allowed_sockets: Array[Socket3D] = []
## false = ห้ามผู้เล่นหมุนกล้องเอง (ตอนกล้องเคลื่อนอัตโนมัติ)
var user_camera := true

# ค่าปัจจุบัน (ที่เห็น) กับค่าเป้าหมาย (ที่กำลังเลื่อนไปหา)
var _cur := { "focus": Vector3.ZERO, "yaw": 0.0, "pitch": 45.0, "dist": 2.0 }
var _tgt := { "focus": Vector3.ZERO, "yaw": 0.0, "pitch": 45.0, "dist": 2.0 }
var _held: PartBody3D
var _held_target := Vector3.ZERO
var _hold_y := 0.5
var _held_origin: Socket3D
var _held_origin_xf: Transform3D
var _hover: Socket3D
var _hover_part: PartBody3D
var _orbiting := false


func _ready() -> void:
	stretch = true
	viewport.transparent_bg = transparent_background
	var we := world.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and transparent_background:
		we.environment.background_mode = Environment.BG_CLEAR_COLOR
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL if orthographic else Camera3D.PROJECTION_PERSPECTIVE
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	for n in _all_children(world):
		if n is Socket3D:
			sockets.append(n)
		elif n is PartBody3D and n.counts_as_installed:
			installed_ids.append(n.data.id)
	for s in sockets:
		if s.start_occupant:
			install(s.start_occupant, s, false, false)
	_tgt.focus = focus
	_tgt.yaw = start_yaw
	_tgt.pitch = start_pitch
	_tgt.dist = start_distance
	if start_view != &"":
		go_to(start_view)
	_cur = _tgt.duplicate()
	_apply_camera()


func _all_children(n: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c in n.get_children():
		out.append(c)
		out.append_array(_all_children(c))
	return out


# ---------------------------------------------------------------- กล้อง

func _process(delta: float) -> void:
	var k := 1.0 if smoothing <= 0.0 else 1.0 - exp(-smoothing * delta)
	_cur.focus = (_cur.focus as Vector3).lerp(_tgt.focus, k)
	_cur.yaw = lerp_angle(deg_to_rad(_cur.yaw), deg_to_rad(_tgt.yaw), k) * 180.0 / PI
	_cur.pitch = lerpf(_cur.pitch, _tgt.pitch, k)
	_cur.dist = lerpf(_cur.dist, _tgt.dist, k)
	_apply_camera()
	if _held:
		var kd := 1.0 - exp(-drag_smoothing * delta)
		_held.global_position = _held.global_position.lerp(_held_target, kd)


func _apply_camera() -> void:
	_rig.position = _cur.focus
	_rig.rotation = Vector3(0, deg_to_rad(_cur.yaw), 0)
	_pitch.rotation = Vector3(deg_to_rad(-_cur.pitch), 0, 0)
	if orthographic:
		camera.size = _cur.dist
		camera.position = Vector3(0, 0, 40.0) # ไกลพอไม่ตัดฉาก · ขนาดภาพคุมด้วย size
	else:
		camera.position = Vector3(0, 0, _cur.dist)


## เลื่อนกล้องไปที่ CameraPoint3D ชื่อ view_name (ค้นทั้ง World)
## record = จำมุมเดิมไว้ให้ปุ่ม "◀ กลับ" (back() ส่ง false)
func go_to(view_name: StringName, instant := false, record := true) -> void:
	var p: CameraPoint3D = null
	for n in _all_children(world): # ชื่อซ้ำกับชิ้นส่วนได้ (เช่น Monitor) → หาเฉพาะ CameraPoint3D
		if n is CameraPoint3D and n.name == view_name:
			p = n
			break
	if p == null:
		push_warning("PartStage3D: ไม่พบ CameraPoint3D '%s'" % view_name)
		return
	if record and current_view != &"" and current_view != view_name:
		_history.append(current_view)
		if _history.size() > 12:
			_history.pop_front()
	current_view = view_name
	set_view(p.yaw, p.pitch, p.distance, p.global_position, instant)
	view_name_changed.emit(view_name)


# ---------------------------------------------------------------- ย้อนกลับ [30 ก.ย.]
var current_view: StringName = &""
var _history: Array[StringName] = []


func can_back() -> bool:
	return not _history.is_empty()


## กลับไปมุมก่อนหน้า (ปุ่ม "◀ กลับ" · Esc · Backspace · ปุ่มข้างเมาส์)
func back() -> void:
	if not _history.is_empty():
		go_to(_history.pop_back(), false, false)


func clear_history() -> void:
	_history.clear()
	view_name_changed.emit(current_view)


## มุมทุกจุดที่มีชื่อปุ่ม (CameraPoint3D.label) เรียงตามลำดับในซีน
func nav_views() -> Array[CameraPoint3D]:
	var a: Array[CameraPoint3D] = []
	for n in _all_children(world):
		if n is CameraPoint3D and n.label != "":
			a.append(n)
	return a


## หมุนกล้องเข้าหา node (ใช้มุมปัจจุบัน) — เช่นตอนคลิกจุดสังเกต
func focus_on(target: Node3D, distance := -1.0) -> void:
	_tgt.focus = target.global_position
	if distance > 0.0:
		_tgt.dist = clampf(distance, distance_limits.x, distance_limits.y)


func set_view(yaw: float, pitch: float, distance: float, focus_point = null, instant := false) -> void:
	_tgt.yaw = yaw if (station_mode or not lock_yaw) else fixed_yaw
	_tgt.pitch = clampf(pitch, pitch_limits.x, pitch_limits.y)
	_tgt.dist = clampf(distance, distance_limits.x, distance_limits.y)
	if focus_point != null:
		_tgt.focus = focus_point
	if instant:
		_cur = _tgt.duplicate()
		_apply_camera()
	view_changed.emit(_tgt.yaw, _tgt.pitch, _tgt.dist)


func reset_view() -> void:
	if start_view != &"":
		go_to(start_view)
	else:
		set_view(start_yaw, start_pitch, start_distance, focus)


func orbit(d_yaw: float, d_pitch := 0.0) -> void:
	set_view(_tgt.yaw + d_yaw, _tgt.pitch + d_pitch, _tgt.dist)


## เลื่อนกล้องซ้าย-ขวาตามแกน X (ใช้แทนการหมุนรอบในแนวด้านข้าง)
func pan(dx: float) -> void:
	var f: Vector3 = _tgt.focus
	f.x = clampf(f.x + dx, pan_limits.x, pan_limits.y)
	_tgt.focus = f


func zoom(factor: float) -> void:
	set_view(_tgt.yaw, _tgt.pitch, _tgt.dist * factor)


# ---------------------------------------------------------------- สร้างจากโค้ด (ทางเลือก — ปกติวาง node ในซีน)

func add_part(p: PcPart, pos: Vector3, m := PartBody3D.Mode.DRAGGABLE, yaw := 0.0) -> PartBody3D:
	var b := PartBody3D.create(p, m)
	b.position = pos
	world.add_child(b)
	b.set_yaw(yaw, false)
	return b


## วางชิ้นลง socket (ตั้งฉากเริ่มต้น หรือหลังตรวจผ่าน)
func install(part: PartBody3D, s: Socket3D, animate := true, emit := true) -> void:
	s.occupant = part
	part.socket = s
	var target := s.global_position + Vector3(0, part.get_size().y / 2.0, 0)
	if animate:
		create_tween().tween_property(part, "global_position", target, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		part.global_position = target
	if not s.accept_any:
		installed_ids.append(part.data.id) # เก็บซ้ำได้ (แรม 2 แถว id เดียวกัน) · erase() ลบทีละตัว
	if emit:
		part_installed.emit(part, s)


func rotate_held(step := 180.0) -> void:
	if _held:
		_held.set_yaw(_held.yaw_deg + step)
		_update_hover()


func held() -> PartBody3D:
	return _held


func _can_use(b: PartBody3D) -> bool:
	return b != null and b.mode != PartBody3D.Mode.STATIC and (allowed.is_empty() or allowed.has(b))


# ---------------------------------------------------------------- input

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					grab_focus()
					_on_left_down(event.position)
				elif _held:
					_drop()
			MOUSE_BUTTON_RIGHT:
				_orbiting = event.pressed and _cam_input()
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed and _cam_input():
					zoom(0.9)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed and _cam_input():
					zoom(1.1)
		accept_event()
	elif event is InputEventMouseMotion:
		if _orbiting:
			if lock_yaw:
				pan(-event.relative.x * _tgt.dist / size.y)
				orbit(0.0, event.relative.y * orbit_speed * 0.5)
			else:
				orbit(-event.relative.x * orbit_speed, event.relative.y * orbit_speed)
		elif _held:
			_move_held(event.position)
		else:
			_update_mouse_hover(event.position)
		accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				rotate_held()
			KEY_Q:
				_key_move(-1)
			KEY_E:
				_key_move(1)
			KEY_HOME:
				reset_view()
			_:
				return
		accept_event()


## ผู้เล่นขยับกล้องเองได้ไหม (ปิดในโหมดสถานี)
func _cam_input() -> bool:
	return user_camera and not station_mode


func _key_move(dir: int) -> void:
	if not _cam_input():
		return
	if lock_yaw:
		pan(1.5 * dir)
	else:
		orbit(30.0 * dir)


func pick_at(screen_pos: Vector2) -> PartBody3D:
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 80.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	# คลิกทะลุชิ้นที่กดไม่ได้ (เช่นฝากระจก/เมนบอร์ดตอนที่ไม่ได้ allow) → เจอชิ้นที่กดได้ข้างใต้ [30 ก.ย.]
	var first: PartBody3D = null
	for i in 6:
		var hit := camera.get_world_3d().direct_space_state.intersect_ray(q)
		var b := hit.get("collider") as PartBody3D
		if b == null:
			break
		if first == null:
			first = b
		if _can_use(b):
			return b
		q.exclude = q.exclude + [hit.get("rid")]
	return first


## ตำแหน่งบนจอ (พิกัด canvas) ของจุดในโลก 3D — ใช้วางไกด์ "คลิกตรงนี้"
func screen_pos_of(world_pos: Vector3) -> Vector2:
	var p := camera.unproject_position(world_pos)
	return get_global_transform_with_canvas() * (p * size / Vector2(viewport.size))


func _update_mouse_hover(screen_pos: Vector2) -> void:
	var b := pick_at(screen_pos)
	if not _can_use(b):
		b = null
	if b == _hover_part:
		return
	if _hover_part:
		_hover_part.set_hover(false)
	_hover_part = b
	if b:
		b.set_hover(true)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		mouse_default_cursor_shape = Control.CURSOR_ARROW


func _on_left_down(screen_pos: Vector2) -> void:
	press_part(pick_at(screen_pos))


## คลิกชิ้น (เรียกจากโค้ด/เทสต์ได้เหมือนผู้เล่นคลิก)
func press_part(b: PartBody3D) -> void:
	if not _can_use(b):
		return
	match b.mode:
		PartBody3D.Mode.TOGGLE:
			b.set_toggle(not b.toggle_on)
			part_toggled.emit(b, b.toggle_on)
		PartBody3D.Mode.CLICK:
			b.clicked.emit()
			part_clicked.emit(b)
		PartBody3D.Mode.DRAGGABLE:
			begin_drag(b)


## เริ่มถือชิ้น
func begin_drag(b: PartBody3D) -> bool:
	if b.socket and b.socket.is_locked():
		drop_rejected.emit(b, b.socket, Socket3D.Result.LOCKED)
		_shake(b)
		return false
	if _hover_part:
		_hover_part.set_hover(false)
		_hover_part = null
	_held = b
	_held_origin = b.socket
	_held_origin_xf = b.global_transform
	_hold_y = b.global_position.y + hold_lift
	_held_target = Vector3(b.global_position.x, _hold_y, b.global_position.z)
	if b.socket:
		b.socket.occupant = null
		if not b.socket.accept_any:
			installed_ids.erase(b.data.id)
		b.socket = null
	part_picked.emit(b)
	return true


func _move_held(screen_pos: Vector2) -> void:
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.001:
		return
	var t := (_hold_y - from.y) / dir.y
	if t < 0:
		return
	var p := from + dir * t
	_mouse_screen = screen_pos
	move_held_to(Vector3(p.x, _hold_y, p.z))
	_mouse_screen = Vector2(-1, -1)


var _mouse_screen := Vector2(-1, -1) # ตำแหน่งเมาส์ตอนลาก (พิกัดใน viewport) · -1 = สั่งจากโค้ด


func move_held_to(p: Vector3, instant := false) -> void:
	if _held == null:
		return
	_held_target = p
	if instant:
		_held.global_position = p
	_update_hover()


func _update_hover() -> void:
	var best: Socket3D = null
	var best_d := snap_dist
	var hp := Vector2(_held_target.x, _held_target.z)
	var by_screen := _mouse_screen.x >= 0.0
	if by_screen:
		best_d = snap_px
	for s in sockets:
		var d := hp.distance_to(Vector2(s.global_position.x, s.global_position.z))
		if by_screen:
			d = _mouse_screen.distance_to(camera.unproject_position(s.global_position))
		if not allowed_sockets.is_empty() and not allowed_sockets.has(s) and s != _held_origin:
			continue
		if _held.is_ancestor_of(s): # socket ที่ติดมากับชิ้นในมือ (เช่นช่อง CPU บนเมนบอร์ด) ไม่นับ [30 ก.ย.]
			continue
		if d < best_d and (s.occupant == null or s.occupant == _held):
			best_d = d
			best = s
	if _hover and _hover != best:
		_hover.highlight(0)
	_hover = best
	if _hover:
		_hover.highlight(1 if _hover.check(_held, installed_ids) == Socket3D.Result.OK else 2)


## ปล่อยชิ้นในมือ (เรียกจากโค้ด/เทสต์ได้)
func drop() -> void:
	if _held:
		_drop()


func _drop() -> void:
	var b := _held
	_held = null
	var s := _hover
	_hover = null
	if s:
		s.highlight(0)
		var res := s.check(b, installed_ids)
		if res == Socket3D.Result.OK:
			if s == _held_origin:
				install(b, s, true, false) # วางกลับที่เดิม = ไม่มีอะไรเปลี่ยน
				part_returned.emit(b)
				return
			if _held_origin:
				part_removed.emit(b, _held_origin)
			install(b, s)
			return
		drop_rejected.emit(b, s, res)
		b.tint(Color(1, 0.25, 0.25))
		get_tree().create_timer(0.45).timeout.connect(b.clear_tint)
	_return_to_origin(b)


func _return_to_origin(b: PartBody3D) -> void:
	if _held_origin:
		install(b, _held_origin, true, false)
	else:
		create_tween().tween_property(b, "global_transform", _held_origin_xf, 0.2)
	part_returned.emit(b)


func _shake(b: PartBody3D) -> void:
	var p := b.position
	var tw := create_tween()
	for i in 3:
		tw.tween_property(b, "position:x", p.x + 0.02, 0.04)
		tw.tween_property(b, "position:x", p.x - 0.02, 0.04)
	tw.tween_property(b, "position:x", p.x, 0.04)
	b.tint(Color(1, 0.25, 0.25))
	tw.tween_callback(b.clear_tint).set_delay(0.25)
