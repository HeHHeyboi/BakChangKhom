class_name PartMainboard extends PartMinigame
## มินิเกม Core Part: Mainboard + CPU — ซิลิโคนแห้ง เครื่องร้อนจนดับ (Docs/PART_MAINBOARD_DESIGN.md)
## ฉาก 2D ใน Scene/MiniGame/PartMainboard/part_mainboard.tscn → Stage/Views/<มุม>
##   ภาพรวมร้าน · โต๊ะคอม · ปลั๊กพ่วง · ในเคส (Board) · ซ็อกเก็ต CPU ซูม (Socket) · แผ่น ESD (Mat)
## phase อยู่ใน Scripts/MiniGame/PartMainboard/ (extends Phase2D) · บทปิ๊บ Assets/Dialog/MiniGame/Mainboard_Pib.txt
## [Claude 2 ต.ค. 2569]

enum PhaseState {
	NONE,
	INSPECT, # 1 ดู 3 จุด: ครีบฮีตซิงก์ · ขอบ CPU · ใต้เมนบอร์ด
	BRIEFING, # 2 ปิ๊บสอนเรื่องความร้อน/ซิลิโคน
	SAFETY, # 3 ปิดเครื่อง → ถอดปลั๊ก → แตะเคส → เลือกที่วางชิ้นส่วน
	REMOVE, # 4 คลายน็อตแบบไขว้ → หมุนเบา ๆ แล้วยกฮีตซิงก์
	CLEAN, # 5 เลือกอุปกรณ์เช็ดซิลิโคนเก่า 2 ขั้น (ผิว CPU · ฐานฮีตซิงก์)
	SEAT_CPU, # 6 เปิดคานล็อก → หัน CPU ให้สามเหลี่ยมตรง → วาง → ปิดคาน
	PASTE, # 7 เลือกชนิด + ปริมาณซิลิโคน
	MOUNT, # 8 วางฮีตซิงก์ → ขันน็อตแบบไขว้ → เสียบปลั๊ก เปิดเครื่อง ดูอุณหภูมิ
	SUMMARY, # 9 สรุปคะแนน
}

const PIB_PATH = "res://Assets/Dialog/MiniGame/Mainboard_Pib.txt"
## มุม CPU ที่วางลงได้ (องศา) — สามเหลี่ยมทองมุมซ้ายล่างตรงกับซ็อกเก็ต
const CPU_OK_ROTATION := 0
const BASE_TEMP := 54.0

@export var start_phase: PhaseState

@onready var stage: Stage2D = %Stage

# สถานะที่ส่งข้าม phase
var plugged := true
var paste_amount := 1 # 0 น้อย · 1 พอดี · 2 มาก (ล้น → เช็ดใหม่)
var screw_diagonal := true
var pins_bent := false
var temp_result := 0.0
var cpu_home := Vector2.ZERO


func _ready() -> void:
	# คะแนนที่ถูกหักต่อหมวด (PART_MAINBOARD_DESIGN.md หัวข้อ 9)
	_mistakes = { &"inspect": 0, &"safety": 0, &"tools": 0, &"cpu": 0, &"paste": 0, &"screws": 0 }
	if dialog_path.is_empty():
		dialog_path = PIB_PATH
	minigame_finished.connect(_on_minigame_finished)
	cpu_home = (%Cpu as Control).position
	_setup()
	super._ready()


## สภาพเครื่องตอนรับมา: ครีบฝุ่นเต็ม · ซิลิโคนแห้ง · เครื่องเปิดอยู่
func _setup() -> void:
	(%Cooler as Item2D).set_state("dusty")
	(%CoolerTop as Item2D).set_state("")
	(%Cpu as Item2D).set_state("old")
	(%Cpu as Control).rotation_degrees = 0
	(%Retention as Item2D).set_state("")
	(%HeatsinkBase as Item2D).set_state("off")
	(%Monitor as Item2D).set_state("desktop")
	(%Plug as Item2D).set_state("")
	(%TempLabel as Label).hide()
	for s in screws():
		s.set_state("")
		s.rotation_degrees = 0
	set_led(true)


func screws() -> Array[Item2D]:
	return [%Screw1 as Item2D, %Screw2 as Item2D, %Screw3 as Item2D, %Screw4 as Item2D]


func set_led(on: bool) -> void:
	(%PowerLed as Item2D).set_state("on" if on else "off")


## ลำดับขันน็อตแบบไขว้: น็อตที่ 1-2 ต้องเป็นคู่ทแยง (1,3) หรือ (2,4) และ 3-4 เป็นอีกคู่
static func is_diagonal(order: Array) -> bool:
	if order.size() < 4:
		return false
	var a := [order[0], order[1]]
	a.sort()
	var b := [order[2], order[3]]
	b.sort()
	return (a == [1, 3] and b == [2, 4]) or (a == [2, 4] and b == [1, 3])


# override PartMinigame._register_phases
func _register_phases() -> Dictionary:
	return {
		PhaseState.INSPECT: $PhaseInspect as Phase,
		PhaseState.BRIEFING: $PhaseBriefing as Phase,
		PhaseState.SAFETY: $PhaseSafety as Phase,
		PhaseState.REMOVE: $PhaseRemove as Phase,
		PhaseState.CLEAN: $PhaseClean as Phase,
		PhaseState.SEAT_CPU: $PhaseSeatCpu as Phase,
		PhaseState.PASTE: $PhasePaste as Phase,
		PhaseState.MOUNT: $PhaseMount as Phase,
		PhaseState.SUMMARY: $PhaseSummary as Phase,
	}


# override PartMinigame._first_phase
func _first_phase() -> int:
	if start_phase != PhaseState.NONE:
		return start_phase
	return PhaseState.INSPECT


# override PartMinigame._last_phase
func _last_phase() -> int:
	return PhaseState.SUMMARY


## override PartMinigame._debug_phase_name
func _debug_phase_name(phase: int) -> String:
	return PhaseState.find_key(phase)


## override PartMinigame._debug_prepare — จัดฉากให้เหมือนเล่นมาถึงก่อน phase นี้
func _debug_prepare(phase: int) -> void:
	_setup()
	var off := phase > PhaseState.SAFETY and phase < PhaseState.SUMMARY
	plugged = not off
	(%Plug as Item2D).set_state("out" if off else "")
	(%Monitor as Item2D).set_state("off" if off else "desktop")
	set_led(not off)
	var cooler_off := phase > PhaseState.REMOVE and phase < PhaseState.SUMMARY
	(%CoolerTop as Item2D).set_state("off" if cooler_off else "")
	for s in screws():
		s.set_state("off" if cooler_off else "")
	(%HeatsinkBase as Item2D).set_state(("clean" if phase > PhaseState.CLEAN else "dirty") if cooler_off else "off")
	(%Cpu as Item2D).set_state("clean" if phase > PhaseState.CLEAN else "old")
	if phase > PhaseState.CLEAN:
		(%Cooler as Item2D).set_state("")


func _on_minigame_finished(_score: Dictionary) -> void:
	Global.in_minigame = false
	Global.cur_pib = null
	if has_meta("standalone"): # เปิดจากเมนู Debug — ไม่แตะเควสต์หลัก
		EventManager.showUI()
	else:
		EventManager.minigame_end()
	call_deferred("queue_free")
