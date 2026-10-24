extends Control
## SETUP WIZARD (Q10, preferred manual route): "Where do you keep your
## pictures / videos / games / anything else?" One folder picker per type.
## Each pick becomes a door in the demo building's lobby. Points at the real
## folders: nothing is copied (Q11). Runs as a flat window before VR starts.

signal finished(locations: Array)

const ROWS := [
	["pictures", "🖼  Where do you keep your pictures?"],
	["videos", "🎬  Where do you keep your videos / films?"],
	["games", "🎮  Where are your games? (shelves come after the demo)"],
	["other", "📦  Anything else you'd like as a room?"],
]

var _edits: Dictionary = {}
var _dialog: FileDialog
var _dialog_kind := ""


func _ready() -> void:
	var vs := get_viewport_rect().size
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.11, 0.14, 0.96)
	bg.size = vs
	add_child(bg)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 560)
	panel.position = (vs - panel.custom_minimum_size) / 2.0
	add_child(panel)
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(m)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	m.add_child(box)
	var title := Label.new()
	title.text = "Welcome to Snow Crash (demo)"
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	var sub := Label.new()
	sub.text = "Pick the folders you'd like to walk around. Each one becomes a room in the demo building.\nSnow Crash only LOOKS at your files: it never copies, moves or changes anything."
	sub.add_theme_font_size_override("font_size", 16)
	box.add_child(sub)
	for r in ROWS:
		var lab := Label.new()
		lab.text = r[1]
		lab.add_theme_font_size_override("font_size", 18)
		box.add_child(lab)
		var row := HBoxContainer.new()
		var edit := LineEdit.new()
		edit.placeholder_text = "(skip)"
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(edit)
		var browse := Button.new()
		browse.text = "Browse…"
		browse.pressed.connect(_browse.bind(r[0]))
		row.add_child(browse)
		box.add_child(row)
		_edits[r[0]] = edit
	var start := Button.new()
	start.text = "Start walking  ▶"
	start.add_theme_font_size_override("font_size", 20)
	start.pressed.connect(_finish)
	box.add_child(start)
	# TODO(libraries): secondary option "Use my Windows Libraries" (Q10).
	_dialog = FileDialog.new()
	_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_dialog.use_native_dialog = true
	_dialog.dir_selected.connect(_on_dir)
	add_child(_dialog)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _browse(kind: String) -> void:
	_dialog_kind = kind
	_dialog.popup_centered(Vector2i(900, 600))


func _on_dir(dir: String) -> void:
	(_edits[_dialog_kind] as LineEdit).text = dir


func _finish() -> void:
	var locs: Array = []
	for r in ROWS:
		var p := (_edits[r[0]] as LineEdit).text.strip_edges()
		if p != "" and DirAccess.dir_exists_absolute(p):
			locs.append({"label": "%s: %s" % [String(r[0]).capitalize(), p.trim_suffix("/").get_file()], "path": p, "kind": r[0]})
	if locs.is_empty():
		return  # TODO(ui): gentle "pick at least one folder" message
	Settings.set_value("demo", "locations", locs)
	Settings.set_value("general", "first_run_done", true)
	queue_free()
	finished.emit(locs)
