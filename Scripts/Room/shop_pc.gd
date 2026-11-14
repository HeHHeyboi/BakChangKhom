@tool
extends SceneHotspot
## คอมของขมบนโต๊ะร้าน — กดแล้วเปิดขมOS แบบเล่นอิสระ (ไม่มีลูกค้า ไม่คิดคะแนน/เงิน)
## ไฟล์/โปรแกรมในเครื่องแก้ได้ที่ Resources/Desktop/Free/khom_pc.tres · [Claude 9 ต.ค. 2569]
## [15 พ.ย. 2569 · 0.3.0] ย้ายไปขมOS ชุดใหม่ (desktop_window2 · DesktopMinigameV2) + แอป "งานซ่อม" (ตารางใบรับเครื่อง)

const DESKTOP_SCENE := "res://Scene/MiniGame/Desktop/desktop_window2.tscn"
const WORK_APP_SCENE := preload("res://Scene/UI/work_order_app.tscn")
const WORK_APP_NAME := "งานซ่อม"
## กว้างไม่ทับโน้ตงานมุมขวาบนของขมOS
const WORK_APP_SIZE := Vector2(470, 440)
## เปิดชิดซ้ายบน ถัดจากไอคอนเดสก์ท็อป
const WORK_APP_POS := Vector2(205, 24)
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
	if m.has_method(&"add_custom_app"):
		m.ready.connect(func() -> void: m.add_custom_app(WORK_APP_NAME, Icons.tex(&"clipboard"), WORK_APP_SCENE, WORK_APP_SIZE, WORK_APP_POS), CONNECT_ONE_SHOT)
	Global.in_minigame = true
	SceneRouter.push_node(m)
	return m
