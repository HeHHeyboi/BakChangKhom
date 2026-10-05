extends Node

var weeks := []
var finished := ""

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var ts: TimeSystem = EventManager.time_system
	ts.week_ended.connect(func(w): weeks.append(w))
	GameState.game_finished.connect(func(e): finished = e)
	print("T money0=", GameState.money, " date=", ts.current_week, "/", ts.current_day, " period=", ts.cur_period)
	var r = GameState.record_repair(&"part_gpu", 96)
	print("T good: ", r, " money=", GameState.money, " period=", ts.cur_period)
	r = GameState.record_repair(&"part_mainboard", 70)
	print("T pass: money=", GameState.money, " period=", ts.cur_period)
	r = GameState.record_repair(&"part_gpu", 90, true)
	print("T fail dmg: money=", GameState.money, " period=", ts.cur_period, " avg=", GameState.average_satisfaction())
	for i in 7:
		EventManager.end_day()
	print("T after 7 days: week=", ts.current_week, " day=", ts.current_day, " weeks_ended=", weeks, " dialog_visible=", DialogScene.visible)
	print("T date label: ", ts.dateText.get_parsed_text(), " | money label: ", ts._money_label.text)
	ts.set_date(12, 7, TimeSystem.TIME.EVENING)
	EventManager.advance_period()
	print("T end: finished=", finished, " ts.finished=", ts.finished, " weeks=", weeks)
	print("T speakers ch2=", GameState.speakers_in("res://Assets/Dialog/Chapter2Rest.txt"))
	var ev: Event = EventManager.eventMap[EventManager.EventID.MAIN]
	print("T main tasks=", ev.totalTask, " last=", ev._tasks[-1].scene_path)
	for p in ["res://Scene/MiniGame/PartRam/part_ram.tscn","res://Scene/MiniGame/PartMainboard/part_mainboard.tscn","res://Scene/MiniGame/PartGpu/part_gpu.tscn","res://Scene/MiniGame/PartFrontPanel/part_front_panel.tscn","res://Scene/MiniGame/PartBios/part_bios.tscn","res://Scene/Location/Room.tscn"]:
		var ps = load(p)
		print("T load ", p.get_file(), " ok=", ps != null and ps.can_instantiate())
	var m = load("res://Scene/MiniGame/PartGpu/part_gpu.tscn").instantiate()
	add_child(m)
	await get_tree().process_frame
	print("T gpu final_score=", m.final_score(), " damaged=", m.repair_damaged())
	get_tree().quit()
