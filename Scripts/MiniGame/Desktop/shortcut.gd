@tool
class_name DesktopShortcut extends Control
## ไอคอนทางลัดบนเดสก์ท็อปขมOS (รูป + ชื่อ) — ตั้งรูปกับข้อความใน Inspector ได้เลย เห็นผลในเอดิเตอร์ทันที
## ใช้ใน Scene/MiniGame/Desktop/shortcut.tscn · ไอคอนอยู่ Assets/MiniGame/Desktop/os_icon_*.png

## รูปไอคอน
@export var icon: Texture2D:
	set(v):
		icon = v
		_apply()
## ชื่อใต้ไอคอน
@export var shortcut_name := "Shortcut":
	set(v):
		shortcut_name = v
		_apply()


func _ready() -> void:
	_apply()


func set_text(text: String) -> void:
	self.shortcut_name = text


func set_texture(t: Texture2D) -> void:
	self.icon = t


func _apply() -> void:
	if not is_inside_tree():
		return
	var texture := get_node_or_null(^"HBoxContainer/Icon") as TextureRect
	if icon:
		texture.texture = icon
	var label := get_node_or_null(^"HBoxContainer/Name") as Label
	if label:
		label.text = shortcut_name
