class_name CautionButton extends TextureButton

@export var trackEvent: Event
@export var trackStep: int = 1
# var minigame = Global.ReturnMiniGame("MiniGame1") as Node2D

# func _ready() -> void:
# 	self.hide()


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

# func _process(_delta: float) -> void:
# 	if EventManager.currentEvent == EventManager.MainEvent.CLEAN_RAM:
# 		self.show()
# 	else:
# 		self.hide()
