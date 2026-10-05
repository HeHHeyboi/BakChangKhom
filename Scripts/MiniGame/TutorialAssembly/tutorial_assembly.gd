class_name TutorialAssembly extends PartMinigame
## มินิเกม Tutorial ประกอบคอมเบื้องต้น — สอนว่าในคอมมีชิ้นอะไรบ้าง แต่ละชิ้นจะได้ซ่อมใน Part ไหน
## ฉาก: Scene/MiniGame/TutorialAssembly/tutorial_assembly.tscn (สืบทอด part_base + Stage + WorkshopRoom)
## ดีไซน์: Docs/TUTORIAL_ASSEMBLY_DESIGN.md · โค้ดทดลอง 2D ของเดิม (Test/assembly.tscn, part.gd, place.gd) ไม่ได้แก้
## [Claude 30 ก.ย. 2569]

enum PhaseState {
	NONE,
	INTRO, # 1 คลิกรู้จักชิ้นส่วน 7 ชิ้น (การ์ดชื่อ · หน้าที่ · จะได้ซ่อมใน Part ไหน)
	BUILD, # 2 ลากชิ้นลงเคสตามลำดับ (ข้อมูลจาก PcPart.requires / socket_type)
	POWER_TEST, # 3 กดปุ่มเปิดเครื่อง → จอขึ้น
	SUMMARY, # 4 สรุปชิ้นส่วน ↔ Part ที่จะได้ซ่อม
}

const PIB_PATH := "res://Assets/Dialog/MiniGame/Assembly_Pib.txt"
## PcPart.core_part → ชื่อ Part ที่จะได้ซ่อม (โชว์บนการ์ด/หน้าสรุป)
const CORE_NAME := {
	&"ram": "Part RAM · ขัดแรม",
	&"mainboard": "Part Mainboard · ซีพียูและเมนบอร์ด",
	&"gpu": "Part GPU · การ์ดจอและสายไฟ",
	&"front_panel": "Part Front Panel · สายหน้าเคส",
	&"bios": "Part BIOS · ตั้งค่าและลงระบบ",
}
const TEX_BOOT_OK := preload("res://Assets/MiniGame/PartRam/ram_tex_screen_boot_ok.png")

@export var start_phase: PhaseState

@onready var stage: Stage2D = %Stage


func _ready() -> void:
	if dialog_path.is_empty():
		dialog_path = PIB_PATH
	minigame_finished.connect(_on_minigame_finished)
	skippable = true # [Claude 5 ต.ค. 2569] ข้ามได้ตอนเป็น Tutorial/เควสต์ · งานลูกค้าข้ามไม่ได้ (PartMinigame เช็ก work_order)
	super._ready()


## ชิ้นส่วนทั้งหมดบนแผ่นรอง (ลูกของ node Parts) เรียงตามลำดับประกอบ
func parts() -> Array[Item2D]:
	var a: Array[Item2D] = []
	for n in %Parts.get_children() + _installed_parts():
		if n is Item2D:
			a.append(n)
	return a


## ชิ้นที่ประกอบลงเคสแล้ว (ย้ายออกจาก Parts ไปอยู่ในมุม Build) — เรียงตามลำดับเดิมด้วย _order
var _order: Array[Item2D] = []


func _installed_parts() -> Array:
	return []


func core_name(p: PcPart) -> String:
	return "จะได้ซ่อมใน " + String(CORE_NAME.get(p.core_part, "งานซ่อมทั่วไป"))

# override PartMinigame._register_phases
func _register_phases() -> Dictionary:
	return {
		PhaseState.INTRO: $PhaseIntro as Phase,
		PhaseState.BUILD: $PhaseBuild as Phase,
		PhaseState.POWER_TEST: $PhasePower as Phase,
		PhaseState.SUMMARY: $PhaseSummary as Phase,
	}

# override PartMinigame._first_phase
func _first_phase() -> int:
	return start_phase if start_phase != PhaseState.NONE else PhaseState.INTRO

# override PartMinigame._last_phase
func _last_phase() -> int:
	return PhaseState.SUMMARY

## override Phase._debug_phase_name
func _debug_phase_name(phase: int) -> String:
	return PhaseState.find_key(phase)


## override PartMinigame._debug_prepare
## ก่อนถึง POWER_TEST / SUMMARY ต้องประกอบครบแล้ว → ใส่ทุกชิ้นลงซ็อกเก็ตให้เลย (ชิ้นที่ใส่แล้วข้ามไป)
func _debug_prepare(phase: int) -> void:
	if phase < PhaseState.POWER_TEST:
		return
	for p in parts():
		if p.socket != null and not p.socket.accept_any:
			continue
		for s in stage.sockets:
			if s.socket_type == p.data.socket_type and s.occupant == null:
				stage.install(p, s, false, false)
				p.mode = Item2D.Mode.STATIC
				break


func _on_minigame_finished(_score: Dictionary) -> void:
	Global.in_minigame = false
	Global.cur_pib = null
	EventManager.minigame_end()
	call_deferred("queue_free")
