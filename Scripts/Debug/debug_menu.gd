extends CanvasLayer

# Debug overlay for jumping the quest to a specific point during development.
# Toggle with F1. Add more entries to `jump_points` to extend this later —
# each one sets the MAIN quest to a task index and optionally changes scene.

const TOGGLE_KEY := KEY_F1

var jump_points: Array[Dictionary] = []
var _button_list: VBoxContainer


func _ready() -> void:
	layer = 100
	visible = false
	jump_points = [
		{
			"label": "Go to Your Room and Clean the Ram",
			"event_id": EventManager.EventID.MAIN,
			"task_index": 1,
			"scene": Constant.HOME_SCENE,
		},
	]
	_build_ui()


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Debug: Jump Quest (F1 to close)"
	vbox.add_child(title)

	_button_list = VBoxContainer.new()
	vbox.add_child(_button_list)

	_refresh_buttons()


func _refresh_buttons() -> void:
	for child in _button_list.get_children():
		child.queue_free()

	for point in jump_points:
		var button := Button.new()
		button.text = point["label"]
		button.pressed.connect(_on_jump_point_pressed.bind(point))
		_button_list.add_child(button)


func _on_jump_point_pressed(point: Dictionary) -> void:
	EventManager.jump_event(point["event_id"], point["task_index"])
	if point.get("scene", "") != "":
		get_tree().change_scene_to_file(point["scene"])
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == TOGGLE_KEY:
		visible = !visible
		get_viewport().set_input_as_handled()
