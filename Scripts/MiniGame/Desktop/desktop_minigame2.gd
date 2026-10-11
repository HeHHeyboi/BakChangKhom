extends Node

var _selected_icon: Control


func _on_wall_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		_select_icon(null)


func _select_icon(ic: Control) -> void:
	if is_instance_valid(_selected_icon):
		(_selected_icon.get_meta("style") as StyleBoxFlat).bg_color = Color(1, 1, 1, 0)
	_selected_icon = ic
	if is_instance_valid(ic):
		(ic.get_meta("style") as StyleBoxFlat).bg_color = Color(0.6, 0.8, 1, 0.35)
