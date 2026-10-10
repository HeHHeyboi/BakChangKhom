class_name ShopPanel extends PanelContainer
## หน้าต่างร้านค้าในตลาด — เปิดจาก MarketStall · แสดงสินค้า (ShopItem) + ปุ่มซื้อ · ไม่มีของ = ข้อความ "ยังไม่มีของขาย"
## [Claude 10 ต.ค. 2569] โหนดอยู่ใน Scene/Location/Market.tscn (ShopPanel)

signal bought(item: ShopItem)

## ข้อความตอนแผงยังไม่มีของขาย
@export_multiline var empty_text := "ยังไม่มีของขายตอนนี้\nเดี๋ยวร้านจะเอาของมาลงเพิ่มในอนาคตนะ"

@onready var title: Label = $Box/Title
@onready var note: Label = $Box/Note
@onready var list: VBoxContainer = $Box/Scroll/List
@onready var empty: Label = $Box/Empty
@onready var close_button: Button = $Box/Close

var _items: Array[ShopItem] = []


func _ready() -> void:
	hide()
	close_button.pressed.connect(close)


func open(shop_name: String, items: Array[ShopItem], greeting := "") -> void:
	_items = items
	title.text = shop_name
	note.text = greeting
	note.visible = greeting != ""
	_fill()
	show()


func close() -> void:
	hide()


func _fill() -> void:
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	empty.text = empty_text
	empty.visible = _items.is_empty()
	list.get_parent().visible = not _items.is_empty()
	for it in _items:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		list.add_child(row)
		if it.icon:
			var ic := TextureRect.new()
			ic.texture = it.icon
			ic.custom_minimum_size = Vector2(48, 48)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(ic)
		var t := Label.new()
		t.text = "%s — ฿%d%s" % [it.display_name, it.price, ("\n" + it.description) if it.description != "" else ""]
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.add_theme_color_override("font_color", Color(0.23, 0.16, 0.11))
		t.add_theme_font_size_override("font_size", 18)
		row.add_child(t)
		var b := Button.new()
		b.text = "ซื้อ"
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = not GameState.can_afford(it.price)
		b.pressed.connect(buy.bind(it))
		row.add_child(b)


## ซื้อ: พอเงิน → หักเงิน + bought · ไม่พอ → false
func buy(it: ShopItem) -> bool:
	if not GameState.can_afford(it.price):
		return false
	GameState.add_money(-it.price)
	bought.emit(it)
	_fill()
	return true
