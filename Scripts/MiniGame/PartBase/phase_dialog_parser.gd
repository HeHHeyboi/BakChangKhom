class_name PhaseDialogParser extends RefCounted

## Parses phase-tagged dialog files used by MiniGame hint characters
## (e.g. Assets/Dialog/MiniGame/Ram_Pib.txt). Format:
##   @SECTION_NAME
##   CharacterName,Dialog text
##   CharacterName,Dialog text
##
##   @NEXT_SECTION
##   ...
## Sections are separated by a blank line. Lines starting with "#" are
## comments and are skipped anywhere in the file.

const COMMENT_PREFIX := "#"
const HEADER_PREFIX := "@"


## Returns a Dictionary[String, Array[DialogToken]] keyed by section name
## (without the leading "@").
static func parse(file_path: String) -> Dictionary:
	var sections: Dictionary = { }
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("PhaseDialogParser: cannot open '%s' (%s)" % [file_path, FileAccess.get_open_error()])
		return sections

	var current_section := ""
	var line_number := 0

	while not file.eof_reached():
		var raw_line := file.get_line()
		line_number += 1
		var line := raw_line.strip_edges()

		if line.is_empty():
			_close_section(sections, current_section, file_path, line_number)
			current_section = ""
			continue

		if line.begins_with(COMMENT_PREFIX):
			continue

		if line.begins_with(HEADER_PREFIX):
			_close_section(sections, current_section, file_path, line_number)
			var section_name := line.substr(1).strip_edges()
			if sections.has(section_name):
				push_warning(
					"PhaseDialogParser: '%s' line %d duplicate section '@%s', overwriting"
					% [file_path, line_number, section_name]
				)
			sections[section_name] = []
			current_section = section_name
			continue

		if current_section.is_empty():
			push_warning(
				"PhaseDialogParser: '%s' line %d text outside any section, ignored: %s" % [file_path, line_number, line]
			)
			continue

		var comma_index := line.find(",")
		if comma_index == -1:
			push_warning(
				"PhaseDialogParser: '%s' line %d missing ',' separator, ignored: %s" % [file_path, line_number, line]
			)
			continue

		sections[current_section].append(DialogToken.new(line.substr(0, comma_index), line.substr(comma_index + 1)))

	file.close()
	_close_section(sections, current_section, file_path, line_number)
	return sections


static func _close_section(sections: Dictionary, section_name: String, file_path: String, line_number: int) -> void:
	if section_name.is_empty():
		return
	if sections.has(section_name) and sections[section_name].is_empty():
		push_error(
			"PhaseDialogParser: '%s' line %d section '@%s' has no dialog lines, ignored"
			% [file_path, line_number, section_name]
		)
		sections.erase(section_name)
