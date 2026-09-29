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
