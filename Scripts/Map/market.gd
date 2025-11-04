extends Button

var root: Node


func _ready() -> void:
	root = get_tree().root
	# MapPanel.show_map.connect(_on_map_show_map)


func _process(delta: float) -> void:
	if Market.visible:
		self.disabled = true
	else:
		self.disabled = false


func _on_market_pressed() -> void:
	Market.move_to_front()
	MapPanel.showmap(MapPanel.Location.MARKET)


func _on_map_show_map(m: MapPanel.Location) -> void:
	if m == MapPanel.Location.MARKET:
		Market.show()
		Market.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		Market.hide()
		Market.process_mode = Node.PROCESS_MODE_DISABLED
