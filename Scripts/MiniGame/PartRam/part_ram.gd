class_name PartRam extends PartMinigame
## มินิเกม Part RAM (2.5D) — ระบบ phase / PibHint มาจาก PartMinigame + part_base.tscn
## ฉาก 2D ทั้งหมดเป็น node ใน part_ram.tscn → Stage/Views/<มุม> (ภาพรวมร้าน · โต๊ะคอม · ปลั๊กพ่วง · ในเคส 2.5D · สล็อตแรม · แผ่น ESD) (เคส · จอ · แผ่น ESD · มุมกล้อง Views)
## phase แต่ละตัวอยู่ใน Scripts/MiniGame/PartRam/ และ extends Phase2D · ดู Docs/RAM_3D_GAMEPLAY.md
## [Claude 29 ก.ย. 2569] ย้ายจาก 2D เป็น 2.5D · [30 ก.ย.] เลิกใช้ 3D engine → วาด Dimetric ด้วย 2D ล้วน

enum PhaseState {
	NONE,
	DIAGNOSIS, # 1 ดูอาการ 3 จุด + เลือกสาเหตุ
	BRIEFING, # 2 ปิ๊บสอนเรื่องแรม
	POWER_OFF, # 3 ปิดเครื่อง → ถอดปลั๊ก → แตะโครงเคส
	REMOVE, # 4 เปิดฝาข้าง → ปลดสลัก → ถอดแรมไปวางบนแผ่น ESD
	CLEAN, # 5 เลือกอุปกรณ์ 3 ขั้น (ฝุ่นบนแผง · ขาทอง · สล็อต)
	INSTALL, # 6 ใส่กลับให้ร่องบากตรง + กดลงจนสลักล็อก
	VERIFY, # 7 เสียบปลั๊ก → เปิดเครื่อง → ดูจอ
	SUMMARY, # 8 สรุป + คะแนน
}

const RAM_PIB_PATH = "res://Assets/Dialog/MiniGame/Ram_Pib.txt"
const TEX_DESKTOP := preload("res://Assets/MiniGame/PartRam/ram_tex_screen_desktop.png")
const TEX_GLITCH := preload("res://Assets/MiniGame/PartRam/ram_tex_screen_glitch.png")
const TEX_BOOT_OK := preload("res://Assets/MiniGame/PartRam/ram_tex_screen_boot_ok.png")
const TEX_DUST := preload("res://Assets/MiniGame/PartRam/ram_tex_dust.png")
const TEX_BEEP := preload("res://Assets/MiniGame/PartRam/ram_tex_beep.png")
const GOLD_DIRTY := Color(0.45, 0.36, 0.2)
const GOLD_CLEAN := Color(0.93, 0.73, 0.25)

@export var start_phase: PhaseState

@onready var stage: Stage2D = %Stage

# สถานะที่ส่งข้าม phase — CLEAN เขียน ram_damaged · INSTALL เขียน ram_seated · VERIFY อ่านทั้งคู่
var ram_damaged := false
var ram_seated := true
var plugged := true
var panel_open := false


func _ready() -> void:
	# คะแนนที่ถูกหักต่อหมวด (MINIGAME1_DESIGN.md หัวข้อ 9) — เต็ม 30 / 25 / 25 / 10 / 10
	_mistakes = { &"diagnosis": 0, &"safety": 0, &"tools": 0, &"handling": 0, &"tidiness": 0 }
	if dialog_path.is_empty():
		dialog_path = RAM_PIB_PATH
	minigame_finished.connect(_on_minigame_finished)
	_setup_dirt()
	super._ready()


## แรมสกปรกตั้งแต่เริ่ม: ฝุ่นบน PCB · ขาทองหมอง · ฝุ่นในสล็อต
func _setup_dirt() -> void:
	var ram: Item2D = %RamA2
	ram.add_overlay("Dust", TEX_DUST, Color(1, 1, 1, 1), PcPart.Face.SIDE_X, 0.9, 0.015) # ใช้ตอนยังไม่มีรูปสถานะ
	set_gold(0.0)
	ram.set_state("dirty")
	var slot: Item2D = %SlotBodyA2
	slot.add_overlay("Dust", TEX_DUST, Color(1, 1, 1, 1), PcPart.Face.TOP)
	slot.set_state("dirty")
	(%BeepFx as Item2D).texture = TEX_BEEP
	(%Monitor as Item2D).set_state("glitch")
	set_led(true)


## 0 = ขาทองหมอง · 1 = เงาวาว
func set_gold(t: float) -> void:
	var ram := %RamA2 as Item2D
	ram.set_shape_color("Gold", GOLD_DIRTY.lerp(GOLD_CLEAN, t)) # ตอนวาดจากโค้ด
	if t > 0.0:
		ram.set_state_blend("dusted", "clean", t) # รูป PNG: ขาทองหมอง → วาว (crossfade ตามความคืบหน้า)


func set_led(on: bool) -> void:
	(%PowerLed as Item2D).set_state("on" if on else "off")


func ram_clips() -> Array:
	var s: Socket2D = (%RamA2 as Item2D).socket
	return s.locks if s else []


func _register_phases() -> Dictionary:
	return {
		PhaseState.DIAGNOSIS: $PhaseDiagnosis as Phase,
		PhaseState.BRIEFING: $PhaseBriefing as Phase,
		PhaseState.POWER_OFF: $PhasePoweroff as Phase,
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


func _on_minigame_finished(_score: Dictionary) -> void:
	Global.in_minigame = false
	Global.cur_pib = null
	EventManager.minigame_end()
	call_deferred("queue_free")
