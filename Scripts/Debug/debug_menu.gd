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
	jump_points = []
	# [Claude 10 ต.ค. 2569] เควสต์หลัก: กดแล้วขั้นนั้น "เสร็จ" (รวมขั้นก่อนหน้า) → ไปขั้นถัดไป · บันทึกเกมให้ด้วย
	var ev = EventManager.eventMap.get(EventManager.EventID.MAIN)
	if ev:
		for i in ev.totalTask:
			jump_points.append({ "label": "✓ เควสต์ %d เสร็จ: %s" % [i + 1, ev._tasks[i].quest_text_th], "call": _complete_quest.bind(i) })
	jump_points.append({ "label": "✓ จบเควสต์หลักทั้งหมด → เริ่มลูปร้าน", "call": _complete_quest.bind(999) })
	jump_points += [
		{
			# [Claude 2 ต.ค. 2569] เปิดมินิเกมตรง ๆ ไม่แตะเควสต์หลัก (Part ที่ยังไม่มีเควสต์)
			"label": "เล่น Part Mainboard + CPU (ทดสอบ)",
			"minigame": "res://Scene/MiniGame/PartMainboard/part_mainboard.tscn",
		},
		{ "label": "เล่น Part GPU + จัดสาย (ทดสอบ)", "minigame": "res://Scene/MiniGame/PartGpu/part_gpu.tscn" },
		{
			"label": "เล่น Part Front Panel + Dual Channel (ทดสอบ)",
			"minigame": "res://Scene/MiniGame/PartFrontPanel/part_front_panel.tscn",
		},
		{ "label": "เล่น Part BIOS + ลง Windows (ทดสอบ)", "minigame": "res://Scene/MiniGame/PartBios/part_bios.tscn" },
		# [Claude 9 ต.ค. 2569] ขมOS งานบนจอ Lv1 (Resources/Desktop/*.tres)
		{ "label": "ขมOS 1-1 ลงโปรแกรม (ทดสอบ)", "call": _open_desktop.bind("task_install_chat") },
		{ "label": "ขมOS 1-2 ลบไฟล์ซ้ำ (ทดสอบ)", "call": _open_desktop.bind("task_free_space_photos") },
		{ "label": "ขมOS 1-3 ถอนโปรแกรมโฆษณา (ทดสอบ)", "call": _open_desktop.bind("task_uninstall_ads_kid") },
		{ "label": "ขมOS 1-4 ปิดโปรแกรมค้าง (ทดสอบ)", "call": _open_desktop.bind("task_close_hang_shop") },
		{ "label": "ขมOS 1-5 เครื่องพิมพ์ (ทดสอบ)", "call": _open_desktop.bind("task_printer_teacher") },
		{ "label": "ขมOS 1-6 เสียงไม่ออก (ทดสอบ)", "call": _open_desktop.bind("task_sound_headman") },
		{ "label": "ขมOS 1-7 ต่อ Wi-Fi (ทดสอบ)", "call": _open_desktop.bind("task_wifi_girl") },
		{ "label": "ขมOS 1-8 สำรองลง USB (ทดสอบ)", "call": _open_desktop.bind("task_backup_yai") },
		{ "label": "ขมOS 1-9 เปิดพร้อมเครื่อง (ทดสอบ)", "call": _open_desktop.bind("task_startup_amnuay") },
		{ "label": "ขมOS 1-10 อัปเดต (ทดสอบ)", "call": _open_desktop.bind("task_update_office") },
		{ "label": "ขมOS Lv2 สแกนไวรัส (ทดสอบ)", "call": _open_desktop.bind("task_virus_min") },
		{ "label": "ขมOS Lv2 จอภาพ (ทดสอบ)", "call": _open_desktop.bind("task_display_director") },
		# [Claude 9 ต.ค. 2569] ทดสอบลูปกะ/สัปดาห์/เดือน (Docs/LEVEL_DESIGN.md ข้อ 4)
		{ "label": "โต๊ะหลังเครื่อง Lv2: เมาส์ไม่ทำงาน (ทดสอบ)", "minigame": "res://Scene/MiniGame/Bench/back_bench.tscn" },
		{ "label": "ลูปร้าน: ข้ามเควสต์ เริ่มรับลูกค้า (ไปห้องขม)", "call": _start_shop_loop },
		{ "label": "เวลา: ทำงาน +1 ชม.", "call": func() -> void: EventManager.time_system.advance_minutes(60) },
		{ "label": "เวลา: ไปช่วงถัดไป (เย็น → 18:30)", "call": EventManager.advance_period },
		{ "label": "เวลา: ปิดร้าน → กะถัดไป", "call": DayLoop.end_shift },
		{ "label": "เวลา: ไป 18:30 กะสุดท้ายของสัปดาห์", "call": _jump_week_end },
		{ "label": "เดโม: ไป 18:30 กะสุดท้ายของเดโม (กะ 7)", "call": func() -> void: EventManager.time_system.set_shift(maxi(DayLoop.demo_shifts, 1), TimeSystem.CLOSE) },
		{ "label": "ระดับ: ปลด Lv3–Lv5 (ให้ ⭐⭐ ครบ)", "call": _unlock_levels },
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

	# [10 ต.ค.] รายการยาว → เลื่อนได้ (ล้อเมาส์/ลากแถบ)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.custom_minimum_size = Vector2(360, 520)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	_button_list = VBoxContainer.new()
	_button_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_button_list)

	_refresh_buttons()


func _refresh_buttons() -> void:
	for child in _button_list.get_children():
		child.queue_free()

	for point in jump_points:
		var button := Button.new()
		button.text = point["label"]
		button.pressed.connect(_on_jump_point_pressed.bind(point))
		_button_list.add_child(button)


func _jump_week_end() -> void:
	var ts: TimeSystem = EventManager.time_system
	var last := (ts.week() - 1) * TimeSystem.SHIFTS_PER_WEEK + TimeSystem.SHIFTS_PER_WEEK
	ts.set_shift(last, TimeSystem.CLOSE)


func _unlock_levels() -> void:
	for lv in range(2, 5):
		GameState.level_stars[lv] = maxi(GameState.level_stars.get(lv, 0), 2)
	DayLoop.add_jobs(3)


func _complete_quest(index: int) -> void:
	if Global.isInMinigame():
		return
	var ev = EventManager.eventMap.get(EventManager.EventID.MAIN)
	if ev == null:
		return
	Global.on_start = false
	EventManager.tutorial.hide()
	var cur := get_tree().current_scene
	if cur and cur.is_in_group("main_menu"):
		cur.hide() # กดจากเมนูหลัก → ซ่อนเมนู
	EventManager.complete_step(EventManager.EventID.MAIN, mini(index, ev.totalTask - 1))
	EventManager.showUI()
	# ขั้นถัดไปอยู่ที่ไหน: คุยกับยาย/ไปร้าน = ในบ้าน · ที่เหลือ (ร้าน) · จบแล้ว = ร้าน (กระดานงาน)
	var next: int = ev.currentTask
	await SceneRouter.go(SceneRouter.HOME if (not ev.isDone and next <= 1) else SceneRouter.ROOM)
	SaveGame.save() # บันทึกตรง ๆ (autosave อาจข้ามถ้าลูปร้านเปิดบทพักทันที)


func _start_shop_loop() -> void:
	DayLoop.force_active = true
	SceneRouter.go(SceneRouter.ROOM)


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
	if point.has("location"):
		SceneRouter.go(point["location"])
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == TOGGLE_KEY:
		visible = !visible
		get_viewport().set_input_as_handled()


## เปิดมินิเกมเป็น overlay ของ SceneRouter แบบไม่ผูกเควสต์ (มินิเกมเห็น meta "standalone" แล้วจะไม่เรียก EventManager.minigame_end)
## เปิดขมOS ด้วยงาน Resources/Desktop/<task_name>.tres (ไม่คิดเงิน)
func _open_desktop(task_name: String) -> void:
	if Global.isInMinigame():
		return
	var m := (load("res://Scene/MiniGame/Desktop/desktop_window.tscn") as PackedScene).instantiate()
	m.set("task", load("res://Resources/Desktop/%s.tres" % task_name))
	m.set_meta("standalone", true)
	SceneRouter.push_node(m)
	Global.in_minigame = true


func _open_minigame(path: String) -> void:
	if Global.isInMinigame():
		return
	var m := (load(path) as PackedScene).instantiate()
	m.set_meta("standalone", true)
	SceneRouter.push_node(m)
	Global.in_minigame = true
