class_name PerkPicker extends Control
## [Claude 16 พ.ย. 2569 · 0.5.0 ขั้น I] หน้าเลื่อนยศ: ยศใหม่ปลดอะไร + เลือกความสามารถช่าง 1 ใน 2 (PerkLayer ชั้น 112 ใน day_loop.tscn)
## แสดงผลอย่างเดียว ← DayLoop.perk_view() · กดเลือก → chosen(rank, id) (DayLoop เรียก GameState.choose_perk)

signal chosen(rank: int, id: StringName)

var _rank := 0


func _ready() -> void:
	visible = false
	%A.pressed.connect(func() -> void: _pick(0))
	%B.pressed.connect(func() -> void: _pick(1))


## v = { rank, title, unlocks: PackedStringArray, options: [{id, name, desc}, {…}] }
func show_view(v: Dictionary) -> void:
	_rank = int(v.get("rank", 0))
	%Title.text = String(v.get("title", ""))
	var lines: PackedStringArray = v.get("unlocks", PackedStringArray())
	%Unlocks.text = "ยศนี้ปลด\n• " + "\n• ".join(lines) if not lines.is_empty() else ""
	%Unlocks.visible = not lines.is_empty()
	var opts: Array = v.get("options", [])
	for i in 2:
		var b: Button = %A if i == 0 else %B
		if i < opts.size():
			b.visible = true
			b.text = "%s\n%s" % [opts[i].name, opts[i].desc]
			b.set_meta("id", StringName(opts[i].id))
		else:
			b.visible = false
	visible = true


func _pick(i: int) -> void:
	var b: Button = %A if i == 0 else %B
	visible = false
	chosen.emit(_rank, StringName(b.get_meta("id", "")))
