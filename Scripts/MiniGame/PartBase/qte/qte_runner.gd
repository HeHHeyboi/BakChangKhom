class_name QteRunner extends Control
## ตัวเล่น QTE กลางของมินิเกม Core Part — PartMinigame สร้างให้เอง (owner.qte)
## ใช้ใน phase:  var r: QteRunner.Result = await owner.qte.run(SPEC, node("RamA2"))
## เมาส์ซ้าย หรือ Space ใช้ได้ทุกแบบ · ระหว่างเล่นบังคลิกฉากข้างหลัง
## กราฟิกตอนนี้วาดด้วย _draw() (placeholder) — ภาพจริงตามรายการใน Docs/CORE_PART_QTE.md ข้อ 7
## [Claude 5 ต.ค. 2569]

enum Result { PERFECT, GOOD, MISS }

## ระหว่างเล่น ค่าปัจจุบัน 0..1 (ใช้ขยับชิ้นงานตามตัวชี้/เกจ)
signal value_changed(value: float)
signal finished(result: Result)

## โหมดช่วย: ช้าลง 2 เท่า + โซนกว้าง 1.5 เท่า (ไว้ผูกหน้าตั้งค่า)
static var assist := false
## บอททดสอบ: ≥ 0 = จบทันทีด้วยผลนี้ (Result.PERFECT / MISS) · −1 = เล่นจริง
static var auto_result := -1

const COL_FRAME := Color(0.85, 0.65, 0.2)
const COL_BG := Color(0.12, 0.1, 0.08, 0.85)
const COL_ZONE := Color(0.35, 0.75, 0.35)
const COL_PERFECT := Color(0.65, 0.95, 0.5)
const COL_POINTER := Color(1.0, 0.55, 0.15)
const COL_OVER := Color(0.85, 0.25, 0.2)
const BAR := Vector2(360, 26)
const GAUGE := Vector2(34, 200)

## ค่าตอนกด/ปล่อยครั้งล่าสุด (HOLD: < zone.x = ปล่อยเร็ว · > zone.y = ค้างนานเกิน)
var last_value := 0.0
var running := false

var _spec: QteSpec
var _zone := Vector2.ZERO
var _perfect := Vector2.ZERO
var _duration := 1.0
var _t := 0.0          # เวลาที่ผ่าน
var _value := 0.0
var _holding := false
var _anchor := Vector2.ZERO
var _hint: Label
var _flash: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 20)
	_hint.add_theme_color_override("font_color", Color.WHITE)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.visible = false
	add_child(_hint)
	_flash = Label.new()
	_flash.add_theme_font_size_override("font_size", 34)
	_flash.add_theme_color_override("font_outline_color", Color.BLACK)
	_flash.add_theme_constant_override("outline_size", 8)
	_flash.visible = false
	add_child(_flash)
	set_process(false)


## เล่น QTE เหนือ target (Control ใด ๆ เช่น Item2D) · zone_scale > 1 = ง่ายขึ้น (ครั้งแรกที่เจอ Part ใช้ 1.5)
func run(spec: QteSpec, target: Control = null, zone_scale := 1.0) -> Result:
	if not is_inside_tree():
		push_warning("QteRunner.run: runner ไม่อยู่ใน scene tree")
		return Result.MISS
	if running:
		push_warning("QteRunner: เรียก run ซ้อนกัน")
		await get_tree().process_frame
		return Result.MISS
	if auto_result >= 0:
		await get_tree().process_frame
		last_value = 0.5
		return clampi(auto_result, Result.PERFECT, Result.MISS) as Result
	if spec == null or spec.kind > QteSpec.Kind.HOLD:
		push_warning("QteRunner: ยังไม่รองรับ QTE แบบนี้ — ให้ผ่านเป็น GOOD")
		await get_tree().process_frame
		return Result.GOOD
	_spec = spec
	var s := clampf(zone_scale, 0.25, 4.0) * (1.5 if assist else 1.0)
	_zone = spec.scaled_zone(_ordered(spec.zone), s)
	_perfect = spec.scaled_zone(_ordered(spec.perfect), s)
	# PERFECT ต้องอยู่ในโซน GOOD เสมอ
	_perfect = Vector2(clampf(_perfect.x, _zone.x, _zone.y), clampf(_perfect.y, _zone.x, _zone.y))
	_duration = maxf(spec.duration, 0.1) * (2.0 if assist else 1.0)
	_t = 0.0
	_value = 0.0
	_holding = false
	_anchor = _anchor_for(target)
	_hint.text = spec.hint
	_hint.visible = spec.hint != ""
	_hint.reset_size()
	_hint.position = _anchor + Vector2(-_hint.size.x * 0.5, -90.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	running = true
	set_process(true)
	queue_redraw()
	var r: Result = await finished
	return r


## ค่าที่กรอกกลับด้าน (x > y) ใน Inspector → สลับให้
static func _ordered(v: Vector2) -> Vector2:
	return Vector2(minf(v.x, v.y), maxf(v.x, v.y))


## ยกเลิกกลางคัน (phase ถูกข้าม) = MISS
func cancel() -> void:
	if running:
		_end(Result.MISS, false)


func _anchor_for(target: Control) -> Vector2:
	var vp := get_viewport_rect().size
	var p := vp * Vector2(0.5, 0.4)
	if target and target.is_inside_tree():
		var r := target.get_global_rect()
		p = r.get_center()
	# ให้แถบอยู่ในจอเสมอ
	p.x = clampf(p.x, BAR.x * 0.5 + 16, vp.x - BAR.x * 0.5 - 16)
	p.y = clampf(p.y, 120.0, vp.y - GAUGE.y * 0.5 - 16)
	return p


func _process(delta: float) -> void:
	if not running or _spec == null:
		return
	_t += delta
	match _spec.kind:
		QteSpec.Kind.TIMING:
			var phase := _t / _duration      # 1 เที่ยว = ซ้ายไปขวา หรือขวาไปซ้าย
			_value = pingpong(phase, 1.0)
			if phase >= _spec.max_sweeps:
				last_value = _value
				_end(Result.MISS)
				return
		QteSpec.Kind.HOLD:
			if _holding:
				_value = minf(_value + delta / _duration, 1.0)
				if _value >= 1.0:              # ค้างจนสุดเกจ = แรงเกิน
					last_value = 1.0
					_end(Result.MISS)
					return
			elif _t >= _duration * _spec.max_sweeps:
				last_value = 0.0
				_end(Result.MISS)
				return
	value_changed.emit(_value)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not running or _spec == null or not is_visible_in_tree():
		return
	var pressed := false
	var released := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		released = not event.pressed
	elif event is InputEventKey and event.physical_keycode == KEY_SPACE and not event.echo:
		pressed = event.pressed
		released = not event.pressed
	else:
		return
	get_viewport().set_input_as_handled()
	match _spec.kind:
		QteSpec.Kind.TIMING:
			if pressed:
				last_value = _value
				_end(_grade(_value))
		QteSpec.Kind.HOLD:
			if pressed:
				_holding = true
			elif released and _holding:
				last_value = _value
				_end(_grade(_value))


func _grade(v: float) -> Result:
	if v >= _perfect.x and v <= _perfect.y:
		return Result.PERFECT
	if v >= _zone.x and v <= _zone.y:
		return Result.GOOD
	return Result.MISS


func _end(r: Result, show_flash := true) -> void:
	running = false
	_holding = false
	set_process(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.visible = false
	queue_redraw()
	if show_flash:
		_show_flash(r)
	finished.emit(r)


func _show_flash(r: Result) -> void:
	if not is_inside_tree():
		return
	_flash.text = ["PERFECT!", "GOOD", "MISS"][r]
	_flash.add_theme_color_override("font_color", [COL_PERFECT, COL_ZONE, COL_OVER][r])
	_flash.visible = true
	_flash.modulate.a = 1.0
	_flash.reset_size()
	_flash.position = _anchor + Vector2(-_flash.size.x * 0.5, -140.0)
	var tw := create_tween()
	tw.tween_property(_flash, "position:y", _flash.position.y - 24.0, 0.6)
	tw.parallel().tween_property(_flash, "modulate:a", 0.0, 0.6).set_delay(0.25)
	tw.tween_callback(func(): _flash.visible = false)


func _draw() -> void:
	if not running or _spec == null:
		return
	match _spec.kind:
		QteSpec.Kind.TIMING:
			var r := Rect2(_anchor + Vector2(-BAR.x * 0.5, -54.0), BAR)
			draw_rect(r.grow(4), COL_BG)
			draw_rect(Rect2(r.position + Vector2(r.size.x * _zone.x, 0), Vector2(r.size.x * (_zone.y - _zone.x), r.size.y)), COL_ZONE)
			draw_rect(Rect2(r.position + Vector2(r.size.x * _perfect.x, 0), Vector2(r.size.x * (_perfect.y - _perfect.x), r.size.y)), COL_PERFECT)
			draw_rect(r.grow(4), COL_FRAME, false, 3.0)
			var x := r.position.x + r.size.x * _value
			draw_rect(Rect2(x - 4, r.position.y - 10, 8, r.size.y + 20), COL_POINTER)
		QteSpec.Kind.HOLD:
			var r := Rect2(_anchor + Vector2(BAR.x * 0.5 - GAUGE.x, -GAUGE.y * 0.5), GAUGE)
			draw_rect(r.grow(4), COL_BG)
			var y_of := func(v: float) -> float: return r.end.y - r.size.y * v
			draw_rect(Rect2(r.position.x, y_of.call(1.0), r.size.x, y_of.call(_zone.y) - y_of.call(1.0)), COL_OVER.darkened(0.3))
			draw_rect(Rect2(r.position.x, y_of.call(_zone.y), r.size.x, y_of.call(_zone.x) - y_of.call(_zone.y)), COL_ZONE.darkened(0.2))
			draw_rect(Rect2(r.position.x, y_of.call(_perfect.y), r.size.x, y_of.call(_perfect.x) - y_of.call(_perfect.y)), COL_PERFECT.darkened(0.2))
			draw_rect(Rect2(r.position.x + 6, y_of.call(_value), r.size.x - 12, r.end.y - y_of.call(_value)), COL_POINTER)
			draw_rect(r.grow(4), COL_FRAME, false, 3.0)
