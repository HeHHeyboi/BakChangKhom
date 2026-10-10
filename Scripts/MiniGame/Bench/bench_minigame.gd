class_name BenchMinigame extends PartMinigame
## โต๊ะหลังเครื่อง (Lv2) — มองหลังเคส: ช่อง USB · จอ · LAN · เสียง · การ์ดจอ · ปลั๊กไฟ + อุปกรณ์ของลูกค้า
## คลิกหัวสาย (เลือก) → คลิกช่อง (เสียบ) · คลิกหัวสายที่เสียบอยู่ = ถอด · ปุ่มสวิตช์ PSU เปิด/ปิดเครื่อง
## ขั้น: ฟังลูกค้า → ลงมือ → ลองใช้ให้ลูกค้าดู → อธิบาย → สรุป (คะแนนแบบเดียวกับ ขมOS)
## ข้อมูลงาน = BenchTask (Resources/Bench/*.tres) · [Claude 10 ต.ค. 2569]

enum Step { LISTEN, WORK, EXPLAIN, SUMMARY, DONE }

const CAP := { &"fix": 40, &"safety": 30, &"listen": 20, &"explain": 10 }
const CAT_NAMES := { &"fix": "ทำงานสำเร็จ", &"safety": "ปลอดภัย", &"listen": "ฟังลูกค้า", &"explain": "อธิบาย" }
const SCREEN := Vector2(1152, 648)
const C_INK := Color(0.16, 0.12, 0.09)
const C_PANEL := Color(0.97, 0.94, 0.87)
## ตำแหน่งช่องหลังเครื่อง (พิกัดจอ)
const PORT_RECTS := {
	"usb1": Rect2(352, 92, 42, 18), "usb2": Rect2(352, 118, 42, 18),
	"usb3": Rect2(404, 92, 42, 18), "usb4": Rect2(404, 118, 42, 18),
	"hdmi_mb": Rect2(352, 162, 54, 20), "lan": Rect2(418, 156, 34, 30), "audio": Rect2(360, 220, 24, 24),
	"hdmi_gpu": Rect2(362, 414, 54, 20), "dp_gpu": Rect2(432, 414, 48, 20), "power": Rect2(358, 532, 48, 40),
}
const PORT_NAMES := {
	"usb1": "USB 1", "usb2": "USB 2", "usb3": "USB 3", "usb4": "USB 4", "hdmi_mb": "จอ (เมนบอร์ด)", "lan": "สายแลน",
	"audio": "เสียง", "hdmi_gpu": "จอ (การ์ดจอ)", "dp_gpu": "DP (การ์ดจอ)", "power": "ไฟเข้า",
}
const PLUG_NAMES := { "keyboard": "คีย์บอร์ด", "mouse": "เมาส์", "monitor": "สายจอ", "power": "ปลั๊กไฟ" }
const PLUG_COLORS := {
	"keyboard": Color(0.3, 0.55, 0.85), "mouse": Color(0.35, 0.7, 0.4), "monitor": Color(0.85, 0.55, 0.2), "power": Color(0.35, 0.35, 0.38),
}
## ที่พักหัวสายตอนไม่ได้เสียบ (ข้างอุปกรณ์)
const PLUG_REST := {
	"monitor": Vector2(800, 200), "keyboard": Vector2(800, 345), "mouse": Vector2(800, 488), "power": Vector2(980, 488),
}
const TOOLS := ["แปรงขนนุ่ม", "ลูกยางเป่าลม", "ผ้าชุบน้ำ"]

signal step_changed(step: Step)

@export var task: BenchTask

var step: Step = Step.LISTEN
var customer_name := "ลูกค้า"
var plugs: Dictionary = { } # plug → port ("" = ไม่ได้เสียบ)
var pc_on := true
var selected_plug := ""
var spots: Array[int] = [] # 2 = ติดแน่น · 1 = หลุดแล้ว (ต้องเป่า) · 0 = สะอาด
var wet := false
var tool := 0
var check_fails := 0
var notes: PackedStringArray = []
var _trap_hit: Dictionary = { }

var _ui: Control
var _board: Control
var _plug_btns: Dictionary = { }
var _modal: ColorRect
var _bubble: Label
var _check_btn: Button
var _note_box: VBoxContainer
var _ask_note: Label
var _clean_panel: Panel
var _spot_btns: Array[Button] = []
var _status: Label


func _ready() -> void:
	_mistakes = { &"fix": 0, &"safety": 0, &"listen": 0, &"explain": 0 }
	if dialog_path.is_empty():
		dialog_path = "res://Assets/Dialog/MiniGame/Desktop_Pib.txt"
	part_id = &"part_bench"
	minigame_finished.connect(_on_minigame_finished)
	if has_meta("work_order"):
		var order = get_meta("work_order")
		if order is CustomerCase:
			customer_name = order.customer
			if order.get("bench_task") is BenchTask:
				task = order.bench_task
	super._ready()
	if task == null:
		push_error("BenchMinigame: ไม่มี BenchTask")
		_finish.call_deferred(false)
		return
	for k in BenchTask.PLUGS:
		plugs[k] = String(task.start_plugs.get(k, ""))
	spots.clear()
	for i in task.dirt_spots:
		spots.append(2)
	_build_ui()
	_open_ask()


func _on_minigame_finished(_score: Dictionary) -> void:
	Global.in_minigame = false
	Global.cur_pib = null
	EventManager.minigame_end()
	call_deferred("queue_free")

# ================================================================ ตรรกะ (เรียกจากเทสต์ได้)


func lose(cat: StringName, pts: int, note := "") -> void:
	var cur: int = _mistakes.get(cat, 0)
	var add := mini(pts, int(CAP.get(cat, 100)) - cur)
	if add > 0:
		_on_mistake(cat, add)
	if note != "" and not notes.has(note):
		notes.append(note)


func _trap(id: StringName, cat: StringName, pts: int, note: String) -> void:
	if not task.traps.has(id) or _trap_hit.has(id):
		return
	_trap_hit[id] = true
	lose(cat, pts, note)


func score_of(cat: StringName) -> int:
	return int(CAP.get(cat, 0)) - int(_mistakes.get(cat, 0))


func ask(i: int) -> String:
	if step != Step.LISTEN:
		return ""
	var good := i == task.ask_best
	if not good:
		lose(&"listen", 10, "ถามลูกค้าไม่ตรงประเด็น")
	elif task.ask_note != "" and is_instance_valid(_ask_note):
		_ask_note.text = task.ask_note
		_ask_note.show()
	_set_step(Step.WORK)
	return task.ask_answer if good else task.ask_answer_wrong


## ถอดสาย · ดึงปลั๊กไฟตอนเครื่องเปิด = กับดัก
func unplug(plug: String) -> void:
	if plugs.get(plug, "") == "":
		return
	if plug == "power" and pc_on:
		_trap(&"pull_power", &"safety", 10, "ดึงปลั๊กไฟตอนเครื่องยังเปิดอยู่")
		say("ดึงปลั๊กตอนเครื่องเปิด เหมือนไฟดับกะทันหัน งานลูกค้าหายได้ ปิดเครื่องก่อนนะ", PibHint.Mood.WORRY)
		pc_on = false
	plugs[plug] = ""
	_refresh()


## เสียบสาย plug ลงช่อง port · คืน "" = เสียบได้ · อื่น ๆ = เหตุผล
func plug_in(plug: String, port: String) -> String:
	if not BenchTask.PLUGS.has(plug) or not BenchTask.PORTS.has(port):
		return "ไม่มีสาย/ช่องนี้"
	for k in plugs:
		if plugs[k] == port and k != plug:
			return "ช่องนี้มีสาย%sเสียบอยู่แล้ว" % PLUG_NAMES[k]
	if BenchTask.PLUGS[plug] != BenchTask.PORTS[port]:
		_trap(&"force_plug", &"safety", 5, "ฝืนเสียบหัวสายผิดชนิด (%s → %s)" % [PLUG_NAMES[plug], PORT_NAMES[port]])
		say("เสียบไม่เข้าอย่าฝืน! หัวกับช่องคนละแบบ ดูรูปร่างช่องก่อน", PibHint.Mood.WORRY)
		return "หัวสายกับช่องคนละแบบ เสียบไม่เข้า"
	plugs[plug] = port
	selected_plug = ""
	_refresh()
	return ""


func set_power(on: bool) -> void:
	if on and plugs.get("power", "") == "":
		return
	pc_on = on
	_refresh()


func device_ok(plug: String) -> bool:
	var port: String = plugs.get(plug, "")
	if port == "" or not pc_on or plugs.get("power", "") == "":
		return false
	match plug:
		"keyboard", "mouse":
			return port != task.broken_port and BenchTask.PORTS[port] == "usb" and not (plug == "keyboard" and wet)
		"monitor":
			return port == "hdmi_gpu" if task.has_gpu else port == "hdmi_mb"
	return true


## ทำความสะอาดจุด i ด้วยเครื่องมือ tool (0 แปรง · 1 ลูกยาง · 2 ผ้าชุบน้ำ)
func clean_spot(i: int, t: int = -1) -> void:
	if t < 0:
		t = tool
	if i < 0 or i >= spots.size():
		return
	if plugs.get("keyboard", "") != "":
		_trap(&"clean_plugged", &"safety", 10, "ทำความสะอาดคีย์บอร์ดทั้งที่ยังเสียบอยู่")
		say("ถอดสายคีย์บอร์ดก่อน! ไม่งั้นปุ่มโดนกดมั่วไปหมด", PibHint.Mood.WORRY)
	match t:
		0:
			if spots[i] == 2:
				spots[i] = 1
		1:
			if spots[i] == 1:
				spots[i] = 0
			elif spots[i] == 2:
				say("ติดแน่นอยู่ เป่าไม่ออก ใช้แปรงปัดให้หลุดก่อน")
			if wet:
				wet = false
				say("เป่าแห้งแล้ว ต่อไปห้ามใช้น้ำกับคีย์บอร์ดนะ")
		2:
			_trap(&"water", &"safety", 10, "ใช้ผ้าชุบน้ำเช็ดคีย์บอร์ด")
			wet = true
			say("น้ำเข้าใต้ปุ่มแล้ว! ไฟฟ้ากับน้ำไม่ถูกกัน ใช้ลูกยางเป่าให้แห้งก่อน", PibHint.Mood.WORRY)
	_refresh()


func dirt_left() -> int:
	return spots.count(2) + spots.count(1)


func check() -> String:
	if step != Step.WORK:
		return "ยังไม่ถึงขั้นนี้"
	var why := _check_reason()
	if why != "":
		check_fails += 1
		lose(&"fix", 10, "ส่งงานแล้วยังไม่เรียบร้อย %d ครั้ง" % check_fails)
		return why
	_set_step(Step.EXPLAIN)
	return ""


func _check_reason() -> String:
	if plugs.get("power", "") == "":
		return "เครื่องไม่ติดเลย ปลั๊กไฟยังไม่ได้เสียบ"
	if not pc_on:
		return "เครื่องยังปิดอยู่ (เปิดสวิตช์ที่ PSU)"
	match task.goal:
		BenchTask.Goal.USB_DEVICE:
			if not device_ok("mouse"):
				return "ขยับเมาส์แล้ว ลูกศรบนจอไม่ขยับเลย"
			if not device_ok("keyboard"):
				return "กดคีย์บอร์ดแล้วไม่มีตัวหนังสือขึ้น"
		BenchTask.Goal.DISPLAY_CABLE:
			if not device_ok("monitor"):
				return "จอยังขึ้นว่า \"ไม่มีสัญญาณ\""
		BenchTask.Goal.CLEAN_KEYBOARD:
			if dirt_left() > 0:
				return "ยังมีเศษขนมติดใต้ปุ่มอยู่ %d จุด ปุ่มยังติด" % dirt_left()
			if wet:
				return "ปุ่มยังเปียก พิมพ์ติด ๆ ดับ ๆ"
			if not device_ok("keyboard"):
				return "เสียบคีย์บอร์ดกลับแล้วยังพิมพ์ไม่ได้"
	if not device_ok("monitor"):
		return "จอไม่ขึ้นภาพ"
	return ""


func explain(i: int) -> void:
	if step != Step.EXPLAIN:
		return
	if i != task.explain_best:
		lose(&"explain", 10, "อธิบายให้ลูกค้าไม่ตรง")
	_set_step(Step.SUMMARY)


func finish() -> void:
	if step == Step.DONE:
		return
	_set_step(Step.DONE)
	_finish(true)


func _set_step(s: Step) -> void:
	step = s
	step_changed.emit(s)
	_refresh()


func say(text: String, mood := PibHint.Mood.NORMAL) -> void:
	if is_instance_valid(pib):
		pib.toast(DialogToken.new(PibHint.DEFAULT_SPEAKER, text), 3.6, mood)

# ================================================================ UI


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Bench"
	layer.layer = 5
	add_child(layer)
	_ui = Control.new()
	_ui.name = "Screen"
	_ui.size = SCREEN
	layer.add_child(_ui)
	_board = Board.new()
	_board.m = self
	_board.size = SCREEN
	_board.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(_board)
	# ช่อง
	for port in PORT_RECTS:
		var b := Button.new()
		b.name = "Port_" + port
		b.flat = true
		b.tooltip_text = PORT_NAMES[port]
		b.focus_mode = Control.FOCUS_NONE
		b.position = (PORT_RECTS[port] as Rect2).position - Vector2(4, 4)
		b.size = (PORT_RECTS[port] as Rect2).size + Vector2(8, 8)
		b.pressed.connect(_on_port.bind(port))
		_ui.add_child(b)
	# หัวสาย
	for plug in BenchTask.PLUGS:
		var b := Button.new()
		b.name = "Plug_" + plug
		b.text = PLUG_NAMES[plug]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(86, 26)
		b.add_theme_font_size_override("font_size", 13)
		var sb := StyleBoxFlat.new()
		sb.bg_color = PLUG_COLORS[plug]
		sb.border_color = C_INK
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(5)
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, sb)
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.7))
		b.pressed.connect(_on_plug.bind(plug))
		_ui.add_child(b)
		_plug_btns[plug] = b
	# สวิตช์ PSU
	var sw := Button.new()
	sw.name = "PowerSwitch"
	sw.focus_mode = Control.FOCUS_NONE
	sw.position = Vector2(424, 536)
	sw.size = Vector2(70, 34)
	sw.pressed.connect(func(): set_power(not pc_on))
	_ui.add_child(sw)
	# กระดาษโน้ต + ปุ่มตรวจ
	var note := PanelContainer.new()
	note.position = Vector2(16, 16)
	note.custom_minimum_size = Vector2(262, 0)
	note.add_theme_stylebox_override("panel", _style(Color(1, 0.93, 0.55), 10))
	_ui.add_child(note)
	_note_box = VBoxContainer.new()
	note.add_child(_note_box)
	_status = _label("", 14, Color(0.4, 0.3, 0.2))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_check_btn = Button.new()
	_check_btn.name = "CheckButton"
	_check_btn.text = "✔ ลองใช้ให้ลูกค้าดู"
	_check_btn.focus_mode = Control.FOCUS_NONE
	_check_btn.position = Vector2(30, 560)
	_check_btn.custom_minimum_size = Vector2(230, 44)
	_check_btn.pressed.connect(_on_check_pressed)
	_ui.add_child(_check_btn)
	if task.goal == BenchTask.Goal.CLEAN_KEYBOARD:
		var cb := Button.new()
		cb.name = "OpenClean"
		cb.text = "ยกคีย์บอร์ดมาทำความสะอาด"
		cb.focus_mode = Control.FOCUS_NONE
		cb.position = Vector2(830, 300)
		cb.pressed.connect(open_clean)
		_ui.add_child(cb)
	_bubble = _label("", 17, C_INK)
	_bubble.position = Vector2(300, 612)
	_bubble.size = Vector2(840, 30)
	_ui.add_child(_bubble)
	_modal = ColorRect.new()
	_modal.color = Color(0, 0, 0, 0.45)
	_modal.size = SCREEN
	_modal.hide()
	_ui.add_child(_modal)
	_refresh()


func _style(c: Color, r := 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.border_color = C_INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(r)
	sb.set_content_margin_all(12)
	return sb


func _label(t: String, fs: int, c: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _plug_pos(plug: String) -> Vector2:
	var port: String = plugs.get(plug, "")
	if port == "":
		return PLUG_REST[plug]
	var r: Rect2 = PORT_RECTS[port]
	return Vector2(r.position.x + r.size.x + 4, r.position.y + r.size.y / 2.0 - 13)


func _refresh() -> void:
	if not is_instance_valid(_ui):
		return
	for plug in _plug_btns:
		var b: Button = _plug_btns[plug]
		b.position = _plug_pos(plug)
		b.modulate = Color(1.3, 1.3, 0.7) if plug == selected_plug else Color.WHITE
		b.text = PLUG_NAMES[plug] + (" ✓" if plug == selected_plug else "")
	(_ui.get_node("PowerSwitch") as Button).text = "เปิดอยู่" if pc_on else "ปิดอยู่"
	for c in _note_box.get_children():
		c.queue_free()
	var t := _label(task.title, 18, C_INK)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note_box.add_child(t)
	var rq := _label(task.request, 13, Color(0.4, 0.3, 0.2))
	rq.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note_box.add_child(rq)
	_ask_note = _label(task.ask_note if step > Step.LISTEN and _mistakes.get(&"listen", 0) == 0 else "", 14, Color(0.7, 0.2, 0.1))
	_ask_note.visible = _ask_note.text != ""
	_note_box.add_child(_ask_note)
	var done := [step > Step.LISTEN, step > Step.WORK, step > Step.WORK, step > Step.EXPLAIN]
	var lines := ["ฟังลูกค้า", "ดูอาการ + ลงมือ", "ลองใช้ให้ลูกค้าดู", "อธิบายให้ลูกค้าฟัง"]
	for i in lines.size():
		_note_box.add_child(_label(("☑ " if done[i] else "☐ ") + lines[i], 15, C_INK))
	_check_btn.disabled = step != Step.WORK
	if is_instance_valid(_clean_panel) and _clean_panel.visible:
		_refresh_clean()
	_board.queue_redraw()


func _on_port(port: String) -> void:
	if step != Step.WORK:
		return
	if selected_plug == "":
		for k in plugs:
			if plugs[k] == port:
				_bubble.text = "ช่อง %s: สาย%s" % [PORT_NAMES[port], PLUG_NAMES[k]]
				return
		_bubble.text = "ช่อง %s ว่างอยู่ — คลิกหัวสายก่อน แล้วค่อยคลิกช่อง" % PORT_NAMES[port]
		return
	var r := plug_in(selected_plug, port)
	_bubble.text = r if r != "" else "เสียบเข้าช่อง %s แล้ว" % PORT_NAMES[port]


func _on_plug(plug: String) -> void:
	if step != Step.WORK:
		return
	if plugs.get(plug, "") != "":
		unplug(plug)
		selected_plug = plug
		_bubble.text = "ถอด%sแล้ว — คลิกช่องที่จะเสียบ" % PLUG_NAMES[plug]
	else:
		selected_plug = "" if selected_plug == plug else plug
	_refresh()

# ---------------------------------------------------------------- ทำความสะอาดคีย์บอร์ด


func open_clean() -> void:
	if not is_instance_valid(_clean_panel):
		_clean_panel = Panel.new()
		_clean_panel.name = "CleanPanel"
		_clean_panel.position = Vector2(150, 90)
		_clean_panel.size = Vector2(850, 440)
		_clean_panel.add_theme_stylebox_override("panel", _style(C_PANEL, 14))
		_ui.add_child(_clean_panel)
		_clean_panel.move_to_front()
	_clean_panel.show()
	_refresh_clean()


func close_clean() -> void:
	if is_instance_valid(_clean_panel):
		_clean_panel.hide()


func _refresh_clean() -> void:
	for c in _clean_panel.get_children():
		c.queue_free()
	_spot_btns.clear()
	var title := _label("ทำความสะอาดคีย์บอร์ด%s" % ("  (ยังเสียบสายอยู่!)" if plugs.get("keyboard", "") != "" else ""), 20, C_INK)
	title.position = Vector2(20, 12)
	_clean_panel.add_child(title)
	var kb := ColorRect.new()
	kb.color = Color(0.82, 0.83, 0.86) if not wet else Color(0.6, 0.72, 0.9)
	kb.position = Vector2(40, 60)
	kb.size = Vector2(770, 250)
	kb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clean_panel.add_child(kb)
	for r in 4:
		for c in 14:
			var key := ColorRect.new()
			key.color = Color(0.97, 0.97, 0.98)
			key.position = Vector2(52 + c * 54, 74 + r * 58)
			key.size = Vector2(46, 46)
			key.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_clean_panel.add_child(key)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in spots.size():
		var b := Button.new()
		b.name = "Spot%d" % i
		b.focus_mode = Control.FOCUS_NONE
		b.position = Vector2(rng.randi_range(60, 760), rng.randi_range(80, 270))
		b.size = Vector2(30, 30)
		var sb := StyleBoxFlat.new()
		sb.bg_color = [Color(0, 0, 0, 0), Color(0.75, 0.6, 0.35), Color(0.5, 0.33, 0.15)][spots[i]]
		sb.set_corner_radius_all(15)
		for st in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(st, sb)
		b.disabled = spots[i] == 0
		b.pressed.connect(clean_spot.bind(i, -1))
		_clean_panel.add_child(b)
		_spot_btns.append(b)
	var row := HBoxContainer.new()
	row.position = Vector2(40, 330)
	row.add_theme_constant_override("separation", 10)
	_clean_panel.add_child(row)
	row.add_child(_label("เครื่องมือ:", 17, C_INK))
	for i in TOOLS.size():
		var tb := Button.new()
		tb.name = "Tool%d" % i
		tb.text = TOOLS[i] + (" ✓" if i == tool else "")
		tb.focus_mode = Control.FOCUS_NONE
		tb.pressed.connect(func():
			tool = i
			_refresh_clean())
		row.add_child(tb)
	var info := _label("เหลือ %d จุด · ปัดด้วยแปรงให้หลุด แล้วเป่าออกด้วยลูกยาง" % dirt_left(), 15, Color(0.4, 0.3, 0.2))
	info.position = Vector2(40, 380)
	_clean_panel.add_child(info)
	var close := Button.new()
	close.text = "เสร็จ วางคีย์บอร์ดกลับ"
	close.focus_mode = Control.FOCUS_NONE
	close.position = Vector2(620, 380)
	close.pressed.connect(close_clean)
	_clean_panel.add_child(close)

# ---------------------------------------------------------------- ฟัง · ตรวจ · อธิบาย · สรุป


func _modal_window(title: String, size: Vector2) -> OsWindow:
	for c in _modal.get_children():
		c.queue_free()
	var w := OsWindow.make("modal", title, null, size)
	w.closable = false
	w.close_btn.hide()
	w.min_btn.hide()
	w.position = (SCREEN - size) / 2.0 - Vector2(0, 30)
	_modal.add_child(w)
	_modal.show()
	_modal.move_to_front()
	return w


func _close_modal() -> void:
	for c in _modal.get_children():
		c.queue_free()
	_modal.hide()


func _open_ask() -> void:
	var w := _modal_window("คุยกับ" + customer_name, Vector2(560, 300))
	var req := _label("%s: \"%s\"" % [customer_name, task.request], 18, C_INK)
	req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	w.body.add_child(req)
	w.body.add_child(_label("ก่อนลงมือ ถามอะไรลูกค้าก่อนดี?", 16, Color(0.4, 0.35, 0.3)))
	for i in task.ask_options.size():
		var b := Button.new()
		b.name = "Ask%d" % i
		b.text = task.ask_options[i]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 40
		b.pressed.connect(func():
			var ans := ask(i)
			_close_modal()
			_bubble.text = "%s: %s" % [customer_name, ans]
			if is_instance_valid(pib) and not task.pib_intro.is_empty():
				pib.say(Array(task.pib_intro)))
		w.body.add_child(b)


func _on_check_pressed() -> void:
	var why := check()
	if why != "":
		_bubble.text = "%s: %s" % [customer_name, why]
		return
	_open_explain()


func _open_explain() -> void:
	var w := _modal_window("อธิบายให้%sฟัง" % customer_name, Vector2(600, 300))
	w.body.add_child(_label("ใช้ได้แล้ว! บอกลูกค้าว่าอะไรดี?", 18, C_INK))
	for i in task.explain_options.size():
		var b := Button.new()
		b.name = "Explain%d" % i
		b.text = task.explain_options[i]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(560, 44)
		b.pressed.connect(func():
			explain(i)
			_open_summary()
			if is_instance_valid(pib) and not task.pib_lesson.is_empty():
				pib.say(Array(task.pib_lesson), PibHint.Mood.HAPPY))
		w.body.add_child(b)


func _open_summary() -> void:
	var score := final_score()
	var w := _modal_window("สรุปงาน — " + task.title, Vector2(520, 400))
	var grade := "⭐⭐⭐" if score >= 90 else ("⭐⭐" if score >= 75 else ("⭐" if score >= 60 else "ไม่ผ่าน"))
	w.body.add_child(_label("คะแนน %d / 100   %s" % [score, grade], 24, C_INK))
	for cat in [&"fix", &"safety", &"listen", &"explain"]:
		w.body.add_child(_label("• %s  %d / %d" % [CAT_NAMES[cat], score_of(cat), CAP[cat]], 17, C_INK))
	for n in notes:
		var l := _label("– " + n, 14, Color(0.6, 0.25, 0.15))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		w.body.add_child(l)
	var b := Button.new()
	b.name = "Finish"
	b.text = "ส่งเครื่องคืนลูกค้า"
	b.custom_minimum_size = Vector2(200, 42)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.pressed.connect(finish)
	w.body.add_child(b)

# ================================================================ วาดหลังเครื่อง


class Board extends Control:
	var m: BenchMinigame

	func _draw() -> void:
		var ink := Color(0.16, 0.12, 0.09)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.42, 0.28, 0.18))
		draw_rect(Rect2(0, 470, size.x, 178), Color(0.55, 0.36, 0.22))
		draw_line(Vector2(0, 470), Vector2(size.x, 470), Color(0.7, 0.5, 0.32), 3)
		# หลังเคส
		draw_rect(Rect2(300, 30, 420, 580), Color(0.21, 0.22, 0.25))
		draw_rect(Rect2(300, 30, 420, 580), ink, false, 4)
		# พัดลมระบายอากาศ
		draw_circle(Vector2(610, 150), 70, Color(0.15, 0.15, 0.17))
		for r in [60, 44, 28]:
			draw_arc(Vector2(610, 150), r, 0, TAU, 40, Color(0.35, 0.36, 0.4), 2)
		# แผ่น I/O
		draw_rect(Rect2(338, 72, 136, 290), Color(0.62, 0.64, 0.68))
		draw_rect(Rect2(338, 72, 136, 290), ink, false, 2)
		_port_label("USB", Vector2(352, 88))
		# ช่องขยาย + การ์ดจอ
		draw_rect(Rect2(330, 396, 370, 48), Color(0.55, 0.57, 0.62) if m.task.has_gpu else Color(0.3, 0.31, 0.34))
		draw_rect(Rect2(330, 396, 370, 48), ink, false, 2)
		if m.task.has_gpu:
			_port_label("การ์ดจอ", Vector2(500, 412))
		for y in [456, 480]:
			draw_rect(Rect2(330, y, 370, 18), Color(0.3, 0.31, 0.34))
		# PSU
		draw_rect(Rect2(330, 510, 370, 90), Color(0.17, 0.17, 0.19))
		draw_rect(Rect2(330, 510, 370, 90), ink, false, 2)
		draw_circle(Vector2(610, 555), 34, Color(0.12, 0.12, 0.13))
		for r in [28, 18]:
			draw_arc(Vector2(610, 555), r, 0, TAU, 32, Color(0.35, 0.36, 0.4), 2)
		# ช่องทั้งหมด
		for port in BenchMinigame.PORT_RECTS:
			var r: Rect2 = BenchMinigame.PORT_RECTS[port]
			var kind: String = BenchTask.PORTS[port]
			var col: Color = {"usb": Color(0.15, 0.3, 0.75), "hdmi": Color(0.1, 0.1, 0.1), "lan": Color(0.85, 0.75, 0.3),
				"audio": Color(0.4, 0.75, 0.35), "dp": Color(0.1, 0.1, 0.1), "power": Color(0.08, 0.08, 0.08)}.get(kind, Color.BLACK)
			if kind == "audio":
				draw_circle(r.get_center(), r.size.x / 2.0, col)
				draw_arc(r.get_center(), r.size.x / 2.0, 0, TAU, 20, ink, 2)
			else:
				draw_rect(r, col)
				draw_rect(r, ink, false, 2)
		# อุปกรณ์ลูกค้า (ขวา)
		_device(Rect2(800, 40, 330, 150), "จอ", m.device_ok("monitor"), "ขึ้นภาพ" if m.device_ok("monitor") else "ไม่มีสัญญาณ")
		_device(Rect2(800, 230, 330, 100), "คีย์บอร์ด", m.device_ok("keyboard"), "ไฟ Caps Lock ติด" if m.device_ok("keyboard") else "ไฟไม่ติด")
		_device(Rect2(800, 380, 160, 96), "เมาส์", m.device_ok("mouse"), "ไฟใต้เมาส์ติด" if m.device_ok("mouse") else "ไม่มีไฟ")
		_device(Rect2(980, 380, 150, 96), "ปลั๊กผนัง", m.plugs.get("power", "") != "", "เครื่อง" + ("เปิด" if m.pc_on else "ปิด"))
		# สาย
		for plug in BenchMinigame.PLUG_REST:
			if m.plugs.get(plug, "") == "":
				continue
			var a: Vector2 = m._plug_pos(plug) + Vector2(86, 13)
			var dev: Vector2 = BenchMinigame.PLUG_REST[plug] + Vector2(43, 0)
			var c1: Vector2 = a + Vector2(120, 0)
			var c2: Vector2 = dev + Vector2(-80, 40)
			var pts := PackedVector2Array()
			for i in 25:
				var t := i / 24.0
				var u := 1.0 - t
				pts.append(u * u * u * a + 3 * u * u * t * c1 + 3 * u * t * t * c2 + t * t * t * dev)
			draw_polyline(pts, BenchMinigame.PLUG_COLORS[plug].darkened(0.3), 5, true)

	func _port_label(t: String, at: Vector2) -> void:
		draw_string(get_theme_default_font(), at + Vector2(0, -2), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.1, 0.1, 0.12))

	func _device(r: Rect2, title: String, ok: bool, state: String) -> void:
		draw_rect(r, Color(0.97, 0.94, 0.87))
		draw_rect(r, Color(0.16, 0.12, 0.09), false, 3)
		var f := get_theme_default_font()
		draw_string(f, r.position + Vector2(12, 26), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.16, 0.12, 0.09))
		draw_circle(r.position + Vector2(r.size.x - 20, 20), 8, Color(0.3, 0.85, 0.35) if ok else Color(0.5, 0.5, 0.5))
		draw_string(f, r.position + Vector2(12, 52), state, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.15, 0.5, 0.2) if ok else Color(0.7, 0.2, 0.12))
