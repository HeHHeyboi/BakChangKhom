extends Node
## [Claude 10 ต.ค. 2569] ทดสอบแผนที่ใหม่ (กดรูปแล้วไป ไม่ต้องเดิน) · ตลาดแบบกด · ห้องเก็บของ (หายางลบ) · ป้ายเวลาเป็น Label
## เปิด Test/map_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	# ---- แผนที่
	var cards: Array = MapPanel.cards.get_children().filter(func(c): return c is MapCard)
	_check(cards.size() == 5, "แผนที่มี 5 สถานที่ (%d)" % cards.size())
	var names: Array = cards.map(func(c): return c.title)
	_check(names == ["บ้าน", "หน้าบ้าน", "ร้านช่างขม", "ตลาด", "เมือง"], "ชื่อสถานที่ %s" % [names])
	_check(cards.all(func(c): return c.thumbnail != null), "ทุกการ์ดมีรูป")
	_check(MapPanel.card_for(SceneRouter.MARKET) != null and MapPanel.get_node("Root/Cards/City").locked, "เมืองล็อก (เร็ว ๆ นี้)")
	await SceneRouter.go(SceneRouter.HOME)
	MapPanel.show()
	await _frames(3)
	_check(MapPanel.get_node("Root/Cards/Home").is_here and MapPanel.get_node("Root/Cards/Home/Here").visible, "การ์ดบ้านขึ้น 'อยู่ที่นี่'")
	_check(MapPanel.here_label.text == "ตอนนี้อยู่: บ้าน", "แถบล่าง: %s" % MapPanel.here_label.text)
	_check(not PauseMenu.can_pause(), "เปิดแผนที่อยู่ → Esc ไม่เปิดเมนูพัก")
	await _shot("map")
	MapPanel._on_card_hovered(MapPanel.get_node("Root/Cards/Shop"), true)
	_check(MapPanel.speech.text.contains("ร้านซ่อมคอม"), "ชี้การ์ด → ปิ๊บอธิบาย")
	MapPanel._on_card_pressed(MapPanel.get_node("Root/Cards/City"))
	_check(MapPanel.visible and MapPanel.speech.text.contains("ยังไปไม่ได้"), "กดที่ล็อก → ไม่ไป + บอกเหตุผล")
	MapPanel._on_card_pressed(MapPanel.get_node("Root/Cards/Market"))
	await _frames(2)
	_check(not MapPanel.visible, "กดตลาด → ปิดแผนที่")
	await get_tree().create_timer(1.2).timeout
	_check(SceneRouter.current_id == SceneRouter.MARKET, "ไปตลาดทันที (ไม่ต้องเดิน)")
	var market: Node = SceneRouter.location_slot.get_child(0)
	_check(market is Control and market.find_child("Player", true, false) == null, "ตลาดไม่มีตัวเดิน")
	var stalls: Array = market.get_children().filter(func(c): return c is MarketStall)
	_check(stalls.size() == 3, "ตลาดมี 3 แผง")
	stalls[0].pressed.emit()
	var sp: ShopPanel = market.get_node("ShopPanel")
	_check(sp.visible and sp.title.text == "ร้านอะไหล่คอม" and sp.empty.visible and sp.empty.text.contains("ยังไม่มีของขาย"), "กดแผง → หน้าต่างร้านค้า (ยังไม่มีของขาย)")
	await get_tree().create_timer(0.6).timeout
	await _shot("shop")
	var it := ShopItem.new()
	it.display_name = "แปรงขนนุ่ม"
	it.price = 50
	sp.open("ทดสอบ", [it] as Array[ShopItem])
	var m0 := GameState.money
	_check(not sp.empty.visible and sp.list.get_child_count() == 1 and sp.buy(it) and GameState.money == m0 - 50, "มีของ → ซื้อได้ หักเงิน")
	GameState.add_money(50)
	sp.close_button.pressed.emit()
	_check(not sp.visible, "ออกจากร้าน → ปิดหน้าต่าง")
	await _shot("market")
	SceneRouter.clear()
	# ---- ห้องหายางลบ = ห้องเก็บของ (คนละฉากกับร้าน)
	var fi: Node = load("res://Scene/MiniGame/find_item_minigame.tscn").instantiate()
	add_child(fi)
	await _frames(2)
	_check((fi.get_node("BG") as TextureRect).texture.resource_path.ends_with("bg_khom_room.jpg"), "ห้องของขม (ฉากหายางลบเดิม ไม่ได้ใช้ในเควสต์แล้ว)")
	_check(fi.get_node("RichTextLabel") is Label and fi.text.text != "", "ข้อความหายางลบเป็น Label")
	await _shot("find")
	fi.queue_free()
	# ---- ป้ายเวลาเลิกใช้ RichTextLabel (error Rect2i)
	var ts: Node = load("res://Scene/time_system.tscn").instantiate()
	add_child(ts)
	await _frames(1)
	ts.updateTime()
	_check(ts.timeText is Label and ts.dateText is Label and ts.dateText.text.contains("บทที่"), "ป้ายเวลา/วันที่เป็น Label")
	ts.queue_free()
	_check(DialogScene.Title is Label, "ชื่อบทใน DialogScene เป็น Label")
	SceneRouter.clear()
	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _check(ok: bool, what: String) -> void:
	if ok:
		print("PASS ", what)
	else:
		fails += 1
		print("FAIL ", what)


func _shot(n: String) -> void:
	if OS.get_environment("SHOT") == "":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_jpg(OS.get_environment("SHOT") + "/map_%s.jpg" % n, 0.8)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
