class_name DesktopMinigameV2 extends PartMinigame

const MIN_SHORTCUT_SIZE = Vector2(60, 60)
const DEFAULT_WINDOW_SIZE = Vector2(450, 350)

const C_INK := Color(0.23, 0.16, 0.11)
const C_BAD := Color(0.75, 0.2, 0.12)
const C_DIM := Color(0.4, 0.35, 0.3)
const C_OK := Color(0.15, 0.5, 0.2)
# NOTE: Load app scene
const EXPLORER_SCENE := preload("res://Scene/MiniGame/Desktop/os_explorer.tscn")
const BROWSER_SCENE := preload("res://Scene/MiniGame/Desktop/os_browser.tscn")
const SETTING_SCENE := preload("res://Scene/MiniGame/Desktop/os_settings.tscn")
const WINDOW_BASE := preload("res://Scene/MiniGame/Desktop/os_window_base.tscn")
const INFO_WINDOW := preload("res://Scene/MiniGame/Desktop/os_info.tscn")
const TASKMANAGER_SCENE := preload("res://Scene/MiniGame/Desktop/os_taskman.tscn")
const WIZARD_SCENE := preload("res://Scene/MiniGame/Desktop/os_wizard.tscn")
const AD_POPUP := preload("res://Scene/MiniGame/Desktop/os_popup_ad.tscn")
const UNSAVED_DOC := "res://Scene/MiniGame/Desktop/os_unsaved_doc.tscn"
const SHORTCUT_SCENE := preload("res://Scene/MiniGame/Desktop/shortcut.tscn")


# NOTE: Explorer constant
## หน้าต่างไฟล์ (Explorer) — โครงจาก os_explorer.tscn · ข้อมูลจาก os.dir_map / os.fs
const DOC_DIR = "เอกสาร"
const DOWNLOAD_DIR = "ดาวน์โหลด"
const PIC_DIR = "รูปภาพ"
const TRASH_DIR = DesktopOS.TRASH

# NOTE: Browser constant
const BROWSER_HOME = "home"
const BROWSER_OFFICIAL = "official"
const BROWSER_OFFICIAL_SCENE = "res://Scene/MiniGame/Desktop/os_browser_official.tscn"
const BROWSER_RESULT_SCENE = "res://Scene/MiniGame/Desktop/os_browser_result.tscn"
const BROWSER_AD_SCENE = "res://Scene/MiniGame/Desktop/os_browser_ad.tscn"
const INFO_ROW = "res://Scene/MiniGame/Desktop/os_row.tscn"

# NOTE: Setting constant
const INSTALLED_APP = "res://Scene/MiniGame/Desktop/os_app_row.tscn"
const PRINTERS_SETTING = "res://Scene/MiniGame/Desktop/os_printers.tscn"
const SOUND_SETTING = "res://Scene/MiniGame/Desktop/os_sound.tscn"
const UPDATED_SETTING = "res://Scene/MiniGame/Desktop/os_update.tscn"
const SECURITY_SETTING = "res://Scene/MiniGame/Desktop/os_security.tscn"
const DISPLAY_SETTING = "res://Scene/MiniGame/Desktop/os_display.tscn"
const WIFI_SETTING = "res://Scene/MiniGame/Desktop/os_wifi.tscn"
const NET_INFO = "res://Scene/MiniGame/Desktop/os_net_row.tscn"


# NOTE: Icon Texture
const DIR := "res://Assets/MiniGame/Desktop/"
const TEX_WALL := preload(DIR + "os_wallpaper.jpg")
const TEX_START := preload(DIR + "os_start.png")
const TEX_NOTE := preload(DIR + "os_sticky_note.png")
const TEX_FOLDER := preload(DIR + "os_icon_folder.png")
const TEX_PICTURES := preload(DIR + "os_icon_pictures.png")
const TEX_DOWNLOADS := preload(DIR + "os_icon_downloads.png")
const TEX_TRASH := preload(DIR + "os_icon_trash_empty.png")
const TEX_TRASH_FULL := preload(DIR + "os_icon_trash_full.png")
const TEX_BROWSER := preload(DIR + "os_icon_browser.png")
const TEX_SETTINGS := preload(DIR + "os_icon_settings.png")
const TEX_CHAT := preload(DIR + "os_icon_chat.png")
const TEX_ADWARE := preload(DIR + "os_icon_adware.png")
const TEX_EXE := preload(DIR + "os_icon_file_exe.png")
const TEX_IMAGE := preload(DIR + "os_icon_file_image.png")
const TEX_DOC := preload(DIR + "os_icon_file_doc.png")
const TEX_WARN := preload(DIR + "os_icon_file_warn.png")

const CAP := { &"fix": 40, &"safety": 30, &"listen": 20, &"explain": 10 }
const ADWARE_SIZE_MB := 120

enum Step {
	LISTEN,
	WORK,
	EXPLAIN,
	SUMMARY,
	DONE,
}
@export var task: DesktopTask
@export var popup_every := 7.0
@export var free_mode := false
@export var tour_mode := false
@export var ui_layer := 5
@export var framed := true
@export var boot_screen := true
var doc_saved = false
var lost_user_file = false
var protection_on = true
var step: Step = Step.LISTEN
var usb_ejected = true
@onready var boot_node = $Os/Screen/OsBoot as OsBoot


# NOTE: Taskbar icon
@onready var start_button = %StartMenu as Button
@onready var screen = %Screen
@onready var explorer = %Explorer as Button
@onready var browser = %Browser as Button
@onready var settings = %Settings as Button
@onready var wifi = %Wifi
@onready var sound = %Sound
@onready var disk = %Disk
@onready var clock = %Clock
@onready var desktop = %Desktop

# NOTE: Desktop icon
@onready var doc_icon = %Doc as DesktopShortcut
@onready var pic_icon = %Pic as DesktopShortcut
@onready var download_icon = %Download as DesktopShortcut
@onready var trash_icon = %Trash as DesktopShortcut
@onready var browser_icon = %BrowserIcon as DesktopShortcut

# NOTE: Minigame Node
@onready var msg_bubble = %CustomerBubble
@onready var note = %Note

var os: DesktopOS
# var _selected_icon: Control
var start_menu: PopupMenu
# var file_menu: PopupMenu
var customer_name: String
var _popup_timer := Timer.new()
var sound_tested := false
# NOTE: Explorer var
var _explorer_folder := "เดสก์ท็อป"
var _explorer_win: OsExplorer
var _explorer_list: ItemList
var _explorer_path: Label
var _explorer_status: Label
var _explorer_usb_dir: Control
var notes: PackedStringArray = []
var _bubble_tw: Tween
## ชื่อโปรแกรม → ไอคอนบนเดสก์ท็อป
var _app_shortcuts: Dictionary[String, DesktopShortcut] = { }

# NOTE: Browser var
var _browser_page: VBoxContainer
var _browser_addr: LineEdit

# NOTE: Task Manager var
var _proc_panel: Control
var _autostart_panel: Control

# NOTE: Setting var
var _settings_installed_list: VBoxContainer
var _settings_progress_bar: ProgressBar
var _settings_disk_label: Label

# NOTE: Printer var
var _printer_install_list: VBoxContainer
var _printer_empty_text: Label
var _printer_test_btn: Button
var _printer_found_list: VBoxContainer
var _print_test_result: Label

var items := [
	["เอกสาร", TEX_FOLDER],
	["รูปภาพ", TEX_PICTURES],
	["ดาวน์โหลด", TEX_DOWNLOADS],
	["เบราว์เซอร์", TEX_BROWSER],
	["ตั้งค่า", TEX_SETTINGS],
	["ถังขยะ", TEX_TRASH],
	["ตัวจัดการงาน", TEX_SETTINGS],
	["ขมการ์ด (ความปลอดภัย)", TEX_SETTINGS],
]
enum UpdateState {
	NOT_CHECKED,
	FOUND,
	INSTALL,
	RESTART,
	FINISH,
	CORRUPT,
}

var update_state: UpdateState = UpdateState.NOT_CHECKED

enum ThreatState {
	HIDDEN,
	FOUND,
	QUARANTINE,
	ALLOW,
}

const ThreatDesc = {
	ThreatState.HIDDEN: "ไม่พบ",
	ThreatState.FOUND: "พบ",
	ThreatState.QUARANTINE: "กักกัน",
	ThreatState.ALLOW: "อนุญาติ",
}

const ThreatColor = { ThreatState.FOUND: C_INK, ThreatState.QUARANTINE: C_OK, ThreatState.ALLOW: C_BAD }


class Threat extends RefCounted:
	var data: DesktopThreat
	var state: ThreatState


	func _init(d: DesktopThreat, s: ThreatState):
		self.data = d
		self.state = s


var threat_list: Array[Threat] = []


func _ready() -> void:
	super._ready()
	os = DesktopOS.new()
	_resolve_task()
	for dir in task.FOLDERS:
		if dir == DesktopTask.USB && !task.usb_drive:
			usb_ejected = false
			continue
		os.create_dir(dir)
	for file in task.files:
		os.add_file(file)
	for p in task.programs:
		var icon: Texture2D = null
		if p.system:
			icon = TEX_SETTINGS
		elif p.adware:
			icon = TEX_ADWARE
		os.installed(p, icon)
	for p in task.printers:
		os.add_printer(p)
	for s in task.sound_devices:
		os.add_sound_device(s)
	for w in task.wifi:
		os.add_wifi(w)
	for t in task.threats:
		var threat = Threat.new(t, ThreatState.HIDDEN)
		threat_list.append(threat)

	os.is_mute = task.sound_muted
	os.set_selected_sound_device(task.sound_device)
	os.change_sound_volumn(task.sound_volume)
	os.selected_scale = os.scale_list.find(task.display_scale)
	if task.unsaved_doc != "":
		var w = load(UNSAVED_DOC).instantiate() as OsWindow2
		w.set_title(task.unsaved_doc + " *ยังไม่บันทึก")
		w.closed.connect(w.queue_free.call_deferred)
		var save_btn = w.get_node("%SaveDoc")
		w.restore(true)
		save_btn.pressed.connect(
			func():
				doc_saved = true
				w.queue_free.call_deferred(),
		)
		screen.add_child(w)
		_ensure_process(w, task.unsaved_doc + " *ยังไม่บันทึก")
	_apply_display(task.display_scale)

	for p in task.processes:
		var w: OsWindow2 = null
		if p.kind == "hang":
			w = WINDOW_BASE.instantiate() as OsWindow2
			var body = w.get_node("%Content") as Control
			w.set_title(p.name + " (ไม่ตอบสนอง)")
			w.set_icon(TEX_EXE)
			w.set_closable(false)
			w.set_bg_color(C_DIM)
			w.restore(true)
			var msg = Label.new()
			msg.text = "กำลังทำงาน...\nโปรแกรมนี้ไม่ตอบสนอง"
			body.add_child(msg)
			screen.add_child(w)
		os.spawn_process(p, w)
	os.process_changed.connect(_refresh_task_manager)

	os.disk_total_mb = task.disk_total_mb
	os.disk_free_mb = task.disk_free_mb
	os.disk_temp_mb = task.temp_mb
	os.disk_free_mb -= os.disk_temp_mb

	clock.text = EventManager.get_clock_text()
	disk.text = "พื้นที่ที่เหลือ %s" % [size_text(os.disk_free_mb)]
	start_button.pressed.connect(self._on_start_button)
	sound.pressed.connect(self._open_sound)

	start_menu = PopupMenu.new()
	start_menu.popup_window = false
	for i in items.size():
		var item = items[i]
		start_menu.add_icon_item(_small(item[1]), item[0], i)

	start_menu.add_separator()
	start_menu.add_item("ปิดเครื่อง" if free_mode else "ปิดเครื่อง (งานยังไม่เสร็จ)", 99)
	start_menu.id_pressed.connect(_on_start_menu)
	doc_icon.button.pressed.connect(open_explorer.bind("เอกสาร"))
	pic_icon.button.pressed.connect(open_explorer.bind("รูปภาพ"))
	download_icon.button.pressed.connect(open_explorer.bind("ดาวน์โหลด"))
	trash_icon.button.pressed.connect(open_explorer.bind(DesktopOS.TRASH))
	browser_icon.button.pressed.connect(open_browser)
	explorer.pressed.connect(open_explorer)
	browser.pressed.connect(open_browser)
	settings.pressed.connect(open_settings)
	wifi.pressed.connect(self._open_wifi)
	_refresh_app_shortcuts()

	_popup_timer.wait_time = popup_every
	_popup_timer.timeout.connect(
		func():
			if has_adware():
				_spawn_popup()
			pass,
	)
	_popup_timer.autostart = true
	self.add_child(_popup_timer)
	self.add_child(start_menu)


func has_adware() -> bool:
	for pname in os.installed_programs:
		var p = os.installed_programs.get(pname) as DesktopOS.App
		if p.data.adware:
			return true
	return false


func _spawn_popup():
	var w = AD_POPUP.instantiate() as OsWindow2
	w.restore(true)
	w.closed.connect(
		func():
			w.queue_free.call_deferred(),
	)
	var btn := w.get_node("%Claim")
	btn.pressed.connect(
		func():
			w.close()
			_trap(&"click_ad", "click_ad", &"safety", 5, "คลิกในหน้าต่างโฆษณา")
			_pib_toast(&"CLICK_AD")
			_spawn_popup(),
	)
	screen.add_child(w)
	pass


func _process(_delta: float) -> void:
	start_button.disabled = start_menu.visible
	if !os.dir_map[os.TRASH].files.is_empty():
		trash_icon.icon = TEX_TRASH_FULL
	else:
		trash_icon.icon = TEX_TRASH


func _on_start_button() -> void:
	start_menu.reset_size()
	var pos = start_button.get_screen_position()
	pos.y -= start_menu.size.y
	start_menu.popup(Rect2i(Vector2i(pos), Vector2i.ZERO))


func _on_start_menu(id: int) -> void:
	match id:
		0:
			open_explorer(DOC_DIR)
		1:
			open_explorer(PIC_DIR)
		2:
			open_explorer(DOWNLOAD_DIR)
		3:
			open_browser()
		4:
			open_settings()
		5:
			open_explorer(TRASH_DIR)
		6:
			open_task_manager()
		7:
			_open_security()
		99:
			_shut_down()


func _on_file_menu(id: int) -> void:
	print("use file menu")
	pass


func _find_window(type: DesktopOS.WinType) -> OsWindow2:
	for w: OsWindow2 in os.instances:
		if w.is_queued_for_deletion() || !w.has_meta("type"):
			continue
		if w.get_meta("type") == type:
			return w
	return null


## หน้าต่างที่ผู้ใช้เปิด — ยังไม่มี pid (เปิดครั้งแรก หรือเคยปิดไปแล้ว) ก็สร้าง process ผูกกับหน้าต่างนี้
func _ensure_process(w: OsWindow2, pname: String) -> void:
	if w.has_meta("pid"):
		return
	var proc := DesktopProcess.new()
	proc.name = pname
	os.spawn_process(proc, w)


# NOTE: Explorer Logic
func open_explorer(folder: String = "เอกสาร") -> void:
	_explorer_folder = folder
	var w := _find_window(DesktopOS.WinType.Explorer)
	if w == null:
		w = EXPLORER_SCENE.instantiate()
		w.set_meta("type", os.WinType.Explorer)
		w.size = DEFAULT_WINDOW_SIZE
		w.restore(true)
		screen.add_child(w)
		os.add_instance(w)
		_setup_explorer(w)
	else:
		w.restore()
	_ensure_process(w, "ไฟล์")
	_refresh_explorer()


## ผูกปุ่ม/รายการในฉาก os_explorer.tscn เข้ากับข้อมูล (ปุ่มโฟลเดอร์สร้างจากแม่แบบ Trash)
func _setup_explorer(w: OsExplorer) -> void:
	w.set_title("ไฟล์ — " + task.pc_name)
	_explorer_win = w
	_explorer_path = w.get_node("%Path")
	_explorer_status = w.get_node("%Status")
	_explorer_list = w.get_node("%FileList")
	_explorer_list.item_activated.connect(
		func(_i):
			_explorer_action("open"),
	)
	_explorer_list.gui_input.connect(_on_explorer_key)

	var side: VBoxContainer = w.get_node("%DirList")
	var trash: Button = w.get_node("%Trash")
	for fo in os.dir_map.keys():
		if fo == DesktopOS.TRASH or (fo == DesktopTask.USB and not task.usb_drive):
			continue

		var b: Button = trash.duplicate()
		b.unique_name_in_owner = false
		b.name = "Folder_" + fo.validate_node_name()
		b.text = "  " + fo
		b.pressed.connect(
			func():
				_explorer_folder = fo
				_refresh_explorer(),
		)
		if fo == DesktopTask.USB:
			_explorer_usb_dir = b
		side.add_child(b)
	side.move_child(trash, -1)
	trash.pressed.connect(
		func():
			_explorer_folder = DesktopOS.TRASH
			_refresh_all(),
	)

	var acts := {
		"Open": "open",
		"Ask": "ask",
		"Delete": "delete",
		"Restore": "restore",
		"CopyUsb": "copy_usb",
		"MoveUsb": "move_usb",
		"Eject": "eject",
	}
	for btn in acts:
		w.get_node("%" + btn).pressed.connect(_explorer_action.bind(acts[btn]))
	for btn in ["CopyUsb", "MoveUsb", "Eject"]:
		w.get_node("%" + btn).visible = task.usb_drive


func _explorer_selected() -> int:
	if not is_instance_valid(_explorer_list):
		return -1
	var sel := _explorer_list.get_selected_items()
	return _explorer_list.get_item_metadata(sel[0]) if not sel.is_empty() else -1


func _explorer_action(what: String) -> void:
	if what == "eject":
		_explorer_status.text = eject_usb()
		_explorer_usb_dir.hide()
		for btn in ["CopyUsb", "MoveUsb", "Eject"]:
			_explorer_win.get_node("%" + btn).visible = false
		return
	var idx := _explorer_selected()
	if what == "delete" && _explorer_folder == DesktopOS.TRASH:
		os.clear_trash()
		_refresh_explorer()
		return
	var f: DesktopFile = os.fs[idx].data if idx >= 0 else null
	if f == null:
		_pib_toast(MinigameHeader.SELECT_FIRST, 2.5)
		return
	match what:
		"open":
			_open_file(f)
		"ask":
			match f.kind:
				DesktopFile.USER:
					customer_say("อันนั้นอย่าลบนะ! ของสำคัญเลย")
				DesktopFile.DUP:
					customer_say("อันนั้นก๊อปไว้ซ้ำแหละ ลบได้เลย")
				DesktopFile.SYSTEM:
					customer_say("ไม่รู้เหมือนกัน มันมีมากับเครื่อง")
				DesktopFile.JUNK:
					customer_say("ไม่รู้จักเลย ไม่เคยใช้")
				_:
					customer_say("อันนั้นโหลดมาเอง")
		"delete":
			if os.move_file(idx, DesktopOS.TRASH):
				_refresh_explorer()
		"restore":
			if os.move_file(idx, os.fs[idx].prev_dir):
				_refresh_explorer()
		"copy_usb":
			_explorer_status.text = copy_to_usb(idx)
		"move_usb":
			_explorer_status.text = move_to_usb(idx)


## WARN: not yet implement: check usb free space
func copy_to_usb(file_idx: int) -> String:
	if task.usb_drive && usb_ejected:
		return "ไม่มี USB เสียบอยู่"
	var copy_data = os.fs[file_idx].data
	if os.find_file(copy_data.name, DesktopTask.USB):
		return "มีไฟล์นี้ใน USB แล้ว"
	var ok = os.add_file(copy_data, DesktopTask.USB)
	if ok > -1:
		_refresh_explorer()

	return "คัดลอก \"%s\" ลง USB แล้ว" % copy_data.name


## WARN: not yet implement: check usb free space
func move_to_usb(file_idx: int) -> String:
	if task.usb_drive && usb_ejected:
		return "ไม่มี USB เสียบอยู่"
	var f = os.fs[file_idx]
	if f.data.kind == "user":
		_trap(
			&"move_not_copy",
			"move_" + String(f.data.name),
			&"safety",
			10,
			"\"ย้าย\" รูปลูกค้าออกจากเครื่อง (ควร \"คัดลอก\")",
		)
		_pib_say(
			"ย้าย = ไฟล์ออกจากเครื่องไปอยู่ใน USB อย่างเดียวนะ สำรองต้อง \"คัดลอก\" ให้มีสองที่",
			PibHint.Mood.WORRY,
		)
	if os.move_file(file_idx, DesktopTask.USB):
		_refresh_explorer()
	return "ย้าย \"%s\" ไป USB แล้ว" % f.data.name


func eject_usb() -> String:
	if task.usb_drive && !usb_ejected:
		return ""
	usb_ejected = true
	if _explorer_folder == DesktopTask.USB:
		_explorer_folder = "เดสก์ท็อป"
	_refresh_all()
	return "ถอด USB ได้อย่างปลอดภัยแล้ว"


func _open_file(f: DesktopFile):
	var msg: String = ""
	match f.kind:
		DesktopFile.USER:
			msg = f.note if f.note != "" else "ไฟล์ของลูกค้า"
		DesktopFile.FAKE_INSTALLER:
			_trap(&"fake_download", "run_fake", &"safety", 5, "เปิดไฟล์จากปุ่มโฆษณา")
			install_adware()
			_refresh_all()
			_pib(&"FAKE_RUN", PibHint.Mood.WORRY)
			msg = "กำลังติดตั้ง… (ไม่มีหน้าให้เลือกอะไรเลย!)"
		DesktopFile.INSTALLER:
			_open_wizard()
		DesktopFile.DUP:
			msg = f.note if f.note != "" else "เปิดดูแล้ว — เหมือนกับ \"%s\" ทุกอย่าง" % f.dup_of
		DesktopFile.SYSTEM:
			msg = f.note if f.note != "" else "ไฟล์ระบบของขมOS — เครื่องต้องใช้ตอนเปิด"
	if msg != "":
		_show_info("เปิด %s" % [f.name], msg, _file_tex(f))


## หน้าต่างข้อความ (os_info.tscn) — ปิดแล้วทิ้งเลย
func _show_info(title: String, msg: String, tex: Texture2D) -> void:
	var w = INFO_WINDOW.instantiate() as OsWindow2
	if w == null:
		push_error("w is OsWindow2")
		return
	w.closed.connect(
		func():
			w.queue_free.call_deferred(),
	)
	w.restore(true)
	w.set_title(title)
	w.set_icon(tex)
	var label = w.get_node("%Message") as Label
	label.text = msg
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var ok := w.get_node("%Ok") as Button
	ok.text = "ตกลง"
	ok.size_flags_horizontal = Control.SIZE_SHRINK_END
	ok.pressed.connect(w.close)
	screen.add_child(w)


## ไอคอนบนเดสก์ท็อปของโปรแกรมที่ติดตั้ง (desktop_icon) — สร้างเพิ่ม/ลบออกให้ตรงกับ os.installed_programs
func _refresh_app_shortcuts() -> void:
	for pname in _app_shortcuts.keys():
		var app = os.installed_programs.get(pname) as DesktopOS.App
		if app == null or not app.data.desktop_icon:
			_app_shortcuts[pname].queue_free()
			_app_shortcuts.erase(pname)
	for pname in os.installed_programs:
		var app = os.installed_programs[pname] as DesktopOS.App
		if not app.data.desktop_icon or _app_shortcuts.has(pname):
			continue
		var s := SHORTCUT_SCENE.instantiate() as DesktopShortcut
		s.name = "App_" + pname.validate_node_name()
		s.icon = app.icon if app.icon else TEX_EXE
		s.shortcut_name = pname
		desktop.add_child(s)
		s.button.pressed.connect(_open_program.bind(pname))
		_app_shortcuts[pname] = s


## ดับเบิลคลิกไอคอนโปรแกรมบนเดสก์ท็อป
func _open_program(pname: String) -> void:
	var app = os.installed_programs.get(pname) as DesktopOS.App
	if app == null:
		return
	if app.data.adware:
		_show_info(pname, "🎁 ยินดีด้วย! คุณได้รับสิทธิ์พิเศษ!\nกดรับรางวัลในหน้าต่างที่เด้งขึ้นมาได้เลย", app.icon)
		_spawn_popup()
	elif app.data.app:
		_show_info(pname, "ยังไม่มีข้อความใหม่\nล่าสุด: ยายส่งสติกเกอร์รูปดอกไม้มา \"กินข้าวยังลูก\"", app.icon)
		if not free_mode:
			customer_say("เปิดได้แล้ว! เดี๋ยวคืนนี้โทรหาหลานเลย")
	else:
		_show_info(pname, "%s\nผู้พัฒนา: %s" % [pname, app.data.publisher], app.icon)


func _refresh_explorer() -> void:
	if not is_instance_valid(_explorer_list):
		return
	_explorer_list.clear()
	_explorer_path.text = "เครื่องนี้ > " + _explorer_folder
	_explorer_win.show_action_bar_preset(OsExplorer.TRASH if _explorer_folder == DesktopOS.TRASH else OsExplorer.NORM)
	if free_mode:
		_explorer_win.ask_action.hide()
	var dir: DesktopOS.Dir = os.dir_map.get(_explorer_folder)
	var count := 0
	if dir != null:
		for idx in dir.files:
			var f := os.fs[idx].data
			var i := _explorer_list.add_item("%s      %s" % [f.name, size_text(f.size_mb)], _file_tex(f))
			_explorer_list.set_item_metadata(i, idx)
			if f.kind == DesktopFile.FAKE_INSTALLER:
				_explorer_list.set_item_custom_fg_color(i, Color(0.8, 0.3, 0.1))
			count += 1
	_explorer_status.text = "%d รายการ · เหลือ %s" % [count, size_text(os.disk_free_mb)]


func _on_explorer_key(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_DELETE:
		_explorer_action("delete")
		_explorer_list.accept_event()


func size_text(mb: int) -> String:
	if absi(mb) >= 1000:
		return "%.1f GB" % (mb / 1000.0)
	return "%d MB" % mb


# NOTE: Browser Logic
func open_browser() -> void:
	var w := _find_window(DesktopOS.WinType.Browser)
	if w == null:
		w = BROWSER_SCENE.instantiate()
		w.restore(true)
		w.set_meta("type", os.WinType.Browser)
		w.size = DEFAULT_WINDOW_SIZE
		_browser_page = w.get_node("%Page")
		_browser_addr = w.get_node("%Address")
		screen.add_child(w)
		os.add_instance(w)
	else:
		w.restore()
	_ensure_process(w, "เบราว์เซอร์")
	_browser_show(BROWSER_HOME)


func _browser_show(page: String) -> void:
	if not is_instance_valid(_browser_page):
		return
	for c in _browser_page.get_children():
		c.queue_free()
	var is_install := task.goal == DesktopTask.Goal.INSTALL and not free_mode
	if page == BROWSER_OFFICIAL:
		var p = load(BROWSER_OFFICIAL_SCENE).instantiate()
		_browser_addr.text = "🔒 https://" + task.install_site
		_browser_page.add_child(p)
		var app_name: Label = p.get_node("%AppName")
		var desc: Label = p.get_node("Description")
		var download: Button = p.get_node("%Download")
		app_name.text = task.install_name
		desc.text = task.install_description
		download.pressed.connect(
			func():
				if download_official():
					_pib_toast(MinigameHeader.OFFICIAL_DONE, 3.0)
				open_explorer(DOWNLOAD_DIR),
		)
		return
	if task.browser_ad:
		var ad = load(BROWSER_AD_SCENE).instantiate()
		var btn = ad.get_node("%AdDownload") as Button
		btn.pressed.connect(
			func():
				click_download_ad()
				open_explorer(DOWNLOAD_DIR),
		)
		_browser_page.add_child(ad)
	if is_install:
		var result = load(BROWSER_RESULT_SCENE).instantiate() as Control
		var link = result.get_node("%Link") as LinkButton
		var url = result.get_node("%Url") as Label
		link.text = "%s — ดาวน์โหลดโปรแกรม (เว็บทางการ)" % task.install_name
		link.pressed.connect(self._browser_show.bind(BROWSER_OFFICIAL))
		url.text = task.install_site
		_browser_page.add_child(result)

		result = load(BROWSER_RESULT_SCENE).instantiate() as Control
		link = result.get_node("%Link") as LinkButton
		url = result.get_node("%Url") as Label
		link.text = "รวมโปรแกรมฟรี 2569 โหลดได้ทุกตัว!!"
		link.pressed.connect(
			func():
				click_download_ad()
				open_explorer(DOWNLOAD_DIR),
		)
		url.text = "freeprogram-zz.biz/โหลดฟรี"
		_browser_page.add_child(result)
	else:
		var news = Label.new()
		var weather = Label.new()
		news.text = "ข่าววันนี้: ตลาดนัดหน้าวัดเลื่อนเป็นวันเสาร์"
		weather.text = "พยากรณ์อากาศ: ฝนตกบ่าย ๆ เก็บผ้าด้วย"
		_browser_page.add_child(news)
		_browser_page.add_child(weather)


## คืน true ถ้าดาวน์โหลดไฟล์ใหม่ · false ถ้ามีไฟล์ชื่อนี้ในโฟลเดอร์ดาวน์โหลดอยู่แล้ว (ปิ๊บบอกแล้ว ไม่โหลดซ้ำ ไม่หักคะแนนซ้ำ)
func click_download_ad() -> bool:
	var fname := "DOWNLOAD_NOW_ฟรี.exe"
	if os.find_file(fname, DOWNLOAD_DIR):
		_pib_toast(MinigameHeader.ALREADY_DOWNLOADED, 3.0)
		return false
	_trap(&"fake_download", "ad_button", &"safety", 10, "กดปุ่มดาวน์โหลดที่เป็นโฆษณา")
	var f := DesktopFile.new()
	f.name = fname
	f.size_mb = 3
	f.kind = DesktopFile.FAKE_INSTALLER
	f.folder = DesktopFile.Folder.DOWNLOADS
	os.add_file(f)
	return true


## คืน true ถ้าดาวน์โหลดไฟล์ใหม่ · false ถ้ามีไฟล์ชื่อนี้ในโฟลเดอร์ดาวน์โหลดอยู่แล้ว
func download_official() -> bool:
	var fname := "setup_%s.exe" % task.install_name
	if os.find_file(fname, DOWNLOAD_DIR):
		_pib_toast(MinigameHeader.ALREADY_DOWNLOADED, 3.0)
		return false
	var f := DesktopFile.new()
	f.name = fname
	f.size_mb = 95
	f.kind = DesktopFile.INSTALLER
	f.folder = DesktopFile.Folder.DOWNLOADS
	os.add_file(f)
	return true


## วิซาร์ดติดตั้ง (เปิดจากไฟล์ setup_*.exe) — หน้า Page0..Page3 วางไว้ใน os_wizard.tscn แล้ว
func _open_wizard() -> void:
	var w := WIZARD_SCENE.instantiate() as OsWindow2
	w.set_title("ติดตั้ง " + task.install_name)
	w.closed.connect(
		func():
			w.queue_free.call_deferred(),
	)
	w.restore(true)
	screen.add_child(w)
	_ensure_process(w, "installer")
	_wizard_page(w, 0, true)


## โชว์หน้า page (ซ่อนหน้าอื่น) แล้วผูกปุ่ม %Next ใหม่ · bundle = ยังติ๊กโปรแกรมแถมอยู่
func _wizard_page(w: OsWindow2, page: int, bundle: bool) -> void:
	if !is_instance_valid(w):
		return
	for i in 4:
		w.get_node("%%Page%d" % i).visible = i == page
	var next := w.get_node("%Next") as Button
	for c in next.pressed.get_connections():
		next.pressed.disconnect(c.callable)
	next.show()
	match page:
		0:
			(w.get_node("%Welcome") as Label).text = "ยินดีต้อนรับสู่ตัวติดตั้ง %s" % task.install_name
			next.text = "ถัดไป ›"
			next.pressed.connect(self._wizard_page.bind(w, 1, bundle))
		1:
			(w.get_node("%CoreCheck") as CheckBox).text = "%s (จำเป็น)" % task.install_name
			var check := w.get_node("%BundleCheck") as CheckBox
			check.text = "ติดตั้ง \"%s\" ด้วย (แนะนำ!) — ผู้สนับสนุน" % task.bundle_name
			check.button_pressed = bundle
			next.text = "ติดตั้ง"
			next.pressed.connect(
				func():
					_wizard_page(w, 2, check.button_pressed),
			)
		2:
			next.hide()
			w.set_closable(false)
			var bar := w.get_node("%Progress") as ProgressBar
			bar.value = 0.0
			# NOTE: tween ผูกกับหน้าต่าง — หน้าต่างหายไป tween ก็หยุดด้วย
			var tw := w.create_tween()
			tw.tween_property(bar, "value", 100.0, 1.2)
			tw.tween_callback(
				func():
					install_app(bundle)
					w.set_closable(true)
					_wizard_page(w, 3, bundle),
			)
		3:
			(w.get_node("%Done") as Label).text = "ติดตั้ง %s เสร็จแล้ว" % task.install_name
			next.text = "เสร็จ"
			next.pressed.connect(w.close)


## วิซาร์ดติดตั้งจบ · with_bundle = ไม่ได้เอาติ๊กโปรแกรมแถมออก
func install_app(with_bundle: bool) -> void:
	if not os.installed_programs.has(task.install_name):
		var p := DesktopProgram.new()
		p.name = task.install_name
		p.publisher = task.install_site
		p.size_mb = task.install_size_mb
		p.desktop_icon = true
		p.app = true
		os.installed(p, TEX_CHAT)
	if with_bundle:
		_trap(&"bundle", "bundle", &"safety", 10, "ลืมเอาติ๊กโปรแกรมแถมออกตอนติดตั้ง")
		install_adware()
	_refresh_all()


## ลงโปรแกรมโฆษณา (จากโปรแกรมแถมในวิซาร์ด หรือเปิดไฟล์ปลอมจากโฆษณา)
func install_adware() -> void:
	if os.installed_programs.has(task.bundle_name):
		return
	var p := DesktopProgram.new()
	p.name = task.bundle_name
	p.publisher = "Super Deal Co."
	p.size_mb = ADWARE_SIZE_MB
	p.adware = true
	p.desktop_icon = true
	os.installed(p, TEX_ADWARE)


# NOTE: Task Manager Logic
func open_task_manager():
	var w = _find_window(DesktopOS.WinType.TaskManager)
	if w == null:
		w = TASKMANAGER_SCENE.instantiate() as OsWindow2
		w.set_meta("type", DesktopOS.WinType.TaskManager)
		w.restore(true)
		_proc_panel = w.get_node("%Proc")
		_autostart_panel = w.get_node("%AutoStart")
		var tab_proc = w.get_node("%TabProc") as Button
		var tab_autostart = w.get_node("%TabStartup") as Button
		tab_proc.pressed.connect(
			func():
				_proc_panel.show()
				_autostart_panel.hide()
				tab_proc.disabled = true
				tab_autostart.disabled = false
				_refresh_task_manager(),
		)
		tab_autostart.pressed.connect(
			func():
				_proc_panel.hide()
				_autostart_panel.show()
				tab_proc.disabled = false
				tab_autostart.disabled = true
				_refresh_task_manager(),
		)
		screen.add_child(w)
		os.add_instance(w)
	else:
		w.restore()
	_ensure_process(w, "ตัวจัดการงาน")
	_refresh_task_manager()


func _refresh_task_manager():
	# NOTE: ยังไม่เคยเปิดตัวจัดการงาน — ไม่มีอะไรให้รีเฟรช
	if not is_instance_valid(_proc_panel):
		return
	var info_row = load(INFO_ROW)
	if _proc_panel.visible:
		var list := _proc_panel.get_node("List") as VBoxContainer
		for c in list.get_children():
			c.queue_free()
		for pid in os.process_map:
			var proc = os.process_map[pid] as DesktopOS.Process
			var node = info_row.instantiate() as Control
			var info = node.get_node("%Info") as Label
			var btn = node.get_node("%Primary") as Button
			info.text = "%s\n%s · %s · ซีพียู %d%%" % [proc.data.name, proc.status, proc.kind, int(proc.data.cpu)]
			info.add_theme_color_override("font_color", C_BAD if proc.data.kind == "hang" else C_INK)
			btn.text = "จบการทำงาน"
			# NOTE: kill_process ยิง process_changed → รีเฟรชรายการเอง
			btn.pressed.connect(
				func():
					if _check_process(pid):
						os.kill_process(pid),
			)
			list.add_child(node)
	else:
		var list = _autostart_panel.get_node("List") as VBoxContainer
		for c in list.get_children():
			c.queue_free()
		var msg = Label.new()
		msg.text = "เปิดเครื่องใช้เวลา ~%d วินาที" % os.boot_time()
		msg.add_theme_color_override("font_color", C_INK)
		list.add_child(msg)
		for pid in os.autostart_map:
			var proc = os.process_map[pid] as DesktopOS.Process
			var node = info_row.instantiate() as Control
			var info = node.get_node("%Info") as Label
			var btn = node.get_node("%Primary") as Button
			var impact := "สูง" if int(proc.data.boot_s) >= 6 else ("กลาง" if int(proc.data.boot_s) >= 3 else "ต่ำ")
			info.text = "%s%s\nผลต่อการเปิดเครื่อง: %s · %s" % [
				proc.data.name,
				"  (ระบบ)" if proc.data.kind == "system" else "",
				impact,
				"เปิดอยู่" if proc.autostart else "ปิดแล้ว",
			]
			btn.text = "ปิด" if proc.autostart else "เปิด"
			btn.pressed.connect(
				func():
					if !_set_autostart(pid, !proc.autostart):
						return
					msg.text = "เปิดเครื่องใช้เวลา ~%d วินาที" % os.boot_time()
					info.text = "%s%s\nผลต่อการเปิดเครื่อง: %s · %s" % [
						proc.data.name,
						"  (ระบบ)" if proc.data.kind == "system" else "",
						impact,
						"เปิดอยู่" if proc.autostart else "ปิดแล้ว",
					]
					btn.text = "ปิด" if proc.autostart else "เปิด",
			)
			list.add_child(node)


func _set_autostart(pid: int, enable: bool) -> bool:
	var p = os.process_map.get(pid) as DesktopOS.Process
	if p == null:
		return false
	if !enable && p.data.kind == "system":
		_trap(
			&"disable_system",
			"nostart_" + String(p.data.name),
			&"safety",
			10,
			"ปิด %s ไม่ให้เปิดพร้อมเครื่อง" % p.data.name,
		)
		_pib_say(
			"%s ต้องเปิดพร้อมเครื่องนะ ไม่งั้นเครื่องไม่ปลอดภัยหรือทำงานได้ไม่เต็มประสิทธิภาพ" % p.data.name,
			PibHint.Mood.WORRY,
		)
		return false
	p.autostart = enable
	return true


func _check_process(pid: int) -> bool:
	var p = os.process_map[pid]
	match String(p.data.kind):
		"system":
			_trap(
				&"kill_system",
				"kill_" + String(p.data.name),
				&"safety",
				10,
				"ปิดโปรแกรมของระบบ (%s) เครื่องจอฟ้า" % p.data.name,
			)
			_pib_say("อันนั้นของระบบ! ปิดแล้วเครื่องล่มเลย ดูคอลัมน์ประเภทก่อนนะ", PibHint.Mood.WORRY)
			return false
		"unsaved":
			_trap(
				&"kill_unsaved",
				"kill_" + String(p.data.name),
				&"listen",
				10,
				"ปิดงานที่ลูกค้ายังไม่บันทึก (%s)" % p.data.name,
			)
			# m.lost_user_file = true
			# m._refresh_note() # [13 ต.ค.] โชว์ปุ่ม "ส่งงานตามสภาพ"
			_pib_say("อ๊ะ! อันนั้นลูกค้ายังใช้อยู่ ข้อมูลที่ยังไม่บันทึกหายหมดแล้ว", PibHint.Mood.WORRY)
			return true
	if p.kind == "hang" and is_instance_valid(p.instance):
		_pib_say("ปิดได้แล้ว เปิดโปรแกรมใหม่ก็ใช้ได้ปกติ")
	return true


# NOTE: Setting Logic
func open_settings() -> void:
	var w = _find_window(DesktopOS.WinType.Settings)
	if w == null:
		w = SETTING_SCENE.instantiate()
		w.set_meta("type", DesktopOS.WinType.Settings)
		_settings_progress_bar = w.get_node("%DiskBar") as ProgressBar
		_settings_progress_bar.max_value = os.disk_total_mb
		_settings_progress_bar.value = os.disk_total_mb - os.disk_free_mb

		_settings_disk_label = w.get_node("%DiskLabel") as Label
		_settings_disk_label.text = "%s / %s" % [
			size_text(os.disk_total_mb - os.disk_free_mb),
			size_text(os.disk_total_mb),
		]
		w.restore(true)
		_settings_installed_list = w.get_node("%Apps")
		var printer_btn = w.get_node("%SecPrinters") as Button
		var sound_btn = w.get_node("%SecSound") as Button
		var wifi_btn = w.get_node("%SecWifi") as Button
		var display_btn = w.get_node("%SecDisplay") as Button
		var update_btn = w.get_node("%SecUpdate") as Button
		var security_btn = w.get_node("%SecSecurity") as Button
		printer_btn.pressed.connect(self._open_printer)
		sound_btn.pressed.connect(self._open_sound)
		wifi_btn.pressed.connect(self._open_wifi)
		display_btn.pressed.connect(self._open_display)
		update_btn.pressed.connect(self._open_update)
		security_btn.pressed.connect(self._open_security)
		screen.add_child(w)
		os.add_instance(w)
	else:
		w.restore()
	_ensure_process(w, "ตั้งค่า")
	_refresh_setting()


func _refresh_setting() -> void:
	# NOTE: ยังไม่เคยเปิดหน้าต่างตั้งค่า — ไม่มีอะไรให้รีเฟรช
	if not is_instance_valid(_settings_installed_list):
		return
	_settings_progress_bar.max_value = os.disk_total_mb
	_settings_progress_bar.value = os.disk_total_mb - os.disk_free_mb
	_settings_disk_label.text = "%s / %s" % [size_text(os.disk_total_mb - os.disk_free_mb), size_text(os.disk_total_mb)]
	for c in _settings_installed_list.get_children():
		c.queue_free()
	var app_node = load(INSTALLED_APP)
	for pname in os.installed_programs:
		var app = app_node.instantiate()
		var p = os.installed_programs.get(pname)
		if p == null:
			continue
		var icon = app.get_node("%Icon") as TextureRect
		var pinfo = app.get_node("%Info") as Label
		var btn = app.get_node("%Uninstall") as Button
		icon.texture = p.icon
		pinfo.text = "%s \n %s, %d mb" % [pname, p.data.publisher, p.data.size_mb]
		btn.pressed.connect(
			func():
				if os.uninstalled(pname):
					_pib_toast("UNINSTALLED", 2)
					_refresh_all(),
		)
		_settings_installed_list.add_child(app)


# NOTE: Printer's Setting Logic
func _open_printer() -> void:
	var w = _find_window(DesktopOS.WinType.Printer)
	if w == null:
		w = load(PRINTERS_SETTING).instantiate() as OsWindow2
		w.restore(true)
		w.set_meta("type", DesktopOS.WinType.Printer)
		os.add_instance(w)
		w.closed.connect(
			func():
				w.queue_free.call_deferred()
				os.instances.erase(w),
		)
		_printer_install_list = w.get_node("%Installed")
		_printer_found_list = w.get_node("%Found")
		_print_test_result = w.get_node("%Result")
		_printer_test_btn = w.get_node("%PrintTest")
		_printer_empty_text = w.get_node("%Empty")
		_printer_test_btn.pressed.connect(
			func():
				_print_test_result.text = os.print_test(),
		)
		screen.add_child(w)
	else:
		w.restore()
	_ensure_process(w, "เครื่องพิมพ์")
	_refresh_printer()


func _refresh_printer() -> void:
	var info_node = load(INFO_ROW)
	for c in _printer_install_list.get_children():
		c.queue_free()
	for c in _printer_found_list.get_children():
		c.queue_free()

	for id in os.printer_map:
		var printer = os.printer_map.get(id) as DesktopOS.Printer
		var node = info_node.instantiate()
		var info = node.get_node("%Info") as Label
		var btn1 = node.get_node("%Primary") as Button
		var btn2 = node.get_node("%Secondary") as Button
		if printer.is_install:
			info.text = printer.data.name
			if os.printer_default_index == id:
				info.text += "  ✓ ค่าเริ่มต้น"
			btn1.text = "ตั้งเป็นค่าเริ่มต้น"
			btn1.pressed.connect(
				func():
					if !os.set_default_printer(id):
						return
					_refresh_printer(),
			)
			btn2.text = "ลบ"
			btn2.show()
			btn2.pressed.connect(
				func():
					os.remove_printer(id)
					_refresh_printer(),
			)
			_printer_install_list.add_child(node)
		else:
			info.text = "%s\n%s" % [printer.data.name, printer.data.note]
			btn1.text = "เพิ่ม"
			btn1.pressed.connect(
				func():
					var ok := os.include_printer(id)
					if !ok:
						_trap(
							&"wrong_printer",
							"printer_" + String(printer.data.name),
							&"fix",
							10,
							"เพิ่มเครื่องพิมพ์ผิดเครื่อง (%s)" % printer.data.name,
						)
						_pib_say("เครื่องนั้นไม่ใช่ของห้องนี้นะ ดูชื่อให้ตรงกับที่ลูกค้าบอก", PibHint.Mood.WORRY)
					_refresh_printer(),
			)
			_printer_found_list.add_child(node)


# NOTE: Sound's Setting Logic
func _open_sound() -> void:
	var w = _find_window(DesktopOS.WinType.Sound)
	if w == null:
		w = load(SOUND_SETTING).instantiate() as OsWindow2
		w.set_meta("type", DesktopOS.WinType.Sound)
		os.add_instance(w)
		w.closed.connect(
			func():
				w.queue_free.call_deferred()
				os.instances.erase(w),
		)
		var device_list = w.get_node("%Device") as OptionButton
		var mute = w.get_node("%Mute") as CheckBox
		var volume_slider = w.get_node("%Volume") as HSlider
		var volume_label = w.get_node("%VolumeLabel") as Label
		var test_btn = w.get_node("%Test") as Button
		var result_text = w.get_node("%Result") as Label
		for dev in os.sound_dev_list:
			device_list.add_item(dev.name)
		device_list.selected = os.selected_sound_dev
		device_list.item_selected.connect(os.set_selected_sound_device)
		mute.toggle_mode = os.is_mute
		mute.pressed.connect(
			func():
				os.is_mute = !os.is_mute,
		)
		volume_slider.min_value = 0
		volume_slider.max_value = 100
		volume_slider.value = os.sound_volume
		volume_slider.step = 1
		volume_slider.value_changed.connect(
			func(value: float):
				os.change_sound_volumn(int(value))
				volume_label.text = str(os.sound_volume),
		)
		volume_label.text = str(os.sound_volume)
		test_btn.pressed.connect(
			func():
				result_text.text = test_sound(),
		)
		w.restore(true)
		screen.add_child(w)
	else:
		w.restore()
	_ensure_process(w, "เสียง")


func test_sound() -> String:
	sound_tested = true
	var dev = os.sound_dev_list.get(os.selected_sound_dev) as DesktopSoundDevice
	if task.sound_devices.is_empty() || dev == null:
		return "♪ ติ๊ง! มีเสียงออกลำโพงแล้ว"
	if !os.installed_programs.has("ไดรเวอร์เสียง"):
		return "ไม่มีไดรเวอร์เสียง เครื่องไม่รู้จักลำโพงเลย"
	if os.is_mute:
		return "เงียบ… (ปิดเสียงอยู่)"
	if os.sound_volume < 20:
		return "เบามากจนไม่ได้ยิน"
	if dev.works:
		return "♪ ติ๊ง! มีเสียงออกลำโพงแล้ว"
	return "เงียบ… เสียงไปออกที่ \"%s\"" % dev.name


# NOTE: Wifi's Setting Logic
func _open_wifi() -> void:
	var w = _find_window(DesktopOS.WinType.Wifi)
	if w == null:
		w = load(WIFI_SETTING).instantiate() as OsWindow2
		w.set_meta("type", DesktopOS.WinType.Wifi)
		os.add_instance(w)
		w.closed.connect(
			func():
				w.queue_free.call_deferred()
				os.instances.erase(w),
		)
		w.restore(true)
		screen.add_child(w)
	else:
		w.restore()
	_ensure_process(w, "Wi-Fi")
	_refresh_wifi(w)


func _refresh_wifi(w):
	var network_info = load(NET_INFO)
	var network_container = w.get_node("%Networks") as VBoxContainer
	var status = w.get_node("%Status") as Label
	var msg = w.get_node("%Message") as Label
	for n in network_container.get_children():
		n.queue_free()
	status.text = os.network_status()
	status.add_theme_color_override("font_color", C_BAD if os.connected_network < 0 else C_OK)
	msg.visible = false
	for net in os.wifi_detected:
		var node = network_info.instantiate() as Control
		var info = node.get_node("%Info") as Label
		var password_input = node.get_node("%Password") as LineEdit
		var connect_btn = node.get_node("%Connect") as Button
		info.text = "%s %s\n%s" % [
			net.data.name,
			"▮".repeat(net.data.signal_level),
			"ต้องใส่รหัส" if net.data.locked else "ไม่ต้องใส่รหัส (สาธารณะ)",
		]
		password_input.visible = net.data.locked
		connect_btn.text = "เชื่อมต่อ" if !net.is_connected else "ตัดการเชื่อมต่อ"
		connect_btn.pressed.connect(
			func():
				if net.is_connected:
					os.wifi_disconnect()
					_refresh_wifi(w)
					return
				var ok = os.wifi_connect(net, password_input.text)
				msg.visible = !ok
				if !ok:
					return
				if !net.data.right:
					_trap(
						&"open_wifi",
						"wifi_" + net.data.name,
						&"safety",
						10,
						"ต่อ Wi-Fi สาธารณะที่ไม่มีรหัส (%s)" % net.data.name,
					)
					_pib_say("เน็ตฟรีไม่มีรหัสแบบนี้ ใครก็แอบดูข้อมูลได้ ใช้เน็ตบ้านลูกค้าดีกว่า", PibHint.Mood.WORRY)
				_refresh_wifi(w),
		)
		network_container.add_child(node)


# NOTE: Display's Setting Logic
func _open_display() -> void:
	var w = _find_window(DesktopOS.WinType.Display)
	if w == null:
		w = load(DISPLAY_SETTING).instantiate() as OsWindow2
		w.set_meta("type", DesktopOS.WinType.Display)
		os.add_instance(w)
		w.restore(true)
		w.closed.connect(
			func():
				w.queue_free.call_deferred()
				os.instances.erase(w),
		)
		var opt = w.get_node("%Options") as Control
		var resolutions_opt = w.get_node("%Resolution") as OptionButton
		var scale_opt = w.get_node("%Scale") as OptionButton
		var pending = w.get_node("%Pending") as Control
		var pending_msg = w.get_node("%PendingMessage") as Control
		var keep_btn = w.get_node("%Keep") as Button
		var revert_btn = w.get_node("%Revert") as Button
		for r in task.resolutions:
			var opt_str = r.name
			if r.best:
				opt_str += " (แนะนำ)"
			resolutions_opt.add_item(opt_str)
		for s in os.scale_list:
			var opt_str = str(s)
			if task.display_scale_best == s:
				opt_str += " (แนะนำ)"
			scale_opt.add_item(opt_str)
		scale_opt.selected = os.selected_scale
		keep_btn.pressed.connect(
			func():
				keep_resolution(true)
				opt.show()
				pending.hide()
				resolutions_opt.selected = os.selected_resolution,
		)
		revert_btn.pressed.connect(
			func():
				keep_resolution(false)
				opt.show()
				pending.hide()
				resolutions_opt.selected = os.selected_resolution,
		)
		resolutions_opt.item_selected.connect(
			func(index: int):
				if !task.resolutions[index].ok:
					os.pending_resolution = index
					opt.hide()
					pending.show()
					pending_msg.text = "จอดับ… \"%s\" — จอนี้แสดงไม่ได้\nจะเก็บค่านี้ไว้ไหม?" % task \
							.resolutions[os.pending_resolution] \
							.name
				else:
					os.selected_resolution = index
					_apply_display(os.scale_list[os.selected_scale]),
		)
		scale_opt.item_selected.connect(
			func(index: int):
				os.selected_scale = index
				_apply_display(os.scale_list[index]),
		)
		screen.add_child(w)
	else:
		w.restore()
	_ensure_process(w, "จอภาพ")


func _apply_display(scale_pct: float) -> void:
	if task.goal != DesktopTask.Goal.DISPLAY:
		return
	var f := scale_pct / 100.0
	if !task.resolutions.is_empty() && !task.resolutions[os.selected_resolution].best:
		f *= 1.35
	desktop.scale = Vector2.ONE * clampf(f, 1.0, 2.0)


func keep_resolution(keep: bool) -> void:
	if os.pending_resolution < 0:
		return
	if keep:
		_trap(&"bad_resolution", "badres", &"fix", 10, "เก็บความละเอียดที่จอไม่รองรับ (จอดำ)")
		_pib_say("จอดำเลย! ความละเอียดที่จอไม่รองรับต้องกดคืนค่าเดิม เลือกอันที่มีคำว่าแนะนำ", PibHint.Mood.WORRY)
	os.pending_resolution = -1


# NOTE: Update's settings
func _open_update() -> void:
	var w = _find_window(DesktopOS.WinType.Update)
	if w == null:
		w = load(UPDATED_SETTING).instantiate() as OsWindow2
		w.set_meta("type", DesktopOS.WinType.Update)
		w.restore(true)
		os.add_instance(w)
		w.closed.connect(
			func():
				w.queue_free.call_deferred()
				os.instances.erase(w),
		)

		var check_btn = w.get_node("%Check") as Button
		var install_btn = w.get_node("%Install") as Button
		var poweroff_btn = w.get_node("%PowerOff") as Button
		var restart_btn = w.get_node("%Restart") as Button
		check_btn.pressed.connect(
			func():
				update_state = UpdateState.FOUND
				_refresh_update(w),
		)
		install_btn.pressed.connect(
			func():
				update_state = UpdateState.INSTALL
				_refresh_update(w)
				var tw = self.create_tween()
				tw.tween_interval(3.0)
				tw.tween_callback(self._finish_install.bind(w)),
		)
		poweroff_btn.pressed.connect(self._power_off_during_update.bind(w))
		restart_btn.pressed.connect(self._restart_now)
		screen.add_child(w)
	else:
		w.restore()
	_ensure_process(w, "อัปเดต")
	_refresh_update(w)


func _refresh_update(w: OsWindow2):
	var status_text = ""
	match update_state:
		UpdateState.NOT_CHECKED:
			status_text = "ยังไม่ได้ตรวจหาอัปเดต"
		UpdateState.FOUND:
			status_text = "พบอัปเดตความปลอดภัย ขนาด %s" % size_text(task.update_mb)
		UpdateState.INSTALL:
			status_text = "กำลังติดตั้ง… ห้ามปิดเครื่อง"
		UpdateState.RESTART:
			status_text = "ติดตั้งเสร็จ ต้องรีสตาร์ตเพื่อให้ใช้งานได้"
		UpdateState.FINISH:
			status_text = "เครื่องเป็นเวอร์ชันล่าสุดแล้ว ✓"
		UpdateState.CORRUPT:
			status_text = "อัปเดตล้มเหลว (เครื่องถูกปิดระหว่างติดตั้ง) — ตรวจหาใหม่"
		_:
			push_error("Should not go to this route")
	var status = w.get_node("%Status") as Label
	var check_btn = w.get_node("%Check") as Button
	var install_btn = w.get_node("%Install") as Button
	var pb = w.get_node("%Progress") as ProgressBar
	var poweroff_btn = w.get_node("%PowerOff") as Button
	var restart_btn = w.get_node("%Restart") as Button
	status.text = status_text
	check_btn.hide()
	install_btn.hide()
	pb.hide()
	poweroff_btn.hide()
	restart_btn.hide()
	if update_state in [UpdateState.NOT_CHECKED, UpdateState.CORRUPT]:
		check_btn.show()
	elif update_state == UpdateState.FOUND:
		install_btn.show()
	elif update_state == UpdateState.INSTALL:
		pb.show()
		poweroff_btn.show()
		pb.show_percentage = false
		pb.value = 0
		create_tween().tween_property(pb, "value", 100.0, 3.0)
	elif update_state == UpdateState.RESTART:
		restart_btn.show()


func _finish_install(w) -> void:
	if update_state == UpdateState.INSTALL:
		update_state = UpdateState.RESTART
		_refresh_update(w)


func _power_off_during_update(w) -> void:
	if update_state != UpdateState.INSTALL:
		return
	_trap(&"interrupt_update", "interrupt", &"safety", 10, "ปิดเครื่องตอนกำลังอัปเดต")
	update_state = UpdateState.CORRUPT
	_pib_say("ห้ามปิดเครื่องตอนอัปเดตเด็ดขาด! ระบบเสียหายได้ ต้องตรวจหาใหม่", PibHint.Mood.WORRY)
	_refresh_update(w)


func _open_security() -> void:
	var w = _find_window(DesktopOS.WinType.Security)
	if w == null:
		w = load(SECURITY_SETTING).instantiate() as OsWindow2
		w.set_meta("type", DesktopOS.WinType.Security)
		w.restore(true)
		os.add_instance(w)
		var protection_check = w.get_node("%Protection") as CheckBox
		var scan_btn = w.get_node("%Scan") as Button
		var clean_btn = w.get_node("%CleanTemp") as Button
		protection_check.button_pressed = protection_on
		protection_check.toggled.connect(
			func(toggled_on: bool):
				protection_on = toggled_on,
		)
		scan_btn.pressed.connect(
			func():
				if !protection_on:
					return
				for t in threat_list:
					if t.state == ThreatState.HIDDEN:
						t.state = ThreatState.FOUND
				_refresh_security(w),
		)
		clean_btn.pressed.connect(
			func():
				os.disk_free_mb += os.disk_temp_mb
				os.disk_temp_mb = 0
				_refresh_all()
				_refresh_security(w),
		)
		screen.add_child(w)
	else:
		w.restore()
	_ensure_process(w, "security")
	_refresh_security(w)


func _refresh_security(w) -> void:
	var threat_container = w.get_node("%Threats") as VBoxContainer
	var temp_label = w.get_node("%TempLabel") as Label
	for c in threat_container.get_children():
		c.queue_free()
	var info = load(INFO_ROW)
	for t in threat_list:
		if t.state == ThreatState.HIDDEN:
			continue
		var st: String = ThreatDesc.get(t.state)
		var node = info.instantiate()
		var info_label = node.get_node("%Info") as Label
		var quarantine_btn = node.get_node("%Primary") as Button
		var allow_btn = node.get_node("%Secondary") as Button
		info_label.text = "%s\n%s · %s" % [t.data.name, t.data.where, st]
		info_label.add_theme_color_override("font_color", ThreatColor[t.state])
		quarantine_btn.text = "กักกัน"
		allow_btn.text = "อนุญาติ"
		quarantine_btn.visible = t.state in [ThreatState.FOUND, ThreatState.ALLOW]
		allow_btn.visible = t.state in [ThreatState.FOUND, ThreatState.QUARANTINE]
		quarantine_btn.pressed.connect(
			func():
				t.state = ThreatState.QUARANTINE
				_refresh_security(w),
		)
		allow_btn.pressed.connect(
			func():
				_trap(&"allow_threat", "allow_" + t.data.name, &"safety", 10, "กดอนุญาตไวรัส (%s)" % t.data.name)
				_pib_say("อนุญาต = ปล่อยให้ไวรัสอยู่ต่อนะ! ต้องกักกัน", PibHint.Mood.WORRY)
				t.state = ThreatState.ALLOW
				_refresh_security(w),
		)
		threat_container.add_child(node)
	temp_label.text = "ไฟล์ชั่วคราว: %s" % [size_text(os.disk_temp_mb)]


func _refresh_all():
	_refresh_explorer()
	_refresh_setting()
	_refresh_app_shortcuts()
	disk.text = "พื้นที่ที่เหลือ %s" % [size_text(os.disk_free_mb)]


func _shut_down() -> void:
	if !free_mode || step == Step.DONE:
		return
	# WARN: not yet implement
	if tour_mode:
		push_error("not yet implement tour_mode")
		pass
	step = Step.DONE
	_finished = true
	Global.in_minigame = false
	Global.cur_pib = null
	if SceneRouter.has(self):
		SceneRouter.pop()
	else:
		queue_free()


func _restart_now() -> void:
	if update_state != UpdateState.RESTART:
		return
	if !doc_saved:
		_trap(&"unsaved_work", "unsaved", &"listen", 10, "รีสตาร์ตทั้งที่งานลูกค้ายังไม่บันทึก")
		lost_user_file = true
		# _refresh_note() # [13 ต.ค.] โชว์ปุ่ม "ส่งงานตามสภาพ"
		_pib_say("งานที่ลูกค้าพิมพ์ค้างไว้หายหมดเลย… ต้องกดบันทึกก่อนรีสตาร์ตทุกครั้ง", PibHint.Mood.WORRY)
	update_state = UpdateState.FINISH
	var pid_list = []
	for pid in os.process_map:
		pid_list.append(pid)
	for pid in pid_list:
		os.kill_process(pid)
	boot_node.show()
	boot_node.play()


func _file_tex(f: DesktopFile) -> Texture2D:
	match f.kind:
		DesktopFile.INSTALLER:
			return TEX_EXE
		DesktopFile.FAKE_INSTALLER:
			return TEX_WARN
		DesktopFile.SYSTEM:
			return TEX_FOLDER
	var n := f.name.to_lower()
	if n.ends_with(".jpg") or n.ends_with(".png") or n.begins_with("รูป"):
		return TEX_IMAGE if n.contains(".") else TEX_PICTURES
	if not n.contains("."):
		return TEX_FOLDER
	return TEX_DOC


func _small(tex: Texture2D) -> Texture2D:
	var img := tex.get_image()
	if img == null:
		return tex
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.resize(24, 24, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


func _resolve_task() -> void:
	if !has_meta("work_order"):
		return
	var order = get_meta("work_order")
	if order is CustomerCase && order.get("desktop_task") is DesktopTask:
		customer_name = order.customer
		task = order.desktop_task


func _pib_toast(section: String, secs := 3.5) -> void:
	if is_instance_valid(pib) and dialog_dict.has(section):
		pib.toast(dialog_dict[section][0], secs)


func _pib_say(text: String, mood := PibHint.Mood.NORMAL, secs := 4.0) -> void:
	if is_instance_valid(pib):
		pib.toast(DialogToken.new(PibHint.DEFAULT_SPEAKER, text), secs, mood)


func _pib(section: StringName, mood := PibHint.Mood.NORMAL) -> void:
	if is_instance_valid(pib) and dialog_dict.has(String(section)):
		pib.say(dialog_dict[String(section)], mood)


func _trap(id: StringName, key: String, cat: StringName, pts: int, note: String) -> void:
	if task == null or not task.traps.has(id):
		return
	lose(cat, pts, note)


func lose(cat: StringName, pts: int, note := "") -> void:
	var cur: int = _mistakes.get(cat, 0)
	var add := mini(pts, int(CAP.get(cat, 100)) - cur)
	if add > 0:
		_on_mistake(cat, add)
	if note != "" and not notes.has(note):
		notes.append(note)


func customer_say(text: String, secs := 3.0) -> void:
	if not is_instance_valid(msg_bubble) or text == "":
		return
	var c_name := msg_bubble.get_node("%Name") as Label
	var msg := msg_bubble.get_node("%Text") as Label
	c_name.text = customer_name
	msg.text = text
	msg_bubble.show()
	msg_bubble.modulate.a = 1.0
	if _bubble_tw:
		_bubble_tw.kill()

	_bubble_tw = create_tween()
	_bubble_tw.tween_interval(secs)
	_bubble_tw.tween_property(msg_bubble, "modulate:a", 0.0, 0.4)
	_bubble_tw.tween_callback(msg_bubble.hide)
