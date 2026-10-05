extends Node
## [Claude 5 ต.ค. 2569] ทดสอบ QTE: ตัว runner (A จังหวะ · B กดค้าง) ด้วยการจำลองคลิก + RAM INSTALL ทั้งผ่าน/พลาด
## เปิด Test/qte_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0
var _clicking_pib := false


func _ready() -> void:
	await get_tree().process_frame
	var layer := CanvasLayer.new()
	add_child(layer)
	var q := QteRunner.new()
	layer.add_child(q)
	await _frames(1)

	# A จังหวะ: รอให้ตัวชี้เข้าโซน PERFECT แล้วคลิก
	var a := QteSpec.new()
	a.duration = 1.0
	var t := _run(q, a)
	while q._value < 0.49 or q._value > 0.51:
		await get_tree().process_frame
	_mouse(true)
	_check(await _result(t) == QteRunner.Result.PERFECT, "A จังหวะ กดกลางโซน = PERFECT")
	_mouse(false)
	t = _run(q, a)
	await _frames(3)   # ตัวชี้ยังอยู่ซ้ายสุด
	_mouse(true)
	_check(await _result(t) == QteRunner.Result.MISS, "A จังหวะ กดเร็วไป = MISS")
	_mouse(false)

	# B กดค้าง
	var b: QteSpec = load("res://Resources/Qte/ram_press.tres")
	t = _run(q, b)
	_key(true)
	while q._value < 0.8:
		await get_tree().process_frame
	_key(false)
	var rb = await _result(t)
	_check(rb != QteRunner.Result.MISS, "B กดค้าง ปล่อยในโซน = ผ่าน (%s · %.2f)" % [rb, q.last_value])
	t = _run(q, b)
	_key(true)
	await _result_of(t)
	_key(false)
	_check(t.result == QteRunner.Result.MISS and q.last_value >= 1.0, "B กดค้างจนสุดเกจ = MISS แรงเกิน")
	t = _run(q, b)
	_key(true)
	await _frames(3)
	_key(false)
	_check(await _result(t) == QteRunner.Result.MISS and q.last_value < b.zone.x, "B ปล่อยเร็ว = MISS ไม่ลงสุด")
	_check(not q.running and q.mouse_filter == Control.MOUSE_FILTER_IGNORE, "จบแล้วไม่บังคลิก")

	# RAM INSTALL ทั้งเส้น (บอท)
	_click_pib_forever()
	for mode in [QteRunner.Result.PERFECT, QteRunner.Result.MISS]:
		QteRunner.auto_result = mode
		var ram: PartMinigame = load("res://Scene/MiniGame/PartRam/part_ram.tscn").instantiate()
		add_child(ram)
		await _frames(2)
		ram.debug_jump(6)   # INSTALL
		await _frames(2)
		var ph = ram._phase_nodes[6]
		ph._on_installed(ram.get_node("%RamA2"), ram.get_node("%SlotA2"))
		var waited := 0.0
		while ram.current_phase == 6 and waited < 15.0:
			await get_tree().create_timer(0.1).timeout
			waited += 0.1
		var name := "PERFECT" if mode == QteRunner.Result.PERFECT else "MISS ทุกครั้ง"
		_check(ram.current_phase == 7, "RAM INSTALL บอท %s → ไป VERIFY (%.1f วิ)" % [name, waited])
		_check(ram.ram_seated, "RAM INSTALL บอท %s → แรมลงสุด" % name)
		var lost: int = ram._mistakes.get(&"handling", 0)
		_check(lost == (0 if mode == QteRunner.Result.PERFECT else 10), "RAM INSTALL บอท %s → หัก handling %d" % [name, lost])
		ram.queue_free()
		await _frames(2)
	QteRunner.auto_result = -1
	_clicking_pib = false
	print("T DONE fails=", fails)
	get_tree().quit()


class Task:
	var result := -1
	var done := false


func _run(q: QteRunner, spec: QteSpec) -> Task:
	var task := Task.new()
	var go := func():
		task.result = await q.run(spec)
		task.done = true
	go.call()
	return task


func _result(task: Task) -> int:
	while not task.done:
		await get_tree().process_frame
	return task.result


func _result_of(task: Task) -> void:
	while not task.done:
		await get_tree().process_frame


func _mouse(down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.position = Vector2(576, 300)
	get_viewport().push_input(e)


func _key(down: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = KEY_SPACE
	e.keycode = KEY_SPACE
	e.pressed = down
	get_viewport().push_input(e)


## กดปิดกล่องคำพูดปิ๊บให้เรื่อย ๆ (แทนผู้เล่น)
func _click_pib_forever() -> void:
	_clicking_pib = true
	while _clicking_pib:
		await get_tree().create_timer(0.15).timeout
		var pib = Global.cur_pib
		if pib and is_instance_valid(pib) and pib.dialog_panel.visible:
			pib._on_dialog_panel_pressed()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
