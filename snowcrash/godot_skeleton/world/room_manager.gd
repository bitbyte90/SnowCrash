extends Node3D
## RoomManager: turns folders into rooms on demand and moves you between them.
## Each room lives in its own "pocket" 1 km from the others (impossible space,
## Q30), so doors can lead anywhere. Rooms reset on exit and the last N stay
## cached (Q32/Q33). See TECH_ARCHITECTURE.md §5-6.

signal arrived(position: Vector3, yaw_deg: float, title: String)
signal go_outside(location_path: String)
signal toast(text: String)

const RoomBuilderScript := preload("res://world/room_builder.gd")
const POCKET_SPACING := 1000.0

var generator := RoomGenerator.new()
var cache := RoomCache.new()
var theme: Dictionary = {}
var locations: Array = []
var current_id := ""
var current_spec: RoomSpec
var template_overrides: Dictionary = {}   # normalised path -> template

var _specs: Dictionary = {}               # id -> RoomSpec (incl. lobby + hallways)
var _parent_ref: Dictionary = {}          # normalised path -> {"kind": "lobby"|"outside"|"folder", "path": String}
var _pocket_of: Dictionary = {}
var _next_pocket := 1
var _pending_id := ""
var _doors_by_target: Dictionary = {}     # normalised path -> Array of door nodes
var _door_cooldown := 0.0


func _ready() -> void:
	generator.density = Settings.get_value("rooms", "density", "normal")
	cache.set_capacity(int(Settings.get_value("performance", "rooms_cached", 3)))
	FileIndex.folder_scanned.connect(_on_folder_scanned)


func _process(delta: float) -> void:
	_door_cooldown = maxf(0.0, _door_cooldown - delta)


## locations: [{label, path, kind}]. use_lobby: the bare demo building has a
## lobby; the museum goes straight from each building's door to its folder.
func setup(locs: Array, use_lobby: bool) -> void:
	locations = locs
	var lobby := RoomSpec.new()
	lobby.id = "lobby"
	lobby.title = "Lobby"
	lobby.is_virtual = true
	lobby.doors.append({"socket": -1, "label": "Outside", "target_path": "", "target_id": "", "kind": "outside", "thumb": ""})
	for i in mini(locs.size(), 8):
		var loc: Dictionary = locs[i]
		lobby.doors.append({"socket": i, "label": loc.get("label", loc["path"]), "target_path": loc["path"], "target_id": "", "kind": "child", "thumb": ""})
		_parent_ref[FileIndex.normalise(loc["path"])] = {"kind": "lobby"} if use_lobby else {"kind": "outside", "path": loc["path"]}
		FileIndex.request_scan(loc["path"], false)   # door counts + thumbnails
	_specs["lobby"] = lobby


func go_lobby() -> void:
	_arrive("lobby")


func go_folder(path: String) -> void:
	var id := RoomGenerator.id_for(path)
	if cache.has_room(id) and _specs.has(id):
		_arrive(id)
		return
	_pending_id = id
	var cached := FileIndex.get_cached(path)
	if not cached.is_empty():
		_on_folder_scanned(path, cached)
	else:
		FileIndex.request_scan(path, true)


func use_door(d: Dictionary) -> void:
	if _door_cooldown > 0.0:
		return
	_door_cooldown = 0.8
	match String(d.get("kind", "")):
		"child":
			go_folder(d["target_path"])
		"parent":
			if String(d.get("target_path", "")) != "":
				go_folder(d["target_path"])
			elif _specs.has(d.get("target_id", "")):
				_arrive(d["target_id"])
		"hallway":
			_arrive(d["target_id"])
		"lobby":
			go_lobby()
		"outside":
			go_outside.emit(String(d.get("target_path", "")))


func register_door(door: Node, target_path: String) -> void:
	var key := FileIndex.normalise(target_path)
	if not _doors_by_target.has(key):
		_doors_by_target[key] = []
	_doors_by_target[key].append(door)
	var cached := FileIndex.get_cached(target_path)
	if not cached.is_empty():
		door.apply_folder_info(cached)


func cycle_slideshow() -> void:
	var s := (int(Settings.get_value("rooms", "slideshow_seconds", 0)) + 1) % 6
	set_slideshow(s)


func set_slideshow(seconds: int) -> void:
	Settings.set_value("rooms", "slideshow_seconds", seconds)
	var room := cache.get_room(current_id)
	if room == null:
		return
	for n in room.find_children("*", "", true, false):
		if n.has_method("set_slideshow"):
			n.set_slideshow(seconds)
		elif n.name == "SlideshowLabel":
			(n as Label3D).text = "Slideshow: %s" % ("off" if seconds == 0 else "%d s" % seconds)
	toast.emit("Slideshow: %s" % ("off (manual)" if seconds == 0 else "every %d s" % seconds))


## "Make this a cinema" (TECH §5.2 per-folder template override).
func make_cinema(path: String) -> void:
	template_overrides[FileIndex.normalise(path)] = RoomSpec.TEMPLATE_CINEMA
	var id := RoomGenerator.id_for(path)
	cache.remove(id)
	_specs.erase(id)
	current_id = ""
	go_folder(path)


func on_cinema_message(text: String) -> void:
	toast.emit(text)


func current_room() -> Node3D:
	return cache.get_room(current_id)


# --- internals ----------------------------------------------------------------

func _on_folder_scanned(path: String, data: Dictionary) -> void:
	var key := FileIndex.normalise(path)
	for door in _doors_by_target.get(key, []):
		if is_instance_valid(door):
			door.apply_folder_info(data)
	var id := RoomGenerator.id_for(path)
	if id == _pending_id:
		_pending_id = ""
		_specs[id] = _make_spec(path, data)
		_arrive(id)


func _make_spec(path: String, data: Dictionary) -> RoomSpec:
	var key := FileIndex.normalise(path)
	var spec := generator.generate(data, "", template_overrides.get(key, ""))
	# Back door, depending on how we got here.
	var pref: Dictionary = _parent_ref.get(key, {})
	if pref.is_empty():
		var parent := path.trim_suffix("/").get_base_dir()
		pref = {"kind": "folder", "path": parent}
	var back := {"socket": -1, "target_id": "", "thumb": ""}
	match String(pref["kind"]):
		"lobby":
			back.merge({"kind": "lobby", "label": "Lobby", "target_path": ""})
		"outside":
			back.merge({"kind": "outside", "label": "Outside", "target_path": pref.get("path", "")})
		_:
			back.merge({"kind": "parent", "label": String(pref["path"]).get_file() if String(pref["path"]).get_file() != "" else pref["path"], "target_path": pref["path"]})
	spec.doors.push_front(back)
	_register_children(spec, path)
	return spec


func _register_children(spec: RoomSpec, real_parent: String) -> void:
	_specs[spec.id] = spec
	for d in spec.doors:
		if d["kind"] == "child":
			var k := FileIndex.normalise(d["target_path"])
			if not _parent_ref.has(k):
				_parent_ref[k] = {"kind": "folder", "path": real_parent}
	for h in spec.overflow_rooms:
		_register_children(h, real_parent)


func _arrive(id: String) -> void:
	var spec: RoomSpec = _specs.get(id)
	if spec == null:
		return
	if current_id != "" and current_id != id:
		cache.on_room_exited(current_id)
	var room := cache.get_room(id)
	if room == null:
		room = RoomBuilderScript.build(spec, self, theme)
		room.position = _pocket_origin(id)
		add_child(room)
		cache.put(id, room)
	current_id = id
	current_spec = spec
	AppState.enter_room(spec.path if spec.path != "" else spec.title)
	var spawn: Vector3 = room.get_meta("spawn_local", Vector3(0, 0, 4.6))
	arrived.emit(room.position + spawn, 0.0, spec.path if spec.path != "" else spec.title)
	# Prefetch: one-level scans of a few door targets so doors fill in quickly.
	var n := 0
	for d in spec.doors:
		if d["kind"] == "child" and n < 8:
			FileIndex.request_scan(d["target_path"], false)
			n += 1


func _pocket_origin(id: String) -> Vector3:
	if not _pocket_of.has(id):
		_pocket_of[id] = _next_pocket
		_next_pocket += 1
	return Vector3(_pocket_of[id] * POCKET_SPACING, 0, 0)
