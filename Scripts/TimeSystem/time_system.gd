extends CanvasLayer

@onready var timeText = $PanelContainer/HBoxContainer/Time as RichTextLabel
@onready var dateText = $PanelContainer/HBoxContainer/Date as RichTextLabel
@export var cur_period = TIME.MORNING

var current_day = 1
var current_month = 1

enum TIME { MORNING, NOON, EVENING }


func _enter_tree() -> void:
	EventManager.next_period.connect(change_period)
	EventManager.next_day.connect(change_day)
	EventManager.hide_time.connect(self.hide)
	EventManager.show_time.connect(self.show)


func _exit_tree() -> void:
	EventManager.next_period.disconnect(change_period)
	EventManager.next_day.disconnect(change_day)
	EventManager.hide_time.disconnect(self.hide)
	EventManager.show_time.disconnect(self.show)


func _ready() -> void:
	updateTime()
	dateText.add_text("วันที่ %d เดือน %d" % [current_day, current_month])


func change_period() -> void:
	match cur_period:
		TIME.MORNING:
			cur_period = TIME.NOON
		TIME.NOON:
			cur_period = TIME.EVENING
		TIME.EVENING:
			cur_period = TIME.MORNING

	updateTime()


func change_day() -> void:
	cur_period = TIME.MORNING
	if current_day >= 30:
		current_day = 1
		current_month += 1
	else:
		current_day += 1

	updateTime()


func set_period(time: TIME) -> void:
	cur_period = time


func updateTime() -> void:
	match cur_period:
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
