extends CanvasLayer

signal on_update_task(String)

@export var QuestList: Node


# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	on_update_task.connect(self._on_update_task)


func _exit_tree() -> void:
	on_update_task.disconnect(self._on_update_task)


func update_task(text: String) -> void:
	print(text)


func _on_update_task(text: String) -> void:
	print(text)
