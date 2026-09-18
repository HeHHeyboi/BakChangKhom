extends Node

var box_click_count = 2
@onready var text = $RichTextLabel as RichTextLabel
var dialog_arr = ["หาไม่เจอ", "อยู่ใหนนะ?", "หรือว่าอยู่ในกล่องนั้น"]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventManager.hideUI()
	pass # Replace with function body.


func _on_box_pressed() -> void:
	if box_click_count > 0:
		text.text = dialog_arr[-box_click_count]
		box_click_count -= 1
	else:
		text.text = "เจอแล้ว!"
