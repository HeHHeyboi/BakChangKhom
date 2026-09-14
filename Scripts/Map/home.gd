extends Button

@onready var root = get_tree().root as Node


func getHomeNode() -> Control:
	if !root.has_node("Home"):
		return null
	var node = root.get_node("Home") as Control
	if node == null:
		return null
	return node


func _process(_delta: float) -> void:
	var home = getHomeNode()
	if home == null:
		return

	if home.visible:
		self.disabled = true
	else:
		self.disabled = false


func _on_pressed() -> void:
	var home = getHomeNode()
	assert(home != null)
	home.move_to_front()
	MapPanel.showmap(MapPanel.Location.HOME)


func _on_map_show_map(m: MapPanel.Location) -> void:
	var home = getHomeNode()
	assert(home != null)
	if m == MapPanel.Location.HOME:
		home.show()
	else:
		home.hide()
