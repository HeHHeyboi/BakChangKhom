extends CanvasLayer
## แผนที่หมู่บ้าน (autoload MapPanel) — กดรูปสถานที่แล้วไปเลย ไม่ต้องเดิน
## โครง (ดู Scene/map.tscn): Root → Dim · Board (รูปแผนที่) · Title · Cards (MapCard ×5) · Speech (คำพูดปิ๊บ) · Pib · BottomBar (อยู่ที่ไหน + ปิด)
## เพิ่ม/ย้ายสถานที่: ลาก MapCard ใน Cards แล้วตั้งค่าใน Inspector ได้เลย
## [Claude 10 ต.ค. 2569] ทำใหม่ตามภาพร่าง (5 ช่องแผนที่ · ข้อความ + ตัวละครมุมขวาล่าง · แถบล่าง)

## ปิ๊บพูดตอนเปิดแผนที่ (ยังไม่ได้ชี้การ์ดไหน)
@export_multiline var default_hint := "จะไปไหนดีขม? ชี้ที่รูปเพื่อดูว่าที่นั่นมีอะไร แล้วกดเพื่อไปได้เลย"

@onready var cards: Control = $Root/Cards
@onready var speech: Label = $Root/Speech/Text
@onready var here_label: Label = $Root/BottomBar/Here
@onready var close_button: Button = $Root/BottomBar/Close


func _ready() -> void:
	visible = false
	for c in _cards():
		c.pressed.connect(_on_card_pressed.bind(c))
		c.card_hovered.connect(_on_card_hovered)
	close_button.pressed.connect(hide)
	visibility_changed.connect(_refresh)


func _cards() -> Array[MapCard]:
	var out: Array[MapCard] = []
	for c in cards.get_children():
		if c is MapCard:
			out.append(c)
	return out


func card_for(id: int) -> MapCard:
	for c in _cards():
		if c.location == id:
			return c
	return null


func _refresh() -> void:
	if not visible:
		return
	var cur := int(SceneRouter.current_id)
	for c in _cards():
		c.is_here = c.location == cur
		c.scale = Vector2.ONE
	_refresh_city()
	_show_confirm(false)
	var here := card_for(cur)
	here_label.text = "ตอนนี้อยู่: %s" % (here.title if here else "-")
	speech.text = default_hint


## [0.9.5] การ์ดเมือง: ปลดหลังบท 11 · ล็อกพร้อมเหตุผลเมื่อวันนี้ไปไม่ได้ (DayLoop.city_state)
func _refresh_city() -> void:
	var city := card_for(SceneRouter.CITY)
	if city == null:
		return
	var st: StringName = DayLoop.city_state()
	city.locked = not (st == &"ok" or st == &"here")
	city.locked_text = DayLoop.city_state_text(st) if city.locked else "เร็ว ๆ นี้"


func _on_card_hovered(card: MapCard, on: bool) -> void:
	if not on:
		speech.text = default_hint
		return
	if card.locked:
		speech.text = "%s — %s" % [card.title, card.locked_text]
	elif card.is_here:
		speech.text = "เราอยู่%sแล้วนะ" % card.title
	else:
		speech.text = card.hint if card.hint != "" else "ไป%sกัน" % card.title


func _on_card_pressed(card: MapCard) -> void:
	if card.locked:
		speech.text = "%s ยังไปไม่ได้นะ (%s)" % [card.title, card.locked_text]
		return
	if card.is_here:
		hide()
		return
	if Global.isDialogShown() or Global.isInMinigame():
		return
	if card.location == SceneRouter.CITY: # [0.9.5] ไปเมือง = ใช้ทั้งวัน → ถามก่อน
		speech.text = "ไปเมืองแล้วร้านปิดทั้งวันนะ แน่ใจไหม?"
		_show_confirm(true)
		return
	showmap(card.location)


# ---------------------------------------------------------------- [0.9.5] ยืนยันไปเมือง (สร้างจากโค้ด)
var _confirm: PanelContainer
var _confirm_text: Label


func _show_confirm(on: bool) -> void:
	if not on:
		if _confirm:
			_confirm.hide()
		return
	if _confirm == null:
		_build_confirm()
	_confirm_text.text = DayLoop.city_confirm_text()
	_confirm.show()


func _build_confirm() -> void:
	_confirm = PanelContainer.new()
	_confirm.name = "CityConfirm"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 0.98, 0.92, 0.98)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(16)
	sb.border_color = Color(0.23, 0.16, 0.11)
	sb.set_border_width_all(4)
	_confirm.add_theme_stylebox_override("panel", sb)
	_confirm.custom_minimum_size = Vector2(520, 0)
	_confirm.position = Vector2(316, 200)
	$Root.add_child(_confirm)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_confirm.add_child(box)
	var head := Label.new()
	head.text = "เข้าเมืองวันนี้?"
	head.add_theme_font_size_override("font_size", 26)
	head.add_theme_color_override("font_color", Color(0.45, 0.22, 0.05))
	box.add_child(head)
	_confirm_text = Label.new()
	_confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_text.add_theme_font_size_override("font_size", 18)
	_confirm_text.add_theme_color_override("font_color", Color(0.23, 0.16, 0.11))
	box.add_child(_confirm_text)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	var go := Button.new()
	go.name = "Go"
	go.text = "ไปเมือง"
	go.custom_minimum_size = Vector2(180, 44)
	go.add_theme_font_size_override("font_size", 20)
	go.pressed.connect(_on_city_confirmed)
	row.add_child(go)
	var no := Button.new()
	no.name = "No"
	no.text = "ไม่ไปดีกว่า"
	no.custom_minimum_size = Vector2(180, 44)
	no.add_theme_font_size_override("font_size", 20)
	no.pressed.connect(func() -> void:
		_show_confirm(false)
		speech.text = default_hint)
	row.add_child(no)


func _on_city_confirmed() -> void:
	_show_confirm(false)
	if not DayLoop.city_trip():
		_refresh_city()
		speech.text = "วันนี้ไปเมืองไม่ได้แล้ว (%s)" % DayLoop.city_state_text(DayLoop.city_state())
		return
	showmap(SceneRouter.CITY)


## ปิดแผนที่แล้วไปฉาก id (SceneRouter.LocationID)
func showmap(id: SceneRouter.LocationID) -> void:
	hide()
	SceneRouter.go(id)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()
