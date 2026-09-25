class_name PartRam extends Node2D
@export var pib: PibHint

enum Phase {
	DIAGNOSIS, # 0 สังเกตอาการ + เลือกสาเหตุ
	BRIEFING, # 1 ปิ๊บสอน
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

@onready var _phase_nodes: Dictionary = {
	Phase.DIAGNOSIS: $PhaseDiagnosis,
	#Phase.BRIEFING: $PhaseBriefing,
	#Phase.POWER_OFF: $PhasePoweroff,
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

	pib.say(dialog_dict["REMOVE"])
	_set_phase(Phase.DIAGNOSIS)


func _set_phase(phase: Phase) -> void:
	_phase_nodes[current_phase].visible = false
	# for p in _phase_nodes:
	# 	_phase_nodes[p].visible = (p == phase)
	current_phase = phase
	if current_phase >= _phase_nodes.size():
		return
	_phase_nodes[current_phase].visible = true
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
