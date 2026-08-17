class_name Player extends CharacterBody2D

const speed = 300

@onready var sprite = $"Idle"
@onready var anim = $"Idle/AnimationPlayer"
@onready var idle = load(Constant.PLAYER_IDLE_SPRITESHEET)
var Dir = Vector2(0, 0)

# TODO: เมื่อเข้า Dialog อาจจะต้อง Disable Player Input ทั้งหมด
# อาจจะต้องใช้ Signal หรือ GameManager


func _process(_delta: float) -> void:
	anima_play(Dir)


func _physics_process(_delta: float) -> void:
	if Global.isDialogShown():
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

	if Dir.x < 0:
		sprite.flip_h = true
	elif Dir.x > 0:
		sprite.flip_h = false

	var Vspeed = Dir.normalized() * speed
	# Vspeed *= abs(Vspeed.normalized())

	self.velocity = Vspeed
	move_and_slide()


func anima_play(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		anim.play("Walk")
	else:
		if anim.is_playing():
			anim.stop()
			sprite.texture = idle
			sprite.hframes = 5
			sprite.vframes = 4
			sprite.region_enabled = false
