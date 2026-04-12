class_name ThreeArgsEvent extends Event
signal event_signal(arg1, arg2, arg3)


func add_listener(listener) -> void:
	assert(listener.get_argument_count() == 3, "listener should have 3 arguments")
	event_signal.connect(listener)
	pass


func remove_listener(listener) -> bool:
	event_signal.disconnect(listener)
	return event_signal.is_connected(listener)


func emit(...args) -> void:
	assert(args.size() == 3, "paramenter in this event should be 3 but get %s" % args.size())
	event_signal.emit(args[0], args[1], args[2])
