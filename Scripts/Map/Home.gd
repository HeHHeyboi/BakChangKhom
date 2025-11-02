extends Button

@onready var root = get_tree().root as Node

# func _ready() -> void:
# 	MapPanel.show_map.connect(_on_map_show_map)


func _process(delta: float) -> void:
	if !root.has_node("Home"):
		return

	var node = root.get_node("Home") as Control
	if node == null:
		return
	if node.visible:
		self.disabled = true
	else:
		self.disabled = false


func _on_pressed() -> void:
	var node = root.get_node("Home") as Control
	if node == null:
		return
	node.move_to_front()
	MapPanel.showmap(MapPanel.Location.HOME)


func _on_map_show_map(m: MapPanel.Location) -> void:
	var node = root.get_node("Home") as Control
	if node == null:
		return
	if m == MapPanel.Location.HOME:
		node.show()
	else:
		node.hide()
