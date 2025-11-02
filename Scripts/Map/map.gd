extends CanvasLayer

signal show_map(m: Location)

enum Location { HOME, MARKET }


func _ready() -> void:
	self.visible = false
	self.hide()


func showmap(m: Location) -> void:
	emit_signal("show_map", m)
	self.hide()
