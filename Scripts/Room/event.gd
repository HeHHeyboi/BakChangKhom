extends TextureButton

var minigame = Global.ReturnMiniGame("MiniGame1") as Node2D


func _on_pressed() -> void:
	get_tree().root.add_child(minigame)
