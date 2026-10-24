extends Node3D
## Entry point for the flat-screen demo and the (untested) OpenXR mode.
## Flow: setup wizard (first run) -> world (bare + one building, or the museum,
## island or city greybox) -> spawn outside -> walk in.
##
## Command-line options (after `--`):
##   --root=PATH        use PATH as a location (repeatable); skips the wizard, saves nothing
##   --world=NAME       bare (default), museum, island or city (greybox worlds)
##   --enter=PATH       start inside the room for PATH
##   --flat             never try VR
##   --fake-vr          build the VR rig + panels without a headset (screenshots/tests only)
##   --tour=DIR         run the scripted screenshot tour and save PNGs into DIR
##   --tour-set=NAME    which tour: demo (default), museum, island, city, wrist or vr (vr needs --fake-vr)

const PlayerRigScript := preload("res://player/player_rig.gd")
const RoomManagerScript := preload("res://world/room_manager.gd")
const WorldBareScript := preload("res://world/world_bare.gd")
const WorldMuseumScript := preload("res://world/world_museum.gd")
const WorldIslandScript := preload("res://world/world_island.gd")
const WorldCityScript := preload("res://world/world_city.gd")
const WristMenuScript := preload("res://ui/wrist_menu.gd")
const VrPanelScript := preload("res://ui/vr_panel.gd")
const HudScript := preload("res://ui/hud.gd")
const BagMenuScript := preload("res://ui/bag_menu.gd")
const TeleportMenuScript := preload("res://ui/teleport_menu.gd")
const WizardScript := preload("res://ui/setup_wizard.gd")
const TourScript := preload("res://tests/capture_tour.gd")

var rig: Node3D
var world: Node3D
var rooms: Node3D
var hud: Control
var bag: Control
var teleport: Control
var wrist: Control
var ui: CanvasLayer
var screen_panel: Node3D        # VR only: carries the 2D UI in front of you
var wrist_panel: Node3D         # VR only: the wrist menu on your left wrist
var opts := {"roots": [], "world": "bare", "enter": "", "flat": false, "fake_vr": false, "tour": "", "tour_set": "demo"}
var _write_notice_shown := false
var _vr_menu_was_open := false


func _ready() -> void:
	add_to_group("sc_main")
	print("Snow Crash %s · Godot %s · OpenXR %s" % [
		ProjectSettings.get_setting("application/config/version", "?"), Engine.get_version_info()["string"],
		"on" if XRServer.find_interface("OpenXR") and XRServer.find_interface("OpenXR").is_initialized() else "off"])
	AppState.register_input_actions()
	_parse_args()
	ui = CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	hud = HudScript.new()
	ui.add_child(hud)
	bag = BagMenuScript.new()
	ui.add_child(bag)
	bag.option_chosen.connect(_on_bag_option)
	bag.closed.connect(_on_menu_closed)
	teleport = TeleportMenuScript.new()
	ui.add_child(teleport)
	teleport.teleport_requested.connect(go_to)
	teleport.closed.connect(_on_menu_closed)
	wrist = WristMenuScript.new()
	ui.add_child(wrist)
	wrist.closed.connect(_on_menu_closed)
	wrist.teleport_requested.connect(go_to)
	wrist.full_teleport_requested.connect(_open_teleport)
	wrist.back_requested.connect(go_up)
	wrist.setup_requested.connect(_rerun_setup)
	wrist.slideshow_changed.connect(func(sec: int):
		if rooms:
			rooms.set_slideshow(sec))
	wrist.cache_size_changed.connect(func(n: int):
		if rooms:
			rooms.cache.set_capacity(n))
	Launcher.message.connect(hud.toast)
	Launcher.confirmation_needed.connect(_on_launch_confirm)
	Notifications.notification_added.connect(func(n): hud.toast("🔔 " + String(n["text"])))

	var locs: Array = []
	if not opts["roots"].is_empty():
		Settings.ephemeral = true   # command-line runs never overwrite the user's setup
		for r in opts["roots"]:
			var p := String(r).replace("\\", "/")
			if p.length() > 3:
				p = p.trim_suffix("/")   # keep "D:/" as it is
			var label := p.get_file() if p.get_file() != "" else p
			locs.append({"label": label, "path": p, "kind": "other"})
	else:
		locs = Settings.get_value("demo", "locations", [])
	if locs.is_empty():
		var wiz: Control = WizardScript.new()
		ui.add_child(wiz)
		wiz.finished.connect(_start)
	else:
		_start(locs)


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := String(a).trim_prefix("--").split("=", true, 1)
		var key := kv[0].replace("-", "_")
		var val := kv[1].trim_prefix("\"").trim_suffix("\"") if kv.size() > 1 else "true"
		if key == "root":
			opts["roots"].append(val)
		elif key == "flat":
			opts["flat"] = true
		elif key == "fake_vr":
			opts["fake_vr"] = true
		elif opts.has(key):
			opts[key] = val


func _start(locs: Array) -> void:
	AppState.locations = locs
	rooms = RoomManagerScript.new()
	rooms.name = "Rooms"
	add_child(rooms)
	rooms.arrived.connect(_on_arrived)
	rooms.go_outside.connect(_on_go_outside)
	rooms.toast.connect(hud.toast)
	var wname := String(opts["world"])
	var scripts := {"museum": WorldMuseumScript, "island": WorldIslandScript, "city": WorldCityScript}
	if not scripts.has(wname):
		wname = "bare"
	opts["world"] = wname
	world = (scripts[wname] if scripts.has(wname) else WorldBareScript).new()
	world.name = "World"
	world.manager = rooms
	add_child(world)
	if wname != "bare":
		rooms.theme = world.ROOM_THEME
	world.build(locs)
	rooms.setup(locs, wname == "bare")

	rig = PlayerRigScript.new()
	rig.name = "PlayerRig"
	rig.force_flat = opts["flat"] or opts["tour"] != ""
	rig.fake_vr = opts["fake_vr"]
	add_child(rig)
	var sp: Array = world.get_spawn()
	rig.teleport_to(sp[0], sp[1])
	if AppState.is_vr:
		_setup_vr_ui()
	var names := {"bare": "bare", "museum": "Museum Quad", "island": "Island", "city": "Metaverse City"}
	hud.set_where("Outside · %s world" % names[wname])
	var welcome := {
		"bare": "Welcome! Read the signs, then walk through the door. (T = teleport, Q = bag, Tab = wrist menu)",
		"museum": "Welcome to the Museum Quad! Each building is one of your folders. Walk in, or press T to teleport.",
		"island": "Welcome to the Island. Turn around: each hut, treehouse and lighthouse is one of your folders.",
		"city": "You've jacked in at a Port. Each tower on the Street is one of your folders. The directory screen = T.",
	}
	hud.toast(welcome[wname], 7.0)
	if opts["enter"] != "":
		go_to({"kind": "folder", "path": opts["enter"]})
	if opts["tour"] != "":
		var tour: Node = TourScript.new()
		tour.main = self
		tour.out_dir = opts["tour"]
		tour.tour_set = opts["tour_set"]
		add_child(tour)


func _process(_delta: float) -> void:
	if rig == null:
		return
	var o: Object = null if _menu_open() else rig.get_pointed()
	hud.set_hover(String(o.get_meta("sc_hover", "")) if o and o.has_meta("sc_hover") else "")
	hud.set_prompt(("Seated · A to stand up" if AppState.is_vr else "Seated · Space to stand up") if rig.is_seated() else "")
	if screen_panel and wrist_panel:
		_update_vr_panels()


func _menu_open() -> bool:
	return bag.visible or teleport.visible or wrist.visible


func _open_teleport() -> void:
	teleport.open()
	rig.set_input_enabled(false)


func _unhandled_input(event: InputEvent) -> void:
	if rig == null:
		return
	if wrist.visible and AppState.is_vr and (event.is_action_pressed("sc_wrist_menu") or event.is_action_pressed("sc_close")):
		wrist.close()   # VR buttons arrive as actions, not keys
		return
	if _menu_open():
		return
	if event.is_action_pressed("sc_close"):
		if not hud.hide_overlays():
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
		return
	if hud.is_viewer_open():
		return
	if event.is_action_pressed("sc_interact"):
		if event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		interact_pointed()
	elif event.is_action_pressed("sc_bag"):
		open_bag_for_pointed()
	elif event.is_action_pressed("sc_teleport_menu"):
		_open_teleport()
	elif event.is_action_pressed("sc_info"):
		var o: Object = rig.get_pointed()
		if o and o.has_meta("sc_item") and not (o.get_meta("sc_item") as Dictionary).is_empty():
			show_info(o.get_meta("sc_item"))
	elif event.is_action_pressed("sc_sit"):
		if rig.is_seated():
			rig.stand_up()
	elif event.is_action_pressed("sc_wrist_menu"):
		open_wrist(-1)
	elif event.is_action_pressed("sc_search"):
		open_wrist(wrist.TAB_SEARCH)
		wrist.focus_search()
	elif event.is_action_pressed("sc_notifications"):
		open_wrist(wrist.TAB_ALERTS)
	elif event is InputEventKey and event.pressed and not event.echo:
		var k: int = (event as InputEventKey).physical_keycode
		if k >= KEY_0 and k <= KEY_5:
			rooms.set_slideshow(k - KEY_0)
			Settings.set_value("rooms", "slideshow_seconds", k - KEY_0)
			wrist.sync_slideshow(k - KEY_0)


func open_wrist(tab: int) -> void:
	wrist.open(tab)
	rig.set_input_enabled(false)
	get_viewport().set_input_as_handled()


func interact_pointed() -> void:
	var o: Object = rig.get_pointed()
	if o and o.has_meta("sc_interact"):
		(o.get_meta("sc_interact") as Callable).call()


func open_bag_for_pointed() -> bool:
	var o: Object = rig.get_pointed()
	if o and o.has_meta("sc_item"):
		var item: Dictionary = o.get_meta("sc_item")
		if not item.is_empty() and item.get("kind", "") != "seat":
			bag.open_for(item)
			rig.set_input_enabled(false)
			return true
	return false


func _on_menu_closed() -> void:
	if rig:
		rig.set_input_enabled(true)


## Launcher asks before running programs / shortcuts; scripts are simply refused.
func _on_launch_confirm(path: String, reason: String) -> void:
	if path.get_extension().to_lower() in Launcher.BLOCKED_SCRIPT_EXTS:
		hud.toast("🛑 " + reason, 6.0)
		return
	var dlg := ConfirmationDialog.new()
	dlg.title = "Run a program?"
	dlg.dialog_text = "%s\n\n%s" % [reason, path]
	dlg.ok_button_text = "Run it"
	dlg.cancel_button_text = "No thanks"
	ui.add_child(dlg)
	rig.set_input_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	dlg.confirmed.connect(Launcher.confirm_and_open.bind(path, false))
	dlg.visibility_changed.connect(_on_dialog_hidden.bind(dlg))
	dlg.popup_centered()


func _on_dialog_hidden(dlg: Window) -> void:
	if not dlg.visible:
		dlg.queue_free()
		_on_menu_closed()
		if not AppState.is_vr:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Wrist menu → Settings → "Change my folders": run the wizard again, then rebuild.
func _rerun_setup() -> void:
	if Settings.ephemeral:
		hud.toast("Started with --root folders, so nothing is saved. Close and start SnowCrash.exe on its own to use the setup wizard.", 8.0)
		return
	if AppState.is_vr:
		hud.toast("Take off the headset: the setup wizard opens on your PC screen.", 6.0)
	rig.set_input_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var wiz: Control = WizardScript.new()
	ui.add_child(wiz)
	wiz.finished.connect(func(_locs): get_tree().reload_current_scene())


## Wrist menu "Up a room": the parent folder; from a location's own room, back outside.
func go_up() -> void:
	var cur := AppState.current_room_path
	if cur == "":
		hud.toast("You're outside already. Pick a place on the Teleport tab.")
		return
	for loc in AppState.locations:
		if FileIndex.normalise(loc["path"]) == FileIndex.normalise(cur):
			if opts["world"] == "bare":
				rooms.go_lobby()
			else:
				_on_go_outside(loc["path"])
			return
	if not DirAccess.dir_exists_absolute(cur):
		hud.toast("This is a hallway: use the Back door behind you.")
		return
	rooms.go_folder(cur.trim_suffix("/").get_base_dir())


## target: {"kind": "spawn"|"lobby"|"folder", "path": String}
func go_to(target: Dictionary) -> void:
	match String(target.get("kind", "")):
		"spawn":
			_leave_rooms()
			var sp: Array = world.get_spawn()
			hud.fade_through(_teleport_rig.bind(sp[0], sp[1], "Outside"))
		"lobby":
			if opts["world"] != "bare":
				hud.toast("This world has no lobby: each building's door leads straight to its folder.")
			else:
				rooms.go_lobby()
		"folder":
			rooms.go_folder(target["path"])
			if target.has("highlight") and String(target["highlight"]) != String(target["path"]):
				hud.toast("📍 %s is in this room." % String(target["highlight"]).get_file(), 6.0)


func _on_arrived(pos: Vector3, yaw: float, title: String) -> void:
	hud.fade_through(_teleport_rig.bind(pos, yaw, title))


func _on_go_outside(location_path: String) -> void:
	_leave_rooms()
	var p: Array = world.get_outside_point(location_path)
	hud.fade_through(_teleport_rig.bind(p[0], p[1], "Outside"))


func _teleport_rig(pos: Vector3, yaw: float, title: String) -> void:
	rig.teleport_to(pos, yaw)
	hud.set_where(title)


func _leave_rooms() -> void:
	if rooms.current_id != "":
		rooms.cache.on_room_exited(rooms.current_id)
		rooms.current_id = ""
	AppState.current_room_path = ""
	AppState.room_changed.emit("")


func _on_bag_option(action: String, item: Dictionary) -> void:
	var path := String(item.get("path", ""))
	match action:
		"view":
			hud.show_image(path)
		"info":
			show_info(item)
		"open_in_windows":
			Launcher.open_in_windows(path)
		"show_path":
			hud.toast("📍 " + path, 8.0)
		"show_in_folder":
			Launcher.show_in_folder(path)
		"copy_path":
			DisplayServer.clipboard_set(path)
			hud.toast("📋 Copied: " + path)
		"enter":
			if item.has("door"):
				rooms.use_door(item["door"])
			elif path != "":
				rooms.go_folder(path)
		"make_cinema":
			rooms.make_cinema(path)
		"play_here":
			var room: Node3D = rooms.current_room()
			var cinema: Node = room.get_node_or_null("Cinema") if room else null
			if cinema:
				cinema.select({"path": path, "name": path.get_file()})
			else:
				hud.toast("Videos play in a cinema: use the TV, or bag → Make this a cinema on the folder's door.")
		"write_locked":
			if not _write_notice_shown:
				_write_notice_shown = true
				hud.toast("✍ Rename / move / delete come with write mode (a supporter unlock). The free version is read-only so nothing can break.", 7.0)


## Bag → Info (or I): plain facts about the thing, read-only.
func show_info(item: Dictionary) -> void:
	var path := String(item.get("path", ""))
	var kind := String(item.get("kind", "file"))
	var lines: Array[String] = ["[b]%s[/b]" % item.get("name", path.get_file()), "Type: %s" % kind, "Path: %s" % path]
	if kind == "folder" or DirAccess.dir_exists_absolute(path):
		var data := FileIndex.get_cached(path)
		if not data.is_empty():
			lines.append("Contains: %d files, %d folders" % [data["files"].size(), data["folders"].size()])
	elif FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)   # read-only
		if f:
			lines.append("Size: %s" % String.humanize_size(f.get_length()))
			f.close()
		var mt := FileAccess.get_modified_time(path)
		lines.append("Modified: %s" % Time.get_datetime_string_from_unix_time(mt, true))
		if kind == "video":
			var r := Settings.get_resume(path)
			if r > 1.0:
				lines.append("Resume point: %d:%02d" % [int(r) / 60, int(r) % 60])
	if item.has("files") and item["files"].size() > 1:
		lines.append("")
		lines.append("[b]Inside this crate (%d):[/b]" % item["files"].size())
		for i in mini(12, item["files"].size()):
			lines.append("· " + String(item["files"][i]).get_file())
	lines.append("")
	lines.append("[i]Read-only: Snow Crash never changes your files. Esc to close.[/i]")
	hud.show_info("\n".join(lines))


# --- VR user interface (UNTESTED in a headset) -------------------------------------

## In VR a CanvasLayer isn't visible in the headset, so the 2D UI goes onto two
## panels: the HUD/bag/teleport "screen" floating in front of you, and the wrist
## menu on your left wrist. The right-hand laser clicks both (ui/vr_panel.gd).
func _setup_vr_ui() -> void:
	hud.set_vr_mode(true)
	wrist.in_vr = true
	wrist.reparent(self)      # out of the CanvasLayer before it moves
	screen_panel = VrPanelScript.new()
	screen_panel.name = "ScreenPanel"
	add_child(screen_panel)
	# 1280x720 px over 2 m, 1.5 m away: 18 px text is about 1 degree tall. TUNE IN HEADSET.
	screen_panel.setup(ui, Vector2i(1280, 720), 2.0)
	rig.vr.place_in_front(screen_panel, 1.5, 0.1)
	wrist_panel = VrPanelScript.new()
	wrist_panel.name = "WristPanel"
	add_child(wrist_panel)
	wrist_panel.setup(wrist, Vector2i(760, 560), 0.32)
	wrist_panel.set_shown(false)


func _update_vr_panels() -> void:
	wrist_panel.set_shown(wrist.visible)
	if wrist.visible:
		# Float just above the left hand, always turned to face you (easier than
		# relying on the exact wrist angle, which we can't tune without a headset).
		var host: Node3D = rig.vr.wrist_host
		var eye: Vector3 = rig.vr.camera.global_position
		var at := host.global_position + Vector3(0, 0.14, 0)
		wrist_panel.global_position = at
		wrist_panel.look_at(at + (at - eye), Vector3.UP)
	var menu: bool = bag.visible or teleport.visible or hud.is_viewer_open() or hud.is_info_open()
	(screen_panel.body.get_child(0) as CollisionShape3D).disabled = not menu
	# Lazy follow: only recentre when you've turned well away, or a menu opens.
	var cam: Node3D = rig.vr.camera
	var to_panel := screen_panel.global_position - cam.global_position
	var fwd := -cam.global_transform.basis.z
	var angle := rad_to_deg(Vector2(fwd.x, fwd.z).angle_to(Vector2(to_panel.x, to_panel.z)))
	if absf(angle) > 40.0 or (menu and not _vr_menu_was_open):
		rig.vr.place_in_front(screen_panel, 1.5, 0.1)
	_vr_menu_was_open = menu
