class_name OnlineShopApp extends VBoxContainer
## [Claude 15 พ.ย. 2569 · 0.4.0 ขั้น E] แอป "ร้านออนไลน์" ในคอมของขม (ShopPC ใส่ผ่าน DesktopMinigameV2.add_custom_app)
## สั่งอะไหล่/ของสิ้นเปลือง ราคาถูกกว่าตลาด · จ่ายทันที (ของ + ค่าส่งต่อครั้ง) · จองช่องคลัง · ของมาถึงตอนเปิดร้านวันถัดไป (PLAN_0_4_0 ข้อ 4)
## ตะกร้าอยู่ในแอป (cart) · กติกา/เงินอยู่ที่ GameState.order_online · ของที่เครื่องบนชั้นรออยู่ขึ้นป้าย "เครื่องของ … รอชิ้นนี้" (DayLoop.waiting_for)

@export var row_style: StyleBox
@export var main_button: StyleBox
@export var main_button_hover: StyleBox
@export var side_button: StyleBox
@export var button_disabled: StyleBox
@export var font := Color(0.35, 0.2, 0.08)
@export var warn := Color(0.75, 0.25, 0.1)
@export var good := Color(0.25, 0.5, 0.2)

## id → [ItemDef, จำนวน]
var cart: Dictionary = { }
var _last_hash := 0
var _t := 0.0
var _msg := ""


func _ready() -> void:
	%Order.pressed.connect(_on_order)
	refresh()


func _process(delta: float) -> void:
	_t += delta
	if _t >= 0.3:
		_t = 0.0
		refresh()


func lines() -> Array:
	var out: Array = []
	for id in cart:
		if int(cart[id][1]) > 0:
			out.append(cart[id])
	return out


func refresh(force := false) -> void:
	var dl := get_node_or_null(^"/root/DayLoop")
	var items: Array[ItemDef] = []
	if dl:
		items = dl.online_catalog()
	var waiting := { }
	for it in items:
		if dl:
			var w: PackedStringArray = dl.waiting_for(it.id)
			if not w.is_empty():
				waiting[it.id] = w
	var deals: Array = dl.deals_view() if dl and dl.has_method(&"deals_view") else []
	var h := [cart.hash(), GameState.money, GameState.used_slots(), GameState.pending_orders.size(), GameState.inventory.size(), waiting.hash(), _msg, str(deals).hash()].hash()
	if h == _last_hash and not force:
		return
	_last_hash = h
	var e := GameState.economy if GameState.economy else EconomyConfig.new()
	%Money.text = "ร้านอะไหล่ออนไลน์ · เงิน ฿%d · คลัง %d/%d ช่อง" % [GameState.money, GameState.used_slots(), GameState.storage_slots]
	for n in %List.get_children():
		%List.remove_child(n)
		n.queue_free()
	# [0.7.0 ขั้น I] ร้านอื่นที่ลดราคาวันนี้ (บางร้านปลอม) ขึ้นบนสุด
	if not deals.is_empty():
		%List.add_child(_head("ร้านอื่นลดราคาวันนี้ — ดูข้อมูลร้านก่อนซื้อ", true))
		for i in deals.size():
			%List.add_child(_deal_row(i, deals[i]))
	# ของที่เครื่องรออยู่ขึ้นก่อน แล้วอะไหล่ · ของสิ้นเปลือง (ตามลำดับของ catalog)
	var kind := -1
	var first := items.filter(func(it: ItemDef) -> bool: return waiting.has(it.id))
	if not first.is_empty():
		%List.add_child(_head("เครื่องบนชั้นรอของพวกนี้อยู่", true))
		for it: ItemDef in first:
			%List.add_child(_row(it, waiting[it.id]))
	for it: ItemDef in items:
		if waiting.has(it.id):
			continue
		if int(it.kind) != kind:
			kind = int(it.kind)
			%List.add_child(_head("อะไหล่" if it.kind == ItemDef.Kind.PART else "ของสิ้นเปลือง", false))
		%List.add_child(_row(it, PackedStringArray()))
	# ตะกร้า + ปุ่มสั่ง
	var ls := lines()
	var total := GameState.order_total(ls)
	var why := GameState.order_block_reason(ls)
	%Cart.text = ("ตะกร้า: %d ชิ้น · รวม ฿%d (ค่าส่ง ฿%d)" % [_count(ls), total, e.online_ship_fee]) if not ls.is_empty() else "ตะกร้าว่าง — กด + เพื่อใส่ของ · ค่าส่ง ฿%d ต่อครั้งที่สั่ง (สั่งรวมกันคุ้มกว่า)" % e.online_ship_fee
	%Order.disabled = why != ""
	%Order.text = "สั่งซื้อ · ของมาวันเปิดร้านถัดไป" if why == "" else why
	var pend := PackedStringArray()
	for o in GameState.pending_orders:
		var pit: ItemDef = load(String(o.path)) as ItemDef if ResourceLoader.exists(String(o.path)) else null
		pend.append("%s ×%d" % [pit.display_name if pit else String(o.id), int(o.qty)])
	%Note.text = (_msg + "\n" if _msg != "" else "") + (("กำลังมาส่ง (เปิดร้านวันถัดไป): " + ", ".join(pend)) if not pend.is_empty() else "ราคาถูกกว่าตลาด แต่ต้องรอ 1 วันเปิดร้าน · จ่ายเงินตอนสั่ง ได้คืนตอนลูกค้ามารับเครื่อง")


func _count(ls: Array) -> int:
	var n := 0
	for l in ls:
		n += int(l[1])
	return n


func _head(t: String, is_warn: bool) -> Label:
	var head := Label.new()
	head.text = t
	head.add_theme_font_size_override(&"font_size", 15)
	head.add_theme_color_override(&"font_color", warn if is_warn else font)
	return head


func _row(it: ItemDef, wait: PackedStringArray) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Row_" + String(it.id)
	if row_style:
		p.add_theme_stylebox_override(&"panel", row_style)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override(&"separation", 8)
	p.add_child(hb)
	var ic := TextureRect.new()
	ic.texture = it.icon
	ic.custom_minimum_size = Vector2(40, 40)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb.add_child(ic)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override(&"separation", 0)
	hb.add_child(info)
	var n := Label.new()
	n.text = "%s · ฿%d%s" % [it.display_name, it.online_cost(), (" (ตลาด ฿%d)" % it.price) if it.market and it.price != it.online_cost() else ("" if it.market else " (ไม่มีในตลาด)")]
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.add_theme_font_size_override(&"font_size", 14)
	n.add_theme_color_override(&"font_color", Color(0.15, 0.12, 0.1))
	info.add_child(n)
	var st := Label.new()
	var have := GameState.count_item(it.id)
	var pend := GameState.pending_count(it.id)
	var sub := "%s · ในคลัง %d%s" % [
		("แพ็กละ %d ครั้ง" % it.uses) if it.kind == ItemDef.Kind.SUPPLY else it.condition_text(),
		have,
		(" · รอส่ง %d" % pend) if pend > 0 else "",
	]
	if not wait.is_empty():
		sub += " · เครื่องของ%sรอชิ้นนี้" % ", ".join(wait)
	var locked := GameState.rank() < it.unlock_rank
	if locked:
		var e := GameState.economy if GameState.economy else EconomyConfig.new()
		sub += " · ล็อก ต้องเป็น%s" % e.rank_names[clampi(it.unlock_rank, 0, e.rank_names.size() - 1)]
	st.text = sub
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.add_theme_font_size_override(&"font_size", 12)
	st.add_theme_color_override(&"font_color", warn if not wait.is_empty() else font)
	info.add_child(st)
	var q := int(cart.get(it.id, [it, 0])[1])
	var minus := _button("−", q <= 0, false)
	minus.name = "Minus"
	minus.pressed.connect(_add.bind(it, -1))
	hb.add_child(minus)
	var ql := Label.new()
	ql.name = "Qty"
	ql.text = str(q)
	ql.custom_minimum_size = Vector2(22, 0)
	ql.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ql.add_theme_color_override(&"font_color", Color(0.15, 0.12, 0.1))
	hb.add_child(ql)
	var plus := _button("+", locked or q >= 9, true)
	plus.name = "Plus"
	plus.pressed.connect(_add.bind(it, 1))
	hb.add_child(plus)
	return p


## [0.7.0 ขั้น I] การ์ดร้านที่ลดราคา: ชื่อร้าน · ของ · ราคา · คะแนน · ข้อมูลร้าน · วิธีจ่าย · ปุ่มซื้อ/รายงาน
func _deal_row(i: int, d: Dictionary) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Deal_%d" % i
	if row_style:
		var sb := row_style.duplicate() as StyleBox
		if sb is StyleBoxFlat:
			(sb as StyleBoxFlat).bg_color = Color(1, 0.94, 0.86) if not bool(d.blacklisted) else Color(0.9, 0.86, 0.84)
		p.add_theme_stylebox_override(&"panel", sb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override(&"separation", 8)
	p.add_child(hb)
	var ic := TextureRect.new()
	ic.texture = d.icon
	ic.custom_minimum_size = Vector2(40, 40)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb.add_child(ic)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override(&"separation", 0)
	hb.add_child(info)
	var t := Label.new()
	t.text = "%s%s · %s ฿%d (ปกติ ฿%d)" % ["[บัญชีดำ] " if bool(d.blacklisted) else "", d.name, d.item, int(d.price), int(d.normal)]
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_font_size_override(&"font_size", 14)
	t.add_theme_color_override(&"font_color", Color(0.15, 0.12, 0.1))
	info.add_child(t)
	var sub := Label.new()
	var lines := PackedStringArray([String(d.rating), "จ่าย: " + String(d.payment)])
	for x in d.signs:
		lines.append("• " + String(x))
	if bool(d.blacklisted):
		lines.append("บัญชีดำของร้านขม — เคยโกง/ถูกรายงานแล้ว")
	sub.text = "\n".join(lines)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override(&"font_size", 12)
	sub.add_theme_color_override(&"font_color", font)
	info.add_child(sub)
	var bx := VBoxContainer.new()
	hb.add_child(bx)
	var done := String(d.done)
	var buy := _button("ซื้อ ฿%d" % int(d.price) if done == "" else {"bought": "สั่งแล้ว", "scammed": "โดนโกง", "reported": "รายงานแล้ว"}.get(done, "-"), not bool(d.can_buy), true)
	buy.name = "Buy"
	buy.custom_minimum_size = Vector2(96, 28)
	buy.pressed.connect(_on_deal.bind(i, true))
	bx.add_child(buy)
	var rep := _button("รายงานร้าน", done != "" or bool(d.blacklisted), false)
	rep.name = "Report"
	rep.custom_minimum_size = Vector2(96, 28)
	rep.pressed.connect(_on_deal.bind(i, false))
	bx.add_child(rep)
	return p


func _on_deal(i: int, buy: bool) -> void:
	var dl := get_node_or_null(^"/root/DayLoop")
	if dl == null:
		return
	var r: Dictionary = dl.deal_buy(i) if buy else dl.deal_report(i)
	_msg = String(r.get("msg", ""))
	var au := get_node_or_null(^"/root/Audio")
	if au and bool(r.get("ok", false)):
		au.sfx(&"coin" if buy and not bool(r.get("fake", false)) else &"click")
	refresh(true)


func _button(t: String, off: bool, primary: bool) -> Button:
	var b := Button.new()
	b.text = t
	b.disabled = off
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(30, 28)
	b.add_theme_font_size_override(&"font_size", 15)
	for c in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
		b.add_theme_color_override(c, Color(0.23, 0.16, 0.11))
	b.add_theme_color_override(&"font_disabled_color", Color(0.55, 0.5, 0.44))
	var normal := main_button if primary else side_button
	if normal:
		b.add_theme_stylebox_override(&"normal", normal)
	if main_button_hover:
		b.add_theme_stylebox_override(&"hover", main_button_hover)
		b.add_theme_stylebox_override(&"pressed", main_button_hover)
	if button_disabled:
		b.add_theme_stylebox_override(&"disabled", button_disabled)
	return b


func _add(it: ItemDef, d: int) -> void:
	var q := clampi(int(cart.get(it.id, [it, 0])[1]) + d, 0, 9)
	if q <= 0:
		cart.erase(it.id)
	else:
		cart[it.id] = [it, q]
	_msg = ""
	refresh(true)


## กดสั่งซื้อ → GameState.order_online · สำเร็จ = ล้างตะกร้า
func _on_order() -> void:
	var ls := lines()
	var total := GameState.order_total(ls)
	var why := GameState.order_online(ls)
	if why == "":
		_msg = "สั่งแล้ว จ่าย ฿%d · ของจะมาส่งตอนเปิดร้านวันถัดไป" % total
		cart.clear()
		var au := get_node_or_null(^"/root/Audio")
		if au:
			au.sfx(&"coin")
	else:
		_msg = why
	refresh(true)
