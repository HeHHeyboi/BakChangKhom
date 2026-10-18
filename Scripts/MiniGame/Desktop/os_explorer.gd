class_name OsExplorer extends OsWindow2
## หน้าต่างไฟล์ของขมOS (os_explorer.tscn) — ลากย้ายที่แถบหัว · คลิกแล้วขึ้นมาหน้าสุด · ปิดด้วย [X]
## เนื้อหา (รายการไฟล์/ปุ่ม) ผูกโดย DesktopMinigameV2.open_explorer

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
	super._ready()


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
			delete_action.text = "ล้างถังขยะ"
		NORM:
			open_action.show()
			ask_action.show()
			delete_action.show()
			delete_action.text = "ลบ"


func show_usb_action():
	copy_usb_action.show()
	move_usb_action.show()
	eject_action.show()


func hide_usb_action():
	copy_usb_action.hide()
	move_usb_action.hide()
	eject_action.hide()
