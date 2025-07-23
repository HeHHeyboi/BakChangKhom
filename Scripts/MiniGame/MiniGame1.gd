extends Node2D

@onready var eraser = $"Eraser" as Sprite2D
@onready var ram = $"Ram" as Sprite2D

@onready var pos1 = $"pos1" as Marker2D
@onready var pos2 = $"pos2" as Marker2D

var moveRight = true
var moving = true
var goalPos
var curPos
var t = 1.0


func _ready() -> void:
	goalPos = pos1.position
	curPos = pos1.position
	eraser.position = curPos
	pass


func _physics_process(delta: float) -> void:
	if moving:
		t += delta * 2
		if t >= 1.0:
			t = 1.0
			moving = false
		eraser.position = curPos.lerp(goalPos, t)


func _on_button_pressed() -> void:
	if moveRight:
		goalPos = pos2.position
		curPos = pos1.position
	else:
		goalPos = pos1.position
		curPos = pos2.position
	t = 1.0 - t
	moveRight = !moveRight
	moving = true
	pass
