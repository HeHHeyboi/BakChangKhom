extends Node

@onready var timer = Timer.new()
var box_click_count = 2
@onready var text = $RichTextLabel as RichTextLabel
@onready var eraser = $Eraser as TextureRect
var dialog_arr = ["หาไม่เจอ", "อยู่ใหนนะ?", "หรือว่าอยู่ในกล่องนั้น"]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# EventManager.hideUI()
	self.add_child(timer)
	timer.wait_time = 1
	timer.one_shot = true
	timer.connect("timeout", self._timeout)


func _timeout():
	Global.in_minigame = false
	EventManager.minigame_end()
	self.call_deferred("queue_free")


func _on_box_pressed() -> void:
	if box_click_count > 0:
		text.text = dialog_arr[-box_click_count]
		box_click_count -= 1
	else:
		text.text = "เจอแล้ว!"
		eraser.show()
		timer.start()
