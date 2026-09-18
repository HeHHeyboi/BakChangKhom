extends TextureButton

@onready var notify = $"caution"


func _on_pressed() -> void:
	if notify.visible:
		var id = EventManager.EventID.MAIN
		EventManager.trigger_step(id, EventManager.eventMap[id])
