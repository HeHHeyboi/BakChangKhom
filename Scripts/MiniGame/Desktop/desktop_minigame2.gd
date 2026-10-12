class_name DesktopMinigameV2 extends PartMinigame

@export var Task: DesktopTask

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

var free_mode = true


func _ready() -> void:
	super._ready()
	os = DesktopOS.new()
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
	pass


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
			# open_explorer("เอกสาร")
			var win = OsWindow.make("doc", "explorer - เอกสาร", TEX_FOLDER, Vector2(300, 300))
			win.set_anchors_preset(Control.PRESET_CENTER, true)
			screen.add_child(win)
			# print("doc")
		1:
			# open_explorer("รูปภาพ")
			print("image")
		2:
			# open_explorer("ดาวน์โหลด")
			print("download")
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
