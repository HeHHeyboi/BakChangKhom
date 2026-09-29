# Scripts/MiniGame/phase_clean.gd
extends Phase
## Phase 4 · CLEAN — 3 ขั้นย่อย เลือกอุปกรณ์จากถาด 6 ชิ้น (สุ่มจาก 10)
## [Claude 29 ก.ย. 2569] เติมโค้ดจากโครงเดิมของเพื่อน (enum CleanStep · signal · TRAY_SIZE · _tools · _blocked_once ·
##   _build_tray · _on_tool_used ยังชื่อเดิม) + UI เบื้องต้นตาม Docs/STORYBOARD.md R4 / Mockup 3 และ MINIGAME1_DESIGN.md หัวข้อ 14
## ข้อมูลอุปกรณ์อยู่ที่ Resources/MiniGame/Tools/*.tres — แก้บท/ค่าพอดีได้โดยไม่ต้องแตะสคริปต์

enum CleanStep {
	DUST_BOARD,
	SCRUB_CONTACTS,
	CLEAN_SLOT,
} # S1 S2 S3

signal step_completed(step: CleanStep)
signal clean_finished(penalty: int)

const TRAY_SIZE := 6
var _tools: Array[CleanTool] # โหลดจาก Resources/MiniGame/Tools/*.tres
var _blocked_once: Dictionary = { } # tool_id -> true (เลือก ❌ ไปแล้วรอบหนึ่ง)

# [Claude] ลิสต์ไฟล์ตรง ๆ แทน DirAccess เพราะตอน export ไฟล์ .tres ถูกแปลงชื่อ
const TOOL_PATHS := [
	"res://Resources/MiniGame/Tools/eraser_white.tres",
	"res://Resources/MiniGame/Tools/brush.tres",
	"res://Resources/MiniGame/Tools/blower.tres",
	"res://Resources/MiniGame/Tools/cloth.tres",
	"res://Resources/MiniGame/Tools/ipa_swab.tres",
	"res://Resources/MiniGame/Tools/eraser_red.tres",
	"res://Resources/MiniGame/Tools/sandpaper.tres",
	"res://Resources/MiniGame/Tools/wet_cloth.tres",
	"res://Resources/MiniGame/Tools/hairdryer.tres",
	"res://Resources/MiniGame/Tools/vacuum.tres",
]
const STEP_TEXT := {
	CleanStep.DUST_BOARD: "S1 · ปัดฝุ่นบนแผงแรม",
	CleanStep.SCRUB_CONTACTS: "S2 · ขัดคราบที่ขาทอง",
	CleanStep.CLEAN_SLOT: "S3 · ทำความสะอาดสลอต",
}
## บทปิ๊บเฉพาะ (อุปกรณ์, ขั้น) ที่มีใน Ram_Pib.txt — ไม่มีในนี้ใช้ line_* ของ CleanTool แทน · -1 = ทุกขั้น
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
const GAIN := { CleanTool.Fit.IDEAL: 50.0, CleanTool.Fit.LIMITED: 25.0 } # ✅ ใช้ 2 ครั้ง · 🟡 ใช้ 4 ครั้ง

var _step: CleanStep = CleanStep.DUST_BOARD
var _progress := 0.0
var _limited_charged: Dictionary = { } # "id:step" -> true (หัก 🟡 ครั้งเดียวต่อชิ้นต่อขั้น)
var _penalty := 0
var _finishing := false

var _built := false
var _bar_tween: Tween
var _target: TextureRect
var _slot: ColorRect
var _bar: ProgressBar
var _step_label: Label
var _tray: HBoxContainer
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
	if not owner.pib.all_lines_finished.is_connected(_on_pib_done):
		owner.pib.all_lines_finished.connect(_on_pib_done)
	_blocked_once.clear()
	_limited_charged.clear()
	_penalty = 0
	_finishing = false
	_set_step(CleanStep.DUST_BOARD)
	show()
	pib_toggle.emit(PibHint.Data.say(MinigameHeader.CLEAN_TRAY))


func _build() -> void:
	_built = true
	var rail := PhaseUI.make_frame(self, "ทำความสะอาดแรม — ขั้นที่ 5/8 · ทำความสะอาด")
	PhaseUI.label(rail, "ขั้นย่อย", 20, PhaseUI.COL_OK)
	for s in STEP_TEXT:
		_chk.append(PhaseUI.check_item(rail, STEP_TEXT[s]))
	PhaseUI.label(rail, "อุปกรณ์ (ชี้เพื่อดูคุณสมบัติ)", 18, PhaseUI.COL_OK)
	_card = PhaseUI.label(rail, "—", 16) # placeholder ของ ui_tool_card.png

	_step_label = PhaseUI.label(self, "", 22)
	_step_label.position = Vector2(30, 70)
	_bar = ProgressBar.new()
	_bar.position = Vector2(30, 105)
	_bar.size = Vector2(800, 22)
	_bar.max_value = 100
	add_child(_bar)

	_target = PhaseUI.texture(self, "res://Assets/MiniGame/PartRam/ram_dirty.png", Rect2(160, 135, 540, 190))
	_slot = PhaseUI.placeholder(
		self,
		Rect2(150, 200, 560, 70),
		Color(0.12, 0.12, 0.15),
		"สลอตบนเมนบอร์ด (ram_slot_empty)",
	)

	# ถาดเครื่องมือ (placeholder ของ ram_tray.png) · y 336–476 ตาม storyboard
	PhaseUI.panel(self, Rect2(20, 336, 820, 136), "Tray", Color(0.35, 0.25, 0.15, 0.85))
	_tray = HBoxContainer.new()
	_tray.position = Vector2(34, 346)
	_tray.size = Vector2(792, 116)
	_tray.add_theme_constant_override("separation", 12)
	add_child(_tray)


func _set_step(step: CleanStep) -> void:
	_step = step
	_progress = 0.0
	if _bar_tween:
		_bar_tween.kill()
	_bar.value = 0
	_step_label.text = STEP_TEXT[step]
	_target.visible = step != CleanStep.CLEAN_SLOT
	_slot.visible = step == CleanStep.CLEAN_SLOT
	_update_target()
	for i in _chk.size():
		PhaseUI.set_check(_chk[i], i < int(step))
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
	var rest := _tools.filter(
		func(t):
			return not tray.has(t),
	)
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
		b.custom_minimum_size = Vector2(120, 116)
		b.tooltip_text = t.display_name
		b.mouse_entered.connect(_show_card.bind(t))
		b.pressed.connect(
			func():
				_on_tool_used(t, _step),
		)
		_tray.add_child(b)


func _show_card(t: CleanTool) -> void:
	var pips := "▮".repeat(t.hardness) + "▯".repeat(5 - t.hardness)
	_card.text = "%s\nความแข็ง %s %d/5\nความชื้น %s\nไฟฟ้าสถิต %s\nเศษตกค้าง %s\nเข้าซอกแคบ %s" % [
		t.display_name,
		pips,
		t.hardness,
		"มี" if t.has_moisture else "ไม่มี",
		"เสี่ยง" if t.esd_risk else "ปลอดภัย",
		"มี" if t.leaves_residue else "ไม่มี",
		"ได้" if t.reaches_narrow else "ไม่ได้",
	]


func _fit(t: CleanTool, step: int) -> int:
	return int(t.fit_per_step.get(step, CleanTool.Fit.FORBIDDEN))


func _on_tool_used(tool: CleanTool, step: CleanStep) -> void:
	if not visible or _finishing:
		return
	match _fit(tool, step):
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
				# ❌ ชิ้นเดิมครั้งที่ 2 = เสียหายจริง → VERIFY บูตไม่ผ่าน
				owner.ram_damaged = true
				_say_for(tool, step, "ไม่ทันแล้วขม... " + tool.line_forbidden, PibHint.Mood.WORRY)
			else:
				# ครั้งแรก ปิ๊บคว้ามือไว้ทัน ไม่เกิดความเสียหาย
				_blocked_once[tool.id] = true
				_say_for(tool, step, "เดี๋ยวก่อน! " + tool.line_forbidden, PibHint.Mood.WORRY)


func _say_for(tool: CleanTool, step: int, fallback: String, mood: PibHint.Mood) -> void:
	var key := "%s:%d" % [tool.id, step]
	var any := "%s:-1" % tool.id
	if STEP_LINES.has(key):
		pib_toggle.emit(PibHint.Data.say(STEP_LINES[key], mood))
	elif STEP_LINES.has(any):
		pib_toggle.emit(PibHint.Data.say(STEP_LINES[any], mood))
	elif fallback != "":
		PhaseUI.pib_say_text([fallback], mood)


func _progress_by(amount: float) -> void:
	_progress = min(_progress + amount, 100.0)
	if _bar_tween:
		_bar_tween.kill()
	_bar_tween = create_tween()
	_bar_tween.tween_property(_bar, "value", _progress, 0.25)
	_update_target()
	if _progress >= 100.0:
		step_completed.emit(_step)
		if _step == CleanStep.CLEAN_SLOT:
			_finishing = true
			PhaseUI.set_check(_chk[2], true)
			clean_finished.emit(_penalty)
			pib_toggle.emit(PibHint.Data.say(MinigameHeader.CLEAN_DONE, PibHint.Mood.HAPPY))
		else:
			_set_step((_step + 1) as CleanStep)


func _update_target() -> void:
	# S1 ฝุ่นบนแผง: dirty → better · S2 ขาทอง: better → clean
	var tex := "ram_dirty"
	if _step == CleanStep.DUST_BOARD:
		tex = "ram_better" if _progress >= 100.0 else "ram_dirty"
	elif _step == CleanStep.SCRUB_CONTACTS:
		tex = "ram_clean" if _progress >= 100.0 else "ram_better"
	_target.texture = load("res://Assets/MiniGame/PartRam/%s.png" % tex)


## [Claude] ต่อจาก PibHint.all_lines_finished ใน init() (ไม่ต้องต่อใน Editor) — จบ phase หลังปิ๊บพูด CLEAN_DONE จบ
func _on_pib_done() -> void:
	if not visible or not _finishing:
		return
	hide()
	phase_completed.emit()
