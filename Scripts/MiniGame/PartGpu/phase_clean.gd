extends Phase2D
## Phase 5 · CLEAN — 3 ขั้นบนแผ่น ESD: S1 ใบพัด · S2 ครีบระบายความร้อน · S3 ขาทอง PCIe (เลือกอุปกรณ์ 7 ชิ้น)
## กติกาเหมือน Part RAM: ตัดสินจาก ToolDef.action (✅ +50% · 🟡 +25% · อุปกรณ์ที่ไม่ตรงกับขั้นนั้นไม่ทำอะไร)
##   S1/S2 ปัด·เป่า = ✅ · S3 ขัด = ✅ / ปัด·เป่า = 🟡
## กติกาพิเศษ: เป่า/ปัดใบพัดหรือครีบโดยไม่ล็อกใบพัดก่อน = −5 (ครั้งเดียว) · ปุ่ม "ใช้นิ้วล็อกใบพัด" ใน rail
## อุปกรณ์: Constant.TOOL_DIR/*.tres (ToolDef) · [Claude 2 ต.ค. 2569]

enum CleanStep { FAN_BLADES, HEATSINK_FINS, GOLD_CONTACTS }

const STEP_TEXT := {
	CleanStep.FAN_BLADES: "S1 · ฝุ่นบนใบพัดลม",
	CleanStep.HEATSINK_FINS: "S2 · ฝุ่นในครีบระบายความร้อน",
	CleanStep.GOLD_CONTACTS: "S3 · ขาทอง PCIe",
}
## หน้าตาการ์ด: ก่อน → หลังของแต่ละขั้น
const STEP_LOOK := {
	CleanStep.FAN_BLADES: ["dusty", "fans"],
	CleanStep.HEATSINK_FINS: ["fans", "fins"],
	CleanStep.GOLD_CONTACTS: ["fins", "clean"],
}
## จุดที่อุปกรณ์ลอยไปถู (สัดส่วนในกรอบการ์ด)
const STEP_POINT := {
	CleanStep.FAN_BLADES: Vector2(0.55, 0.38),
	CleanStep.HEATSINK_FINS: Vector2(0.75, 0.55),
	CleanStep.GOLD_CONTACTS: Vector2(0.52, 0.85),
}
const TOOL_LINES := {
	"blower:1": "CLEAN_FINS_BLOWER",
	"eraser_white:2": "CLEAN_CONTACTS_ERASER",
	"hairdryer:-1": "CLEAN_HAIRDRYER",
}
const GAIN := { CleanTool.Fit.IDEAL: 50.0, CleanTool.Fit.LIMITED: 25.0 }

var _tools: Array[ToolDef] = []
var _step := CleanStep.FAN_BLADES
var _progress := 0.0
var _bar_tween: Tween
var _busy := false
var _finishing := false
var fan_locked := false
var _no_lock_charged := false
var _built := false
var _chk: Array[Label] = []
var _bar: ProgressBar
var _tray: HBoxContainer
var _card: Label
var _lock_btn: Button


func init():
	if _tools.is_empty(): # init() ถูกเรียกทุกครั้งที่เข้า phase — โหลดครั้งเดียวพอ ไม่งั้นอุปกรณ์ซ้ำ
		for p in DirAccess.get_files_at(Constant.TOOL_DIR):
			var t := load(Constant.TOOL_DIR + p) as ToolDef
			if t:
				_tools.append(t)
	if not _built:
		_build()
	_busy = false
	_finishing = false
	_no_lock_charged = false
	set_fan_lock(false)
	show()
	allow([])
	cam(&"Mat")
	listen(owner.pib.all_lines_finished, _on_pib_done)
	_set_step(CleanStep.FAN_BLADES)
	say("CLEAN_LOCK_FAN")


func _build() -> void:
	_built = true
	var rail := PhaseUI.make_frame(self, "ซ่อมการ์ดจอ — ขั้นที่ 5/8 · ทำความสะอาด")
	PhaseUI.force_rail_open(self, true)
	for s in STEP_TEXT:
		_chk.append(PhaseUI.check_item(rail, STEP_TEXT[s]))
	_lock_btn = PhaseUI.rail_button(rail, "", func(): set_fan_lock(not fan_locked))
	_bar = ProgressBar.new()
	_bar.max_value = 100
	_bar.custom_minimum_size = Vector2(0, 18)
	rail.add_child(_bar)
	_tray = HBoxContainer.new()
	var panel := PanelContainer.new()
	panel.add_child(_tray)
	add_child(panel)
	panel.set_anchors_preset(PRESET_CENTER_BOTTOM, true)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH # ขยายออกสองข้างจากกึ่งกลาง
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN # ขยายขึ้นด้านบน ไม่ล้นขอบล่าง
	panel.offset_bottom = -175
	_tray.add_theme_constant_override("separation", 6)
	_tray.alignment = BoxContainer.ALIGNMENT_CENTER
	_card = PhaseUI.label(rail, "ชี้ที่อุปกรณ์เพื่อดูคุณสมบัติ", 14)


func set_fan_lock(on: bool) -> void:
	fan_locked = on
	_lock_btn.text = "☑ ล็อกใบพัดด้วยนิ้วแล้ว" if on else "☐ ใช้นิ้วล็อกใบพัด"


func _set_step(step: CleanStep) -> void:
	_step = step
	_progress = 0.0
	if _bar_tween and _bar_tween.is_valid():
		_bar_tween.kill() # tween ของขั้นก่อนยังวิ่งอยู่ จะทับค่า 0 ถ้าไม่ฆ่า
	_bar.value = 0
	_apply_visual(0.0) # รีเซ็ตภาพของขั้นใหม่ให้ตรงกับ progress 0
	for i in _chk.size():
		PhaseUI.set_check(_chk[i], i < int(step))
	_lock_btn.visible = step != CleanStep.GOLD_CONTACTS
	_fill_tray()
	PhaseUI.refresh(self)


func _fill_tray() -> void:
	for c in _tray.get_children():
		c.queue_free()
	for t: ToolDef in _tools:
		var b := TextureButton.new()
		b.name = String(t.id)
		b.texture_normal = t.icon
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.custom_minimum_size = Vector2(60, 56)
		b.tooltip_text = t.display_name
		b.mouse_entered.connect(_show_card.bind(t))
		b.pressed.connect(func(): use_tool(t))
		_tray.add_child(b)


func _show_card(t: ToolDef) -> void:
	_card.text = "%s\nการใช้งาน %s\nจำนวนครั้ง %s · เวลา %d นาที" % [
		t.display_name,
		_action_names(t.action),
		"ไม่จำกัด" if t.uses < 0 else str(t.uses),
		t.time_minutes,
	]


## ชื่อ Action ทุกบิตที่ติดอยู่ใน flags (action เป็นบิตแฟล็ก ใช้ keys() ตรง ๆ ไม่ได้)
func _action_names(flags: int) -> String:
	var names: PackedStringArray = []
	for key in ToolDef.Action:
		if flags & ToolDef.Action[key]:
			names.append(key.capitalize())
	return " / ".join(names)


func tool_by_id(id: String) -> ToolDef:
	for t in _tools:
		if String(t.id) == id:
			return t
	return null


func use_tool(tool: ToolDef) -> void:
	if not visible or _finishing or _busy:
		return
	var gain: float = 0.0
	var brush_blow := tool.action & (ToolDef.Action.BRUSH | ToolDef.Action.BLOW)
	match _step:
		CleanStep.GOLD_CONTACTS:
			if tool.action & ToolDef.Action.SCRUB:
				gain = GAIN[CleanTool.Fit.IDEAL]
			if brush_blow:
				gain = GAIN[CleanTool.Fit.LIMITED]
		_:
			if brush_blow:
				gain = GAIN[CleanTool.Fit.IDEAL]
	if gain < 0.0:
		return
	_animate_tool(tool, true)
	# เป่า/ปัดใบพัดหรือครีบโดยไม่ล็อกใบพัด → ปิ๊บเตือน −5 (ครั้งเดียว)
	if _step != CleanStep.GOLD_CONTACTS and not fan_locked:
		_warn_no_lock()
	else:
		_say_tool(tool, PibHint.Mood.HAPPY)
	_progress_by(gain)


func _warn_no_lock() -> void:
	if _no_lock_charged:
		return
	_no_lock_charged = true
	mistake.emit(&"clean", 5)
	say("CLEAN_NO_LOCK", PibHint.Mood.WORRY)


func _say_tool(tool: ToolDef, mood: PibHint.Mood) -> void:
	var h: String = TOOL_LINES.get("%s:%d" % [tool.id, _step], TOOL_LINES.get("%s:-1" % tool.id, ""))
	if h != "" and owner.dialog_dict.has(h):
		say(h, mood)


func _animate_tool(tool: ToolDef, reach: bool) -> void:
	var spr := node("ToolSprite") as TextureRect
	var top := spr.get_parent() as Control
	var r := (node("GpuCard") as Control).get_global_rect()
	var gp: Vector2 = r.position + r.size * (STEP_POINT[_step] as Vector2)
	var tgt: Vector2 = top.get_global_transform_with_canvas().affine_inverse() * gp - spr.size / 2.0
	spr.texture = tool.icon
	spr.position = tgt + Vector2(90, -120)
	spr.modulate = Color.WHITE
	spr.show()
	var tw := create_tween()
	if reach:
		tw.tween_property(spr, "position", tgt, 0.25)
		for i in 3:
			tw.tween_property(spr, "position:x", tgt.x - 40, 0.1)
			tw.tween_property(spr, "position:x", tgt.x + 40, 0.1)
	else:
		tw.tween_property(spr, "position", tgt + Vector2(60, -60), 0.25)
		tw.tween_property(spr, "modulate", Color(1, 0.4, 0.4), 0.15)
		tw.tween_interval(0.25)
	await tw.finished
	spr.hide()


func _progress_by(amount: float) -> void:
	_progress = minf(_progress + amount, 100.0)
	if _bar_tween and _bar_tween.is_valid():
		_bar_tween.kill()
	_bar_tween = create_tween()
	_bar_tween.tween_property(_bar, "value", _progress, 0.25)
	_apply_visual(_progress / 100.0)
	if _progress < 100.0:
		return
	if _step < CleanStep.GOLD_CONTACTS:
		_set_step((_step + 1) as CleanStep)
	else:
		(node("GpuCard") as Item2D).set_state("clean")
		_finishing = true
		PhaseUI.set_check(_chk[2], true)
		say("CLEAN_DONE", PibHint.Mood.HAPPY)


## ผลที่เห็นในฉาก: การ์ดเปลี่ยนหน้าตาก่อน → หลังของขั้นปัจจุบันตาม progress
func _apply_visual(t: float) -> void:
	var looks: Array = STEP_LOOK[_step]
	(node("GpuCard") as Item2D).set_state_blend(looks[0], looks[1], t)


func _on_pib_done() -> void:
	if visible and _finishing:
		finish()
