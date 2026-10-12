class_name DesktopOS extends RefCounted

enum WinType {
	Explorer,
}


class Dir extends RefCounted:
	var dname: String
	var files: PackedInt32Array


	func _init(name: String):
		self.dname = name


var fs: Array[DesktopFile] = []
var dir_map: Dictionary[String, Dir] = { }
var instances: Array[OsWindow] = []


func create_dir(dir_name: String) -> void:
	var d = Dir.new(dir_name)
	if !dir_map.has(d.dname):
		dir_map.set(d.dname, d)


func add_file(file: DesktopFile) -> int:
	var index = fs.size()
	var dir = dir_map[file.folder_name()]
	if dir == null:
		return -1
	dir.files.append(index)
	fs.append(file)
	return index


func add_instance(win: OsWindow) -> void:
	instances.append(win)
