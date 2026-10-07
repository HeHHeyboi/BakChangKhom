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
## QTE กลางของมินิเกม — phase เรียก: var r = await owner.qte.run(SPEC, node("ชิ้นงาน"), owner.qte_zone_scale())
var qte: QteRunner
## มีปุ่ม "ข้ามบทฝึก" มุมขวาบน (กด 2 ครั้งยืนยัน) — ใช้กับ Tutorial / งานในเควสต์ · งานลูกค้า (meta work_order) ข้ามไม่ได้เสมอ
@export var skippable := false
var _skip_btn: Button
var _skip_armed := false
## จบมินิเกมไปแล้ว (กันส่ง minigame_finished ซ้ำ → เควสต์เดิน 2 ขั้น / เงินเข้า 2 ครั้ง)
var _finished := false


func _ready() -> void:
	EventManager.hideUI()
	Global.cur_pib = pib
	dialog_dict = PhaseDialogParser.parse(dialog_path)
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
	if skippable and not has_meta("work_order"):
		_build_skip()
	_set_phase(_first_phase())
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
	for p in _phase_nodes:
		if p == phase:
			_phase_nodes[p].visible = true
			_phase_nodes[p].init()
			current_phase = p
		else:
			_phase_nodes[p].visible = false

	phase_changed.emit(phase)


func _advance_phase() -> void:
	if _finished:
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


func _exit_tree() -> void:
	if qte:
		qte.cancel()


## ครั้งแรกที่ซ่อม Part นี้ผ่าน (ยังไม่เคยผ่าน) โซน QTE กว้าง 1.5 เท่า · Docs/CORE_PART_QTE.md ข้อ 1
func qte_zone_scale() -> float:
	var gs := get_node_or_null(^"/root/GameState")
	var id := part_id if part_id != &"" else StringName(scene_file_path.get_file().get_basename())
	if gs and gs.has_cleared(id):
		return 1.0
	return 1.5


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
	var order = get_meta("work_order")
	if order is CustomerCase:
		fee = order.fee
		if order.part_id != String(id):
			push_warning("%s: งานลูกค้า %s เป็น %s แต่มินิเกมนี้คือ %s" % [name, order.id, order.part_id, id])
	gs.record_repair(id, final_score(), repair_damaged(), fee)


## คะแนน 0–100 จาก phase สุดท้าย (SUMMARY มี var total) · ไม่มี = คิดจาก _mistakes
func final_score() -> int:
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
