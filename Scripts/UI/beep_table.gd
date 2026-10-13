class_name BeepTable extends CanvasLayer
## ตารางรหัสเสียงบี๊บ BIOS (POST beep codes) — กดปุ่ม ▶ ฟังเสียงจริงได้ทุกแถว (Audio.beep)
## โหนดทุกแถวอยู่ใน Scene/UI/beep_table.tscn (แก้ข้อความ/เพิ่มแถวใน Inspector: ปุ่ม ▶ ใส่ metadata "code" = ชื่อไฟล์ beep_<code>.wav)
## เปิดจาก: สมุดคู่มือในมินิเกม · ขั้นดูอาการของงานแรม · PowerCheck · [Claude 13 ต.ค. 2569]

const SCENE_PATH := "res://Scene/UI/beep_table.tscn"

@onready var rows: GridContainer = %Rows
@onready var close_button: Button = %CloseButton


## เปิดตารางทับจอ (ปิดแล้วลบตัวเอง) · เรียกจากที่ไหนก็ได้: BeepTable.open_over(self)
static func open_over(from: Node) -> BeepTable:
	var t := (load(SCENE_PATH) as PackedScene).instantiate() as BeepTable
	from.get_tree().root.add_child(t)
	return t


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(queue_free)
	for c in rows.get_children():
		if c is Button and c.has_meta("code"):
			(c as Button).pressed.connect(_play.bind(StringName(c.get_meta("code"))))


func _play(code: StringName) -> void:
	var a := get_node_or_null(^"/root/Audio")
	if a:
		a.beep(code)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()
