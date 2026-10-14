class_name OsExplorer extends OsWindow2
## หน้าต่างไฟล์ของขมOS (os_explorer.tscn) — ลากย้ายที่แถบหัว · คลิกแล้วขึ้นมาหน้าสุด · ปิดด้วย [X]
## เนื้อหา (รายการไฟล์/ปุ่ม) ผูกโดย DesktopMinigameV2.open_explorer

@onready var _topbar: PanelContainer = $VBoxContainer/Topbar


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
