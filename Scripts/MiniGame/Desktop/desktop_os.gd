class_name DesktopOS extends RefCounted


class File extends RefCounted:
	var fname: String
	var description: String
	var fsize: int


	func _init(name: String, desc: String, size: int) -> void:
		self.fname = name
		self.description = desc
		self.fsize = size


var fs: Array[File] = []
var file_path: Dictionary[String, PackedInt32Array] = { }


func add_file(location: String, fname: String, desc: String, size: int) -> void:
	pass
