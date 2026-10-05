class_name PartBios extends PartMinigame
## มินิเกม Core Part: BIOS + OS + Upgrade — เคส C05 "เปิดทีไรเข้าหน้าจอฟ้า ๆ" (Docs/PART_BIOS_DESIGN.md)
## ฉาก 2D ใน Scene/MiniGame/PartBios/part_bios.tscn → Stage/Views/<มุม>
##   ภาพรวมร้าน · โต๊ะคอม (จอเล็ก + ปุ่ม) · ท้ายเคส (แฟลชไดรฟ์ลูกค้า · USB ตัวติดตั้ง · ปลั๊ก) · ในเคส (ถ่าน CMOS)
##   · Bios (หน้าจอ BIOS เต็มมุม) · Install (เลือกไดรฟ์ลง Windows) · Chart (กราฟคอขวด)
## ค่าบนจอ BIOS เป็น Label ผูกกับ state (refresh_bios) ไม่ฝังในภาพ · บทปิ๊บ Assets/Dialog/MiniGame/Bios_Pib.txt
## [Claude 2 ต.ค. 2569]

enum PhaseState {
	NONE,
	INSPECT, # 1 อ่านหน้าจอ BIOS ที่ค้างอยู่ 3 แถบ
	BRIEFING, # 2 BIOS คืออะไร
	CHECK_HW, # 3 ตอบคำถามจากค่าบนจอ (แรมกี่ GB · ความเร็ว · ดิสก์อยู่มั้ย)
	BOOT_ORDER, # 4 จัดลำดับบูต (ต้นเหตุ)
	XMP, # 5 เปิดโปรไฟล์ความเร็วแรม
	SAVE_EXIT, # 6 Save / Discard / Load Defaults → บูตจริง (ผิด → ย้อนกลับ · XMP ล้ม → เคลียร์ CMOS)
	OS_INSTALL, # 7 ลง Windows ลง SSD ใหม่ของลูกค้า (ห้ามทับ HDD ข้อมูลลูกค้า)
	UPGRADE, # 8 อ่านกราฟคอขวด แนะนำการอัปเกรด
	SUMMARY, # 9 สรุป
}

const PIB_PATH = "res://Assets/Dialog/MiniGame/Bios_Pib.txt"
const DEV_NAME := {
	"usb": "USB : KINGSTON DT 32GB",
	"hdd": "SATA 1 : WDC 1TB (Windows)",
	"dvd": "DVD : ASUS DRW-24D5",
	"net": "Network : PXE LAN",
}
const START_ORDER := ["usb", "hdd", "dvd", "net"] # ตอนรับเครื่องมา
const DEFAULT_ORDER := ["hdd", "dvd", "usb", "net"] # Load Optimized Defaults / เคลียร์ CMOS
const XMP_TEXT := ["Disabled  (2133 MHz)", "Profile 1  (3200 MHz)", "Profile 2  (3000 MHz)"]
const XMP_MHZ := [2133, 3200, 3000]

@export var start_phase: PhaseState
## -1 สุ่ม 20% · 0 ไม่ล้ม · 1 ล้มเสมอ (Profile 1 ครั้งแรก) — ใช้ทดสอบ
@export var force_xmp_fail := -1

@onready var stage: Stage2D = %Stage

var order: Array = [] # ลำดับที่กำลังแก้บนจอ
var xmp := 0
var saved_order: Array = [] # ลำดับที่บันทึกในเมนบอร์ดแล้ว
var saved_xmp := 0
var usb_plugged := true # แฟลชไดรฟ์ลูกค้าที่เสียบค้าง
var installer_plugged := false
var plugged := true
var xmp_p1_unstable := false # Profile 1 เคยทำเครื่องบูตไม่ขึ้น
var os_drive := "" # "ssd" / "hdd"
var data_lost := false


func _ready() -> void:
	_mistakes = { &"read": 0, &"boot": 0, &"xmp": 0, &"save": 0, &"os": 0, &"upgrade": 0 }
	if dialog_path.is_empty():
		dialog_path = PIB_PATH
	minigame_finished.connect(_on_minigame_finished)
	_setup()
	super._ready()


func _setup() -> void:
	order = START_ORDER.duplicate()
	saved_order = START_ORDER.duplicate()
	xmp = 0
	saved_xmp = 0
	usb_plugged = true
	installer_plugged = false
	plugged = true
	xmp_p1_unstable = false
	os_drive = ""
	data_lost = false
	(%UsbStick as Item2D).set_state("")
	(%UsbInstaller as Item2D).set_state("out")
	(%PowerCord as Item2D).set_state("")
	(%CmosBattery as Item2D).set_state("")
	(%Monitor as Item2D).set_state("bios")
	(%PowerLed as Item2D).set_state("on")
	(%Popup as Item2D).set_state("off")
	(%PopupLabel as Label).hide()
	show_progress(false)
	refresh_bios()


## เขียนค่าบนจอ BIOS ใหม่จาก state
func refresh_bios() -> void:
	for i in 4:
		(get_node("%%BootLbl%d" % (i + 1)) as Label).text = "%d.  %s" % [i + 1, DEV_NAME[order[i]]]
	(%MemLabel as Label).text = "Memory  : 16384 MB @ %d MHz" % XMP_MHZ[xmp]
	(%XmpLabel as Label).text = XMP_TEXT[xmp]
	(%XmpToggle as Item2D).set_state("on" if xmp > 0 else "")
	var ssd := "SATA 2  : SSD 240GB (%s)" % ("Windows" if os_drive == "ssd" else "empty")
	(%Sata2Label as Label).text = ssd
	(%Sata1Label as Label).text = "SATA 1  : WDC 1TB (%s)" % ("Windows - new" if data_lost else "Windows")


func show_progress(on: bool) -> void:
	(%ProgressBg as Control).visible = on
	(%ProgressFill as Control).visible = on
	(%ProgressLabel as Control).visible = on
	for n in ["DriveSsd", "DriveHdd", "DriveUsb"]:
		(get_node("%" + n) as Control).visible = not on
		(get_node("%" + n + "Lbl") as Control).visible = not on


func set_power(on: bool, screen := "bios") -> void:
	(%PowerLed as Item2D).set_state("on" if on else "off")
	(%Monitor as Item2D).set_state(screen if on else "off")


## ค่าทั้งหมดกลับเป็นค่าโรงงาน (Load Defaults / เคลียร์ CMOS)
func load_defaults() -> void:
	order = DEFAULT_ORDER.duplicate()
	xmp = 0
	refresh_bios()


func discard() -> void:
	order = saved_order.duplicate()
	xmp = saved_xmp
	refresh_bios()


func save_settings() -> void:
	saved_order = order.duplicate()
	saved_xmp = xmp
	refresh_bios()


## อุปกรณ์แรกที่เครื่องจะลองบูต (ข้าม USB ถ้าถอดออกแล้ว)
func first_boot_device() -> String:
	for d in saved_order:
		if d == "usb" and not usb_plugged:
			continue
		return d
	return ""


## Profile 1 บูตไม่ขึ้นหรือเปล่า (ครั้งแรกสุ่ม 20% · เคยล้มแล้วล้มตลอด)
func xmp_fails() -> bool:
	if saved_xmp != 1:
		return false
	if xmp_p1_unstable:
		return true
	var fail := randf() < 0.2 if force_xmp_fail < 0 else force_xmp_fail == 1
	xmp_p1_unstable = fail
	return fail


func go_phase(p: PhaseState) -> void:
	if _phase_nodes.has(current_phase):
		_phase_nodes[current_phase].abort()
	_set_phase(p)


func _register_phases() -> Dictionary:
	return {
		PhaseState.INSPECT: $PhaseInspect as Phase,
		PhaseState.BRIEFING: $PhaseBriefing as Phase,
		PhaseState.CHECK_HW: $PhaseCheckHw as Phase,
		PhaseState.BOOT_ORDER: $PhaseBootOrder as Phase,
		PhaseState.XMP: $PhaseXmp as Phase,
		PhaseState.SAVE_EXIT: $PhaseSaveExit as Phase,
		PhaseState.OS_INSTALL: $PhaseOsInstall as Phase,
		PhaseState.UPGRADE: $PhaseUpgrade as Phase,
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
	if phase > PhaseState.BOOT_ORDER:
		order = ["hdd", "usb", "dvd", "net"]
	if phase > PhaseState.XMP:
		xmp = 2
	if phase > PhaseState.SAVE_EXIT:
		save_settings()
		set_power(true, "desktop")
	if phase > PhaseState.OS_INSTALL:
		os_drive = "ssd"
	refresh_bios()


## ของเสียระหว่างซ่อม → GameState หักเงิน
func repair_damaged() -> bool:
	return data_lost


func _on_minigame_finished(_score: Dictionary) -> void:
	Global.in_minigame = false
	Global.cur_pib = null
	if has_meta("standalone"):
		EventManager.showUI()
	else:
		EventManager.minigame_end()
	call_deferred("queue_free")
