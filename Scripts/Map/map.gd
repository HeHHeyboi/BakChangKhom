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
	var here := card_for(cur)
	here_label.text = "ตอนนี้อยู่: %s" % (here.title if here else "-")
	speech.text = default_hint


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
	showmap(card.location)


## ปิดแผนที่แล้วไปฉาก id (SceneRouter.LocationID)
func showmap(id: SceneRouter.LocationID) -> void:
	hide()
	SceneRouter.go(id)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()
