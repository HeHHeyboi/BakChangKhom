class_name QuestBoard extends CanvasLayer

@export var QuestList: Node
## [Claude 10 ต.ค. 2569] ปุ่มย่อ/ขยายกระดานเควสต์ (กด Q ก็ได้)
@export var ToggleButton: Button

## true = ย่ออยู่ (เห็นแค่หัว "เควสต์")
var collapsed := false

var _event_map: Dictionary[Event, Label] = { }


func update_task(text: String, event: Event) -> void:
	if _event_map.has(event):
		var label = _event_map.get(event)
		if text == "":
			_event_map.erase(event)
			label.queue_free()
		else:
			label.text = "- " + text
	else:
		var label = Label.new()
		label.text = "- " + text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		QuestList.add_child(label)
		_event_map.set(event, label)


func _ready() -> void:
	if ToggleButton:
		ToggleButton.pressed.connect(toggle)
	set_collapsed(collapsed)


func toggle() -> void:
	set_collapsed(not collapsed)


func set_collapsed(on: bool) -> void:
	collapsed = on
	if QuestList:
		QuestList.visible = not on
	if ToggleButton:
		ToggleButton.text = "แสดง" if on else "ซ่อน"


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q and not Global.in_minigame:
		toggle()
		get_viewport().set_input_as_handled()
