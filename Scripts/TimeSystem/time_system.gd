extends CanvasLayer

@onready var textBox = $Control/PanelContainer/RichTextLabel as RichTextLabel
@export var cur_time = TIME.MORNING

enum TIME { MORNING, NOON, EVENING }
signal time_update(t: TIME)


func _ready() -> void:
	updateTime(cur_time)


func _process(delta: float) -> void:
	# updateTime(cur_time)
	if Global.in_minigame:
		self.hide()
	else:
		self.show()


func change_time(t: TIME) -> void:
	cur_time = t
	emit_signal("time_update", cur_time)


func updateTime(t: TIME) -> void:
	match t:
		TIME.MORNING:
			textBox.clear()
			textBox.push_color(Color.LIGHT_YELLOW)
			textBox.append_text("เช้า")
			textBox.pop()
		TIME.NOON:
			textBox.clear()
			textBox.push_color(Color.YELLOW)
			textBox.append_text("เที่ยง")
			textBox.pop()
		TIME.EVENING:
			textBox.clear()
			textBox.push_color(Color.NAVY_BLUE)
			textBox.append_text("เย็น")
			textBox.pop()
