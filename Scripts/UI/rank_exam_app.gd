class_name RankExamApp extends VBoxContainer
## [Claude 16 พ.ย. 2569 · 0.5.0] แอป "สอบช่าง" ในคอมของขม (ShopPC ใส่ผ่าน DesktopMinigameV2.add_custom_app) — สอบเลื่อนยศ (PLAN_0_5_0 ข้อ 5)
## หน้าแรก ← DayLoop.exam_app_view() · กดเริ่ม → DayLoop.exam_begin · กดตัวเลือก → exam_answer (ขึ้นเฉลยทันที) · ครบ → exam_finish
## กติกา/ผลอยู่ที่ DayLoop ทั้งหมด · ฉากนี้แสดงผล + ส่งคำตอบ

@export var choice_style: StyleBox
@export var choice_hover: StyleBox
@export var main_button: StyleBox
@export var main_button_hover: StyleBox
@export var font := Color(0.35, 0.2, 0.08)
@export var good := Color(0.25, 0.5, 0.2)
@export var bad := Color(0.75, 0.25, 0.1)
@export var dim := Color(0.55, 0.5, 0.44)

## หน้าที่แสดงอยู่: &"home" · &"question" · &"feedback" · &"result"
var page: StringName = &"home"


func _ready() -> void:
	%Action.pressed.connect(_on_action)
	if main_button:
		%Action.add_theme_stylebox_override(&"normal", main_button)
		%Action.add_theme_stylebox_override(&"hover", main_button_hover if main_button_hover else main_button)
		%Action.add_theme_stylebox_override(&"pressed", main_button_hover if main_button_hover else main_button)
	var dl := _dl()
	if dl and dl.exam_running():
		page = &"feedback" if not (dl.exam["last"] as Dictionary).is_empty() else &"question"
	refresh()


func _dl() -> Node:
	return get_node_or_null(^"/root/DayLoop")


func refresh() -> void:
	var dl := _dl()
	if dl == null:
		return
	_clear_choices()
	%Feedback.visible = false
	%History.visible = false
	%Sub.visible = false
	%Unlocks.visible = false
	%Image.visible = false
	%Body.visible = true
	match page:
		&"question":
			_show_question(dl.exam_question_view())
		&"feedback":
			_show_feedback(dl)
		&"result":
			_show_result(dl.exam)
		_:
			_show_home(dl.exam_app_view())


func _show_home(v: Dictionary) -> void:
	%Rank.text = String(v.get("rank", ""))
	%Title.text = String(v.get("title", ""))
	%Sub.visible = true
	%Sub.text = String(v.get("sub", ""))
	%Body.visible = false
	var ul: PackedStringArray = v.get("unlocks", PackedStringArray())
	%Unlocks.visible = not ul.is_empty()
	%Unlocks.text = "ผ่านแล้วได้\n• " + "\n• ".join(ul)
	var btn := String(v.get("button", ""))
	%Action.visible = btn != ""
	%Action.text = btn
	var hist: PackedStringArray = v.get("history", PackedStringArray())
	%History.visible = not hist.is_empty()
	%History.text = "ประวัติ: " + " · ".join(hist.slice(0, 3))


func _show_question(q: Dictionary) -> void:
	if q.is_empty():
		page = &"home"
		refresh()
		return
	%Title.text = "ข้อ %d/%d" % [int(q.i), int(q.total)]
	%Rank.text = "หมวด %s" % String(q.get("domain", ""))
	%Body.text = String(q.question)
	var img := q.get("image") as Texture2D
	%Image.texture = img
	%Image.visible = img != null
	%Action.visible = false
	var i := 0
	for c: String in q.choices:
		var b := Button.new()
		b.name = "Choice%d" % i
		b.text = c
		b.focus_mode = Control.FOCUS_NONE
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(0, 34)
		b.add_theme_font_size_override(&"font_size", 15)
		b.add_theme_color_override(&"font_color", font)
		b.add_theme_color_override(&"font_hover_color", font)
		if choice_style:
			b.add_theme_stylebox_override(&"normal", choice_style)
			b.add_theme_stylebox_override(&"hover", choice_hover if choice_hover else choice_style)
			b.add_theme_stylebox_override(&"pressed", choice_hover if choice_hover else choice_style)
		b.pressed.connect(answer.bind(c))
		%Choices.add_child(b)
		i += 1


func _show_feedback(dl: Node) -> void:
	var last: Dictionary = dl.exam.get("last", { })
	var ok := bool(last.get("correct", false))
	%Title.text = "ถูกต้อง!" if ok else "ยังไม่ใช่"
	%Title.add_theme_color_override(&"font_color", good if ok else bad)
	%Body.text = ("" if ok else "คำตอบคือ \"%s\"\n" % String(last.get("answer", ""))) + String(last.get("explain", ""))
	%Feedback.visible = true
	%Feedback.text = "ตอบถูกแล้ว %d ข้อ" % int(dl.exam.get("right", 0))
	%Action.visible = true
	%Action.text = "ดูผลสอบ" if dl.exam_answered_all() else "ข้อถัดไป"


func _show_result(r: Dictionary) -> void:
	var passed := bool(r.get("passed", false))
	%Title.add_theme_color_override(&"font_color", good if passed else bad)
	%Title.text = "ผ่านแล้ว!" if passed else "ยังไม่ผ่าน"
	%Rank.text = "ใบแจ้งผลสอบ"
	%Sub.visible = true
	%Sub.text = "คะแนน %d/%d · เกณฑ์ผ่าน %d" % [int(r.right), int(r.total), _econ_pass()]
	%Body.text = ("ขมเป็น%sแล้ว ปิดคอมแล้วเลือกความสามารถช่าง 1 อย่าง" % GameState.rank_name()) if passed else "ทวนหมวดที่พลาดแล้วกลับมาสอบใหม่วันเปิดร้านถัดไป"
	# ผลแยกหมวด (แบบใบแจ้งผลข้อสอบใบรับรองช่าง)
	var rep: Dictionary = r.get("report", { })
	if not rep.is_empty():
		var lines := PackedStringArray()
		for d in rep:
			var x: Array = rep[d]
			lines.append("%s %s %d/%d%s" % ["✓" if int(x[0]) == int(x[1]) else "✗", d, int(x[0]), int(x[1]), "" if int(x[0]) == int(x[1]) else " · ควรทบทวน"])
		%Unlocks.visible = true
		%Unlocks.text = "ผลแยกหมวด\n" + "\n".join(lines)
	%Action.visible = true
	%Action.text = "กลับหน้าแรก"


func _econ_pass() -> int:
	return GameState.economy.exam_pass if GameState.economy else 2


## กดตัวเลือก (ใช้ในเทสต์ได้)
func answer(choice: String) -> void:
	var dl := _dl()
	if dl == null or page != &"question":
		return
	dl.exam_answer(choice)
	page = &"feedback"
	refresh()


func _on_action() -> void:
	var dl := _dl()
	if dl == null:
		return
	match page:
		&"home":
			if dl.exam_can_start():
				dl.exam_begin()
				page = &"question"
		&"feedback":
			if dl.exam_answered_all():
				dl.exam_finish()
				page = &"result"
			else:
				page = &"question"
		&"result":
			page = &"home"
	%Title.add_theme_color_override(&"font_color", font)
	refresh()


func _clear_choices() -> void:
	for n in %Choices.get_children():
		%Choices.remove_child(n)
		n.queue_free()
