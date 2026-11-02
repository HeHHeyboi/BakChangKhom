class_name DesktopOS extends RefCounted

enum WinType {
	Explorer,
	Browser,
	Settings,
	TaskManager,
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
	var prev_dir: String = ""


	func _init(src: DesktopFile):
		data = src
		dir = src.folder_name()


class App extends RefCounted:
	var data: DesktopProgram
	var icon: Texture2D


	func _init(src: DesktopProgram, app_icon: Texture2D) -> void:
		self.data = src
		self.icon = app_icon


## process ตอนเล่น — instance = หน้าต่างที่ผู้ใช้เปิด (null = process จาก DesktopTask.processes ไม่มีหน้าต่าง)
class Process extends RefCounted:
	var data: DesktopProcess
	var id: int
	var status: String
	var kind: String
	var instance: OsWindow2 = null


## เปลี่ยนทุกครั้งที่ process เกิด/จบ (ตัวจัดการงานใช้รีเฟรชรายการ)
signal process_changed


## ชื่อโฟลเดอร์ถังขยะ — ลบไฟล์ = ย้ายมาที่นี่
const TRASH := "ถังขยะ"

var fs: Array[File] = []
var dir_map: Dictionary[String, Dir] = { }
var instances: Array[OsWindow2] = []
var installed_programs: Dictionary[String, App] = { }
var process_map: Dictionary[int, Process] = { }
var disk_total_mb: int = 0
var disk_free_mb: int = 0
var current_id = 0


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
	disk_free_mb += src.size_mb
	return index


## คืนไฟล์ในโฟลเดอร์ dir · dir ว่าง = ทุกไฟล์ใน fs (รวมถังขยะ) · ไม่มีโฟลเดอร์นั้นคืน []
func list_dir(dir: String) -> Array[File]:
	if dir == "":
		return fs.duplicate()
	var result: Array[File] = []
	var d := dir_map.get(dir) as Dir
	if d == null:
		return result
	for idx in d.files:
		result.append(fs[idx])
	return result


## มีไฟล์ชื่อ fname ในโฟลเดอร์ dir ไหม · dir ว่าง = หาทุกโฟลเดอร์
func find_file(fname: String, dir: String) -> bool:
	for file in list_dir(dir):
		if file.data.name == fname:
			return true
	return false


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
	file.prev_dir = from.dname
	return true


func clear_trash() -> void:
	var trash = dir_map.get(TRASH) as Dir
	assert(trash != null, "Can't find trash dir")
	# NOTE: Dir.files เก็บ index ของ fs — ลบไฟล์แล้ว index เลื่อน จึงสร้าง fs ใหม่แล้วเติม Dir.files ใหม่ตาม File.dir
	for d in dir_map.values():
		d.files.clear()
	var kept: Array[File] = []
	for file in fs:
		if file.dir == TRASH:
			disk_free_mb += file.data.size_mb
		else:
			dir_map[file.dir].files.append(kept.size())
			kept.append(file)
	fs = kept


func add_instance(win: OsWindow2) -> void:
	instances.append(win)


func installed(program: DesktopProgram, app_icon: Texture2D = null):
	print(program.name)
	var app = App.new(program, app_icon)
	self.installed_programs.set(program.name, app)
	self.disk_free_mb -= program.size_mb


func uninstalled(name: String) -> bool:
	print(name)
	var p = self.installed_programs.get(name) as App
	if p == null:
		print("find nothing")
		return false
	self.disk_free_mb += p.data.size_mb
	self.installed_programs.erase(name)
	return true


## instance = หน้าต่างที่ผู้ใช้เปิด — ผูก pid ไว้ที่ meta "pid" ของหน้าต่าง · ปิดหน้าต่างเอง (✕) = process จบด้วย
func spawn_process(proc: DesktopProcess, instance: OsWindow2 = null) -> int:
	var id = current_id
	current_id += 1
	var p = Process.new()
	p.data = proc
	p.id = id
	p.status = "ไม่ตอบสนอง" if proc.kind == "hang" else "กำลังทำงาน"
	p.kind = "ระบบ" if proc.kind == "system" else "แอป"
	if instance != null:
		p.instance = instance
		instance.set_meta("pid", id)
		instance.closed.connect(_on_instance_closed.bind(id), CONNECT_ONE_SHOT)
	process_map.set(id, p)
	process_changed.emit()
	return id


## process ที่มีหน้าต่าง — สั่ง close() ให้หน้าต่างจัดการปิดตัวเอง (closed → _on_instance_closed ลบ process)
## process ที่ไม่มีหน้าต่าง (จาก DesktopTask) — ลบออกจาก process_map ตรง ๆ
func kill_process(proc_id: int) -> bool:
	var p := process_map.get(proc_id) as Process
	if p == null:
		return false
	if is_instance_valid(p.instance):
		p.instance.close()
	if p.data.kind == "system":
		return false
	if process_map.erase(proc_id):
		process_changed.emit()
	return true


func _on_instance_closed(proc_id: int) -> void:
	var p := process_map.get(proc_id) as Process
	if p != null and is_instance_valid(p.instance):
		p.instance.remove_meta("pid")
	if process_map.erase(proc_id):
		process_changed.emit()
