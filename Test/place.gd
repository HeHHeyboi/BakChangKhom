class_name Place extends Node2D

# Called when the node enters the scene tree for the first time.
var occupant: Node2D = null
enum PlaceType {
	NONE,
	RAM,
	GPU,
	CPU,
}
@export var place_type: PlaceType = PlaceType.NONE


func _ready() -> void:
	add_to_group("place")


# วาง part ลงช่องนี้ ถ้าช่องว่างอยู่ (หรือเป็น part ตัวเดิม)
func try_place(part: Node2D, type: PlaceType) -> bool:
	# if (occupant != null && occupant != part):
	if (occupant != null && occupant != part || type != place_type):
		return false
	occupant = part
	part.global_position = self.global_position
	return true


func release(part: Node2D) -> void:
	if occupant == part:
		occupant = null


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	pass # Replace with function body.


func _on_area_2d_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	pass # Replace with function body.
