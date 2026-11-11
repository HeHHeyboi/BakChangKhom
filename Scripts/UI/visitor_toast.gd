class_name VisitorToast extends PanelContainer
## [0.2.5 · 8 พ.ย. 2569] ป้ายแจ้ง "ลูกค้าเข้าร้าน" กลางบนจอ — PLAN_0_2_5 ข้อ 3
## ฉาก Scene/UI/visitor_toast.tscn (วางใน day_loop.tscn → ToastLayer ชั้น 104: เหนือ HUD/แถบเป้า 100 · ใต้ปุ่มคลัง 105 · สรุปเดือน 108 · ข้ามวัน 110 · บทพูด 128)
## DayLoop เรียก show_message() ตอนเปิดร้าน (ชื่อเสียง → ลูกค้าวันนี้) และทุกครั้งที่ลูกค้ารอบใหม่เดินเข้ามา
## ข้อความเข้าคิว · ไม่ขึ้นระหว่างมินิเกม / บทพูด / ฉากข้ามวัน แล้วค่อยขึ้นทีหลัง

## วินาทีที่ป้ายค้างบนจอ (ไม่รวมเฟด)
@export var hold_seconds := 2.6
## วินาทีเฟดเข้า/ออก
@export var fade_seconds := 0.25
## เก็บข้อความรอได้กี่อัน (เกินนี้ทิ้งอันเก่า)
@export var max_queue := 3

@onready var _title: Label = %ToastTitle
@onready var _body: Label = %ToastBody

var _queue: Array[PackedStringArray] = []
var _tw: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	modulate.a = 0.0


## title = บรรทัดใหญ่ ("ลูกค้าเดินเข้าร้าน 2 คน") · body = บรรทัดเล็ก (ว่างได้)
func show_message(title: String, body := "") -> void:
	_queue.append(PackedStringArray([title, body]))
	while _queue.size() > max_queue:
		_queue.pop_front()


func is_showing() -> bool:
	return _tw != null and _tw.is_valid() and _tw.is_running()


func clear() -> void:
	_queue.clear()
	if _tw and _tw.is_valid():
		_tw.kill()
	visible = false
	modulate.a = 0.0


func _process(_delta: float) -> void:
	if _queue.is_empty() or is_showing() or _blocked():
		return
	var m: PackedStringArray = _queue.pop_front()
	_title.text = m[0]
	_body.text = m[1]
	_body.visible = m[1] != ""
	visible = true
	modulate.a = 0.0
	_tw = create_tween()
	_tw.tween_property(self, "modulate:a", 1.0, fade_seconds)
	_tw.tween_interval(hold_seconds)
	_tw.tween_property(self, "modulate:a", 0.0, fade_seconds)
	_tw.tween_callback(func() -> void: visible = false)


## ไม่แสดงตอนมินิเกม · บทพูด · ฉากข้ามวัน · เมนูหลัก/เมนูพัก · ยังไม่เริ่มลูปร้าน (บทนำ/เควสต์หลัก) · อยู่นอกร้าน (ตลาด/แผนที่) — รอแล้วค่อยขึ้น
## [9 พ.ย.] แก้บั๊ก: ป้าย "วันนี้มีลูกค้า n คน" ขึ้นทับเมนูหลักตอนเปิดเกม
func _blocked() -> bool:
	if Global.on_start or Global.in_minigame:
		return true
	var pm := get_node_or_null(^"/root/PauseMenu") as CanvasItem
	if pm and pm.visible:
		return true
	var tree_scene := get_tree().current_scene
	if tree_scene and tree_scene.is_in_group(&"main_menu") and tree_scene.visible:
		return true
	var loop := get_node_or_null(^"/root/DayLoop")
	if loop and loop.has_method(&"_loop_active") and loop.has_method(&"_in_shop"):
		if not loop.call(&"_loop_active") or not loop.call(&"_in_shop"):
			return true
	var sr := get_node_or_null(^"/root/SceneRouter")
	if sr and sr.get("overlay_stack") is CanvasLayer and (sr.get("overlay_stack") as CanvasLayer).get_child_count() > 0:
		return true # มินิเกม/หน้าต่างซ้อนเปิดอยู่
	var dlg := get_node_or_null(^"/root/DialogScene") as CanvasItem
	if dlg and dlg.visible:
		return true
	var dl := get_node_or_null(^"/root/DayLoop")
	if dl and bool(dl.get("_skipping")):
		return true
	return false
