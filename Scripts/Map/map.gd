class_name MapPanel extends Control


func _ready() -> void:
	self.visible = false
	Global.show_map.connect(_hide_map)


func _hide_map(_m) -> void:
	self.hide()
