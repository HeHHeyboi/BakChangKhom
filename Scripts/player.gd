extends CharacterBody2D

const speed = 300

var Dir = Vector2(0, 0)

func _physics_process(_delta: float) -> void:
	Dir = Vector2.ZERO
	if Input.is_action_pressed("up",true):
		Dir.y -=1
	elif Input.is_action_pressed("down",true):
		Dir.y += 1
	elif Input.is_action_pressed("left",true):
		Dir.x -= 1
	elif Input.is_action_pressed("right",true):
		Dir.x += 1

	var Vspeed = Dir.normalized() * speed 
	# Vspeed *= abs(Vspeed.normalized())

	self.velocity = Vspeed
	move_and_slide()
