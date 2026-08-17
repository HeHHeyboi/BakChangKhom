extends TextureButton

@export var notify: TextureRect


func _on_pressed() -> void:
	get_tree().change_scene_to_file(Constant.ROOM_SCENE)
