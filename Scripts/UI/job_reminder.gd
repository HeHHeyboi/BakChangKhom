class_name JobReminder extends Control
## [8 พ.ย. 2569] ปุ่ม "งานลูกค้า" ระหว่างซ่อม — กดดูซ้ำได้ว่าลูกค้าขออะไร (เผื่อลืมหลังปิดหน้าต่างคุยกับลูกค้า)
## ฉาก Scene/UI/job_reminder.tscn (วางใน day_loop.tscn → ReminderLayer ชั้น 11: เหนือมินิเกม SceneRouter.overlay_stack ชั้น 10 · ใต้ HUD 100 · บทพูด 128)
## ไม่แก้ไฟล์มินิเกม/ขมOS — อ่านอย่างเดียวจาก DayLoop.today_case และมินิเกมที่เปิดอยู่ (task.request · step · _mistakes · task.ask_answer/ask_note ถ้ามี)
## ขึ้นเฉพาะงานลูกค้า (มี DayLoop._minigame) · ไม่ขึ้นในบทฝึก/เควสต์หลัก

## ตำแหน่งปุ่มต่อมินิเกม (มุมซ้ายบนของปุ่ม) · ไม่มีในรายการ = default_pos
@export var default_pos := Vector2(1086, 58)
@export var part_pos := {
	"part_desktop": Vector2(1088, 60), # นอกจอมอนิเตอร์ ขวาบน
	"part_bench": Vector2(24, 214), # ใต้กระดาษโน้ต ซ้ายบน
}

@onready var _btn: Button = %ReminderButton
@onready var _card: PanelContainer = %ReminderCard
@onready var _title: Label = %CardTitle
@onready var _body: Label = %CardBody
@onready var _close: Button = %CardClose
@onready var _dim: ColorRect = %Dim

var _case: CustomerCase


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# ไอคอนบน ข้อความล่าง (ปุ่มเล็ก ไม่บังมินิเกม)
	_btn.icon = Icons.sized(&"clipboard", 28)
	_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	_btn.expand_icon = false
	_btn.pressed.connect(open_card)
	_close.pressed.connect(close_card)
	_dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			close_card()
	)
	_btn.hide()
	close_card()


func _process(_delta: float) -> void:
	var m := _minigame()
	var want := m != null and _case_now() != null
	if want and _case != _case_now():
		_case = _case_now()
		_btn.position = part_pos.get(_case.part_id, default_pos)
		close_card()
	if not want:
		_case = null
		if _card.visible:
			close_card()
	_btn.visible = want and not _card.visible
	if _card.visible:
		_fill(m) # คำตอบลูกค้าอาจเพิ่งได้มา


func open_card() -> void:
	var m := _minigame()
	if m == null or _case_now() == null:
		return
	_fill(m)
	_dim.show()
	_card.show()
	_btn.hide()


func close_card() -> void:
	_dim.hide()
	_card.hide()


func is_open() -> bool:
	return _card.visible


## ข้อความในการ์ด (ใช้ในเทสด้วย)
func card_text() -> String:
	return _title.text + "\n" + _body.text


func _fill(m: Node) -> void:
	var c := _case_now()
	if c == null:
		return
	_title.text = "งานของ%s" % c.customer
	var lines := PackedStringArray()
	var task = m.get("task")
	var said := c.symptom
	if task != null and String(task.get("request")) != "":
		said = String(task.get("request"))
	lines.append("ลูกค้าบอกว่า: \"%s\"" % said)
	if c.device != "":
		lines.append("เครื่อง: %s" % c.device)
	# งานที่มีขั้นคุยกับลูกค้า (ขมOS · โต๊ะหลังเครื่อง): ถามแล้วได้ความว่าอะไร
	var step = m.get("step")
	if task != null and step != null:
		if int(step) == 0:
			lines.append("ยังไม่ได้ถามลูกค้า — เลือกคำถามในหน้าต่างคุยกับลูกค้าก่อน")
		else:
			var mistakes = m.get("_mistakes")
			var asked_well: bool = mistakes is Dictionary and int(mistakes.get(&"listen", 0)) == 0
			var ans := String(task.get("ask_answer")) if asked_well else String(task.get("ask_answer_wrong"))
			if ans != "":
				lines.append("ถามแล้วลูกค้าตอบว่า: \"%s\"" % ans)
			var note := String(task.get("ask_note"))
			if asked_well and note != "":
				lines.append("สิ่งที่ต้องระวัง: %s" % note)
		lines.append("ขั้นตอน: ฟังลูกค้า → ดูอาการ + ลงมือ → ลองใช้ให้ลูกค้าดู → อธิบายให้ลูกค้าฟัง")
	else:
		lines.append("ขั้นตอนดูได้ที่แถบบนซ้าย · ไม่แน่ใจกดสมุดคู่มือมุมขวาบน")
	_body.text = "\n".join(lines)


func _case_now() -> CustomerCase:
	var dl := get_node_or_null(^"/root/DayLoop")
	return dl.get("today_case") as CustomerCase if dl else null


func _minigame() -> Node:
	var dl := get_node_or_null(^"/root/DayLoop")
	if dl == null:
		return null
	var m = dl.get("_minigame")
	return m if is_instance_valid(m) and (m as Node).is_inside_tree() else null
