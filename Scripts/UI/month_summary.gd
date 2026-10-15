class_name MonthSummary
extends Control
## [0.2.0-E] หน้าสรุปสิ้นเดือน (Scene/UI/month_summary.tscn ใน DayLoop/SummaryLayer)
## ตารางรายรับ | รายจ่าย (บิลแตกย่อย) · ลงทุน · กำไรเทียบเป้า · พลาดเป้า/ค้างบิล · ปิ๊บบอกสาเหตุ
## โครง/สี/ขนาดอยู่ใน .tscn — สคริปต์แค่เติมแถวในตาราง

signal continue_pressed

@export_group("แถวในตาราง")
@export var row_font := 15
@export var sub_font := 12
@export var text_color := Color(0.25, 0.17, 0.1)
@export var sub_color := Color(0.45, 0.38, 0.3)
@export var empty_text := "—"
@export_group("ผล")
@export var good_color := Color(0.18, 0.55, 0.25)
@export var warn_color := Color(0.85, 0.5, 0.1)
@export var bad_color := Color(0.75, 0.2, 0.15)
@export var mark_on := "●"
@export var mark_off := "○"

const INCOME_KINDS := [&"fee", &"tip", &"sell", &"other"]
const EXPENSE_KINDS := [&"bill", &"buy", &"ot_power", &"damage", &"other"]

@onready var _title: Label = %Title
@onready var _sub: Label = %Sub
@onready var _income_grid: GridContainer = %IncomeGrid
@onready var _expense_grid: GridContainer = %ExpenseGrid
@onready var _income_total: Label = %IncomeTotal
@onready var _expense_total: Label = %ExpenseTotal
@onready var _invest: Label = %Invest
@onready var _profit: Label = %Profit
@onready var _result: Label = %Result
@onready var _bar: ProgressBar = %ProfitBar
@onready var _target: Label = %Target
@onready var _strikes: Label = %Strikes
@onready var _hint: Label = %Hint
@onready var _continue: Button = %Continue


func _ready() -> void:
	visible = false
	_continue.pressed.connect(func() -> void: continue_pressed.emit())


## rep = GameState.month_report/close_month · bill = GameState.pay_month_bill
func show_report(title: String, sub: String, rep: Dictionary, bill: Dictionary, button_text: String) -> void:
	var econ: EconomyConfig = GameState.economy if GameState.economy else EconomyConfig.new()
	var by: Dictionary = rep.get("by_kind", { })
	_title.text = title
	_sub.text = sub
	_sub.visible = sub != ""
	# รายรับ
	_clear(_income_grid)
	for k in INCOME_KINDS:
		if int(by.get(k, 0)) > 0:
			_row(_income_grid, GameState.MONEY_KINDS[k], int(by[k]))
	if _income_grid.get_child_count() == 0:
		_row(_income_grid, empty_text, 0, true)
	_income_total.text = _baht(int(rep.get("income", 0)))
	# รายจ่าย (บิลแตกเป็นแถวย่อย)
	_clear(_expense_grid)
	for k in EXPENSE_KINDS:
		var is_bill: bool = k == &"bill" and not bill.is_empty()
		if int(by.get(k, 0)) >= 0 and not is_bill:
			continue
		# บิลแสดงเสมอ (แม้จ่ายได้ ฿0) พร้อมรายการย่อย + ยอดที่ยังค้าง
		_row(_expense_grid, ("บิลรายเดือน (จ่ายแล้ว)" if is_bill else GameState.MONEY_KINDS[k]), -int(by.get(k, 0)))
		if is_bill:
			for part in [["ค่าเช่าที่", "rent"], ["ค่าไฟ", "power"], ["ค่าน้ำ", "water"], ["ค่าเน็ต", "internet"], ["ยอดค้างเดิม", "prev_debt"], ["ค่าปรับค้างชำระ", "late_fee"]]:
				if int(bill.get(part[1], 0)) > 0:
					_row(_expense_grid, "   " + part[0], int(bill[part[1]]), true)
			if int(bill.get("debt", 0)) > 0:
				_row(_expense_grid, "   ยังค้างจ่าย (ยกไปเดือนหน้า)", int(bill.debt), true, bad_color)
	if _expense_grid.get_child_count() == 0:
		_row(_expense_grid, empty_text, 0, true)
	_expense_total.text = _baht(int(rep.get("expense", 0)))
	var inv := int(rep.get("invest", 0))
	_invest.visible = inv > 0
	_invest.text = "ลงทุนกับร้าน %s (ไม่นับในกำไร)" % _baht(inv)
	# กำไรเทียบเป้า
	var profit := int(rep.get("profit", 0))
	var target := maxi(int(rep.get("target", 1)), 1)
	_profit.text = _baht(profit)
	_target.text = "เป้า %s" % _baht(target)
	_bar.max_value = target
	_bar.value = clampi(profit, 0, target)
	var col := bad_color
	if bool(rep.get("over", false)):
		_result.text = "เกินเป้า!"
		col = good_color
	elif bool(rep.get("reached", false)):
		_result.text = "ถึงเป้าแล้ว!"
		col = good_color
	elif not bool(rep.get("counted", true)):
		_result.text = "ยังไม่ถึงเป้า (เดือนแรกไม่นับ)"
		col = warn_color
	else:
		_result.text = "ไม่ถึงเป้า"
	if bool(rep.get("shop_closed", false)):
		_result.text = "ร้านไปต่อไม่ไหวแล้ว…"
		col = bad_color
	_result.add_theme_color_override("font_color", col)
	_profit.add_theme_color_override("font_color", col if profit < target else good_color)
	var fill := _bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	if fill:
		fill.bg_color = col
		_bar.add_theme_stylebox_override("fill", fill)
	var debt := int(rep.get("debt", 0))
	_strikes.text = "พลาดเป้า %s%s" % [
		_marks(int(rep.get("missed_months", 0)), econ.fail_missed_months),
		("  ·  ค้างบิล %s %s" % [_baht(debt), _marks(int(rep.get("debt_streak", 0)), econ.fail_debt_months)]) if debt > 0 else "",
	]
	_hint.text = String(rep.get("hint", ""))
	_continue.text = button_text
	visible = true


func _row(grid: GridContainer, label: String, amount: int, small := false, color := Color(0, 0, 0, 0)) -> void:
	var l := Label.new()
	l.text = label
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var a := Label.new()
	a.text = _baht(amount) if label != empty_text else ""
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for n: Label in [l, a]:
		n.add_theme_font_size_override("font_size", sub_font if small else row_font)
		n.add_theme_color_override("font_color", color if color.a > 0 else (sub_color if small else text_color))
		grid.add_child(n)


func _clear(grid: GridContainer) -> void:
	for c in grid.get_children():
		grid.remove_child(c)
		c.queue_free()


func _marks(n: int, of: int) -> String:
	return mark_on.repeat(clampi(n, 0, of)) + mark_off.repeat(maxi(of - n, 0))


static func _baht(n: int) -> String:
	return MonthGoalBar._baht(n)
