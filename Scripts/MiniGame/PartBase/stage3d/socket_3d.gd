@tool
class_name Socket3D extends Node3D
## จุดติดตั้งชิ้นส่วน — ตำแหน่ง node = จุดที่ "ก้น" ของชิ้นส่วนวางลง
## วางเป็น node ในซีน: ตั้ง Socket Type · Locks (สลักที่ต้องเปิดก่อน) · Start Occupant (ชิ้นที่เสียบอยู่ตั้งแต่เริ่ม)
## ใน Editor จะเห็นกล่องสีฟ้าจาง ๆ บอกตำแหน่ง · ตอนเล่นจะเรืองเขียว/แดงเมื่อลากชิ้นเข้าใกล้
## ตรวจตามกฎ TUTORIAL_ASSEMBLY_DESIGN.md ข้อ 4

enum Result { OK, WRONG_SOCKET, WRONG_ORDER, WRONG_ORIENTATION, OCCUPIED, LOCKED }

@export var socket_type: StringName
@export var accept_any := false ## ถาดพักชิ้นส่วน: รับทุกชิ้น
@export var required_yaw := -1.0 ## < 0 = ไม่สนทิศ
@export var hint_size := Vector3(0.03, 0.32, 1.34):
	set(v):
		hint_size = v
		_update_hint_mesh()
@export var locks: Array[PartBody3D] = [] ## ชิ้น TOGGLE ที่ต้อง "เปิด" ก่อนถอด/ใส่
@export var start_occupant: PartBody3D ## ชิ้นที่ติดตั้งอยู่ตั้งแต่เริ่มฉาก

var occupant: PartBody3D
var _hl: MeshInstance3D


func _ready() -> void:
	_hl = MeshInstance3D.new()
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.3, 0.6, 1, 0.25)
	_hl.material_override = m
	add_child(_hl)
	_update_hint_mesh()
	_hl.visible = Engine.is_editor_hint()


func _update_hint_mesh() -> void:
	if _hl == null:
		return
	var b := BoxMesh.new()
	b.size = hint_size
	_hl.mesh = b
	_hl.position.y = hint_size.y / 2


func is_locked() -> bool:
	for l in locks:
		if l and not l.toggle_on:
			return true
	return false


func check(part: PartBody3D, installed_ids: Array) -> Result:
	if occupant and occupant != part:
		return Result.OCCUPIED
	if not accept_any and part.data.socket_type != socket_type:
		return Result.WRONG_SOCKET
	if not accept_any:
		for r in part.data.requires:
			if not installed_ids.has(r):
				return Result.WRONG_ORDER
		if required_yaw >= 0.0 and part.data.needs_orientation \
				and not is_equal_approx(fposmod(part.yaw_deg - rotation_degrees.y, 360.0), fposmod(required_yaw, 360.0)):
			return Result.WRONG_ORIENTATION
	if is_locked():
		return Result.LOCKED
	return Result.OK


## 0 = ปิด · 1 = เขียว (ใส่ได้) · 2 = แดง (ผิด)
func highlight(state: int) -> void:
	_hl.visible = state != 0
	if state != 0:
		_hl.material_override.albedo_color = Color(0.3, 1, 0.4, 0.35) if state == 1 else Color(1, 0.3, 0.3, 0.35)
