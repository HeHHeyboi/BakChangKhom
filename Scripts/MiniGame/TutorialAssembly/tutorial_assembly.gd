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

## [Claude 9 ต.ค. 2569] ภาพ "ประกอบแล้ว" ของแต่ละชิ้น (ขนาดเท่ามุม Build วางทับเป๊ะ) — ใส่เสร็จแล้วชิ้นที่ลอยหายไป เหลือภาพนี้
## วาดจาก Assets/MiniGame/TutorialAssembly/src/gen_asm.py (แก้ตำแหน่ง socket ต้องสร้างภาพใหม่ด้วย)
const LAYER_DIR := "res://Assets/MiniGame/TutorialAssembly/asm_layer_%s.png"
## socket_type → ชื่อภาพ · เรียงตามลำดับซ้อน (ล่าง → บน)
const LAYERS := {
	&"psu_bay": "psu", &"mb_standoff": "mb", &"cpu_socket": "cpu", &"cooler_mount": "cooler",
	&"ram_slot": "ram", &"m2_slot": "ssd", &"pcie_x16": "gpu", &"cables": "cables",
}
const LAYER_FADE := 0.25
## หลังเปิดเครื่อง → ทำความรู้จัก ขมOS (phase_power)
const DESKTOP_SCENE := "res://Scene/MiniGame/Desktop/desktop_window.tscn"
const OS_TOUR := "res://Resources/Desktop/Free/os_tour.tres"

@export var start_phase: PhaseState

var _layers: Dictionary = { } # socket_type → TextureRect
## ขมOS ที่เปิดอยู่ (tour) · null = ไม่ได้เปิด
var os_tour: Node

@onready var stage: Stage2D = %Stage


func _ready() -> void:
	if dialog_path.is_empty():
		dialog_path = PIB_PATH
	minigame_finished.connect(_on_minigame_finished)
	skippable = true # [Claude 5 ต.ค. 2569] ข้ามได้ตอนเป็น Tutorial/เควสต์ · งานลูกค้าข้ามไม่ได้ (PartMinigame เช็ก work_order)
	_build_layers()
	super._ready()


func _build_layers() -> void:
	var build := stage.find_view(&"Build")
	if build == null:
		return
	var box := Control.new()
	box.name = "Installed"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size = Vector2(1152, 420)
	build.add_child(box)
	build.move_child(box, 0) # อยู่ใต้ socket/ชิ้นที่กำลังลอย
	for key in LAYERS:
		var path := LAYER_DIR % LAYERS[key]
		if not ResourceLoader.exists(path):
			push_warning("TutorialAssembly: ไม่พบภาพ %s" % path)
			continue
		var t := TextureRect.new()
		t.name = String(LAYERS[key]).capitalize()
		t.texture = load(path)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_SCALE
		t.size = box.size
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.visible = false
		box.add_child(t)
		_layers[key] = t


## ชิ้นนี้ติดตั้งเสร็จ → ภาพประกอบแล้วจางเข้า แล้วซ่อนชิ้นที่ลอยอยู่ (น็อต/คันล็อกที่เป็นลูกของชิ้นหายไปด้วย — มีในภาพแล้ว)
func show_installed(p: Item2D, animate := true) -> void:
	if p == null or p.data == null:
		return
	await _fade_layer(p.data.socket_type, animate)
	if is_instance_valid(p):
		p.visible = false


## เปิดขมOS แบบทำความรู้จัก (ทับทั้งจอ) แล้วรอจนผู้เล่นปิดเครื่อง/กดข้าม · คืน true = ข้าม
func open_os_tour() -> bool:
	var ps := load(DESKTOP_SCENE) as PackedScene
	if ps == null or not ResourceLoader.exists(OS_TOUR):
		push_warning("TutorialAssembly: เปิดขมOS ไม่ได้ — ข้ามไป")
		return true
	var m := ps.instantiate()
	m.set("task", load(OS_TOUR))
	m.set("tour_mode", true)
	m.set("ui_layer", 115) # เหนือ UI บทฝึก (ปุ่มกลับ 110 · QTE 30 · ปุ่มข้าม 35) แต่ใต้ปิ๊บ (120)
	if is_instance_valid(pib):
		pib.hide()
	os_tour = m
	add_child(m)
	var skipped: bool = await m.tour_finished
	os_tour = null
	Global.cur_pib = pib
	return skipped


func close_os_tour() -> void:
	if is_instance_valid(os_tour):
		os_tour.queue_free()
	os_tour = null
	Global.cur_pib = pib


## สายไฟ (ตอนครบทุกชิ้น)
func show_cables(animate := true) -> void:
	await _fade_layer(&"cables", animate)


func layer_shown(key: StringName) -> bool:
	return _layers.has(key) and (_layers[key] as Control).visible and (_layers[key] as Control).modulate.a > 0.99


func _fade_layer(key: StringName, animate: bool) -> void:
	var t: TextureRect = _layers.get(key)
	if t == null:
		return
	t.visible = true
	if not animate:
		t.modulate.a = 1.0
		return
	t.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(t, "modulate:a", 1.0, LAYER_FADE)
	await tw.finished


## ชิ้นส่วนทั้งหมด (ลูกของ node Parts ตอนเริ่ม) เรียงตามลำดับประกอบ — รวมชิ้นที่ใส่ลงเคสแล้ว
## [Claude 10 ต.ค. 2569] เดิมอ่านจาก Parts ทุกครั้ง พอชิ้นถูกย้ายลงเคส (reparent) ก็หายจากรายการ → หน้าสรุปว่าง
var _all_parts: Array[Item2D] = []


func parts() -> Array[Item2D]:
	if _all_parts.is_empty():
		for n in %Parts.get_children():
			if n is Item2D:
				_all_parts.append(n)
	var a: Array[Item2D] = []
	for n in _all_parts:
		if is_instance_valid(n):
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
	for s in stage.sockets: # ชิ้นที่ใส่แล้ว (ย้ายออกจาก Parts ไปแล้ว)
		if s.occupant and not s.accept_any:
			show_installed(s.occupant, false)
	for p in parts():
		if p.socket != null and not p.socket.accept_any:
			continue
		for s in stage.sockets:
			if s.socket_type == p.data.socket_type and s.occupant == null:
				stage.install(p, s, false, false)
				p.mode = Item2D.Mode.STATIC
				show_installed(p, false)
				break
	show_cables(false)


func _on_minigame_finished(_score: Dictionary) -> void:
	Global.in_minigame = false
	Global.cur_pib = null
	EventManager.minigame_end()
	call_deferred("queue_free")
