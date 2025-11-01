extends Button

@onready var map = $"../Map"


func _process(delta: float) -> void:
	if map.visible:
		self.disabled = true
	else:
		self.disabled = false


func _on_pressed() -> void:
	if !map.visible:
		map.visible = true
