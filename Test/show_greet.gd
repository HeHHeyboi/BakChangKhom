extends Label

@export var print_event: Event


func _ready():
	print_event.add_listener(showText)


func showText(greeting: String):
	self.text = greeting
