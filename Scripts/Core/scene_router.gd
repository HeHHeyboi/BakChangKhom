extends Node

enum LocationID {
	HOME,
	ROOM,
	WORKSHOP,
	WORKBENCH,
	MARKET,
}
const HOME = LocationID.HOME
const ROOM = LocationID.ROOM
const WORKSHOP = LocationID.WORKSHOP
const WORKBENCH = LocationID.WORKBENCH
const MARKET = LocationID.MARKET

signal location_changed(id: LocationID)
signal overlay_closed(scene_path: String, result: Variant)

const LOCATIONS := {
	HOME: "res://Scene/Location/Home.tscn",
	ROOM: "res://Scene/Location/Room.tscn",
	WORKSHOP: "res://Scene/Location/Workshop.tscn",
	WORKBENCH: "res://Scene/Location/Workbench.tscn",
	MARKET: "res://Scene/Location/Market.tscn",
}

var overlay_stack: CanvasLayer
var location_slot: CanvasLayer
var current_id = -1
var _stack: Array[Node] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	overlay_stack = CanvasLayer.new()
	overlay_stack.layer = 10
	overlay_stack.name = "overlay"
	location_slot = CanvasLayer.new()
	location_slot.name = "location_slot"
	location_slot.layer = 0
	var root = self.get_tree().root
	root.add_child.call_deferred(overlay_stack)
	root.add_child.call_deferred(location_slot)


func go(id: LocationID) -> void:
	while not _stack.is_empty():
		pop(null)
	await Fade.fade_out()
	for c in location_slot.get_children():
		location_slot.remove_child(c)
		c.queue_free()

	if !ResourceLoader.exists(LOCATIONS[id]):
		return
	location_slot.add_child(load(LOCATIONS[id]).instantiate())
	current_id = id
	location_changed.emit(id)
	await Fade.fade_in()


## ล้างทุกอย่างกลับไปก่อนเข้าเกม (ใช้ตอนกลับหน้าแรก) — ไม่มี fade
func clear() -> void:
	while not _stack.is_empty():
		pop(null)
	for c in location_slot.get_children():
		location_slot.remove_child(c)
		c.queue_free()
	current_id = -1


func push(path: String, ctx: Variant = null) -> Node:
	if !ResourceLoader.exists(path):
		return null
	var n: Node = load(path).instantiate()
	n.set_meta("ctx", ctx)
	return await push_node(n)


## วางโหนดที่สร้างเองเป็น overlay (มีจอดำ fade เหมือน push) · ตั้ง meta ให้เสร็จก่อนเรียก (_ready ของโหนดอ่านได้)
## ใช้โดย DayLoop.start_repair (meta work_order) · DebugMenu._open_minigame (meta standalone)
## [Claude 8 ต.ค. 2569] คืนฟังก์ชันนี้ — commit b6cf245 รวมเข้า push() แต่ยังมีที่เรียกอยู่ 2 ที่
func push_node(n: Node) -> Node:
	if n == null:
		return null
	await Fade.fade_out()
	if _stack.is_empty():
		_set_location_paused(true)
	else:
		_stack.back().process_mode = Node.PROCESS_MODE_DISABLED
	_stack.append(n)
	overlay_stack.add_child(n)
	await Fade.fade_in()
	return n


func pop(result: Variant = null) -> void:
	if _stack.is_empty():
		return
	var n: Node = _stack.pop_back()
	var path := n.scene_file_path
	n.queue_free()
	if _stack.is_empty():
		_set_location_paused(false)
	else:
		_stack.back().process_mode = Node.PROCESS_MODE_INHERIT
	overlay_closed.emit(path, result)


func _set_location_paused(on: bool) -> void:
	for c in location_slot.get_children():
		c.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT
