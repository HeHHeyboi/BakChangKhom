extends "res://Scripts/Market/market.gd"
## [Claude 16 พ.ย. 2569 · 0.9.5] ฉากเมือง (Scene/Location/City.tscn) — ฉากกดแบบตลาด: ออฟฟิศเก่า · ร้านอะไหล่ (MarketStall) · ร้านกาแฟ · รถตู้กลับบ้าน
## ไปได้จากแผนที่ (DayLoop.city_trip) · กฎ/เงิน/เวลาอยู่ที่ DayLoop "[0.9.5] เมือง" · บทอยู่ Assets/Dialog/City/ (CityBook)
## ฉากนี้แสดงผล + ต่อปุ่มเท่านั้น · การ์ดตั๋ว OfficeTaskCard: checked → DayLoop.city_ticket_check → พิมพ์ลงจอดำ

const OFFICE_BG := "res://Assets/Background/bg_office_new.jpg"
const CITY_BG := "res://Assets/Background/bg_city_day.jpg"

@onready var office: SceneHotspot = $Office
@onready var cafe: SceneHotspot = $Cafe
@onready var van: SceneHotspot = $Van
var card: OfficeTaskCard
var _leave_asked := false


func _ready() -> void:
	super._ready()
	office.pressed.connect(_on_office)
	cafe.pressed.connect(_on_cafe)
	van.pressed.connect(_on_van)
	_arrive.call_deferred()


## บทถึงเมือง (ครั้งเดียวต่อการไป)
func _arrive() -> void:
	var c: Dictionary = GameState.city
	if not DayLoop.city_today() or int(c.get("arrive_shift", -1)) == int(c.get("last_shift", -2)):
		return
	c["arrive_shift"] = int(c.last_shift)
	_play("เข้าเมือง", CityBook.arrive_dialog(int(c.get("visits", 1))), CITY_BG, func() -> void: say("ชี้ที่ตึกเพื่อดูว่ามีอะไร · กดรถตู้เมื่อจะกลับบ้าน"))


func _exit_tree() -> void:
	if is_instance_valid(card):
		card.queue_free()


func _busy() -> bool:
	return Global.isDialogShown() or Global.isInMinigame() or (card != null and card.visible)


func _play(title: String, file: String, bg: String, then: Callable) -> bool:
	if not EventManager.play_story_dialog(title, file, bg, DialogUtil.speakers_in(file).slice(0, 2)):
		return false
	if then.is_valid():
		DialogScene.on_dialog_finish.connect(then, CONNECT_ONE_SHOT)
	return true


# ---------------------------------------------------------------- ออฟฟิศ


func _on_office() -> void:
	if _busy():
		return
	if not DayLoop.city_today():
		say("วันนี้ไม่ได้นัดใครไว้ที่ออฟฟิศ")
		return
	if not DayLoop.city_office_can():
		say("วันนี้ลองงานกับทีมไปแล้ว พรุ่งนี้ทุกคนก็ทำงานต่อตามปกติ")
		return
	_play("ออฟฟิศเก่า", CityBook.office_dialog(), OFFICE_BG, _after_office_talk)


func _after_office_talk() -> void:
	if DialogScene.last_choice != CityBook.TRY_OFFICE:
		say("แวะทักทายทีมแล้ว ยังกลับมาลองงานได้วันนี้นะ")
		return
	start_office()


## เปิดการ์ดตั๋ว (เทสต์เรียกตรงได้)
func start_office() -> bool:
	if DayLoop.city_office_begin().is_empty():
		return false
	if card == null:
		card = OfficeTaskCard.new()
		get_tree().root.add_child(card) # ไม่ใส่ใต้ฉาก (ฉากอยู่ใน CanvasLayer ของ SceneRouter → ชั้นของการ์ดไม่ทับ HUD)
		card.checked.connect(func(i: int) -> void: card.type_out(DayLoop.city_ticket_check(i)))
		card.picked.connect(_on_ticket_picked)
		card.done.connect(_on_ticket_done)
	card.show()
	card.show_question(DayLoop.city_ticket_view())
	return true


func _on_ticket_picked(text: String) -> void:
	var r: Dictionary = DayLoop.city_ticket_answer(text)
	if not r.is_empty():
		card.show_answer(r)


func _on_ticket_done() -> void:
	if DayLoop.city_ticket_next():
		card.show_question(DayLoop.city_ticket_view())
		return
	card.hide()
	var res: Dictionary = DayLoop.city_office_finish()
	if not res.is_empty():
		_play("ออฟฟิศเก่า", CityBook.office_done_file(int(res.right), int(res.total), int(res.pay)), OFFICE_BG, Callable())


# ---------------------------------------------------------------- ร้านกาแฟ


func _on_cafe() -> void:
	if _busy():
		return
	if not DayLoop.city_cafe_can():
		say("วันนี้แวะร้านกาแฟไปแล้ว" if DayLoop.city_today() else "ร้านกาแฟคนแน่นมาก ไว้มาวันหลัง")
		return
	_play("ร้านกาแฟ", CityBook.cafe_dialog(), CITY_BG, func() -> void:
		DayLoop.city_cafe(DialogScene.last_choice)
		say("ได้คุยกับพี่แนนเรื่องทำงานออนไลน์ (ค่ากาแฟ ฿%d)" % GameState.economy.city_coffee))


# ---------------------------------------------------------------- กลับบ้าน


func _on_van() -> void:
	if _busy():
		return
	var c: Dictionary = GameState.city
	if DayLoop.city_today() and not _leave_asked and int(c.get("office_shift", -1)) != int(c.get("last_shift", -2)):
		_leave_asked = true
		say("ยังไม่ได้ไปออฟฟิศเลยนะ กดรถตู้อีกครั้งถ้าจะกลับบ้านจริง ๆ")
		return
	DayLoop.city_return()
	SceneRouter.go(SceneRouter.HOME)
