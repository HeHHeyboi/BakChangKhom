class_name DesktopMinigameV2 extends PartMinigame

const MIN_SHORTCUT_SIZE = Vector2(60, 60)
const DEFAULT_WINDOW_SIZE = Vector2(450, 350)

# NOTE: Load app scene
const EXPLORER_SCENE := preload("res://Scene/MiniGame/Desktop/os_explorer.tscn")
const BROWSER_SCENE := preload("res://Scene/MiniGame/Desktop/os_browser.tscn")
const WINDOW_BASE := preload("res://Scene/MiniGame/Desktop/os_window_base.tscn")
const INFO_WINDOW := preload("res://Scene/MiniGame/Desktop/os_info.tscn")

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

@export var task: DesktopTask
@export var popup_every := 7.0
@export var free_mode := false
@export var tour_mode := false
@export var ui_layer := 5
@export var framed := true
@export var boot_screen := true

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
# NOTE: Explorer var
var _explorer_folder := "เดสก์ท็อป"
var _explorer_win: OsExplorer
var _explorer_list: ItemList
var _explorer_path: Label
var _explorer_status: Label
var notes: PackedStringArray = []
var _bubble_tw: Tween

# NOTE: Browser var
var _browser_page: VBoxContainer
var _browser_addr: LineEdit

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


func _ready() -> void:
	super._ready()
	os = DesktopOS.new()
	_resolve_task()
	for dir in task.FOLDERS:
		os.create_dir(dir)
	for file in task.files:
		os.add_file(file)

	os.disk_total_mb = task.disk_total_mb
	os.disk_free_mb = task.disk_free_mb
	clock.text = EventManager.get_clock_text()
	start_button.pressed.connect(self._on_start_button)

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
	self.add_child(start_menu)


func _process(_delta: float) -> void:
	start_button.disabled = start_menu.visible


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
			# print("browser")
		4:
			# open_settings()
			print("setting")
		5:
			open_explorer(TRASH_DIR)
		6:
			# extra.open_task_manager()
			print("task_manager")
		7:
			# extra.open_security()
			print("security")
		99:
			print("shutdown")
			# shut_down()


func _on_file_menu(id: int) -> void:
	print("use file menu")
	pass


func _find_window(key: String) -> OsWindow2:
	for w in os.instances:
		if is_instance_valid(w) and w.key == key:
			return w
	return null


# NOTE: Explorer Logic
## หน้าต่างไฟล์ (Explorer) — โครงจาก os_explorer.tscn · ข้อมูลจาก os.dir_map / os.fs
const DOC_DIR = "เอกสาร"
const DOWNLOAD_DIR = "ดาวน์โหลด"
const PIC_DIR = "รูปภาพ"
const TRASH_DIR = DesktopOS.TRASH


func open_explorer(folder: String = "เอกสาร") -> void:
	_explorer_folder = folder
	var w := _find_window("explorer")
	if w == null:
		w = EXPLORER_SCENE.instantiate()
		w.set_meta("type", os.WinType.Explorer)
		# var n := os.instances.size()
		w.size = DEFAULT_WINDOW_SIZE
		# w.position = Vector2(130 + (n % 5) * 34, 40 + (n % 5) * 28)
		# w.position = w.position.clamp(Vector2.ZERO, (screen.size - w.size).max(Vector2.ZERO))
		w.restore(true)
		screen.add_child(w)
		os.add_instance(w)
		_setup_explorer(w)
	else:
		w.restore()
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
		side.add_child(b)
	side.move_child(trash, -1)
	trash.pressed.connect(
		func():
			_explorer_folder = DesktopOS.TRASH
			_refresh_explorer(),
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
		print("eject_usb")
		return
	var idx := _explorer_selected()
	if what == "delete" && _explorer_folder == DesktopOS.TRASH:
		os.clear_trash()
		_refresh_explorer()
		return
	var f: DesktopFile = os.fs[idx].data if idx >= 0 else null
	if f == null:
		_pib_toast(&"SELECT_FIRST", 2.5)
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
			print("copy_usb ", f.name)
		"move_usb":
			print("move_usb ", f.name)


func _open_file(f: DesktopFile):
	var msg: String = ""
	match f.kind:
		DesktopFile.USER:
			msg = f.note if f.note != "" else "ไฟล์ของลูกค้า"
		DesktopFile.FAKE_INSTALLER:
			_trap(&"fake_download", "run_fake", &"safety", 5, "เปิดไฟล์จากปุ่มโฆษณา")
			# WARN: need to implement
			# install_adware()
			_pib(&"FAKE_RUN", PibHint.Mood.WORRY)
			msg = "กำลังติดตั้ง… (ไม่มีหน้าให้เลือกอะไรเลย!)"
		DesktopFile.INSTALLER:
			pass
		DesktopFile.DUP:
			msg = f.note if f.note != "" else "เปิดดูแล้ว — เหมือนกับ \"%s\" ทุกอย่าง" % f.dup_of
		DesktopFile.SYSTEM:
			msg = f.note if f.note != "" else "ไฟล์ระบบของขมOS — เครื่องต้องใช้ตอนเปิด"
	if msg != "":
		var w = INFO_WINDOW.instantiate() as OsWindow2
		if w == null:
			push_error("w is OsWindow2")
			return
		w.closed.connect(
			func():
				w.queue_free.call_deferred(),
		)
		w.restore(true)
		w.set_title("เปิด %s" % [f.name])
		w.set_icon(self._file_tex(f))
		var label = w.get_node("%Message") as Label
		label.text = msg
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL

		var ok := w.get_node("%Ok") as Button
		ok.text = "ตกลง"
		ok.size_flags_horizontal = Control.SIZE_SHRINK_END
		ok.pressed.connect(w.close)
		screen.add_child(w)


func _refresh_explorer() -> void:
	if not is_instance_valid(_explorer_list):
		return
	_explorer_list.clear()
	_explorer_path.text = "เครื่องนี้ › " + _explorer_folder
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
const BROWSER_HOME = "home"
const BROWSER_OFFICIAL = "official"
const BROWSER_OFFICIAL_SCENE = "res://Scene/MiniGame/Desktop/os_browser_official.tscn"
const BROWSER_RESULT_SCENE = "res://Scene/MiniGame/Desktop/os_browser_result.tscn"
const BROWSER_AD_SCENE = "res://Scene/MiniGame/Desktop/os_browser_ad.tscn"


func open_browser() -> void:
	var w := _find_window("browser")
	if w == null:
		w = BROWSER_SCENE.instantiate()
		w.restore(true)
		w.set_meta("type", os.WinType.Browser)
		w.size = DEFAULT_WINDOW_SIZE
		_browser_page = w.get_node("%Page")
		_browser_addr = w.get_node("%Address")
		screen.add_child(w)
	else:
		w.restore()
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
				download_official()
				_pib_toast(&"OFFICIAL_DONE", 3.0)
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


func click_download_ad() -> Dictionary:
	return { }


func download_official() -> Dictionary:
	return { }


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


func _pib_toast(section: StringName, secs := 3.5) -> void:
	if is_instance_valid(pib) and dialog_dict.has(String(section)):
		pib.toast(dialog_dict[String(section)][0], secs)


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
