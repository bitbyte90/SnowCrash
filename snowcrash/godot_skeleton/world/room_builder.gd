extends RefCounted
## RoomSpec -> nodes, for the bare white-box theme (and tinted variants for
## other worlds via a `theme` Dictionary). A theme pack will eventually supply
## shells with named sockets instead (WORLDS.md §6); the socket maths here is
## the stand-in for those sockets.
##
## Standard room: 16 m wide (x -8..8), 14 m deep (z -7..7), 4.5 m high.
## Spawn at z = +4.6 facing -Z. Back door (to the parent) behind you at z = +7.
## Canvas sockets: back wall 6, left wall 3, right wall 3 (= 12).
## Door sockets: left wall 2, right wall 2, front wall 4 (= 8).

const KitScript := preload("res://world/kit.gd")
const DoorScript := preload("res://world/door.gd")
const CanvasScript := preload("res://world/canvas.gd")
const LootScript := preload("res://world/loot_drop.gd")
const CinemaScript := preload("res://world/cinema.gd")

const SIZE := Vector3(16, 4.5, 14)
const SPAWN := Vector3(0, 0, 4.6)

const DEFAULT_THEME := {
	"wall": Color(0.93, 0.92, 0.9), "floor": Color(0.66, 0.56, 0.44), "ceiling": Color(0.85, 0.85, 0.86),
	"frame": Color(0.12, 0.1, 0.08), "door": Color(0.45, 0.32, 0.22), "door_frame": Color(0.95, 0.94, 0.9),
	"cinema_wall": Color(0.12, 0.1, 0.14), "cinema_floor": Color(0.2, 0.06, 0.08), "light": Color(1, 0.96, 0.9),
}

const CANVAS_SOCKETS := [
	# back wall (rot 0)
	[Vector3(-6.25, 1.75, -6.85), 0.0], [Vector3(-3.75, 1.75, -6.85), 0.0], [Vector3(-1.25, 1.75, -6.85), 0.0],
	[Vector3(1.25, 1.75, -6.85), 0.0], [Vector3(3.75, 1.75, -6.85), 0.0], [Vector3(6.25, 1.75, -6.85), 0.0],
	# left wall (faces +X)
	[Vector3(-7.85, 1.75, -4.6), 90.0], [Vector3(-7.85, 1.75, -2.2), 90.0], [Vector3(-7.85, 1.75, 0.2), 90.0],
	# right wall (faces -X)
	[Vector3(7.85, 1.75, -4.6), -90.0], [Vector3(7.85, 1.75, -2.2), -90.0], [Vector3(7.85, 1.75, 0.2), -90.0],
]

const DOOR_SOCKETS := [
	[Vector3(-7.9, 0, 2.6), 90.0], [Vector3(7.9, 0, 2.6), -90.0],
	[Vector3(-7.9, 0, 5.2), 90.0], [Vector3(7.9, 0, 5.2), -90.0],
	[Vector3(-3.0, 0, 6.9), 180.0], [Vector3(3.0, 0, 6.9), 180.0],
	[Vector3(-5.6, 0, 6.9), 180.0], [Vector3(5.6, 0, 6.9), 180.0],
]
## Rooms with no pictures (lobbies, folder-of-folders) put doors straight ahead.
const DOOR_SOCKETS_AHEAD := [
	[Vector3(-5.4, 0, -6.9), 0.0], [Vector3(-2.7, 0, -6.9), 0.0], [Vector3(0.0, 0, -6.9), 0.0],
	[Vector3(2.7, 0, -6.9), 0.0], [Vector3(5.4, 0, -6.9), 0.0],
	[Vector3(-7.9, 0, -3.0), 90.0], [Vector3(7.9, 0, -3.0), -90.0], [Vector3(-7.9, 0, 0.4), 90.0],
]
const BACK_DOOR := [Vector3(0, 0, 6.9), 180.0]


static func build(spec: RoomSpec, manager: Node, theme: Dictionary = {}) -> Node3D:
	var t := DEFAULT_THEME.duplicate()
	t.merge(theme, true)
	if spec.template == RoomSpec.TEMPLATE_HALLWAY:
		return _build_hallway(spec, manager, t)
	var cinema := spec.template == RoomSpec.TEMPLATE_CINEMA
	var room := Node3D.new()
	room.name = "Room_" + spec.id
	room.set_meta("spawn_local", SPAWN)
	_shell(room, SIZE, t["cinema_wall"] if cinema else t["wall"], t["cinema_floor"] if cinema else t["floor"], t["ceiling"])
	# Lights: soft and shadowless (cheap in VR and on the Compatibility renderer).
	var energy := 0.45 if cinema else 0.9
	room.add_child(KitScript.omni(Vector3(-4, 3.3, -3), energy, 13.0, t["light"]))
	room.add_child(KitScript.omni(Vector3(4, 3.3, -3), energy, 13.0, t["light"]))
	room.add_child(KitScript.omni(Vector3(0, 3.3, 3.5), energy * 0.8, 11.0, t["light"]))

	# Room title above the entrance wall facing you... and on the back wall.
	var counts := _count_line(spec)
	var title := KitScript.label("%s\n%s" % [spec.title, counts], Vector3(0, 3.85, -6.88), 0.006,
		Color(0.95, 0.95, 0.95) if cinema else Color(0.15, 0.15, 0.18), 0 if not cinema else 8)
	room.add_child(title)
	if spec.error != "":
		room.add_child(KitScript.label("🔒 Can't open this folder:\n%s" % spec.error, Vector3(0, 2.0, -6.8), 0.008, Color(0.6, 0.1, 0.1), 0))

	var slideshow := int(Settings.get_value("rooms", "slideshow_seconds", 0))
	if cinema:
		var c: Node3D = CinemaScript.new()
		c.name = "Cinema"
		c.setup(spec.videos, SIZE)
		if manager.has_method("on_cinema_message"):
			c.message.connect(manager.on_cinema_message)
		room.add_child(c)
	else:
		for cv in spec.canvases:
			var socket: Array = CANVAS_SOCKETS[int(cv["socket"]) % CANVAS_SOCKETS.size()]
			var canvas: Node3D = CanvasScript.new()
			canvas.setup(cv["images"], slideshow, t["frame"])
			canvas.position = socket[0]
			canvas.rotation_degrees.y = socket[1]
			room.add_child(canvas)
		if spec.canvases.size() > 0:
			_slideshow_plaque(room, slideshow, manager)
		if spec.videos.size() > 0:
			_tv_corner(room, spec, manager)

	_place_objects(room, spec)

	var sockets: Array = DOOR_SOCKETS_AHEAD if (spec.canvases.is_empty() and not cinema) else DOOR_SOCKETS
	for d in spec.doors:
		var socket: Array = BACK_DOOR if int(d["socket"]) < 0 else sockets[int(d["socket"]) % sockets.size()]
		var door: Node3D = DoorScript.new()
		door.setup(d, t)
		door.position = socket[0]
		door.rotation_degrees.y = socket[1]
		door.door_used.connect(manager.use_door)
		room.add_child(door)
		if d["kind"] == "child" and manager.has_method("register_door"):
			manager.register_door(door, d["target_path"])
	return room


static func _shell(room: Node3D, s: Vector3, wall: Color, floor_col: Color, ceiling: Color) -> void:
	room.add_child(KitScript.box(Vector3(s.x, 0.2, s.z), Vector3(0, -0.1, 0), floor_col))
	room.add_child(KitScript.box(Vector3(s.x, 0.2, s.z), Vector3(0, s.y + 0.1, 0), ceiling))
	room.add_child(KitScript.box(Vector3(s.x, s.y, 0.2), Vector3(0, s.y / 2, -s.z / 2 - 0.1), wall))
	room.add_child(KitScript.box(Vector3(s.x, s.y, 0.2), Vector3(0, s.y / 2, s.z / 2 + 0.1), wall))
	room.add_child(KitScript.box(Vector3(0.2, s.y, s.z), Vector3(-s.x / 2 - 0.1, s.y / 2, 0), wall))
	room.add_child(KitScript.box(Vector3(0.2, s.y, s.z), Vector3(s.x / 2 + 0.1, s.y / 2, 0), wall))
	# Skirting strip so walls read in flat light.
	room.add_child(KitScript.box(Vector3(s.x, 0.12, 0.04), Vector3(0, 0.06, -s.z / 2 + 0.02), wall.darkened(0.3), false))


static func _count_line(spec: RoomSpec) -> String:
	var parts: Array[String] = []
	var n := spec.total_images()
	if n > 0:
		parts.append("%d pictures on %d canvases" % [n, spec.canvases.size()] if n > spec.canvases.size() else "%d pictures" % n)
	if spec.videos.size() > 0:
		parts.append("%d films" % spec.videos.size())
	var child_doors := spec.doors.filter(func(d): return d["kind"] in ["child", "hallway"]).size()
	if child_doors > 0:
		parts.append("%d doors" % child_doors)
	return " · ".join(parts)


static func _slideshow_plaque(room: Node3D, seconds: int, manager: Node) -> void:
	var plaque := KitScript.box(Vector3(0.6, 0.35, 0.08), Vector3(-1.5, 1.2, 4.0), Color(0.2, 0.22, 0.26)) as StaticBody3D
	var stand := KitScript.box(Vector3(0.08, 1.0, 0.08), Vector3(-1.5, 0.5, 4.05), Color(0.2, 0.22, 0.26), false)
	room.add_child(stand)
	plaque.rotation_degrees.x = -25
	var l := KitScript.label("Slideshow: %s" % ("off" if seconds == 0 else "%d s" % seconds), Vector3(0, 0, 0.05), 0.0026)
	l.name = "SlideshowLabel"
	plaque.add_child(l)
	KitScript.make_interactive(plaque, {}, "Slideshow switch (E: off → 1 → … → 5 s)", manager.cycle_slideshow)
	room.add_child(plaque)


## Videos in a non-cinema room: a TV corner whose screen offers "make this a cinema".
static func _tv_corner(room: Node3D, spec: RoomSpec, manager: Node) -> void:
	var tv := KitScript.box(Vector3(1.6, 0.95, 0.08), Vector3(5.2, 1.3, 4.2), Color(0.05, 0.05, 0.06)) as StaticBody3D
	tv.rotation_degrees.y = -35
	tv.add_child(KitScript.label("📺 %d films here\nE: watch in a cinema" % spec.videos.size(), Vector3(0, 0, 0.05), 0.0035))
	room.add_child(KitScript.box(Vector3(0.9, 0.8, 0.5), Vector3(5.2, 0.4, 4.3), Color(0.3, 0.22, 0.15), false))
	KitScript.make_interactive(tv, {"kind": "folder", "path": spec.path, "name": spec.title}, "TV: %d films (E: make this a cinema)" % spec.videos.size(), manager.make_cinema.bind(spec.path))
	room.add_child(tv)


## Loot drops / crates / Polaroids, in a loose grid in the middle of the room.
static func _place_objects(room: Node3D, spec: RoomSpec) -> void:
	var slots: Array[Vector3] = []
	for row in 2:
		for col in 8:
			slots.append(Vector3(-3.5 + col * 1.0, 0, -1.2 + row * 1.3))
	var i := 0
	for obj in spec.objects:
		var files: Array = obj["files"]
		if obj["grouped"]:
			if i >= slots.size():
				break
			var drop: Node3D = LootScript.new()
			drop.setup(obj["kind"], files, true)
			drop.position = slots[i]
			room.add_child(drop)
			i += 1
		else:
			for f in files:
				if i >= slots.size():
					break
				var d: Node3D = LootScript.new()
				d.setup(obj["kind"], [f], false)
				d.position = slots[i]
				room.add_child(d)
				i += 1


## Hallway (virtual overflow room): a corridor with doors on both sides.
static func _build_hallway(spec: RoomSpec, manager: Node, t: Dictionary) -> Node3D:
	var room := Node3D.new()
	room.name = "Hall_" + spec.id
	var length := 22.0
	var s := Vector3(5, 3.6, length)
	room.set_meta("spawn_local", Vector3(0, 0, length / 2 - 2.0))
	_shell(room, s, t["wall"].darkened(0.05), t["floor"].darkened(0.1), t["ceiling"])
	for k in 4:
		room.add_child(KitScript.omni(Vector3(0, 3.2, length / 2 - 3 - k * 5.5), 1.0, 8.0, t["light"]))
	room.add_child(KitScript.label(spec.title, Vector3(0, 2.8, -length / 2 + 0.05), 0.006, Color(0.15, 0.15, 0.2), 0))
	for d in spec.doors:
		var door: Node3D = DoorScript.new()
		door.setup(d, t)
		var sock := int(d["socket"])
		if sock < 0:
			door.position = Vector3(0, 0, length / 2 - 0.1)
			door.rotation_degrees.y = 180
		else:
			var left := sock % 2 == 0
			door.position = Vector3(-2.4 if left else 2.4, 0, length / 2 - 4.0 - (sock / 2) * 2.9)
			door.rotation_degrees.y = 90 if left else -90
		door.door_used.connect(manager.use_door)
		room.add_child(door)
		if d["kind"] == "child":
			manager.register_door(door, d["target_path"])
	return room
