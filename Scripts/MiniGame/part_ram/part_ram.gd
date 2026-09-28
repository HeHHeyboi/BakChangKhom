class_name PartRam extends PartMinigame
## มินิเกม Part RAM — ระบบ phase / PibHint / Background มาจาก PartMinigame + part_base.tscn

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

const RAM_PIB_PATH = "res://Assets/Dialog/MiniGame/Ram_Pib.txt"

@export var start_phase: PhaseState

# [Claude 29 ก.ย.] สถานะที่ส่งข้าม phase — CLEAN เขียน ram_damaged · INSTALL เขียน ram_seated · VERIFY อ่านทั้งคู่
var ram_damaged := false
var ram_seated := true


func _ready() -> void:
	# คะแนนที่ถูกหักต่อหมวด (MINIGAME1_DESIGN.md หัวข้อ 9) — เต็ม 30 / 25 / 25 / 10 / 10
	_mistakes = { &"diagnosis": 0, &"safety": 0, &"tools": 0, &"handling": 0, &"tidiness": 0 }
	if dialog_path.is_empty():
		dialog_path = RAM_PIB_PATH
	# [Claude 29 ก.ย.] จบมินิเกม → เดินเควสต์ต่อแล้วปิดซีน (แบบเดียวกับ find_item_minigame.gd)
	minigame_finished.connect(_on_minigame_finished)
	super._ready()


func _register_phases() -> Dictionary:
	return {
		PhaseState.DIAGNOSIS: $PhaseDiagnosis as Phase,
		PhaseState.BRIEFING: $PhaseBriefing as Phase,
		PhaseState.POWER_OFF: $PhasePoweroff as Phase,
		# [Claude 29 ก.ย.] เปิดใช้ phase 3–7 (UI เบื้องต้นตาม storyboard)
		PhaseState.REMOVE: $PhaseRemove as Phase,
		PhaseState.CLEAN: $PhaseClean as Phase,
		PhaseState.INSTALL: $PhaseInstall as Phase,
		PhaseState.VERIFY: $PhaseVerify as Phase,
		PhaseState.SUMMARY: $PhaseSummary as Phase,
	}


func _first_phase() -> int:
	if start_phase != PhaseState.NONE:
		return start_phase
	return PhaseState.DIAGNOSIS


func _last_phase() -> int:
	return PhaseState.SUMMARY


# [Claude 29 ก.ย.]
func _on_minigame_finished(_score: Dictionary) -> void:
	Global.in_minigame = false
	Global.cur_pib = null
	EventManager.minigame_end()
	call_deferred("queue_free")
