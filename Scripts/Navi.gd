extends CanvasLayer

# --- Antigravity ---
# [Navi: Tutorial Tip Box only]

var message_box: PanelContainer
var label: RichTextLabel
var tween: Tween
var sprite: Sprite2D
var navi_icon = preload("res://icon.svg")

# Progress UI
var progress_panel: PanelContainer
var progress_bar: ProgressBar
var progress_label: Label

# สถานะ
var tips_shown = {}

func _ready():
	self.layer = 120
	_build_tip_ui()
	_build_progress_ui()

## --- helper: ตั้ง IGNORE ให้ node และ children ทั้งหมด ---
func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)

## --- สร้าง UI ---

func _build_tip_ui():
	# กล่องข้อความ Navi — มุมขวาล่าง เป็นกล่องเล็กๆ
	message_box = PanelContainer.new()
	add_child(message_box)
	# ล็อคตำแหน่ง 4 ด้านชัดเจน มุมขวาบน ขนาด 244x50px
	message_box.anchor_left   = 1.0
	message_box.anchor_top    = 0.0
	message_box.anchor_right  = 1.0
	message_box.anchor_bottom = 0.0
	message_box.offset_left   = -260  # ความกว้าง = 260-16 = 244px
	message_box.offset_top    = 16
	message_box.offset_right  = -16
	message_box.offset_bottom = 66    # ความสูง = 66-16 = 50px
	message_box.modulate.a = 0

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.18, 0.93)
	style.set_corner_radius_all(10)
	style.set_border_width_all(2)
	style.border_color = Color(0.2, 0.8, 1.0)
	message_box.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 52)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	message_box.add_child(margin)

	label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = false
	label.scroll_active = false
	label.clip_contents = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# กำหนด min/max ของ label: สูงสุด ~3 บรรทัด
	label.custom_minimum_size = Vector2(0, 36)
	margin.add_child(label)

	sprite = Sprite2D.new()
	sprite.texture = navi_icon
	sprite.scale = Vector2(0.22, 0.22)
	sprite.position = Vector2(26, 28)
	message_box.add_child(sprite)

	_ignore_mouse(message_box)

func _build_progress_ui():
	# Progress Bar (ด้านบนกลาง ตอนมินิเกม)
	progress_panel = PanelContainer.new()
	add_child(progress_panel)
	progress_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 20)
	progress_panel.offset_top = 90
	progress_panel.custom_minimum_size = Vector2(320, 50)
	progress_panel.modulate.a = 0

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.88)
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = Color(0.4, 0.9, 0.4)
	progress_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	progress_panel.add_child(margin)

	var vb = VBoxContainer.new()
	margin.add_child(vb)

	progress_label = Label.new()
	progress_label.text = "ความคืบหน้าการซ่อม RAM"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	vb.add_child(progress_label)

	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 15
	progress_bar.value = 0
	progress_bar.custom_minimum_size = Vector2(280, 18)
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.2, 0.9, 0.3)
	bar_fill.set_corner_radius_all(4)
	progress_bar.add_theme_stylebox_override("fill", bar_fill)
	vb.add_child(progress_bar)

	_ignore_mouse(progress_panel)

## === ฟังก์ชัน Tip ===

func show_tip(text: String, duration: float = 6.0, tip_id: String = ""):
	if label == null: return
	if tip_id != "" and tips_shown.has(tip_id): return
	if tip_id != "": tips_shown[tip_id] = true

	# ไม่ใช้ [center] เพราะทำให้กล่องยืด
	label.text = text
	if tween: tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(message_box, "modulate:a", 1.0, 0.5)
	tween.tween_interval(duration)
	tween.tween_property(message_box, "modulate:a", 0.0, 0.5)

## === Quest stubs (ไม่ทำงาน เพื่อไม่ให้ code อื่น error) ===

func show_quest(_quest_text: String, _arrow_text: String = ""):
	pass  # ถูกลบออกแล้ว

func hide_quest():
	pass  # ถูกลบออกแล้ว

## === ฟังก์ชัน Progress Bar ===

func show_progress(max_val: int = 15):
	if progress_bar == null: return
	progress_bar.max_value = max_val
	progress_bar.value = 0
	var t = create_tween()
	t.tween_property(progress_panel, "modulate:a", 1.0, 0.4)

func update_progress(val: int):
	if progress_bar == null: return
	progress_bar.value = val
	var pct = int((float(val) / float(progress_bar.max_value)) * 100)
	progress_label.text = "ความคืบหน้าการซ่อม RAM: %d%%" % pct

func hide_progress():
	if progress_panel == null: return
	var t = create_tween()
	t.tween_property(progress_panel, "modulate:a", 0.0, 0.4)

## === ฟังก์ชัน Tutorial ===

func guide_to_grandma():
	show_tip("ดูที่บ้านคุณยายสิ มีเครื่องหมาย [color=red]![/color] อยู่ ลองคลิกเข้าไปทักทายเธอดูครับ", 7.0, "grandma")

func guide_movement():
	show_tip("ใช้ปุ่ม [color=cyan]W, A, S, D[/color] เพื่อเดิน หรือ [color=yellow]Arrow Keys[/color] ก็ได้ครับ", 6.0, "walk")

func guide_repair():
	show_tip("โอ้! RAM สกปรกมากเลยครับ ลอง[color=yellow]คลิกขยับยางลบ[/color]ไปมาเพื่อทำความสะอาดนะ!", 7.0, "repair")

func guide_to_desk():
	_hide_door_arrow()
	show_tip("ดูเหมือนที่ [color=yellow]โต๊ะทำงานของขม[/color] จะมีของให้ซ่อมอยู่นะครับ ลองเข้าไปดูสิ!", 6.0, "desk")

func guide_quest_door():
	show_tip("ไปที่ [color=yellow]ประตูห้องของขม[/color] แล้วเลือกซ่อมคอมได้เลยครับ!", 5.0, "door")
	_show_door_arrow()

## ลูกศรเด้งชี้ไปที่ประตู
var _door_arrow: Label
var _arrow_tween: Tween

func _show_door_arrow():
	if _door_arrow == null:
		_door_arrow = Label.new()
		add_child(_door_arrow)
		_door_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_door_arrow.add_theme_font_size_override("font_size", 52)
		_door_arrow.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	_door_arrow.text = "↘"
	_door_arrow.position = Vector2(980, 440)
	_door_arrow.show()
	_door_arrow.modulate.a = 1.0
	if _arrow_tween: _arrow_tween.kill()
	_arrow_tween = create_tween().set_loops()
	_arrow_tween.tween_property(_door_arrow, "position", Vector2(1010, 470), 0.5).set_ease(Tween.EASE_IN_OUT)
	_arrow_tween.tween_property(_door_arrow, "position", Vector2(980, 440), 0.5).set_ease(Tween.EASE_IN_OUT)

func _hide_door_arrow():
	if _door_arrow != null:
		if _arrow_tween: _arrow_tween.kill()
		_door_arrow.hide()
