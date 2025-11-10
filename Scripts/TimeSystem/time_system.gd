extends CanvasLayer

@onready var timeText = $PanelContainer/HBoxContainer/Time as RichTextLabel
@onready var dateText = $PanelContainer/HBoxContainer/Date as RichTextLabel
@export var cur_time = TIME.MORNING

var current_day = 1
var current_month = 1

enum TIME { MORNING, NOON, EVENING }
signal time_update(t: TIME)


func _ready() -> void:
	updateTime(cur_time)
	dateText.add_text("วันที่ %d เดือน %d" % [current_day, current_month])


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
			timeText.clear()
			timeText.push_color(Color.LIGHT_YELLOW)
			timeText.append_text("เช้า")
			timeText.pop()
		TIME.NOON:
			timeText.clear()
			timeText.push_color(Color.YELLOW)
			timeText.append_text("เที่ยง")
			timeText.pop()
		TIME.EVENING:
			timeText.clear()
			timeText.push_color(Color.NAVY_BLUE)
			timeText.append_text("เย็น")
			timeText.pop()
