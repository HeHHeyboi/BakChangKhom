class_name OneArgsEvent extends Event
signal event_signal(arg1)


func add_listener(listener) -> void:
	event_signal.connect(listener)
	pass


func remove_listener(listener) -> bool:
	event_signal.disconnect(listener)
	return event_signal.is_connected(listener)


func emit(...args) -> void:
	assert(args.size() == 1, "paramenter in this event should be 1")
	event_signal.emit(args[0])
