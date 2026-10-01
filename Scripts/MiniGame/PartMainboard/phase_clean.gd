extends Phase2D
## Phase 5 · CLEAN — เลือกอุปกรณ์เช็ดซิลิโคนเก่า 2 ขั้น: S1 ผิว CPU (มุมซ็อกเก็ต) · S2 ฐานฮีตซิงก์ (แผ่น ESD)
## กติกาเหมือน Part RAM: ✅ +50% · 🟡 +25% และ −3 ครั้งแรก · ❌ −8 ปิ๊บห้ามทันครั้งแรก
## อุปกรณ์: Resources/Parts/Mainboard/Tools/*.tres (CleanTool ตัวเดิม) · [Claude 2 ต.ค. 2569]

enum CleanStep { CPU_SURFACE, HEATSINK_BASE }

const TOOL_DIR := "res://Resources/Parts/Mainboard/Tools/"
const TOOL_IDS := ["ipa_swab", "cloth", "tissue", "wet_cloth", "thinner", "sandpaper", "wire_brush"]
const STEP_TEXT := {
	CleanStep.CPU_SURFACE: "S1 · เช็ดผิว CPU",
	CleanStep.HEATSINK_BASE: "S2 · เช็ดฐานฮีตซิงก์",
}
const STEP_VIEW := { CleanStep.CPU_SURFACE: &"Socket", CleanStep.HEATSINK_BASE: &"Mat" }
## บทปิ๊บเฉพาะใน Mainboard_Pib.txt (ไม่มี = ใช้ line_* ของ CleanTool)
const TOOL_LINES := {
	"ipa_swab": "CLEAN_IPA",
	"tissue": "CLEAN_TISSUE",
	"wet_cloth": "CLEAN_WATER",
	"thinner": "CLEAN_THINNER",
	"sandpaper": "CLEAN_SANDPAPER",
}
const GAIN := { CleanTool.Fit.IDEAL: 50.0, CleanTool.Fit.LIMITED: 25.0 }

var _tools: Array[CleanTool] = []
var _step := CleanStep.CPU_SURFACE
var _progress := 0.0
var _blocked_once := {}
var _limited_charged := {}
var _busy := false
var _finishing := false
var _built := false
var _chk: Array[Label] = []
var _bar: ProgressBar
var _tray: GridContainer
var _card: Label


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
	show()
	allow([])
	listen(owner.pib.all_lines_finished, _on_pib_done)
	_set_step(CleanStep.CPU_SURFACE)
	say("CLEAN_TRAY")


func _build() -> void:
	_built = true
	var rail := PhaseUI.make_frame(self, "ซ่อมเมนบอร์ด — ขั้นที่ 5/8 · เช็ดซิลิโคนเก่า")
	for s in STEP_TEXT:
		_chk.append(PhaseUI.check_item(rail, STEP_TEXT[s]))
	_bar = ProgressBar.new()
	_bar.max_value = 100
	_bar.custom_minimum_size = Vector2(0, 18)
	rail.add_child(_bar)
	_tray = GridContainer.new()
	_tray.columns = 3
	_tray.add_theme_constant_override("h_separation", 6)
	_tray.add_theme_constant_override("v_separation", 6)
	rail.add_child(_tray)
	_card = PhaseUI.label(rail, "ชี้ที่อุปกรณ์เพื่อดูคุณสมบัติ", 14)


func _set_step(step: CleanStep) -> void:
	_step = step
	_progress = 0.0
	_bar.value = 0
	for i in _chk.size():
		PhaseUI.set_check(_chk[i], i < int(step))
	cam(STEP_VIEW[step])
	_fill_tray()


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
		b.custom_minimum_size = Vector2(80, 64)
		b.tooltip_text = t.display_name
		b.mouse_entered.connect(_show_card.bind(t))
		b.pressed.connect(func(): use_tool(t))
		_tray.add_child(b)


func _show_card(t: CleanTool) -> void:
	_card.text = "%s\nชื้น %s · ทิ้งเศษ %s · แข็ง %d/5" % [
		t.display_name, "มี" if t.has_moisture else "ไม่มี", "มี" if t.leaves_residue else "ไม่มี", t.hardness]


func fit_of(t: CleanTool) -> int:
	return int(t.fit_per_step.get(int(_step), CleanTool.Fit.FORBIDDEN))


func tool_by_id(id: String) -> CleanTool:
	for t in _tools:
		if String(t.id) == id:
			return t
	return null


func use_tool(tool: CleanTool) -> void:
	if not visible or _finishing or _busy:
		return
	var fit := fit_of(tool)
	_busy = true
	await _animate_tool(tool, fit != CleanTool.Fit.FORBIDDEN)
	_busy = false
	match fit:
		CleanTool.Fit.IDEAL:
			_say_tool(tool, tool.line_ideal, PibHint.Mood.HAPPY)
			_progress_by(GAIN[CleanTool.Fit.IDEAL])
		CleanTool.Fit.LIMITED:
			var key := "%s:%d" % [tool.id, _step]
			if not _limited_charged.has(key):
				_limited_charged[key] = true
				mistake.emit(&"tools", 3)
				_say_tool(tool, tool.line_limited, PibHint.Mood.NORMAL)
			_progress_by(GAIN[CleanTool.Fit.LIMITED])
		_:
			mistake.emit(&"tools", 8)
			if _blocked_once.has(tool.id):
				say_text(["ไม่ทันแล้วขม... " + tool.line_forbidden], PibHint.Mood.WORRY)
			else:
				_blocked_once[tool.id] = true
				_say_tool(tool, "เดี๋ยวก่อน! " + tool.line_forbidden, PibHint.Mood.WORRY)


func _say_tool(tool: CleanTool, fallback: String, mood: PibHint.Mood) -> void:
	var h: String = TOOL_LINES.get(String(tool.id), "")
	if h != "" and owner.dialog_dict.has(h):
		say(h, mood)
	elif fallback != "":
		say_text([fallback], mood)


func _target() -> Control:
	return node("Cpu") if _step == CleanStep.CPU_SURFACE else node("HeatsinkBase")


## อุปกรณ์ลอยมาถูไปมาที่เป้าหมาย · ห้ามใช้ = ปิ๊บคว้าไว้ก่อนถึง
func _animate_tool(tool: CleanTool, reach: bool) -> void:
	var spr := node("ToolSprite") as TextureRect
	var top := spr.get_parent() as Control
	var tgt := top.get_global_transform_with_canvas().affine_inverse() * _target().get_global_rect().get_center() - spr.size / 2.0
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
	var t := _progress / 100.0
	if _step == CleanStep.CPU_SURFACE:
		(node("Cpu") as Item2D).set_state_blend("old", "clean", t)
	else:
		(node("HeatsinkBase") as Item2D).set_state_blend("dirty", "clean", t)
	if _progress < 100.0:
		return
	if _step == CleanStep.CPU_SURFACE:
		(node("Cpu") as Item2D).set_state("clean")
		_set_step(CleanStep.HEATSINK_BASE)
	else:
		(node("HeatsinkBase") as Item2D).set_state("clean")
		(node("Cooler") as Item2D).set_state("") # เป่าฝุ่นครีบไปพร้อมกัน
		_finishing = true
		PhaseUI.set_check(_chk[1], true)
		say("CLEAN_DONE", PibHint.Mood.HAPPY)


func _on_pib_done() -> void:
	if visible and _finishing:
		finish()
