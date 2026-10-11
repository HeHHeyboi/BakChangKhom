extends Node
signal next_period
signal next_day

signal sendUpdatedEvent(EventID, Event)
signal showDialogEvent(arg1: StringName, arg2: String, arg3: Array)

enum EventID {
	NONE,
	MAIN,
}

@export var eventMap: Dictionary[EventID, Event]
@onready var questboard = $"QuestBoard" as QuestBoard
@onready var time_system = $"TimeSystem" as TimeSystem
@onready var tutorial = $"Tutorial" as Tutorial
## ป้ายเงินบน HUD (อยู่ในแผงของ TimeSystem แต่ EventManager เป็นคนอัปเดต)
@export var money_label: Label
## แถวชื่อยศ · แถบ XP · ตัวเลข XP (RankPanel/Box) และป้ายเลื่อนขั้น (RankUp) บน HUD — เช่นกัน
@export var rank_box: Control
@export var rank_up_panel: Control
var currentEvent: EventID
var pendingTask: int = -1
## true ระหว่างเล่นบทที่ไม่ใช่ขั้นของเควสต์ (บท Chapter ท้ายรอบ · Epilogue) — จบแล้วไม่ไปเดินเควสต์หลัก
var _story_dialog := false

signal on_tutorial_finish
signal on_minigame_end
signal on_dialog_end


func _ready() -> void:
	var root_tree = get_tree().root.get_tree()
	root_tree.node_added.connect(self._on_node_added)
	DialogScene.on_dialog_finish.connect(self._on_dialog_finish)
	_bind_game_state.call_deferred() # GameState เป็น autoload ที่โหลดหลัง EventManager
	if eventMap.size() <= 0:
		return
	currentEvent = EventID.MAIN
	var event = eventMap[currentEvent]
	event.reset()
	event.isActive = true
	questboard.update_task(event.get_task().quest_text_th, event)
	sendUpdatedEvent.emit(currentEvent, event)
	tutorial.on_tutorial_end.connect(_on_tutorial_end)


func _bind_game_state() -> void:
	if not GameState.money_changed.is_connected(_on_money_changed):
		GameState.money_changed.connect(_on_money_changed)
	if not GameState.rank_up.is_connected(_on_rank_up):
		GameState.rank_up.connect(_on_rank_up)
	_on_money_changed(GameState.money, 0)

# ---------------------------------------------------------------- เงิน (HUD)


func _on_money_changed(money: int, _delta: int) -> void:
	if money_label == null:
		return
	var value := str(money)
	if absi(money) >= 1000:
		value = "%.1fk" % (money / 1000.0)
	money_label.text = "฿ %s" % value


# ---------------------------------------------------------------- ยศช่าง (HUD) [ย้ายมาจาก TimeSystem]
var _shown_xp := -1


## xp ถูกตั้งตรง ๆ ตอน reset/โหลดเซฟ (ไม่ยิง xp_changed) เลยต้องเช็กทุกเฟรม
func _process(_delta: float) -> void:
	if GameState.xp == _shown_xp:
		return
	_shown_xp = GameState.xp
	update_rank()


## แถบยศใต้ป้ายเวลา: ชื่อยศ · แถบ XP · "120/500 XP"
func update_rank() -> void:
	if rank_box == null:
		return
	(rank_box.get_node(^"Rank") as Label).text = GameState.rank_name()
	(rank_box.get_node(^"Bar") as ProgressBar).value = GameState.rank_progress()
	var nxt := GameState.xp_next()
	(rank_box.get_node(^"Xp") as Label).text = (
		("%d/%d XP" % [GameState.xp, nxt])
		if nxt > 0
		else ("%d XP · ยศสูงสุด" % GameState.xp)
	)


func _on_rank_up(_rank: int, rank_name: String) -> void:
	if rank_up_panel == null:
		return
	(rank_up_panel.get_node(^"Text") as Label).text = "เลื่อนขั้น!  ขมเป็น \"%s\" แล้ว" % rank_name
	rank_up_panel.show()
	rank_up_panel.modulate.a = 0.0
	Audio.sfx(&"success")
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # ป้ายต้องจางหายแม้เปิดเมนูพัก (เดิมอยู่ใน TimeSystem ที่ process_mode=ALWAYS)
	tw.tween_property(rank_up_panel, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.6)
	tw.tween_property(rank_up_panel, "modulate:a", 0.0, 0.4)
	tw.tween_callback(rank_up_panel.hide)


func _on_node_added(node: Node) -> void:
	if node is CautionMarker:
		sendUpdatedEvent.emit(currentEvent, self.eventMap[currentEvent])
		if not node.caution_press.is_connected(trigger_step):
			node.caution_press.connect(trigger_step)


func init_manager() -> void:
	currentEvent = EventID.MAIN
	var event = eventMap[currentEvent]
	questboard.update_task(event.get_task().quest_text_th, event)
	sendUpdatedEvent.emit(EventID.MAIN, event)


func update_event(id: EventID) -> QuestStep:
	var event = eventMap[id]
	if event == null:
		return

	var quest_step = event.next_step()
	if event.isDone:
		sendUpdatedEvent.emit(id, null)
		return null
	else:
		sendUpdatedEvent.emit(id, event)

	questboard.update_task(quest_step.quest_text_th, event)
	return quest_step


# Jumps an event straight to a task index (used by the debug menu).
func jump_event(id: EventID, task_index: int) -> void:
	var event = eventMap[id]
	if event == null:
		return
	currentEvent = id
	var quest_step = event.set_step(task_index)
	questboard.update_task(quest_step.quest_text_th, event)
	questboard.show()
	time_system.show()

	sendUpdatedEvent.emit(id, event)


func show_dialog(title: String, file_path: StringName, bg_name: String, chars: Array = []):
	showDialogEvent.emit(file_path, bg_name, chars)
	DialogScene.set_title(title)


# Per-step reaction table: what happens when a quest step's caution marker is
# pressed. Called directly by CautionMarker.caution_press connections, and by
# any node that gates a press on its own marker's visibility (e.g. grandma.gd).
func trigger_step(id: EventID, event: Event) -> void:
	if event == null:
		return
	var data = event.get_task()
	if data == null:
		questboard.update_task("", event)
		return
	elif data.emitType == QuestStep.EmitType.TRIGGER:
		_process_data(id, data)


func _on_dialog_finish() -> void:
	showUI()
	if _story_dialog:
		_story_dialog = false
		return
	on_dialog_end.emit()
	var event = eventMap[currentEvent]
	if event == null:
		return
	var id = currentEvent
	var data = event.get_task()
	if data == null:
		return
	if data.isDone && data.action == QuestStep.Action.DIALOG:
		data = update_event(id)
		if data == null:
			questboard.update_task("", event)
			return
	if data.emitType == QuestStep.EmitType.DIALOG_END:
		_process_data(id, data)


func _on_tutorial_end():
	on_tutorial_finish.emit()
	showUI()
	var event = eventMap[currentEvent]
	if event == null:
		return
	var id = currentEvent
	var data = event.get_task()
	if data == null:
		return
	if data.isDone && data.action == QuestStep.Action.TUTORIAL:
		data = update_event(id)
		if data == null:
			questboard.update_task("", event)
			return
	if data.emitType == QuestStep.EmitType.TUTORIAL_END:
		_process_data(id, data)


func minigame_end() -> void:
	showUI()
	SceneRouter.pop()
	on_minigame_end.emit()
	var event = eventMap[currentEvent]
	if event == null:
		return
	var id = currentEvent
	var data = event.get_task()
	if data == null:
		return
	if data.isDone && (data.action == QuestStep.Action.MINIGAME || data.action == QuestStep.Action.SCENE_CHANGE):
		data = update_event(id)
		if data == null:
			questboard.update_task("", event)
			return
	if data.emitType == QuestStep.EmitType.MINIGAME_END:
		_process_data(id, data)


func _process_data(id: EventID, data: QuestStep):
	if data == null || id == EventID.NONE:
		return

	_hud_state(data.showHUD)
	match data.action:
		QuestStep.Action.DIALOG:
			DialogScene.show_dialog(data.dialog_file, data.bg_name, data.chars)
			DialogScene.set_title(data.title)
			if !on_dialog_end.is_connected(data.set_done):
				on_dialog_end.connect(data.set_done, CONNECT_ONE_SHOT)
		QuestStep.Action.MINIGAME, QuestStep.Action.SCENE_CHANGE:
			SceneRouter.push(data.scene_path)
			Global.in_minigame = true
			if !on_minigame_end.is_connected(data.set_done):
				on_minigame_end.connect(data.set_done, CONNECT_ONE_SHOT)
		QuestStep.Action.TUTORIAL:
			tutorial.show_tutorial(data.tutorial)
			if !on_tutorial_finish.is_connected(data.set_done):
				on_tutorial_finish.connect(data.set_done, CONNECT_ONE_SHOT)


## เปิดบทพูดนอกเควสต์ (บท Chapter ประจำรอบ · Epilogue) — เรียกจาก GameState ตอนครบ 7 วัน
## คืน false ถ้าเปิดไม่ได้ (ไฟล์หาย/บทว่าง/มีบทอื่นเปิดอยู่) — ผู้เรียกต้องไปต่อเอง ไม่งั้นรอ on_dialog_finish ค้าง
func play_story_dialog(title: String, file_path: String, bg_name: String, chars: Array = []) -> bool:
	if not DialogUtil.has_lines(file_path):
		push_warning("play_story_dialog: ไม่พบบท หรือบทว่าง %s" % file_path)
		return false
	if DialogScene.visible:
		push_warning("play_story_dialog: มีบทอื่นเปิดอยู่ ข้าม %s" % file_path)
		return false
	if bg_name != "" and not ResourceLoader.exists(bg_name):
		push_warning("play_story_dialog: ไม่พบฉากหลัง %s" % bg_name)
		bg_name = ""
	_story_dialog = true
	hideUI()
	DialogScene.show_dialog(file_path, bg_name, chars)
	DialogScene.set_title(title)
	return true


## จบช่วงเวลาปัจจุบัน (เช้า → เที่ยง → เย็น → วันใหม่)
func advance_period() -> void:
	next_period.emit()


## นอน → วันถัดไป (ครบ 7 วัน TimeSystem จะยิง week_ended)
func end_day() -> void:
	next_day.emit()


func _hud_state(state: bool):
	questboard.visible = state
	time_system.visible = state


func hideUI():
	_hud_state(false)


func showUI():
	_hud_state(true)


const TutorialState = Tutorial.TutorialState


func show_tutorial(index: TutorialState) -> void:
	tutorial.show_tutorial(index)


## [Claude 10 ต.ค. 2569] จบเควสต์ทั้งเส้น (ทุกขั้นนับว่าเสร็จ) — ใช้ตอนโหลดเซฟ / Debug · ลูปร้านเริ่มทำงาน
func finish_event(id: EventID) -> void:
	var event = eventMap.get(id)
	if event == null:
		return
	currentEvent = id
	if event.totalTask > 0:
		event.set_step(event.totalTask - 1)
		event._tasks[event.totalTask - 1].set_done()
	event.currentTask = event.totalTask
	event.isDone = true
	questboard.update_task("", event)
	questboard.show()
	time_system.show()
	sendUpdatedEvent.emit(id, event)


## [Claude 10 ต.ค. 2569] ทำขั้น index ให้เสร็จ (รวมขั้นก่อนหน้า) แล้วไปขั้นถัดไป · ขั้นสุดท้าย = จบเควสต์
func complete_step(id: EventID, index: int) -> void:
	var event = eventMap.get(id)
	if event == null:
		return
	if index + 1 >= event.totalTask:
		finish_event(id)
	else:
		jump_event(id, index + 1)


func get_clock_text() -> String:
	return TimeSystem.clock_text(time_system.current_minute)
