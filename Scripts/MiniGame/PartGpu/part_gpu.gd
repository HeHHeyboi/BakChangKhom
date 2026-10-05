class_name PartGpu extends PartMinigame
## มินิเกม Core Part: GPU + Cable Management — การ์ดจอไม่ได้ต่อไฟ จอไม่ขึ้น (Docs/PART_GPU_DESIGN.md)
## ฉาก 2D ใน Scene/MiniGame/PartGpu/part_gpu.tscn → Stage/Views/<มุม>
##   ภาพรวมร้าน · โต๊ะคอม · ท้ายเคส (Rear) · ในเคสมองด้านข้าง (Case) · แผ่น ESD (Mat)
## phase อยู่ใน Scripts/MiniGame/PartGpu/ (extends Phase2D) · บทปิ๊บ Assets/Dialog/MiniGame/Gpu_Pib.txt
## [Claude 2 ต.ค. 2569]

enum PhaseState {
	NONE,
	INSPECT, # 1 ดู 3 จุด: สาย HDMI ท้ายเคส · ไฟบนการ์ด · หัว 8-pin ห้อยว่าง
	BRIEFING, # 2 ปิ๊บสอน PCIe + ไฟเลี้ยงการ์ด
	SAFETY, # 3 ปิดเครื่อง → ถอดปลั๊ก → แตะเคส
	REMOVE, # 4 ไขน็อตท้ายเคส → กดสลัก → ดึงการ์ด
	CLEAN, # 5 ใบพัด · ครีบ · ขาทอง (ล็อกใบพัดก่อนเป่า)
	INSTALL, # 6 วางการ์ด → กดจนสลักดีด → ขันน็อตท้ายเคส
	POWER, # 7 เลือกหัวสายไฟให้ถูก → ดันจนคลิก
	AIRFLOW, # 8 จัดสาย · ทิศพัดลม · ย้าย HDMI → เปิดเครื่องทดสอบ
	SUMMARY, # 9 สรุป
}

enum Fan { FRONT, REAR, TOP }
const PIB_PATH = "res://Assets/Dialog/MiniGame/Gpu_Pib.txt"
## ทิศที่ถูก: true = เป่าเข้า (intake)
const FAN_OK := { Fan.FRONT: true, Fan.REAR: false, Fan.TOP: false }
## มุมหมุนลูกศร (รูปลูกศรชี้ขวา) — หน้าเคสอยู่ขวาของภาพ
const FAN_ROT := {
	Fan.FRONT: { true: 180.0, false: 0.0 },
	Fan.REAR: { true: 0.0, false: 180.0 },
	Fan.TOP: { true: 90.0, false: -90.0 },
}
const GPU_SLOT_POS := Vector2(290, 140)
const HDMI_MB_POS := Vector2(391, 114) # เสียบช่อง HDMI ของเมนบอร์ด (มุม Rear)
const HDMI_GPU_POS := Vector2(415, 244) # เสียบช่อง HDMI ของการ์ดจอ

@export var start_phase: PhaseState

@onready var stage: Stage2D = %Stage

var plugged := true
var cable_locked := false
var cable_molex := false
var slot_damaged := false
var card_burnt := false
var fan_intake := { Fan.FRONT: false, Fan.REAR: true, Fan.TOP: false }
var temp_result := 0.0


func _ready() -> void:
	_mistakes = { &"inspect": 0, &"safety": 0, &"remove": 0, &"clean": 0, &"power": 0, &"airflow": 0 }
	if dialog_path.is_empty():
		dialog_path = PIB_PATH
	minigame_finished.connect(_on_minigame_finished)
	_setup()
	super._ready()


## สภาพเครื่องตอนรับมา: การ์ดในสล็อต (ไม่มีไฟ) · หัว 8-pin ห้อย · HDMI เสียบเมนบอร์ด · สายรก · พัดลมหลังกลับทิศ
func _setup() -> void:
	(%GpuSide as Item2D).set_state("")
	(%GpuSide as Control).position = GPU_SLOT_POS
	(%GpuSide as Item2D).clear_tint()
	(%GpuLed as Item2D).set_state("off")
	(%Latch as Item2D).set_state("")
	(%LooseCable as Item2D).set_state("")
	(%PluggedCable as Item2D).set_state("off")
	(%GpuCard as Item2D).set_state("off")
	(%BracketScrew as Item2D).set_state("")
	var h := %HdmiCable as Item2D
	h.set_state("")
	h.position = HDMI_MB_POS
	h.set_meta("gpu_pos", HDMI_GPU_POS)
	h.remove_meta("on_gpu")
	(%PowerCord as Item2D).set_state("")
	(%Monitor as Item2D).set_state("desktop")
	(%TidyBundle as Item2D).set_state("off")
	for m in ["Mess1", "Mess2", "Mess3"]:
		(get_node("%" + m) as Item2D).set_state("")
	(%TempLabel as Label).hide()
	set_led(true)
	apply_fans()


func set_led(on: bool) -> void:
	(%PowerLed as Item2D).set_state("on" if on else "off")


func fan_node(f: Fan) -> Item2D:
	return get_node("%" + ["FanFront", "FanRear", "FanTop"][f]) as Item2D


func apply_fans(animate := false) -> void:
	for f in fan_intake:
		var n := fan_node(f)
		var to: float = FAN_ROT[f][fan_intake[f]]
		if animate:
			create_tween().tween_property(n, "rotation_degrees", to, 0.2)
		else:
			n.rotation_degrees = to


func fans_wrong() -> int:
	var w := 0
	for f in FAN_OK:
		if fan_intake[f] != FAN_OK[f]:
			w += 1
	return w


## VERIFY พบว่าหัวสายยังไม่คลิก → กลับไปขั้นเสียบสายใหม่
func return_to_power() -> void:
	if _phase_nodes.has(current_phase):
		_phase_nodes[current_phase].abort()
	_set_phase(PhaseState.POWER)


# override PartMinigame._register_phases
func _register_phases() -> Dictionary:
	return {
		PhaseState.INSPECT: $PhaseInspect as Phase,
		PhaseState.BRIEFING: $PhaseBriefing as Phase,
		PhaseState.SAFETY: $PhaseSafety as Phase,
		PhaseState.REMOVE: $PhaseRemove as Phase,
		PhaseState.CLEAN: $PhaseClean as Phase,
		PhaseState.INSTALL: $PhaseInstall as Phase,
		PhaseState.POWER: $PhasePower as Phase,
		PhaseState.AIRFLOW: $PhaseAirflow as Phase,
		PhaseState.SUMMARY: $PhaseSummary as Phase,
	}


func _first_phase() -> int:
	if start_phase != PhaseState.NONE:
		return start_phase
	return PhaseState.INSPECT


func _last_phase() -> int:
	return PhaseState.SUMMARY


func _debug_phase_name(phase: int) -> String:
	return PhaseState.find_key(phase)


## จัดฉากให้เหมือนเล่นมาถึงก่อน phase นี้
func _debug_prepare(phase: int) -> void:
	_setup()
	var off := phase > PhaseState.SAFETY and phase < PhaseState.SUMMARY
	plugged = not off
	(%PowerCord as Item2D).set_state("out" if off else "")
	(%Monitor as Item2D).set_state("off" if off else "desktop")
	set_led(not off)
	var on_mat := phase == PhaseState.CLEAN or phase == PhaseState.INSTALL
	(%GpuSide as Item2D).set_state("off" if on_mat else "")
	(%BracketScrew as Item2D).set_state("off" if on_mat else "")
	(%Latch as Item2D).set_state("open" if on_mat else "")
	(%GpuCard as Item2D).set_state(("clean" if phase == PhaseState.INSTALL else "dusty") if on_mat else "off")


## ของเสียระหว่างซ่อม → GameState หักเงิน
func repair_damaged() -> bool:
	return card_burnt or slot_damaged


func _on_minigame_finished(_score: Dictionary) -> void:
	Global.in_minigame = false
	Global.cur_pib = null
	if has_meta("standalone"):
		EventManager.showUI()
	else:
		EventManager.minigame_end()
	call_deferred("queue_free")
