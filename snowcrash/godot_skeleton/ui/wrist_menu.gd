extends Control
## WRIST MENU (Q36, UX_CONTROLS.md §3): Search · Teleport · Settings · Alerts.
## Flat-screen: Tab opens it as a centred panel (/ jumps to Search, N to Alerts).
## VR: main.gd moves this Control into a VrPanel on the left wrist (ui/vr_panel.gd);
## the right-hand laser clicks it. The same code runs in both places.
## Everything here is read-only; settings are saved in app data, never in your folders.

signal teleport_requested(target: Dictionary)
signal full_teleport_requested
signal back_requested
signal slideshow_changed(seconds: int)
signal cache_size_changed(rooms: int)
signal setup_requested
signal closed

const SIZE := Vector2(760, 560)
const TAB_SEARCH := 0
const TAB_TELEPORT := 1
const TAB_SETTINGS := 2
const TAB_ALERTS := 3

var in_vr := false
var _panel: PanelContainer
var _tabs: TabContainer
var _query: LineEdit
var _results: ItemList
var _search_status: Label
var _places: ItemList
var _alerts: ItemList
var _slide_label: Label
var _slide: HSlider
var _cache: SpinBox
var _volume: HSlider
var _volume_label: Label
var _mute: CheckBox
var _dnd: CheckBox
var _clock: Label
var _where: Label
var _unread := 0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = SIZE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.12, 0.15, 0.97)
	sb.border_color = Color(0.35, 0.6, 0.9, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	_panel.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)

	# Header: clock, where you are, close.
	var head := HBoxContainer.new()
	box.add_child(head)
	_clock = _label("", 22)
	head.add_child(_clock)
	_where = _label("", 15)
	_where.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_where.clip_text = true
	_where.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_where)
	head.add_child(_button("⬆ Up a room", func(): back_requested.emit()))
	head.add_child(_button("✕", close))

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_theme_font_size_override("font_size", 19)
	box.add_child(_tabs)
	_build_search()
	_build_teleport()
	_build_settings()
	_build_alerts()
	_tabs.tab_changed.connect(_on_tab_changed)

	SearchService.results_ready.connect(_on_results)
	Notifications.notification_added.connect(_on_notification)
	Notifications.notifications_cleared.connect(_refresh_alerts)
	AppState.room_changed.connect(func(_p): _refresh_where())


# --- building the tabs ----------------------------------------------------------

func _build_search() -> void:
	var v := _tab("🔍 Search")
	var row := HBoxContainer.new()
	v.add_child(row)
	_query = LineEdit.new()
	_query.placeholder_text = "Type part of a file or folder name…"
	_query.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_query.add_theme_font_size_override("font_size", 18)
	_query.text_submitted.connect(func(_t): _do_search())
	row.add_child(_query)
	row.add_child(_button("Search", _do_search))
	_search_status = _label("Searches your chosen places (or the whole PC if Everything is installed).", 14)
	_search_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_search_status.custom_minimum_size = Vector2(700, 0)   # wrapped labels need a width or they grow very tall
	v.add_child(_search_status)
	_results = _list()
	_results.item_activated.connect(func(_i): _go_result())
	v.add_child(_results)
	var r2 := HBoxContainer.new()
	v.add_child(r2)
	r2.add_child(_button("✈ Go there", _go_result, true))
	r2.add_child(_button("📍 Show path", _show_result_path, true))
	# TODO(vr): an in-VR keyboard (Godot XR Tools has one) or voice input.


func _build_teleport() -> void:
	var v := _tab("🧭 Teleport")
	v.add_child(_label("Jump to a place. For any folder, open the full teleport menu.", 14))
	_places = _list()
	_places.item_activated.connect(func(_i): _go_place())
	v.add_child(_places)
	var row := HBoxContainer.new()
	v.add_child(row)
	row.add_child(_button("✈ Go there", _go_place, true))
	row.add_child(_button("📂 Browse all folders…", _browse_all, true))


func _build_settings() -> void:
	var v := _tab("⚙ Settings")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 14)
	v.add_child(grid)

	_slide_label = _label("", 17)
	grid.add_child(_slide_label)
	_slide = HSlider.new()
	_slide.min_value = 0
	_slide.max_value = 5
	_slide.step = 1
	_slide.custom_minimum_size = Vector2(300, 28)
	_slide.value = int(Settings.get_value("rooms", "slideshow_seconds", 0))
	_slide.value_changed.connect(_on_slide)
	grid.add_child(_slide)

	grid.add_child(_label("Rooms kept in memory", 17))
	_cache = SpinBox.new()
	_cache.min_value = 1
	_cache.max_value = 10
	_cache.value = int(Settings.get_value("performance", "rooms_cached", 3))
	_cache.value_changed.connect(_on_cache)
	grid.add_child(_cache)

	_volume_label = _label("", 17)
	grid.add_child(_volume_label)
	_volume = HSlider.new()
	_volume.min_value = 0.0
	_volume.max_value = 1.0
	_volume.step = 0.05
	_volume.custom_minimum_size = Vector2(300, 28)
	_volume.value = float(Settings.get_value("audio", "master", 0.8))
	_volume.value_changed.connect(_on_volume)
	grid.add_child(_volume)

	grid.add_child(_label("Sound", 17))
	_mute = CheckBox.new()
	_mute.text = "Mute everything"
	_mute.button_pressed = bool(Settings.get_value("audio", "muted", false))
	_mute.toggled.connect(func(on): Settings.set_value("audio", "muted", on))
	grid.add_child(_mute)

	grid.add_child(_label("My folders", 17))
	grid.add_child(_button("Change my folders (setup wizard)…", _request_setup))

	_update_setting_labels()
	var note := _label("Saved in Snow Crash's own settings file (never in your folders). When started with --root, nothing is saved.", 13)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(700, 0)
	v.add_child(note)
	# TODO(settings): the full tree from UX_CONTROLS.md §8 (comfort, worlds, density…).


func _build_alerts() -> void:
	var v := _tab("🔔 Alerts")
	_alerts = _list()
	v.add_child(_alerts)
	var row := HBoxContainer.new()
	v.add_child(row)
	row.add_child(_button("✈ Go there", _go_alert, true))
	row.add_child(_button("🧹 Clear all", func(): Notifications.clear(), true))
	_dnd = CheckBox.new()
	_dnd.text = "Do not disturb"
	_dnd.button_pressed = Notifications.do_not_disturb
	_dnd.toggled.connect(func(on): Notifications.do_not_disturb = on)
	row.add_child(_dnd)


# --- open / close ----------------------------------------------------------------

func open(tab := -1) -> void:
	visible = true
	if not in_vr:
		_panel.position = ((get_viewport_rect().size - SIZE) / 2.0).floor()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		_panel.position = Vector2.ZERO
	if tab >= 0:
		_tabs.current_tab = tab
	_refresh_where()
	_refresh_places()
	_refresh_alerts()
	_on_tab_changed(_tabs.current_tab)


func close() -> void:
	if not visible:
		return
	visible = false
	if not in_vr:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func toggle(tab := -1) -> void:
	if visible and (tab < 0 or tab == _tabs.current_tab):
		close()
	else:
		open(tab)


func unread_count() -> int:
	return _unread


func current_tab() -> int:
	return _tabs.current_tab


func _process(_delta: float) -> void:
	if visible:
		var t := Time.get_time_dict_from_system()
		_clock.text = "%02d:%02d" % [t["hour"], t["minute"]]


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or in_vr or not (event is InputEventKey) or not event.pressed:
		return
	var k := (event as InputEventKey).physical_keycode
	if k == KEY_ESCAPE or (k == KEY_TAB and not _query.has_focus()):
		close()
		get_viewport().set_input_as_handled()


# --- search ------------------------------------------------------------------------

func focus_search(text := "") -> void:
	_tabs.current_tab = TAB_SEARCH
	if text != "":
		_query.text = text
	_query.grab_focus()


func _do_search() -> void:
	var q := _query.text.strip_edges()
	if q == "":
		return
	_results.clear()
	_search_status.text = "Searching for “%s”…" % q
	SearchService.search(q)


func _on_results(query: String, results: Array) -> void:
	if query.strip_edges() != _query.text.strip_edges():
		return  # an older search finished late
	_results.clear()
	for r in results:
		var icon := "📁" if r["kind"] == "folder" else _icon(String(r["kind"]))
		_results.add_item("%s  %s   —  %s" % [icon, r.get("name", String(r["path"]).get_file()), String(r["path"]).get_base_dir()])
		_results.set_item_metadata(_results.item_count - 1, r)
	var src := "Everything" if SearchService.backend == "everything" else "your chosen places"
	_search_status.text = ("%d result(s) for “%s” in %s." % [results.size(), query, src]) if not results.is_empty() else "Nothing called “%s” in %s." % [query, src]
	if _results.item_count > 0:
		_results.select(0)


func _go_result() -> void:
	var r := _selected(_results)
	if r.is_empty():
		return
	var path := String(r["path"])
	# Folders: go inside. Files: go to the room that holds them.
	var target := path if r["kind"] == "folder" else path.get_base_dir()
	close()
	teleport_requested.emit({"kind": "folder", "path": target, "highlight": path})


func _show_result_path() -> void:
	var r := _selected(_results)
	if not r.is_empty():
		_search_status.text = "📍 " + String(r["path"])


# --- teleport tab ------------------------------------------------------------------

func _refresh_places() -> void:
	_places.clear()
	_add(_places, "🏛  Outside (spawn)", {"kind": "spawn"})
	_add(_places, "🚪  Lobby", {"kind": "lobby"})
	for loc in AppState.locations:
		_add(_places, "★  %s" % loc.get("label", loc["path"]), {"kind": "folder", "path": loc["path"]})
	# TODO(favourites/recent): Settings-backed lists above the locations.
	_places.select(0)


func _browse_all() -> void:
	close()
	full_teleport_requested.emit()


func _go_place() -> void:
	var t := _selected(_places)
	if not t.is_empty():
		close()
		teleport_requested.emit(t)


# --- settings ----------------------------------------------------------------------

func _request_setup() -> void:
	close()
	setup_requested.emit()


func _on_slide(v: float) -> void:
	Settings.set_value("rooms", "slideshow_seconds", int(v))
	slideshow_changed.emit(int(v))
	_update_setting_labels()


func _on_cache(v: float) -> void:
	Settings.set_value("performance", "rooms_cached", int(v))
	cache_size_changed.emit(int(v))


func _on_volume(v: float) -> void:
	Settings.set_value("audio", "master", v)
	_update_setting_labels()


func _update_setting_labels() -> void:
	var s := int(_slide.value)
	_slide_label.text = "Slideshow: %s" % ("manual" if s == 0 else "every %d s" % s)
	_volume_label.text = "Volume: %d%%" % int(round(_volume.value * 100))


## Keeps the slider in step when the slideshow is changed with the 0-5 keys.
func sync_slideshow(seconds: int) -> void:
	_slide.set_value_no_signal(seconds)
	_update_setting_labels()


# --- alerts ------------------------------------------------------------------------

func _on_notification(_item: Dictionary) -> void:
	_unread += 1
	_refresh_tab_titles()
	if visible:
		_refresh_alerts()


func _refresh_alerts() -> void:
	_alerts.clear()
	for n in Notifications.items:
		var t := Time.get_datetime_dict_from_unix_time(int(n["time"]) + _tz_offset())
		_alerts.add_item("%02d:%02d   %s" % [t["hour"], t["minute"], n["text"]])
		_alerts.set_item_metadata(_alerts.item_count - 1, n)
	if Notifications.items.is_empty():
		_alerts.add_item("No alerts. Changes in your rooms and app messages show up here.")
		_alerts.set_item_disabled(0, true)
	_refresh_tab_titles()


func _go_alert() -> void:
	var n := _selected(_alerts)
	var path := String(n.get("data", {}).get("path", "")) if not n.is_empty() else ""
	if path != "":
		close()
		teleport_requested.emit({"kind": "folder", "path": path if DirAccess.dir_exists_absolute(path) else path.get_base_dir()})


func _on_tab_changed(tab: int) -> void:
	if tab == TAB_ALERTS:
		_unread = 0
		_refresh_tab_titles()
	elif tab == TAB_SEARCH and visible and not in_vr:
		_query.grab_focus.call_deferred()


func _refresh_tab_titles() -> void:
	_tabs.set_tab_title(TAB_ALERTS, "🔔 Alerts" + (" (%d)" % _unread if _unread > 0 else ""))


func _refresh_where() -> void:
	_where.text = AppState.current_room_path if AppState.current_room_path != "" else "Outside"


# --- small helpers -----------------------------------------------------------------

func _tab(title: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = title
	v.add_theme_constant_override("separation", 8)
	_tabs.add_child(v)
	return v


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l


func _button(text: String, cb: Callable, expand := false) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 17)
	if expand:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(cb)
	return b


func _list() -> ItemList:
	var l := ItemList.new()
	l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size = Vector2(0, 260)
	l.add_theme_font_size_override("font_size", 17)
	return l


func _add(list: ItemList, text: String, meta: Dictionary) -> void:
	list.add_item(text)
	list.set_item_metadata(list.item_count - 1, meta)


func _selected(list: ItemList) -> Dictionary:
	var sel := list.get_selected_items()
	if sel.is_empty():
		return {}
	var m: Variant = list.get_item_metadata(sel[0])
	return m if m is Dictionary else {}


static func _icon(kind: String) -> String:
	match kind:
		"image", "image_other":
			return "🖼"
		"video":
			return "🎬"
		"audio":
			return "🎵"
		"archive":
			return "📦"
		_:
			return "📄"


static func _tz_offset() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60
