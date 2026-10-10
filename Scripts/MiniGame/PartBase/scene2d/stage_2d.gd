@tool
class_name Stage2D extends Control
## ฉากมินิเกมแบบ 2D ล้วน — มีหลาย "มุม" (View2D ใต้ node Views) · สลับมุมด้วยภาพ crossfade + ซูมเล็กน้อย
## ชิ้น (Item2D) · จุดวาง (Socket2D) · จุดกด (Hotspot2D) เป็น Control ธรรมดา จัดใน Editor ได้
## ลากชิ้น: ชิ้นลอยตามเมาส์ (อยู่ชั้น Top) · ปล่อยบน socket ในมุมเดียวกัน · ลากไปค้างที่ Hotspot = ย้ายไปมุมนั้นทั้งที่ยังถืออยู่
## สัญญาณและฟังก์ชันชื่อเดิมทั้งหมด (phase เดิมใช้ต่อได้) · Docs/SCENE_2D.md
## [Claude 30 ก.ย. 2569] แทนฉาก 3D / 2.5D เดิม

signal part_picked(part: Item2D)
signal part_installed(part: Item2D, socket: Socket2D)
signal part_removed(part: Item2D, socket: Socket2D)
signal drop_rejected(part: Item2D, socket: Socket2D, reason: Socket2D.Result)
signal part_toggled(part: Item2D, on: bool)
signal part_clicked(part: Item2D)
signal part_returned(part: Item2D)
signal view_changed(view: StringName)
signal view_name_changed(view: StringName)

@export var start_view: StringName = &"Overview"
## ปุ่ม "กลับ" (ViewNav ตั้งให้) — ไกด์ชี้ปุ่มนี้เมื่อไปมุมเป้าหมายด้วยจุดกดในฉากไม่ได้
var back_anchor: Control
## id ชิ้นที่ถือว่าติดตั้งอยู่แล้ว แต่ไม่มี node (วาดอยู่ในรูปพื้นหลัง) เช่น "mainboard"
@export var preinstalled: Array[StringName] = []
@export var transition_time := 0.32
@export var snap_px := 56.0 ## ระยะ (พิกเซล) ที่ socket ดูดชิ้นในมือ
@export var portal_delay := 0.45 ## ถือชิ้นค้างบน Hotspot นานเท่านี้ = ไปมุมนั้น

@onready var views_root: Control = $Views
@onready var top: Control = $Top

var sockets: Array[Socket2D] = []
var installed_ids: Array[StringName] = []
var allowed: Array[Item2D] = []
var allowed_sockets: Array[Socket2D] = []
var user_camera := true # ใช้ร่วมกับ phase เดิม (ระบบ 2D ไม่มีกล้องให้ขยับ)
var current_view: StringName = &""

var _view: View2D
var _history: Array[StringName] = []
var _held: Item2D
var _held_origin: Socket2D
var _held_parent: Node
var _held_pos := Vector2.ZERO
var _held_size := Vector2.ZERO
var _grab := Vector2.ZERO
var _mouse := Vector2.ZERO
var _hover: Socket2D
var _hover_item: Control
var _portal: Hotspot2D
var _portal_t := 0.0
var _busy := false
var _transition_tween: Tween
var inset_right := 0.0 ## พื้นที่ฝั่งขวาที่ UI บัง (พิกเซลของ Stage) — ดู set_inset()
var _pan_x := NAN ## NAN = ใช้ focus_x ของมุม · มีค่า = pan_to ค้างไว้ให้มุมปัจจุบัน
var _pan_tween: Tween


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	for v in views():
		v.visible = false
	if Engine.is_editor_hint():
		var v0 := find_view(start_view)
		if v0:
			v0.visible = true
			_view = v0
		return
	installed_ids.append_array(preinstalled)
	for n in _all(views_root):
		if n is Socket2D:
			sockets.append(n)
		elif n is Item2D and n.counts_as_installed and n.data:
			installed_ids.append(n.data.id)
	for s in sockets:
		if s.start_occupant:
			install(s.start_occupant, s, false, false)
	go_to(start_view, true)


func _all(n: Node) -> Array[Node]:
	var out: Array[Node] = []
	if n == null:
		return out
	for c in n.get_children():
		out.append(c)
		out.append_array(_all(c))
	return out


func views() -> Array[View2D]:
	var a: Array[View2D] = []
	if views_root == null:
		return a
	for c in views_root.get_children():
		if c is View2D:
			a.append(c)
	return a


func find_view(n: StringName) -> View2D:
	for v in views():
		if v.name == n or v.aliases.has(String(n)):
			return v
	return null


func view_of(n: Node) -> View2D:
	var p := n
	while p and not (p is View2D):
		p = p.get_parent()
	return p as View2D


func _process(delta: float) -> void:
	_layout()
	if _held:
		var target := top.get_global_transform_with_canvas().affine_inverse() * (
			get_global_transform_with_canvas() * _mouse
		) - _grab
		_held.position = _held.position.lerp(target, 1.0 - exp(-22.0 * delta))
		# ค้างบนประตู → ย้ายมุม
		if _portal:
			_portal_t += delta
			if _portal_t >= portal_delay and not _busy:
				var t := _portal.target_view
				_portal.set_hover(false)
				_portal = null
				go_to(t)
	if Engine.is_editor_hint():
		queue_redraw()


## จัดมุมให้อยู่กลางพื้นที่ (จอแคบ = ตัดขอบ ยึด focus_x)
## [Claude 1 ต.ค.] ฉากสูงกว่า 420 (ไม่มีแถบหัวข้อแล้ว) → ขยายทั้งชุดมุม + ชั้นบนเท่ากันให้เต็มความสูง แล้วตัดขอบซ้าย-ขวาแทน
func view_scale() -> float:
	return maxf(1.0, size.y / View2D.DESIGN.y)


## ความกว้างที่มองเห็นจริง — Stage กว้างเต็มเสมอ แต่หักพื้นที่ที่ UI ฝั่งขวา (Info rail) บังอยู่
func visible_width() -> float:
	return maxf(size.x - inset_right, 1.0)


## UI ฝั่งขวาบังกี่พิกเซล (PhaseUI._auto_rail เรียก) — แทนการหดความกว้าง Stage
func set_inset(right: float) -> void:
	inset_right = maxf(right, 0.0)


## เลื่อนมุมปัจจุบันให้กึ่งกลางอยู่ที่ x (พิกัดในมุม · หน่วยเดียวกับ focus_x) — ใช้ชั่วคราวจนเปลี่ยนมุมหรือ reset_camera()
func pan_to(x: float, animate := true) -> void:
	if _view == null:
		return
	_kill_pan()
	if not animate:
		_pan_x = x
		return
	if is_nan(_pan_x):
		_pan_x = _view.focus_x
	_pan_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pan_tween.tween_property(self, "_pan_x", x, transition_time)


## คืนมุมปัจจุบันเป็นค่าตั้งต้น: เลิก pan_to · ตัดซูม/crossfade ที่ค้างอยู่ (ไม่เปลี่ยนมุม — reset_view() เดิมคือกลับ start_view)
func reset_camera() -> void:
	_kill_pan()
	_pan_x = NAN
	reset_zoom()


func _kill_pan() -> void:
	if _pan_tween and _pan_tween.is_valid():
		_pan_tween.kill()
	_pan_tween = null


func _layout() -> void:
	if Engine.is_editor_hint():
		return # Editor แสดงตำแหน่งดิบ (ไม่เขียนค่าที่คำนวณลง .tscn)
	var k := view_scale()
	var vis := visible_width()
	views_root.scale = Vector2(k, k)
	top.scale = Vector2(k, k)
	views_root.clip_contents = true
	views_root.size.x = vis / k # ตัดภาพที่ล้ำไปใต้ rail
	var sz := Vector2(vis, size.y) / k
	for v in views():
		v.size = View2D.DESIGN
		var fx := _pan_x if (v == _view and not is_nan(_pan_x)) else v.focus_x
		var x := sz.x / 2.0 - fx
		x = clampf(x, minf(0.0, sz.x - View2D.DESIGN.x), 0.0)
		v.position = Vector2(x, (sz.y - View2D.DESIGN.y) / 2.0)

# ---------------------------------------------------------------- มุม


func go_to(view_name: StringName, instant := false, record := true) -> void:
	var v := find_view(view_name)
	if v == null:
		if view_name != &"Carry":
			push_warning("Stage2D: ไม่พบมุม '%s'" % view_name)
		return
	if v == _view:
		return
	# [Claude 10 ต.ค. 2569] เปลี่ยนมุมซ้อนระหว่าง crossfade เดิมยังไม่จบ → มุมเก่าค้างโปร่งแสงทับ (เห็นเป็นภาพซ้อน)
	if _transition_tween and _transition_tween.is_valid() and _transition_tween.is_running():
		reset_zoom()
	if record and current_view != &"" and current_view != v.name:
		_history.append(current_view)
		if _history.size() > 12:
			_history.pop_front()
	var old := _view
	_view = v
	current_view = v.name
	_kill_pan() # pan_to ใช้กับมุมเดียว · เปลี่ยนมุมแล้วกลับเป็น focus_x
	_pan_x = NAN
	_set_hover_item(null)
	if old == null or instant:
		if old:
			old.visible = false
		v.visible = true
		v.modulate.a = 1.0
		v.scale = Vector2.ONE
	else:
		_transition(old, v)
	view_changed.emit(v.name)
	view_name_changed.emit(v.name)


## เปลี่ยนภาพแบบ crossfade + ซูมเข้า/ออกเล็กน้อย
func _transition(old: View2D, v: View2D) -> void:
	_busy = true
	var zoom_in: bool = _history.size() > 0 and _history.back() == old.name
	v.visible = true
	v.modulate.a = 0.0
	v.pivot_offset = View2D.DESIGN / 2.0
	old.pivot_offset = View2D.DESIGN / 2.0
	v.scale = Vector2.ONE * (0.94 if zoom_in else 1.06)
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_transition_tween = tw
	tw.tween_property(old, "modulate:a", 0.0, transition_time)
	tw.tween_property(old, "scale", Vector2.ONE * (1.08 if zoom_in else 0.94), transition_time)
	tw.tween_property(v, "modulate:a", 1.0, transition_time)
	tw.tween_property(v, "scale", Vector2.ONE, transition_time)
	await tw.finished
	if old != _view:
		old.visible = false
		old.scale = Vector2.ONE
		old.modulate.a = 1.0
	_busy = false


## ยกเลิกซูม/crossfade ที่ค้างอยู่ แล้วคืนมุมปัจจุบันเป็น scale 1 · ทึบเต็ม (มุมอื่นซ่อน)
func reset_zoom() -> void:
	if _transition_tween and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = null
	_busy = false
	for v in views():
		v.scale = Vector2.ONE
		v.modulate.a = 1.0
		v.visible = v == _view


func can_back() -> bool:
	return not _history.is_empty()


func back() -> void:
	if not _history.is_empty():
		go_to(_history.pop_back(), false, false)


func clear_history() -> void:
	_history.clear()
	view_name_changed.emit(current_view)


## มุมที่มีชื่อปุ่ม (แถบนำทาง)
func nav_views() -> Array[View2D]:
	var a: Array[View2D] = []
	for v in views():
		if v.label != "":
			a.append(v)
	return a


func reset_view() -> void:
	go_to(start_view)


func pan(_dx: float) -> void:
	pass

# ---------------------------------------------------------------- ตำแหน่งบนจอ


## ตำแหน่งบนจอ (canvas) ของ node — ถ้าอยู่มุมอื่น ชี้ไปที่ Hotspot ที่พาไปมุมนั้นแทน · null = ไม่มีให้ชี้
func screen_pos_of_node(n: Control):
	if n == null or not is_instance_valid(n):
		return null
	if n == _held or n.get_parent() == top:
		return n.get_global_transform_with_canvas() * (n.size / 2.0)
	var v := view_of(n)
	if v == _view:
		return n.get_global_transform_with_canvas() * (n.size / 2.0)
	if v == null or _view == null:
		return null
	var hop := _first_hop(_view, v)
	if hop:
		return hop.get_global_transform_with_canvas() * (hop.size / 2.0)
	if back_anchor and back_anchor.is_visible_in_tree():
		return back_anchor.get_global_transform_with_canvas() * (back_anchor.size / 2.0)
	return null


## [Claude 1 ต.ค.] หาจุดกดแรกในมุม from ที่พาไปถึงมุม to ได้สั้นที่สุด (เดินต่อกันหลายมุมได้) · ไม่มีทาง = null
func _first_hop(from: View2D, to: View2D) -> Hotspot2D:
	var first := { } # View2D → Hotspot2D แรกที่ออกจาก from
	var queue: Array[View2D] = [from]
	var seen := { from: true }
	while not queue.is_empty():
		var cur: View2D = queue.pop_front()
		for c in _all(cur):
			if not (c is Hotspot2D) or not c.is_visible_in_tree() and cur == from:
				continue
			var nv := find_view(c.target_view)
			if nv == null or seen.has(nv):
				continue
			seen[nv] = true
			first[nv] = c if cur == from else first[cur]
			if nv == to:
				return first[nv]
			queue.append(nv)
	return null

# ---------------------------------------------------------------- ติดตั้ง


func install(part: Item2D, s: Socket2D, animate := true, emit := true) -> void:
	s.occupant = part
	part.socket = s
	var parent := s.get_parent()
	var gp := part.get_global_transform_with_canvas().origin
	if part.get_parent() != parent:
		part.reparent(parent) # reparent คง owner ไว้ → %ชื่อ ยังหาเจอ
	# อยู่หน้า socket
	parent.move_child(part, min(s.get_index() + 1, parent.get_child_count() - 1))
	var target := s.position
	if animate and part.is_visible_in_tree():
		part.position = parent.get_global_transform_with_canvas().affine_inverse() * gp
		var tw := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(part, "position", target, 0.18)
		tw.tween_property(part, "size", s.size, 0.18)
	else:
		part.position = target
		part.size = s.size
	part.pivot_offset = s.size / 2.0
	if not s.accept_any and part.data:
		installed_ids.append(part.data.id)
	if emit:
		part_installed.emit(part, s)


func held() -> Item2D:
	return _held


func rotate_held(step := 180.0) -> void:
	if _held:
		_held.set_yaw(_held.yaw_deg + step)
		_update_socket_hover()


func _can_use(b: Control) -> bool:
	if b is Hotspot2D:
		return _held == null
	if not (b is Item2D):
		return false
	return b.mode != Item2D.Mode.STATIC and (allowed.is_empty() or allowed.has(b))

# ---------------------------------------------------------------- input


func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton:
		_mouse = event.position
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				grab_focus()
				var b := pick_at(event.position)
				if b is Hotspot2D:
					if not _busy:
						go_to(b.target_view)
				else:
					press_part(b)
			elif _held:
				_drop()
		accept_event()
	elif event is InputEventMouseMotion:
		_mouse = event.position
		if _held:
			_update_socket_hover()
			_update_portal()
		else:
			var b := pick_at(event.position)
			_set_hover_item(b if _can_use(b) else null)
		accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			rotate_held()
			accept_event()


## ของที่อยู่บนสุดตรงจุดนี้ในมุมปัจจุบัน (พิกัดของ Stage) — คลิกทะลุชิ้นที่ยังกดไม่ได้
func pick_at(p: Vector2) -> Control:
	if _view == null or _busy or p.x > visible_width(): # ส่วนใต้ rail ไม่ใช่ฉาก
		return null
	var gp := get_global_transform_with_canvas() * p
	var list := _all(_view)
	var first: Control = null
	for i in range(list.size() - 1, -1, -1):
		var n = list[i]
		if not ((n is Item2D) or (n is Hotspot2D)) or not n.is_visible_in_tree() or n == _held:
			continue
		var lp: Vector2 = (n as Control).get_global_transform_with_canvas().affine_inverse() * gp
		if not n.hit_local(lp):
			continue
		if first == null:
			first = n
		if _can_use(n):
			return n
	return first


func _set_hover_item(b: Control) -> void:
	if b == _hover_item:
		return
	if is_instance_valid(_hover_item):
		_hover_item.set_hover(false)
	_hover_item = b
	if b:
		b.set_hover(true)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if b else Control.CURSOR_ARROW


func press_part(b: Control) -> void:
	if b is not Item2D or !_can_use(b):
		return
	var it := b as Item2D
	match it.mode:
		Item2D.Mode.TOGGLE:
			it.set_toggle(not it.toggle_on)
			part_toggled.emit(it, it.toggle_on)
		Item2D.Mode.CLICK:
			it.clicked.emit()
			part_clicked.emit(it)
		Item2D.Mode.DRAGGABLE:
			begin_drag(it)


func begin_drag(b: Item2D) -> bool:
	if b.socket and b.socket.is_locked():
		drop_rejected.emit(b, b.socket, Socket2D.Result.LOCKED)
		_shake(b)
		return false
	_set_hover_item(null)
	_held = b
	_held_origin = b.socket
	_held_parent = b.get_parent()
	_held_pos = b.position
	_held_size = b.size
	var gp := b.get_global_transform_with_canvas().origin
	if b.socket:
		b.socket.occupant = null
		if not b.socket.accept_any and b.data:
			installed_ids.erase(b.data.id)
		b.socket = null
	# ย้ายขึ้นชั้นบนสุด ลอยตามเมาส์
	b.reparent(top)
	b.position = top.get_global_transform_with_canvas().affine_inverse() * gp
	var local_mouse := top.get_global_transform_with_canvas().affine_inverse() * (
		get_global_transform_with_canvas() * _mouse
	)
	_grab = local_mouse - b.position
	_grab = _grab.lerp(b.size / 2.0, 0.5) # ดึงเข้ากลางนิด ๆ ให้ถือถนัด
	b.modulate.a = 0.92
	for s in sockets:
		if view_of(s) and _socket_ok(s) and s.check(b, installed_ids) == Socket2D.Result.OK:
			s.highlight(Socket2D.HL.HINT)
	part_picked.emit(b)
	return true


func _socket_ok(s: Socket2D) -> bool:
	if not allowed_sockets.is_empty() and not allowed_sockets.has(s) and s != _held_origin:
		return false
	if _held and _held.is_ancestor_of(s):
		return false
	return s.occupant == null or s.occupant == _held


func _update_socket_hover() -> void:
	var best: Socket2D = null
	var best_d := snap_px
	var gm := get_global_transform_with_canvas() * _mouse
	for s in sockets:
		if view_of(s) != _view or not _socket_ok(s):
			continue
		var r := s.get_global_rect()
		var d := 0.0 if r.has_point(gm) else r.get_center().distance_to(gm) - minf(r.size.x, r.size.y) * 0.5
		# กรอบซ้อนกัน → เลือกอันที่ชิ้นนี้ใส่ได้ก่อน แล้วค่อยดูว่าใกล้กลางกรอบแค่ไหน
		if s.check(_held, installed_ids) != Socket2D.Result.OK:
			d += snap_px * 0.5
		d += r.get_center().distance_to(gm) * 0.01
		if d < best_d:
			best_d = d
			best = s
	if _hover and _hover != best:
		_hover.highlight(
			(Socket2D.HL.HINT if _hover.check(_held, installed_ids) == Socket2D.Result.OK else Socket2D.HL.CLOSE)
		)
	_hover = best
	if _hover:
		_hover.highlight(
			Socket2D.HL.VALID if _hover.check(_held, installed_ids) == Socket2D.Result.OK else Socket2D.HL.INVALID
		)


func _update_portal() -> void:
	var gp := get_global_transform_with_canvas() * _mouse
	var found: Hotspot2D = null
	for c in _all(_view):
		if c is Hotspot2D and c.portal and c.is_visible_in_tree():
			if c.hit_local(c.get_global_transform_with_canvas().affine_inverse() * gp):
				found = c
				break
	if found != _portal:
		if _portal:
			_portal.set_hover(false)
		_portal = found
		_portal_t = 0.0
		if _portal:
			_portal.set_hover(true)


## ปล่อยชิ้นในมือ (เรียกจากโค้ด/เทสต์ได้)
func drop() -> void:
	if _held:
		_drop()


## จำลองเมาส์ (เทสต์): ย้ายชิ้นในมือไปที่จุดบนจอ (พิกัด Stage)
func move_mouse(p: Vector2) -> void:
	_mouse = p
	if _held:
		_held.position = top.get_global_transform_with_canvas().affine_inverse() * (
			get_global_transform_with_canvas() * p
		) - _grab
		_update_socket_hover()


func _drop() -> void:
	var b := _held
	_held = null
	b.modulate.a = 1.0
	if _portal:
		_portal.set_hover(false)
		_portal = null
	for s in sockets:
		s.highlight(Socket2D.HL.CLOSE)
	var s := _hover
	_hover = null
	if s:
		var res := s.check(b, installed_ids)
		if res == Socket2D.Result.OK:
			if s == _held_origin:
				install(b, s, true, false)
				part_returned.emit(b)
				return
			if _held_origin:
				part_removed.emit(b, _held_origin)
			install(b, s)
			return
		drop_rejected.emit(b, s, res)
		b.tint(Color(1, 0.3, 0.3))
		get_tree().create_timer(0.45).timeout.connect(b.clear_tint)
	_return_to_origin(b)


func _return_to_origin(b: Item2D) -> void:
	if _held_origin:
		install(b, _held_origin, true, false)
	else:
		var gp := b.get_global_transform_with_canvas().origin
		b.reparent(_held_parent)
		b.position = (_held_parent as CanvasItem).get_global_transform_with_canvas().affine_inverse() * gp
		b.size = _held_size
		create_tween().tween_property(b, "position", _held_pos, 0.2)
	part_returned.emit(b)


func _shake(b: Control) -> void:
	var p := b.position
	var tw := create_tween()
	for i in 3:
		tw.tween_property(b, "position:x", p.x + 5, 0.04)
		tw.tween_property(b, "position:x", p.x - 5, 0.04)
	tw.tween_property(b, "position:x", p.x, 0.04)
	if b is Item2D:
		b.tint(Color(1, 0.3, 0.3))
		tw.tween_callback(b.clear_tint).set_delay(0.25)


## ภาพฉากตอนนี้ (ตัดจากจอเฉพาะกรอบของ stage) — สมุดคู่มือใช้เป็นภาพตัวอย่าง
func snapshot() -> Image:
	var vp := get_viewport()
	if vp == null:
		return null
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		return null
	var xf := vp.get_final_transform() * get_global_transform_with_canvas()
	var r := Rect2i(Rect2(xf * Vector2.ZERO, xf.basis_xform(Vector2(visible_width(), size.y))).abs())
	r = r.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	if r.size.x <= 0 or r.size.y <= 0:
		return null
	return img.get_region(r)
