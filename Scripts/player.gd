class_name Player extends CharacterBody2D

const speed = 300

@onready var sprite = $"Idle"
var Dir = Vector2(0, 0)
var isDialogShow = false

# TODO: เมื่อเข้า Dialog อาจจะต้อง Disable Player Input ทั้งหมด
# อาจจะต้องใช้ Signal หรือ GameManager


func _physics_process(_delta: float) -> void:
	if isDialogShow:
		return

	Dir = Vector2.ZERO
	if Input.is_action_pressed("up", true):
		Dir.y -= 1
	elif Input.is_action_pressed("down", true):
		Dir.y += 1
	elif Input.is_action_pressed("left", true):
		Dir.x -= 1
	elif Input.is_action_pressed("right", true):
		Dir.x += 1

	print(bool(-1))
	if Dir.x < 0:
		sprite.flip_h = true
	elif Dir.x > 0:
		sprite.flip_h = false

	var Vspeed = Dir.normalized() * speed
	# Vspeed *= abs(Vspeed.normalized())

	self.velocity = Vspeed
	move_and_slide()
