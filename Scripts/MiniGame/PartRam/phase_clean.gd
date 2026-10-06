extends Phase2D
## Phase 5 · CLEAN — 3 ขั้นย่อย เลือกอุปกรณ์จากถาด 6 ชิ้น (สุ่มจาก 10) แล้วดูผลบนแรมในฉาก 2.5D
##   S1 ฝุ่นบนแผง (ฝุ่นจางลง) · S2 ขาทอง (หมอง → วาว) · S3 สล็อตบนเมนบอร์ด (กล้องเลื่อนไปที่สล็อตเอง)
## [Claude 29 ก.ย. 2569] ต่อยอดโครงเดิม (CleanStep · TRAY_SIZE · _tools · _blocked_once · _build_tray · _on_tool_used)
## ข้อมูลอุปกรณ์: Resources/Parts/Ram/Tools/*.tres · กติกาคะแนน: MINIGAME1_DESIGN.md หัวข้อ 14

enum CleanStep {
	DUST_BOARD,
	SCRUB_CONTACTS,
	CLEAN_SLOT,
}

signal step_completed(step: CleanStep)
signal clean_finished(penalty: int)

const TRAY_SIZE := 6
const STEP_TEXT := {
	CleanStep.DUST_BOARD: "S1 · ปัดฝุ่นบนแผงแรม",
	CleanStep.SCRUB_CONTACTS: "S2 · ขัดคราบที่ขาทอง",
	CleanStep.CLEAN_SLOT: "S3 · ทำความสะอาดสล็อต",
}
const STEP_VIEW := {
	CleanStep.DUST_BOARD: &"Mat",
	CleanStep.SCRUB_CONTACTS: &"MatGold",
	CleanStep.CLEAN_SLOT: &"SlotClose",
}
## บทปิ๊บเฉพาะ (อุปกรณ์:ขั้น) ใน Ram_Pib.txt · -1 = ทุกขั้น · ไม่มีในนี้ใช้ line_* ของ CleanTool
const STEP_LINES := {
	"brush:0": MinigameHeader.CLEAN_S1_GOOD,
	"blower:0": MinigameHeader.CLEAN_S1_GOOD,
	"cloth:0": MinigameHeader.CLEAN_S1_GOOD,
	"eraser_white:1": MinigameHeader.CLEAN_S2_ERASER,
	"blower:1": MinigameHeader.CLEAN_S2_BLOWER,
	"eraser_white:2": MinigameHeader.CLEAN_S3_ERASER,
	"sandpaper:-1": MinigameHeader.CLEAN_SANDPAPER,
	"wet_cloth:-1": MinigameHeader.CLEAN_WET_CLOTH,
	"vacuum:-1": MinigameHeader.CLEAN_VACUUM,
}
const GAIN := { CleanTool.Fit.IDEAL: 50.0, CleanTool.Fit.LIMITED: 25.0 } # ✅ 2 ครั้ง · 🟡 4 ครั้ง

# var _tools: Array[CleanTool] = []
var _blocked_once: Dictionary = { } # tool_id -> true (เลือก ❌ ไปแล้วรอบหนึ่ง)
var _limited_charged: Dictionary = { }
var _step: CleanStep = CleanStep.DUST_BOARD
# var _step_list: Array[StepTool] = [StepTool.new(), StepTool.new(), StepTool.new()]
var _progress := 0.0
var _bar_tween: Tween
var _penalty := 0
var _busy := false
var _finishing := false
var _tools: Array[ToolDef] = []
var _built := false
var _step_label: Label
var _bar: ProgressBar
var _tray: HBoxContainer
var _card: Label
var _chk: Array[Label] = []


func init():
	if _tools.is_empty(): # init() ถูกเรียกทุกครั้งที่เข้า phase — โหลดครั้งเดียวพอ ไม่งั้นอุปกรณ์ซ้ำ
		for p in DirAccess.get_files_at(Constant.TOOL_DIR):
			var t := load(Constant.TOOL_DIR + p) as ToolDef
			_tools.append(t)
	if not _built:
		print("build")
		_build()
	_blocked_once.clear()
	_limited_charged.clear()
	_penalty = 0
	_busy = false
	_finishing = false
	show()
	allow([]) # phase นี้คลิกเครื่องมือใน rail อย่างเดียว
	listen(owner.pib.all_lines_finished, _on_pib_done)
	_set_step(CleanStep.DUST_BOARD)
	say(MinigameHeader.CLEAN_TRAY)


func _build() -> void:
	_built = true
	var rail := PhaseUI.make_frame(self, "ซ่อมแรม — ขั้นที่ 5/8 · ทำความสะอาด")
	PhaseUI.set_rail_overlay(self)
	for s in STEP_TEXT:
		_chk.append(PhaseUI.check_item(rail, STEP_TEXT[s]))
	_step_label = PhaseUI.label(rail, "", 18, PhaseUI.COL_OK)
	_bar = ProgressBar.new()
	_bar.max_value = 100
	_bar.custom_minimum_size = Vector2(0, 18)
	rail.add_child(_bar)
	_tray = HBoxContainer.new()
	_tray.add_theme_constant_override("h_separation", 6)
	_tray.set_anchors_preset(PRESET_BOTTOM_WIDE)
	self.add_child(_tray)
	_fill_tray(_tools)
	_card = PhaseUI.label(rail, "ชี้ที่อุปกรณ์เพื่อดูคุณสมบัติ", 14)


func _set_step(step: CleanStep) -> void:
	_step = step
	_progress = 0.0
	if _bar_tween and _bar_tween.is_valid():
		_bar_tween.kill() # tween ของขั้นก่อนยังวิ่งอยู่ จะทับค่า 0 ถ้าไม่ฆ่า
	_bar.value = 0
	_apply_visual(0.0) # รีเซ็ตภาพของขั้นใหม่ให้ตรงกับ progress 0
	_step_label.text = STEP_TEXT[step]
	for i in _chk.size():
		PhaseUI.set_check(_chk[i], i < int(step))
	cam(STEP_VIEW[step])


func _build_tray(step: CleanStep) -> Array[CleanTool]:
	# การันตี ✅ ≥ 1 และ ❌ ≥ 2 แล้วสุ่มที่เหลือให้ครบ TRAY_SIZE
	# var cur_step = _step_list[step]
	# var ideal: CleanTool = cur_step.ideal[randi_range(0, len(cur_step.ideal) - 1)]
	# var limited: CleanTool = cur_step.limited[randi_range(0, len(cur_step.limited) - 1)]
	# var bad: Array[CleanTool] = cur_step.forbidden
	# bad.shuffle()
	# var tray: Array[CleanTool] = []
	# tray.append(ideal)
	# tray.append(limited)
	# tray.append_array(bad.slice(0, -1))
	# while tray.size() > 6:
	# 	tray.pop_back()
	# tray.shuffle()
	# return tray
	return []


func _fill_tray(tray: Array[ToolDef]) -> void:
	for c in _tray.get_children():
		c.queue_free()
	for t in tray:
		var b := TextureButton.new()
		b.texture_normal = t.icon
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.custom_minimum_size = Vector2(80, 70)
		b.tooltip_text = t.display_name
		b.mouse_entered.connect(_show_card.bind(t))
		b.pressed.connect(
			func():
				self._on_tool_used(t, _step),
		)
		_tray.add_child(b)


func _show_card(t: CleanTool) -> void:
	var pips := "▮".repeat(t.hardness) + "▯".repeat(5 - t.hardness)
	_card.text = "%s\nแข็ง %s · ชื้น %s\nไฟฟ้าสถิต %s · เศษ %s · เข้าซอก %s" % [
		t.display_name,
		pips,
		"มี" if t.has_moisture else "ไม่มี",
		"เสี่ยง" if t.esd_risk else "ปลอดภัย",
		"มี" if t.leaves_residue else "ไม่มี",
		"ได้" if t.reaches_narrow else "ไม่ได้",
	]


func _fit(t: CleanTool, step: int) -> int:
	return int(t.fit_per_step.get(step, CleanTool.Fit.FORBIDDEN))


func _on_tool_used(tool: ToolDef, step: CleanStep) -> void:
	if not visible or _finishing or _busy:
		return
	# var fit := _fit(tool, step)
	# _busy = true
	# await _animate_tool(tool, fit != CleanTool.Fit.FORBIDDEN)
	# _busy = false
	match step:
		CleanStep.DUST_BOARD:
			if tool.action & (ToolDef.Action.BRUSH | ToolDef.Action.BLOW):
				# _say_for(tool, step, tool.line_ideal, PibHint.Mood.HAPPY)
				_progress_by(GAIN[CleanTool.Fit.IDEAL])
		CleanStep.SCRUB_CONTACTS:
			# var key := "%s:%d" % [tool.id, step]
			if tool.action & (ToolDef.Action.SCRUB):
				_progress_by(GAIN[CleanTool.Fit.IDEAL])
			elif tool.action & (ToolDef.Action.BRUSH | ToolDef.Action.BLOW):
				_progress_by(GAIN[CleanTool.Fit.LIMITED])
		CleanStep.CLEAN_SLOT:
			if tool.action & (ToolDef.Action.BRUSH | ToolDef.Action.BLOW):
				_progress_by(GAIN[CleanTool.Fit.IDEAL])
			elif tool.action & (ToolDef.Action.SCRUB):
				_progress_by(GAIN[CleanTool.Fit.LIMITED])


## อุปกรณ์ลอยมาถูไปมาที่เป้าหมาย (รูป 2D ในชั้นบนของฉาก) · ห้ามใช้ = ปิ๊บคว้าไว้ก่อนถึง
func _animate_tool(tool: ToolDef, reach: bool) -> void:
	var spr := node("ToolSprite") as TextureRect
	spr.texture = tool.icon
	var half := spr.size / 2.0
	var target := _target_point() - half
	spr.position = target + Vector2(90, -120)
	spr.modulate = Color.WHITE
	spr.show()
	var tw := create_tween()
	if reach:
		tw.tween_property(spr, "position", target, 0.25)
		for i in 3:
			tw.tween_property(spr, "position:x", target.x - 70, 0.12)
			tw.tween_property(spr, "position:x", target.x + 70, 0.12)
	else:
		tw.tween_property(spr, "position", target + Vector2(60, -60), 0.25)
		tw.tween_property(spr, "modulate", Color(1, 0.4, 0.4), 0.15)
		tw.tween_interval(0.25)
	await tw.finished
	spr.hide()
	spr.modulate = Color.WHITE


## จุดเป้าหมาย (พิกัดชั้นบนของฉาก): กลางแรม · ขาทอง (ขอบล่างแรม) · สล็อต
func _target_point() -> Vector2:
	var top := (node("ToolSprite") as Control).get_parent() as Control
	var inv := top.get_global_transform_with_canvas().affine_inverse()
	var ram := node("RamA2") as Control
	var r := ram.get_global_rect()
	match _step:
		CleanStep.SCRUB_CONTACTS:
			return inv * Vector2(r.get_center().x, r.end.y - r.size.y * 0.2)
		CleanStep.CLEAN_SLOT:
			return inv * (node("SlotBodyA2") as Control).get_global_rect().get_center()
	return inv * r.get_center()


func _say_for(tool: CleanTool, step: int, fallback: String, mood: PibHint.Mood) -> void:
	var key := "%s:%d" % [tool.id, step]
	var any := "%s:-1" % tool.id
	if STEP_LINES.has(key):
		say(STEP_LINES[key], mood)
	elif STEP_LINES.has(any):
		say(STEP_LINES[any], mood)
	elif fallback != "":
		say_text([fallback], mood)


func _progress_by(amount: float) -> void:
	_progress = min(_progress + amount, 100.0)
	if _bar_tween and _bar_tween.is_valid():
		_bar_tween.kill()
	_bar_tween = create_tween()
	_bar_tween.tween_property(_bar, "value", _progress, 0.25)
	_apply_visual(_progress / 100.0)
	if _progress >= 100.0:
		step_completed.emit(_step)
		if _step == CleanStep.CLEAN_SLOT:
			_finishing = true
			PhaseUI.set_check(_chk[2], true)
			clean_finished.emit(_penalty)
			say(MinigameHeader.CLEAN_DONE, PibHint.Mood.HAPPY)
		else:
			_set_step((_step + 1) as CleanStep)


## ผลที่เห็นในฉาก: ฝุ่นบนแผงจาง · ขาทองวาว · ฝุ่นในสล็อตหาย
func _apply_visual(t: float) -> void:
	match _step:
		CleanStep.DUST_BOARD:
			var ram := node("RamA2") as Item2D
			ram.set_layer_alpha("Dust", 1.0 - t)
			ram.set_state_blend("dirty", "dusted", t) # ฝุ่นจางลงแบบเปลี่ยนรูป
		CleanStep.SCRUB_CONTACTS:
			owner.set_gold(t)
		CleanStep.CLEAN_SLOT:
			var slot := node("SlotBodyA2") as Item2D
			slot.set_layer_alpha("Dust", 1.0 - t)
			slot.set_state_blend("dirty", "clean", t)


func _on_pib_done() -> void:
	if visible and _finishing:
		finish()
