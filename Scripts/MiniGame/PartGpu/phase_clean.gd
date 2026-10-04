extends Phase2D
## Phase 5 · CLEAN — 3 ขั้นบนแผ่น ESD: S1 ใบพัด · S2 ครีบระบายความร้อน · S3 ขาทอง PCIe (เลือกอุปกรณ์ 7 ชิ้น)
## กติกาเหมือน Part RAM (✅ +50% · 🟡 +25% −3 · ❌ −8 ปิ๊บห้ามทันครั้งแรก)
## กติกาพิเศษ: เป่า/ปัดใบพัดหรือครีบโดยไม่ล็อกใบพัดก่อน = −5 (ครั้งเดียว) · ปุ่ม "ใช้นิ้วล็อกใบพัด" ใน rail
## อุปกรณ์: Resources/Parts/Gpu/Tools/*.tres · [Claude 2 ต.ค. 2569]

enum CleanStep { FAN_BLADES, HEATSINK_FINS, GOLD_CONTACTS }

const TOOL_DIR := "res://Resources/Parts/Gpu/Tools/"
const TOOL_IDS := ["brush", "blower", "eraser_white", "ipa_swab", "cloth", "hairdryer", "vacuum"]
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
const BLOW_TOOLS := ["brush", "blower"]
const TOOL_LINES := {
	"blower:1": "CLEAN_FINS_BLOWER",
	"eraser_white:2": "CLEAN_CONTACTS_ERASER",
	"hairdryer:-1": "CLEAN_HAIRDRYER",
}
const GAIN := { CleanTool.Fit.IDEAL: 50.0, CleanTool.Fit.LIMITED: 25.0 }

var _tools: Array[CleanTool] = []
var _step := CleanStep.FAN_BLADES
var _progress := 0.0
var _blocked_once := {}
var _limited_charged := {}
var _busy := false
var _finishing := false
var fan_locked := false
var _no_lock_charged := false
var _built := false
var _chk: Array[Label] = []
var _bar: ProgressBar
var _tray: GridContainer
var _card: Label
var _lock_btn: Button


func init():
	if _tools.is_empty():
		for id in TOOL_IDS:
			var t := load(TOOL_DIR + id + ".tres") as CleanTool
			if t:
				_tools.append(t)
	if not _built:
		_build()
	_blocked_once.clear()
	_limited_charged.clear()
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
	for s in STEP_TEXT:
		_chk.append(PhaseUI.check_item(rail, STEP_TEXT[s]))
	_lock_btn = PhaseUI.rail_button(rail, "", func(): set_fan_lock(not fan_locked))
	_bar = ProgressBar.new()
	_bar.max_value = 100
	_bar.custom_minimum_size = Vector2(0, 18)
	rail.add_child(_bar)
	_tray = GridContainer.new()
	_tray.columns = 4
	_tray.add_theme_constant_override("h_separation", 4)
	_tray.add_theme_constant_override("v_separation", 4)
	rail.add_child(_tray)
	_card = PhaseUI.label(rail, "ชี้ที่อุปกรณ์เพื่อดูคุณสมบัติ", 14)


func set_fan_lock(on: bool) -> void:
	fan_locked = on
	_lock_btn.text = "☑ ล็อกใบพัดด้วยนิ้วแล้ว" if on else "☐ ใช้นิ้วล็อกใบพัด"


func _set_step(step: CleanStep) -> void:
	_step = step
	_progress = 0.0
	_bar.value = 0
	for i in _chk.size():
		PhaseUI.set_check(_chk[i], i < int(step))
	_lock_btn.visible = step != CleanStep.GOLD_CONTACTS
	(node("GpuCard") as Item2D).set_state(STEP_LOOK[step][0])
	_fill_tray()
	PhaseUI.refresh(self)


func _fill_tray() -> void:
	for c in _tray.get_children():
		c.queue_free()
	var list := _tools.duplicate()
	list.shuffle()
	for t: CleanTool in list:
		var b := TextureButton.new()
		b.name = String(t.id)
		b.texture_normal = t.icon
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.custom_minimum_size = Vector2(60, 56)
		b.tooltip_text = t.display_name
		b.mouse_entered.connect(func(): _card.text = t.display_name)
		b.pressed.connect(func(): use_tool(t))
		_tray.add_child(b)


func tool_by_id(id: String) -> CleanTool:
	for t in _tools:
		if String(t.id) == id:
			return t
	return null


func fit_of(t: CleanTool) -> int:
	return int(t.fit_per_step.get(int(_step), CleanTool.Fit.FORBIDDEN))


func use_tool(tool: CleanTool) -> void:
	if not visible or _finishing or _busy:
		return
	var fit := fit_of(tool)
	_busy = true
	await _animate_tool(tool, fit != CleanTool.Fit.FORBIDDEN)
	_busy = false
	var no_lock: bool = fit != CleanTool.Fit.FORBIDDEN and BLOW_TOOLS.has(String(tool.id)) \
			and _step != CleanStep.GOLD_CONTACTS and not fan_locked
	match fit:
		CleanTool.Fit.IDEAL:
			if no_lock:
				_warn_no_lock()
			else:
				_say_tool(tool, tool.line_ideal, PibHint.Mood.HAPPY)
			_progress_by(GAIN[CleanTool.Fit.IDEAL])
		CleanTool.Fit.LIMITED:
			var key := "%s:%d" % [tool.id, _step]
			if not _limited_charged.has(key):
				_limited_charged[key] = true
				mistake.emit(&"clean", 3)
				if no_lock:
					_warn_no_lock()
				else:
					_say_tool(tool, tool.line_limited, PibHint.Mood.NORMAL)
			_progress_by(GAIN[CleanTool.Fit.LIMITED])
		_:
			mistake.emit(&"clean", 8)
			if _blocked_once.has(tool.id):
				say_text(["ไม่ทันแล้วขม... " + tool.line_forbidden], PibHint.Mood.WORRY)
			else:
				_blocked_once[tool.id] = true
				_say_tool(tool, "เดี๋ยวก่อน! " + tool.line_forbidden, PibHint.Mood.WORRY)


func _warn_no_lock() -> void:
	if _no_lock_charged:
		return
	_no_lock_charged = true
	mistake.emit(&"clean", 5)
	say("CLEAN_NO_LOCK", PibHint.Mood.WORRY)


func _say_tool(tool: CleanTool, fallback: String, mood: PibHint.Mood) -> void:
	var h: String = TOOL_LINES.get("%s:%d" % [tool.id, _step], TOOL_LINES.get("%s:-1" % tool.id, ""))
	if h != "" and owner.dialog_dict.has(h):
		say(h, mood)
	elif fallback != "":
		say_text([fallback], mood)


func _animate_tool(tool: CleanTool, reach: bool) -> void:
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
	create_tween().tween_property(_bar, "value", _progress, 0.25)
	var looks: Array = STEP_LOOK[_step]
	(node("GpuCard") as Item2D).set_state_blend(looks[0], looks[1], _progress / 100.0)
	if _progress < 100.0:
		return
	if _step < CleanStep.GOLD_CONTACTS:
		_set_step((_step + 1) as CleanStep)
	else:
		(node("GpuCard") as Item2D).set_state("clean")
		_finishing = true
		PhaseUI.set_check(_chk[2], true)
		say("CLEAN_DONE", PibHint.Mood.HAPPY)


func _on_pib_done() -> void:
	if visible and _finishing:
		finish()
