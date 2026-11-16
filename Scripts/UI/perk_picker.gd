class_name PerkPicker extends Control
## [Claude 16 พ.ย. 2569 · 0.5.0 ขั้น I] หน้าเลื่อนยศ: ยศใหม่ปลดอะไร + เลือกความสามารถช่าง 1 ใน 2 (0.6.0: 1 ใน 3) (PerkLayer ชั้น 112 ใน day_loop.tscn)
## แสดงผลอย่างเดียว ← DayLoop.perk_view() · กดเลือก → chosen(rank, id) (DayLoop เรียก GameState.choose_perk)

signal chosen(rank: int, id: StringName)

var _rank := 0


func _ready() -> void:
	visible = false
	%A.pressed.connect(func() -> void: _pick(0))
	%B.pressed.connect(func() -> void: _pick(1))


## [0.6.0 ขั้น K] ปุ่มทาง C (สร้างจากปุ่ม B ตอนมี 3 ตัวเลือก)
func _buttons() -> Array[Button]:
	var out: Array[Button] = [%A, %B]
	var c := (%B as Button).get_parent().get_node_or_null(^"C") as Button
	if c:
		out.append(c)
	return out


func _ensure_c() -> void:
	var parent := (%B as Button).get_parent()
	if parent.get_node_or_null(^"C") == null:
		var c := (%B as Button).duplicate() as Button
		c.name = "C"
		parent.add_child(c)
		c.pressed.connect(func() -> void: _pick(2))


## v = { rank, title, unlocks: PackedStringArray, options: [{id, name, desc}, {…}] }
func show_view(v: Dictionary) -> void:
	_rank = int(v.get("rank", 0))
	%Title.text = String(v.get("title", ""))
	var lines: PackedStringArray = v.get("unlocks", PackedStringArray())
	%Unlocks.text = "ยศนี้ปลด\n• " + "\n• ".join(lines) if not lines.is_empty() else ""
	%Unlocks.visible = not lines.is_empty()
	var opts: Array = v.get("options", [])
	if opts.size() > 2:
		_ensure_c()
	var btns := _buttons()
	for i in btns.size():
		var b: Button = btns[i]
		if i < opts.size():
			b.visible = true
			b.text = "%s\n%s" % [opts[i].name, opts[i].desc]
			b.set_meta("id", StringName(opts[i].id))
		else:
			b.visible = false
	visible = true


func _pick(i: int) -> void:
	var b: Button = _buttons()[i]
	visible = false
	chosen.emit(_rank, StringName(b.get_meta("id", "")))
