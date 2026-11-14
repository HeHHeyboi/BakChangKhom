class_name DoorCard extends PanelContainer
## [Claude 15 พ.ย. 2569 · 0.3.0 ขั้น C] การ์ดลูกค้าหน้าประตู (DoorLayer ชั้น 90 ใน day_loop.tscn) — แทนกระดานงาน
## ฉากนี้แสดงผลอย่างเดียว: DayLoop สร้าง view (DayLoop.door_view()) แล้วเรียก show_view() · กดปุ่มส่ง signal กลับ (กติกาอยู่ที่ DayLoop)
## ปรับหน้าตาใน Editor ได้ (โหนดชื่อ %Title %Quota %Note %Front %Portrait %Name %Detail %PatienceBar %Accept %Appoint %Reject %Queue %Wait %Close)

signal accept_pressed
signal appoint_pressed
signal reject_pressed
signal wait_pressed
signal close_pressed
signal hide_pressed

## สีแถบความอดทน: เหลือมาก → น้อย
@export var patience_ok := Color(0.36, 0.62, 0.3)
@export var patience_low := Color(0.85, 0.45, 0.15)


func _ready() -> void:
	%Accept.pressed.connect(func() -> void: accept_pressed.emit())
	%Appoint.pressed.connect(func() -> void: appoint_pressed.emit())
	%Reject.pressed.connect(func() -> void: reject_pressed.emit())
	%Wait.pressed.connect(func() -> void: wait_pressed.emit())
	%Close.pressed.connect(func() -> void: close_pressed.emit())
	%HideButton.pressed.connect(func() -> void: hide_pressed.emit())


## v = DayLoop.door_view(): { title, quota, quota_full, note, front: {} (ว่าง = ไม่มีคน), queue, empty, wait_disabled }
## front = { name, detail, portrait: Texture2D|null, patience_left, patience_max, phone,
##           accept: {text, disabled, visible, tooltip}, appoint: {text, disabled, tooltip}, reject_disabled }
func show_view(v: Dictionary) -> void:
	%Title.text = String(v.get("title", ""))
	%Quota.text = String(v.get("quota", ""))
	%Quota.add_theme_color_override(&"font_color", Color(0.7, 0.2, 0.1) if v.get("quota_full", false) else Color(0.35, 0.2, 0.08))
	var note := String(v.get("note", ""))
	%Note.text = note
	%Note.visible = note != ""
	var f: Dictionary = v.get("front", { })
	%Front.visible = not f.is_empty()
	%Empty.visible = f.is_empty()
	%Empty.text = String(v.get("empty", ""))
	if not f.is_empty():
		_show_front(f)
	var q := String(v.get("queue", ""))
	%Queue.text = q
	%Queue.visible = q != ""
	%Wait.disabled = bool(v.get("wait_disabled", false))
	reset_size()


func _show_front(f: Dictionary) -> void:
	%Name.text = String(f.get("name", ""))
	%Detail.text = String(f.get("detail", ""))
	var tex = f.get("portrait")
	%Portrait.texture = tex as Texture2D
	%Portrait.get_parent().visible = tex is Texture2D
	var phone := bool(f.get("phone", false))
	%PatienceRow.visible = true
	var mx := maxi(int(f.get("patience_max", 2)), 1)
	var left := clampi(int(f.get("patience_left", mx)), 0, mx)
	%PatienceBar.max_value = mx
	%PatienceBar.value = left
	%PatienceBar.visible = not phone
	var fill := (%PatienceBar.get_theme_stylebox(&"fill") as StyleBoxFlat)
	if fill:
		fill = fill.duplicate()
		fill.bg_color = patience_low if left <= 1 else patience_ok
		%PatienceBar.add_theme_stylebox_override(&"fill", fill)
	%PatienceLabel.text = "โทรมาขอนัดเอาเครื่องมาวันเปิดร้านถัดไป" if phone else "รอได้อีก %s" % TimeSystem.turns_text(left)
	_apply_button(%Accept, f.get("accept", { }))
	_apply_button(%Appoint, f.get("appoint", { }))
	%Reject.disabled = bool(f.get("reject_disabled", false))


func _apply_button(b: Button, d: Dictionary) -> void:
	b.visible = bool(d.get("visible", true))
	b.text = String(d.get("text", b.text))
	b.disabled = bool(d.get("disabled", false))
	b.tooltip_text = String(d.get("tooltip", ""))
