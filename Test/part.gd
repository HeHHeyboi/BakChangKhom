class_name Part extends Sprite2D

@onready var _area = $Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# ให้ Area2D ที่อยู่บนสุดได้รับ input_event เพียงตัวเดียว
	var vp := get_viewport()
	vp.physics_object_picking_sort = true
	vp.physics_object_picking_first_only = true


var hold = false
var current_place: Node2D = null


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# เริ่มลากได้เฉพาะตอนกดบน area เท่านั้น
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		hold = true
		get_parent().move_child(self, -1)
		if current_place:
			current_place.release(self)
			current_place = null


# ติดตามการเลื่อนและการปล่อยเมาส์ทั่วทั้งหน้าจอ เพื่อไม่ให้หลุดเมื่อเมาส์เร็วกว่า sprite
func _input(event: InputEvent) -> void:
	if not hold:
		return
	if event is InputEventMouseMotion:
		self.global_position = get_global_mouse_position()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		hold = false
		_drop()


# ปล่อย part: ถ้าทับช่อง place ที่ว่างอยู่ ให้ snap เข้าไป
func _drop() -> void:
	for area in _area.get_overlapping_areas():
		var place: Node = area.get_parent()
		if place.is_in_group("place") and place.try_place(self):
			current_place = place
			return


func _on_area_2d_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_area_2d_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
