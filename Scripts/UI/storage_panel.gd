extends CanvasLayer
## คลังของ (autoload "Storage") — ปุ่ม 📦 มุมล่างซ้าย (ข้างปุ่มแผนที่) + หน้าต่างช่องของ · Docs/STORAGE_SHOP_ECO.md ข้อ 1
## โหนดทั้งหมดอยู่ใน Scene/UI/storage_panel.tscn (ย้ายปุ่ม/ปรับสีใน Inspector ได้) · ช่องแต่ละช่อง = Scene/UI/item_slot.tscn
## ข้อมูลอยู่ที่ GameState.inventory · ปุ่มซ่อนเองตอนอยู่เมนูหลัก · มินิเกม · บทพูด · แผนที่ · เมนูพัก
## [Claude 13 ต.ค. 2569]

const SLOT_SCENE := preload("res://Scene/UI/item_slot.tscn")

@onready var open_button: Button = %OpenButton
@onready var window: Control = %Window
@onready var count_label: Label = %Count
@onready var tabs: Array[Button] = [%TabAll, %TabParts, %TabSupplies]
@onready var grid: GridContainer = %Grid
@onready var scroll: ScrollContainer = %Scroll
@onready var empty_note: Label = %EmptyNote
@onready var detail_name: Label = %DetailName
@onready var detail_text: Label = %DetailText
@onready var sell_button: Button = %SellButton
@onready var close_button: Button = %CloseButton
@onready var toast: Control = %Toast
@onready var toast_text: Label = %ToastText
var _toast_tw: Tween

## ซ่อนปุ่ม 📦 ชั่วคราว (เช่น ตอนหน้าต่างร้านค้าเปิดทับมุมล่าง) — หน้าต่างคลังยังเปิดจากปุ่ม "ดูคลัง" ในร้านได้
var block_button := false
var _filter := -1
var _sel := -1
var _group := ButtonGroup.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	window.hide()
	open_button.pressed.connect(open)
	close_button.pressed.connect(close)
	sell_button.pressed.connect(_sell)
	var kinds := [-1, ItemDef.Kind.PART, ItemDef.Kind.SUPPLY]
	for i in tabs.size():
		tabs[i].toggle_mode = true
		tabs[i].pressed.connect(_set_filter.bind(kinds[i]))
	GameState.inventory_changed.connect(_refresh)
	GameState.item_received.connect(_on_item_received)
	_refresh()


## [13 ต.ค.] ป้ายเด้ง "ได้ … เข้าคลัง" — โชว์ทุกที่ (รวมบทสอน/มินิเกม ที่ปุ่มคลังซ่อนอยู่)
func _on_item_received(item: ItemDef, qty: int) -> void:
	if item == null or item.kind == ItemDef.Kind.UPGRADE:
		return
	var n := ""
	if item.kind == ItemDef.Kind.SUPPLY:
		n = " (%d ครั้ง)" % (item.uses * qty)
	elif qty > 1:
		n = " ×%d" % qty
	toast_text.text = "ได้ %s%s เข้าคลัง · %d/%d ช่อง" % [item.display_name, n, GameState.used_slots(), GameState.storage_slots]
	toast.show()
	toast.modulate.a = 0.0
	if _toast_tw:
		_toast_tw.kill()
	_toast_tw = create_tween()
	_toast_tw.tween_property(toast, "modulate:a", 1.0, 0.2)
	_toast_tw.tween_interval(2.2)
	_toast_tw.tween_property(toast, "modulate:a", 0.0, 0.4)
	_toast_tw.tween_callback(toast.hide)


func open() -> void:
	_sel = -1
	_set_filter(-1)
	window.show()


func close() -> void:
	window.hide()


func _process(_d: float) -> void:
	var show_btn := _can_show()
	if open_button.visible != show_btn:
		open_button.visible = show_btn
	if not show_btn and window.visible and Global.in_minigame:
		window.hide()


## ปุ่มคลังโชว์ได้ไหมตอนนี้
func _can_show() -> bool:
	var cur := get_tree().current_scene
	if block_button or cur == null or (cur.is_in_group("main_menu") and cur.visible):
		return false
	if Global.in_minigame or Global.isDialogShown():
		return false
	# HUD ถูกซ่อน (EventManager.hideUI — มินิเกม/ขมOS/บทนำ) = ซ่อนปุ่มคลังด้วย
	if has_node(^"/root/EventManager") and EventManager.time_system and not EventManager.time_system.visible:
		return false
	if has_node(^"/root/MapPanel") and MapPanel.visible:
		return false
	if has_node(^"/root/PauseMenu") and PauseMenu.visible:
		return false
	return true


func _unhandled_input(event: InputEvent) -> void:
	if window.visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()


func _set_filter(kind: int) -> void:
	_filter = kind
	var kinds := [-1, ItemDef.Kind.PART, ItemDef.Kind.SUPPLY]
	for i in tabs.size():
		tabs[i].set_pressed_no_signal(kinds[i] == kind)
	_refresh()


func _refresh() -> void:
	open_button.text = "คลัง %d/%d" % [GameState.used_slots(), GameState.storage_slots]
	count_label.text = "%d/%d ช่อง" % [GameState.used_slots(), GameState.storage_slots]
	var over := GameState.used_slots() > GameState.storage_slots
	count_label.add_theme_color_override("font_color", Color(0.8, 0.15, 0.1) if over else Color(0.4, 0.3, 0.2))
	if over:
		count_label.text += " (เกิน! ขายหรือใช้ออกก่อนซื้อเพิ่ม)"
	for c in grid.get_children():
		grid.remove_child(c)
		c.queue_free()
	var shown := 0
	for i in GameState.inventory.size():
		var e: Dictionary = GameState.inventory[i]
		var it := GameState.item_of(e)
		if it == null or (_filter != -1 and it.kind != _filter):
			continue
		var slot := SLOT_SCENE.instantiate() as ItemSlot
		grid.add_child(slot)
		slot.button_group = _group
		var top := ("ใหม่" if String(e.condition) == "new" else "มือสอง") if it.kind == ItemDef.Kind.PART else "เหลือ %d ครั้ง" % int(e.qty)
		var reserved := String(e.get("reserved_for", ""))
		var price := ("฿%d" % it.price) if it.kind == ItemDef.Kind.PART else ("฿%d/แพ็ก" % it.price)
		slot.set_item(it, top, price, "จอง" if reserved != "" else "")
		slot.index = i
		slot.pressed.connect(_select.bind(i))
		if i == _sel:
			slot.set_pressed_no_signal(true)
		shown += 1
	if _filter == -1:
		for k in GameState.free_slots():
			var slot := SLOT_SCENE.instantiate() as ItemSlot
			grid.add_child(slot)
			slot.set_empty()
	# แท็บกรองแล้วไม่มีของ (หรือคลังเต็มแต่ไม่มีหมวดนี้) → ข้อความแทนตารางว่าง
	var nothing := grid.get_child_count() == 0
	empty_note.visible = nothing
	scroll.visible = not nothing
	_refresh_detail()


func _select(i: int) -> void:
	_sel = i
	_refresh_detail()


func _refresh_detail() -> void:
	if _sel < 0 or _sel >= GameState.inventory.size():
		_sel = -1
		detail_name.text = "คลังของร้าน"
		detail_text.text = "อะไหล่ 1 ชิ้นใช้ 1 ช่อง · ของสิ้นเปลืองชนิดเดียวกันซ้อนในช่องเดียว · ช่องเต็มแล้วซื้อของเพิ่มไม่ได้\nขยายคลังได้ที่ร้านอะไหล่คอมในตลาด"
		sell_button.visible = false
		return
	var e: Dictionary = GameState.inventory[_sel]
	var it := GameState.item_of(e)
	detail_name.text = it.display_name if it else String(e.id)
	var lines: Array[String] = []
	if it and it.description != "":
		lines.append(it.description)
	if String(e.get("reserved_for", "")) != "":
		lines.append("จองไว้ให้งานของ %s — ขาย/ทิ้งไม่ได้" % e.reserved_for)
	detail_text.text = "\n".join(lines)
	if it:
		lines.append(("ราคาซื้อ ฿%d" % it.price) + ((" · ขายคืนได้ ฿%d" % GameState.sell_price(_sel)) if GameState.sell_price(_sel) > 0 else ""))
		detail_text.text = "\n".join(lines)
	var price := GameState.sell_price(_sel)
	sell_button.visible = true
	sell_button.disabled = String(e.get("reserved_for", "")) != ""
	sell_button.text = ("ขายคืน ฿%d" % price) if price > 0 else "ทิ้ง"


func _sell() -> void:
	if _sel < 0:
		return
	GameState.sell_back(_sel)
	_sel = -1
	_refresh()
