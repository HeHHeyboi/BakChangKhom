class_name OsWindow2 extends Panel

signal closed
var _drag := false
var _drag_off := Vector2.ZERO
const TITLE_H := 21

@export var _topbar: PanelContainer


func set_title(title: String):
	var t = _topbar.get_node("%Title") as Label
	t.text = title


func set_icon(icon: Texture2D):
	var i = _topbar.get_node("%Icon") as TextureRect
	i.texture = icon


func _ready() -> void:
	var row := _topbar.get_node("HBoxContainer")
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in row.get_children():
		if c is Control and c is not BaseButton:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_topbar.gui_input.connect(_on_bar_input)
	_topbar.get_node("%Close").pressed.connect(close)


func close() -> void:
	closed.emit()
	self.hide()


func restore(force: bool = true) -> void:
	if not visible or force:
		set_anchors_and_offsets_preset(PRESET_CENTER, PRESET_MODE_KEEP_SIZE)
	show()
	move_to_front()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		move_to_front()


func _on_bar_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_drag = event.pressed
		_drag_off = get_parent_control().get_local_mouse_position() - position
		if event.pressed:
			move_to_front()
	elif event is InputEventMouseMotion and _drag:
		var p: Vector2 = get_parent_control().get_local_mouse_position() - _drag_off
		var area := get_parent_area_size()
		position = Vector2(clampf(p.x, -size.x + 40, area.x - 40), clampf(p.y, 0, area.y - TITLE_H))
