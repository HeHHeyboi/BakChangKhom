class_name ShopPanel extends PanelContainer
## หน้าต่างร้านค้าในตลาด — เปิดจาก MarketStall · ของเป็นการ์ดแบบช่อง (Scene/UI/item_slot.tscn) · กดการ์ด → รายละเอียด + จำนวน + ซื้อ
## ของที่เป็น ItemDef เข้าคลัง (GameState.buy: เช็กเงิน · ช่องคลัง · ยศ · สต็อกร้าน) · ShopItem แบบเก่า = หักเงินอย่างเดียว
## โหนดทั้งหมดอยู่ใน Scene/Location/Market.tscn (ShopPanel) — แก้หน้าตาใน Inspector ได้
## [Claude 10 ต.ค. 2569] · [13 ต.ค.] การ์ดแบบช่อง + คลัง (Docs/STORAGE_SHOP_ECO.md ข้อ 2)

signal bought(item: ShopItem)

const SLOT_SCENE := preload("res://Scene/UI/item_slot.tscn")

## ข้อความตอนแผงยังไม่มีของขาย
@export_multiline var empty_text := "ยังไม่มีของขายตอนนี้\nเดี๋ยวร้านจะเอาของมาลงเพิ่มในอนาคตนะ"

@onready var title: Label = %Title
@onready var money_label: Label = %Money
@onready var note: Label = %Note
@onready var tabs: Array[Button] = [%TabAll, %TabParts, %TabSupplies]
@onready var storage_info: Label = %StorageInfo
@onready var storage_button: Button = %StorageButton
@onready var scroll: ScrollContainer = %Scroll
@onready var grid: GridContainer = %Grid
@onready var empty: Label = %Empty
@onready var detail_name: Label = %DetailName
@onready var detail_text: Label = %DetailText
@onready var qty_minus: Button = %QtyMinus
@onready var qty_label: Label = %Qty
@onready var qty_plus: Button = %QtyPlus
@onready var total_label: Label = %Total
@onready var buy_button: Button = %BuyButton
@onready var close_button: Button = %Close

var _items: Array[ShopItem] = []
var _sel: ShopItem
var _qty := 1
## -1 = ทั้งหมด · ItemDef.Kind
var _filter := -1
var _group := ButtonGroup.new()


func _ready() -> void:
	hide()
	close_button.pressed.connect(close)
	buy_button.pressed.connect(func(): buy(_sel, _qty))
	qty_minus.pressed.connect(func(): _set_qty(_qty - 1))
	qty_plus.pressed.connect(func(): _set_qty(_qty + 1))
	var kinds := [-1, ItemDef.Kind.PART, ItemDef.Kind.SUPPLY]
	for i in tabs.size():
		tabs[i].toggle_mode = true
		tabs[i].pressed.connect(_set_filter.bind(kinds[i]))
	storage_button.pressed.connect(func():
		if has_node(^"/root/Storage"):
			get_node(^"/root/Storage").open())
	GameState.inventory_changed.connect(_refresh_if_open)
	GameState.money_changed.connect(func(_m, _d): _refresh_if_open())


func open(shop_name: String, items: Array[ShopItem], greeting := "") -> void:
	_items = items
	title.text = shop_name
	note.text = greeting
	note.visible = greeting != ""
	_sel = null
	_qty = 1
	_set_filter(-1)
	show()
	_block_storage_button(true)


func close() -> void:
	hide()
	_block_storage_button(false)


func _exit_tree() -> void:
	_block_storage_button(false)


func _block_storage_button(on: bool) -> void:
	var st := get_node_or_null(^"/root/Storage")
	if st:
		st.block_button = on
	# [13 ต.ค.] หน้าต่างร้านอยู่ในฉาก (ใต้ HUD) → ซ่อนแถบ HUD ตอนเปิดร้าน ไม่ให้บังหัวหน้าต่าง
	var em := get_node_or_null(^"/root/EventManager")
	if em and is_inside_tree():
		if on:
			em.hideUI()
		else:
			em.showUI()


func _refresh_if_open() -> void:
	if visible:
		_fill()


func _set_filter(kind: int) -> void:
	_filter = kind
	var kinds := [-1, ItemDef.Kind.PART, ItemDef.Kind.SUPPLY]
	for i in tabs.size():
		tabs[i].set_pressed_no_signal(kinds[i] == kind)
	_fill()


func _shown_items() -> Array[ShopItem]:
	var out: Array[ShopItem] = []
	for it in _items:
		if it == null:
			continue
		var k := (it as ItemDef).kind if it is ItemDef else -1
		if k == ItemDef.Kind.UPGRADE:
			k = ItemDef.Kind.PART # อัปเกรดคลังโชว์ในแท็บอะไหล่
		if _filter == -1 or k == _filter:
			out.append(it)
	return out


func _fill() -> void:
	for c in grid.get_children():
		grid.remove_child(c)
		c.queue_free()
	money_label.text = "฿%s" % _comma(GameState.money)
	storage_info.text = "คลัง %d/%d ช่อง" % [GameState.used_slots(), GameState.storage_slots]
	var shown := _shown_items()
	empty.text = empty_text
	empty.visible = shown.is_empty()
	scroll.visible = not shown.is_empty()
	for it in shown:
		var slot := SLOT_SCENE.instantiate() as ItemSlot
		grid.add_child(slot)
		slot.button_group = _group
		var top := ""
		var bottom := "฿%s" % _comma(it.price)
		var tag := ""
		if it is ItemDef:
			var d := it as ItemDef
			top = d.card_badge()
			var left := GameState.stock_left(d)
			if left >= 0:
				bottom += " · เหลือ %d" % left
			var why := GameState.buy_block_reason(d, 1)
			if why.begins_with("ล็อก"):
				tag = "ล็อก"
			elif left == 0:
				tag = "หมด"
			elif why == "มีแล้ว":
				tag = "มีแล้ว"
		slot.set_item(_as_def(it), top, bottom, tag)
		slot.pressed.connect(_select.bind(it))
		if it == _sel:
			slot.set_pressed_no_signal(true)
	_refresh_detail()


## ShopItem แบบเก่า → ห่อเป็น ItemDef ชั่วคราวเพื่อให้การ์ดแสดงได้
func _as_def(it: ShopItem) -> ItemDef:
	if it is ItemDef:
		return it as ItemDef
	var d := ItemDef.new()
	d.display_name = it.display_name
	d.price = it.price
	d.icon = it.icon
	d.description = it.description
	d.id = it.id
	d.emoji = ""
	return d


func _select(it: ShopItem) -> void:
	_sel = it
	_qty = 1
	_refresh_detail()


func _set_qty(q: int) -> void:
	_qty = clampi(q, 1, 9)
	_refresh_detail()


func _refresh_detail() -> void:
	var has := _sel != null
	var stackable := has and _sel is ItemDef and (_sel as ItemDef).kind != ItemDef.Kind.UPGRADE
	qty_minus.visible = stackable
	qty_plus.visible = stackable
	qty_label.visible = stackable
	if not has:
		detail_name.text = "เลือกของที่อยากซื้อ"
		detail_text.text = "กดที่การ์ดเพื่อดูรายละเอียด"
		total_label.text = ""
		buy_button.disabled = true
		buy_button.text = "ซื้อ"
		return
	var extra := ""
	if _sel is ItemDef:
		var d := _sel as ItemDef
		match d.kind:
			ItemDef.Kind.PART:
				extra = "อะไหล่ · %s · 1 ชิ้นใช้ 1 ช่องคลัง" % d.condition_text()
			ItemDef.Kind.SUPPLY:
				extra = "ของสิ้นเปลือง · แพ็กละ %d ครั้ง · ซ้อนในช่องเดียวได้ (มีอยู่ %d ครั้ง)" % [d.uses, GameState.count_item(d.id)]
			ItemDef.Kind.UPGRADE:
				extra = "อัปเกรด · คลังเป็น %d ช่อง (ตอนนี้ %d)" % [d.storage_slots_to, GameState.storage_slots]
	detail_name.text = _sel.display_name
	detail_text.text = "\n".join([_sel.description, extra].filter(func(x): return x != ""))
	qty_label.text = str(_qty)
	total_label.text = "รวม ฿%s" % _comma(_sel.price * _qty)
	var why := GameState.buy_block_reason(_sel as ItemDef, _qty) if _sel is ItemDef else ("" if GameState.can_afford(_sel.price) else "เงินไม่พอ")
	buy_button.disabled = why != ""
	buy_button.text = why if why != "" else "ซื้อ"


## ซื้อ: ItemDef → เข้าคลัง (GameState.buy) · ShopItem เก่า → หักเงิน · สำเร็จ = true
func buy(it: ShopItem, qty := 1) -> bool:
	if it == null:
		return false
	if it is ItemDef:
		if GameState.buy(it as ItemDef, qty) != "":
			return false
	else:
		if not GameState.can_afford(it.price * qty):
			return false
		GameState.add_money(-it.price * qty, &"buy", "%s ×%d" % [it.display_name, qty])
	bought.emit(it)
	_fill()
	return true


static func _comma(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
