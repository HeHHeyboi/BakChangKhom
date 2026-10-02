class_name PartFrontPanel extends PartMinigame
## มินิเกม Core Part: Front Panel + Dual Channel — กดปุ่มแล้วเครื่องไม่ติด (Docs/PART_FRONTPANEL_DESIGN.md)
## ฉาก 2D ใน Scene/MiniGame/PartFrontPanel/part_front_panel.tscn → Stage/Views/<มุม>
##   ภาพรวมร้าน · โต๊ะคอม (ปุ่ม/ไฟหน้าเคส · จอ BIOS) · ท้ายเคส (ปลั๊ก) · ในเคส · แผงพินซูม (Pins) · สล็อตแรม (Slots)
## phase อยู่ใน Scripts/MiniGame/PartFrontPanel/ · บทปิ๊บ Assets/Dialog/MiniGame/FrontPanel_Pib.txt
## [Claude 2 ต.ค. 2569]

enum PhaseState {
	NONE,
	INSPECT, # 1 ไฟเมนบอร์ดติด · กดปุ่มแล้วเงียบ · โน้ตลูกค้า
	BRIEFING, # 2 ปุ่ม power แค่ต่อวงจร 2 ขา
	SAFETY, # 3 ถอดปลั๊ก → แตะเคส
	READ_MAP, # 4 ส่องไฟฉายอ่านผังพิน (ข้ามได้ −10)
	CONNECT, # 5 เสียบหัวต่อ 4 หัว (ตำแหน่ง + ขั้ว LED)
	TEST_BUTTON, # 6 เสียบปลั๊ก กดปุ่มหน้าเคส ดูไฟ (ผิด → ย้อนไปแก้)
	DUAL_CHANNEL, # 7 จัดแรม 2 แถวให้เป็น dual channel
	VERIFY, # 8 บูตเข้า BIOS ดู Dual/Single Channel
	SUMMARY, # 9 สรุป
}

const PIB_PATH = "res://Assets/Dialog/MiniGame/FrontPanel_Pib.txt"
const CONNS := ["power_sw", "reset_sw", "power_led", "hdd_led"]
const CONN_NODE := { "power_sw": "ConnPowerSw", "reset_sw": "ConnResetSw", "power_led": "ConnPowerLed", "hdd_led": "ConnHddLed" }
const CONN_NAME := { "power_sw": "POWER SW", "reset_sw": "RESET SW", "power_led": "POWER LED", "hdd_led": "HDD LED" }
const CORRECT_PAIR := { "power_sw": "pwr", "reset_sw": "rst", "power_led": "pled", "hdd_led": "hdd" }
const HAS_POLARITY := { "power_sw": false, "reset_sw": false, "power_led": true, "hdd_led": true }
## จุดกึ่งกลางคู่พิน (x) และแถว (true = แถวบน)
const PAIRS := { "pled": [486.0, true], "pwr": [606.0, true], "hdd": [486.0, false], "rst": [606.0, false] }
const PAIR_NODE := { "pled": "PairPled", "pwr": "PairPwr", "hdd": "PairHdd", "rst": "PairRst" }
const TRAY := [Vector2(150, 130), Vector2(280, 130), Vector2(150, 270), Vector2(280, 270)] # ถาดซ้าย (ในกรอบกล้อง · พ้นแถบหัวขั้นตอน)
const ROW_TOP_Y := 72.0
const ROW_BOT_Y := 228.0
const SLOTS := ["A1", "A2", "B1", "B2"]
const SLOT_TOP := { "A1": 113.0, "A2": 178.0, "B1": 243.0, "B2": 308.0 }
const RAISED := 7.0

@export var start_phase: PhaseState

@onready var stage: Stage2D = %Stage

var plugged := true
var map_revealed := false
var placement := {} # conn → pair ("" = อยู่ในถาด)
var flipped := {} # conn → bool (กลับขั้ว)
var ram := {} # slot → "" ว่าง · "raised" วางแต่ยังไม่ลง · "locked"
var ram_in_hand := 0 # แรมที่ถอดออกมาถืออยู่
var channel_result := "" # "Dual" / "Single" (ขั้น VERIFY)


func _ready() -> void:
	_mistakes = { &"inspect": 0, &"safety": 0, &"map": 0, &"connect": 0, &"dual": 0, &"verify": 0 }
	if dialog_path.is_empty():
		dialog_path = PIB_PATH
	minigame_finished.connect(_on_minigame_finished)
	_setup()
	super._ready()


## สภาพเครื่องตอนรับมา: เสียบปลั๊ก ไฟเมนบอร์ดติด · หัวต่อหน้าเคสหลุดหมด (ลูกค้าถอดตอนทำความสะอาด) · แรมอยู่ A1 + A2
func _setup() -> void:
	plugged = true
	map_revealed = false
	(%PowerCord as Item2D).set_state("")
	(%MbLed as Item2D).set_state("")
	(%Monitor as Item2D).set_state("off")
	(%MemLabel as Label).hide()
	(%PinLabels as Item2D).set_state("off")
	(%Beam as Control).hide()
	(%Flashlight as Control).show()
	set_front_leds(false, false)
	for i in CONNS.size():
		var c: String = CONNS[i]
		placement[c] = ""
		flipped[c] = HAS_POLARITY[c] and i == 2 # POWER LED มาแบบกลับหัว ผู้เล่นต้องสังเกตเอง
		place_conn(c, "", false)
	ram_in_hand = 0
	channel_result = ""
	for s in SLOTS:
		ram[s] = "locked" if s == "A1" or s == "A2" else ""
		show_ram(s)


func set_front_leds(power_on: bool, hdd_on: bool) -> void:
	(%PowerLed as Item2D).set_state("on" if power_on else "off")
	(%HddLed as Item2D).set_state("on" if hdd_on else "off")


func conn_node(c: String) -> Item2D:
	return get_node("%" + CONN_NODE[c]) as Item2D


func conn_at(pair: String) -> String:
	for c in CONNS:
		if placement[c] == pair:
			return c
	return ""


## วางหัวต่อ c ที่คู่พิน pair ("" = กลับถาด) · แถวล่างพลิกแนวตั้งให้สายชี้ลง
func place_conn(c: String, pair: String, animate := true) -> void:
	placement[c] = pair
	var n := conn_node(c)
	var to: Vector2
	var sy := 1.0
	if pair == "":
		to = TRAY[CONNS.find(c)]
	else:
		var p: Array = PAIRS[pair]
		to = Vector2(float(p[0]) - 60.0, ROW_TOP_Y if p[1] else ROW_BOT_Y)
		sy = 1.0 if p[1] else -1.0
	n.mirror = flipped[c]
	n.queue_redraw()
	n.pivot_offset = n.size / 2.0
	n.scale = Vector2(1, sy)
	if animate:
		create_tween().tween_property(n, "position", to, 0.18)
	else:
		n.position = to


func flip_conn(c: String) -> void:
	flipped[c] = not flipped[c]
	conn_node(c).mirror = flipped[c]
	conn_node(c).queue_redraw()


func conn_ok(c: String) -> bool:
	return placement[c] == CORRECT_PAIR[c] and not (HAS_POLARITY[c] and flipped[c])


func show_ram(s: String) -> void:
	var r := get_node("%Ram" + s) as Item2D
	r.set_state("off" if ram[s] == "" else "")
	r.position.y = SLOT_TOP[s] - (RAISED if ram[s] == "raised" else 0.0)
	r.modulate = Color(1, 1, 1, 0.85) if ram[s] == "raised" else Color.WHITE
	for side in ["L", "R"]:
		(get_node("%Clip" + s + side) as Item2D).set_state("" if ram[s] == "locked" else "open")


func ram_slots() -> Array:
	return SLOTS.filter(func(s): return ram[s] != "")


## A?+B? = dual · สองแถวช่องเดียวกัน หรือแถวเดียว = single
func is_dual() -> bool:
	var used := ram_slots()
	if used.size() != 2:
		return false
	return String(used[0]).left(1) != String(used[1]).left(1)


func go_phase(p: PhaseState) -> void:
	if _phase_nodes.has(current_phase):
		_phase_nodes[current_phase].abort()
	_set_phase(p)


func _register_phases() -> Dictionary:
	return {
		PhaseState.INSPECT: $PhaseInspect as Phase,
		PhaseState.BRIEFING: $PhaseBriefing as Phase,
		PhaseState.SAFETY: $PhaseSafety as Phase,
		PhaseState.READ_MAP: $PhaseReadMap as Phase,
		PhaseState.CONNECT: $PhaseConnect as Phase,
		PhaseState.TEST_BUTTON: $PhaseTest as Phase,
		PhaseState.DUAL_CHANNEL: $PhaseDual as Phase,
		PhaseState.VERIFY: $PhaseVerify as Phase,
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


func _debug_prepare(phase: int) -> void:
	_setup()
	if phase > PhaseState.SAFETY:
		plugged = false
		(%PowerCord as Item2D).set_state("out")
		(%MbLed as Item2D).set_state("off")
	if phase > PhaseState.READ_MAP:
		map_revealed = true
		(%PinLabels as Item2D).set_state("")
		(%Beam as Control).show()
		(%Flashlight as Control).hide()
	if phase > PhaseState.CONNECT:
		for c in CONNS:
			flipped[c] = false
			place_conn(c, CORRECT_PAIR[c], false)
	if phase > PhaseState.TEST_BUTTON:
		plugged = true
		(%PowerCord as Item2D).set_state("")


func _on_minigame_finished(_score: Dictionary) -> void:
	Global.in_minigame = false
	Global.cur_pib = null
	if has_meta("standalone"):
		EventManager.showUI()
	else:
		EventManager.minigame_end()
	call_deferred("queue_free")
