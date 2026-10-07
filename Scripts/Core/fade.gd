extends CanvasLayer

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var bg: Panel = $BG


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_opacity(0)


func set_opacity(value: float) -> void:
	bg.self_modulate.a = value


func fade_in() -> void:
	if anim.is_playing():
		anim.stop()

	anim.play(&"fade_in")
	await anim.animation_finished


func fade_out() -> void:
	if anim.is_playing():
		anim.stop()

	anim.play(&"fade_out")
	await anim.animation_finished
