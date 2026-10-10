@tool
extends SceneHotspot
## คอมของขมบนโต๊ะร้าน — กดแล้วเปิดขมOS แบบเล่นอิสระ (ไม่มีลูกค้า ไม่คิดคะแนน/เงิน)
## ไฟล์/โปรแกรมในเครื่องแก้ได้ที่ Resources/Desktop/Free/khom_pc.tres · [Claude 9 ต.ค. 2569]

const DESKTOP_SCENE := "res://Scene/MiniGame/Desktop/desktop_window.tscn"
## ข้อมูลเครื่อง (DesktopTask)
@export var task: DesktopTask = preload("res://Resources/Desktop/Free/khom_pc.tres")


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		pressed.connect(open_pc)


## เปิดขมOS · คืน null ถ้าเปิดไม่ได้ (กำลังมีบท/มินิเกม)
func open_pc() -> Node:
	if Global.isDialogShown() or Global.isInMinigame():
		return null
	var ps := load(DESKTOP_SCENE) as PackedScene
	if ps == null or task == null:
		push_error("shop_pc: เปิดขมOS ไม่ได้ (%s)" % DESKTOP_SCENE)
		return null
	var m := ps.instantiate()
	m.set("task", task)
	m.set("free_mode", true)
	Global.in_minigame = true
	SceneRouter.push_node(m)
	return m
