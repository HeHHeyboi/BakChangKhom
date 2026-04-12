@abstract
# NOTE: Child Class must implement emit() or Invoke() function
class_name Event extends Resource

@abstract func add_listener(arg: Callable)
@abstract func remove_listener(arg: Callable) -> bool
@abstract func emit(...args)
