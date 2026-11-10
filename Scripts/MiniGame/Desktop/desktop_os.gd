class_name DesktopOS extends RefCounted

enum WinType {
	Explorer,
	Browser,
	Settings,
	TaskManager,
	Printer,
	Sound,
	Wifi,
	Display,
	Update,
	Security,
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
	var status: String
	var kind: String
	var autostart: bool
	var instance: OsWindow2 = null


class Printer extends RefCounted:
	var data: DesktopPrinter
	var is_install: bool

# NOTE: when sound device need to have different setting for each one
# class SoundDev extends RefCounted:
# 	var data: DesktopSoundDevice
# 	var is_mute: bool
# 	var volume: int


class Wifi extends RefCounted:
	var data: DesktopWifi
	var is_connected: bool
	var id: int


signal process_changed


## ชื่อโฟลเดอร์ถังขยะ — ลบไฟล์ = ย้ายมาที่นี่
const TRASH := "ถังขยะ"

var fs: Array[File] = []
var dir_map: Dictionary[String, Dir] = { }
var instances: Array[OsWindow2] = []
var installed_programs: Dictionary[String, App] = { }
var process_map: Dictionary[int, Process] = { }
var autostart_map: Dictionary[int, Process] = { }
var printer_map: Dictionary[int, Printer] = { }
var printer_default_index: int = -1
var sound_dev_list: Array[DesktopSoundDevice] = []
var selected_sound_dev: int = -1
var is_mute = false
var sound_volume = 0
var wifi_detected: Array[Wifi] = []
var connected_network: int = -1
var scale_list = [100, 125, 150, 175, 200]
var selected_resolution = 0
var pending_resolution = -1
var selected_scale = -1

var disk_total_mb: int = 0
var disk_free_mb: int = 0
var disk_temp_mb: int = 0
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
	var app = App.new(program, app_icon)
	self.installed_programs.set(program.name, app)
	self.disk_free_mb -= program.size_mb


func uninstalled(name: String) -> bool:
	var p = self.installed_programs.get(name) as App
	if p == null:
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
	p.status = "ไม่ตอบสนอง" if proc.kind == "hang" else "กำลังทำงาน"
	p.kind = "ระบบ" if proc.kind == "system" else "แอป"
	if instance != null:
		p.instance = instance
		instance.set_meta("pid", id)
		instance.closed.connect(_on_instance_closed.bind(id), CONNECT_ONE_SHOT)
	process_map.set(id, p)
	if proc.startup:
		p.autostart = true
		autostart_map.set(id, p)
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


func boot_time() -> int:
	var result = 0
	for pid in autostart_map:
		var p = autostart_map.get(pid) as Process
		if p == null || !p.autostart:
			continue
		result += p.data.boot_s
	return result


func add_printer(data: DesktopPrinter) -> void:
	var printer = Printer.new()
	printer.data = data
	printer.is_install = false
	var id = printer_map.size()
	printer_map.set(id, printer)


func include_printer(id: int) -> bool:
	var printer = printer_map.get(id) as Printer
	if printer == null:
		return false
	if printer_default_index < 0:
		printer_default_index = id
	printer.is_install = true
	if !printer.data.right:
		return false
	return true


func remove_printer(id: int) -> bool:
	var printer = printer_map.get(id) as Printer
	if printer == null:
		return false
	printer.is_install = false

	if printer_default_index < 0:
		return true
	if id != printer_default_index:
		return true

	printer_default_index = -1
	for index in printer_map:
		printer = printer_map.get(index) as Printer
		if printer.is_install:
			printer_default_index = id
			break
	return true


func set_default_printer(id: int) -> bool:
	if printer_default_index == id:
		return false
	printer_default_index = id
	return true


func print_test() -> String:
	if printer_default_index < 0:
		return "ยังไม่มีเครื่องพิมพ์ในเครื่องเลย"
	var p = printer_map.get(printer_default_index) as DesktopOS.Printer
	var printed_ok = p != null and p.data.right
	return "พิมพ์หน้าทดสอบที่ \"%s\" แล้ว — %s" % [
		p.data.name,
		"ออกกระดาษที่โต๊ะลูกค้า!" if printed_ok else "กระดาษไปออกที่ห้องอื่น…",
	]


func add_sound_device(dev: DesktopSoundDevice):
	sound_dev_list.append(dev)


func set_selected_sound_device(id: int) -> bool:
	if id > sound_dev_list.size():
		return false
	selected_sound_dev = id
	return true


func change_sound_volumn(value: int):
	sound_volume = value


func add_wifi(wifi: DesktopWifi):
	var w = Wifi.new()
	w.data = wifi
	w.id = wifi_detected.size()
	wifi_detected.append(w)


func wifi_connect(net: Wifi, password: String = "") -> bool:
	var prev_wifi: Wifi = null
	if connected_network >= 0:
		prev_wifi = wifi_detected[connected_network] as Wifi
	if net.data.locked:
		var ok = net.data.password.casecmp_to(password)
		if ok != 0 || password.is_empty():
			return false
	connected_network = net.id
	net.is_connected = true
	if prev_wifi != null:
		prev_wifi.is_connected = false
	return true


func wifi_disconnect():
	assert(connected_network >= 0)
	var wifi = wifi_detected[connected_network]
	wifi.is_connected = false
	connected_network = -1


func network_status() -> String:
	if connected_network < 0:
		return "ไม่ได้เชื่อมต่อ"
	return "เชื่อมต่อ: %s" % [wifi_detected[connected_network].data.name]
