extends Node3D
## The Island GREYBOX (WORLDS.md §3, WORLD_BLOCKOUTS.md §3).
## Spawn on the beach facing the sea; turn around to see the island. Each chosen
## folder is a "locale": C: beach hut village, D: treehouse, E: lighthouse,
## F: cave grotto; more become islets reached by rope bridges.
## Primitive meshes only; sizes follow the blockout spec (scaled down a little
## so the greybox fits in one view).

const KitScript := preload("res://world/kit.gd")
const DoorScript := preload("res://world/door.gd")

const SAND := Color(0.86, 0.77, 0.56)
const GRASS := Color(0.36, 0.55, 0.25)
const ROCK := Color(0.5, 0.46, 0.42)
const PLANK := Color(0.55, 0.4, 0.25)
const WATER := Color(0.12, 0.42, 0.55)
const PALM_TRUNK := Color(0.5, 0.38, 0.24)
const PALM_LEAF := Color(0.2, 0.5, 0.2)

## Interiors: bamboo walls, woven floor, driftwood frames.
const ROOM_THEME := {
	"wall": Color(0.82, 0.72, 0.5), "floor": Color(0.58, 0.46, 0.3), "ceiling": Color(0.7, 0.6, 0.42),
	"frame": Color(0.55, 0.5, 0.42), "door": Color(0.45, 0.33, 0.2), "door_frame": Color(0.75, 0.66, 0.46),
	"light": Color(1.0, 0.88, 0.7),
}

## Locale slots on the main island: [position, yaw facing the spawn side, kind]
const SLOTS := [
	[Vector3(-24, 0, -24), 25.0, "huts"],
	[Vector3(26, 0, -30), -30.0, "treehouse"],
	[Vector3(44, 0, -6), -70.0, "lighthouse"],
	[Vector3(0, 0, -58), 0.0, "cave"],
	[Vector3(-96, 0, -40), 70.0, "islet"],
	[Vector3(96, 0, -40), -70.0, "islet"],
]

var manager: Node
var _fronts: Dictionary = {}


func build(locations: Array) -> void:
	_environment()
	# Sea (visual) + the island's sand and grass discs.
	add_child(KitScript.box(Vector3(800, 0.1, 800), Vector3(0, -0.35, 0), WATER, false))
	var sand := KitScript.cylinder(76.0, 1.0, Vector3(0, -0.5, -66), SAND)
	sand.scale = Vector3(1.0, 1.0, 0.95)
	add_child(sand)
	add_child(KitScript.cylinder(54.0, 0.1, Vector3(0, 0.03, -74), GRASS, false))
	# The hill (the cave locale is cut into its front).
	add_child(KitScript.cone(30.0, 6.0, 22.0, Vector3(0, 11.0, -84), GRASS.darkened(0.15)))
	add_child(KitScript.cone(8.0, 2.0, 5.0, Vector3(0, 24.0, -84), ROCK, false))
	# Keep walkers on dry land: an invisible ring of walls at the waterline.
	var islets := locations.size() > 4
	for i in 24:
		var a := TAU * i / 24.0
		var p := Vector3(sin(a) * 74.0, 1.5, -66 + cos(a) * 70.0)
		if p.z > -6.0 and p.x > 8.0 and p.x < 28.0:
			continue   # gap for the jetty
		if islets and absf(p.x) > 55.0 and absf(p.z + 40.0) < 14.0:
			continue   # gaps for the rope bridges
		var wall := KitScript.barrier(Vector3(20, 3, 0.5), p)
		wall.rotation.y = a
		add_child(wall)

	# Jetty (3 m wide, 30 m long) east of the spawn.
	add_child(KitScript.box(Vector3(3, 0.25, 30), Vector3(18, 0.65, 18), PLANK))
	add_child(KitScript.ramp(Vector3(18, 0.0, 1.0), Vector3(18, 0.78, 3.4), 3.0))
	for k in 6:
		add_child(KitScript.cylinder(0.15, 2.0, Vector3(16.6, 0.0, 6 + k * 5), PLANK.darkened(0.3), false))
		add_child(KitScript.cylinder(0.15, 2.0, Vector3(19.4, 0.0, 6 + k * 5), PLANK.darkened(0.3), false))

	# "Turn around" sign, readable from the spawn (which faces the sea).
	var sign := Node3D.new()
	sign.position = Vector3(2.2, 0, 3.0)
	sign.rotation_degrees.y = 200
	sign.add_child(KitScript.box(Vector3(0.1, 1.3, 0.1), Vector3(0, 0.65, 0), PLANK.darkened(0.2), false))
	sign.add_child(KitScript.box(Vector3(1.6, 0.7, 0.06), Vector3(0, 1.5, 0), PLANK, false))
	sign.add_child(KitScript.label("Lovely view!\nNow turn around ↻\nYour island is behind you", Vector3(0, 1.5, 0.04), 0.0032, Color(1, 0.95, 0.85)))
	add_child(sign)

	var locs := locations if not locations.is_empty() else [{"label": "C:", "path": ""}, {"label": "D:", "path": ""}]
	for i in mini(locs.size(), SLOTS.size()):
		_locale(locs[i], SLOTS[i])

	# Palms along the beach and around the locales (seeded so screenshots repeat).
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 46:
		var a := rng.randf_range(-PI * 0.95, PI * 0.95)
		var r := rng.randf_range(30.0, 66.0)
		var p := Vector3(sin(a) * r, 0, -66 + cos(a) * r * 0.92)
		if p.z > -4.0 and absf(p.x) < 14.0:
			continue   # keep the spawn view open
		if _near_slot(p, 12.0):
			continue
		_palm(p, rng)
	# Rocks.
	for i in 14:
		var p := Vector3(rng.randf_range(-60, 60), 0, rng.randf_range(-110, -10))
		if not _near_slot(p, 10.0) and p.distance_to(Vector3(0, 0, 0)) > 12.0:
			add_child(KitScript.sphere(rng.randf_range(0.6, 1.6), p, ROCK))


func _near_slot(p: Vector3, dist: float) -> bool:
	for s in SLOTS:
		if Vector2(p.x, p.z).distance_to(Vector2(s[0].x, s[0].z)) < dist:
			return true
	return Vector2(p.x, p.z).distance_to(Vector2(0, -2)) < 6.0


func _palm(p: Vector3, rng: RandomNumberGenerator) -> void:
	var palm := Node3D.new()
	palm.position = p
	palm.rotation_degrees = Vector3(rng.randf_range(-8, 8), rng.randf_range(0, 360), rng.randf_range(-8, 8))
	var h := rng.randf_range(5.0, 8.0)
	palm.add_child(KitScript.cylinder(0.22, h, Vector3(0, h / 2, 0), PALM_TRUNK))
	for k in 6:
		var leaf := KitScript.box(Vector3(0.7, 0.08, 3.2), Vector3(0, h, 0), PALM_LEAF, false)
		leaf.rotation = Vector3(deg_to_rad(18), TAU * k / 6.0, 0)
		leaf.translate_object_local(Vector3(0, 0, 1.4))
		palm.add_child(leaf)
	add_child(palm)


## One locale = one chosen folder. Local +Z faces the approach.
func _locale(loc: Dictionary, slot: Array) -> void:
	var root := Node3D.new()
	root.position = slot[0]
	root.rotation_degrees.y = slot[1]
	add_child(root)
	var label_text := String(loc.get("label", "Drive"))
	var door_pos := Vector3.ZERO
	var door_scale := 1.3
	match String(slot[2]):
		"huts":
			for k in 3:
				var x := (k - 1) * 9.0
				var z := -2.0 if k == 1 else 1.0
				root.add_child(KitScript.box(Vector3(6, 3.6, 6), Vector3(x, 1.8, z - 3), Color(0.72, 0.6, 0.4)))
				var roof := KitScript.cone(5.2, 0.2, 2.6, Vector3(x, 4.9, z - 3), Color(0.62, 0.52, 0.28), false, 4)
				roof.rotation_degrees.y = 45
				root.add_child(roof)
			door_pos = Vector3(0, 0, -1.95)
			door_scale = 1.2
		"treehouse":
			root.add_child(KitScript.cylinder(1.3, 9.0, Vector3(0, 4.5, -2), PALM_TRUNK.darkened(0.2)))
			root.add_child(KitScript.box(Vector3(9, 0.4, 9), Vector3(0, 5.2, -2), PLANK))
			root.add_child(KitScript.box(Vector3(5, 3, 5), Vector3(0, 6.9, -2.5), Color(0.6, 0.48, 0.3), false))
			root.add_child(KitScript.cone(4.2, 0.2, 2.2, Vector3(0, 9.5, -2.5), Color(0.55, 0.45, 0.25), false, 4))
			root.add_child(KitScript.sphere(5.5, Vector3(0, 12.5, -2), PALM_LEAF.darkened(0.1)))
			# Spiral ramp hinted by a few landing boxes (the door is at the foot of the tree).
			for k in 4:
				var a := k * PI / 2.0
				root.add_child(KitScript.box(Vector3(2, 0.2, 1.4), Vector3(sin(a) * 2.6, 1.2 + k * 1.0, -2 + cos(a) * 2.6), PLANK, false))
			door_pos = Vector3(0, 0, -0.68)
			door_scale = 1.1
		"lighthouse":
			root.add_child(KitScript.cylinder(3.2, 18.0, Vector3(0, 9.0, -3.2), Color(0.95, 0.95, 0.92)))
			for k in 3:
				root.add_child(KitScript.cylinder(3.25, 1.6, Vector3(0, 4.0 + k * 5.0, -3.2), Color(0.75, 0.15, 0.12), false))
			root.add_child(KitScript.cylinder(2.2, 2.4, Vector3(0, 19.2, -3.2), Color(0.25, 0.25, 0.28), false))
			root.add_child(KitScript.glow_box(Vector3(1.4, 1.2, 1.4), Vector3(0, 19.2, -3.2), Color(1.0, 0.9, 0.5), 4.0))
			root.add_child(KitScript.omni(Vector3(0, 19.5, -3.2), 2.0, 30.0, Color(1, 0.9, 0.6)))
			door_pos = Vector3(0, 0, -0.02)
		"cave":
			root.add_child(KitScript.box(Vector3(7, 5.5, 2), Vector3(0, 2.75, -1.6), ROCK.darkened(0.55), false))
			for side: float in [-1.0, 1.0]:
				root.add_child(KitScript.sphere(2.4, Vector3(side * 4.2, 2.0, -0.8), ROCK))
			root.add_child(KitScript.sphere(3.0, Vector3(0, 6.0, -1.2), ROCK))
			door_pos = Vector3(0, 0, -0.55)
		"islet":
			root.add_child(KitScript.cylinder(20.0, 1.0, Vector3(0, -0.5, -10), SAND))
			root.add_child(KitScript.box(Vector3(6, 4, 6), Vector3(0, 2, -14), Color(0.72, 0.6, 0.4)))
			root.add_child(KitScript.cone(5.0, 0.2, 2.6, Vector3(0, 5.3, -14), Color(0.62, 0.52, 0.28), false, 4))
			door_pos = Vector3(0, 0, -10.95)
			# Rope bridge back towards the main island (2 m wide, railings 1 m).
			root.add_child(KitScript.box(Vector3(2, 0.2, 26), Vector3(0, 0.3, 20), PLANK))
			for side: float in [-1.0, 1.0]:
				root.add_child(KitScript.box(Vector3(0.06, 0.06, 26), Vector3(side * 1.0, 1.3, 20), Color(0.8, 0.7, 0.5), false))
	# Sign + door.
	root.add_child(KitScript.box(Vector3(0.12, 2.0, 0.12), door_pos + Vector3(-2.2, 1.0, 1.0), PLANK.darkened(0.2), false))
	root.add_child(KitScript.box(Vector3(2.4, 0.8, 0.08), door_pos + Vector3(-2.2, 2.2, 1.0), PLANK, false))
	root.add_child(KitScript.label(label_text, door_pos + Vector3(-2.2, 2.2, 1.05), 0.006, Color(1, 0.95, 0.8)))
	var door: Node3D = DoorScript.new()
	door.setup({"socket": 0, "label": label_text, "target_path": loc.get("path", ""), "target_id": "", "kind": "child", "thumb": ""}, ROOM_THEME)
	door.position = door_pos
	door.scale = Vector3.ONE * door_scale
	if String(loc.get("path", "")) != "":
		door.door_used.connect(manager.use_door)
		manager.register_door(door, loc["path"])
	root.add_child(door)
	root.add_child(KitScript.omni(door_pos + Vector3(0, 3.0, 1.5), 0.8, 8.0, Color(1, 0.85, 0.6)))
	var front: Vector3 = root.to_global(door_pos + Vector3(0, 0, 7)) if root.is_inside_tree() else root.transform * (door_pos + Vector3(0, 0, 7))
	_fronts[loc.get("path", "")] = [front, float(slot[1])]


func _environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	# Golden hour: peach horizon, soft blue overhead, a low sun over the sea.
	sm.sky_top_color = Color(0.32, 0.45, 0.72)
	sm.sky_horizon_color = Color(1.0, 0.72, 0.5)
	sm.ground_horizon_color = Color(0.85, 0.62, 0.45)
	sm.ground_bottom_color = Color(0.15, 0.3, 0.4)
	sm.sun_angle_max = 20.0
	sky.sky_material = sm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.75, 0.7)
	e.ambient_light_energy = 0.55
	e.fog_enabled = true
	e.fog_light_color = Color(0.95, 0.75, 0.6)
	e.fog_density = 0.0035
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	# Light travels from the sea (+Z) onto the island: the sunset is in your opening view.
	sun.rotation_degrees = Vector3(-14, 10, 0)
	sun.light_energy = 1.25
	sun.light_color = Color(1.0, 0.78, 0.55)
	add_child(sun)
	# TODO(time-of-day): follow real time / fixed sunset / fixed night (Settings).


func get_spawn() -> Array:
	return [Vector3(0, 0, -1.0), 180.0]   # on the beach, facing out to sea (+Z)


func get_outside_point(location_path: String) -> Array:
	return _fronts.get(location_path, get_spawn())
