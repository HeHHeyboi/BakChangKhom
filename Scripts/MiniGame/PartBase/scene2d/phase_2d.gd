class_name Phase2D extends Phase
## ฐานของ phase ที่เล่นในฉาก 2D (Stage2D) — ตัวช่วย: stage · กล้องอัตโนมัติ · ต่อสัญญาณแบบถอดเองตอนจบ phase · ให้ปิ๊บพูด
## ใช้คู่กับ PartMinigame ที่มีตัวแปร stage (Stage2D) · ดู Scripts/MiniGame/PartRam/ เป็นตัวอย่าง

var _links: Array = [] # [[signal, callable], ...] ต่อไว้ตอน phase นี้เล่นอยู่เท่านั้น


func stage() -> Stage2D:
	return owner.stage


func node(unique_name: String) -> Node:
	return owner.get_node("%" + unique_name)


## ต่อสัญญาณเฉพาะตอน phase นี้ active — ถอดให้อัตโนมัติใน finish()
func listen(sig: Signal, cb: Callable) -> void:
	if not sig.is_connected(cb):
		sig.connect(cb)
	_links.append([sig, cb])


func _unlisten_all() -> void:
	for l in _links:
		if (l[0] as Signal).is_connected(l[1]):
			(l[0] as Signal).disconnect(l[1])
	_links.clear()


## กล้องไปที่มุมสำเร็จรูป (View2D) แบบนุ่ม
## nav_enabled = false → ซ่อนแถบสลับมุม/ปุ่มกลับ (เช่นหน้าสรุป · ช่วงปิ๊บสอน)
var nav_enabled := true


func cam(view_name: StringName) -> void:
	ViewNav.ensure(owner, stage()).set_enabled(nav_enabled)
	stage().go_to(view_name)


## รีเซ็ตซูมของมุมปัจจุบันกลับเป็นปกติ (ตัดการเปลี่ยนมุมที่ยังเล่นอยู่ทิ้ง)
func reset_zoom() -> void:
	stage().reset_zoom()


## โหมด Info rail ของ phase นี้ (ตั้งใน Inspector หรือเรียก set_rail_mode ใน init())
##   AUTO = เปิดเมื่อมีปุ่มใน rail แล้วฉากหดหนี · SQUEEZE = เปิดเสมอ ฉากหด
##   OVERLAY = เปิดเมื่อมีปุ่ม แต่วางทับภาพ ฉากกว้างเต็ม · HIDDEN = ซ่อน rail เสมอ
enum RailMode { AUTO, SQUEEZE, OVERLAY, HIDDEN }

@export var rail_mode: RailMode = RailMode.AUTO


func set_rail_mode(mode: RailMode) -> void:
	rail_mode = mode
	refresh_layout()


## ทางลัด: วางทับ (true) หรือกลับเป็น AUTO (false)
func set_rail_overlay(on := true) -> void:
	set_rail_mode(RailMode.OVERLAY if on else RailMode.AUTO)


## ตัดสินใจ layout ของ phase นี้ที่เดียว: rail เปิดไหม · Stage หดไหม — เรียกซ้ำได้เมื่อ UI เปลี่ยน (PhaseUI.refresh เรียกมาที่นี่)
func refresh_layout() -> void:
	if not has_meta("rail") or not visible:
		return
	var open: bool
	match rail_mode:
		RailMode.HIDDEN:
			open = false
		RailMode.SQUEEZE:
			open = true
		_:
			open = PhaseUI.rail_wanted(self)
	PhaseUI.apply_rail(self, open)
	var st = owner.get("stage") if owner else null
	if st is Stage2D:
		var squeeze := open and rail_mode != RailMode.OVERLAY
		(st as Stage2D).set_inset(maxf((st as Stage2D).size.x - PhaseUI.RAIL.position.x, 0.0) if squeeze else 0.0)


## เลื่อนมุมปัจจุบันให้กึ่งกลางอยู่ที่ x (พิกัดในมุม) — ค้างจนเปลี่ยนมุมหรือ reset_camera()
func pan(x: float, animate := true) -> void:
	stage().pan_to(x, animate)


## คืนมุมปัจจุบันเป็นค่าตั้งต้น (focus_x ของมุม · ไม่ซูม · ไม่ pan) โดยไม่เปลี่ยนมุม
func reset_camera() -> void:
	stage().reset_camera()


## จำกัดว่าคลิก/ลากได้เฉพาะชิ้นไหน (ว่าง = ทุกชิ้น)
func allow(parts: Array) -> void:
	var a: Array[Item2D] = []
	for p in parts:
		if p:
			a.append(p)
	stage().allowed = a


func allow_sockets(list: Array) -> void:
	var a: Array[Socket2D] = []
	for x in list:
		if x:
			a.append(x)
	stage().allowed_sockets = a


## ปิ๊บพูดไม่เกินกี่บรรทัดต่อครั้ง — ที่เกินย้ายไป "บันทึกของปิ๊บ" ในสมุดคู่มือ (PhaseUI.note) · 0 = ไม่จำกัด
const SAY_MAX_LINES := 2
const SAY_MORE_LINE := "ที่เหลือปิ๊บจดไว้ในสมุดแล้ว แตะรูปหนังสือมุมขวาบนดูได้เลย"


func say(header: String, mood := PibHint.Mood.NORMAL) -> void:
	var lines: Array = owner.dialog_dict.get(header, [])
	if SAY_MAX_LINES > 0 and lines.size() > SAY_MAX_LINES and has_meta("rail_box"):
		var extra := []
		for t in lines.slice(SAY_MAX_LINES):
			extra.append(t.dialog if t is DialogToken else str(t))
		PhaseUI.note(self, extra)
		var shown := lines.slice(0, SAY_MAX_LINES)
		shown.append(DialogToken.new(PibHint.DEFAULT_SPEAKER, SAY_MORE_LINE))
		owner.pib.say(shown, mood)
		return
	pib_toggle.emit(PibHint.Data.say(header, mood))


func toast(header: String) -> void:
	pib_toggle.emit(PibHint.Data.toast(header))


func say_text(lines: Array, mood := PibHint.Mood.NORMAL) -> void:
	owner.pib.say(lines, mood)


# ---------------------------------------------------------------- ไกด์ "คลิกตรงนี้" [30 ก.ย.]
var _hint_marker: GuideMarker
var _hint_token := 0


## โชว์วงกลม + ลูกศรที่ชิ้น target หลังผู้เล่นไม่ทำอะไร delay วินาที (0 = ทันที)
## สมุดคู่มือจะวาดวงกลมที่ชิ้นเดียวกันในภาพตัวอย่างด้วย (meta "hint_target")
func hint(target: Control, text := "คลิกตรงนี้", delay := 4.0, view := &"") -> void:
	clear_hint()
	if target == null:
		return
	set_meta("hint_target", target)
	var tok := _hint_token
	if delay > 0.0:
		await wait(delay)
	if tok != _hint_token or not visible:
		return
	if view != &"":
		cam(view)
	_hint_marker = GuideMarker.follow(self, stage(), target, text)
	if target is Item2D:
		_hint_marker.flip_below = (target as Item2D).hint_flip


func clear_hint() -> void:
	_hint_token += 1
	remove_meta("hint_target")
	if is_instance_valid(_hint_marker):
		_hint_marker.queue_free()
	_hint_marker = null


func finish() -> void:
	if not visible: # await ค้างจาก phase ที่ถูกข้ามด้วย debug jump
		return
	clear_hint()
	stage().clear_history() # phase ใหม่เริ่มประวัติมุมกล้องใหม่
	_unlisten_all()
	stage().allowed = []
	stage().allowed_sockets = []
	stage().user_camera = true
	hide()
	phase_completed.emit()


## ทิ้ง phase กลางคันแบบเงียบ ๆ (debug jump) — เหมือน finish() แต่ไม่ emit phase_completed
func abort() -> void:
	clear_hint()
	_unlisten_all()
	stage().allowed = []
	stage().allowed_sockets = []
	stage().user_camera = true
	hide()


## ปุ่มใน info rail (ใช้กับ VBox ที่ได้จาก PhaseUI.make_frame)
func rail_button(box: Container, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(cb)
	box.add_child(b)
	return b


## รอสักพักแบบไม่บล็อก (ใช้ใน await)
func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout
