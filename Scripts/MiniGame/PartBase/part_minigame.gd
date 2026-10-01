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

var current_phase: int = -1
var dialog_dict: Dictionary
var _mistakes: Dictionary = { }
var _phase_nodes: Dictionary = { }


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
	if current_phase == _last_phase():
		print("last phase")
		minigame_finished.emit(_mistakes)
		return
	_set_phase(current_phase + 1)


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
		b.pressed.connect(func():
			debug_jump(ph)
			_debug_layer.visible = false
		)
		box.add_child(b)


func _unhandled_input(event: InputEvent) -> void:
	if _debug_layer and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == DEBUG_TOGGLE_KEY:
		_debug_layer.visible = not _debug_layer.visible
		get_viewport().set_input_as_handled()
