extends Control
## TELEPORT MENU (Q4). Top level: Outside (the building's front door), the
## Lobby, and each chosen location. "Open ▸" drills into folders; "Go there"
## (or double-click / Enter) lands you inside that room. See UX_CONTROLS.md §5.
## TODO(vr): lives on the wrist panel; X opens it directly.

## target: {"kind": "spawn"|"lobby"|"folder", "path": String}
signal teleport_requested(target: Dictionary)
signal closed

var _list: ItemList
var _crumbs: Label
var _current := ""          # "" = top level
var _panel: PanelContainer


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(560, 560)
	add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	_panel.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	var title := Label.new()
	title.text = "🧭 Teleport"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	_crumbs = Label.new()
	_crumbs.add_theme_font_size_override("font_size", 15)
	_crumbs.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	box.add_child(_crumbs)
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.custom_minimum_size = Vector2(520, 380)
	_list.add_theme_font_size_override("font_size", 18)
	_list.item_activated.connect(_on_activated)
	box.add_child(_list)
	var row := HBoxContainer.new()
	box.add_child(row)
	for spec in [["⬆ Up", _go_up], ["Open ▸", _open_selected], ["✈ Go there", _go_selected], ["Close", close]]:
		var b := Button.new()
		b.text = spec[0]
		b.add_theme_font_size_override("font_size", 17)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(spec[1])
		row.add_child(b)


func open() -> void:
	visible = true
	_panel.position = (get_viewport_rect().size - _panel.custom_minimum_size) / 2.0
	if _current == "":
		show_top()
	else:
		show_folder(_current)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_list.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func show_top() -> void:
	_current = ""
	_crumbs.text = "This PC  (pick a place, then Go there; Open ▸ looks inside)"
	_list.clear()
	_add("🏛  Outside: the building's front door", {"kind": "spawn"})
	_add("🚪  Lobby", {"kind": "lobby"})
	for loc in AppState.locations:
		_add("★  %s" % loc.get("label", loc["path"]), {"kind": "folder", "path": loc["path"]})
	# TODO(Q4, full app): drives as buildings: DirAccess.get_drive_count()/get_drive_name().
	# TODO(favourites/recent): sections above the list.
	if _list.item_count > 0:
		_list.select(0)


func show_folder(path: String) -> void:
	_current = path
	_crumbs.text = path
	_list.clear()
	_add("📍  (this folder)", {"kind": "folder", "path": path})
	var data: Dictionary = FileIndex.get_cached(path)
	if data.is_empty():
		# A one-level scan is fine in a flat menu; the world always scans on worker threads.
		data = FileScanner.new().scan_folder(path)
	for f in data.get("folders", []):
		_add("📁  " + String(f["name"]), {"kind": "folder", "path": f["path"]})
	_list.select(0)


## Used by the scripted screenshot tour.
func select_label_containing(text: String) -> bool:
	for i in _list.item_count:
		if _list.get_item_text(i).contains(text):
			_list.select(i)
			_list.ensure_current_is_visible()
			return true
	return false


func _add(text: String, target: Dictionary) -> void:
	_list.add_item(text)
	_list.set_item_metadata(_list.item_count - 1, target)


func _selected() -> Dictionary:
	var sel := _list.get_selected_items()
	return {} if sel.is_empty() else _list.get_item_metadata(sel[0])


func _open_selected() -> void:
	var t := _selected()
	if t.get("kind", "") == "folder":
		show_folder(t["path"])


func _go_selected() -> void:
	var t := _selected()
	if not t.is_empty():
		close()
		teleport_requested.emit(t)


func _on_activated(_index: int) -> void:
	_go_selected()


func _go_up() -> void:
	if _current == "":
		return
	for loc in AppState.locations:
		if FileIndex.normalise(loc["path"]) == FileIndex.normalise(_current):
			show_top()
			return
	var parent := _current.trim_suffix("/").get_base_dir()
	if parent == "" or parent == _current:
		show_top()
	else:
		show_folder(parent)


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and (event as InputEventKey).physical_keycode in [KEY_ESCAPE, KEY_T]:
		close()
		get_viewport().set_input_as_handled()
