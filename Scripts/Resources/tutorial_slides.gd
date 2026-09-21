class_name TutorialSlides extends Resource
@export var ImageSlide: Array[Texture2D] = []:
	set(value):
		_slides = value
		totalSlide = value.size()

var totalSlide = 0
var _slides = []
var curIndex = 0


## รีเซ็ตกลับไปสไลด์แรก — ต้องเรียกทุกครั้งที่เปิด tutorial ใหม่
## เพราะ TutorialSlides เป็น Resource ที่แชร์กันทั้งเกม curIndex จึงค้างข้ามรอบ
func reset() -> void:
	curIndex = 0


func get_cur_slide() -> Texture2D:
	if _slides.is_empty():
		return null
	return _slides[curIndex]


func get_next_slide() -> Texture2D:
	if curIndex >= totalSlide - 1:
		curIndex = totalSlide - 1
		return null

	curIndex += 1
	return _slides.get(curIndex)


func get_prev_slide() -> Texture2D:
	if curIndex <= 0:
		curIndex = 0
		return null
	curIndex -= 1
	return _slides.get(curIndex)


func is_finish() -> bool:
	return curIndex >= totalSlide - 1
