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
		{
			"label": "ข้ามไป Tutorial ประกอบคอม (กด ! ในห้อง)",
			"event_id": EventManager.EventID.MAIN,
			"task_index": 3,
			"scene": Constant.ROOM_SCENE,
		},
		{
			# [Claude 2 ต.ค. 2569] เปิดมินิเกมตรง ๆ ไม่แตะเควสต์หลัก (Part ที่ยังไม่มีเควสต์)
			"label": "เล่น Part Mainboard + CPU (ทดสอบ)",
			"minigame": "res://Scene/MiniGame/PartMainboard/part_mainboard.tscn",
		},
		{
			"label": "เล่น Part GPU + จัดสาย (ทดสอบ)",
			"minigame": "res://Scene/MiniGame/PartGpu/part_gpu.tscn",
		},
		{
			"label": "เล่น Part Front Panel + Dual Channel (ทดสอบ)",
			"minigame": "res://Scene/MiniGame/PartFrontPanel/part_front_panel.tscn",
		},
		{
			"label": "เล่น Part BIOS + ลง Windows (ทดสอบ)",
			"minigame": "res://Scene/MiniGame/PartBios/part_bios.tscn",
		},
		# [Claude 5 ต.ค. 2569] ทดสอบลูปเวลา 7 วัน/รอบ · 12 รอบ (Docs/GAME_LOOP.md)
		{
			"label": "ลูปร้าน: ข้ามเควสต์ เริ่มรับลูกค้า (ไปห้องขม)",
			"call": _start_shop_loop,
		},
		{
			"label": "เวลา: ไปช่วงถัดไป (เย็น → วันใหม่)",
			"call": EventManager.advance_period,
		},
		{
			"label": "เวลา: นอน → วันถัดไป",
			"call": EventManager.end_day,
		},
		{
			"label": "เวลา: ไปเย็นวันที่ 7 ของรอบนี้ (นอนต่อ = จบรอบ)",
			"call": func(): EventManager.time_system.set_date(EventManager.time_system.current_week, TimeSystem.DAYS_PER_WEEK, TimeSystem.TIME.EVENING),
		},
		{
			"label": "เวลา: ไปเย็นวันที่ 7 รอบ 12 (นอนต่อ = ฉากจบ)",
			"call": func(): EventManager.time_system.set_date(TimeSystem.TOTAL_WEEKS, TimeSystem.DAYS_PER_WEEK, TimeSystem.TIME.EVENING),
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


func _start_shop_loop() -> void:
	DayLoop.force_active = true
	get_tree().change_scene_to_file(Constant.ROOM_SCENE)


func _on_jump_point_pressed(point: Dictionary) -> void:
	if point.has("call"):
		(point["call"] as Callable).call()
		visible = false
		return
	if point.has("minigame"):
		_open_minigame(point["minigame"])
		visible = false
		return
	EventManager.jump_event(point["event_id"], point["task_index"])
	if point.get("scene", "") != "":
		get_tree().change_scene_to_file(point["scene"])
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == TOGGLE_KEY:
		visible = !visible
		get_viewport().set_input_as_handled()


## เปิดมินิเกมเป็นลูกของฉากปัจจุบัน แบบไม่ผูกเควสต์ (มินิเกมเห็น meta "standalone" แล้วจะไม่เรียก EventManager.minigame_end)
func _open_minigame(path: String) -> void:
	var cs := get_tree().current_scene
	for c in cs.get_children():
		if c is PartMinigame:
			return
	var m := (load(path) as PackedScene).instantiate()
	m.set_meta("standalone", true)
	cs.add_child(m)
	Global.in_minigame = true
