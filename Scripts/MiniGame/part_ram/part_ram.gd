class_name PartRam extends Node2D
@export var pib: PibHint

enum PhaseState {
	NONE,
	DIAGNOSIS, # 1 สังเกตอาการ + เลือกสาเหตุ
	BRIEFING, # 0 ปิ๊บสอน
	POWER_OFF, # 2 ปิดเครื่อง/ถอดปลั๊ก/แตะเคส
	REMOVE, # 3 ปลดสลัก + ดึงแรม
	CLEAN, # 4 ขัด (กลไกเดิม)
	INSTALL, # 5 ใส่กลับ
	VERIFY, # 6 เปิดเครื่องตรวจผล
	SUMMARY, # 7 สรุป + คะแนน
}

signal phase_changed(phase: PhaseState)
signal minigame_finished(score: Dictionary)

var current_phase: PhaseState = PhaseState.DIAGNOSIS
var _mistakes := { "diagnosis": 0, "safety": 0, "handling": 0 }
var dialog_dict: Dictionary

@export var RAM_PIB_PATH = "res://Assets/Dialog/MiniGame/Ram_Pib.txt"
@export var start_phase: PhaseState
@onready var _phase_nodes: Dictionary = {
	PhaseState.DIAGNOSIS: $PhaseDiagnosis as Phase,
	PhaseState.BRIEFING: $PhaseBriefing as Phase,
	PhaseState.POWER_OFF: $PhasePoweroff as Phase,
	#PhaseState.REMOVE: $PhaseRemove,
	#PhaseState.CLEAN: $PhaseClean,
	#PhaseState.INSTALL: $PhaseInstall,
	#PhaseState.VERIFY: $PhaseVerify,
	#PhaseState.SUMMARY: $PhaseSummary,
}


func _ready() -> void:
	EventManager.hideUI()
	Global.cur_pib = pib
	dialog_dict = PhaseDialogParser.parse(RAM_PIB_PATH)
	if pib == null:
		push_error("Pib is null please assign")
		return

	for phase in _phase_nodes:
		_phase_nodes[phase].phase_completed.connect(_advance_phase)
		_phase_nodes[phase].pib_toggle.connect(self.pib_toggle)

	#pib.say(dialog_dict["REMOVE"])
	#_set_phase(PhaseState.DIAGNOSIS)
	if start_phase != PhaseState.NONE:
		_set_phase(start_phase)
	else:
		_set_phase(PhaseState.DIAGNOSIS)


func _set_phase(phase: PhaseState) -> void:
	for p in _phase_nodes:
		if p == phase:
			_phase_nodes[p].visible = true
			_phase_nodes[p].init()
			current_phase = p
		else:
			_phase_nodes[p].visible = false

	phase_changed.emit(phase)


func _advance_phase() -> void:
	if current_phase == PhaseState.SUMMARY:
		minigame_finished.emit(_mistakes)
		return
	_set_phase(current_phase + 1 as PhaseState)


func pib_toggle(data: PibHint.Data):
	match data.type:
		data.Act.SAY:
			var lines = dialog_dict[data.header]
			if lines != null:
				pib.say(lines, data.mood)
			else:
				push_error("There is no header %s" % data.header)
		data.Act.TOAST:
			if !dialog_dict.has(data.header):
				push_error("There is no header %s" % data.header)
				return
			var dialog = dialog_dict[data.header][0]
			pib.toast(dialog, data.seconds)
