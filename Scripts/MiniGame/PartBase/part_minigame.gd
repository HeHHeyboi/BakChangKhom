class_name PartMinigame extends Node2D
## ฐานของมินิเกม Core Part ทุกตัว (RAM · Mainboard · GPU · Front Panel · BIOS)
## ใช้คู่กับซีน res://Scene/MiniGame/PartBase/part_base.tscn (Background + PibHint)
## Part ใหม่: New Inherited Scene จาก part_base.tscn → ใส่ phase node → เปลี่ยน script เป็นคลาสที่ extends PartMinigame
## แล้ว override _register_phases() / _first_phase() / _last_phase() — ดู part_ram.gd เป็นตัวอย่าง
## รายละเอียดเต็ม: Docs/MINIGAME_PREFAB.md

signal phase_changed(phase: int)
signal minigame_finished(score: Dictionary)

@export var pib: PibHint
## ไฟล์บทปิ๊บแบบ @SECTION ของ Part นี้ (เช่น res://Assets/Dialog/MiniGame/Ram_Pib.txt)
@export_file("*.txt") var dialog_path: String
## ใช้คิดค่าซ่อมใน GameState (EconomyConfig.repair_fee) · ว่าง = ชื่อไฟล์ซีน เช่น part_gpu
@export var part_id: StringName

var current_phase: int = -1
var dialog_dict: Dictionary
var _mistakes: Dictionary = { }
var _phase_nodes: Dictionary = { }
## [Claude 13 พ.ย. 2569] แถบล่างใต้ฉาก Stage (y 476–648) — เดิมเห็นรูป Background (ผนังร้าน) โผล่ใต้ฉากตอนปิ๊บไม่พูด ดูเหมือน 2 ฉากซ้อนกัน
const FLOOR_BAR_COLOR := Color(0.2, 0.14, 0.1)
## QTE กลางของมินิเกม — phase เรียก: var r = await owner.qte.run(SPEC, node("ชิ้นงาน"), owner.qte_zone_scale())
var qte: QteRunner
## มีปุ่ม "ข้ามบทฝึก" มุมขวาบน (กด 2 ครั้งยืนยัน) — ใช้กับ Tutorial / งานในเควสต์ · งานลูกค้า (meta work_order) ข้ามไม่ได้เสมอ
@export var skippable := false
var _skip_btn: Button
var _skip_armed := false
## จบมินิเกมไปแล้ว (กันส่ง minigame_finished ซ้ำ → เควสต์เดิน 2 ขั้น / เงินเข้า 2 ครั้ง)
var _finished := false
## [Claude 13 ต.ค. 2569] ปุ่ม "ยอมแพ้งานนี้" (Task Fail) ในงานลูกค้า — ปิดได้ต่อซีนใน Inspector
@export var allow_give_up := true
const GIVE_UP_SCENE := preload("res://Scene/MiniGame/PartBase/give_up_layer.tscn")
## ผู้เล่นกดยอมแพ้ → คะแนน 0 · งานกลับขึ้นกระดานวันถัดไป (DayLoop)
var gave_up := false


func _ready() -> void:
	EventManager.hideUI()
	Global.cur_pib = pib
	dialog_dict = PhaseDialogParser.parse(dialog_path)
	_fill_case_text()
	_load_scenario() # [0.6.0 ขั้น C]
	if pib == null:
		push_error("Pib is null please assign")
		return

	_phase_nodes = _register_phases()
	for phase in _phase_nodes:
		# DEFERRED กันไม่ให้ phase ถัดไปรับสัญญาณ all_lines_finished รอบเดียวกันต่อทันที (BUG-36)
		_phase_nodes[phase].phase_completed.connect(_advance_phase, CONNECT_DEFERRED)
		_phase_nodes[phase].pib_toggle.connect(self.pib_toggle)
		_phase_nodes[phase].mistake.connect(_on_mistake)

	_build_qte()
	_build_floor_bar()
	if skippable and not has_meta("work_order"):
		_build_skip()
	# ขมOS (DesktopMinigame) มีปุ่ม "ส่งงานตามสภาพ" ของตัวเอง (can_give_up) → ไม่ใส่ซ้ำ
	if allow_give_up and has_meta("work_order") and not has_method(&"can_give_up"):
		var gl := GIVE_UP_SCENE.instantiate()
		add_child(gl)
		gl.confirmed.connect(abandon_task)
	_set_phase(_start_phase()) # [0.6.0 ขั้น E] เล่นต่อจากครึ่งตรวจ = เริ่มที่จุดแบ่ง
	if not guide_on():
		_say_try_yourself.call_deferred()
	if OS.is_debug_build():
		_debug_build_ui()


## override: คืน { ค่า enum ของ phase: node ที่ extends Phase }
func _register_phases() -> Dictionary:
	return { }


## override: phase แรกที่จะเริ่ม
func _first_phase() -> int:
	return 0


## override: phase สุดท้าย — จบแล้ว emit minigame_finished
func _last_phase() -> int:
	return -1


func _set_phase(phase: int) -> void:
	if _checkpoint_stops(phase):
		return
	_scenario_phase_changed(phase)
	for p in _phase_nodes:
		if p == phase:
			_phase_nodes[p].visible = true
			_phase_nodes[p].init()
			current_phase = p
			if p == _first_phase() and not _resumed:
				_perk_first_phase.call_deferred(p)
		else:
			_phase_nodes[p].visible = false

	phase_changed.emit(phase)


func _advance_phase() -> void:
	if _finished:
		return
	if _scenario_wants_diag():
		_show_diag()
		return
	if current_phase == _last_phase():
		_finish(true)
		return
	if not _phase_nodes.has(current_phase + 1):
		push_warning("%s: ไม่มี phase %d ต่อจาก %d — จบมินิเกม" % [name, current_phase + 1, current_phase])
		_finish(true)
		return
	_set_phase(current_phase + 1)


## จบมินิเกมครั้งเดียวเท่านั้น · report = ส่งผลงานให้ GameState (งานลูกค้า)
func _finish(report: bool) -> void:
	if _finished:
		return
	_finished = true
	_store_scenario_report()
	if report:
		_report_repair()
	minigame_finished.emit(_mistakes)


func _build_qte() -> void:
	if qte:
		return
	var layer := CanvasLayer.new()
	layer.name = "QteLayer"
	layer.layer = 30
	add_child(layer)
	qte = QteRunner.new()
	qte.name = "Qte"
	layer.add_child(qte)


func _build_skip() -> void:
	var layer := CanvasLayer.new()
	layer.name = "SkipLayer"
	layer.layer = 35
	add_child(layer)
	_skip_btn = Button.new()
	_skip_btn.text = "ข้ามบทฝึก ►"
	_skip_btn.focus_mode = Control.FOCUS_NONE
	_skip_btn.add_theme_font_size_override("font_size", 18)
	_skip_btn.position = Vector2(1000, 12)
	_skip_btn.pressed.connect(_on_skip_pressed)
	layer.add_child(_skip_btn)


## กดครั้งแรก = ถามยืนยัน (3 วิ) · กดซ้ำ = จบมินิเกมทันที (ไม่คิดคะแนน/เงิน) แล้วเควสต์เดินต่อ
func _on_skip_pressed() -> void:
	if _finished or not is_inside_tree():
		return
	if not _skip_armed:
		_skip_armed = true
		_skip_btn.text = "แน่ใจ? กดอีกครั้ง"
		_skip_btn.reset_size()
		_skip_btn.position.x = 1152 - _skip_btn.size.x - 12
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(_skip_btn) and not _finished:
			_skip_armed = false
			_skip_btn.text = "ข้ามบทฝึก ►"
		return
	skip()


## ข้ามมินิเกมทั้งตัว — phase ปัจจุบันถูก abort · ส่ง minigame_finished ให้ Part ปิดตัวเองตามปกติ
func skip() -> void:
	if _finished:
		return
	if has_meta("work_order"):
		push_warning("%s: งานลูกค้าข้ามไม่ได้" % name)
		return
	if qte:
		qte.cancel()
	if _phase_nodes.has(current_phase) and is_instance_valid(_phase_nodes[current_phase]):
		_phase_nodes[current_phase].abort()
	if is_instance_valid(pib):
		pib.hide()
	if is_instance_valid(_skip_btn):
		_skip_btn.disabled = true
	_finish(false)


## [13 ต.ค.] ยอมแพ้งานลูกค้า → หยุด phase/QTE · ส่งผล FAIL (คะแนน 0) ให้ GameState · ปิดมินิเกมตามปกติ
func abandon_task() -> void:
	if _finished:
		return
	gave_up = true
	if qte:
		qte.cancel()
	if _phase_nodes.has(current_phase) and is_instance_valid(_phase_nodes[current_phase]):
		_phase_nodes[current_phase].abort()
	if is_instance_valid(pib):
		pib.hide()
	_finish(true)


func _exit_tree() -> void:
	if qte:
		qte.cancel()


## [13 ต.ค.] ไกด์ (วงกลมชี้ "คลิกตรงนี้" + ปิ๊บพูดยาว) เปิดไหม — playtest: งาน RAM วน 4–5 รอบแล้วไกด์ซ้ำจนไม่ได้คิดเอง
## อัตโนมัติ: งานลูกค้าที่เคยซ่อม Part นี้ผ่านแล้ว = ปิด (เปิดสมุดคู่มือดูได้เสมอ) · Tutorial/เควสต์ = เปิด
func guide_on() -> bool:
	match int(GameSettings.get_value("guide_mode")):
		GameSettings.GUIDE_ALWAYS:
			return true
		GameSettings.GUIDE_OFF:
			return false
	var gs := get_node_or_null(^"/root/GameState")
	var id := part_id if part_id != &"" else StringName(scene_file_path.get_file().get_basename())
	if has_meta("work_order") and gs and gs.rank_level >= gs.economy.guide_hint_rank and not hint_requested: # [0.6.0 ขั้น J] ยศเชี่ยวชาญ: ใบ้เมื่อขอ
		return false
	return not (has_meta("work_order") and gs and gs.has_cleared(id))


func _say_try_yourself() -> void:
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(pib) and not _finished:
		pib.toast(DialogToken.new(PibHint.DEFAULT_SPEAKER, "งานนี้เคยทำแล้ว ครั้งนี้ลองเองนะ! ติดตรงไหนแตะสมุดคู่มือมุมขวาบน"), 5.0, PibHint.Mood.NORMAL)


## ครั้งแรกที่ซ่อม Part นี้ผ่าน (ยังไม่เคยผ่าน) โซน QTE กว้าง 1.5 เท่า · Docs/CORE_PART_QTE.md ข้อ 1
func qte_zone_scale() -> float:
	var gs := get_node_or_null(^"/root/GameState")
	var id := part_id if part_id != &"" else StringName(scene_file_path.get_file().get_basename())
	var mult := 1.0
	if gs and gs.has_tool(&"magnet_driver"): # [0.6.0 ขั้น J] ไขควงแม่เหล็ก
		mult = gs.economy.magnet_qte_mult
	if gs and gs.has_perk(&"steady_hand"): # [0.6.0 ขั้น K] มือนิ่ง
		mult *= gs.economy.perk_steady_mult
	if gs and gs.has_cleared(id):
		return mult
	return 1.5 * mult


## ส่งผลงานซ่อมให้ GameState (เงิน · ความพอใจ · XP) — ลูปเกม Docs/GAME_LOOP.md §3
## เฉพาะงานลูกค้าที่ DayLoop เปิด (meta "work_order" = CustomerCase) · งานในเควสต์/Debug ไม่คิดเงิน
func _report_repair() -> void:
	var gs := get_node_or_null(^"/root/GameState")
	if gs == null or not has_meta("work_order"):
		return
	var id := part_id
	if id == &"":
		id = StringName(scene_file_path.get_file().get_basename())
	var fee := -1
	var level := 0
	var order = get_meta("work_order")
	if order is CustomerCase:
		fee = order.fee
		level = order.level
		if order.part_id != String(id):
			push_warning("%s: งานลูกค้า %s เป็น %s แต่มินิเกมนี้คือ %s" % [name, order.id, order.part_id, id])
	gs.record_repair(id, mini(final_score() + self_bonus(), 100) if not gave_up else final_score(), repair_damaged(), fee, level, gave_up)


## คะแนน 0–100 จาก phase สุดท้าย (SUMMARY มี var total) · ไม่มี = คิดจาก _mistakes
func final_score() -> int:
	if gave_up:
		return 0
	var last = _phase_nodes.get(_last_phase())
	if is_instance_valid(last) and "total" in last:
		return clampi(int(last.total), 0, 100)
	var lost := 0
	for k in _mistakes:
		lost += int(_mistakes[k])
	return clampi(100 - lost, 0, 100)


## override: ทำของลูกค้าเสียระหว่างซ่อม (การ์ดไหม้ · ขาซ็อกเก็ตงอ ฯลฯ) → หักเงิน
func repair_damaged() -> bool:
	return false


## สะสมคะแนนที่ถูกหักแยกตามหมวด — Phase SUMMARY อ่านจาก _mistakes
func _on_mistake(category: StringName, points: int) -> void:
	_mistakes[category] = _mistakes.get(category, 0) + points


func pib_toggle(data: PibHint.Data):
	# เช็ก has() ก่อนทั้งสองกรณี (BUG-33)
	if not dialog_dict.has(data.header):
		push_error("There is no header %s" % data.header)
		return
	match data.type:
		data.Act.SAY:
			pib.say(dialog_dict[data.header], data.mood)
		data.Act.TOAST:
			pib.toast(dialog_dict[data.header][0], data.seconds)

# ---------------------------------------------------------------- Debug: กระโดดข้าม phase (เฉพาะ debug build · F2 เปิด/ปิด)

const DEBUG_TOGGLE_KEY := KEY_F2

var _debug_layer: CanvasLayer


## override: ชื่อที่โชว์บนปุ่ม (ปกติใช้ PhaseState.find_key(phase) ของคลาสลูก)
func _debug_phase_name(phase: int) -> String:
	return str(phase)


## override: จัดสถานะในฉากให้เหมือนเล่นมาถึงก่อน phase นี้ (ตัวแปรที่ส่งข้าม phase · ภาพชิ้นส่วน · ตำแหน่งชิ้นส่วน)
func _debug_prepare(_phase: int) -> void:
	pass


## ข้ามไป phase ใดก็ได้ — เก็บ phase ที่กำลังเล่นแบบเงียบ ๆ (ไม่ emit phase_completed) แล้วเริ่ม phase ใหม่
func debug_jump(phase: int) -> void:
	if not _phase_nodes.has(phase):
		return
	if _phase_nodes.has(current_phase):
		_phase_nodes[current_phase].abort()
	_debug_prepare(phase)
	_set_phase(phase)


func _debug_build_ui() -> void:
	_debug_layer = CanvasLayer.new()
	_debug_layer.layer = 130
	_debug_layer.visible = false
	add_child(_debug_layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 120)
	_debug_layer.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "Debug: Jump Phase (F2 to close)"
	box.add_child(title)
	var phases := _phase_nodes.keys()
	phases.sort()
	for ph in phases:
		var b := Button.new()
		b.text = "%d · %s" % [ph, _debug_phase_name(ph)]
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(
			func():
				debug_jump(ph)
				_debug_layer.visible = false,
		)
		box.add_child(b)


func _unhandled_input(event: InputEvent) -> void:
	if (
		_debug_layer and event is InputEventKey and event.pressed
		and not event.echo and event.physical_keycode == DEBUG_TOGGLE_KEY
	):
		_debug_layer.visible = not _debug_layer.visible
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- [8 พ.ย. 2569] บทปิ๊บใช้อาการจากใบงานลูกค้า


## ในไฟล์บท (Assets/Dialog/MiniGame/*_Pib.txt) เขียน {symptom|ข้อความเดิม} · {customer|…} · {device|…} ได้
## งานลูกค้า (มี meta work_order) → ใช้ค่าจาก CustomerCase · บทฝึก/เควสต์หลัก (ไม่มีใบงาน) → ใช้ข้อความหลัง |
## กันอาการที่ลูกค้าเล่ากับที่ปิ๊บพูดไม่ตรงกัน (เดิมปิ๊บพูดข้อความตายตัวของ Part นั้น)
func _fill_case_text() -> void:
	var c: CustomerCase = get_meta("work_order") as CustomerCase if has_meta("work_order") else null
	for key in dialog_dict:
		for t in dialog_dict[key]:
			if t is DialogToken and t.dialog.contains("{"):
				t.dialog = fill_case_text(t.dialog, c)


static func fill_case_text(text: String, c: CustomerCase) -> String:
	var re := RegEx.create_from_string("\\{(symptom|customer|device)\\|([^}]*)\\}")
	var out := text
	for m in re.search_all(text):
		var v := ""
		if c:
			v = String(c.get(m.get_string(1))).strip_edges().trim_suffix(".")
		out = out.replace(m.get_string(), v if v != "" else m.get_string(2))
	return out


## ปิดพื้นที่นอก Stage (ใต้ฉาก + มุมขวาบนเหนือสมุด) ด้วยพื้นสีเข้มทั้งจอ แทนรูป Background ที่โผล่มา
## อยู่ใต้ Stage และใต้ PibHint (CanvasLayer 120) · ซ่อนตาม Stage → ช่วงที่ Phase ซ่อน Stage ยังเห็น Background เดิม
func _build_floor_bar() -> void:
	var stage := get_node_or_null("Stage") as Control
	if stage == null or has_node("FloorBar"):
		return
	var bar := Panel.new()
	bar.name = "FloorBar"
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.position = Vector2.ZERO
	bar.size = Vector2(1152, 648)
	var sb := StyleBoxFlat.new()
	sb.bg_color = FLOOR_BAR_COLOR
	bar.add_theme_stylebox_override(&"panel", sb)
	var line := ColorRect.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.color = FLOOR_BAR_COLOR.darkened(0.5)
	line.position = Vector2(0, stage.position.y + stage.size.y)
	line.size = Vector2(1152, 4)
	bar.add_child(line)
	add_child(bar)
	move_child(bar, stage.get_index())
	bar.visible = stage.visible
	stage.visibility_changed.connect(func(): bar.visible = stage.visible)


# ---------------------------------------------------------------- [0.6.0 ขั้น C] สถานการณ์ซ่อม (PLAN_0_6_0 ข้อ 3)
# ฉากเหมือนเดิม — สถานการณ์เปลี่ยนบทปิ๊บ (RepairScenario.lines) · ถามสาเหตุหลังตรวจครบ (Part ที่ไม่มีขั้นวินิจฉัยของตัวเอง)
# · ปุ่ม "ข้ามขั้นนี้" ในขั้นที่เคสนี้ไม่จำเป็น · ผลเก็บใน meta "scenario_report" ของงาน (DayLoop จดลง scenario_log)

var scenario: RepairScenario
var scenario_stats := { "wrong": 0, "skipped": [], "did_optional": [] }
var _diag_done := false
var _scen_layer: CanvasLayer
var _diag_panel: PanelContainer
var _skip_opt_btn: Button
var _diag_advancing := false

## บทที่บอกสาเหตุของเคสเดิมตรง ๆ → สถานการณ์อื่นใช้บทกลางแทน (ก่อนใส่ RepairScenario.lines)
const NEUTRAL_LINES := {
	&"part_ram": {
		"DIAGNOSIS_HINT": "ลองย้อนดูเบาะแสที่ได้จากในเคสอีกครั้งนะ แล้วเทียบกับที่ลูกค้าเล่า",
	},
	&"part_mainboard": {
		"BRIEFING": "ความร้อนจาก CPU ไม่ได้ลอยหายไปเองนะขม มันต้องถูกพาออกไปทางฮีตซิงก์|ซิลิโคนมีไว้ไล่อากาศออก ไม่ได้มีไว้เป็นกาว ทาบาง ๆ ก็พอ|ระหว่างซ่อม เราจะเปลี่ยนซิลิโคนให้ใหม่ด้วยเลย",
		"INSPECT_DONE": "ครบแล้ว ลองสรุปดูว่าอะไรคือต้นเหตุจริง ๆ",
	},
	&"part_gpu": {
		"BRIEFING": "สลอตยาวที่สุดบนเมนบอร์ดที่อยู่ใกล้ CPU นั่นแหละคือ PCIe x16 ช่องของการ์ดจอ|การ์ดจอกินไฟเยอะกว่าที่สลอตจ่ายให้ได้ เลยต้องต่อสายไฟจากพาวเวอร์เพิ่มอีกเส้น|ระหว่างซ่อม เราจะเช็กไฟ สายจอ และฝุ่นให้ครบทีเดียว",
		"INSPECT_DONE": "ครบแล้ว ลองสรุปดูว่าอะไรคือต้นเหตุจริง ๆ",
	},
	&"part_front_panel": {
		"BRIEFING": "ขมรู้มั้ยว่าปุ่ม power หน้าเคสจริง ๆ แล้วไม่ได้มีไฟวิ่งผ่านเลย|มันแค่เอาขาสองขาบนเมนบอร์ดมาแตะกันชั่วขณะ เมนบอร์ดเห็นว่าแตะกันก็สั่งเปิดเครื่อง|ระหว่างซ่อม เราจะไล่สายหน้าเคสให้ครบทุกเส้น",
	},
	&"part_bios": {
		"BRIEFING": "หน้าจอฟ้า ๆ นี่ไม่ใช่เครื่องพังนะขม มันคือ BIOS โปรแกรมที่อยู่ในเมนบอร์ด|ทุกครั้งที่เปิดเครื่อง BIOS จะทำงานก่อน Windows เสมอ คอยตรวจว่าฮาร์ดแวร์ครบมั้ย",
		"BOOT_ORDER": "ระหว่างนี้แก้ลำดับบูตด้วย อันดับหนึ่งยังเป็น USB ที่ลูกค้าเสียบทิ้งไว้|ให้ดิสก์ที่มีวินโดวส์ขึ้นก่อน เครื่องจะได้ไม่ไปหาที่อื่น",
	},
}


## สถานการณ์ของงานนี้ (meta "scenario" ของมินิเกม หรือของงานลูกค้า) · อ่านได้ก่อน _ready (Part ใช้ตอนจัดฉาก)
func current_scenario() -> RepairScenario:
	if has_meta("scenario") and get_meta("scenario") is RepairScenario:
		return get_meta("scenario")
	if has_meta("work_order") and get_meta("work_order") is CustomerCase:
		return (get_meta("work_order") as CustomerCase).scenario()
	return null


func scenario_flag(key: String, def: Variant = false) -> Variant:
	var sc := current_scenario()
	return sc.flags.get(key, def) if sc else def


func part_key() -> StringName:
	if part_id != &"":
		return part_id
	return StringName(scene_file_path.get_file().get_basename())


func _load_scenario() -> void:
	scenario = current_scenario()
	if scenario == null:
		return
	var tok := func(text: String) -> Array:
		var out := []
		for t in text.split("|", false):
			out.append(DialogToken.new(PibHint.DEFAULT_SPEAKER, t.strip_edges()))
		return out
	if not scenario.flags.get("default", false):
		var neutral: Dictionary = NEUTRAL_LINES.get(part_key(), { })
		for h in neutral:
			dialog_dict[h] = tok.call(neutral[h])
	for h in scenario.lines:
		dialog_dict[h] = scenario.line_tokens(h, PibHint.DEFAULT_SPEAKER)
	if scenario.diag_correct != "":
		dialog_dict["DIAGNOSIS_CORRECT"] = tok.call(scenario.diag_correct)
	# สรุป: สาเหตุ + วิธีสังเกต ก่อนบทสรุปเดิม
	var head: Array = tok.call("สาเหตุของเครื่องนี้คือ%s" % scenario.cause)
	head.append_array(tok.call(scenario.teach))
	head.append_array(dialog_dict.get("SUMMARY", []))
	dialog_dict["SUMMARY"] = head


## Part ที่มีขั้นวินิจฉัย (เลือกสาเหตุ) ของตัวเองอยู่แล้ว override → false (PartRam)
func _scenario_uses_panel() -> bool:
	return true


func _scenario_wants_diag() -> bool:
	return scenario != null and not _diag_done and current_phase == _first_phase() and _scenario_uses_panel() and scenario.diag_choices.size() >= 2 and not gave_up


## ตัวเลือกวินิจฉัย (สลับลำดับ) [[ข้อความ, true=ถูก]…]
func scenario_choices() -> Array:
	var out := []
	if scenario == null:
		return out
	for i in scenario.diag_choices.size():
		out.append([scenario.diag_choices[i], i == 0])
	out.shuffle()
	return out


## ตอบวินิจฉัย (ใช้ทั้งแผงกลางและ PhaseDiagnosis ของแรม) · คืน true = ถูก
func scenario_answer(correct: bool) -> bool:
	if correct:
		_diag_done = true
		return true
	scenario_stats["wrong"] = int(scenario_stats.wrong) + 1
	_on_mistake(&"diagnosis", 10)
	if scenario and scenario.diag_wrong != "":
		pib.say([DialogToken.new(PibHint.DEFAULT_SPEAKER, scenario.diag_wrong)], PibHint.Mood.NORMAL)
	return false


func _scen_canvas() -> CanvasLayer:
	if _scen_layer == null:
		_scen_layer = CanvasLayer.new()
		_scen_layer.layer = 115
		add_child(_scen_layer)
	return _scen_layer


func _show_diag() -> void:
	if is_instance_valid(_diag_panel):
		_diag_panel.show()
		return
	_diag_panel = PanelContainer.new()
	_diag_panel.name = "ScenarioDiag"
	_diag_panel.anchor_left = 0.5
	_diag_panel.anchor_right = 0.5
	_diag_panel.offset_left = -270
	_diag_panel.offset_right = 270
	_diag_panel.offset_top = 70
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.1, 0.08, 0.95)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(16)
	sb.border_color = Color(0.93, 0.73, 0.25)
	sb.set_border_width_all(2)
	_diag_panel.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_diag_panel.add_child(box)
	var title := Label.new()
	title.text = "สรุปอาการ · สาเหตุน่าจะเป็นอะไร?"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.93, 0.73, 0.25))
	box.add_child(title)
	var sym := Label.new()
	sym.text = "ลูกค้าเล่า: \"%s\"" % scenario.symptom
	sym.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sym.custom_minimum_size.x = 500
	sym.add_theme_font_size_override("font_size", 17)
	box.add_child(sym)
	var btns := []
	for c in scenario_choices():
		var b := Button.new()
		b.text = c[0]
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_on_diag_pick.bind(b, bool(c[1])))
		box.add_child(b)
		btns.append(b)
	add_tool_buttons(box, btns, scenario.diag_choices[0]) # [0.6.0 ขั้น J]
	_scen_canvas().add_child(_diag_panel)


func _on_diag_pick(b: Button, correct: bool) -> void:
	if not scenario_answer(correct):
		b.disabled = true
		return
	_diag_panel.hide()
	pib.say(dialog_dict.get("DIAGNOSIS_CORRECT", []), PibHint.Mood.HAPPY)
	_diag_advancing = true
	var go := func() -> void:
		if _diag_advancing:
			_diag_advancing = false
			_advance_phase()
	if pib.has_signal(&"all_lines_finished"):
		pib.all_lines_finished.connect(go, CONNECT_ONE_SHOT)
	get_tree().create_timer(8.0).timeout.connect(go)


## ชื่อ phase ตาม enum ของ Part (_debug_phase_name)
func _phase_name(phase: int) -> String:
	if not _phase_nodes.has(phase):
		return ""
	return String(_debug_phase_name(phase))


func _scenario_phase_changed(phase: int) -> void:
	if is_instance_valid(_skip_opt_btn):
		_skip_opt_btn.queue_free()
		_skip_opt_btn = null
	if scenario == null:
		return
	# ขั้นที่ไม่จำเป็นแต่ผู้เล่นทำจนจบ → จดไว้บอกตอนสรุป (ไม่หักคะแนน)
	if current_phase >= 0 and scenario.optional_phases.has(_phase_name(current_phase)) and phase == current_phase + 1:
		var did: Array = scenario_stats.did_optional
		if not did.has(_phase_name(current_phase)) and not (scenario_stats.skipped as Array).has(_phase_name(current_phase)):
			did.append(_phase_name(current_phase))
	if scenario.optional_phases.has(_phase_name(phase)) and _phase_nodes.has(phase + 1):
		_skip_opt_btn = Button.new()
		_skip_opt_btn.name = "SkipOptional"
		_skip_opt_btn.text = "ข้ามขั้นนี้ ►  (เคสนี้ไม่จำเป็น)"
		_skip_opt_btn.add_theme_font_size_override("font_size", 18)
		_skip_opt_btn.anchor_top = 0.0
		_skip_opt_btn.anchor_left = 0.5
		_skip_opt_btn.anchor_right = 0.5
		_skip_opt_btn.offset_left = -150
		_skip_opt_btn.offset_right = 150
		_skip_opt_btn.offset_top = 8
		_skip_opt_btn.pressed.connect(skip_optional_phase)
		_scen_canvas().add_child(_skip_opt_btn)


## ข้ามขั้นที่เคสนี้ไม่จำเป็น (จัดฉากเหมือนทำเสร็จแล้วด้วย _debug_prepare)
func skip_optional_phase() -> bool:
	if scenario == null or not scenario.optional_phases.has(_phase_name(current_phase)) or not _phase_nodes.has(current_phase + 1):
		return false
	(scenario_stats.skipped as Array).append(_phase_name(current_phase))
	debug_jump(current_phase + 1)
	return true


func scenario_report() -> Dictionary:
	if scenario == null:
		return { }
	return {
		"id": String(scenario.id), "part": String(scenario.part), "title": scenario.title,
		"cause": scenario.cause, "teach": scenario.teach, "decoy": scenario.decoy,
		"wrong": int(scenario_stats.wrong), "first_try": int(scenario_stats.wrong) == 0 and _diag_done,
		"skipped": (scenario_stats.skipped as Array).duplicate(), "did_optional": (scenario_stats.did_optional as Array).duplicate(),
		"gave_up": gave_up,
	}


func _store_scenario_report() -> void:
	var r := scenario_report()
	if r.is_empty():
		return
	set_meta("scenario_report", r)
	if has_meta("work_order") and get_meta("work_order") is CustomerCase:
		(get_meta("work_order") as CustomerCase).set_meta("scenario_report", r)


# ---------------------------------------------------------------- [0.6.0 ขั้น E] มินิเกมแบ่งครึ่ง + เลือกชิ้นจากคลัง (PLAN_0_6_0 ข้อ 4)
# จุดแบ่ง = phase แรกของครึ่งซ่อม · ถึงจุดแบ่ง → ถาม DayLoop (meta "checkpoint" = Callable คืน true = หยุด เพราะของไม่มี)
# หยุด → meta "inspection" (คะแนนที่หัก + ผลวินิจฉัย) แล้วจบแบบไม่ส่งผล · เล่นต่อ → meta "resume" = ผลครึ่งตรวจ → เริ่มที่จุดแบ่ง
# งานที่ต้องใช้อะไหล่: ถึงจุดแบ่งแล้วเลือกชิ้นจากคลังเอง (เลือกผิด = หัก tools 5 · ไม่เสียของ)

const SPLIT_AT := {
	&"part_ram": "CLEAN",
	&"part_mainboard": "CLEAN",
	&"part_gpu": "CLEAN",
	&"part_front_panel": "CONNECT",
	&"part_bios": "BOOT_ORDER",
}
## ของหลอกในถาดเลือกชิ้น (ต่อ Part) — โชว์คู่กับชิ้นที่ถูก
const PICK_DECOYS := {
	&"part_ram": [&"ram_ddr3_4gb_used", &"ram_ddr4_8gb_used", &"ram_ddr4_8gb_new"],
	&"part_mainboard": [&"mb_used", &"fan_cpu", &"paste_grey"],
	&"part_gpu": [&"fan_gpu", &"psu_450w", &"gpu_used", &"cable_hdmi"],
	&"part_front_panel": [&"fp_switch", &"cable_sata", &"cable_tie"],
	&"part_bios": [&"cmos_cr2032", &"cable_sata", &"ram_ddr4_8gb_used"],
}
const TOOLS_PICK_WRONG := 5

var _checkpoint_done := false
var _resumed := false
var _pick_layer: Control
var inspection_stopped := false


func split_phase() -> int:
	var name: String = SPLIT_AT.get(part_key(), "")
	for ph in _phase_nodes:
		if _phase_name(ph) == name:
			return ph
	return -1


func _start_phase() -> int:
	if has_meta("resume") and scenario and split_phase() >= 0:
		var r: Dictionary = get_meta("resume")
		_resumed = true
		_checkpoint_done = true
		_diag_done = true
		for k in r.get("mistakes", { }):
			_mistakes[StringName(k)] = int(r.mistakes[k])
		scenario_stats["wrong"] = int(r.get("wrong", 0))
		scenario_stats["skipped"] = (r.get("skipped", []) as Array).duplicate()
		scenario_stats["did_optional"] = (r.get("did_optional", []) as Array).duplicate()
		_debug_prepare(split_phase())
		_open_pick_if_needed.call_deferred()
		_build_hint_button.call_deferred()
		return split_phase()
	_build_hint_button.call_deferred()
	return _first_phase()


## ถึงจุดแบ่งครั้งแรก → ถาม DayLoop · คืน true = หยุดมินิเกมไว้แค่นี้ (ครึ่งตรวจ)
func _checkpoint_stops(phase: int) -> bool:
	if _checkpoint_done or scenario == null or phase != split_phase() or phase < 0:
		return false
	_checkpoint_done = true
	var stop := false
	if has_meta("checkpoint") and get_meta("checkpoint") is Callable:
		stop = bool((get_meta("checkpoint") as Callable).call())
	if stop:
		_end_inspection()
		return true
	_open_pick_if_needed.call_deferred()
	return false


func inspection_data() -> Dictionary:
	var m := { }
	for k in _mistakes:
		m[String(k)] = int(_mistakes[k])
	return { "mistakes": m, "wrong": int(scenario_stats.wrong), "skipped": (scenario_stats.skipped as Array).duplicate(), "did_optional": (scenario_stats.did_optional as Array).duplicate(), "cause": scenario.cause if scenario else "" }


## จบครึ่งตรวจ: เก็บผลไว้ · ไม่ส่งคะแนน/เงิน (DayLoop อ่าน meta "inspection" ตอนมินิเกมปิด)
func _end_inspection() -> void:
	if _finished:
		return
	inspection_stopped = true
	var d := inspection_data()
	set_meta("inspection", d)
	if has_meta("work_order") and get_meta("work_order") is CustomerCase:
		(get_meta("work_order") as CustomerCase).set_meta("inspection", d)
	if _phase_nodes.has(current_phase):
		_phase_nodes[current_phase].abort()
	_finished = true
	minigame_finished.emit(_mistakes)


## รายการในถาดเลือกชิ้น [[ItemDef, ถูกไหม]…] (สลับลำดับ) · ว่าง = งานนี้ไม่ใช้อะไหล่
func pick_options() -> Array:
	var out := []
	if scenario == null or scenario.needs_part == &"":
		return out
	var good: Array[StringName] = [scenario.needs_part]
	good.append_array(scenario.part_alternatives)
	var shown := { }
	var add := func(id: StringName, ok: bool) -> void:
		if shown.has(id):
			return
		var path := "res://Resources/Shop/%s.tres" % id
		if not ResourceLoader.exists(path):
			return
		shown[id] = true
		out.append([load(path), ok])
	add.call(scenario.needs_part, true)
	for id in PICK_DECOYS.get(part_key(), []):
		if out.size() >= 3:
			break
		if not good.has(id):
			add.call(id, false)
	out.shuffle()
	return out


func _open_pick_if_needed() -> void:
	var opts := pick_options()
	if opts.is_empty() or not is_inside_tree():
		return
	_pick_layer = Control.new()
	_pick_layer.name = "PartPick"
	_pick_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pick_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pick_layer.add_child(dim)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = 70
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.1, 0.08, 0.96)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(16)
	sb.border_color = Color(0.45, 0.75, 0.5)
	sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var t := Label.new()
	t.text = "หยิบชิ้นใหม่จากคลัง"
	t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", Color(0.55, 0.85, 0.6))
	box.add_child(t)
	var sub := Label.new()
	sub.text = "สาเหตุ: %s\nเลือกชิ้นที่ต้องใช้กับเครื่องนี้" % scenario.cause
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size.x = 560
	sub.add_theme_font_size_override("font_size", 17)
	box.add_child(sub)
	for o in opts:
		var it: ItemDef = o[0]
		var b := Button.new()
		b.text = ("%s %s" % [it.emoji, it.display_name]).strip_edges()
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_on_pick.bind(b, bool(o[1]), it))
		box.add_child(b)
	_pick_layer.add_child(panel)
	_scen_canvas().add_child(_pick_layer)


func _on_pick(b: Button, ok: bool, it: ItemDef) -> void:
	if not ok:
		b.disabled = true
		_on_mistake(&"tools", TOOLS_PICK_WRONG)
		var why := scenario.part_hint if scenario.part_hint != "" else "ชิ้นนี้ไม่ใช่สำหรับเครื่องนี้"
		pib.say([DialogToken.new(PibHint.DEFAULT_SPEAKER, "%s ไม่ใช่ชิ้นที่เครื่องนี้ต้องการนะ" % it.display_name), DialogToken.new(PibHint.DEFAULT_SPEAKER, why)], PibHint.Mood.NORMAL)
		return
	pib.say([DialogToken.new(PibHint.DEFAULT_SPEAKER, "ใช่ %s นี่แหละ เอามาใส่แทนชิ้นเดิมกัน" % it.display_name)], PibHint.Mood.HAPPY)
	if is_instance_valid(_pick_layer):
		_pick_layer.queue_free()
	_pick_layer = null


# ---------------------------------------------------------------- [0.6.0 ขั้น J] ไกด์ตามยศ + เครื่องมือวินิจฉัย (PLAN_0_6_0 ข้อ 7)

## กด "ขอคำใบ้" แล้ว (ยศเชี่ยวชาญขึ้นไป) → ไกด์กลับมา · ไม่ได้โบนัสทำเอง
var hint_requested := false
var _hint_btn: Button
## เครื่องมือที่ใช้ในการวินิจฉัยครั้งนี้แล้ว
var tools_used: Array[StringName] = []


func _gs() -> Node:
	return get_node_or_null(^"/root/GameState")


## ยศเชี่ยวชาญขึ้นไป · งานลูกค้า · ไม่ขอคำใบ้ → คะแนน +self_bonus
func self_bonus() -> int:
	var gs := _gs()
	if gs == null or not has_meta("work_order") or hint_requested or gs.rank_level < gs.economy.guide_hint_rank:
		return 0
	return int(gs.economy.self_bonus)


func _build_hint_button() -> void:
	var gs := _gs()
	if gs == null or not has_meta("work_order") or gs.rank_level < gs.economy.guide_hint_rank or not is_inside_tree():
		return
	_hint_btn = Button.new()
	_hint_btn.name = "AskHint"
	_hint_btn.text = "💡 ขอคำใบ้"
	_hint_btn.tooltip_text = "ไกด์ (วงกลมชี้) จะกลับมา · ไม่ได้โบนัสทำเอง +%d" % int(gs.economy.self_bonus)
	_hint_btn.add_theme_font_size_override("font_size", 17)
	_hint_btn.anchor_left = 1.0
	_hint_btn.anchor_right = 1.0
	_hint_btn.offset_left = -330
	_hint_btn.offset_right = -180
	_hint_btn.offset_top = 8
	_hint_btn.pressed.connect(request_hint)
	_scen_canvas().add_child(_hint_btn)


func request_hint() -> void:
	if hint_requested:
		return
	hint_requested = true
	if is_instance_valid(_hint_btn):
		_hint_btn.disabled = true
		_hint_btn.text = "💡 เปิดคำใบ้แล้ว"
	if is_instance_valid(pib):
		pib.say([DialogToken.new(PibHint.DEFAULT_SPEAKER, "ได้เลย ทำขั้นต่อไปเดี๋ยวปิ๊บชี้ให้")], PibHint.Mood.NORMAL)


## เครื่องมือที่ใช้กับสถานการณ์นี้ได้ [[id, ชื่อ, เบาะแส]…] (มีเครื่องมือ + สถานการณ์มีเบาะแสของเครื่องมือนั้น)
func diag_tools() -> Array:
	var out := []
	var gs := _gs()
	if scenario == null or gs == null:
		return out
	for pair in [[&"multimeter", "meter"], [&"post_card", "post"]]:
		var clue := String(scenario.flags.get(pair[1], ""))
		if clue != "" and gs.has_tool(pair[0]):
			out.append([pair[0], EconomyConfig.TOOL_NAMES.get(pair[0], ""), clue])
	return out


## ใส่ปุ่มเครื่องมือใต้ตัวเลือกวินิจฉัย · กด = ปิ๊บบอกเบาะแส + ปิดตัวเลือกผิด 1 ข้อ (correct_text = ข้อที่ถูก)
func add_tool_buttons(parent: Control, choice_buttons: Array, correct_text: String) -> void:
	for t in diag_tools():
		var b := Button.new()
		b.name = "Tool_%s" % t[0]
		b.text = "🔧 ใช้%s" % t[1]
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(use_diag_tool.bind(t[0], String(t[2]), b, choice_buttons, correct_text))
		parent.add_child(b)


func use_diag_tool(id: StringName, clue: String, btn: Button, choice_buttons: Array, correct_text: String) -> void:
	if tools_used.has(id):
		return
	tools_used.append(id)
	if is_instance_valid(btn):
		btn.disabled = true
	for b in choice_buttons:
		if is_instance_valid(b) and b is Button and not (b as Button).disabled and (b as Button).text != correct_text:
			(b as Button).disabled = true
			(b as Button).text = "✗ " + (b as Button).text
			break
	if is_instance_valid(pib):
		pib.say([DialogToken.new(PibHint.DEFAULT_SPEAKER, clue)], PibHint.Mood.NORMAL)


# ---------------------------------------------------------------- [0.6.0 ขั้น K] ความสามารถที่แก้มินิเกม (PLAN_0_6_0 ข้อ 8)

## ตาไว: จุดที่ phase แรกให้คลิก (stage.allowed) กะพริบ 1 ครั้ง · นักสืบ: ปิ๊บเตือนจุดหลอก + เล่าความลับของลูกค้า
var sharp_eye_flashed: Array = []
var detective_said := false


func _perk_first_phase(phase: int) -> void:
	var gs := _gs()
	if gs == null or not has_meta("work_order") or current_phase != phase:
		return
	if gs.has_perk(&"sharp_eye"):
		_sharp_eye_flash(phase)
	if gs.has_perk(&"detective") and scenario and not detective_said:
		detective_said = true
		var lines := []
		if scenario.secret != "":
			lines.append(DialogToken.new(PibHint.DEFAULT_SPEAKER, "ลูกค้าเล่าเพิ่มเองว่า %s" % scenario.secret))
		if scenario.decoy != "":
			lines.append(DialogToken.new(PibHint.DEFAULT_SPEAKER, "ระวังนะ %s" % scenario.decoy))
		if not lines.is_empty() and is_instance_valid(pib):
			pib.say(lines, PibHint.Mood.NORMAL)


func _sharp_eye_flash(phase: int) -> void:
	var ph = _phase_nodes.get(phase)
	if ph == null or not ph.has_method(&"stage"):
		return
	var st = ph.stage()
	if st == null or not ("allowed" in st):
		return
	sharp_eye_flashed.clear()
	for it in st.allowed:
		if is_instance_valid(it) and it is Item2D:
			(it as Item2D).tint(Color(1, 0.9, 0.35))
			sharp_eye_flashed.append(it)
	await get_tree().create_timer(0.9).timeout
	for it in sharp_eye_flashed:
		if is_instance_valid(it):
			(it as Item2D).clear_tint()
