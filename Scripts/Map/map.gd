extends CanvasLayer


func _ready() -> void:
	self.visible = false
	self.hide()


func showmap(id: SceneRouter.LocationID) -> void:
	self.hide()
	SceneRouter.go(id)
