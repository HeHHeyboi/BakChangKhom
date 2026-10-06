class_name ToolDef extends Resource
enum Action {
	SCREW = 1 << 0,
	PRY = 1 << 1,
	BLOW = 1 << 2,
	BRUSH = 1 << 3,
	SCRUB = 1 << 4,
	WIPE = 1 << 5,
	MEASURE = 1 << 6,
	APPLY = 1 << 7,
	CUT = 1 << 8,
	GRIP = 1 << 9,
}
@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var action: Action = Action.SCREW
@export var uses := -1 # −1 = ไม่จำกัด · ของสิ้นเปลืองใส่จำนวน
@export var time_minutes := 5 # เวลาในเกมที่ใช้ต่อครั้ง (ข้อ 2.1)
@export var qte: QteSpec # ว่าง = ใช้แล้วสำเร็จเลย
@export var price := 0 # ร้านค้า (ข้อ 10.2)
@export var unlock_rank := 0
