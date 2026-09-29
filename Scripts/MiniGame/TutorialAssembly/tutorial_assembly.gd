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

@onready var stage: PartStage3D = %Stage


func _ready() -> void:
	if dialog_path.is_empty():
		dialog_path = PIB_PATH
	minigame_finished.connect(_on_minigame_finished)
	super._ready()


## ชิ้นส่วนทั้งหมดบนแผ่นรอง (ลูกของ node Parts) เรียงตามลำดับประกอบ
func parts() -> Array[PartBody3D]:
	var a: Array[PartBody3D] = []
	for n in %Parts.get_children():
		if n is PartBody3D:
			a.append(n)
	return a


func core_name(p: PcPart) -> String:
	return "จะได้ซ่อมใน " + String(CORE_NAME.get(p.core_part, "งานซ่อมทั่วไป"))


func _register_phases() -> Dictionary:
	return {
		PhaseState.INTRO: $PhaseIntro as Phase,
		PhaseState.BUILD: $PhaseBuild as Phase,
		PhaseState.POWER_TEST: $PhasePower as Phase,
		PhaseState.SUMMARY: $PhaseSummary as Phase,
	}


func _first_phase() -> int:
	return start_phase if start_phase != PhaseState.NONE else PhaseState.INTRO


func _last_phase() -> int:
	return PhaseState.SUMMARY


func _on_minigame_finished(_score: Dictionary) -> void:
	Global.in_minigame = false
	Global.cur_pib = null
	EventManager.minigame_end()
	call_deferred("queue_free")
