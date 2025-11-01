extends Button

var root: Node


func _ready() -> void:
	root = get_tree().root
	Global.show_map.connect(_on_map_show_map)


func _process(delta: float) -> void:
	if Market.visible:
		self.disabled = true
	else:
		self.disabled = false


func _on_market_pressed() -> void:
	Market.move_to_front()
	Global.showmap(Global.Map.MARKET)


func _on_map_show_map(m: Global.Map) -> void:
	if m == Global.Map.MARKET:
		Market.show()
	else:
		Market.hide()
