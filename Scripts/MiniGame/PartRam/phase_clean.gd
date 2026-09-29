extends Phase3D
## Phase 5 · CLEAN — 3 ขั้นย่อย เลือกอุปกรณ์จากถาด 6 ชิ้น (สุ่มจาก 10) แล้วดูผลบนแรมในฉาก 3D
##   S1 ฝุ่นบนแผง (ฝุ่นจางลง) · S2 ขาทอง (หมอง → วาว) · S3 สล็อตบนเมนบอร์ด (กล้องเลื่อนไปที่สล็อตเอง)
## [Claude 29 ก.ย. 2569] ต่อยอดโครงเดิม (CleanStep · TRAY_SIZE · _tools · _blocked_once · _build_tray · _on_tool_used)
## ข้อมูลอุปกรณ์: Resources/Parts/Ram/Tools/*.tres · กติกาคะแนน: MINIGAME1_DESIGN.md หัวข้อ 14

enum CleanStep {
	DUST_BOARD,
	SCRUB_CONTACTS,
	CLEAN_SLOT,
} # S1 S2 S3

signal step_completed(step: CleanStep)
signal clean_finished(penalty: int)

const TRAY_SIZE := 6
const TOOL_PATHS := [
	"res://Resources/Parts/Ram/Tools/eraser_white.tres",
	"res://Resources/Parts/Ram/Tools/brush.tres",
	"res://Resources/Parts/Ram/Tools/blower.tres",
	"res://Resources/Parts/Ram/Tools/cloth.tres",
	"res://Resources/Parts/Ram/Tools/ipa_swab.tres",
	"res://Resources/Parts/Ram/Tools/eraser_red.tres",
	"res://Resources/Parts/Ram/Tools/sandpaper.tres",
	"res://Resources/Parts/Ram/Tools/wet_cloth.tres",
	"res://Resources/Parts/Ram/Tools/hairdryer.tres",
	"res://Resources/Parts/Ram/Tools/vacuum.tres",
]
const STEP_TEXT := {
	CleanStep.DUST_BOARD: "S1 · ปัดฝุ่นบนแผงแรม",
	CleanStep.SCRUB_CONTACTS: "S2 · ขัดคราบที่ขาทอง",
	CleanStep.CLEAN_SLOT: "S3 · ทำความสะอาดสล็อต",
}
const STEP_VIEW := { CleanStep.DUST_BOARD: &"Mat", CleanStep.SCRUB_CONTACTS: &"MatGold", CleanStep.CLEAN_SLOT: &"SlotClose" }
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

var _tools: Array[CleanTool] = []
var _blocked_once: Dictionary = { } # tool_id -> true (เลือก ❌ ไปแล้วรอบหนึ่ง)
var _limited_charged: Dictionary = { }
var _step: CleanStep = CleanStep.DUST_BOARD
var _progress := 0.0
var _penalty := 0
var _busy := false
var _finishing := false

var _built := false
var _step_label: Label
var _bar: ProgressBar
var _tray: GridContainer
var _card: Label
var _chk: Array[Label] = []


func init():
	if _tools.is_empty():
		for p in TOOL_PATHS:
			var t := load(p) as CleanTool
			if t:
				_tools.append(t)
	if not _built:
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
	for s in STEP_TEXT:
		_chk.append(PhaseUI.check_item(rail, STEP_TEXT[s]))
	_step_label = PhaseUI.label(rail, "", 18, PhaseUI.COL_OK)
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
	_step_label.text = STEP_TEXT[step]
	for i in _chk.size():
		PhaseUI.set_check(_chk[i], i < int(step))
	cam(STEP_VIEW[step])
	_fill_tray(_build_tray(step))


func _build_tray(step: CleanStep) -> Array[CleanTool]:
	# การันตี ✅ ≥ 1 และ ❌ ≥ 2 แล้วสุ่มที่เหลือให้ครบ TRAY_SIZE
	var ideal: Array[CleanTool] = []
	var bad: Array[CleanTool] = []
	for t in _tools:
		var f := _fit(t, step)
		if f == CleanTool.Fit.IDEAL:
			ideal.append(t)
		elif f == CleanTool.Fit.FORBIDDEN:
			bad.append(t)
	ideal.shuffle()
	bad.shuffle()
	var tray: Array[CleanTool] = []
	tray.append_array(ideal.slice(0, 1))
	tray.append_array(bad.slice(0, 2))
	var rest := _tools.filter(func(t): return not tray.has(t))
	rest.shuffle()
	for t in rest:
		if tray.size() >= TRAY_SIZE:
			break
		tray.append(t)
	tray.shuffle()
	return tray


func _fill_tray(tray: Array[CleanTool]) -> void:
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
		b.pressed.connect(func(): _on_tool_used(t, _step))
		_tray.add_child(b)


func _show_card(t: CleanTool) -> void:
	var pips := "▮".repeat(t.hardness) + "▯".repeat(5 - t.hardness)
	_card.text = "%s\nแข็ง %s · ชื้น %s\nไฟฟ้าสถิต %s · เศษ %s · เข้าซอก %s" % [
		t.display_name, pips,
		"มี" if t.has_moisture else "ไม่มี",
		"เสี่ยง" if t.esd_risk else "ปลอดภัย",
		"มี" if t.leaves_residue else "ไม่มี",
		"ได้" if t.reaches_narrow else "ไม่ได้",
	]


func _fit(t: CleanTool, step: int) -> int:
	return int(t.fit_per_step.get(step, CleanTool.Fit.FORBIDDEN))


func _on_tool_used(tool: CleanTool, step: CleanStep) -> void:
	if not visible or _finishing or _busy:
		return
	var fit := _fit(tool, step)
	_busy = true
	await _animate_tool(tool, fit != CleanTool.Fit.FORBIDDEN)
	_busy = false
	match fit:
		CleanTool.Fit.IDEAL:
			_say_for(tool, step, tool.line_ideal, PibHint.Mood.HAPPY)
			_progress_by(GAIN[CleanTool.Fit.IDEAL])
		CleanTool.Fit.LIMITED:
			var key := "%s:%d" % [tool.id, step]
			if not _limited_charged.has(key):
				_limited_charged[key] = true
				_penalty += 3
				mistake.emit(&"tools", 3)
				_say_for(tool, step, tool.line_limited, PibHint.Mood.NORMAL)
			_progress_by(GAIN[CleanTool.Fit.LIMITED])
		CleanTool.Fit.FORBIDDEN:
			_penalty += 8
			mistake.emit(&"tools", 8)
			if _blocked_once.has(tool.id):
				owner.ram_damaged = true # ❌ ชิ้นเดิมครั้งที่ 2 = เสียหายจริง → VERIFY บูตไม่ผ่าน
				_say_for(tool, step, "ไม่ทันแล้วขม... " + tool.line_forbidden, PibHint.Mood.WORRY)
			else:
				_blocked_once[tool.id] = true # ครั้งแรก ปิ๊บคว้ามือไว้ทัน
				_say_for(tool, step, "เดี๋ยวก่อน! " + tool.line_forbidden, PibHint.Mood.WORRY)


## อุปกรณ์ (ภาพ 2D แบบ billboard) ลอยมาถูไปมาที่เป้าหมาย · ห้ามใช้ = ปิ๊บคว้าไว้ก่อนถึง
func _animate_tool(tool: CleanTool, reach: bool) -> void:
	var spr := node("ToolSprite") as Sprite3D
	spr.texture = tool.icon
	var target := _target_point()
	spr.global_position = target + Vector3(0, 0.6, 0.6)
	spr.show()
	var tw := create_tween()
	if reach:
		tw.tween_property(spr, "global_position", target + Vector3(0, 0.05, 0.25), 0.25)
		for i in 3:
			tw.tween_property(spr, "global_position:z", target.z - 0.35, 0.12)
			tw.tween_property(spr, "global_position:z", target.z + 0.35, 0.12)
	else:
		tw.tween_property(spr, "global_position", target + Vector3(0, 0.3, 0.35), 0.25)
		tw.tween_property(spr, "modulate", Color(1, 0.4, 0.4), 0.15)
		tw.tween_interval(0.25)
	await tw.finished
	spr.hide()
	spr.modulate = Color.WHITE


func _target_point() -> Vector3:
	var ram := node("RamA2") as Node3D
	match _step:
		CleanStep.SCRUB_CONTACTS:
			return ram.global_position + Vector3(0, -0.13, 0)
		CleanStep.CLEAN_SLOT:
			return (node("SlotBodyA2") as Node3D).global_position + Vector3(0, 0.05, 0)
	return ram.global_position + Vector3(0, 0.03, 0)


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
	create_tween().tween_property(_bar, "value", _progress, 0.25)
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
			(node("RamA2") as PartBody3D).set_layer_alpha("Dust", 1.0 - t)
		CleanStep.SCRUB_CONTACTS:
			owner.set_gold(t)
		CleanStep.CLEAN_SLOT:
			(node("SlotBodyA2") as PartBody3D).set_layer_alpha("Dust", 1.0 - t)


func _on_pib_done() -> void:
	if visible and _finishing:
		finish()
