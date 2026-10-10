extends TextureButton

@onready var notify = $"caution"


func _on_pressed() -> void:
	if notify.visible and not DialogScene.visible: # [10 ต.ค.] กดซ้ำระหว่างบทเปิดอยู่ = ไม่เปิดบทซ้อน
		var id = EventManager.EventID.MAIN
		EventManager.trigger_step(id, EventManager.eventMap[id])
