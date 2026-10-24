extends Node3D
## Museum Quad GREYBOX (WORLDS.md §2, WORLD_BLOCKOUTS.md §2). Smithsonian-style:
## a lawn ringed by museum buildings, one per drive (in the demo: one per
## chosen folder), spawn on the landing circle facing the first building.
## Primitive meshes only; measurements match the blockout spec.

const KitScript := preload("res://world/kit.gd")
const DoorScript := preload("res://world/door.gd")

const RADIUS := 30.0           # landing circle centre -> building front faces
const BUILDING := Vector3(22, 11, 16)
const STONE := Color(0.86, 0.83, 0.76)
const STONE_DARK := Color(0.7, 0.67, 0.6)
const LAWN := Color(0.33, 0.52, 0.27)
const PATH := Color(0.78, 0.74, 0.66)

## Interior tint for rooms in this world (warm stone, dark wood, gilt frames).
const ROOM_THEME := {
	"wall": Color(0.88, 0.84, 0.76), "floor": Color(0.36, 0.24, 0.15), "ceiling": Color(0.95, 0.93, 0.88),
	"frame": Color(0.72, 0.56, 0.22), "door": Color(0.3, 0.2, 0.12), "door_frame": Color(0.8, 0.76, 0.68),
	"light": Color(1.0, 0.93, 0.8),
}

var manager: Node
var _fronts: Dictionary = {}   # location path -> [front centre, yaw]


func build(locations: Array) -> void:
	_environment()
	add_child(KitScript.box(Vector3(160, 0.2, 160), Vector3(0, -0.1, 0), LAWN))
	# Cross paths + ring path + landing circle.
	add_child(KitScript.box(Vector3(4, 0.03, 2 * RADIUS), Vector3(0, 0.015, 0), PATH, false))
	add_child(KitScript.box(Vector3(2 * RADIUS, 0.03, 4), Vector3(0, 0.015, 0), PATH, false))
	add_child(KitScript.cylinder(7.0, 0.06, Vector3(0, 0.03, 0), PATH.lightened(0.1), false))
	add_child(KitScript.cylinder(5.0, 0.07, Vector3(0, 0.035, 0), Color(0.62, 0.6, 0.58), false))
	# Map plinth (a physical teleport point) + label.
	var plinth := KitScript.box(Vector3(1.2, 1.1, 0.6), Vector3(0, 0.55, 2.2), Color(0.45, 0.33, 0.2)) as StaticBody3D
	KitScript.make_interactive(plinth, {}, "Map of your PC: teleport", func(): get_tree().call_group("sc_main", "_open_teleport"))
	add_child(plinth)
	add_child(KitScript.label("MAP OF YOUR PC\nPress T to teleport", Vector3(0, 1.3, 2.52), 0.0026, Color(1, 0.9, 0.6)))

	var locs := locations if not locations.is_empty() else [{"label": "C:", "path": ""}, {"label": "D:", "path": ""}]
	var count := mini(locs.size(), 6)
	for i in count:
		var angle := TAU * i / float(maxi(count, 4))   # at least 4 slots so 2 buildings don't face each other only
		_building(locs[i], angle)

	# Trees around the quad.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 26:
		var a := TAU * i / 26.0 + rng.randf() * 0.1
		var r := RADIUS - 9.0 + rng.randf() * 3.0
		var p := Vector3(sin(a) * r, 0, -cos(a) * r)
		if absf(p.x) < 4.5 or absf(p.z) < 4.5:
			continue  # keep the paths clear
		add_child(KitScript.cylinder(0.25, 2.4, p + Vector3(0, 1.2, 0), Color(0.4, 0.28, 0.18)))
		add_child(KitScript.sphere(1.6 + rng.randf() * 0.6, p + Vector3(0, 3.6, 0), Color(0.22, 0.42, 0.2)))
	# Benches by the circle.
	for a: float in [0.785, 2.356, 3.927, 5.498]:
		var bp := Vector3(sin(a) * 8.5, 0.25, -cos(a) * 8.5)
		var bench := KitScript.box(Vector3(2.0, 0.5, 0.6), bp, Color(0.45, 0.3, 0.18)) as Node3D
		bench.rotation.y = -a
		add_child(bench)


func _building(loc: Dictionary, angle: float) -> void:
	var front := Vector3(sin(angle), 0, -cos(angle)) * RADIUS
	var yaw := -angle
	var b := Node3D.new()
	b.position = front
	b.rotation.y = yaw
	add_child(b)
	var s := BUILDING
	# Podium + steps (local +Z faces the quad; the front face is at z = 0).
	b.add_child(KitScript.box(Vector3(s.x + 2, 1.2, s.z + 2), Vector3(0, 0.6, -s.z / 2), STONE_DARK))
	for k in 4:  # visual steps...
		b.add_child(KitScript.box(Vector3(12, 0.3, 0.6), Vector3(0, 0.15 + k * 0.3, 2.2 - k * 0.6), STONE_DARK.lightened(0.05), false))
	# ...walked as an invisible ramp (character controllers don't climb 30 cm steps).
	var ramp := StaticBody3D.new()
	var rc := CollisionShape3D.new()
	var rs := BoxShape3D.new()
	rs.size = Vector3(12, 0.1, 2.6)
	rc.shape = rs
	ramp.add_child(rc)
	ramp.position = Vector3(0, 0.6, 1.5)
	ramp.rotation.x = atan2(1.2, 2.4)
	b.add_child(ramp)
	# Main block, portico columns, entablature, pediment.
	b.add_child(KitScript.box(Vector3(s.x, s.y, s.z - 4), Vector3(0, 1.2 + s.y / 2, -s.z / 2 - 2), STONE))
	for c in 6:
		var x := -7.5 + c * 3.0
		b.add_child(KitScript.cylinder(0.55, 8.0, Vector3(x, 1.2 + 4.0, -1.0), STONE.lightened(0.05)))
	b.add_child(KitScript.box(Vector3(19, 1.2, 4.4), Vector3(0, 1.2 + 8.6, -1.6), STONE, false))
	var ped := KitScript.prism(Vector3(19, 2.6, 4.4), Vector3(0, 1.2 + 10.5, -1.6), STONE)
	b.add_child(ped)
	# Banner + name.
	var label_text := String(loc.get("label", "Drive"))
	b.add_child(KitScript.box(Vector3(1.4, 4.0, 0.05), Vector3(-5.2, 6.0, 0.4), Color(0.55, 0.12, 0.12), false))
	b.add_child(KitScript.box(Vector3(1.4, 4.0, 0.05), Vector3(5.2, 6.0, 0.4), Color(0.55, 0.12, 0.12), false))
	b.add_child(KitScript.label(label_text.to_upper(), Vector3(0, 1.2 + 8.6, 0.65), 0.016, Color(0.25, 0.2, 0.15), 0))
	# Entrance door (into this location's first room).
	var door: Node3D = DoorScript.new()
	door.setup({"socket": 0, "label": label_text, "target_path": loc.get("path", ""), "target_id": "", "kind": "child", "thumb": ""}, ROOM_THEME)
	door.position = Vector3(0, 1.2, -3.0)
	door.scale = Vector3(1.6, 1.6, 1.6)
	if String(loc.get("path", "")) != "":
		door.door_used.connect(manager.use_door)
		manager.register_door(door, loc["path"])
	b.add_child(door)
	b.add_child(KitScript.omni(Vector3(0, 6.0, 0.5), 1.0, 10.0, Color(1, 0.9, 0.75)))
	# Outside return point: 8 m in front of the steps, facing the building.
	_fronts[loc.get("path", "")] = [front + Vector3(sin(angle), 0, -cos(angle)) * -8.0, rad_to_deg(yaw)]


func _environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.35, 0.55, 0.85)
	sm.sky_horizon_color = Color(0.75, 0.82, 0.9)
	sm.ground_horizon_color = Color(0.6, 0.65, 0.6)
	sky.sky_material = sm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.82, 0.85)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.1
	sun.light_color = Color(1, 0.95, 0.85)
	add_child(sun)


func get_spawn() -> Array:
	return [Vector3(0, 0, 4.5), 0.0]


func get_outside_point(location_path: String) -> Array:
	return _fronts.get(location_path, get_spawn())
