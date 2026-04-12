class_name NoArgsEvent extends Event

signal event_signal


func add_listener(listener) -> void:
	event_signal.connect(listener)
	pass


func remove_listener(listener) -> bool:
	event_signal.disconnect(listener)
	return event_signal.is_connected(listener)


func emit(..._args) -> void:
	event_signal.emit()
	pass
