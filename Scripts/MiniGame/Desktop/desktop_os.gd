class_name DesktopOS extends RefCounted

enum WinType {
	Explorer,
}


class Dir extends RefCounted:
	var dname: String
	var files: PackedInt32Array


	func _init(name: String):
		self.dname = name


## ไฟล์ตอนเล่น — data คือ DesktopFile ต้นฉบับ (Resource ใช้ร่วมกัน ห้ามแก้) ส่วนค่าที่เปลี่ยนตอนเล่นเก็บที่ File เช่น dir
class File extends RefCounted:
	var data: DesktopFile
	var dir: String


	func _init(src: DesktopFile):
		data = src
		dir = src.folder_name()


## ชื่อโฟลเดอร์ถังขยะ — ลบไฟล์ = ย้ายมาที่นี่
const TRASH := "ถังขยะ"

var fs: Array[File] = []
var dir_map: Dictionary[String, Dir] = { }
var instances: Array[OsWindow2] = []


func _init():
	create_dir(TRASH)


func create_dir(dir_name: String) -> void:
	var d = Dir.new(dir_name)
	if !dir_map.has(d.dname):
		dir_map.set(d.dname, d)


func add_file(src: DesktopFile) -> int:
	var file := File.new(src)
	var dir: Dir = dir_map.get(file.dir)
	if dir == null:
		return -1
	var index := fs.size()
	dir.files.append(index)
	fs.append(file)
	return index


## ย้ายไฟล์ไปโฟลเดอร์ dest แล้วอัปเดต File.dir
## คืน false ถ้าไม่มีไฟล์/โฟลเดอร์ปลายทาง หรือไฟล์อยู่ในโฟลเดอร์นั้นอยู่แล้ว
func move_file(file_index: int, dest: String) -> bool:
	var to: Dir = dir_map.get(dest)
	if file_index < 0 or file_index >= fs.size() or to == null:
		return false
	var file := fs[file_index]
	if file.dir == dest:
		return false
	var from: Dir = dir_map.get(file.dir)
	from.files.remove_at(from.files.find(file_index))
	to.files.append(file_index)
	file.dir = dest
	return true


func add_instance(win: OsWindow2) -> void:
	instances.append(win)
