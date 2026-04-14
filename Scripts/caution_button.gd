class_name CautionButton extends TextureButton

@export var trackEvent: Event
@export var trackStep: int = 1


func _enter_tree() -> void:
	EventManager.sendUpdatedEvent.connect(checkTrackEvent)


func _exit_tree() -> void:
	EventManager.sendUpdatedEvent.disconnect(checkTrackEvent)


func _ready():
	checkTrackEvent()


func checkTrackEvent():
	if trackEvent.currentStep == trackStep:
		self.show()
	else:
		self.hide()

