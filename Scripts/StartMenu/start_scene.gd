extends Control
## เมนูหลัก (เริ่มเกม · ตั้งค่า · ออกจากเกม) — [Claude 10 ต.ค. 2569] สร้างใหม่เป็นโหนดทั้งหมด (เดิมเป็นภาพวาด)
## ปุ่ม/ตัวละคร/หัวเรื่อง แก้ใน Start_Scene.tscn ได้ · หน้าตั้งค่า = Scene/UI/settings_panel.tscn

@export var SettingScene: SettingsPanel
@export var tutorial: TextureRect
var showTutorial = false
var _confirm_new := false
## [0.9.0] ดู/ข้ามบทนำ = หน้าเลือกการ์ดใหญ่ 2 ใบหลังสไลด์วิธีเล่น (_show_intro_choice) · เดิมเป็นตัวเลือกในบท Prolouge.txt
const PROLOGUE_SKIP_TEXT := "res://Assets/Dialog/PrologueSkip.txt"
var _skip_chosen := false
var intro_layer: CanvasLayer


func _ready() -> void:
	Global.on_start = true
	EventManager.hideUI()
	EventManager.on_tutorial_finish.connect(tutorial_end)
	EventManager.on_dialog_end.connect(dialog_end)
	# เวอร์ชันเว็บปิดหน้าต่างเองไม่ได้ → ซ่อนปุ่มออก
	$Menu/Quit_Button.visible = not OS.has_feature("web")
	# [10 ต.ค.] มีเซฟ → ปุ่ม "เล่นต่อ" (บอกกะ + เงิน)
	var info := SaveGame.info()
	$Menu/Continue_Button.visible = not info.is_empty()
	if not info.is_empty():
		$Menu/Continue_Button.text = "เล่นต่อ (%s · ฿%d)" % [TimeSystem.shift_label(int(info.shift)), info.money]
	elif SaveGame.is_old_version():
		# [0.2.0-G] เซฟจาก 0.1.x ใช้ไม่ได้ (ระบบเวลาเปลี่ยน) → บอกแทนการซ่อนเงียบ ๆ
		$Menu/Continue_Button.visible = true
		$Menu/Continue_Button.disabled = true
		$Menu/Continue_Button.text = "เซฟเวอร์ชันเก่าใช้ไม่ได้ · เริ่มใหม่"
		$Menu/Continue_Button.tooltip_text = "ระบบเวลาในเกมเปลี่ยนแล้ว เซฟจากเวอร์ชัน 0.1.x จึงโหลดไม่ได้"
	# [0.9.5] เมนูหลักเหลือแค่ปุ่มหลัก · ใบประกาศ + ส่งออกข้อมูลการเล่น + คำแนะนำ Esc ย้ายไปอยู่ในปุ่มถ้วยมุมขวาบน (_add_stats_button)
	$Version.hide()
	_add_stats_button()
	_add_form_button() # [0.9.5] ช่วยทดสอบเกม (ฟอร์มก่อน/หลังเล่น)
	for b in $Menu.get_children():
		if b is Button:
			_hover_bounce(b)
	_idle_bob($Khom, 0.0)
	_idle_bob($Grandma, 0.6)
	($Menu/Continue_Button if $Menu/Continue_Button.visible and not $Menu/Continue_Button.disabled else $Menu/Start_Button).grab_focus.call_deferred()


func dialog_end():
	EventManager.on_dialog_end.disconnect(dialog_end)
	if _skip_chosen:
		_skip_intro()
	else:
		SceneRouter.go(SceneRouter.HOME)
	Fade.set_opacity(1)


func tutorial_end():
	EventManager.on_tutorial_finish.disconnect(tutorial_end)
	_show_intro_choice()


## [0.9.0] หน้าเลือก "ดูเรื่องราวตั้งแต่ต้น" / "ข้ามไปเปิดร้านเลย" — การ์ดใหญ่ อ่านง่าย มีคำอธิบายว่าแต่ละทางได้อะไร
func _show_intro_choice() -> void:
	intro_layer = CanvasLayer.new()
	intro_layer.name = "IntroChoice"
	intro_layer.layer = 50
	add_child(intro_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.02, 0.88)
	for n in ["Menu", "Title", "Subtitle", "Logo", "Version", "VersionTag", "StatsButton", "StatsPanel", "FormButton", "FormPanel"]: # เหลือแค่ภาพพื้นหลัง + ตัวละคร
		var c := get_node_or_null(NodePath(n)) as CanvasItem
		if c:
			c.hide()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_layer.add_child(dim)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override(&"separation", 22)
	intro_layer.add_child(root)
	var title := Label.new()
	title.name = "Title"
	title.text = "จะเริ่มเรื่องแบบไหนดี?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 40)
	title.add_theme_color_override(&"font_color", Color(1, 0.95, 0.82))
	title.add_theme_color_override(&"font_outline_color", Color(0.25, 0.14, 0.05))
	title.add_theme_constant_override(&"outline_size", 6)
	root.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 28)
	root.add_child(row)
	var watch := _intro_card("WatchCard", "ดูเรื่องราวตั้งแต่ต้น", "แนะนำ · เล่นครั้งแรก",
		"รู้จักขม ยาย และปิ๊บ แล้วฝึกประกอบคอมทีละขั้นก่อนเปิดร้านจริง", "มีบทฝึกประกอบคอมกับปิ๊บ", true)
	var skip := _intro_card("SkipCard", "ข้ามไปเปิดร้านเลย", "เคยเล่นแล้ว",
		"เริ่มที่หน้าร้าน ได้ของติดตัวครบ รับลูกค้าคนแรกได้ทันที", "ดูวิธีเล่นได้จากสมุดคู่มือระหว่างซ่อม", false)
	row.add_child(watch)
	row.add_child(skip)
	watch.pressed.connect(_choose_intro.bind(false))
	skip.pressed.connect(_choose_intro.bind(true))
	var hint := Label.new()
	hint.text = "เลือกด้วยเมาส์ หรือปุ่มลูกศร + Enter"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override(&"font_size", 16)
	hint.add_theme_color_override(&"font_color", Color(1, 0.93, 0.8, 0.75))
	root.add_child(hint)
	watch.focus_neighbor_right = watch.get_path_to(skip)
	skip.focus_neighbor_left = skip.get_path_to(watch)
	watch.grab_focus.call_deferred()


## การ์ดเลือก 1 ใบ = ปุ่มใหญ่ (ทั้งการ์ดกดได้) · หัวเรื่อง · ป้าย · คำอธิบาย · หมายเหตุ
func _intro_card(card_name: String, head: String, tag: String, body: String, foot: String, primary: bool) -> Button:
	var b := Button.new()
	b.name = card_name
	b.custom_minimum_size = Vector2(420, 250)
	var base := Color(1, 0.96, 0.86) if primary else Color(0.96, 0.93, 0.87)
	var edge := Color(0.85, 0.55, 0.15) if primary else Color(0.55, 0.45, 0.35)
	for st in [&"normal", &"hover", &"pressed", &"focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = base if st == &"normal" else base.lightened(0.35)
		sb.border_color = edge if st == &"normal" else Color(1, 0.75, 0.25)
		sb.set_border_width_all(4 if st == &"normal" else 7)
		sb.set_corner_radius_all(18)
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = 10
		if st == &"focus":
			sb.draw_center = false
		b.add_theme_stylebox_override(st, sb)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		m.add_theme_constant_override(side, 22)
	b.add_child(m)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override(&"separation", 10)
	m.add_child(v)
	var pill := Label.new()
	pill.name = "Tag"
	pill.text = "  " + tag + "  "
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pill.add_theme_font_size_override(&"font_size", 16)
	pill.add_theme_color_override(&"font_color", Color.WHITE)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.82, 0.45, 0.1) if primary else Color(0.5, 0.42, 0.35)
	ps.set_corner_radius_all(10)
	ps.set_content_margin_all(3)
	pill.add_theme_stylebox_override(&"normal", ps)
	v.add_child(pill)
	var t := Label.new()
	t.name = "Head"
	t.text = head
	t.add_theme_font_size_override(&"font_size", 32)
	t.add_theme_color_override(&"font_color", Color(0.3, 0.16, 0.05))
	v.add_child(t)
	var d := Label.new()
	d.name = "Body"
	d.text = body
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(370, 0)
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	d.add_theme_font_size_override(&"font_size", 21)
	d.add_theme_color_override(&"font_color", Color(0.25, 0.18, 0.12))
	v.add_child(d)
	var f := Label.new()
	f.name = "Foot"
	f.text = foot
	f.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	f.add_theme_font_size_override(&"font_size", 16)
	f.add_theme_color_override(&"font_color", Color(0.5, 0.38, 0.25))
	v.add_child(f)
	for n in [pill, t, d, f]:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## เลือกแล้ว → เล่นบทนำ (ออฟฟิศ) หรือบทสั้นข้ามบทนำ (dialog_end ไปต่อ) · จดลง playlog/start.csv
func _choose_intro(skip: bool) -> void:
	if intro_layer:
		intro_layer.queue_free()
		intro_layer = null
	_skip_chosen = skip
	Playlog.append("start.csv", ["choice"], ["skip_intro" if skip else "watch_intro"])
	if skip:
		EventManager.show_dialog("บ้านยาย", PROLOGUE_SKIP_TEXT, Constant.BG_DIR + "bg_path_sunset.jpg")
	else:
		EventManager.show_dialog("ออฟฟิศ", Constant.PROLOUGE_TEXT, Constant.OFFICE_BG)
	Global.on_start = false
	showTutorial = false
	EventManager.showUI()
	self.hide()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_option_button_pressed() -> void:
	SettingScene.open()


func _on_start_button_pressed() -> void:
	if showTutorial:
		return
	# [10 ต.ค.] มีเซฟอยู่ → ถามก่อน (กดซ้ำ = เริ่มใหม่ · เซฟเดิมถูกแทนที่ด้วยเซฟใหม่ตอนเข้าบ้าน)
	if SaveGame.exists() and not _confirm_new:
		_confirm_new = true
		$Menu/Start_Button.text = "เริ่มใหม่? กดอีกครั้ง"
		$Menu/Start_Button.tooltip_text = "เซฟเดิมจะถูกแทนที่ด้วยเกมใหม่"
		return
	SaveGame.clear() # เริ่มใหม่ = ลบเซฟเดิม → เซฟใหม่สร้างเองตอนเข้าฉากแรก
	DayLoop._reset_run()
	EventManager.jump_event(EventManager.EventID.MAIN, 0) # เควสต์กลับขั้นแรก (กรณีกลับเมนูมาเริ่มใหม่)
	EventManager.hideUI()
	showTutorial = true
	EventManager.show_tutorial(EventManager.TutorialState.BASIC_START)


## [0.3.0 ขั้น J] ข้ามบทนำ = ตัวเลือกต้นบทนำ (Assets/Dialog/Prolouge.txt) · ไม่ใช่ปุ่มที่เมนู
## จบเควสต์หลักทั้งหมด + ของติดตัว → ไปหน้าร้าน (บทพักก่อนลูกค้าคนแรกยังเล่นตามปกติ)
func _skip_intro() -> void:
	var ev = EventManager.eventMap.get(EventManager.EventID.MAIN)
	if ev:
		EventManager.jump_event(EventManager.EventID.MAIN, 0)
		EventManager.complete_step(EventManager.EventID.MAIN, ev.totalTask - 1)
	GameState.ensure_starter_kit()
	EventManager.showUI()
	await SceneRouter.go(SceneRouter.ROOM)
	SaveGame.save()


## ปุ่มขยายนิดหน่อยตอนเอาเมาส์ชี้
func _hover_bounce(b: Button) -> void:
	b.pivot_offset = b.custom_minimum_size / 2.0
	b.mouse_entered.connect(func(): create_tween().tween_property(b, "scale", Vector2(1.05, 1.05), 0.1))
	b.mouse_exited.connect(func(): create_tween().tween_property(b, "scale", Vector2.ONE, 0.1))


## ตัวละครหายใจเบา ๆ
func _idle_bob(n: Control, delay: float) -> void:
	var tw := create_tween().set_loops()
	tw.tween_interval(delay)
	tw.tween_property(n, "scale", Vector2(1.0, 1.025), 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(n, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE)


## โหลดเซฟ → ข้ามบทนำ ไปฉากที่บันทึกไว้
func _on_continue_button_pressed() -> void:
	if showTutorial:
		return
	showTutorial = true
	var loc := SaveGame.load_into()
	if loc < 0:
		showTutorial = false
		$Menu/Continue_Button.hide()
		return
	EventManager.on_tutorial_finish.disconnect(tutorial_end)
	EventManager.on_dialog_end.disconnect(dialog_end)
	Global.on_start = false
	EventManager.showUI()
	hide()
	SceneRouter.go(loc)


## [0.9.5] ปุ่มถ้วยมุมขวาบน → หน้าความสำเร็จ (รวมทุกเซฟ) แยก 5 หมวด (AchievementApp · source_profile)
## เดิม (0.7.0–0.9.0) ป้ายใบประกาศมุมซ้ายล่าง + ปุ่มส่งออกมุมขวาล่าง + ป้าย Esc → ผู้ใช้ 16 พ.ย.: รก · ส่งออกข้อมูลการเล่นอยู่ในเมนูพัก (Esc) ที่เดียว
const ACH_APP := preload("res://Scene/UI/achievement_app.tscn")


func _add_stats_button() -> void:
	var t := Button.new()
	t.name = "StatsButton"
	t.icon = load("res://Assets/UI/Icons/icon_trophy.png") as Texture2D
	t.expand_icon = true
	t.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.tooltip_text = "ความสำเร็จ"
	t.custom_minimum_size = Vector2(60, 60)
	t.size = Vector2(60, 60)
	t.position = Vector2(1152 - 60 - 18, 18)
	t.focus_mode = Control.FOCUS_NONE
	for st in [&"normal", &"hover", &"pressed"]: # ปุ่มกลมเล็ก (ธีมเมนูมีขอบไม้หนา ไอคอนเหลือนิดเดียว)
		var rs := StyleBoxFlat.new()
		rs.bg_color = Color(1, 0.95, 0.82) if st == &"normal" else Color(1, 0.86, 0.55)
		rs.border_color = Color(0.45, 0.28, 0.12)
		rs.set_border_width_all(3)
		rs.set_corner_radius_all(30)
		rs.set_content_margin_all(9)
		t.add_theme_stylebox_override(st, rs)
	var overlay := Control.new() # พื้นมืด + หน้าความสำเร็จ (กดพื้นมืดเพื่อปิด)
	overlay.name = "StatsPanel"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.hide()
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			overlay.hide())
	overlay.add_child(dim)
	var page := PanelContainer.new()
	page.name = "Page"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 0.97, 0.9)
	sb.border_color = Color(0.6, 0.42, 0.2)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(16)
	page.add_theme_stylebox_override(&"panel", sb)
	page.position = Vector2(226, 44)
	page.size = Vector2(700, 560)
	page.custom_minimum_size = Vector2(700, 560)
	overlay.add_child(page)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 8)
	page.add_child(box)
	var app := ACH_APP.instantiate()
	app.source_profile = true
	app.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(app)
	var close := Button.new()
	close.name = "Close"
	close.text = "กลับ"
	close.custom_minimum_size = Vector2(180, 40)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.add_theme_font_size_override(&"font_size", 18)
	close.pressed.connect(overlay.hide)
	box.add_child(close)
	t.pressed.connect(func() -> void:
		overlay.visible = not overlay.visible
		if overlay.visible:
			app.refresh(true))
	add_child(t) # ปุ่มถ้วยอยู่บนสุด (กดซ้ำเพื่อปิด)


## [0.9.5] ปุ่มคลิปบอร์ดกลม (ข้างถ้วย) → แผง "ช่วยทดสอบเกม": แบบทดสอบก่อนเล่น · หลังเล่น (เปิดเบราว์เซอร์ · Playlog.FORM_*)
func _add_form_button() -> void:
	var t := Button.new()
	t.name = "FormButton"
	t.icon = load("res://Assets/UI/Icons/icon_clipboard.png") as Texture2D
	t.expand_icon = true
	t.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.tooltip_text = "ช่วยทดสอบเกม"
	t.custom_minimum_size = Vector2(60, 60)
	t.size = Vector2(60, 60)
	t.position = Vector2(1152 - 60 - 18 - 72, 18)
	t.focus_mode = Control.FOCUS_NONE
	for st in [&"normal", &"hover", &"pressed"]:
		var rs := StyleBoxFlat.new()
		rs.bg_color = Color(1, 0.95, 0.82) if st == &"normal" else Color(1, 0.86, 0.55)
		rs.border_color = Color(0.45, 0.28, 0.12)
		rs.set_border_width_all(3)
		rs.set_corner_radius_all(30)
		rs.set_content_margin_all(10)
		t.add_theme_stylebox_override(st, rs)
	var overlay := Control.new()
	overlay.name = "FormPanel"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.hide()
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			overlay.hide())
	overlay.add_child(dim)
	var page := PanelContainer.new()
	page.name = "Page"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 0.97, 0.9)
	sb.border_color = Color(0.6, 0.42, 0.2)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(18)
	page.add_theme_stylebox_override(&"panel", sb)
	page.custom_minimum_size = Vector2(560, 0)
	page.position = Vector2(296, 70)
	overlay.add_child(page)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 10)
	page.add_child(box)
	var head := Label.new()
	head.text = "ช่วยทดสอบเกม 🙏"
	head.add_theme_font_size_override(&"font_size", 24)
	head.add_theme_color_override(&"font_color", Color(0.45, 0.22, 0.05))
	box.add_child(head)
	var body := Label.new()
	body.text = "บักช่างขมเป็นส่วนหนึ่งของโครงงานศึกษาการเรียนรู้ผ่านเกม หากท่านสะดวก รบกวนช่วยทำแบบทดสอบก่อนเริ่มเล่นและหลังเล่นจบ เพื่อนำผลไปพัฒนาเกมต่อไป\nสแกน QR ด้วยมือถือ หรือกดลิงก์ใต้รูปได้เลย ขอบคุณมากครับ 🙏\n(ไม่ทำแบบทดสอบก็เล่นได้ตามปกติ)"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override(&"font_size", 17)
	body.add_theme_color_override(&"font_color", Color(0.25, 0.16, 0.1))
	box.add_child(body)
	# [0.9.5] QR + ลิงก์ใต้ QR (สแกนด้วยมือถือ หรือกดลิงก์เปิดเบราว์เซอร์) · รูป QR สร้างจาก Playlog.FORM_* (Assets/UI/QR/ · เปลี่ยนลิงก์ต้องสร้าง QR ใหม่)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 36)
	box.add_child(row)
	for f in [[&"pre", "แบบทดสอบก่อนเล่น", Playlog.FORM_PRE], [&"post", "แบบทดสอบหลังเล่น", Playlog.FORM_POST]]:
		var col := VBoxContainer.new()
		col.name = "Form_" + String(f[0])
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override(&"separation", 4)
		row.add_child(col)
		var cap := Label.new()
		cap.text = String(f[1])
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.add_theme_font_size_override(&"font_size", 18)
		cap.add_theme_color_override(&"font_color", Color(0.45, 0.22, 0.05))
		col.add_child(cap)
		var qr := TextureRect.new()
		qr.name = "QR"
		qr.texture = load("res://Assets/UI/QR/form_%s.png" % String(f[0])) as Texture2D
		qr.custom_minimum_size = Vector2(150, 150)
		qr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		qr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		qr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		qr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(qr)
		var link := LinkButton.new()
		link.name = "Link"
		link.text = String(f[2]).trim_prefix("https://")
		link.tooltip_text = "เปิดในเบราว์เซอร์"
		link.underline = LinkButton.UNDERLINE_MODE_ALWAYS
		link.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		link.add_theme_font_size_override(&"font_size", 15)
		link.add_theme_color_override(&"font_color", Color(0.15, 0.35, 0.7))
		link.add_theme_color_override(&"font_hover_color", Color(0.1, 0.25, 0.55))
		link.pressed.connect(Playlog.open_form.bind(f[0]))
		col.add_child(link)
	var close := Button.new()
	close.name = "Close"
	close.text = "กลับ"
	close.custom_minimum_size = Vector2(160, 38)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.add_theme_font_size_override(&"font_size", 17)
	close.pressed.connect(overlay.hide)
	box.add_child(close)
	t.pressed.connect(func() -> void: overlay.visible = not overlay.visible)
	add_child(t)
