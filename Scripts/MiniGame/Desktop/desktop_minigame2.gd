class_name DesktopMinigameV2 extends PartMinigame

const MIN_SHORTCUT_SIZE = Vector2(60, 60)
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

@export var task: DesktopTask
@export var popup_every := 7.0
@export var free_mode := false
@export var tour_mode := false
@export var ui_layer := 5
@export var framed := true
@export var boot_screen := true

@onready var start_button = %StartMenu
@onready var screen = %Screen
@onready var explorer = %Explorer
@onready var browser = %Browser
@onready var settings = %Settings
@onready var wifi = %Wifi
@onready var sound = %Sound
@onready var disk = %Disk
@onready var clock = %Clock
@onready var desktop = %Desktop

var os: DesktopOS
var _selected_icon: Control
var start_menu: PopupMenu
var customer_name: String
var _explorer_folder := "เดสก์ท็อป"
var _explorer_list: ItemList
var _explorer_path: Label
var _explorer_status: Label

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
	self.add_child(start_menu)


func _process(delta: float) -> void:
	start_button.disabled = start_menu.visible


func _on_start_button() -> void:
	start_menu.reset_size()
	var pos = start_button.get_screen_position()
	pos.y -= start_menu.size.y
	start_menu.popup(Rect2i(Vector2i(pos), Vector2i.ZERO))


func _on_start_menu(id: int) -> void:
	match id:
		0:
			open_explorer("เอกสาร")
		1:
			open_explorer("รูปภาพ")
		2:
			open_explorer("ดาวน์โหลด")
		3:
			# open_browser()
			print("browser")
		4:
			# open_settings()
			print("setting")
		5:
			# open_trash()
			print("trash")
		6:
			# extra.open_task_manager()
			print("task_manager")
		7:
			# extra.open_security()
			print("security")
		99:
			print("shutdown")
			# shut_down()


## หน้าต่างไฟล์ (Explorer) — ข้อมูลจาก os.dir_map / os.fs
func open_explorer(folder: String) -> void:
	_explorer_folder = folder
	var w := _find_window("explorer")
	if w != null:
		w.restore()
	else:
		w = OsWindow.make("explorer", "ไฟล์ — " + task.pc_name, TEX_FOLDER, Vector2(640, 380))
		w.set_meta("type", os.WinType.Explorer)
		var n := os.instances.size()
		w.position = Vector2(130 + (n % 5) * 34, 40 + (n % 5) * 28)
		w.position = w.position.clamp(Vector2.ZERO, (screen.size - w.size).max(Vector2.ZERO))
		w.closed.connect(os.instances.erase.bind(w))
		os.add_instance(w)
		screen.add_child(w)
		_build_explorer(w)
	_refresh_explorer()


func _find_window(key: String) -> OsWindow:
	for w in os.instances:
		if is_instance_valid(w) and w.key == key:
			return w
	return null


func _build_explorer(w: OsWindow) -> void:
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	w.body.add_child(row)
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 140
	row.add_child(side)
	for fo in os.dir_map.keys():
		if fo == DesktopTask.USB and not task.usb_drive:
			continue
		var b := Button.new()
		b.name = "Folder_" + fo.validate_node_name()
		b.text = fo
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(
			func():
				_explorer_folder = fo
				_refresh_explorer(),
		)
		side.add_child(b)
	var tb := Button.new()
	tb.text = "ถังขยะ"
	tb.alignment = HORIZONTAL_ALIGNMENT_LEFT
	tb.focus_mode = Control.FOCUS_NONE
	tb.pressed.connect(print.bind("trash")) # open_trash()
	side.add_child(tb)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	_explorer_path = _label("", 15, Color(0.35, 0.35, 0.4))
	right.add_child(_explorer_path)
	_explorer_list = ItemList.new()
	_explorer_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_explorer_list.fixed_icon_size = Vector2i(28, 28)
	_explorer_list.item_activated.connect(
		func(i):
			_explorer_action("open"),
	)
	_explorer_list.gui_input.connect(_on_explorer_key)
	right.add_child(_explorer_list)
	var bar := HBoxContainer.new()
	right.add_child(bar)
	var acts := (
		[["เปิด", "open"], ["ลบ", "delete"]]
		if free_mode
		else [["เปิด", "open"], ["ถามลูกค้า", "ask"], ["ลบ", "delete"]]
	)
	if task.usb_drive:
		acts.append_array([["คัดลอกไป USB", "copy_usb"], ["ย้ายไป USB", "move_usb"], ["ถอด USB", "eject"]])
	for a in acts:
		var b := Button.new()
		b.text = a[0]
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_explorer_action.bind(a[1]))
		bar.add_child(b)
	_explorer_status = _label("", 14, Color(0.35, 0.35, 0.4))
	_explorer_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_explorer_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bar.add_child(_explorer_status)


func _explorer_selected() -> DesktopFile:
	if not is_instance_valid(_explorer_list):
		return null
	var sel := _explorer_list.get_selected_items()
	return _explorer_list.get_item_metadata(sel[0]) if not sel.is_empty() else null


func _explorer_action(what: String) -> void:
	if what == "eject":
		print("eject_usb")
		return
	var f := _explorer_selected()
	if f == null:
		_explorer_status.text = "เลือกไฟล์ก่อน"
		return
	match what:
		"open":
			print("open ", f.name) # _open_file_ui(f)
		"ask":
			print("ask ", f.name) # customer_say(ask_about(f))
		"delete":
			print("delete ", f.name) # delete_file(f)
		"copy_usb":
			print("copy_usb ", f.name)
		"move_usb":
			print("move_usb ", f.name)


func _on_explorer_key(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_DELETE:
		_explorer_action("delete")
		_explorer_list.accept_event()


func _refresh_explorer() -> void:
	if not is_instance_valid(_explorer_list):
		return
	_explorer_list.clear()
	_explorer_path.text = "เครื่องนี้ › " + _explorer_folder
	var dir: DesktopOS.Dir = os.dir_map.get(_explorer_folder)
	var count := 0
	if dir != null:
		for idx in dir.files:
			var f := os.fs[idx]
			var i := _explorer_list.add_item(
				"%s      %s" % [f.name, DesktopMinigame.size_text(f.size_mb)],
				_file_tex(f),
			)
			_explorer_list.set_item_metadata(i, f)
			if f.kind == DesktopFile.FAKE_INSTALLER:
				_explorer_list.set_item_custom_fg_color(i, Color(0.8, 0.3, 0.1))
			count += 1
	_explorer_status.text = "%d รายการ · เหลือ %s" % [count, DesktopMinigame.size_text(task.disk_free_mb)]


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


func _label(t: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _small(tex: Texture2D) -> Texture2D:
	var img := tex.get_image()
	if img == null:
		return tex
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.resize(24, 24, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


func _on_wall_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		_select_icon(null)


func _select_icon(ic: Control) -> void:
	if is_instance_valid(_selected_icon):
		(_selected_icon.get_meta("style") as StyleBoxFlat).bg_color = Color(1, 1, 1, 0)
	_selected_icon = ic
	if is_instance_valid(ic):
		(ic.get_meta("style") as StyleBoxFlat).bg_color = Color(0.6, 0.8, 1, 0.35)


func _resolve_task() -> void:
	if !has_meta("work_order"):
		return
	var order = get_meta("work_order")
	if order is CustomerCase && order.get("desktop_task") is DesktopTask:
		customer_name = order.customer
		task = order.desktop_task
