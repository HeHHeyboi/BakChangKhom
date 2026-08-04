extends Node2D

@onready var eraser = $"Eraser" as Sprite2D
@onready var ram = $"Ram" as Sprite2D

@onready var pos1 = $"pos1" as Marker2D
@onready var pos2 = $"pos2" as Marker2D
@onready var button = $"MiniGame" as Control
@onready var startText = $"StartText" as Label
@onready var miniGameBG = $"MiniGameBackgroud" as Panel

var moveRight = true
var moving = true
var isStart = false
var isFinish = false
var goalPos
var curPos
var clikTime = 0
var t = 1.0
var RamIMG = [
	load("res://Assets/MiniGame/ramDirty.png"),
	load("res://Assets/MiniGame/ramSligtDirty.png"),
	load("res://Assets/MiniGame/ram.png")
]

enum RamStatus { DIRTY = 0, BETTER = 10, CLEAN = 15 }


func _ready() -> void:
	goalPos = pos1.position
	curPos = pos1.position
	eraser.position = curPos
	EventManager.hideTimeUI(true)
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if !isStart:
			if event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
				isStart = true
				ram.show()
				eraser.show()
				button.show()
				miniGameBG.show()
				startText.hide()


func _physics_process(delta: float) -> void:
	if moving && !isFinish:
		t += delta * 2
		if t >= 1.0:
			t = 1.0
			moving = false
		eraser.position = curPos.lerp(goalPos, t)

	match clikTime:
		RamStatus.DIRTY:
			ram.texture = RamIMG[0]
		RamStatus.BETTER:
			ram.texture = RamIMG[1]
		RamStatus.CLEAN:
			ram.texture = RamIMG[2]


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

	clikTime += 1
	if clikTime == RamStatus.CLEAN:
		isFinish = true
		button.hide()
		for n in miniGameBG.get_children():
			n.show()


func _on_return_pressed() -> void:
	EventManager.update_event(EventManager.EventID.MAIN)
	EventManager.next_period.emit()
	EventManager.hideTimeUI(false)
	queue_free()
