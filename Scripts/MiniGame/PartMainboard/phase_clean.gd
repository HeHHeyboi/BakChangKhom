extends Phase2D
## Phase 5 · CLEAN — เลือกอุปกรณ์เช็ดซิลิโคนเก่า 2 ขั้น: S1 ผิว CPU (มุมซ็อกเก็ต) · S2 ฐานฮีตซิงก์ (แผ่น ESD)
## กติกาเหมือน Part RAM: ตัดสินจาก ToolDef.action (✅ +50% · 🟡 +25% · อุปกรณ์ที่ไม่ตรงกับขั้นนั้นไม่ทำอะไร)
##   ทั้ง 2 ขั้น: เช็ด (WIPE) = ✅ · ขัด (SCRUB) = 🟡
## อุปกรณ์: Constant.TOOL_DIR/*.tres (ToolDef) · [Claude 2 ต.ค. 2569]

enum CleanStep { CPU_SURFACE, HEATSINK_BASE }

const STEP_TEXT := {
	CleanStep.CPU_SURFACE: "S1 · เช็ดผิว CPU",
	CleanStep.HEATSINK_BASE: "S2 · เช็ดฐานฮีตซิงก์",
}
const STEP_VIEW := { CleanStep.CPU_SURFACE: &"Socket", CleanStep.HEATSINK_BASE: &"Mat" }
## บทปิ๊บเฉพาะอุปกรณ์ใน Mainboard_Pib.txt (ไม่มีในนี้ = ปิ๊บไม่พูด)
const TOOL_LINES := {
	"ipa_swab": "CLEAN_IPA",
	"tissue": "CLEAN_TISSUE",
	"wet_cloth": "CLEAN_WATER",
	"thinner": "CLEAN_THINNER",
	"sandpaper": "CLEAN_SANDPAPER",
}
const GAIN := { CleanTool.Fit.IDEAL: 50.0, CleanTool.Fit.LIMITED: 25.0 }

var _tools: Array[ToolDef] = []
var _step := CleanStep.CPU_SURFACE
var _progress := 0.0
var _bar_tween: Tween
var _busy := false
var _finishing := false
var _built := false
var _chk: Array[Label] = []
var _bar: ProgressBar
var _tray: HBoxContainer
var _card: Label


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


func _set_step(step: CleanStep) -> void:
	_step = step
	_progress = 0.0
	if _bar_tween and _bar_tween.is_valid():
		_bar_tween.kill() # tween ของขั้นก่อนยังวิ่งอยู่ จะทับค่า 0 ถ้าไม่ฆ่า
	_bar.value = 0
	_apply_visual(0.0) # รีเซ็ตภาพของขั้นใหม่ให้ตรงกับ progress 0
	for i in _chk.size():
		PhaseUI.set_check(_chk[i], i < int(step))
	cam(STEP_VIEW[step])
	_fill_tray()


func _fill_tray() -> void:
	for c in _tray.get_children():
		c.queue_free()
	for t: ToolDef in _tools:
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


## เช็ด (WIPE) = ✅ · ขัด (SCRUB) = 🟡 · อย่างอื่นไม่ทำอะไร (เหมือน Part RAM)
func use_tool(tool: ToolDef) -> void:
	if not visible or _finishing or _busy:
		return
	var gain: float
	if tool.action & ToolDef.Action.WIPE:
		gain = GAIN[CleanTool.Fit.IDEAL]
	elif tool.action & ToolDef.Action.SCRUB:
		gain = GAIN[CleanTool.Fit.LIMITED]
	else:
		return
	_animate_tool(tool, true)
	_say_tool(tool, PibHint.Mood.HAPPY)
	_progress_by(gain)


func _say_tool(tool: ToolDef, mood: PibHint.Mood) -> void:
	var h: String = TOOL_LINES.get(String(tool.id), "")
	if h != "" and owner.dialog_dict.has(h):
		say(h, mood)


func _target() -> Control:
	return node("Cpu") if _step == CleanStep.CPU_SURFACE else node("HeatsinkBase")


## อุปกรณ์ลอยมาถูไปมาที่เป้าหมาย · ห้ามใช้ = ปิ๊บคว้าไว้ก่อนถึง
func _animate_tool(tool: ToolDef, reach: bool) -> void:
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
	if _bar_tween and _bar_tween.is_valid():
		_bar_tween.kill()
	_bar_tween = create_tween()
	_bar_tween.tween_property(_bar, "value", _progress, 0.25)
	_apply_visual(_progress / 100.0)
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


## ผลที่เห็นในฉาก: ซิลิโคนเก่าบนผิว CPU / ฐานฮีตซิงก์ค่อย ๆ สะอาดตาม progress
func _apply_visual(t: float) -> void:
	if _step == CleanStep.CPU_SURFACE:
		(node("Cpu") as Item2D).set_state_blend("old", "clean", t)
	else:
		(node("HeatsinkBase") as Item2D).set_state_blend("dirty", "clean", t)


func _on_pib_done() -> void:
	if visible and _finishing:
		finish()
