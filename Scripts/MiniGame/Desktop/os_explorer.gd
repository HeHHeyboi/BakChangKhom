class_name OsExplorer extends OsWindow2
## หน้าต่างไฟล์ของขมOS (os_explorer.tscn) — ลากย้ายที่แถบหัว · คลิกแล้วขึ้นมาหน้าสุด · ปิดด้วย [X]
## เนื้อหา (รายการไฟล์/ปุ่ม) ผูกโดย DesktopMinigameV2.open_explorer

@onready var _topbar: PanelContainer = $VBoxContainer/Topbar
@onready var open_action = %Open
@onready var ask_action = %Ask
@onready var restore_action = %Restore
@onready var delete_action = %Delete
@onready var copy_usb_action = %CopyUsb
@onready var move_usb_action = %MoveUsb
@onready var eject_action = %Eject

const TRASH = 1
const NORM = 2


func _ready() -> void:
	key = "explorer"
	# ให้เมาส์ทะลุไปถึงแถบหัวเพื่อลากย้าย (ยกเว้นปุ่ม X)
	var row := _topbar.get_node("HBoxContainer")
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in row.get_children():
		if c is Control and c is not BaseButton:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_topbar.gui_input.connect(_on_bar_input)
	_topbar.get_node("%Close").pressed.connect(close)


func set_title(t: String) -> void:
	_topbar.get_node("%Title").text = t


func show_action_bar_preset(preset: int):
	open_action.hide()
	ask_action.hide()
	restore_action.hide()
	delete_action.hide()
	match preset:
		TRASH:
			restore_action.show()
			delete_action.show()
		NORM:
			open_action.show()
			ask_action.show()
			delete_action.show()


func show_usb_action():
	copy_usb_action.show()
	move_usb_action.show()
	eject_action.show()
