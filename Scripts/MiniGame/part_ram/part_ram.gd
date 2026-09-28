class_name PartRam extends Node2D
@export var pib: PibHint

enum Phase {
	NONE,
	BRIEFING, # 0 ปิ๊บสอน
	DIAGNOSIS, # 1 สังเกตอาการ + เลือกสาเหตุ
	POWER_OFF, # 2 ปิดเครื่อง/ถอดปลั๊ก/แตะเคส
	REMOVE, # 3 ปลดสลัก + ดึงแรม
	CLEAN, # 4 ขัด (กลไกเดิม)
	INSTALL, # 5 ใส่กลับ
	VERIFY, # 6 เปิดเครื่องตรวจผล
	SUMMARY, # 7 สรุป + คะแนน
}

signal phase_changed(phase: Phase)
signal minigame_finished(score: Dictionary)

var current_phase: Phase = Phase.DIAGNOSIS
var _mistakes := { "diagnosis": 0, "safety": 0, "handling": 0 }
var dialog_dict: Dictionary

@export var RAM_PIB_PATH = "res://Assets/Dialog/MiniGame/Ram_Pib.txt"
@export var start_phase: Phase
@onready var _phase_nodes: Dictionary = {
	Phase.DIAGNOSIS: $PhaseDiagnosis as PhaseDiagnosis,
	Phase.POWER_OFF: $PhasePoweroff as PhasePoweroff,
	#Phase.BRIEFING: $PhaseBriefing,
	#Phase.REMOVE: $PhaseRemove,
	#Phase.CLEAN: $PhaseClean,
	#Phase.INSTALL: $PhaseInstall,
	#Phase.VERIFY: $PhaseVerify,
	#Phase.SUMMARY: $PhaseSummary,
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
	#_set_phase(Phase.DIAGNOSIS)
	if start_phase != Phase.NONE:
		_set_phase(start_phase)
	else:
		_set_phase(Phase.DIAGNOSIS)


func _set_phase(phase: Phase) -> void:
	for p in _phase_nodes:
		_phase_nodes[p].visible = (p == phase)
	phase_changed.emit(phase)


func _advance_phase() -> void:
	if current_phase == Phase.SUMMARY:
		minigame_finished.emit(_mistakes)
		return
	_set_phase(current_phase + 1 as Phase)


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
